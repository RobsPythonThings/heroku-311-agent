# AIRFX Final Benchmark — P-0042

**Date:** 2026-03-08
**Org:** utopia-uat
**Engine version:** 94+ rules, 175 unit tests
**Project:** P-0042 (US, Core - Experience Cloud;Mulesoft;Public Sector Solutions;Tableau - Cloud)

## Results

| Metric | Value |
|--------|-------|
| **Total questions** | 348 |
| **Green** | **300 (86.2%)** |
| **Yellow** | **48 (13.8%)** |
| **Red** | **0** |
| **CPU time** | 6,106ms (61% of governor limit) |

## Progression From Baseline

| Run | Date | Green | Yellow | Red | Unit Tests | Key Changes |
|-----|------|------:|-------:|----:|----------:|-------------|
| Baseline | 2026-02-28 | 207 | 141 | 0 | 74 | Initial engine |
| Run 1 | 2026-03-05 | 275 | 73 | 0 | 111 | Pre-filter, NO_MATCH split, adversarial tests |
| Run 2 | 2026-03-06 | 278 | 70 | 0 | 134 | Obligation parsing, product dimensions |
| Run 3 | 2026-03-07 | 294 | 54 | 0 | 170 | Yellow mining round 1 (8 new rules) |
| **Run 4 (final)** | **2026-03-08** | **300** | **48** | **0** | **175** | **Yellow mining round 2 (3 new rules + 2 broadened)** |

## Improvement Summary

- **+93 Green** from baseline (+45%)
- **-93 Yellow** from baseline (-66%)
- **0 Red** across all runs (no false positives)
- **+101 unit tests** from baseline

## Rule Distribution

| Rule ID | Count | Flag | Category |
|---------|------:|------|----------|
| PREFILTER_NON_SECURITY | 201 | Green | Pre-filter (functional) |
| NO_MATCH_FUNCTIONAL | 65 | Green | NO_MATCH split (functional) |
| BYOK | 9 | Green | BINARY_CAN |
| DATA_RESIDENCY | 6 | Green | CONDITIONAL |
| MAINTENANCE_WINDOW | 4 | Green | Obligation-softened |
| CALENDAR_SCHEDULING | 3 | Green | BINARY_CAN |
| ADMIN_CONSOLE | 3 | Green | BINARY_CAN |
| MULTI_FACTOR_AUTH | 3 | Green | BINARY_CAN |
| RBAC | 3 | Green | BINARY_CAN |
| CHANGE_TRACKING | 3 | Green | BINARY_CAN |
| NO_MATCH_SECURITY | 9 | Yellow | NO_MATCH (security) |
| UPTIME | 4 | Yellow | NUMERIC_TIERED_MIN |
| UPTIME_PARSE_FAIL | 4 | Yellow | Parse failure |
| RESPONSE_RECOVERY_TIME | 4 | Yellow | BINARY_CAN_DIFFERENTLY |
| ACCESSIBILITY_508 | 3 | Yellow | BINARY_CAN_DIFFERENTLY |
| AUDIT_ALERTS_USER | 3 | Yellow | BINARY_CAN_DIFFERENTLY |
| AUDIT_INFO_ACCESS | 3 | Yellow | BINARY_CAN_DIFFERENTLY |
| BCP_DR_PLAN | 3 | Yellow | BINARY_CAN_DIFFERENTLY |
| CIA_TRIAD | 3 | Yellow | BINARY_CAN_DIFFERENTLY |
| RIGHT_TO_AUDIT | 3 | Yellow | BINARY_CAN_DIFFERENTLY |
| SECURITY_POSTURE_DESCRIBE | 3 | Yellow | BINARY_CAN_DIFFERENTLY |
| SIEM_INTEGRATION | 3 | Yellow | BINARY_CAN_DIFFERENTLY |
| VULNERABILITY_ASSESSMENT | 3 | Yellow | BINARY_CAN_DIFFERENTLY |

## 48 Remaining Yellows Breakdown

- **9 NO_MATCH_SECURITY** — genuine unknowns requiring human review (state-specific regs, customer policy compliance)
- **39 rule-matched CAN_DIFFERENTLY** — all have pre-written alternative responses explaining how Salesforce addresses the requirement differently

## CMDT Context Verification

All 348 records received country-specific CMDT capability context (US). Context includes:
- Hyperforce region availability (us-east-1, us-west-2)
- Product-specific data residency
- Certifications (FedRAMP, ISO 27001, SOC 2)
- Feature availability (Shield, BYOK, GovCloud Plus)
- Hard Nos list
- CDN data transit caveats
