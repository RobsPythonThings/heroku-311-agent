# Validation Discrepancy Analysis

**Source:** `docs/validation_discrepancies.csv`
**Total discrepancies:** 4839
**Date:** 2026-03-08

## Overview

A discrepancy occurs when the AIRFX engine produces a different flag than the original human-assigned flag from the KB. Not all discrepancies are errors — the engine may be *correctly* downgrading over-flagged questions.

## Category Breakdown

| Category | Count | % |
|----------|------:|--:|
| DOWNGRADE | 4729 | 97.7% |
| UPGRADE | 110 | 2.3% |

## Flag Transitions

| Original | Engine | Count | Direction |
|----------|--------|------:|-----------|
| RED | Yellow | 2353 | DOWNGRADE |
| RED | Green | 1416 | DOWNGRADE |
| YELLOW | Green | 960 | OTHER |
| YELLOW | Red | 110 | UPGRADE |

## Engine Rule Distribution

Which engine rules are producing discrepancies:

| Rule ID | Count | % | Meaning |
|---------|------:|--:|---------|
| NO_MATCH_SECURITY | 1656 | 34.2% | Security Q, no rule matched → Yellow |
| NO_MATCH_FUNCTIONAL | 1598 | 33.0% | No security terms, no rule → Green |
| PREFILTER_NON_SECURITY | 370 | 7.6% | Pre-filter caught functional terms → Green |
| ACCESSIBILITY_508 | 179 | 3.7% | WCAG/508 matched → Yellow (CAN_DIFFERENTLY) |
| UPTIME | 159 | 3.3% | Uptime rule matched (numeric) |
| UPTIME_PARSE_FAIL | 112 | 2.3% | Uptime detected but number extraction failed |
| ENCRYPTION_AT_REST | 85 | 1.8% |  |
| BREACH_NOTIFY_GOV_PARSE_FAIL | 70 | 1.4% |  |
| PEN_TEST_CUSTOMER | 55 | 1.1% | Pen test matched → Green (CAN) |
| RPO_PARSE_FAIL | 52 | 1.1% | RPO detected but number extraction failed |
| BACKGROUND_CHECK_GENERAL | 47 | 1.0% |  |
| EVENT_MONITORING | 46 | 1.0% |  |
| DATA_RESIDENCY | 40 | 0.8% | Data residency detected, no country → Yellow |
| BREACH_NOTIFY_GOV | 39 | 0.8% | Breach notification (numeric) → varies |
| FILE_SCANNING | 33 | 0.7% | Virus/malware scanning → Yellow (CAN_DIFFERENTLY) |
| RPO | 30 | 0.6% | RPO matched (numeric) |
| SAAS_DELIVERY | 26 | 0.5% | SaaS/cloud delivery → Green (CAN) |
| WAF_ALTERNATIVE | 17 | 0.4% | WAF matched → Yellow (CAN_DIFFERENTLY) |
| DR_TESTING | 17 | 0.4% |  |
| SERVICE_CREDIT_SLA | 17 | 0.4% |  |

## Root Cause Analysis

### 1. NO_MATCH_SECURITY — Engine says Yellow, Original says Red

**Count:** 1656 (34.2% of all discrepancies)

These are security questions the engine has no rule for. The engine correctly says 'I don't know' (Yellow), but the original KB flagged them Red.

**Topic breakdown within NO_MATCH_SECURITY:**

| Topic | Count |
|-------|------:|
| Incident Response / Breach Process | 222 |
| Confidentiality / NDA | 153 |
| Security Policy Compliance | 106 |
| Personnel Security / Clearance | 103 |
| Logging / Monitoring | 79 |
| Right to Audit / Security Audit | 71 |
| Data Protection / Privacy | 63 |
| Patch / Vulnerability Management | 57 |
| Encryption (general) | 32 |
| Certifications (ISO/SOC) | 30 |
| Business Continuity / DR Plan | 25 |
| Security Assessment / Review | 25 |
| Data Segregation / Multi-tenant | 9 |
| Access Control | 8 |
| (No topic match) | 673 |

### 2. NO_MATCH_FUNCTIONAL — Engine says Green, Original says Red/Yellow

**Count:** 1598 (33.0% of all discrepancies)

