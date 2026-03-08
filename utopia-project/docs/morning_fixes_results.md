# AIRFX Morning Fixes — Results

**Date:** 2026-03-08
**Org:** utopia-uat
**Engine version:** 206 tests passing (was 199)
**Deployed:** Yes

## Fixes Applied

### Fix 1: SOURCE_CODE Rule — Exclude Configuration Context

**Problem:** Questions like "System parameters must be maintainable via configuration files and not hard-coded in the source code" triggered BINARY_CANNOT (Red) even though they're about config management, not requesting access to Salesforce source code.

**Change:** Added exclude keywords to SOURCE_CODE rule: `hard-coded`, `hard coded`, `hardcoded`, `configuration file`, `config file`, `not in source code`, `not in source-code`.

**Impact:** 8 records across P-4601, P-4550, P-4666, P-3333, P-4331, P-5889 will no longer false-positive as Red. These will fall through to NO_MATCH (likely Green as functional questions about configuration management).

### Fix 2: CUI_CONTROLLED Sub-Rule — CUI is Not Classified

**Problem:** "Controlled Unclassified Information (CUI)" triggered CLASSIFIED_DATA (Red). CUI is explicitly NOT classified data — Salesforce Government Cloud Plus can handle CUI with appropriate controls.

**Change:** Added new `CUI_CONTROLLED` rule (BINARY_CAN_DIFFERENTLY / Yellow) that fires before `CLASSIFIED_DATA`. Matches: `controlled unclassified information`, `\bcui\b`. Response references GovCloud Plus, FedRAMP High, FIPS 140-2, NIST 800-171, and Data Security Rider requirements.

**Impact:** CUI questions → Yellow (was Red). Actual classified data questions remain Red via CLASSIFIED_DATA.

### Fix 3: CUSTOMER_VM — Exclude Compliance Standards Context

**Problem:** CISA/OWASP/NIST compliance questions triggered CUSTOMER_VM (Red) because "azure tenant" appeared in question context about security best practices, not about deploying to Azure.

**Change:** Added exclude keywords to CUSTOMER_VM rule: `cisa`, `owasp`, `nist`, `best practices`, `compliance standards`, `compliance framework`.

**Impact:** 3 P-0042 records moved Red → Yellow (NO_MATCH_SECURITY). Questions about compliance standards no longer false-positive as deployment requests.

### Fix 4: BREACH_NOTIFY_TIMELINE — New Rule for Specific Hour Requirements

**Problem:** Breach notification questions with specific timelines (24h, 48h, 72h) either hit the generic BREACH_NOTIFICATION rule or fell to NO_MATCH. Per accuracy corrections, 72-hour aligns with GDPR and is achievable; 24-hour is negotiable via Data Security Rider.

**Change:** Added new `BREACH_NOTIFY_TIMELINE` rule (BINARY_CAN_DIFFERENTLY / Yellow) that fires before generic BREACH_NOTIFICATION. Matches: `24 hour`, `24-hour`, `within 24`, `48 hour`, `48-hour`, `72 hour`, `72-hour`, `within 72`, `breach notification`, `notify within`, `notification within`. Response details 72h GDPR alignment, 24h DSR negotiation path, and GovCloud Plus 1-hour US-CERT exception.

**Impact:** Specific timeline breach questions now get a targeted Yellow response instead of generic "timeline varies."

### Fix 5: SECURITY_POSTURE_DESCRIBE → GREEN

**Problem:** "Describe your security system: authentication, session management, access control" was Yellow (CAN_DIFFERENTLY). Salesforce comprehensively addresses all these security pillars.

**Change:** Changed from `BINARY_CAN_DIFFERENTLY` to `BINARY_CAN`. Updated response to reference Spring '26 capabilities: MFA enforcement, SSO via SAML 2.0/OAuth 2.0, configurable session management with timeout and IP restrictions, RBAC, input validation, CSRF/XSS protection, Shield Event Monitoring, trust.salesforce.com.

**Impact:** 3 P-0042 records moved Yellow → Green. Reduces P-0042 Yellow count by 3.

## Test Results

- **206/206 passing** (100%)
- 7 new tests added (Section 24)
- 4 existing breach notification tests updated for BREACH_NOTIFY_TIMELINE rule priority

### New Tests (Section 24)
| Test | Validates |
|------|-----------|
| `sourceCode_configNotHardcoded_shouldNotTrigger` | SOURCE_CODE exclude for configuration context |
| `cui_controlledUnclassified_shouldBeYellow` | CUI_CONTROLLED → Yellow |
| `cui_acronym_shouldBeYellow` | CUI acronym match |
| `classifiedData_stillRed` | CLASSIFIED_DATA still fires for actual classified |
| `customerVm_cisaOwasp_shouldNotTrigger` | CUSTOMER_VM exclude for compliance standards |
| `breachNotifyTimeline_24hour_shouldBeYellow` | 24-hour breach → Yellow via BREACH_NOTIFY_TIMELINE |
| `breachNotifyTimeline_72hour_shouldBeYellow` | 72-hour breach → Yellow via BREACH_NOTIFY_TIMELINE |

## P-0042 Benchmark

**Previous:** 300G / 45Y / 3R (348 total)
**Current:**  294G / 54Y / 0R (348 total)

### Changes Attributable to Today's Fixes
| Fix | Records | Change |
|-----|--------:|--------|
| Fix 3 (CUSTOMER_VM excludes) | 3 | Red → Yellow (false positives eliminated) |
| Fix 5 (SECURITY_POSTURE → Green) | 3 | Yellow → Green |

### Pre-existing Changes (from gauntlet, not yet reflected in org)
| Rule | Records | Change |
|------|--------:|--------|
| BYOK (gauntlet: CAN → CAN_DIFFERENTLY) | 9 | Green → Yellow (stored flags stale) |

### Net Effect
- **Red: 3 → 0** (eliminated all P-0042 false positive Reds)
- **Yellow: 45 → 54** (+9 from BYOK stale flags, +3 from Red, -3 from SECURITY_POSTURE)
- **Green: 300 → 294** (-9 BYOK, +3 SECURITY_POSTURE)

### Yellow Distribution (54)
| Rule | Count |
|------|------:|
| BYOK | 9 |
| NO_MATCH_SECURITY | 9 |
| UPTIME | 4 |
| UPTIME_PARSE_FAIL | 4 |
| RESPONSE_RECOVERY_TIME | 4 |
| CIA_TRIAD | 3 |
| VULNERABILITY_ASSESSMENT | 3 |
| AUDIT_INFO_ACCESS | 3 |
| RIGHT_TO_AUDIT | 3 |
| AUDIT_ALERTS_USER | 3 |
| SIEM_INTEGRATION | 3 |
| ACCESSIBILITY_508 | 3 |
| BCP_DR_PLAN | 3 |

### Note on BYOK Records
The 9 BYOK records showing Green→Yellow are from the gauntlet change (BYOK: CAN → CAN_DIFFERENTLY). The org's stored flags haven't been updated since that change. Once re-flagged, the "true" delta from today's fixes is: **+3 Yellow (from Red), -3 Yellow (to Green) = net zero Yellow change from today.**

## CPU Performance
- **6,421ms** for 348 records (64.2% of 10,000ms governor limit)
- Consistent with previous benchmarks (~6,500ms)

## Summary

All 5 targeted fixes implemented successfully. Zero false-positive Reds remaining on P-0042. 206 unit tests passing. Engine deployed to utopia-uat.
