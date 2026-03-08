# P-0042 Yellow Flag Reduction Analysis

**Date:** 2026-03-08
**Starting Yellows:** 70 (from Run 2 baseline)
**Final Yellows:** 48
**Final Greens:** 300 / 348 (86%)
**Unit Tests:** 175/175 passing

## Methodology

Extracted all 70 Yellow questions from P-0042 via anonymous Apex. Deduplicated across lots (P-0042 repeats sections across 3-4 lots). Categorized each unique question into FIXABLE, LEGITIMATE_YELLOW, or NEEDS_CMDT.

## Question Inventory

70 Yellows = 18 unique questions × 3-4 repetitions across lots.

### FIXABLE — Rules Added (22 questions converted)

| # | Question Pattern | Count | Rule Added | New Flag | Notes |
|---|-----------------|------:|-----------|----------|-------|
| 1 | "Calendars with role-based functionality, event scheduling" | 3 | CALENDAR_SCHEDULING (CAN) | Green | Functional question; "role-based" triggered security pre-filter but this is about calendar features |
| 2 | "Dedicated administration website for system control" | 3 | ADMIN_CONSOLE (CAN) | Green | Salesforce Setup IS a comprehensive admin interface |
| 3 | "Describe security system: Authentication, Session Mgmt, Access Control..." | 3 | SECURITY_POSTURE_DESCRIBE (CAN_DIFFERENTLY) | Yellow | SF has all these capabilities; answer describes how each is addressed |
| 4 | "Standard response and recovery times in event of disruptions" | 4 | RESPONSE_RECOVERY_TIME (CAN_DIFFERENTLY) | Yellow | RPO 4h/RTO 12h + Premier response times |
| 5 | "Planned unavailability outside core productive hours" (with "should") | 4 | MAINTENANCE_WINDOW (CAN_DIFFERENTLY) | Green | Obligation softening: "should" -> CAN_DIFFERENTLY -> Green |
| 6 | "Confidentiality, integrity, availability, non-repudiation" | 3 | CIA_TRIAD (CAN_DIFFERENTLY) | Yellow | Was falsely hitting UPTIME_PARSE_FAIL; now correctly handled |
| 7 | "Vulnerability assessment (static/dynamic code analysis)" | 3 | VULNERABILITY_ASSESSMENT (CAN_DIFFERENTLY) | Yellow | SF does all of these as part of SDLC |
| 8 | "Audit information: physical access, logical security, system logs" | 3 | AUDIT_INFO_ACCESS (CAN_DIFFERENTLY) | Yellow | Physical access logs N/A for SaaS; app-level audit logs available |
| 9 | "Track system changes for audit purposes" | 3 | CHANGE_TRACKING (CAN) | Green | Setup Audit Trail + Field History Tracking |
| 10 | "Audits and alerts for user activity (records, exports, printing)" | 3 | AUDIT_ALERTS_USER (CAN_DIFFERENTLY) | Yellow | Shield Event Monitoring add-on required for full capability |
| 11 | "Manage/disable default settings that pose security risk" | 3 | SECURITY_SETTINGS_MGMT (CAN_DIFFERENTLY) | Yellow | Password, session, IP, OAuth settings configurable; infra settings are platform-managed |

### FIXABLE — Existing Rules Broadened (12 questions converted)

| # | Question Pattern | Count | Rule Modified | Change |
|---|-----------------|------:|--------------|--------|
| 12 | "Role-based system access privileges" | 3 | RBAC | Added 'role-based.*privilege', 'role-based.*permission' |
| 13 | "Encryption keys managed and controlled by Department" | 9 | BYOK | Added 'encryption key.*managed', 'encryption key.*controlled', 'manage.*encryption key', 'control.*encryption key' |

### LEGITIMATE_YELLOW — Correctly Yellow (24 questions remain)

| # | Question Pattern | Count | Rule | Why Yellow |
|---|-----------------|------:|------|-----------|
| 1 | "99.9% system availability" | 4 | UPTIME (tiered) | 99.9% is in the Yellow tier (99.7-99.9%) — correct |
| 2 | "Response times per System Availability tab" | 4 | UPTIME_PARSE_FAIL | References external document tab — no number to extract |
| 3 | "Response/recovery times in event of disruptions" | 4 | RESPONSE_RECOVERY_TIME | CAN_DIFFERENTLY — SF has times but can't guarantee customer-specific SLAs |
| 4 | "Generate detailed user activity and system security audit data" | 3 | RIGHT_TO_AUDIT | CAN_DIFFERENTLY — SOC 2/ISO 27001 reports, not raw data |
| 5 | "Audits and alerts for user activity" | 3 | AUDIT_ALERTS_USER | CAN_DIFFERENTLY — requires Shield add-on |
| 6 | "SIEM integration" | 3 | SIEM_INTEGRATION | CAN_DIFFERENTLY — Shield Event Monitoring required |
| 7 | "Section 508 compliance" | 3 | ACCESSIBILITY_508 | CAN_DIFFERENTLY — substantial conformance, not 100% |
| 8 | "Audit information: physical access, logical security" | 3 | AUDIT_INFO_ACCESS | CAN_DIFFERENTLY — physical access logs N/A for SaaS |
| 9 | "CIA triad: confidentiality, integrity, availability" | 3 | CIA_TRIAD | CAN_DIFFERENTLY — comprehensive but multi-topic |
| 10 | "Vulnerability assessment, code analysis" | 3 | VULNERABILITY_ASSESSMENT | CAN_DIFFERENTLY — SF does this but won't share detailed results |
| 11 | "Security settings management" | 3 | SECURITY_SETTINGS_MGMT | CAN_DIFFERENTLY — some settings platform-managed |
| 12 | "Disaster recovery and BCP" | 3 | BCP_DR_PLAN | CAN_DIFFERENTLY — plans not shared for customer review |
| 13 | "Describe security system" | 3 | SECURITY_POSTURE_DESCRIBE | CAN_DIFFERENTLY — can describe all, some are add-on |

