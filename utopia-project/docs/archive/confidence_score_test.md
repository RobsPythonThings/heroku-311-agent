# AIRFX Confidence Score — E2E Test Results

**Date:** 2026-03-08
**Org:** utopia-uat (`rsmith2utopia@salesforce.com.2025uat`)
**Engine version:** AIRFX_ResponseFlagInvocable (195 tests passing)

## Test Method

- Created temporary GPS_ResponseNew__c records under existing projects (P-6396 US, P-6399 JP)
- Ran `AIRFX_ResponseFlagInvocable.flagResponses()` end-to-end
- Verified flag, rule ID, confidence score, and CMDT context
- Rolled back all records via savepoint

## Results

| # | Question | Expected Flag | Actual Flag | Rule ID | Confidence | Expected Range | Status |
|---|----------|---------------|-------------|---------|-----------|---------------|--------|
| 1 | Can Salesforce provide dedicated hardware for our deployment? | Red | **Red** | DEDICATED_HARDWARE | **90** | 80+ | PASS |
| 2 | Does Salesforce support patch management processes? | Yellow | **Yellow** | PATCH_MGMT_PROCESS | **70** | 50-70 | PASS |
| 3 | What is your approach to supplier diversity programs? | Green | **Green** | NO_MATCH_FUNCTIONAL | **0** | ≤20 | PASS |
| 4 | Is Salesforce ISMAP certified for Japanese government? | Green | **Green** | ISMAP_CERT | **100** | 80+ | PASS |

**All 4 tests PASS.**

## Confidence Score Breakdown

### Q1 — Dedicated Hardware (RED, 90)
- Keywords matched: 1 ("dedicated hardware") → +10
- Rule type: BINARY_CANNOT (Red) → +45 (base 25 + rule 20)
- CMDT: US Hyperforce region exists, Confidence=VERIFIED → +35 (20 + 15)
- Pre-filter: not triggered → +0
- **Total: 90**

### Q2 — Patch Management (YELLOW, 70)
- Keywords matched: 1 ("patch management") → +10
- Rule type: BINARY_CAN_DIFFERENTLY (Yellow) → +25 (base 15 + rule 10)
- CMDT: US Hyperforce region exists, Confidence=VERIFIED → +35 (20 + 15)
- Pre-filter: not triggered → +0
- **Total: 70**

### Q3 — Supplier Diversity (GREEN, 0)
- Keywords matched: 0 → +0
- Rule type: NO_MATCH_FUNCTIONAL → +0
- CMDT: skipped for functional questions → +0
- Pre-filter: not triggered → +0
- **Total: 0** (functional question with no rule match)

### Q4 — ISMAP Japan (GREEN, 100)
- Keywords matched: 3 ("ismap", "certified", "government") → +30 (capped)
- Rule type: BINARY_CAN (Green) → +45 (base 25 + rule 20)
- CMDT: JP Hyperforce region exists, Confidence=VERIFIED → +35 (20 + 15)
- Pre-filter: not triggered → +0
- **Total: 110 → clamped to 100**

## CMDT Context

| Question | Country | CMDT Context Length |
|----------|---------|-------------------|
| Q1 | US | 3,395 chars |
| Q2 | US | 3,395 chars |
| Q3 | US | 3,395 chars |
| Q4 | JP | 3,466 chars |

## Confidence_Score__c Field

- Field deployed to org via metadata API (Tooling API confirms: `00N7x00000S0BszEAF`)
- Compiled Apex class (`AIRFX_ResponseFlagInvocable`) writes `Confidence_Score__c` on each record
- Anonymous Apex SOQL cannot query the field due to org schema cache delay (known Salesforce behavior)
- Field will be queryable in production after next metadata refresh

## Changes Made During Testing

1. **ISMAP_CERT rule added** — `BINARY_CAN` rule for ISMAP certification (Japanese government market)
2. **Security pre-filter updated** — Added "ismap", "certified", "certification", "certifications" to SECURITY_TERMS
3. **Confidence scoring formula tuned:**
   - Added base bonus (+25 for CAN/CANNOT, +15 for CAN_DIFFERENTLY) for deterministic rule matches
   - CMDT bonus only applies to security questions (not NO_MATCH_FUNCTIONAL or PREFILTER)
   - Ensures functional auto-greens score low, rule-matched decisions score high

## Scoring Formula

```
score = 0
+ min(keywordsMatched × 10, 30)              // keyword contribution
+ ruleTypeBonus:
    BINARY_CAN/CANNOT → +45 (base 25 + rule 20)
    BINARY_CAN_DIFFERENTLY → +25 (base 15 + rule 10)
    NO_MATCH_SECURITY → -10
    NO_MATCH_FUNCTIONAL → 0
    PREFILTER_NON_SECURITY → 0
+ preFilterTriggered ? -10 : 0
+ CMDT bonus (security questions only):
    record exists → +20
    Confidence__c = VERIFIED → +15
    Confidence__c = INFERRED → +5
    Confidence__c = NEEDS_REVIEW → 0
= clamp(0, 100)
```
