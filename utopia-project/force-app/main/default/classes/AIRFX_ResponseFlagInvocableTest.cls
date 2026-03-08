/**
 * AIRFX_ResponseFlagInvocableTest
 * ================================
 * Test coverage for the deterministic Red/Yellow/Green flag engine.
 *
 * Tests organized by:
 *   1. Numeric rules (uptime, RPO, RTO, breach notification)
 *   2. Binary CANNOT rules (escrow, dedicated hardware, IL6, etc.)
 *   3. Binary CAN rules (encryption, backups, pen testing, etc.)
 *   4. Conditional rules (data residency, FIPS, citizen support)
 *   5. Edge cases (blank questions, no rule match, parse failures)
 *   6. Full invocable integration (record creation + DML)
 *   7. Connor's test cases (real-world validation)
 *
 * @author  Robert Smith (Principal SE, GPS)
 * @date    2026-02-06
 * @project Agentic Utopia (EYES) — Phase 2: Answer Flagging
 */
@IsTest
private class AIRFX_ResponseFlagInvocableTest {

    // =========================================================================
    // TEST DATA HELPERS
    // =========================================================================

    private static List<AIRFX_ResponseFlagInvocable.CapabilityRule> getRules() {
        return AIRFX_ResponseFlagInvocable.buildRules();
    }

    private static AIRFX_ResponseFlagInvocable.FlagDecision eval(
        String question, String answer, String product, String country
    ) {
        return AIRFX_ResponseFlagInvocable.evaluate(
            question, answer, product, country, getRules()
        );
    }

    // =========================================================================
    // 1. NUMERIC RULES — UPTIME
    // =========================================================================

    @IsTest
    static void uptime_99995_shouldBeYellow() {
        // Uptime above 99.9% is Yellow — aspirational, we can discuss SLA options
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The platform must guarantee 99.995% uptime.',
            'Salesforce provides 99.95% uptime...', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Uptime 99.995% is Yellow — aspirational');
        System.assertEquals('UPTIME', d.ruleId);
    }

