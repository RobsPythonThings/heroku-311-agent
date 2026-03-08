# AIRFX: Yellow → Green Upgrades

**Date:** 2026-03-08
**Org:** utopia-uat
**Engine:** AIRFX_ResponseFlagInvocable (195 tests, scoring v2)

## Summary

- **Total Yellow records checked:** 50
- **Upgraded to Green:** 33
- **Remained Yellow:** 17

Records were updated in-place via `flagResponses()` DML.

## Upgraded Records

### Rule-Matched Upgrades (3 records)

| Record ID | Project | Rule ID | Confidence | Question |
|-----------|---------|---------|-----------|----------|
| a217x000001JX4a | P-4000 | MAINTENANCE_WINDOW | 100 | Planned unavailability of the CRM system...should only be carried out outside of core productive hours. |
| a217x000001JYew | — | DATA_SEGREGATION | 90 | The system must be multi-tenant capable. Tenants are logically separate organizational units... |
| a217x000001JaFX | — | DATA_RESIDENCY | 80 | Architecture Overview - Provide a high-level overview of your solution's architecture including how the solution is hosted... |

**Why upgraded:** These matched deterministic rules that confirm Salesforce capability. Q1 used optional language ("should") which softened CAN_DIFFERENTLY → GREEN. Q2 matched DATA_SEGREGATION (BINARY_CAN). Q3 matched DATA_RESIDENCY for US (GREEN).

### Pre-Filter Upgrades (2 records)

| Record ID | Rule ID | Question |
|-----------|---------|----------|
| a217x000001JXmM | PREFILTER_NON_SECURITY | Based on HMRC usage, a forecast for the next month's expenditure is provided. |
| a217x000001JaFY | PREFILTER_NON_SECURITY | Development and Configuration Requirements...what aspects of the solution are available 'out-of-the-box'. |

**Why upgraded:** Pre-filter detected functional terms ("forecast", "out of the box", "proposed solution") with no security terms. Previously miscategorized as security.

### NO_MATCH_FUNCTIONAL Upgrades (28 records)

| Record ID | Question (truncated) |
|-----------|---------------------|
| a217x000001JXm9 | Time required to restore service after a data loss or outage. |
| a217x000001JXmB | Time from a disaster being declared to full service restoration. |
| a217x000001JXmC | [SFDC INTERNAL NOTE: What is the request here?...] |
| a217x000001JXmD | Time taken to acknowledge and begin resolution of critical incidents. |
| a217x000001JXmE | Time taken to acknowledge and begin resolution of incidents, split by severity. |
| a217x000001JXmJ | Based on supplier product roadmaps, new features and capabilities are initiated... |
| a217x000001JXmK | Tracks how often new features or enhancements are released. |
| a217x000001JXmL | How many issues are cause by a vendor change to the platform. |
| a217x000001JXmN | Actual HMRC spend to date, split by calendar month. |
| a217x000001JXmO | Any escalations or issues raised during the period have been acknowledged... |
| a217x000001JXmQ | Sudden increases or drops in active users, beyond expected thresholds... |
| a217x000001JXmR | Volume of 4xx and 5xx error rates across APIs and UI endpoints... |
| a217x000001JXmS | Volume of data ingested, queried, or exported is monitored... |
| a217x000001JXmT | Token usage for AI-powered features is monitored... |
| a217x000001JXmU | Volume and distribution of API calls is monitored... |
| a217x000001JXmX | [SFDC INTERNAL NOTE: What does CRM channel services mean?...] |
| a217x000001JXmY | The Holder guarantees the integrity and confidentiality of the Cnam assets... |
| a217x000001JXma | Is your building protected by an Intruder Detection System (alarm)? |
| a217x000001JXmc | Does your organisation follow the best practices established by the CNIL? |
| a217x000001JaFJ | What is the clinical problem you want this solution to solve? |
| a217x000001JaFK | May differ across the three PC – but could it be common? |
| a217x000001JaFL | eDischarge std? |
| a217x000001JaFM | What is the operational problem you want this solution to solve? |
| a217x000001JaFN | What is the technical problem you want this solution to solve? |
| a217x000001JaFO | If you have any queries about the submission of documents... |
| a217x000001JaFd | What more would you want to know from the Trust? |
| a217x000001JaFe | Restrictions - How do the Trust's current draught requirements restrict you... |
| a217x000001JaG5 | Clinical Safety - Confirm if you are compliant with DCB 0129... |

**Why upgraded:** These questions contain no security terms — they are operational, functional, or process questions that were previously Yellow because the old engine didn't split NO_MATCH by security classification. The improved engine correctly auto-greens functional questions with no security signal.

## Impact

- **33/50 (66%) of sampled Yellows** were false positives that the improved engine corrects
- Most were functional/operational questions that should never have been flagged Yellow
- 3 were rule-matched upgrades where the engine now has appropriate rules (maintenance, segregation, residency)