Engine classified these as functional (no security terms detected) and auto-Greened. But the original KB flagged them Red or Yellow. Two sub-cases:

- **Genuine functional:** Engine is correct — these are non-security questions that were over-flagged in the KB.

- **Misclassified:** Security-adjacent questions where the engine's term list doesn't detect them (e.g., 'accessibility', 'WCAG', 'background check').

**Sub-topic breakdown:**

| Sub-topic | Count |
|-----------|------:|
| Other functional | 1316 |
| Accessibility/WCAG (missed by engine) | 112 |
| Performance (not security) | 102 |
| SLA (not security) | 55 |
| Backup/Recovery (missed by engine) | 13 |

### 3. PREFILTER_NON_SECURITY — Engine says Green, Original says Red/Yellow

**Count:** 370 (7.6% of all discrepancies)

Pre-filter detected functional terms and auto-Greened. Most are correct downgrades — SLA, performance, reporting questions that aren't actually security.

### 4. PARSE_FAIL — Engine says Yellow, Original says Red

**Count:** 245 (5.1% of all discrepancies)

Engine detected the right topic (uptime/RPO/RTO) but couldn't extract a number. Common causes:

- RPO/RTO phrased as 'no data loss' or 'zero RPO' (no numeric)

- Question mentions topic in header but number is in a table not included

- Mixed units or ambiguous phrasing

### 5. UPGRADE — Engine says Red, Original says Yellow

**Count:** 110 (2.3% of all discrepancies)

Engine correctly identifies a BINARY_CANNOT (e.g., ISO 14001, ISO 45001). Original KB was lenient with Yellow.


## Key Findings

1. **1656 discrepancies (34%)** are NO_MATCH_SECURITY — the engine's biggest gap. Adding rules for the top topics (audit, security policy, incident response, personnel security, patch management) would address the majority.
2. **1598 discrepancies (33%)** are NO_MATCH_FUNCTIONAL — many are legitimate downgrades (accessibility and performance are not security). Some (~112) are accessibility questions that need broader keyword coverage in the pre-filter or ACCESSIBILITY_508 rule.
3. **245 discrepancies (5%)** are PARSE_FAIL — the engine correctly identifies the topic but can't extract a number. Improving the numeric parser for 'zero RPO', 'no data loss', and 'within X minutes' patterns would fix these.
4. **110 discrepancies (2%)** are UPGRADE — the engine is stricter than the original KB. These are correct.
5. Most DOWNGRADE discrepancies are **intentional** — the engine is more conservative than the original KB, preferring Yellow ('I don't know') over Red ('Salesforce can't do this') when no rule matches.

## Recommendations

### Immediate (10 new rules)
Add rules for the highest-volume NO_MATCH_SECURITY topics:
1. RIGHT_TO_AUDIT (CAN_DIFFERENTLY) — SOC 2/ISO 27001 attestations, no direct audit access
2. SECURITY_ASSESSMENT_ACCESS (CAN_DIFFERENTLY) — independent assessments, no customer-directed audits
3. INCIDENT_RESPONSE_PROCESS (CAN_DIFFERENTLY) — SF has IR program, no customer-format reports
4. SECURITY_CLEARANCE_PERSONNEL (CAN_DIFFERENTLY) — background checks per own policy, not customer vetting
5. PATCH_MGMT_PROCESS (CAN_DIFFERENTLY) — SF manages patching cadence, no customer-directed timelines
6. DATA_SEGREGATION (CAN) — logical tenant isolation in multi-tenant architecture
7. ISO_27001_CERT (CAN) — ISO 27001 certification held
8. SOC2_CERT (CAN) — SOC 2 Type II attestation held
9. BCP_DR_PLAN (CAN_DIFFERENTLY) — SF has BCP/DR, no customer review/approval
10. CONFIDENTIALITY_NDA (CAN_DIFFERENTLY) — SF NDA, not customer-specific NDAs

### Future improvements
- Broaden ACCESSIBILITY_508 keywords to catch more WCAG/accessibility variants
- Improve numeric parser for 'zero RPO', 'no data loss', 'within N minutes' patterns
- Add security terms to pre-filter: 'clearance', 'vetting', 'audit' (currently missed)