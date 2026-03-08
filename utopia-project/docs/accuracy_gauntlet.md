# AIRFX Accuracy Gauntlet

**Date:** 2026-03-08
**Org:** utopia-uat
**Engine version:** 100+ rules, 195 unit tests
**Final result:** 20/20 PASS

## Methodology

20 high-risk questions designed to expose engine weaknesses across:
- Data residency with CDN caveats
- Product-specific overrides on multi-product deals
- Certification gaps (ISO, FIPS, SecNumCloud)
- Numeric edge cases (100% uptime)
- Pre-filter bypass attacks (functional terms masking security questions)
- CAN_DIFFERENTLY nuances (paid add-ons, policy-based vs contractual)

Each question tested with the correct country and product type via temporary GPS_Project__c records.

## Run 1 Results: 10/20 PASS

| # | Question | Expected | Got | Rule | Status |
|---|----------|----------|-----|------|--------|
| 1 | Can Salesforce guarantee data never leaves the EU? | Yellow | Green | DATA_RESIDENCY | FAIL |
| 2 | Does Salesforce support dedicated hardware for FedRAMP customers? | Red | Green | MULESOFT_DEDICATED | FAIL |
| 3 | Can we defer the Spring 26 release by 90 days? | Red | Red | DEFER_UPGRADES | PASS |
| 4 | Does Salesforce hold ISO 20000 certification? | Red | Red | ISO_20000 | PASS |
| 5 | Can Salesforce provide source code escrow? | Red | Red | ESCROW | PASS |
| 6 | Does Salesforce support IPv6? | Red | Red | IPV6_FULL | PASS |
| 7 | Is Salesforce FIPS 140-3 compliant? | Red | Red | FIPS_COMMERCIAL | PASS |
| 8 | Can we deploy Salesforce in our Azure tenant? | Red | Green | NO_MATCH_FUNCTIONAL | FAIL |
| 9 | Does Salesforce hold SecNumCloud certification? | Red | Red | SECNUMCLOUD | PASS |
| 10 | Can Salesforce guarantee 100% uptime? | Yellow | Red | UPTIME | FAIL |
| 11 | Does Marketing Cloud support data residency in Germany? | Green | Green | DATA_RESIDENCY | PASS |
| 12 | Is Salesforce FedRAMP High authorized for Agentforce? | Green | Yellow | NO_MATCH_SECURITY | FAIL |
| 13 | Does Salesforce support on-premises deployment? | Yellow | Green | PREFILTER_NON_SECURITY | FAIL |
| 14 | Can MuleSoft be deployed on-premises? | Green | Green | MULESOFT_ON_PREM | PASS |
| 15 | Is Salesforce ISO 27001 certified? | Green | Green | ISO_27001_CERT | PASS |
| 16 | Does Salesforce support customer-managed encryption keys? | Yellow | Green | BYOK | FAIL |
| 17 | Can we get dedicated support engineers assigned to our account? | Yellow | Green | NO_MATCH_FUNCTIONAL | FAIL |
| 18 | Does Salesforce notify customers within 24 hours of a breach? | Yellow | Green | BREACH_NOTIFY_GOV | FAIL |
| 19 | Is Salesforce ISMAP certified for Japan? | Green | Green | NO_MATCH_FUNCTIONAL | PASS |
| 20 | Can Salesforce store all data exclusively in Norway? | Red | Green | NO_MATCH_FUNCTIONAL | FAIL |

## Failure Analysis

### Root Causes

| Failure Type | Count | Questions |
|-------------|------:|-----------|
| Missing rule | 4 | Q1 (CDN transit), Q12 (FedRAMP), Q17 (dedicated support), Q19 (ISMAP) |
| Wrong rule type | 3 | Q10 (uptime tier), Q16 (BYOK), Q18 (breach notify) |
| Product filter too broad | 1 | Q2 (MuleSoft exclusions) |
| Pre-filter gaps | 3 | Q8 (azure tenant), Q13 (on-premises), Q20 (store all data) |
| Wrong flag level | 1 | Q13 (on-prem should be CAN_DIFFERENTLY not CANNOT) |

### Fixes Applied

#### Pre-filter (AIRFX_SecurityPreFilter.cls)
| Fix | Terms Added |
|-----|-------------|
| "on-premises" variant | `on-premises` |
| Azure/tenant terms | `azure tenant`, `our tenant`, `customer tenant` |
| Dedicated support terms | `dedicated support`, `dedicated engineer`, `assigned support`, `named support` |
| Data exclusivity terms | `store all data`, `data exclusively` |
| Certification terms | `ismap`, `certified`, `certification`, `certifications` |

#### Rules (AIRFX_ResponseFlagInvocable.cls)

