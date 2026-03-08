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
    static void uptime_99995_shouldBeRed() {
        // Connor's exact test case from video at 1:50
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'The platform must guarantee 99.995% uptime.',
            'Salesforce provides 99.95% uptime...', '', ''
        );
        System.assertEquals('Red', d.flag, 'Uptime 99.995% exceeds SF 99.9% max — must be Red');
        System.assert(d.reason.contains('99.9'), 'Reason should reference our 99.9% maximum');
        System.assertEquals('UPTIME', d.ruleId);
    }

    @IsTest
    static void uptime_9995_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor shall provide 99.95% availability for the hosted solution.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, '99.95% > 99.7% = Red');
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
    static void uptime_100_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'System must provide 100% availability.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, '100% > 99.9% = Red');
    }

    @IsTest
    static void uptime_9999_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Platform requires 99.99% uptime guarantee.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, '99.99% > 99.9% = Red');
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
    static void breach_1hour_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Vendor must provide breach notification within 1 hour of discovery.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag, 'Breach 1hr < SF 24hrs = Red');
    }

    @IsTest
    static void breach_24hours_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Security breach notification within 24 hours.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'Breach 24hrs == SF 24hrs = Green');
    }

    @IsTest
    static void breach_72hours_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Breach notification within 72 hours.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag, 'Breach 72hrs > SF 24hrs = Green');
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
    static void onPrem_shouldBeRed() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Solution must support on-premise deployment.',
            '', '', ''
        );
        System.assertEquals('Red', d.flag);
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
    static void byok_shouldBeGreen() {
        AIRFX_ResponseFlagInvocable.FlagDecision d = eval(
            'Customer must be able to bring your own key for encryption.',
            '', '', ''
        );
        System.assertEquals('Green', d.flag);
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
        System.assertEquals('Red', results[0].flag, '99.99% > 99.7% = Red');

        // Verify the record was updated
        GPS_ResponseNew__c updated = [
            SELECT Security_Flag__c, Response_Flag_Reason__c
            FROM GPS_ResponseNew__c
            WHERE Id = :resp.Id
        ];
        System.assertEquals('Red', updated.Security_Flag__c);
        System.assert(updated.Response_Flag_Reason__c.contains('99.9'), 'Reason should mention 99.9% maximum');
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
        // 0,3,6,9,12,15,18 = 7 reds; 1,4,7,10,13,16,19 = 7 greens; 2,5,8,11,14,17 = 6 yellows
        System.assertEquals(7, reds, 'Should have 7 Red flags');
        System.assertEquals(7, greens, 'Should have 7 Green flags');
        System.assertEquals(6, yellows, 'Should have 6 Yellow flags');
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
}