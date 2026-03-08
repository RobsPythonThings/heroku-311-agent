# Norway Country Verification

**Date:** 2026-03-08
**Projects:** P-3334, P-3333

## Query Results

| Project | Country__c | Product_Type__c | Country Name |
|---------|:----------:|----------------|-------------|
| P-3333 | NO | (null) | Norway |
| P-3334 | NO | Vlocity - Comms Cloud; Agentforce | Norway |

## Analysis

Both projects are set to `NO` (Norway, ISO 3166-1 alpha-2).

**Norway is NOT in the Salesforce Hyperforce 18-region list:**
AU, BR, CA, FR, DE, IN, ID, IE, IL, IT, JP, SG, KR, SE, CH, AE, UK, US

The closest Hyperforce region for Nordic countries is **SE (Sweden)**.

## Data Residency Impact

Questions requiring data residency in Norway will correctly flag **Red** via the
`DATA_RESIDENCY` rule (CONDITIONAL_DATA_RESIDENCY type), because `NO` is not in
`ALLOWED_DATA_COUNTRIES`.

This is the **correct behavior** if the deal genuinely requires data to reside in Norway.
However, many Nordic/EU deals can be served from the **Sweden (SE)** or **Germany (DE)**
Hyperforce region with data staying within the EU.

## Recommendation

**No change made.** Country settings are correct as configured. If the deals can accept
EU-based hosting (Sweden or Germany), the project owner should update Country__c to
`SE` or `DE` — this would change data residency flags from Red to Green.

Robert should confirm with the deal team whether Norway-specific hosting is a hard
requirement or if EU hosting suffices.

## Status: Verified — no fix needed