### LEGITIMATE_YELLOW — NO_MATCH_SECURITY (9 questions remain)

| # | Question Pattern | Count | Why Unfixable |
|---|-----------------|------:|--------------|
| 1 | "Compliance with Department security policies, data sharing agreements, state IT guidelines, SSA certification" | 3 | Customer-specific policy compliance — genuinely ambiguous |
| 2 | "System development and data security best practices per 60GG-2 F.A.C., 60GG-4 F.A.C." | 3 | State-specific regulation — needs human review |
| 3 | "Capabilities for 60GG-2, CISA Cloud Security TRA, CISA Zero Trust, NIST 800-53, FIPS 199" | 3 | Multiple specific standards — genuinely complex |

## Results Summary

### Flag Distribution Progression

| Metric | Baseline | Run 1 | Run 2 | Run 3 | Run 4 (final) |
|--------|----------|-------|-------|-------|---------------|
| GREEN | 207 | 275 | 278 | 294 | **300** |
| YELLOW | 141 | 73 | 70 | 54 | **48** |
| RED | 0 | 0 | 0 | 0 | **0** |
| Unit Tests | 97 | 111 | 134 | 170 | **175** |

### Rule Distribution (Final)

| Rule | Count | Flag |
|------|------:|------|
| PREFILTER_NON_SECURITY | 201 | Green |
| NO_MATCH_FUNCTIONAL | 65 | Green |
| BYOK | 9 | Green |
| DATA_RESIDENCY | 6 | Green |
| MAINTENANCE_WINDOW | 4 | Green (softened) |
| UPTIME | 4 | Yellow (tiered) |
| UPTIME_PARSE_FAIL | 4 | Yellow |
| RESPONSE_RECOVERY_TIME | 4 | Yellow |
| CALENDAR_SCHEDULING | 3 | Green |
| ADMIN_CONSOLE | 3 | Green |
| MULTI_FACTOR_AUTH | 3 | Green |
| RBAC | 3 | Green |
| CHANGE_TRACKING | 3 | Green |
| NO_MATCH_SECURITY | 9 | Yellow |
| CIA_TRIAD | 3 | Yellow |
| VULNERABILITY_ASSESSMENT | 3 | Yellow |
| AUDIT_INFO_ACCESS | 3 | Yellow |
| RIGHT_TO_AUDIT | 3 | Yellow |
| AUDIT_ALERTS_USER | 3 | Yellow |
| SIEM_INTEGRATION | 3 | Yellow |
| ACCESSIBILITY_508 | 3 | Yellow |
| SECURITY_POSTURE_DESCRIBE | 3 | Yellow |
| BCP_DR_PLAN | 3 | Yellow |

### Remaining 48 Yellows Breakdown

- **9 NO_MATCH_SECURITY** — genuine unknowns (state-specific regs, customer policy compliance)
- **39 rule-matched CAN_DIFFERENTLY** — all have pre-written alternative responses with specific Salesforce capabilities

### Key Metrics

- **66% Yellow reduction** from baseline (141 -> 48)
- **86% Green rate** (300/348)
- **0 false Reds** across all runs
- **100% of remaining Yellows have clear reasons** — either a CAN_DIFFERENTLY response or a genuine unknown
- **9 questions** (2.6%) genuinely need human review

## New Rules Added (This Round)

| Rule ID | Type | Flag | Converts |
|---------|------|------|----------|
| CALENDAR_SCHEDULING | BINARY_CAN | Green | 3 |
| ADMIN_CONSOLE | BINARY_CAN | Green | 3 |
| SECURITY_POSTURE_DESCRIBE | BINARY_CAN_DIFFERENTLY | Yellow (better reason) | 3 |

## New Tests Added (This Round)

| Test | Validates |
|------|-----------|
| calendarScheduling_shouldBeGreen | Calendar+role-based -> Green |
| adminConsole_shouldBeGreen | Admin website -> Green |
| securityPostureDescribe_shouldBeYellow | Broad security describe -> Yellow |
| securityPostureDescribe_should_softensToGreen | Optional language softens to Green |
| adminConsole_doesNotMatchDedicatedHardware | "dedicated admin website" != DEDICATED_HARDWARE |
