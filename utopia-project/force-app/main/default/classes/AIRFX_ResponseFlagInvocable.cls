/**
 * AIRFX_ResponseFlagInvocable
 * ===========================
 * Deterministic Red/Yellow/Green triage engine for GPS_ResponseNew__c.
 *
 * PROBLEM:
 *   The RAG pipeline is unfiltered — 1,881 knowledge articles with no
 *   metadata, no product filtering, no region awareness. LLM-generated
 *   flags are wrong ~30% of the time because the model synthesizes from
 *   wrong/conflicting grounding docs.
 *
 * SOLUTION:
 *   Hardcoded capability map derived from official Salesforce GPS
 *   grounding document (Mike Rosa). Keyword-matched rules applied
 *   deterministically — no LLM needed for flagging.
 *
 * FLAG LOGIC:
 *   RED    = Requirement exceeds Salesforce capability or conflicts with policy.
 *           SE must edit the answer or escalate before submission.
 *   GREEN  = Requirement verified as met by deterministic comparison.
 *           SE can trust and move on.
 *   YELLOW = No deterministic rule matched. Human review required.
 *           Better to say "I don't know" than guess wrong.
 *
 * RULE TYPES:
 *   BINARY_CANNOT          — Salesforce cannot do this. Any requirement = Red.
 *   BINARY_CAN             — Salesforce can do this. Requirement asking for it = Green.
 *   BINARY_CAN_DIFFERENTLY — Salesforce meets the intent but not the explicit letter = Yellow.
 *   NUMERIC_MIN            — SF commits to X. Requirement > X = Red, <= X = Green.
 *   NUMERIC_MAX            — SF commits to max X. Requirement < X = Red, >= X = Green.
 *   CONDITIONAL            — Depends on Product_Type__c or Country__c from GPS_Project__c.
 *
 * USAGE:
 *   Flow action in AIRFX_GetSingleAnswer, or batch re-flagging.
 *   Pass GPS_ResponseNew__c record IDs → flags written to Response_Flag__c
 *   and Response_Flag_Reason__c.
 *
 * @author  Robert Smith (Principal SE, GPS)
 * @date    2026-02-06
 * @project Agentic Utopia (EYES) — Phase 2: Answer Flagging
 */