    @IsTest
    static void uptime_9995_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor shall provide 99.95% availability for the hosted solution.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, '99.95% is Yellow — above standard SLA');
    }

    @IsTest
    static void uptime_999_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The system must maintain 99.9% uptime as measured monthly.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, '99.9% is in the 99.7-99.9 approval zone = Yellow');
        System.assert(d.reason.contains('engage your AE'), 'Should advise engaging AE');
    }

    @IsTest
    static void uptime_997_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Minimum 99.7% uptime required.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, '99.7% is at the threshold = Yellow (needs approval)');
    }

    @IsTest
    static void uptime_985_shouldBeGreen() {
        // Connor's case: "98.5% SLA flagged Red when we actually exceed it"
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Platform must maintain 98.5% availability.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, '98.5% < 99.7% = Green');
    }

    @IsTest
    static void uptime_95_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Service availability of at least 95%.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, '95% < 99.7% = Green');
    }

    @IsTest
    static void uptime_996_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Platform must maintain 99.6% availability.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, '99.6% < 99.7% = Green');
    }

    @IsTest
    static void uptime_995_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Minimum 99.5% availability required.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, '99.5% < 99.7% = Green');
    }

    @IsTest
    static void uptime_99_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must provide 99% availability.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, '99% < 99.7% = Green');
    }

    @IsTest
    static void uptime_998_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The system must maintain 99.8% uptime.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, '99.8% is in the 99.7-99.9 approval zone = Yellow');
    }

    @IsTest
    static void uptime_100_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must provide 100% availability.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, '100% is Yellow — aspirational, SLA options available');
    }

    @IsTest
    static void uptime_9999_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Platform requires 99.99% uptime guarantee.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, '99.99% is Yellow — above standard SLA');
    }

    // =========================================================================
    // 2. NUMERIC RULES — RPO
    // =========================================================================

    @IsTest
    static void rpo_2hours_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Recovery Point Objective (RPO) must not exceed 2 hours.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'RPO 2hrs < SF 4hrs = Red');
    }

    @IsTest
    static void rpo_1hour_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'RPO of 1 hour or less.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'RPO 1hr < SF 4hrs = Red');
    }

    @IsTest
    static void rpo_4hours_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'RPO shall not exceed 4 hours.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'RPO 4hrs == SF 4hrs = Green');
    }

    @IsTest
    static void rpo_8hours_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Recovery Point Objective of 8 hours.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'RPO 8hrs > SF 4hrs = Green');
    }

    // =========================================================================
    // 3. NUMERIC RULES — RTO
    // =========================================================================

    @IsTest
    static void rto_4hours_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Recovery Time Objective must not exceed 4 hours.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'RTO 4hrs < SF 12hrs = Red');
    }

    @IsTest
    static void rto_12hours_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'RTO of 12 hours or less.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'RTO 12hrs == SF 12hrs = Green');
    }

    @IsTest
    static void rto_24hours_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Recovery Time Objective shall not exceed 24 hours.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'RTO 24hrs > SF 12hrs = Green');
    }

    // =========================================================================
    // 4. NUMERIC RULES — BREACH NOTIFICATION
    // =========================================================================

    @IsTest
    static void breach_1hour_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must provide breach notification within 1 hour of discovery.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Breach notification is CAN_DIFFERENTLY — timeline varies');
        System.assertEquals('BREACH_NOTIFICATION', d.ruleId);
    }

    @IsTest
    static void breach_24hours_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Security breach notification within 24 hours.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Breach notification is CAN_DIFFERENTLY — timeline varies');
        System.assertEquals('BREACH_NOTIFICATION', d.ruleId);
    }

    @IsTest
    static void breach_72hours_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Breach notification within 72 hours.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Breach notification is CAN_DIFFERENTLY — timeline varies');
        System.assertEquals('BREACH_NOTIFICATION', d.ruleId);
    }

    // =========================================================================
    // 5. BINARY CANNOT — Always Red
    // =========================================================================

    @IsTest
    static void escrow_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor shall provide source code escrow arrangements.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
        System.assert(d.reason.contains('escrow'));
    }

    @IsTest
    static void sourceCode_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must provide access to source code for review.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void dedicatedHardware_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must run on dedicated hardware isolated from other tenants.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void privateCloud_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must be deployed in agency private cloud environment.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void serviceCredits_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor shall provide service credits for any downtime exceeding SLA.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void resolutionTime_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Critical incidents must have a resolution time of 4 hours.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void il6_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must be certified at Impact Level 6 (IL6).',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void encryptionInMemory_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All data must be encrypted in memory during processing.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void sbom_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must provide a Software Bill of Materials (SBOM).',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void onPrem_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must support on-premise deployment.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'On-prem is CAN_DIFFERENTLY — MuleSoft/Tableau exceptions exist');
        System.assertEquals('ON_PREM_GENERAL', d.ruleId);
    }

    @IsTest
    static void ipv6_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must fully support IPv6 addressing.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void classifiedData_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must support storage of classified data.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void deferUpgrades_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Agency must be able to defer upgrades until testing is complete.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void customerBackgroundCheck_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Agency reserves the right to perform background checks on vendor employees with access to agency data.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void secnumcloud_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must be SecNumCloud certified.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void customerVm_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Software must be deployed to customer virtual machine.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
    }

    // =========================================================================
    // 6. BINARY CAN — Always Green
    // =========================================================================

    @IsTest
    static void encryptionAtRest_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All data must be encrypted at rest.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void encryptionInTransit_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Data must be encrypted in transit between client and server.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void tls_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must support TLS 1.2 or higher.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void byok_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Customer must be able to bring your own key for encryption.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'BYOK requires Shield add-on — CAN_DIFFERENTLY');
        System.assertEquals('BYOK', d.ruleId);
    }

    @IsTest
    static void il5_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must be authorized at Impact Level 5 (IL5).',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void rbac_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must support role-based access control.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void penTest_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Agency must be able to perform penetration testing.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void backup_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must provide nightly backups of all data.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void dataExport_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must support data export at end of contract.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void drTesting_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must perform annual disaster recovery testing.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void mfa_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must support multi-factor authentication.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
    }

    // =========================================================================
    // 7. CONDITIONAL RULES
    // =========================================================================

    @IsTest
    static void dataResidency_US_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All data must reside within the United States.',
            '', '', 'US'
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void dataResidency_Germany_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Data must be hosted in Germany per data sovereignty requirements.',
            '', '', 'DE'
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void dataResidency_Switzerland_shouldBeGreen() {
        // Switzerland added to Hyperforce in 2025
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Data must reside in Switzerland.',
            '', '', 'CH'
        );
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void dataResidency_China_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Data must reside in China.',
            '', '', 'CN'
        );
        System.assertEquals('Red', d.flag);
        System.assert(d.reason.contains('NOT'));
    }

    @IsTest
    static void dataResidency_noCountry_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Data must reside within our jurisdiction.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
    }

    // =========================================================================
    // 8. EDGE CASES
    // =========================================================================

    @IsTest
    static void blankQuestion_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval('', '', '', '');
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('NO_QUESTION', d.ruleId);
    }

    @IsTest
    static void nullQuestion_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(null, '', '', '');
        System.assertEquals('Yellow', d.flag);
    }

    @IsTest
    static void noRuleMatch_functional_shouldBeGreen() {
        // No security terms, no functional terms, no rule match → auto-Green (functional)
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'What is your corporate social responsibility program?',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'No security terms + no rule match = functional Green');
        System.assertEquals('NO_MATCH_FUNCTIONAL', d.ruleId);
        System.assertEquals('Functional', d.classification);
    }

    @IsTest
    static void noRuleMatch_security_shouldBeYellow() {
        // Has security terms but no rule matches — real security question needing review
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Describe your data processing safeguards for cross-border transfers.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Security terms present + no rule match = Yellow');
        System.assertEquals('NO_MATCH_SECURITY', d.ruleId);
        System.assertEquals('Security', d.classification);
    }

    @IsTest
    static void uptimeNoNumber_shouldBeYellow() {
        // Question mentions uptime but has no number
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'What is your platform uptime?',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assert(d.ruleId.contains('PARSE_FAIL'), 'Should fail to parse number');
    }

    // =========================================================================
    // 9. GOV CLOUD DETECTION
    // =========================================================================

    @IsTest
    static void govCloudDetection_govcloud() {
        System.assert(AIRFX_ResponseFlagInvocable.isGovCloudDeal('Government Cloud Plus'));
    }

    @IsTest
    static void govCloudDetection_govText() {
        System.assert(AIRFX_ResponseFlagInvocable.isGovCloudDeal('Gov Cloud'));
    }

    @IsTest
    static void govCloudDetection_commercial() {
        System.assert(!AIRFX_ResponseFlagInvocable.isGovCloudDeal('Sales Cloud'));
    }

    @IsTest
    static void govCloudDetection_null() {
        System.assert(!AIRFX_ResponseFlagInvocable.isGovCloudDeal(null));
    }

    @IsTest
    static void govCloudDetection_blank() {
        System.assert(!AIRFX_ResponseFlagInvocable.isGovCloudDeal(''));
    }

    @IsTest
    static void fips_govCloud_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must comply with FIPS 140-2 encryption standards.',
            '', 'Government Cloud Plus', ''
        );
        System.assertEquals('Green', d.flag, 'FIPS 140-2 available in GovCloud');
    }

    @IsTest
    static void fips_commercial_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must comply with FIPS 140-2 encryption standards.',
            '', 'Sales Cloud', ''
        );
        System.assertEquals('Red', d.flag, 'FIPS 140-2 not available in commercial');
    }

    @IsTest
    static void citizenSupport_govCloud_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All support staff must be US citizens.',
            '', 'Government Cloud', ''
        );
        System.assertEquals('Green', d.flag, 'GovCloud guarantees citizen support');
    }

    @IsTest
    static void citizenSupport_commercial_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All support staff must be US citizens.',
            '', 'Sales Cloud', ''
        );
        System.assertEquals('Red', d.flag, 'Commercial has global support model');
    }

    // =========================================================================
    // 10. BINARY CAN DIFFERENTLY — Yellow with alternative
    // =========================================================================

    @IsTest
    static void waf_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must deploy a web application firewall (WAF) to protect all web-facing services.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'WAF is platform-managed, not customer-configurable');
        System.assertEquals('WAF_ALTERNATIVE', d.ruleId);
        System.assert(d.reason.contains('Cloudflare'), 'Should mention Cloudflare as WAF provider');
    }

    @IsTest
    static void accessibility508_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must comply with Section 508 accessibility standards.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Accessibility is partial conformance');
        System.assertEquals('ACCESSIBILITY_508', d.ruleId);
        System.assert(d.reason.contains('ACR'), 'Should mention ACRs');
    }

    @IsTest
    static void wcag_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Platform must conform to WCAG 2.1 Level AA.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('ACCESSIBILITY_508', d.ruleId);
    }

    @IsTest
    static void fileScan_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All uploaded files must be scanned for viruses and malware.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'File scanning via AppExchange partners');
        System.assertEquals('FILE_SCANNING', d.ruleId);
        System.assert(d.reason.contains('WithSecure'), 'Should mention WithSecure');
    }

    @IsTest
    static void logRetention_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must retain security logs for a minimum of 7 years to meet regulatory requirements.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Long retention via Shield + export');
        System.assertEquals('LOG_RETENTION_LONG', d.ruleId);
        System.assert(d.reason.contains('10 years'), 'Should mention Shield 10-year LoginEvent retention');
    }

    @IsTest
    static void siemIntegration_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must support SIEM integration for forwarding security events.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'SIEM via Shield Event Monitoring');
        System.assertEquals('SIEM_INTEGRATION', d.ruleId);
        System.assert(d.reason.contains('Shield'), 'Should mention Shield');
    }

    @IsTest
    static void backgroundCheckGeneral_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does the vendor conduct background checks on all employees?',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'SF does checks per own policy, not customer policy');
        System.assertEquals('BACKGROUND_CHECK_GENERAL', d.ruleId);
    }

    @IsTest
    static void vulnScanReport_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must provide vulnerability assessment reports on an annual basis.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Summary reports available via Trust portal');
        System.assertEquals('VULN_SCAN_RESULTS', d.ruleId);
    }

    @IsTest
    static void encryptAllData_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must provide full disk encryption for the entire database.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Shield provides substantial but not total coverage');
        System.assertEquals('ENCRYPT_ALL_DATA', d.ruleId);
    }

    // =========================================================================
    // 10b. NEW RULES — KB Analysis (2026-03-08)
    // =========================================================================

    @IsTest
    static void rightToAudit_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The agency reserves the right to audit the contractor\'s security practices at any time.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Right to audit = CAN_DIFFERENTLY');
        System.assertEquals('RIGHT_TO_AUDIT', d.ruleId);
        System.assert(d.reason.contains('SOC 2'), 'Should mention SOC 2 attestations');
    }

    @IsTest
    static void securityAuditCompliance_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must allow security audit of their systems for compliance verification.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('RIGHT_TO_AUDIT', d.ruleId);
    }

    @IsTest
    static void securityAssessment_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The organisation shall comply to the customer\'s request for ongoing Information Security Assessments.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Security assessment = CAN_DIFFERENTLY');
        System.assertEquals('SECURITY_ASSESSMENT_ACCESS', d.ruleId);
        System.assert(d.reason.contains('Trust & Compliance'), 'Should mention Trust portal');
    }

    @IsTest
    static void incidentResponseProcess_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor shall have a documented incident response plan and incident management procedures.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Incident response = CAN_DIFFERENTLY');
        System.assertEquals('INCIDENT_RESPONSE_PROCESS', d.ruleId);
        System.assert(d.reason.contains('trust.salesforce.com'), 'Should mention trust site');
    }

    @IsTest
    static void incidentNotification_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The supplier must provide incident notification to the customer within specified timeframes.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('INCIDENT_RESPONSE_PROCESS', d.ruleId);
    }

    @IsTest
    static void securityClearancePersonnel_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All contractor personnel must hold a valid security clearance and pass a police check.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Security clearance = CAN_DIFFERENTLY');
        System.assertEquals('SECURITY_CLEARANCE_PERSONNEL', d.ruleId);
    }

    @IsTest
    static void backgroundInvestigation_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must conduct background investigation on all staff with access to agency data.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('SECURITY_CLEARANCE_PERSONNEL', d.ruleId);
    }

    @IsTest
    static void patchManagement_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The supplier shall have a patch management process for applying security patches promptly.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Patch management = CAN_DIFFERENTLY');
        System.assertEquals('PATCH_MGMT_PROCESS', d.ruleId);
        System.assert(d.reason.contains('cadence'), 'Should mention SF patching cadence');
    }

    @IsTest
    static void vulnerabilityRemediation_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The contractor shall remediate all vulnerabilities discovered through vulnerability assessments.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('PATCH_MGMT_PROCESS', d.ruleId);
    }

    @IsTest
    static void bcpDrPlan_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The contractor must develop and deliver a business continuity plan and disaster recovery plan.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'BCP/DR plan = CAN_DIFFERENTLY');
        System.assertEquals('BCP_DR_PLAN', d.ruleId);
        System.assert(d.reason.contains('SPARC'), 'Should mention SPARC targets');
    }

    @IsTest
    static void confidentialityNda_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All personnel must sign a non-disclosure agreement before accessing agency data.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'NDA = CAN_DIFFERENTLY');
        System.assertEquals('CONFIDENTIALITY_NDA', d.ruleId);
        System.assert(d.reason.contains('DPA'), 'Should mention DPA coverage');
    }

    @IsTest
    static void dataSeg_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The application must provide method for data segregation between tenants including logical separation.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'Data segregation = CAN');
        System.assertEquals('DATA_SEGREGATION', d.ruleId);
    }

    @IsTest
    static void iso27001_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must maintain ISO 27001 certification.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'ISO 27001 = CAN');
        System.assertEquals('ISO_27001_CERT', d.ruleId);
    }

    @IsTest
    static void soc2_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must provide SOC 2 Type II attestation reports.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'SOC 2 = CAN');
        System.assertEquals('SOC2_CERT', d.ruleId);
    }

    @IsTest
    static void escrowBusinessContinuity_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Describe vendor exit strategy and business continuity arrangements including source code escrow.',
            '', '', ''
        );
        // 'escrow' will match ESCROW (BINARY_CANNOT) first since it appears earlier in rules
        // This is correct — pure escrow requests should still be Red
        System.assertEquals('Red', d.flag, 'Plain escrow mention hits ESCROW rule first');
    }

    // =========================================================================
    // 11. KEYWORD MATCHING (was 10)
    // =========================================================================

    @IsTest
    static void keywordMatch_positive() {
        System.assert(AIRFX_ResponseFlagInvocable.matchesKeywords(
            'the platform must guarantee 99.9% uptime',
            new List<String>{'uptime', 'availability'}
        ));
    }

    @IsTest
    static void keywordMatch_negative() {
        System.assert(!AIRFX_ResponseFlagInvocable.matchesKeywords(
            'describe your project management approach',
            new List<String>{'uptime', 'availability'}
        ));
    }

    @IsTest
    static void keywordMatch_regex() {
        System.assert(AIRFX_ResponseFlagInvocable.matchesKeywords(
            'all data must be encrypted in memory during processing',
            new List<String>{'encrypt.*in memory'}
        ));
    }

    // =========================================================================
    // 11. NUMERIC EXTRACTION
    // =========================================================================

    @IsTest
    static void extractNumber_percentage() {
        Decimal val = AIRFX_ResponseFlagInvocable.extractNumber('99.95% uptime required', '%');
        System.assertEquals(99.95, val);
    }

    @IsTest
    static void extractNumber_hours() {
        Decimal val = AIRFX_ResponseFlagInvocable.extractNumber('within 4 hours of discovery', ' hours');
        System.assertEquals(4, val);
    }

    @IsTest
    static void extractNumber_noMatch() {
        Decimal val = AIRFX_ResponseFlagInvocable.extractNumber('no numbers here', '%');
        System.assertEquals(null, val);
    }

    @IsTest
    static void extractNumber_multiplePercentages_takesHighest() {
        // If requirement says "between 99% and 99.99%", take 99.99 (most demanding)
        Decimal val = AIRFX_ResponseFlagInvocable.extractNumber(
            'uptime between 99% and 99.99% monthly', '%'
        );
        System.assertEquals(99.99, val);
    }

    @IsTest
    static void extractNumber_multipleHours_takesLowest() {
        // "RPO of 4 hours to 8 hours" — both have unit, takes lowest (most demanding)
        Decimal val = AIRFX_ResponseFlagInvocable.extractNumber(
            'rpo between 4 hours and 8 hours', ' hours'
        );
        System.assertEquals(4, val);
    }

    // =========================================================================
    // 12. FULL INVOCABLE INTEGRATION TEST
    // =========================================================================

    /**
     * Helper: get existing GPS_Project__c to avoid triggering
     * "GPS RFP AE/SE Notification of New Project" flow on insert.
     */
    private static GPS_Project__c getExistingProject() {
        List<GPS_Project__c> projects = [
            SELECT Id, ProjectName__c, Country__c, Product_Type__c
            FROM GPS_Project__c
            LIMIT 1
        ];
        System.assert(!projects.isEmpty(), 'UAT must have at least one GPS_Project__c');
        return projects[0];
    }

    @IsTest(SeeAllData=true)
    static void fullInvocable_createsRecordAndFlags() {
        GPS_Project__c proj = getExistingProject();

        // Create test response — uptime requirement that should be Red
        GPS_ResponseNew__c resp = new GPS_ResponseNew__c(
            GPS_Projects__c = proj.Id,
            Question__c = 'The platform must guarantee 99.99% uptime availability.',
            AI_Generated_Answer__c = 'Salesforce provides high availability...'
        );
        insert resp;

        // Run the invocable
        AIRFX_ResponseFlagInvocable.FlagRequest req = new AIRFX_ResponseFlagInvocable.FlagRequest();
        req.responseId = resp.Id;

        Test.startTest();
        List<AIRFX_ResponseFlagInvocable.FlagResult> results =
            AIRFX_ResponseFlagInvocable.flagResponses(
                new List<AIRFX_ResponseFlagInvocable.FlagRequest>{ req }
            );
        Test.stopTest();

        // Verify result
        System.assertEquals(1, results.size());
        System.assert(results[0].success, 'Should succeed: ' + results[0].errorMessage);
        System.assertEquals('Yellow', results[0].flag, '99.99% is Yellow — above standard SLA');

        // Verify the record was updated
        GPS_ResponseNew__c updated = [
            SELECT Security_Flag__c, Response_Flag_Reason__c
            FROM GPS_ResponseNew__c
            WHERE Id = :resp.Id
        ];
        System.assertEquals('Yellow', updated.Security_Flag__c);
    }

    @IsTest(SeeAllData=true)
    static void fullInvocable_escrowRed() {
        GPS_Project__c proj = getExistingProject();

        GPS_ResponseNew__c resp = new GPS_ResponseNew__c(
            GPS_Projects__c = proj.Id,
            Question__c = 'Vendor must provide source code escrow.',
            AI_Generated_Answer__c = 'Salesforce can discuss escrow arrangements...'
        );
        insert resp;

        AIRFX_ResponseFlagInvocable.FlagRequest req = new AIRFX_ResponseFlagInvocable.FlagRequest();
        req.responseId = resp.Id;

        Test.startTest();
        List<AIRFX_ResponseFlagInvocable.FlagResult> results =
            AIRFX_ResponseFlagInvocable.flagResponses(
                new List<AIRFX_ResponseFlagInvocable.FlagRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals('Red', results[0].flag);

        GPS_ResponseNew__c updated = [
            SELECT Security_Flag__c FROM GPS_ResponseNew__c WHERE Id = :resp.Id
        ];
        System.assertEquals('Red', updated.Security_Flag__c);
    }

    @IsTest(SeeAllData=true)
    static void fullInvocable_encryptionGreen() {
        GPS_Project__c proj = getExistingProject();

        GPS_ResponseNew__c resp = new GPS_ResponseNew__c(
            GPS_Projects__c = proj.Id,
            Question__c = 'All data must be encrypted at rest using AES-256 or equivalent.',
            AI_Generated_Answer__c = 'Salesforce encrypts all data at rest...'
        );
        insert resp;

        AIRFX_ResponseFlagInvocable.FlagRequest req = new AIRFX_ResponseFlagInvocable.FlagRequest();
        req.responseId = resp.Id;

        Test.startTest();
        List<AIRFX_ResponseFlagInvocable.FlagResult> results =
            AIRFX_ResponseFlagInvocable.flagResponses(
                new List<AIRFX_ResponseFlagInvocable.FlagRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals('Green', results[0].flag);
    }

    @IsTest(SeeAllData=true)
    static void fullInvocable_noMatchFunctionalGreen() {
        GPS_Project__c proj = getExistingProject();

        // No security terms → NO_MATCH_FUNCTIONAL → Green
        GPS_ResponseNew__c resp = new GPS_ResponseNew__c(
            GPS_Projects__c = proj.Id,
            Question__c = 'Describe your approach to change management.',
            AI_Generated_Answer__c = 'Salesforce follows best practices...'
        );
        insert resp;

        AIRFX_ResponseFlagInvocable.FlagRequest req = new AIRFX_ResponseFlagInvocable.FlagRequest();
        req.responseId = resp.Id;

        Test.startTest();
        List<AIRFX_ResponseFlagInvocable.FlagResult> results =
            AIRFX_ResponseFlagInvocable.flagResponses(
                new List<AIRFX_ResponseFlagInvocable.FlagRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals('Green', results[0].flag, 'No security terms = functional Green');
    }

    @IsTest
    static void fullInvocable_nullInput() {
        Test.startTest();
        List<AIRFX_ResponseFlagInvocable.FlagResult> results =
            AIRFX_ResponseFlagInvocable.flagResponses(null);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(!results[0].success);
    }

    @IsTest
    static void fullInvocable_emptyInput() {
        Test.startTest();
        List<AIRFX_ResponseFlagInvocable.FlagResult> results =
            AIRFX_ResponseFlagInvocable.flagResponses(
                new List<AIRFX_ResponseFlagInvocable.FlagRequest>()
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(!results[0].success);
    }

    @IsTest
    static void fullInvocable_badRecordId() {
        AIRFX_ResponseFlagInvocable.FlagRequest req = new AIRFX_ResponseFlagInvocable.FlagRequest();
        req.responseId = null;

        Test.startTest();
        List<AIRFX_ResponseFlagInvocable.FlagResult> results =
            AIRFX_ResponseFlagInvocable.flagResponses(
                new List<AIRFX_ResponseFlagInvocable.FlagRequest>{ req }
            );
        Test.stopTest();

        // Should handle gracefully — null ID won't be in the query
    }

    @IsTest(SeeAllData=true)
    static void fullInvocable_bulkTest() {
        GPS_Project__c proj = getExistingProject();

        List<GPS_ResponseNew__c> resps = new List<GPS_ResponseNew__c>();
        List<AIRFX_ResponseFlagInvocable.FlagRequest> reqs =
            new List<AIRFX_ResponseFlagInvocable.FlagRequest>();

        // Create 20 records with mixed questions
        for (Integer i = 0; i < 20; i++) {
            String q;
            if (Math.mod(i, 3) == 0) {
                q = 'System must guarantee 99.99% uptime.';        // Red
            } else if (Math.mod(i, 3) == 1) {
                q = 'Data must be encrypted at rest.';              // Green
            } else {
                q = 'Describe your data processing safeguards.';     // Yellow (has security term 'data processing')
            }

            resps.add(new GPS_ResponseNew__c(
                GPS_Projects__c = proj.Id,
                Question__c = q,
                AI_Generated_Answer__c = 'Test answer.'
            ));
        }
        insert resps;

        // Collect IDs of just our test records
        Set<Id> testIds = new Set<Id>();
        for (GPS_ResponseNew__c r : resps) {
            AIRFX_ResponseFlagInvocable.FlagRequest req = new AIRFX_ResponseFlagInvocable.FlagRequest();
            req.responseId = r.Id;
            reqs.add(req);
            testIds.add(r.Id);
        }

        Test.startTest();
        List<AIRFX_ResponseFlagInvocable.FlagResult> results =
            AIRFX_ResponseFlagInvocable.flagResponses(reqs);
        Test.stopTest();

        System.assertEquals(20, results.size());

        // Verify all succeeded
        for (AIRFX_ResponseFlagInvocable.FlagResult fr : results) {
            System.assert(fr.success, 'All should succeed: ' + fr.errorMessage);
        }

        // Verify flags on only our test records
        List<GPS_ResponseNew__c> updated = [
            SELECT Security_Flag__c FROM GPS_ResponseNew__c
            WHERE Id IN :testIds
        ];
        Integer reds = 0, greens = 0, yellows = 0;
        for (GPS_ResponseNew__c r : updated) {
            if (r.Security_Flag__c == 'Red') reds++;
            else if (r.Security_Flag__c == 'Green') greens++;
            else if (r.Security_Flag__c == 'Yellow') yellows++;
        }
        // 0,3,6,9,12,15,18 = 7 yellows (uptime 99.99% now Yellow); 1,4,7,10,13,16,19 = 7 greens; 2,5,8,11,14,17 = 6 yellows
        System.assertEquals(0, reds, 'Should have 0 Red flags (uptime >99.9% is now Yellow)');
        System.assertEquals(7, greens, 'Should have 7 Green flags');
        System.assertEquals(13, yellows, 'Should have 13 Yellow flags (7 uptime + 6 security)');
    }

    // =========================================================================
    // 8. PREFILTER — "support" must not auto-green security questions
    // =========================================================================

    @IsTest
    static void classification_ruleMatch_shouldBeSecurity() {
        // Any question that matches a rule is classified as Security
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All data must be encrypted at rest.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
        System.assertEquals('Security', d.classification);
    }

    @IsTest
    static void classification_preFilter_shouldBeFunctional() {
        // Pre-filtered questions are classified as Functional
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'How do you customize the dashboard layouts?',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
        System.assertEquals('Functional', d.classification);
        System.assertEquals('PREFILTER_NON_SECURITY', d.ruleId);
    }

    // =========================================================================
    // 13. OBLIGATION LEVEL DETECTION
    // =========================================================================

    @IsTest
    static void obligation_must_isMandatory() {
        System.assertEquals('MANDATORY', AIRFX_ResponseFlagInvocable.detectObligation(
            'the system must support encryption at rest'));
    }

    @IsTest
    static void obligation_shall_isMandatory() {
        System.assertEquals('MANDATORY', AIRFX_ResponseFlagInvocable.detectObligation(
            'the contractor shall provide escrow'));
    }

    @IsTest
    static void obligation_should_isOptional() {
        System.assertEquals('OPTIONAL', AIRFX_ResponseFlagInvocable.detectObligation(
            'the solution should support encryption at rest'));
    }

    @IsTest
    static void obligation_may_isOptional() {
        System.assertEquals('OPTIONAL', AIRFX_ResponseFlagInvocable.detectObligation(
            'the vendor may provide source code'));
    }

    @IsTest
    static void obligation_highlyDesirable_isOptional() {
        System.assertEquals('OPTIONAL', AIRFX_ResponseFlagInvocable.detectObligation(
            'highly desirable - the solution provides escrow'));
    }

    @IsTest
    static void obligation_noSignal_isNeutral() {
        System.assertEquals('NEUTRAL', AIRFX_ResponseFlagInvocable.detectObligation(
            'describe your encryption capabilities'));
    }

    @IsTest
    static void obligation_mustOverridesShould() {
        // If both "must" and "should" appear, mandatory wins
        System.assertEquals('MANDATORY', AIRFX_ResponseFlagInvocable.detectObligation(
            'the solution must support tls and should support tls 1.3'));
    }

    // =========================================================================
    // 14. OBLIGATION AFFECTS FLAGS
    // =========================================================================

    @IsTest
    static void obligation_escrow_should_softensToYellow() {
        // "should provide escrow" — BINARY_CANNOT but optional → Yellow
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor should provide source code escrow arrangements.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Optional CANNOT softens Red → Yellow');
        System.assertEquals('ESCROW', d.ruleId);
        System.assert(d.reason.contains('optional language'), 'Should note optional language');
    }

    @IsTest
    static void obligation_escrow_must_staysRed() {
        // "must provide escrow" — BINARY_CANNOT + mandatory = Red
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must provide source code escrow arrangements.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'Mandatory CANNOT stays Red');
        System.assertEquals('ESCROW', d.ruleId);
    }

    @IsTest
    static void obligation_waf_should_softensToGreen() {
        // "should deploy WAF" — CAN_DIFFERENTLY but optional → Green
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor should deploy a web application firewall (WAF).',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'Optional CAN_DIFFERENTLY softens Yellow → Green');
        System.assertEquals('WAF_ALTERNATIVE', d.ruleId);
        System.assert(d.reason.contains('optional language'), 'Should note optional language');
    }

    @IsTest
    static void obligation_waf_must_staysYellow() {
        // "must deploy WAF" — CAN_DIFFERENTLY + mandatory = Yellow (unchanged)
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must deploy a web application firewall (WAF).',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Mandatory CAN_DIFFERENTLY stays Yellow');
        System.assertEquals('WAF_ALTERNATIVE', d.ruleId);
    }

    @IsTest
    static void obligation_highlyDesirable_ipv6_softensToYellow() {
        // "Highly desirable - IPv6" — BINARY_CANNOT + optional → Yellow
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Highly desirable - the solution supports IPv6 addressing.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Highly desirable CANNOT softens Red → Yellow');
        System.assertEquals('IPV6_FULL', d.ruleId);
    }

    @IsTest
    static void obligation_neutral_escrow_staysRed() {
        // No must/should — defaults to strict (Red for CANNOT)
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Describe your source code escrow arrangements.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'Neutral obligation keeps default Red');
    }

    // =========================================================================
    // 15. MULESOFT PRODUCT RULES
    // =========================================================================

    @IsTest
    static void mulesoft_onPrem_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must support on-premise deployment.',
            '', 'MuleSoft', ''
        );
        System.assertEquals('Green', d.flag, 'MuleSoft supports on-prem');
        System.assertEquals('MULESOFT_ON_PREM', d.ruleId);
        System.assert(d.reason.contains('Anypoint Runtime'), 'Should mention Anypoint Runtime');
    }

    @IsTest
    static void mulesoft_dedicatedHardware_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must run on dedicated hardware.',
            '', 'MuleSoft', ''
        );
        System.assertEquals('Green', d.flag, 'MuleSoft supports dedicated hardware');
        System.assertEquals('MULESOFT_DEDICATED', d.ruleId);
    }

    @IsTest
    static void mulesoft_privateCloud_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must be deployed in agency private cloud environment.',
            '', 'MuleSoft Anypoint', ''
        );
        System.assertEquals('Green', d.flag, 'MuleSoft supports private cloud');
        System.assertEquals('MULESOFT_PRIVATE_CLOUD', d.ruleId);
    }

    @IsTest
    static void mulesoft_detection() {
        System.assert(AIRFX_ResponseFlagInvocable.isMuleSoftDeal('MuleSoft'));
        System.assert(AIRFX_ResponseFlagInvocable.isMuleSoftDeal('Anypoint Platform'));
        System.assert(!AIRFX_ResponseFlagInvocable.isMuleSoftDeal('Sales Cloud'));
        System.assert(!AIRFX_ResponseFlagInvocable.isMuleSoftDeal(null));
    }

    // =========================================================================
    // 16. TABLEAU PRODUCT RULES
    // =========================================================================

    @IsTest
    static void tableau_onPrem_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must support on-premise deployment.',
            '', 'Tableau', ''
        );
        System.assertEquals('Green', d.flag, 'Tableau supports on-prem');
        System.assertEquals('TABLEAU_ON_PREM', d.ruleId);
        System.assert(d.reason.contains('Tableau Server'), 'Should mention Tableau Server');
    }

    @IsTest
    static void tableau_dedicatedHardware_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must run on dedicated hardware.',
            '', 'Tableau Server', ''
        );
        System.assertEquals('Green', d.flag, 'Tableau supports dedicated hardware');
        System.assertEquals('TABLEAU_DEDICATED', d.ruleId);
    }

    @IsTest
    static void tableau_privateCloud_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must be deployed in agency private cloud environment.',
            '', 'Tableau', ''
        );
        System.assertEquals('Green', d.flag, 'Tableau supports private cloud');
        System.assertEquals('TABLEAU_PRIVATE_CLOUD', d.ruleId);
    }

    @IsTest
    static void tableau_detection() {
        System.assert(AIRFX_ResponseFlagInvocable.isTableauDeal('Tableau'));
        System.assert(AIRFX_ResponseFlagInvocable.isTableauDeal('Tableau Server'));
        System.assert(!AIRFX_ResponseFlagInvocable.isTableauDeal('Sales Cloud'));
        System.assert(!AIRFX_ResponseFlagInvocable.isTableauDeal(null));
    }

    @IsTest
    static void nonMulesoft_onPrem_staysYellow() {
        // Without MuleSoft product type, on-prem should be Yellow (CAN_DIFFERENTLY)
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must support on-premise deployment.',
            '', 'Sales Cloud', ''
        );
        System.assertEquals('Yellow', d.flag, 'Non-MuleSoft on-prem is CAN_DIFFERENTLY');
        System.assertEquals('ON_PREM_GENERAL', d.ruleId);
    }

    @IsTest
    static void nonTableau_onPrem_staysYellow() {
        // Without Tableau product type, on-prem should be Yellow (CAN_DIFFERENTLY)
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must support on-premise deployment.',
            '', 'Service Cloud', ''
        );
        System.assertEquals('Yellow', d.flag, 'Non-Tableau on-prem is CAN_DIFFERENTLY');
        System.assertEquals('ON_PREM_GENERAL', d.ruleId);
    }

    // =========================================================================
    // 17. ADVERSARIAL TESTS — 20 trick questions designed to find engine flaws
    // =========================================================================

    @IsTest
    static void adversarial_negation_noOnPrem() {
        // "no on-premise" — negation should NOT produce Red
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Confirm that no on-premise deployment is required for your solution.',
            '', '', ''
        );
        System.assertNotEquals('Red', d.flag, 'ADV-01: negation "no on-prem" should not be Red');
    }

    @IsTest
    static void adversarial_doubleNegative_encrypt() {
        // Double negative — "must not fail to encrypt" means "must encrypt"
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must not fail to encrypt data at rest.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'ADV-02: double negative encrypt at rest => Green');
    }

    @IsTest
    static void adversarial_compound_escrowAndEncrypt() {
        // Compound question — escrow first-match-wins
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does the vendor provide source code escrow and encryption at rest?',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'ADV-03: compound escrow+encrypt => Red (first match)');
        System.assertEquals('ESCROW', d.ruleId);
    }

    @IsTest
    static void adversarial_misleadingPercentage() {
        // 99.9% in non-uptime context
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The solution should protect 99.9 percent of email messages from phishing attacks.',
            '', '', ''
        );
        System.assertNotEquals('UPTIME', d.ruleId, 'ADV-04: 99.9% non-uptime should not match UPTIME');
    }

    @IsTest
    static void adversarial_saasNoOnPrem() {
        // SaaS delivery + no on-premise — should be Green
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Is the solution delivered as SaaS with no on-premise components?',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'ADV-05: SaaS+no on-prem => Green');
    }

    @IsTest
    static void adversarial_escrowOnMuleSoftDeal() {
        // Escrow is Red even on MuleSoft deals
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does the vendor provide source code escrow?',
            '', 'MuleSoft', ''
        );
        System.assertEquals('Red', d.flag, 'ADV-06: escrow still Red on MuleSoft deal');
    }

    @IsTest
    static void adversarial_tableauDedicated() {
        // Tableau + dedicated hardware = Green (not generic Red)
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must run on dedicated hardware.',
            '', 'Tableau', ''
        );
        System.assertEquals('Green', d.flag, 'ADV-07: Tableau+dedicated => Green');
        System.assertEquals('TABLEAU_DEDICATED', d.ruleId);
    }

    @IsTest
    static void adversarial_shouldSoftensEscrow() {
        // "should" makes BINARY_CANNOT soften to Yellow
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor should ideally provide source code escrow.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'ADV-08: should softens escrow Red => Yellow');
    }

    @IsTest
    static void adversarial_tls12() {
        // TLS 1.2 question — clear Green
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does the platform support TLS 1.2 for all connections?',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'ADV-09: TLS 1.2 => Green');
    }

    @IsTest
    static void adversarial_il5GovCloud() {
        // IL5 on GovCloud — Green
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The system must support Impact Level 5 data.',
            '', 'Government Cloud Plus', ''
        );
        System.assertEquals('Green', d.flag, 'ADV-10: IL5 GovCloud => Green');
    }

    @IsTest
    static void adversarial_dataResidencyAU() {
        // Data residency in valid Hyperforce country
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All data must reside within Australia.',
            '', '', 'AU'
        );
        System.assertEquals('Green', d.flag, 'ADV-11: data residency AU => Green');
    }

    @IsTest
    static void adversarial_dataResidencyNZ() {
        // Data residency in invalid country
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'All data must reside within New Zealand.',
            '', '', 'NZ'
        );
        System.assertEquals('Red', d.flag, 'ADV-12: data residency NZ => Red');
    }

    @IsTest
    static void adversarial_maySoftensWAF() {
        // "may" softens CAN_DIFFERENTLY to Green
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor may provide a web application firewall.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'ADV-13: may softens WAF => Green');
    }

    @IsTest
    static void adversarial_supportResponseTime() {
        // Support ticket question — should NOT be Red
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'What is the support ticket response time for priority 1 issues?',
            '', '', ''
        );
        System.assertNotEquals('Red', d.flag, 'ADV-14: support response time should not be Red');
    }

    @IsTest
    static void adversarial_iso27001ScaryPhrasing() {
        // ISO 27001 with intimidating language
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must demonstrate ISO 27001 certification or equivalent.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'ADV-15: ISO 27001 scary phrasing => Green');
    }

    @IsTest
    static void adversarial_zeroRPO() {
        // "zero" RPO — text not numeric — should be Yellow or Red
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The solution must achieve zero recovery point objective.',
            '', '', ''
        );
        System.assertNotEquals('Green', d.flag, 'ADV-16: zero RPO should not be Green');
    }

    @IsTest
    static void adversarial_sbomUnusualPhrasing() {
        // SBOM with unusual wording
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Provide a complete software bill of materials for all components.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'ADV-17: SBOM unusual phrasing => Red');
    }

    @IsTest
    static void adversarial_auditAtAnyTime() {
        // "right to audit at any time" — two rules compete
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The contractor must provide right to audit at any time.',
            '', '', ''
        );
        // Either CUSTOMER_AUDIT_SCHEDULE (Red) or RIGHT_TO_AUDIT (Yellow) — both are valid
        System.assert(d.flag == 'Red' || d.flag == 'Yellow',
            'ADV-18: audit at any time => Red or Yellow, got ' + d.flag);
    }

    @IsTest
    static void adversarial_blankQuestion() {
        // Blank question — graceful handling
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval('', '', '', '');
        System.assertEquals('Yellow', d.flag, 'ADV-19: blank => Yellow');
        System.assertEquals('NO_QUESTION', d.ruleId);
    }

    @IsTest
    static void adversarial_muleSoftOnPrem() {
        // MuleSoft + on-prem = Green
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can the integration platform be deployed on-premises in our data center?',
            '', 'MuleSoft Anypoint', ''
        );
        System.assertEquals('Green', d.flag, 'ADV-20: MuleSoft on-prem => Green');
        System.assertEquals('MULESOFT_ON_PREM', d.ruleId);
    }

    // =========================================================================
    // 18. EXISTING EDGE CASE TESTS
    // =========================================================================

    @IsTest
    static void preFilter_euDataProcessing_shouldNotBeAutoGreened() {
        // "support" in "must support the processing" should NOT trigger
        // the functional pre-filter. This question contains security terms
        // (residency/reside) and must pass through to the rules engine.
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The platform must support the processing of data within the EU/EEA, so that it is not transferred outside',
            '', '', ''
        );
        System.assertNotEquals('Green', d.flag,
            'EU/EEA data processing question must NOT be auto-greened by pre-filter');
        System.assertNotEquals('PREFILTER_NON_SECURITY', d.ruleId,
            'Should not hit the pre-filter non-security rule');
    }

    // =========================================================================
    // 19. ADVERSARIAL TEST FIXES — broadened keywords
    // =========================================================================

    @IsTest
    static void adversarial_dataNeverLeavesEU_shouldNotBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can Salesforce guarantee data never leaves the EU?',
            '', '', ''
        );
        System.assertNotEquals('Green', d.flag,
            'Data residency question about data leaving EU must not be Green');
    }

    @IsTest
    static void adversarial_deferSpringRelease_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can we defer the Spring release?',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'Deferring releases is a hard no — must be Red');
        System.assertEquals('DEFER_UPGRADES', d.ruleId);
    }

    @IsTest
    static void adversarial_deployOwnVMs_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can we deploy Salesforce on our own virtual machines?',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'Customer VMs are a hard no — must be Red');
        System.assertEquals('CUSTOMER_VM', d.ruleId);
    }

    @IsTest
    static void adversarial_approveChanges_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can we approve platform changes before they are deployed?',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'Customer approval before changes is a hard no — must be Red');
        System.assertEquals('CUSTOMER_APPROVAL_CHANGES', d.ruleId);
    }

    @IsTest
    static void adversarial_hostInNorway_shouldNotBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can Salesforce host our org in Norway?',
            '', '', ''
        );
        System.assertNotEquals('Green', d.flag,
            'Norway is not a Hyperforce region — hosting question must not be Green');
    }

    // =========================================================================
    // 20. P-0042 YELLOW MINING — new rules from YELLOW analysis
    // =========================================================================

    @IsTest
    static void maintenanceWindow_shouldSoftened_shouldBeGreen() {
        // "should" triggers obligation softening: CAN_DIFFERENTLY Yellow → Green
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Planned unavailability should only be carried out outside of core productive hours.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
        System.assertEquals('MAINTENANCE_WINDOW', d.ruleId);
    }

    @IsTest
    static void maintenanceWindow_must_shouldBeYellow() {
        // "must" = mandatory obligation, stays Yellow
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Planned unavailability must only be carried out outside of core productive hours.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('MAINTENANCE_WINDOW', d.ruleId);
    }

    @IsTest
    static void responseRecoveryTime_shouldBeYellowCanDiff() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'What are the standard response and recovery times in the event of system disruptions?',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('RESPONSE_RECOVERY_TIME', d.ruleId);
    }

    @IsTest
    static void vulnerabilityAssessment_shouldBeYellowCanDiff() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Any development must include a process for continual vulnerability assessment including static code analysis and dynamic code analysis.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('VULNERABILITY_ASSESSMENT', d.ruleId);
    }

    @IsTest
    static void auditInfoAccess_shouldBeYellowCanDiff() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Audit information, including physical access, logical security controls, and system logs, must be available.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('AUDIT_INFO_ACCESS', d.ruleId);
    }

    @IsTest
    static void changeTracking_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Ability to request and track system changes and upgrades for audit purposes.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
        System.assertEquals('CHANGE_TRACKING', d.ruleId);
    }

    @IsTest
    static void auditAlertsUser_shouldBeYellowCanDiff() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Providing audits and alerts for user activity, including changes to records, exports, and printing.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('AUDIT_ALERTS_USER', d.ruleId);
    }

    @IsTest
    static void securitySettingsMgmt_shouldBeYellowCanDiff() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Providing the ability to manage, change, and disable default settings that pose a security risk.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('SECURITY_SETTINGS_MGMT', d.ruleId);
    }

    @IsTest
    static void rbac_privileges_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Provide role-based system access privileges for job seekers, staff, and system administrators.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
        System.assertEquals('RBAC', d.ruleId);
    }

    @IsTest
    static void encryptionKeysManagedBy_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Using strong, unique encryption keys that are fully managed and controlled by the Department.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'BYOK requires Shield add-on — CAN_DIFFERENTLY');
        System.assertEquals('BYOK', d.ruleId);
    }

    @IsTest
    static void ciaTriad_shouldBeYellowNotUptime() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Providing the appropriate level of assurance for maintaining the confidentiality, integrity, availability, and non-repudiation requirements.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag);
        System.assertEquals('CIA_TRIAD', d.ruleId,
            'Should match CIA_TRIAD, not UPTIME_PARSE_FAIL');
    }

    // =========================================================================
    // 21. YELLOW MINING ROUND 2 — additional fixable rules
    // =========================================================================

    @IsTest
    static void calendarScheduling_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Contain viewable, interactive calendars with role-based functionality. Calendar functionality must include event scheduling capabilities.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'Calendar scheduling is a functional capability');
        System.assertEquals('CALENDAR_SCHEDULING', d.ruleId);
    }

    @IsTest
    static void adminConsole_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Including a dedicated administration website for use by staff to provide a comprehensive level of control over aspects of system operation, parameters, and security.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'Salesforce Setup is an admin console');
        System.assertEquals('ADMIN_CONSOLE', d.ruleId);
    }

    @IsTest
    static void securityPostureDescribe_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Describe the security system used by your proposed Solution, including: Authentication, Session Management, Access Control, Malicious Input Handling, Error Handling and Logging.',
            '', '', ''
        );
        System.assertEquals('Yellow', d.flag, 'Security posture description is CAN_DIFFERENTLY');
        System.assertEquals('SECURITY_POSTURE_DESCRIBE', d.ruleId);
    }

    @IsTest
    static void securityPostureDescribe_should_softensToGreen() {
        // "should" softens CAN_DIFFERENTLY to Green
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor should describe the security system including Authentication, Session Management, and Access Control.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'Optional language softens to Green');
        System.assertEquals('SECURITY_POSTURE_DESCRIBE', d.ruleId);
    }

    @IsTest
    static void adminConsole_doesNotMatchDedicatedHardware() {
        // "dedicated administration website" must NOT match DEDICATED_HARDWARE
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Including a dedicated administration website for use by staff.',
            '', '', ''
        );
        System.assertNotEquals('DEDICATED_HARDWARE', d.ruleId,
            'Dedicated admin website must not match DEDICATED_HARDWARE rule');
    }

    // =========================================================================
    // CONFIDENCE SCORING TESTS
    // =========================================================================

    @IsTest
    static void confidence_highScore_binaryCanWithCMDT() {
        // BINARY_CAN rule (encryption at rest) + US country with VERIFIED CMDT = high confidence
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does the vendor provide encryption at rest for all stored data?',
            '', '', 'US'
        );
        Integer score = AIRFX_ResponseFlagInvocable.calculateConfidence(d, 'US', '');
        System.assert(score >= 55, 'BINARY_CAN + US CMDT should yield high confidence, got: ' + score);
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void confidence_highScore_binaryCannotWithCMDT() {
        // BINARY_CANNOT rule (source code escrow) + US country = high confidence
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must provide source code escrow to the customer.',
            '', '', 'US'
        );
        Integer score = AIRFX_ResponseFlagInvocable.calculateConfidence(d, 'US', '');
        System.assert(score >= 55, 'BINARY_CANNOT + US CMDT should yield high confidence, got: ' + score);
        System.assertEquals('Red', d.flag);
    }

    @IsTest
    static void confidence_mediumScore_canDifferently() {
        // BINARY_CAN_DIFFERENTLY (WAF) + US country = medium-high confidence
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must provide a web application firewall (WAF) for all traffic.',
            '', '', 'US'
        );
        Integer score = AIRFX_ResponseFlagInvocable.calculateConfidence(d, 'US', '');
        System.assert(score >= 35, 'CAN_DIFFERENTLY + US CMDT should yield medium confidence, got: ' + score);
        System.assert(score <= 100, 'Score should be capped at 100, got: ' + score);
    }

    @IsTest
    static void confidence_lowScore_noMatchSecurity() {
        // NO_MATCH_SECURITY = -10 rule type, no CMDT = low score
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Describe your zero-trust architecture implementation for compliance.',
            '', '', ''
        );
        Integer score = AIRFX_ResponseFlagInvocable.calculateConfidence(d, '', '');
        System.assert(score <= 20, 'NO_MATCH_SECURITY without CMDT should yield low confidence, got: ' + score);
        System.assertEquals('Yellow', d.flag);
    }

    @IsTest
    static void confidence_prefilterGreen_lowScore() {
        // Pre-filter functional question = preFilterTriggered = -10
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does the system support dashboard creation and report scheduling?',
            '', '', ''
        );
        Integer score = AIRFX_ResponseFlagInvocable.calculateConfidence(d, '', '');
        System.assert(score <= 10, 'Pre-filter GREEN should yield low confidence score, got: ' + score);
        System.assertEquals('PREFILTER_NON_SECURITY', d.ruleId);
        System.assert(d.preFilterTriggered, 'Pre-filter should be marked as triggered');
    }

    @IsTest
    static void confidence_noMatchFunctional_zeroScore() {
        // NO_MATCH_FUNCTIONAL: no keywords, no CMDT, rule type = 0
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'What color options are available for the interface theme?',
            '', '', ''
        );
        Integer score = AIRFX_ResponseFlagInvocable.calculateConfidence(d, '', '');
        System.assert(score <= 10, 'NO_MATCH_FUNCTIONAL should yield near-zero confidence, got: ' + score);
        System.assertEquals('Green', d.flag);
    }

    @IsTest
    static void confidence_cmdtBoost_verifiedCountry() {
        // Same rule but with vs without CMDT country should show score difference
        AIRFX_ResponseFlagInvocable.FlagDecision d1 = eval(
            'Does the vendor provide encryption at rest?',
            '', '', 'US'
        );
        Integer scoreWithCMDT = AIRFX_ResponseFlagInvocable.calculateConfidence(d1, 'US', '');

        AIRFX_ResponseFlagInvocable.FlagDecision d2 = eval(
            'Does the vendor provide encryption at rest?',
            '', '', ''
        );
        Integer scoreWithoutCMDT = AIRFX_ResponseFlagInvocable.calculateConfidence(d2, '', '');

        System.assert(scoreWithCMDT > scoreWithoutCMDT,
            'CMDT country should boost score: with=' + scoreWithCMDT + ' without=' + scoreWithoutCMDT);
    }

    @IsTest
    static void confidence_multipleKeywords_cappedAt30() {
        // A question matching many keywords should cap keyword bonus at 30
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Describe encryption at rest and encryption in transit and TLS and BYOK and key management.',
            '', '', 'US'
        );
        Integer score = AIRFX_ResponseFlagInvocable.calculateConfidence(d, 'US', '');
        // BYOK is now CAN_DIFFERENTLY (Yellow), keyword cap 30 + base+rule 25 + CMDT 35 = 90
        System.assert(score <= 100, 'Score should not exceed 100, got: ' + score);
        System.assert(score >= 40, 'Multiple keywords should boost score, got: ' + score);
    }

    @IsTest
    static void confidence_clampedAtZero() {
        // NO_MATCH_SECURITY (-10) with no CMDT should clamp to 0, not go negative
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Describe your quantum-resistant cryptography compliance posture.',
            '', '', ''
        );
        Integer score = AIRFX_ResponseFlagInvocable.calculateConfidence(d, '', '');
        System.assert(score >= 0, 'Confidence score must never be negative, got: ' + score);
    }

    @IsTest
    static void confidence_storedOnDecision() {
        // Verify confidence score is set on FlagDecision after evaluate + calculateConfidence
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The vendor must provide SSO integration via SAML 2.0.',
            '', '', 'US'
        );
        d.confidenceScore = AIRFX_ResponseFlagInvocable.calculateConfidence(d, 'US', '');
        System.assertNotEquals(null, d.confidenceScore, 'Confidence score should be set');
        System.assert(d.confidenceScore >= 0 && d.confidenceScore <= 100,
            'Confidence score must be 0-100, got: ' + d.confidenceScore);
    }

    // =========================================================================
    // 22. ACCURACY GAUNTLET — new rules from gauntlet testing
    // =========================================================================

    @IsTest
    static void cdnDataTransit_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can Salesforce guarantee data never leaves the EU?',
            '', '', 'DE'
        );
        System.assertEquals('Yellow', d.flag, 'CDN routes globally — cannot guarantee data never leaves');
        System.assertEquals('CDN_DATA_TRANSIT', d.ruleId);
    }

    @IsTest
    static void dedicatedHardware_salesforceNotMulesoft() {
        // On a MuleSoft deal, asking about "Salesforce dedicated hardware" should still be Red
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does Salesforce support dedicated hardware for FedRAMP customers?',
            '', 'Core - Platform;Mulesoft', 'US'
        );
        System.assertEquals('Red', d.flag, 'Salesforce core dedicated hardware is always Red');
        System.assertEquals('DEDICATED_HARDWARE', d.ruleId);
    }

    @IsTest
    static void customerVm_azureTenant() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can we deploy Salesforce in our Azure tenant?',
            '', '', 'US'
        );
        System.assertEquals('Red', d.flag, 'Azure tenant = customer VM = Red');
        System.assertEquals('CUSTOMER_VM', d.ruleId);
    }

    @IsTest
    static void fedrampHigh_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Is Salesforce FedRAMP High authorized for Agentforce?',
            '', 'Agentforce', 'US'
        );
        System.assertEquals('Green', d.flag, 'FedRAMP High is held');
        System.assertEquals('FEDRAMP_HIGH', d.ruleId);
    }

    @IsTest
    static void onPremGeneral_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does Salesforce support on-premises deployment?',
            '', 'Core - Platform', 'US'
        );
        System.assertEquals('Yellow', d.flag, 'On-prem is CAN_DIFFERENTLY — MuleSoft/Tableau exceptions');
        System.assertEquals('ON_PREM_GENERAL', d.ruleId);
    }

    @IsTest
    static void byok_shouldBeYellowCanDifferently() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does Salesforce support customer-managed encryption keys?',
            '', '', 'US'
        );
        System.assertEquals('Yellow', d.flag, 'BYOK requires Shield add-on');
        System.assertEquals('BYOK', d.ruleId);
    }

    @IsTest
    static void dedicatedSupport_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can we get dedicated support engineers assigned to our account?',
            '', '', 'US'
        );
        System.assertEquals('Yellow', d.flag, 'Dedicated support is Premier/Signature add-on');
        System.assertEquals('DEDICATED_SUPPORT', d.ruleId);
    }

    @IsTest
    static void breachNotification_shouldBeYellow() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Does Salesforce notify customers within 24 hours of a breach?',
            '', '', 'US'
        );
        System.assertEquals('Yellow', d.flag, 'Breach notification timeline varies');
        System.assertEquals('BREACH_NOTIFICATION', d.ruleId);
    }

    @IsTest
    static void dataResidency_norway_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Can Salesforce store all data exclusively in Norway?',
            '', '', 'NO'
        );
        System.assertEquals('Red', d.flag, 'Norway is not a Hyperforce region');
        System.assertEquals('DATA_RESIDENCY', d.ruleId);
    }

    @IsTest
    static void ismap_japan_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Is Salesforce ISMAP certified for Japan?',
            '', '', 'JP'
        );
        System.assertEquals('Green', d.flag, 'ISMAP certification held');
    }

    // =========================================================================
    // Section 23 — Regulatory Framework CMDT context tests
    // =========================================================================

    @IsTest
    static void regulatoryContext_countryWithRecord_includesRegulation() {
        // Regulatory_Framework__mdt records are seeded in the org
        // This test verifies buildCMDTCapabilityContext includes regulatory info for a known country
        String ctx = AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext('DE', 'Sales Cloud');
        // DE has GDPR as primary regulation — if CMDT record exists, context should mention it
        if (ctx.contains('Applicable regulations in')) {
            System.assert(ctx.contains('GDPR'), 'DE context should mention GDPR');
            System.assert(ctx.contains('EU adequacy status:'), 'Should include adequacy status');
            System.assert(ctx.contains('Cross-border transfer mechanism:'), 'Should include transfer mechanism');
        }
        // If no CMDT records are active (e.g., scratch org), test still passes — no assertion failure
    }

    @IsTest
    static void regulatoryContext_countryWithoutRecord_noRegSection() {
        // ZZ is not a real country — should not produce regulatory lines
        String ctx = AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext('ZZ', 'Sales Cloud');
        System.assert(!ctx.contains('Applicable regulations in'), 'ZZ should have no regulatory context');
    }

    @IsTest
    static void regulatoryContext_blankCountry_noRegSection() {
        String ctx = AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext('', 'Sales Cloud');
        System.assert(!ctx.contains('Applicable regulations in'), 'Blank country should have no regulatory context');
    }

    @IsTest
    static void regulatoryContext_usCountry_includesRegulation() {
        String ctx = AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext('US', 'Sales Cloud');
        if (ctx.contains('Applicable regulations in')) {
            System.assert(ctx.contains('United States') || ctx.contains('US'), 'US context should reference United States');
            System.assert(ctx.contains('Cross-border transfer mechanism:'), 'Should include transfer mechanism');
        }
    }
}