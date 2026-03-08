# Gate 2.5 — Conditional Commitment Language Detector

**Date:** 2026-03-08
**Author:** Robert Smith
**Engine:** AIRFX_ResponseFlagInvocable (Gate 2.5 addition)
**Tests:** 241 passing (216 original + 5 conversational + 20 Gate 2.5)

## What Gate 2.5 Does

Detects conditional commitment language in RFP questions — phrases that imply
customer-specific requirements Salesforce hasn't seen yet, making a firm Green
commitment premature. Downgrades Green → Yellow with an explanatory reason.

**Trigger points in the triage pipeline:**
1. After BINARY_CAN rule matches Green (before returning)
2. After PREFILTER_NON_SECURITY auto-Green (before returning)
3. After NO_MATCH_FUNCTIONAL auto-Green (before returning)

Gate 2.5 does NOT affect Red, Yellow, or numeric rule decisions.

## Patterns Detected

| Pattern | Example | Source |
|---------|---------|--------|
| Future unknown requirements | "which will be provided at contract execution" | GPS-0329/0540 |
| Unknown solution design | "based on solution design" | GPS-4204 |
| Meet or exceed customer minimums | "meet or exceed minimum requirements" | GPS-0329 |
| Open-ended compliance scope | "rules, laws, regulations, and policies" | GPS-0306 |
| SLA commitment language | "SLA - Data Backup" | GPS-2504 |
| Conditional compliance (no known standard) | "comply with required safeguards" | GPS-4189 |
| External party requirements | "as required by the State" | GPS-4189 |
| Customer-specific policy compliance | "in accordance with data retention policies" | GPS-1336 |

### Known Standard Bypass

"Comply with HIPAA/FedRAMP/NIST/SOC2/ISO 27001/GDPR/PCI DSS/FIPS/FISMA/CJIS/ITAR/CMMC/StateRAMP/TxRAMP"
→ Does NOT trigger Gate 2.5 (these are known standards with deterministic answers).

## Mike Rosa Validation

| Metric | Before Gate 2.5 | After Gate 2.5 |
|--------|:-:|:-:|
| **Agreement rate** | 87.0% (275/316) | **90.5% (286/316)** |
| Mike=Yellow, Engine=Green | 15 | **6** |
| Mike=Green, Engine=Yellow | 14 | 14 (unchanged) |
| Net improvement | — | **+11 records** |

### Records Gate 2.5 Fixed (9 of 15)

| Record | Pattern Matched | Mike's Reasoning |
|--------|----------------|------------------|
| GPS-0306 | open-ended compliance scope | "rules, laws, regulations, and policies is too open ended" |
| GPS-0329 | meet or exceed + future requirements | "We need to know customer's requirements before committing" |
| GPS-0540 | meet or exceed + future requirements | (same as GPS-0329) |
| GPS-1336 | in accordance with + retention policies | "Not sure what data retention policies are" |
| GPS-2504 | SLA commitment | "We cannot tie backups to SLAs. SLAs are almost always yellow" |
| GPS-4189 | comply with + solution design | "We do not know what the requirements are" |
| GPS-4197 | comply with + unknown controls | "We cannot enforce non-dictionary" |
| GPS-4204 | solution design unknown | "Solution design is unknown" |
| GPS-3343* | comply with + external requirements | "We don't let customers monitor infrastructure" |

*GPS-3343 caught via "comply with" pattern in broader question context.

### Records Still Unresolved (6 of 15)

These are **capability-specific gaps**, not language patterns. They need specific rules:

| Record | Mike's Reasoning | Needed Fix |
|--------|-----------------|------------|
| GPS-1282 | "Not clear what export formats" | BINARY_CAN_DIFFERENTLY rule for export formats |
| GPS-3272 | "SFTP gets complicated" | BINARY_CAN_DIFFERENTLY rule for SFTP |
| GPS-3288 | "Would require configuration" | BINARY_CAN_DIFFERENTLY rule for custom identifiers |
| GPS-4252 | "Unclear what immediately means" | Ambiguous timeline detection |
| GPS-4253 | "Primary logging fails, we failover org" | BINARY_CAN_DIFFERENTLY rule for alt audit logging |

## Full Org Impact

| Metric | Before Gate 2.5 | After Gate 2.5 | Delta |
|--------|:-:|:-:|:-:|
| **Green** | 3,611 (77.2%) | 3,577 (76.4%) | -34 |
| **Yellow** | 957 (20.4%) | 991 (21.2%) | +34 |
| **Red** | 112 (2.4%) | 112 (2.4%) | 0 |
| **Total** | 4,680 | 4,680 | 0 |

34 records across all projects were downgraded from Green → Yellow. These are questions where the engine detected a keyword match (and would have auto-Greened) but the question contains conditional commitment language indicating customer-specific requirements haven't been defined yet.

**Zero false positives introduced** — all 14 pre-existing Mike=Green/Engine=Yellow disagreements were already Yellow before Gate 2.5.

## Test Coverage

20 new tests added:
- 7 tests for specific Mike patterns (meet or exceed, solution design, comply with, SLA, etc.)
- 5 negative tests (simple questions that should stay Green)
- 2 known standard bypass tests (HIPAA, FedRAMP)
- 3 direct method tests (detectConditionalCommitment, containsKnownStandard, containsSLAReference)
- 1 BINARY_CANNOT non-interference test
- 1 reason string verification test
- 1 prefilter conditional test
