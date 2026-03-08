# P-0042 Benchmark Results

## Latest Run: 2026-03-08 (YELLOW mining + adversarial fixes)

### Baseline Comparison

| Metric | Baseline (original KB) | Run 1 (10 new rules) | Run 2 (obligation + product) | Run 3 (YELLOW mining) | Delta (Run 2 -> 3) |
|--------|----------------------|---------------------|---------------------------|---------------------|-------------------|
| Total Questions | 348 | 348 | 348 | 348 | — |
| RED | 0 | 0 | 0 | 0 | — |
| GREEN | 207 | 275 | 278 | **288** | **+10** |
| YELLOW | 141 | 73 | 70 | **60** | **-10** |
| Functional | — | 266 | 266 | 266 | — |
| Security | — | 79 | 79 | 79 | — |
| Unit Tests | — | 134 | 134 | **170** | +36 |

### Project Context

- **Project:** P-0042 (348 questions)
- **Product:** Core - Experience Cloud; MuleSoft; Public Sector Solutions; Tableau - Cloud
- **Country:** US
- **Questions with optional language (should/may):** 36

### Rule Distribution (Run 3)

| Rule | Count | Flag | Classification |
|------|------:|------|----------------|
| PREFILTER_NON_SECURITY | 201 | Green | Functional |
| NO_MATCH_FUNCTIONAL | 68 | Green | Functional |
| NO_MATCH_SECURITY | 21 | Yellow | Security |
| BYOK | 6 | Green | Security |
| UPTIME | 4 | Yellow | Security |
| UPTIME_PARSE_FAIL | 4 | Yellow | Security |
| RESPONSE_RECOVERY_TIME | 4 | Yellow | Security |
| MAINTENANCE_WINDOW | 4 | Green/Yellow | Security |
| VULNERABILITY_ASSESSMENT | 3 | Yellow | Security |
| SIEM_INTEGRATION | 3 | Yellow | Security |
| RIGHT_TO_AUDIT | 3 | Yellow | Security |
| RBAC | 3 | Green | Security |
| MULTI_FACTOR_AUTH | 3 | Green | Security |
| DATA_RESIDENCY | 3 | Green | Security |
| CIA_TRIAD | 3 | Yellow | Security |
| CHANGE_TRACKING | 3 | Green | Security |
| BCP_DR_PLAN | 3 | Yellow | Security |
| AUDIT_INFO_ACCESS | 3 | Yellow | Security |
| AUDIT_ALERTS_USER | 3 | Yellow | Security |
| ACCESSIBILITY_508 | 3 | Yellow | Security |

### What Changed from Run 2 to Run 3

**+10 Green / -10 Yellow** from 8 new/broadened rules:

1. **CIA_TRIAD** (x3) — "confidentiality, integrity, availability" questions were falsely hitting UPTIME_PARSE_FAIL. New rule fires first, gives proper CIA context.
2. **MAINTENANCE_WINDOW** (x4) — "planned unavailability outside business hours" now matched with context about Salesforce maintenance windows. 4 questions with "should" language softened to Green.
3. **RESPONSE_RECOVERY_TIME** (x4) — "standard response and recovery times" now matched instead of NO_MATCH_SECURITY.
4. **VULNERABILITY_ASSESSMENT** (x3) — "vulnerability assessment, static/dynamic code analysis" now matched.
5. **AUDIT_INFO_ACCESS** (x3) — "audit information including physical access, logical security" now matched.
6. **CHANGE_TRACKING** (x3) — "track system changes for audit" now Green (Setup Audit Trail).
7. **AUDIT_ALERTS_USER** (x3) — "audits and alerts for user activity" now matched.
8. **RBAC** (x3) — Broadened keywords to match "role-based system access privileges".
9. **BYOK** (x6) — Broadened keywords to match "encryption keys managed/controlled by".

### Adversarial Test Fixes (also in Run 3)

5 broadened/new rules from adversarial testing:
- **DATA_RESIDENCY** — added "data.*leave", "host.*in", "org in", "data.*cross border"
- **DEFER_UPGRADES** — added "defer.*release", "delay.*release", "skip.*release"
- **CUSTOMER_VM** — added "our own vm", "own virtual machine", "deploy.*virtual machine"
- **CUSTOMER_APPROVAL_CHANGES** — added "approve.*change.*before", "approve.*platform change"

### Cumulative Shift from Baseline

1. **Pre-filter expansion** — 201 questions (58%) caught by functional pre-filter
2. **NO_MATCH split** — 68 questions with no security terms auto-Green (functional classification)
3. **18+ CAN_DIFFERENTLY rules** — Right to Audit, Security Assessment, Incident Response, CIA Triad, Maintenance Window, Response/Recovery Time, Vulnerability Assessment, Audit Info, Audit Alerts, Security Settings, Patch Management, BCP/DR, Confidentiality/NDA, SIEM, 508, etc.
4. **Obligation parsing** — "should"/"may" language softens CAN_DIFFERENTLY Yellow→Green
5. **Product dimensions** — MuleSoft/Tableau product rules available
6. **Rule ordering** — CIA_TRIAD and MAINTENANCE_WINDOW before UPTIME prevents false UPTIME_PARSE_FAIL

### CMDT Context

Flowing through `buildCMDTCapabilityContext()`:
- Hyperforce Region: US available (AWS us-east-1)
- Product regions: 7 products x US availability
- Certifications: FedRAMP High/Moderate, ISO 27001:2022, ISMAP
- Feature availability: Shield, BYOK, EU OZ, GovCloud Plus, Premier Support
- Hard Nos: 17 items (dedicated HW, on-prem, SBOM, etc.)
- CDN caveat included on all region records

### Performance

- **CPU time:** ~6.5 seconds for 348 records (65% of 10,000ms governor limit)
- **DML:** Updates all 348 records with new flag, reason, classification, and CMDT context

### Remaining 60 Yellow Breakdown

| Category | Count | Notes |
|----------|------:|-------|
| NO_MATCH_SECURITY | 21 | Genuine unknowns — needs human review + RAG |
| UPTIME (tiered) | 4 | 99.9% requirement — correctly Yellow |
| UPTIME_PARSE_FAIL | 4 | Uptime detected but no number — correctly Yellow |
| RESPONSE_RECOVERY_TIME | 4 | RTO/RPO questions — CAN_DIFFERENTLY |
| CIA_TRIAD | 3 | General security posture — CAN_DIFFERENTLY |
| VULNERABILITY_ASSESSMENT | 3 | Code scanning — CAN_DIFFERENTLY |
| SIEM_INTEGRATION | 3 | SIEM/log forwarding — CAN_DIFFERENTLY |
| RIGHT_TO_AUDIT | 3 | Audit access — CAN_DIFFERENTLY |
| AUDIT_INFO_ACCESS | 3 | Physical/logical audit info — CAN_DIFFERENTLY |
| AUDIT_ALERTS_USER | 3 | User activity alerts — CAN_DIFFERENTLY |
| BCP_DR_PLAN | 3 | BCP/DR plan review — CAN_DIFFERENTLY |
| ACCESSIBILITY_508 | 3 | WCAG/508 conformance — CAN_DIFFERENTLY |
| SECURITY_SETTINGS_MGMT | 3 | Security config — CAN_DIFFERENTLY |

### Conclusion

57% reduction in Yellow flags from baseline (141 → 60). Each Yellow now has a clear reason — either a rule-matched CAN_DIFFERENTLY with a pre-written alternative response, or a genuine unknown (21 NO_MATCH_SECURITY) requiring human review + RAG answer. No false Reds introduced across any run.