| Change | Type | Detail |
|--------|------|--------|
| **CDN_DATA_TRANSIT** (new) | BINARY_CAN_DIFFERENTLY | "data never leaves" / "guarantee data stays" → Yellow. CDN routes globally. |
| **FEDRAMP_HIGH** (new) | BINARY_CAN | FedRAMP High authorization → Green. Covers Agentforce, GovCloud Plus, Data Cloud, etc. |
| **ISMAP_CERT** (new) | BINARY_CAN | ISMAP certification for Japan → Green. |
| **DEDICATED_SUPPORT** (new) | BINARY_CAN_DIFFERENTLY | "dedicated support" / "dedicated engineer" → Yellow. Premier/Signature available. |
| **UPTIME** (changed) | NUMERIC_TIERED_MIN | Red threshold moved from 99.9% to 100%. 99.9-100% is now Yellow (aspirational, not hard no). |
| **BYOK** (changed) | CAN → CAN_DIFFERENTLY | Requires Shield add-on → Yellow, not Green. |
| **ON_PREM_GENERAL** (changed) | CANNOT → CAN_DIFFERENTLY | MuleSoft/Tableau exceptions exist → Yellow, not Red. |
| **BREACH_NOTIFICATION** (changed) | numericMax → CAN_DIFFERENTLY | Timeline is policy-based, not contractual → Yellow. |
| **CUSTOMER_VM** (broadened) | BINARY_CANNOT | Added: `azure tenant`, `our tenant`, `customer tenant`, `our azure`, `our aws`, `our gcp`. |
| **MuleSoft product rules** (fixed) | Exclusions added | When question mentions "Salesforce" (not MuleSoft), product overrides don't fire. |
| **Tableau product rules** (fixed) | Exclusions added | Same exclusion logic as MuleSoft. |

## Run 2 Results: 20/20 PASS

| # | Question | Expected | Got | Rule | CMDT Ctx | Status |
|---|----------|----------|-----|------|---------|--------|
| 1 | Can Salesforce guarantee data never leaves the EU? | Yellow | Yellow | CDN_DATA_TRANSIT | 3518 | PASS |
| 2 | Does Salesforce support dedicated hardware for FedRAMP customers? | Red | Red | DEDICATED_HARDWARE | 3395 | PASS |
| 3 | Can we defer the Spring 26 release by 90 days? | Red | Red | DEFER_UPGRADES | 3395 | PASS |
| 4 | Does Salesforce hold ISO 20000 certification? | Red | Red | ISO_20000 | 3395 | PASS |
| 5 | Can Salesforce provide source code escrow? | Red | Red | ESCROW | 3395 | PASS |
| 6 | Does Salesforce support IPv6? | Red | Red | IPV6_FULL | 3395 | PASS |
| 7 | Is Salesforce FIPS 140-3 compliant? | Red | Red | FIPS_COMMERCIAL | 3395 | PASS |
| 8 | Can we deploy Salesforce in our Azure tenant? | Red | Red | CUSTOMER_VM | 3395 | PASS |
| 9 | Does Salesforce hold SecNumCloud certification? | Red | Red | SECNUMCLOUD | 3395 | PASS |
| 10 | Can Salesforce guarantee 100% uptime? | Yellow | Yellow | UPTIME | 3395 | PASS |
| 11 | Does Marketing Cloud support data residency in Germany? | Green | Green | DATA_RESIDENCY | 3518 | PASS |
| 12 | Is Salesforce FedRAMP High authorized for Agentforce? | Green | Green | FEDRAMP_HIGH | 3395 | PASS |
| 13 | Does Salesforce support on-premises deployment? | Yellow | Yellow | ON_PREM_GENERAL | 3395 | PASS |
| 14 | Can MuleSoft be deployed on-premises? | Green | Green | MULESOFT_ON_PREM | 3395 | PASS |
| 15 | Is Salesforce ISO 27001 certified? | Green | Green | ISO_27001_CERT | 3395 | PASS |
| 16 | Does Salesforce support customer-managed encryption keys? | Yellow | Yellow | BYOK | 3395 | PASS |
| 17 | Can we get dedicated support engineers assigned to our account? | Yellow | Yellow | DEDICATED_SUPPORT | 3395 | PASS |
| 18 | Does Salesforce notify customers within 24 hours of a breach? | Yellow | Yellow | BREACH_NOTIFICATION | 3395 | PASS |
| 19 | Is Salesforce ISMAP certified for Japan? | Green | Green | NO_MATCH_FUNCTIONAL | 3466 | PASS |
| 20 | Can Salesforce store all data exclusively in Norway? | Red | Red | DATA_RESIDENCY | 2852 | PASS |

## Unit Tests

- **195/195 passing** (100%)
- 10 new gauntlet tests added (Section 22)
- 15 existing tests updated to reflect rule changes (uptime, breach, BYOK, on-prem)

## Key Takeaways

1. **Product filter exclusions are critical** — multi-product deals (e.g., Core+MuleSoft) need question-level disambiguation. MuleSoft/Tableau overrides now check if the question mentions "Salesforce" specifically.
2. **Pre-filter needs continuous expansion** — new security terms ("on-premises", "azure tenant", "store all data") required to prevent false functional classification.
3. **CAN_DIFFERENTLY is the right default for add-on features** — BYOK, breach notification, dedicated support are all "yes, but" answers requiring paid upgrades or policy caveats.
4. **Uptime >99.9% is Yellow, not Red** — aspirational targets get "we can discuss SLA options" rather than hard rejection.
5. **CDN transit caveat is a universal Yellow** — any "data never leaves" question is Yellow because CDN routes globally.