public with sharing class AIRFX_ResponseFlagInvocable {

    // =========================================================================
    // CONSTANTS
    // =========================================================================

    private static final String FLAG_RED    = 'Red';
    private static final String FLAG_YELLOW = 'Yellow';
    private static final String FLAG_GREEN  = 'Green';

    // =========================================================================
    // INVOCABLE INTERFACE
    // =========================================================================

    public class FlagRequest {
        @InvocableVariable(label='Response Record ID' description='GPS_ResponseNew__c record ID to flag' required=false)
        public Id responseId;

        @InvocableVariable(label='Project Record ID' description='GPS_Project__c ID — flags ALL responses for this project' required=false)
        public Id projectId;
    }

    public class FlagResult {
        @InvocableVariable(label='Response Record ID')
        public Id responseId;

        @InvocableVariable(label='Flag Value')
        public String flag;

        @InvocableVariable(label='Flag Reason')
        public String reason;

        @InvocableVariable(label='Rule Matched')
        public String ruleId;

        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Flag Response: Red/Yellow/Green'
        description='Deterministic triage flag for AI-generated RFP responses. Compares requirement against Salesforce capability map.'
        category='EYES / RFP Processing'
    )
    public static List<FlagResult> flagResponses(List<FlagRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            FlagResult empty = new FlagResult();
            empty.success = false;
            empty.errorMessage = 'No requests provided.';
            return new List<FlagResult>{ empty };
        }

        // Collect record IDs — support both individual and project-level flagging
        Set<Id> responseIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        for (FlagRequest req : requests) {
            if (req.responseId != null) {
                responseIds.add(req.responseId);
            }
            if (req.projectId != null) {
                projectIds.add(req.projectId);
            }
        }

        // If project IDs provided, expand to all responses for those projects
        if (!projectIds.isEmpty()) {
            for (GPS_ResponseNew__c r : [
                SELECT Id FROM GPS_ResponseNew__c WHERE GPS_Projects__c IN :projectIds
            ]) {
                responseIds.add(r.Id);
            }
        }

        // Bulk query responses + parent project
        Map<Id, GPS_ResponseNew__c> responseMap = new Map<Id, GPS_ResponseNew__c>([
            SELECT Id,
                   Question__c,
                   AI_Generated_Answer__c,
                   Security_Flag__c,
                   Product_Category__c,
                   GPS_Projects__c,
                   GPS_Projects__r.Product_Type__c,
                   GPS_Projects__r.Country__c
            FROM GPS_ResponseNew__c
            WHERE Id IN :responseIds
        ]);

        // Build rules once
        List<CapabilityRule> rules = buildRules();

        // Process each request
        List<FlagResult> results = new List<FlagResult>();
        List<GPS_ResponseNew__c> toUpdate = new List<GPS_ResponseNew__c>();

        // If projectId was used, iterate all responses; otherwise use individual IDs
        List<Id> idsToProcess = new List<Id>();
        Boolean isProjectMode = false;
        for (FlagRequest req : requests) {
            if (req.projectId != null) {
                isProjectMode = true;
            }
        }
        if (isProjectMode) {
            idsToProcess.addAll(responseMap.keySet());
        } else {
            for (FlagRequest req : requests) {
                if (req.responseId != null) {
                    idsToProcess.add(req.responseId);
                }
            }
        }

        for (Id recId : idsToProcess) {
            FlagResult fr = new FlagResult();
            fr.responseId = recId;

            GPS_ResponseNew__c rec = responseMap.get(recId);
            if (rec == null) {
                fr.success = false;
                fr.errorMessage = 'Record not found: ' + recId;
                results.add(fr);
                continue;
            }

            try {
                // Get project context
                String productType = rec.GPS_Projects__r != null
                    ? rec.GPS_Projects__r.Product_Type__c : '';
                String country = rec.GPS_Projects__r != null
                    ? rec.GPS_Projects__r.Country__c : '';

                // Run the flag engine
                FlagDecision decision = evaluate(
                    rec.Question__c,
                    rec.AI_Generated_Answer__c,
                    productType,
                    country,
                    rules
                );

                fr.flag = decision.flag;
                fr.reason = decision.reason;
                fr.ruleId = decision.ruleId;
                fr.success = true;

                // Stage the update
                toUpdate.add(new GPS_ResponseNew__c(
                    Id = rec.Id,
                    Security_Flag__c = decision.flag,
                    Response_Flag_Reason__c = decision.reason
                ));

            } catch (Exception e) {
                fr.success = false;
                fr.flag = FLAG_YELLOW;
                fr.reason = 'Flagging engine error: ' + e.getMessage();
                fr.errorMessage = e.getMessage();

                // Still write Yellow on error — safer than no flag
                toUpdate.add(new GPS_ResponseNew__c(
                    Id = rec.Id,
                    Security_Flag__c = FLAG_YELLOW,
                    Response_Flag_Reason__c = 'Flagging engine error — human review required.'
                ));
            }

            results.add(fr);
        }

        // Bulk DML
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        return results;
    }

    // =========================================================================
    // FLAG ENGINE
    // =========================================================================

    @TestVisible
    private static FlagDecision evaluate(
        String question,
        String aiAnswer,
        String productType,
        String country,
        List<CapabilityRule> rules
    ) {
        FlagDecision decision = new FlagDecision();

        if (String.isBlank(question)) {
            decision.flag = FLAG_YELLOW;
            decision.reason = 'No question text to evaluate.';
            decision.ruleId = 'NO_QUESTION';
            return decision;
        }

        AIRFX_SecurityPreFilter.Result preFilter =
            AIRFX_SecurityPreFilter.evaluate(question);

        if (preFilter != null && preFilter.skipAsGreen) {
            decision.flag = FLAG_GREEN;
            decision.reason = 'Pre-filter: obvious functional/non-security clause.';
            if (preFilter.matchedFunctionalTerms != null && !preFilter.matchedFunctionalTerms.isEmpty()) {
                decision.reason += ' Functional terms: ' + String.join(preFilter.matchedFunctionalTerms, ', ');
            }
            decision.ruleId = 'PREFILTER_NON_SECURITY';
            return decision;
        }

        String qLower = question.toLowerCase();
        String aLower = String.isNotBlank(aiAnswer) ? aiAnswer.toLowerCase() : '';
        Boolean isGovCloud = isGovCloudDeal(productType);

        // Iterate rules in priority order — first match wins
        for (CapabilityRule rule : rules) {
            if (!matchesKeywords(qLower, rule.keywords)) {
                continue;
            }
            // Check exclude keywords — if any match, skip this rule
            if (rule.excludeKeywords != null && !rule.excludeKeywords.isEmpty() && matchesKeywords(qLower, rule.excludeKeywords)) {
                continue;
            }

            // Check product filter
            if (rule.productFilter == 'GOV_CLOUD' && !isGovCloud) continue;
            if (rule.productFilter == 'COMMERCIAL' && isGovCloud) continue;

            // Apply rule based on type
            switch on rule.ruleType {
                when 'BINARY_CANNOT' {
                    decision.flag = FLAG_RED;
                    decision.reason = rule.reason;
                    decision.ruleId = rule.id;
                    return decision;
                }
                when 'BINARY_CAN' {
                    decision.flag = FLAG_GREEN;
                    decision.reason = rule.reason;
                    decision.ruleId = rule.id;
                    return decision;
                }
                when 'BINARY_CAN_DIFFERENTLY' {
                    decision.flag = FLAG_YELLOW;
                    decision.reason = rule.reason;
                    decision.ruleId = rule.id;
                    return decision;
                }
                when 'NUMERIC_MIN' {
                    // SF commits to a minimum. If requirement asks for MORE, Red.
                    Decimal reqValue = extractNumber(qLower, rule.numericUnit);
                    if (reqValue == null) {
                        // Can't parse the requirement number — Yellow
                        decision.flag = FLAG_YELLOW;
                        decision.reason = 'Detected ' + rule.id + ' topic but could not extract numeric value from requirement. Human review needed.';
                        decision.ruleId = rule.id + '_PARSE_FAIL';
                        return decision;
                    }
                    if (reqValue > rule.numericThreshold) {
                        decision.flag = FLAG_RED;
                        decision.reason = 'Requirement: ' + reqValue + rule.numericUnit
                            + '. Salesforce commits to: ' + rule.numericThreshold + rule.numericUnit
                            + '. ' + rule.reason;
                        decision.ruleId = rule.id;
                    } else {
                        decision.flag = FLAG_GREEN;
                        decision.reason = 'Requirement: ' + reqValue + rule.numericUnit
                            + '. Salesforce commits to: ' + rule.numericThreshold + rule.numericUnit
                            + '. Requirement met.';
                        decision.ruleId = rule.id;
                    }
                    return decision;
                }
                when 'NUMERIC_MAX' {
                    // SF commits to a maximum. If requirement asks for LESS, Red.
                    Decimal reqValue = extractNumber(qLower, rule.numericUnit);
                    if (reqValue == null) {
                        decision.flag = FLAG_YELLOW;
                        decision.reason = 'Detected ' + rule.id + ' topic but could not extract numeric value from requirement. Human review needed.';
                        decision.ruleId = rule.id + '_PARSE_FAIL';
                        return decision;
                    }
                    if (reqValue < rule.numericThreshold) {
                        decision.flag = FLAG_RED;
                        decision.reason = 'Requirement: ' + reqValue + rule.numericUnit
                            + '. Salesforce commits to: ' + rule.numericThreshold + rule.numericUnit
                            + '. ' + rule.reason;
                        decision.ruleId = rule.id;
                    } else {
                        decision.flag = FLAG_GREEN;
                        decision.reason = 'Requirement: ' + reqValue + rule.numericUnit
                            + '. Salesforce commits to: ' + rule.numericThreshold + rule.numericUnit
                            + '. Requirement met.';
                        decision.ruleId = rule.id;
                    }
                    return decision;
                }
                when 'CONDITIONAL_DATA_RESIDENCY' {
                    decision = evaluateDataResidency(qLower, country, rule);
                    return decision;
                }
            }
        }

        // No rule matched — Yellow
        decision.flag = FLAG_YELLOW;
        decision.reason = 'No deterministic rule matched this requirement. Human review required.';
        decision.ruleId = 'NO_MATCH';
        return decision;
    }

    // =========================================================================
    // DATA RESIDENCY EVALUATION
    // =========================================================================

    private static final Set<String> ALLOWED_DATA_COUNTRIES = new Set<String>{
        'us', 'br', 'ca', 'au', 'in', 'jp', 'sg', 'kr', 'fr', 'de', 'se', 'gb',
        'id', 'ie', 'il', 'it', 'ch', 'ae'
    };

    // Human-readable mapping for flag reasons
    private static final Map<String, String> COUNTRY_NAMES = new Map<String, String>{
        'us' => 'United States', 'br' => 'Brazil', 'ca' => 'Canada',
        'au' => 'Australia', 'in' => 'India', 'jp' => 'Japan',
        'sg' => 'Singapore', 'kr' => 'South Korea', 'fr' => 'France',
        'de' => 'Germany', 'se' => 'Sweden', 'gb' => 'United Kingdom',
        'id' => 'Indonesia', 'ie' => 'Ireland', 'il' => 'Israel',
        'it' => 'Italy', 'ch' => 'Switzerland', 'ae' => 'UAE'
    };

    private static FlagDecision evaluateDataResidency(
        String qLower, String country, CapabilityRule rule
    ) {
        FlagDecision decision = new FlagDecision();
        decision.ruleId = rule.id;

        // If the project has a country, check it against allowed list
        if (String.isNotBlank(country)) {
            String countryLower = country.toLowerCase().trim();
            if (ALLOWED_DATA_COUNTRIES.contains(countryLower)) {
                String displayName = COUNTRY_NAMES.containsKey(countryLower)
                    ? COUNTRY_NAMES.get(countryLower) : country;
                decision.flag = FLAG_GREEN;
                decision.reason = 'Data residency in ' + displayName + ' (' + country.toUpperCase() + ') is supported. '
                    + 'Salesforce hosts data in 18 Hyperforce regions: US, BR, CA, AU, IN, JP, SG, KR, FR, DE, SE, GB, ID, IE, IL, IT, CH, AE.';
            } else {
                decision.flag = FLAG_RED;
                decision.reason = 'Data residency in ' + country.toUpperCase() + ' is NOT in Salesforce\'s supported hosting locations. '
                    + 'Supported: US, BR, CA, AU, IN, JP, SG, KR, FR, DE, SE, GB, ID, IE, IL, IT, CH, AE. '
                    + 'Escalation required.';
            }
        } else {
            // No country on project — can't determine, Yellow
            decision.flag = FLAG_YELLOW;
            decision.reason = 'Data residency requirement detected but no Country__c on GPS_Project__c. Cannot evaluate. Human review needed.';
        }

        return decision;
    }

    // =========================================================================
    // GOV CLOUD DETECTION
    // =========================================================================

    @TestVisible
    private static Boolean isGovCloudDeal(String productType) {
        if (String.isBlank(productType)) return false;
        String pt = productType.toLowerCase();
        return pt.contains('gov') || pt.contains('government')
            || pt.contains('gcch') || pt.contains('il4') || pt.contains('il5');
    }

    // =========================================================================
    // KEYWORD MATCHING
    // =========================================================================

    @TestVisible
    private static Boolean matchesKeywords(String text, List<String> keywords) {
        for (String kw : keywords) {
            // If keyword contains regex metacharacters, use Pattern matching
            if (kw.contains('.*') || kw.contains('\\b')) {
                try {
                    Pattern p = Pattern.compile(kw);
                    Matcher m = p.matcher(text);
                    if (m.find()) return true;
                } catch (Exception e) {
                    // Bad regex — fall back to contains
                    if (text.contains(kw)) return true;
                }
            } else {
                if (text.contains(kw)) return true;
            }
        }
        return false;
    }

    // =========================================================================
    // NUMERIC EXTRACTION
    // =========================================================================

    /**
     * Extracts a numeric value from text, optionally near a unit keyword.
     * Simpler than SmartResponseRouter's parser — just needs the number.
     */
    @TestVisible
    private static Decimal extractNumber(String text, String unit) {
        // Strategy: find number patterns near the unit context
        String regex;

        if (unit == '%') {
            // Look for patterns like 99.9%, 99.99 percent, etc.
            regex = '(\\d+\\.?\\d*)\\s*(%|percent)';
        } else if (unit == ' hours') {
            regex = '(\\d+\\.?\\d*)\\s*(hours?|hrs?)';
        } else if (unit == ' minutes') {
            regex = '(\\d+\\.?\\d*)\\s*(minutes?|mins?)';
        } else if (unit == ' days') {
            regex = '(\\d+\\.?\\d*)\\s*(days?|calendar days?|business days?)';
        } else {
            // Generic number extraction
            regex = '(\\d+\\.?\\d*)';
        }

        Pattern p = Pattern.compile(regex);
        Matcher m = p.matcher(text);

        // Collect all matches and return the most relevant one
        // For percentages: return the highest (most demanding requirement)
        // For time: return the lowest (tightest SLA)
        List<Decimal> found = new List<Decimal>();
        while (m.find()) {
            try {
                found.add(Decimal.valueOf(m.group(1)));
            } catch (Exception e) {
                continue;
            }
        }

        if (found.isEmpty()) return null;

        if (unit == '%') {
            // For uptime/SLA percentages, the requirement is the highest number
            Decimal max = found[0];
            for (Decimal d : found) {
                if (d > max) max = d;
            }
            return max;
        } else {
            // For time-based SLAs (RPO, RTO, response time), requirement is the lowest
            Decimal min = found[0];
            for (Decimal d : found) {
                if (d < min) min = d;
            }
            return min;
        }
    }

    // =========================================================================
    // CAPABILITY RULES — Source: GPS Grounding Document (Mike Rosa)
    // =========================================================================

    @TestVisible
    private static List<CapabilityRule> buildRules() {
        List<CapabilityRule> rules = new List<CapabilityRule>();

        // =================================================================
        // NUMERIC RULES
        // =================================================================

        // UPTIME / AVAILABILITY — 99.7% without approval, 99.9% with
        rules.add(numericMin('UPTIME',
            new List<String>{'uptime', 'availability', '% sla', 'percent sla', 'percent uptime', 'percent availability'},
            99.7, '%',
            'Salesforce commits to 99.7% uptime. 99.9% available with approval only. Any requirement above 99.7% must be escalated.'));

        // RPO — 4 hours (lower = more demanding)
        rules.add(numericMax('RPO',
            new List<String>{'recovery point objective', 'rpo'},
            4, ' hours',
            'Salesforce RPO is 4 hours. Requirements demanding shorter RPO cannot be met.'));

        // RTO — 12 hours (lower = more demanding)
        rules.add(numericMax('RTO',
            new List<String>{'recovery time objective', 'rto'},
            12, ' hours',
            'Salesforce RTO is 12 hours. Requirements demanding shorter RTO cannot be met.'));

        // BREACH NOTIFICATION — Gov Cloud: 24 hours
        rules.add(numericMax('BREACH_NOTIFY_GOV',
            new List<String>{'breach notification', 'breach notice', 'notify.*breach', 'security breach.*notif'},
            24, ' hours',
            'Salesforce Gov Cloud commits to 24-hour breach notification. Shorter timeframes cannot be guaranteed.'));

        // =================================================================
        // BINARY CANNOT — Red flags (Salesforce cannot do this)
        // =================================================================

        rules.add(binaryCannot('ESCROW',
            new List<String>{'escrow', 'source code escrow'},
            'Salesforce cannot provide escrow services. Source code escrow is inapplicable to SaaS delivered through multitenant architecture.'));

        rules.add(binaryCannot('SOURCE_CODE',
            new List<String>{'source code', 'source-code', 'codebase access'},
            'Salesforce cannot provide source code. Inapplicable to SaaS subscription through multitenant architecture.'));

        rules.add(binaryCannot('DEDICATED_HARDWARE',
            new List<String>{'dedicated hardware', 'dedicated instance', 'dedicated equipment', 'dedicated server', 'dedicated infrastructure'},
            'Salesforce cannot offer dedicated hardware. Salesforce is a multitenant SaaS platform.'));

        rules.add(binaryCannotWithExclusions('PRIVATE_CLOUD',
            new List<String>{'private cloud', 'on-premise cloud', 'customer-hosted cloud'},
            new List<String>{
                'no private cloud', 'not.*private cloud', 'without.*private cloud',
                '\\bsaas\\b', 'public cloud'
            },
            'Salesforce cannot be hosted in a private cloud.'));

        rules.add(binaryCannot('SERVICE_CREDIT_SLA',
            new List<String>{'service credit', 'service level credit', 'sla credit', 'sla penalty', 'sla penalt', 'liquidated damages'},
            'Salesforce cannot do service credit SLAs. Salesforce does not typically offer SLAs with financial penalties.'));

        // RESOLUTION_TIME — narrowed to only catch hard numeric resolution guarantees.
        // General support questions (help desk, business hours, channels) stay Yellow 
        // for AI grounding with Standard/Premier/Signature tier details.
        // Premier guarantees RESPONSE times, not RESOLUTION times — that distinction matters.
        rules.add(binaryCannot('RESOLUTION_TIME_HARD',
            new List<String>{
                'resolve within \\d', 'resolution within \\d',
                'resolution time.*\\d',
                'mean time to repair', 'mttr',
                'guaranteed resolution', 'resolution guarantee',
                'resolution time sla', 'resolution time agreement',
                'fix within \\d', 'repair within \\d',
                'remediate within \\d'
            },
            'Salesforce cannot guarantee specific resolution times. Premier/Signature plans offer defined response times (not resolution times). Resolution depends on issue complexity.'));

        rules.add(binaryCannot('RESPONSE_TIME_GUARANTEE',
            new List<String>{'response time guarantee', 'guaranteed response time', 'performance guarantee', 'guaranteed latency', 'guaranteed throughput'},
            'Salesforce cannot guarantee specific response times. Performance depends on components outside Salesforce\'s control.'));

        rules.add(binaryCannot('IL6',
            new List<String>{'il6', 'il-6', 'impact level 6', 'impact level six'},
            'Salesforce does not currently support IL6.'));

        rules.add(binaryCannot('CUSTOMER_BACKGROUND_CHECK',
            new List<String>{'background check on salesforce', 'background checks on vendor', 'background check.*provider employee', 'checks on contractor personnel'},
            'Salesforce does not allow customers to perform background checks on Salesforce employees.'));

        rules.add(binaryCannot('CUSTOMER_NDA',
            new List<String>{'customer-specific nda', 'custom nda', 'customer nda', 'specific non-disclosure'},
            'Salesforce requires employees to sign a confidentiality agreement. Customer-specific NDAs cannot be accommodated.'));

        rules.add(binaryCannot('RAW_SCAN_RESULTS',
            new List<String>{'raw scan result', 'vulnerability scan result', 'scan report', 'detailed vulnerability'},
            'Salesforce cannot provide raw scan results. Executive summaries can be provided.'));

        rules.add(binaryCannot('ENCRYPTION_IN_MEMORY',
            new List<String>{'encrypt.*in memory', 'encrypt.*in use', 'in-memory encryption', 'encryption at use', 'data in use encrypt'},
            'Salesforce encrypts data in transit and at rest. Salesforce does not encrypt data in memory/in use.'));

        rules.add(binaryCannot('SBOM',
            new List<String>{'sbom', 'software bill of material', 'bill of materials'},
            'Salesforce cannot provide SBOMs.'));

        rules.add(binaryCannot('SECNUMCLOUD',
            new List<String>{'secnumcloud'},
            'Salesforce does not meet SecNumCloud requirements.'));

        rules.add(binaryCannot('CUSTOMER_VM',
            new List<String>{'customer vm', 'customer virtual machine', 'deploy to our vm', 'deploy to agency vm', 'customer-owned infrastructure'},
            'Salesforce cannot be deployed to a customer VM. Salesforce runs in AWS VMs managed by Salesforce.'));

        rules.add(binaryCannot('CUSTOMER_APPROVAL_CHANGES',
            new List<String>{'customer approval before changes', 'approval before maintenance', 'approve.*before.*upgrade', 'seek.*authorization.*before'},
            'Salesforce cannot seek customer approval before making changes. Upgrade and maintenance schedules are set by Salesforce.'));

        rules.add(binaryCannot('CUSTOMER_AUDIT_SCHEDULE',
            new List<String>{'audit on demand', 'audit at any time', 'unlimited audit', 'unrestricted audit'},
            'Salesforce can only allow audits under conditions described in our contracts.'));

        rules.add(binaryCannot('DEFER_UPGRADES',
            new List<String>{'defer upgrade', 'opt out of upgrade', 'skip upgrade', 'choose.*upgrade', 'decline.*upgrade'},
            'Customers cannot defer or choose upgrades. Salesforce has its own release schedule.'));

        rules.add(binaryCannot('IPV6_FULL',
            new List<String>{'ipv6', 'ip version 6', 'ip v6'},
            'Salesforce does not fully support IPv6.'));

        // SAAS / CLOUD DELIVERY — affirm cloud-native delivery model
        // Must appear before ON_PREM_GENERAL and DATA_RESIDENCY since first match wins.
        // Catches questions asking for SaaS/cloud delivery, preventing false Reds 
        // from on-prem rules and wrong-reason Greens from data residency.
        rules.add(binaryCan('SAAS_DELIVERY',
            new List<String>{
                'software as a service', '\bsaas\b', 'cloud-based delivery', 'cloud based', 'cloud-based',
                'cloud.based.*model', 'cloud service model', 'cloud.hosted',
                'delivered as.*saas', 'delivered as.*cloud'
            },
            'Salesforce is delivered exclusively as SaaS/PaaS. No on-premises infrastructure required for vendor-managed components. All maintenance, updates, and security patches are managed by Salesforce.'));

        rules.add(binaryCannotWithExclusions('ON_PREM_GENERAL',
            new List<String>{'on-premise', 'on premise', 'on-prem', 'self-hosted'},
            new List<String>{
                'no on-premise', 'no on premise', 'no on-prem',
                'not on-premise', 'not on premise', 'not on-prem',
                'without on-premise', 'without on premise', 'without on-prem',
                'requiring no on-prem', 'eliminat.*on-prem',
                '\\bsaas\\b', 'cloud-based.*not.*on-prem',
                'how is.*deploy', 'how.*deployed', 'describe.*deploy', 'what.*deployment model', 'cloud based'
            },
            'On-premises deployment is strictly limited to MuleSoft and Tableau only.'));

        rules.add(binaryCannot('CUSTOMER_POLICY_COMPLY',
            new List<String>{'comply with customer.*security policy', 'comply with agency.*security policy', 'follow.*customer.*policy', 'follow.*agency.*procedure', 'adhere to.*customer.*standard'},
            'Salesforce cannot comply with customer-specific security standards. Salesforce enforces its own policies.'));

        rules.add(binaryCannot('CUSTOMER_REMEDIATION_TIMELINE',
            new List<String>{'remediat.*within.*day', 'remediat.*within.*hour', 'patch.*within.*day', 'patch.*within.*hour', 'customer.*remediation timeline'},
            'Salesforce has its own remediation timelines. Salesforce cannot agree to customer-imposed timelines.'));

        rules.add(binaryCannot('IPS',
            new List<String>{'intrusion prevention system', '\\bips\\b'},
            'Salesforce uses an IDS but does not use an Intrusion Prevention System (IPS).'));

        rules.add(binaryCannot('ISO_20000',
            new List<String>{'iso 20000', 'iso/iec 20000', 'iso20000'},
            'Salesforce does not have ISO/IEC 20000 certification (self-assessment completed).'));

        rules.add(binaryCannot('ISO_14001',
            new List<String>{'iso 14001', 'iso14001'},
            'Salesforce does not have ISO 14001 certification but can demonstrate environmental impact with other documentation.'));

        rules.add(binaryCannot('ISO_45001',
            new List<String>{'iso 45001', 'iso45001'},
            'Salesforce does not have ISO 45001 certification.'));

        rules.add(binaryCannot('CLASSIFIED_DATA',
            new List<String>{'classified data', 'classified information', 'top secret', 'secret clearance'},
            'Classified data cannot be stored in Salesforce commercial or government clouds.'));

        rules.add(binaryCannot('CUSTOMER_FORMAT_INCIDENT',
            new List<String>{'incident report.*customer.*format', 'incident report.*preferred format', 'incident report.*our format'},
            'Salesforce cannot provide incident reports in a customer\'s preferred format. Implementation partner may reformat.'));

        rules.add(binaryCannot('ADVANCE_NOTICE_UNPLANNED',
            new List<String>{'advance notice.*unplanned', 'prior notice.*unplanned', 'advance warning.*outage'},
            'Salesforce cannot give advance notice of unplanned outages.'));

        // =================================================================
        // BINARY CAN — Green flags (Salesforce does this)
        // =================================================================

        rules.add(binaryCan('ENCRYPTION_AT_REST',
            new List<String>{'encrypt.*at rest', 'encryption at rest', 'data at rest.*encrypt'},
            'Salesforce encrypts all data at rest.'));

        rules.add(binaryCan('ENCRYPTION_IN_TRANSIT',
            new List<String>{'encrypt.*in transit', 'encryption in transit', 'data in transit.*encrypt', 'encrypt.*in motion'},
            'Salesforce encrypts all data in transit.'));

        rules.add(binaryCan('TLS',
            new List<String>{'tls 1.2', 'tls 1.3', 'tls1.2', 'tls1.3', 'transport layer security'},
            'Salesforce supports TLS 1.2 and TLS 1.3.'));

        rules.add(binaryCan('BYOK',
            new List<String>{'bring your own key', 'byok', 'customer managed key', 'customer.*encryption key'},
            'Salesforce offers BYOK. Customers can manage encryption keys (keys must be shared with Salesforce).'));

        rules.add(binaryCan('IL5',
            new List<String>{'il5', 'il-5', 'impact level 5', 'impact level five'},
            'Salesforce core has an IL5 PATO.'));

        rules.add(binaryCan('RBAC',
            new List<String>{'role-based access', 'role based access', 'rbac'},
            'Salesforce supports role-based access control (RBAC) within Salesforce.'));

        rules.add(binaryCan('PEN_TEST_CUSTOMER',
            new List<String>{'penetration test', 'pen test', 'pentest'},
            'Customers can perform their own penetration tests. Vulnerability remediation follows Salesforce internal timelines.'));

        rules.add(binaryCan('BACKUP',
            new List<String>{'nightly backup', 'daily backup', 'regular backup', 'automatic backup'},
            'Salesforce provides nightly backups as part of the standard offering.'));

        rules.add(binaryCan('EVENT_MONITORING',
            new List<String>{'event monitoring', 'event log', 'audit log', 'user activity log'},
            'Salesforce provides event monitoring and audit logging capabilities.'));

        rules.add(binaryCan('MULTI_FACTOR_AUTH',
            new List<String>{'multi-factor', 'multifactor', 'mfa', 'two-factor', '2fa'},
            'Salesforce supports multi-factor authentication.'));

        rules.add(binaryCan('SSO',
            new List<String>{'single sign-on', 'single sign on', '\bsso\b', 'saml', 'saml-based', 'federated identity', 'identity provider'},
            'Salesforce supports SAML 2.0 and OAuth-based single sign-on (SSO) with any compliant identity provider.'));

        rules.add(binaryCan('END_TO_END_ENCRYPTION',
            new List<String>{'end to end encrypt', 'end-to-end encrypt', 'e2e encrypt'},
            'Salesforce provides end-to-end encryption including in transit and at rest. Does not encrypt in memory.'));

        rules.add(binaryCan('DR_TESTING',
            new List<String>{'disaster recovery test', 'dr test', 'test.*disaster recovery'},
            'Salesforce tests DR at least once a year. Customers cannot specify the schedule.'));

        rules.add(binaryCan('DATA_EXPORT',
            new List<String>{'data export', 'data extraction', 'data portability', 'extract.*data.*end of contract'},
            'Salesforce returns data in .csv format at end of contract. Data export available via Export Services, Data Loader, APIs.'));

        rules.add(binaryCan('SUBPROCESSOR_LIST',
            new List<String>{'list of subcontract', 'list of subprocessor', 'subprocessor list', 'subcontractor list'},
            'A list of subcontractors and subprocessors can be provided. Salesforce can notify customers of changes but they cannot approve.'));

        // =================================================================
        // CONDITIONAL RULES
        // =================================================================

        // FIPS 140-2 — Gov Cloud only
        rules.add(new CapabilityRule('FIPS_GOV',
            new List<String>{'fips 140', 'fips-140', 'fips140'},
            'BINARY_CAN', null, null, 'GOV_CLOUD',
            'Salesforce US Government Cloud has been tested to ensure FIPS 140-2 compliance.'));
        rules.add(new CapabilityRule('FIPS_COMMERCIAL',
            new List<String>{'fips 140', 'fips-140', 'fips140'},
            'BINARY_CANNOT', null, null, 'COMMERCIAL',
            'FIPS 140-2 compliance is only available in US Government Cloud, not commercial environments.'));

        // US CITIZEN SUPPORT — Gov Cloud only
        rules.add(new CapabilityRule('CITIZEN_SUPPORT_GOV',
            new List<String>{'us citizen', 'citizen.*support', 'cleared.*support', 'citizenship of support'},
            'BINARY_CAN', null, null, 'GOV_CLOUD',
            'US Government Cloud guarantees citizenship of support staff.'));
        rules.add(new CapabilityRule('CITIZEN_SUPPORT_COMMERCIAL',
            new List<String>{'us citizen', 'citizen.*support', 'cleared.*support', 'citizenship of support'},
            'BINARY_CANNOT', null, null, 'COMMERCIAL',
            'Only US Government Cloud guarantees citizenship of support. Commercial environments have a global support model.'));

        // DATA RESIDENCY — conditional on country
        rules.add(new CapabilityRule(
            'DATA_RESIDENCY',
            new List<String>{'data residen', 'data sovereign', 'data locali', 'data location', 'hosted in', 'data center location', 'data stored', 'data must reside', 'data shall reside', 'data will reside', 'data reside'},
            'CONDITIONAL_DATA_RESIDENCY', null, null, null,
            'Salesforce hosts data in 18 Hyperforce regions: US, BR, CA, AU, IN, JP, SG, KR, FR, DE, SE, GB, ID, IE, IL, IT, CH, AE.'));

        // =================================================================
        // BINARY CAN DIFFERENTLY — Yellow flags
        // Salesforce meets the intent but not the explicit letter.
        // These produce Yellow with a pre-written alternative explanation.
        // =================================================================

        rules.add(binaryCanDifferently('WAF_ALTERNATIVE',
            new List<String>{'web application firewall', '\\bwaf\\b', 'application firewall'},
            'Salesforce utilizes Cloudflare for WAF, DDoS prevention, and IP reputation filtering at the platform edge. This is platform-managed and not customer-configurable. Customers requiring custom WAF rules should use third-party solutions in front of Experience Cloud sites.'));

        rules.add(binaryCanDifferently('ACCESSIBILITY_508',
            new List<String>{'section 508', '\\b508\\b.*compliance', '\\b508\\b.*conform', 'wcag 2', 'vpat', 'accessibility conformance'},
            'Salesforce publishes product-specific Accessibility Conformance Reports (ACRs) demonstrating substantial WCAG 2.1 Level A/AA conformance for Lightning Experience. Full 100% conformance is not claimed across all products and criteria. ACRs are available at salesforce.com/company/legal/508_accessibility/.'));

        rules.add(binaryCanDifferently('CDP_BACKUP',
            new List<String>{'near.zero rpo', 'zero rpo', 'continuous data protection', 'real.time backup', 'real.time replication', 'continuous backup'},
            'Salesforce standard RPO is 4 hours. For near-zero RPO, Salesforce Backup & Recover with Continuous Data Protection (add-on) is available. Customers can also implement their own backup strategy using Data Loader, APIs, or AppExchange partners (OwnBackup, Odaseva).'));

        rules.add(binaryCanDifferently('ENCRYPT_ALL_DATA',
            new List<String>{'encrypt all data.*rest', 'all data.*encrypt.*rest', 'full disk encryption', 'encrypt.*entire database'},
            'Shield Platform Encryption (add-on) provides AES-256 encryption at rest with customer key management. Hyperforce infrastructure provides disk-level encryption via AWS. Not all field types can be encrypted at the application layer even with Shield, but substantial coverage is achievable.'));

        rules.add(binaryCanDifferently('FILE_SCANNING',
            new List<String>{'virus', 'malware', 'antivirus', 'anti-virus', 'file scan.*upload', 'scan.*uploaded file', 'scan.*attachment'},
            'Salesforce does not natively scan customer-uploaded files. File scanning is available via AppExchange partners (e.g., WithSecure/F-Secure). Salesforce scans files attached to support cases via WithSecure as a sub-processor. Custom Apex triggers can also call external scanning APIs on file upload.'));

        rules.add(binaryCanDifferently('LOG_RETENTION_LONG',
            new List<String>{'retain.*log.*year', 'log.*retention.*year', 'log.*7 year', 'log.*5 year', 'log.*3 year', 'log.*10 year', 'retain.*audit.*year'},
            'Standard log retention: Login History 6 months, Setup Audit Trail 180 days, Field History 18 months. With Shield Event Monitoring (add-on), LoginEvent data is retained for 10 years natively. Other event types can be exported to external SIEM/storage for long-term retention.'));

        rules.add(binaryCanDifferently('SIEM_INTEGRATION',
            new List<String>{'siem integration', 'siem.*event', 'event.*siem', 'forward.*log.*siem', 'stream.*event.*siem', 'security information and event management'},
            'Infrastructure/OS/network logs are not available (multi-tenant SaaS). With Shield Event Monitoring (add-on), 20+ application event types can be streamed to external SIEM tools via the Streaming API. This covers login events, API events, report exports, permission changes, and more.'));

        rules.add(binaryCanDifferently('BACKGROUND_CHECK_GENERAL',
            new List<String>{'do you.*background check', 'does.*vendor.*background check', 'do.*staff.*background', 'do.*employee.*background', 'conduct.*background check', 'perform.*background check'},
            'Salesforce conducts background checks on employees per its own global policy. Customer-specific vetting standards, clearance levels, or sharing of background check results cannot be accommodated in a multi-tenant environment. For US federal customers, Government Cloud Plus meets NIST 800-53 personnel security controls via FedRAMP High authorization.'));

        rules.add(binaryCanDifferently('ESCROW_INTENT',
            new List<String>{'business continuity.*escrow', 'escrow.*business continuity', 'continuity.*source code', 'vendor.*viability', 'vendor.*bankruptcy', 'vendor.*exit strategy'},
            'Source code escrow is inapplicable to SaaS. The business continuity intent is met through: (1) data is always exportable via APIs, Data Loader, and weekly export services; (2) Salesforce\'s financial stability as a publicly traded company; (3) SOC 2, ISO 27001, and other compliance attestations demonstrate operational resilience.'));

        rules.add(binaryCanDifferently('VULN_SCAN_RESULTS',
            new List<String>{'vulnerability.*report', 'penetration test.*report', 'pen test.*report', 'security assessment.*report', 'share.*scan.*result', 'provide.*scan.*result'},
            'Raw vulnerability scan data and audit workpapers are not shared. Executive summary penetration test and vulnerability assessment reports are available via the Salesforce Trust and Compliance portal (compliance.salesforce.com). For Government Cloud Plus customers, FedRAMP POA&M documentation is available.'));

        return rules;
    }

    // =========================================================================
    // RULE BUILDER HELPERS
    // =========================================================================

    private static CapabilityRule numericMin(String id, List<String> keywords,
        Decimal threshold, String unit, String reason
    ) {
        return new CapabilityRule(id, keywords, 'NUMERIC_MIN', threshold, unit, null, reason);
    }

    private static CapabilityRule numericMax(String id, List<String> keywords,
        Decimal threshold, String unit, String reason
    ) {
        return new CapabilityRule(id, keywords, 'NUMERIC_MAX', threshold, unit, null, reason);
    }

    private static CapabilityRule binaryCannot(String id, List<String> keywords, String reason) {
        return new CapabilityRule(id, keywords, 'BINARY_CANNOT', null, null, null, reason);
    }

    private static CapabilityRule binaryCan(String id, List<String> keywords, String reason) {
        return new CapabilityRule(id, keywords, 'BINARY_CAN', null, null, null, reason);
    }

    private static CapabilityRule binaryCanDifferently(String id, List<String> keywords, String reason) {
        return new CapabilityRule(id, keywords, 'BINARY_CAN_DIFFERENTLY', null, null, null, reason);
    }

    /**
     * Creates a BINARY_CANNOT rule with exclusion keywords.
     * If the question matches a keyword BUT also matches an exclude keyword,
     * the rule is skipped — preventing false positives from negated context.
     * Example: "no on-premises" contains "on-premises" but the negation means
     * the customer is explicitly NOT asking for on-prem.
     */
    private static CapabilityRule binaryCannotWithExclusions(
        String id, List<String> keywords, List<String> excludeKeywords, String reason
    ) {
        CapabilityRule rule = new CapabilityRule(id, keywords, 'BINARY_CANNOT', null, null, null, reason);
        rule.excludeKeywords = excludeKeywords;
        return rule;
    }

    // =========================================================================
    // INNER CLASSES
    // =========================================================================

    @TestVisible
    private class CapabilityRule {
        public String id;
        public List<String> keywords;
        public String ruleType;         // BINARY_CANNOT, BINARY_CAN, BINARY_CAN_DIFFERENTLY, NUMERIC_MIN, NUMERIC_MAX, CONDITIONAL_DATA_RESIDENCY
        public Decimal numericThreshold;
        public String numericUnit;
        public String productFilter;    // null = all, GOV_CLOUD, COMMERCIAL
        public String reason;
        public List<String> excludeKeywords;

        public CapabilityRule(String id, List<String> keywords, String ruleType,
            Decimal numericThreshold, String numericUnit, String productFilter, String reason
        ) {
            this.id = id;
            this.keywords = keywords;
            this.ruleType = ruleType;
            this.numericThreshold = numericThreshold;
            this.excludeKeywords = new List<String>();
            this.numericUnit = numericUnit;
            this.productFilter = productFilter;
            this.reason = reason;
        }
    }

    @TestVisible
    private class FlagDecision {
        public String flag;
        public String reason;
        public String ruleId;

        public FlagDecision() {
            this.flag = FLAG_YELLOW;
            this.reason = '';
            this.ruleId = '';
        }
    }
}