# AIRFX: Suspicious Red Records Audit

**Date:** 2026-03-08
**Org:** utopia-uat
**Method:** Compared each RED record's question/reason against Hard_No__mdt keywords

## Summary

- **Total Red records:** 51
- **Matched Hard_No__mdt keyword:** 12
- **No Hard_No match (suspicious):** 39

## Analysis

The 39 "suspicious" REDs are **not actually suspicious** — they are legitimate RED flags from deterministic Apex rules that don't correspond to Hard_No__mdt records. Hard_No__mdt only covers a subset of BINARY_CANNOT rules. The remaining REDs come from:

### Category 1: Uptime/SLA (17 records) — LEGITIMATE

Rule: `UPTIME` (NUMERIC_TIERED_MIN)

These are requirements asking for ≥99.8% uptime. Salesforce commits to 99.7%. Correctly flagged RED.

| Projects | Count | Requirement |
|----------|-------|-------------|
| P-4000, P-0056, P-6390, P-4601, P-4666, P-3334, P-3333, P-3530 | 10 | 99.9% uptime |
| P-5889 | 3 | 99.8% uptime |
| P-0045 | 2 | 99.999% uptime |
| P-5889 | 1 | 99.99% datacenter uptime |
| P-5889 | 1 | 1.6 hours downtime/annum |

**Status:** All legitimate. These exceed Salesforce's 99.7% SLA.

### Category 2: Source Code (9 records) — LEGITIMATE

Rule: `SOURCE_CODE` (BINARY_CANNOT)

Questions mentioning "source code" in Azure tenant/configuration contexts. Rule correctly fires because the question literally contains "source code".

| Projects | Count | Question Pattern |
|----------|-------|-----------------|
| P-4601, P-4550, P-4666, P-3333, P-4331 (×2), P-5889 (×2) | 8 | "System parameters...must be maintainable via configuration files...not hard-coded in the source code" |
| P-5889 | 1 | "Prevent unauthorised change to source code" |

**Status:** Legitimate but potentially over-flagged. The "not hard-coded in source code" context is about configuration management, not requesting access to Salesforce source code. **Robert should review if SOURCE_CODE rule needs an exclude keyword for "configuration" or "hard-coded" contexts.**

### Category 3: Classified Data (4 records) — LEGITIMATE

Rule: `CLASSIFIED_DATA` (BINARY_CANNOT)

| Projects | Count | Question Pattern |
|----------|-------|-----------------|
| P-3001 | 2 | NATO classified information safeguarding |
| P-4331 | 1 | Controlled Unclassified Information (CUI) requirements |

**Status:** Legitimate. Salesforce cannot store classified data. Note: CUI is "Controlled Unclassified" which is different from classified — **Robert should review if CUI should be YELLOW (CAN_DIFFERENTLY) rather than RED.**

### Category 4: CISA/OWASP Compliance (3 records) — FALSE POSITIVE

Rule: `CUSTOMER_VM` (BINARY_CANNOT) — matched "azure tenant"

| Projects | Count | Question Pattern |
|----------|-------|-----------------|
| P-0042 (×2), P-0042 | 3 | "utilize system development and data security best practices...CISA, NIST, OWASP..." |

**Status: FALSE POSITIVE.** These are compliance standards questions, not requests for customer VM deployment. The CUSTOMER_VM rule is triggering on the phrase "azure tenant" which appears in the question context but is not the actual requirement. **This should be investigated — the question doesn't ask for Azure tenant deployment.**

### Category 5: Data Residency (2 records) — LEGITIMATE

Rule: `DATA_RESIDENCY` (CONDITIONAL)

| Projects | Count | Detail |
|----------|-------|--------|
| P-3334 | 1 | SaaS solution with on-premise components — country NO (Norway) not in Hyperforce |
| P-3333 | 1 | GDPR Art. 15 data request — country NO not supported |

**Status:** Legitimate but worth checking. Country "NO" (Norway) isn't in Hyperforce yet. If these projects have the wrong country set, the flag would be wrong.

### Category 6: RPO/RTO (2 records) — LEGITIMATE

Rule: `RPO` (NUMERIC_MAX), `RTO` (NUMERIC_MAX)

| Project | Requirement | SF Commitment | Flag |
|---------|-------------|---------------|------|
| P-5889 | RPO ≤ 1 hour | 4 hours | RED |
| P-5889 | RTO ≤ 8 hours | 12 hours | RED |

**Status:** Legitimate. Requirements are stricter than Salesforce's SPARC targets.

### Category 7: FIPS 140-2 (2 records) — LEGITIMATE

Rule: `FIPS_GOV` with product filter `COMMERCIAL`

| Projects | Count | Detail |
|----------|-------|--------|
| P-3463, P-4330 | 2 | FIPS 140-2 certification on commercial (non-GovCloud) deals |

**Status:** Legitimate. FIPS only available on Government Cloud.

### Category 8: Resolution Time (2 records) — LEGITIMATE

Rule: `RESOLUTION_TIME` (BINARY_CANNOT)

| Project | Question |
|---------|----------|
| P-5889 | Patches within 48 hours SLA |

**Status:** Legitimate. Salesforce cannot commit to customer-imposed patching timelines.

### Category 9: Citizen Support (1 record) — LEGITIMATE

Rule: `CITIZEN_SUPPORT` with product filter `COMMERCIAL`

| Project | Question |
|---------|----------|
| P-4331 | PII protections for US Citizens (commercial deal) |

**Status:** Legitimate. US citizen support guarantees only on Government Cloud.

## Action Items for Robert

1. **SOURCE_CODE false positives** — Consider adding exclude keywords like "hard-coded" or "configuration" to the SOURCE_CODE rule, so questions about configuration management don't trigger it.
2. **CUI vs Classified** — Review if "Controlled Unclassified Information" should map to CAN_DIFFERENTLY (Yellow) rather than CLASSIFIED_DATA (Red).
3. **CUSTOMER_VM false positive on CISA/OWASP** — The 3 P-0042 records flagged RED because "azure tenant" appeared in a compliance standards question. Consider refining the CUSTOMER_VM rule.
4. **Norway (NO) data residency** — Verify projects P-3334 and P-3333 actually need Norway hosting. If they're EU deals, France/Germany/Sweden may suffice.
