# CSV Accuracy Audit Report

**Source:** `Red and Yellow flag kb - Best.csv`
**Date:** 2026-03-08
**Total rows audited:** 6,539
**CMDT sources cross-referenced:** Hyperforce_Region__mdt (31 records, 18 available), Certification__mdt (13), Hard_No__mdt (17), Feature_Availability__mdt (8), Regulatory_Framework__mdt (17), Product_Region__mdt (125)

---

## Category Counts

| Category | Count | % of Total | Output File |
|----------|-------|------------|-------------|
| ACCURATE | 3,535 | 54.1% | `csv_accurate_rows.csv` |
| STALE | 15 | 0.2% | `csv_stale_rows.csv` |
| WRONG | 37 | 0.6% | `csv_wrong_rows.csv` |
| EMPTY | 2,754 | 42.1% | `csv_empty_rows.csv` |
| NEEDS_REVIEW | 198 | 3.0% | `csv_needs_review_rows.csv` |

## Most Common Error Patterns

| Pattern | Count |
|---------|-------|
| Says disk/all-data encryption not provided (Shield + AWS disk encryption available) | 28 |
| Says TLS 1.3 not supported (TLS 1.3 available since 2025) | 8 |
| References RTO of 8 hours (now 12 hours per SPARC) | 7 |
| Says WAF not used (Cloudflare WAF is deployed) | 3 |
| Says cannot dictate data location (18 Hyperforce regions available) | 2 |
| Hard_No keyword "ISO 14001" answered affirmatively | 1 |
| Hard_No keyword "ISO 45001" answered affirmatively | 1 |
| Says Hyperforce not available in Switzerland (CH) — it IS available | 1 |
| Claims FedRAMP for quip (not in Certification__mdt) | 1 |

## Correction Rules Applied

### WRONG — Contradicts CMDT or Known Facts (37 rows)

| Rule | Rows |
|------|------|
| Disk/all-data encryption not provided → WRONG | 28 |
| WAF not used → WRONG | 3 |
| Cannot dictate data location → WRONG | 2 |
| Hard_No keyword answered affirmatively → WRONG | 2 |
| FedRAMP for non-CMDT products → WRONG | 1 |
| Hyperforce not available (but IS) → WRONG | 1 |
| Dedicated hardware possible → WRONG | 0 |
| On-premises for core → WRONG | 0 |

### STALE — Outdated but Directionally Correct (15 rows)

| Rule | Rows |
|------|------|
| TLS 1.3 not supported (available since 2025) → STALE | 8 |
| ISO 27001:2013 (now 2022) → STALE | 0 |
| RTO of 8 hours (now 12 per SPARC) → STALE | 7 |

### NEEDS_REVIEW — Generic Answers (198 rows)

All 198 rows use boilerplate "standard exception" language without substantive answers. These need SME rewrite for ingestion.

## Sample WRONG Rows

- **Row 14** (#redflag): Says WAF not used (Cloudflare WAF is deployed)
  > Q: _26 Firewall26.3 The Contractor shall propose a Web Application Firewall (WAF). The WAF has the follo_
  > A: _- We do not use WAF but we have alternative controls in place too mitigate risk against web applicat_

- **Row 23** (#redflag): Says WAF not used (Cloudflare WAF is deployed)
  > Q: _#45 Network Security Managementb) Host-based firewalls to protect endpoint devices against unauthori_
  > A: _we do not use host-based or application firewall, but alternative controls in place_

- **Row 185** (#yellowflag): Hard_No keyword "ISO 14001" answered affirmatively
  > Q: _9.0 STANDARDS AND COMPLIANCENFR-080ShouldThe Solution should be compliant with the ISO 14001 Environ_
  > A: _- This will apply to our public cloud provider in context of our services. we can provide a standard_

- **Row 187** (#yellowflag): Hard_No keyword "ISO 45001" answered affirmatively
  > Q: _NFR-081 - ShouldThe Solution should be compliant with the ISO 45001 Occupational Health and Safety_
  > A: _- This will apply to our public cloud provider in context of our services, we can provide a standard_

- **Row 237** (#redflag): Says WAF not used (Cloudflare WAF is deployed)
  > Q: _5.2 WAF + IRAP + Essential 8_
  > A: _We are not IRAP assessed and we do not have WAFNote -: The requirement is asking for alternative con_

- **Row 458** (#redflag): Says Hyperforce not available in Switzerland (CH) — it IS available
  > Q: _Page 7: "6.Data hosting and processing in a localized and secure cloud in Switzerland;"  _
  > A: _We don't have (yet) Hyperforce in Switzerland - planned for End of 2023_

- **Row 569** (#redflag): Says disk/all-data encryption not provided (Shield + AWS disk encryption available)
  > Q: _The contractor shall support encryption at the storage level, to include architecture, engineering, _
  > A: _We do not provide disk level encryption, but we do encrypt in the database in the event a disk is lo_

- **Row 570** (#redflag): Says disk/all-data encryption not provided (Shield + AWS disk encryption available)
  > Q: _The system must encrypt all internal and external data connections during transmission and storage _
  > A: _We cannot encrypt ALL data at rest._


## Sample STALE Rows

- **Row 32** (#redflag): References RTO of 8 hours (now 12 hours per SPARC)
  > A: _Our standard exception around RPO of 4 hours and RTO of 8 hours applies here_

- **Row 265** (#redflag): Says TLS 1.3 not supported (TLS 1.3 available since 2025)
  > A: _]? -The requirement is TLS 1.3 which is not supported at moment_

- **Row 270** (#redflag): Says TLS 1.3 not supported (TLS 1.3 available since 2025)
  > A: _- We do not support TLS 1.3 at the moment, we can provide our standard response around 1.2 and the s_

- **Row 501** (#redflag): Says TLS 1.3 not supported (TLS 1.3 available since 2025)
  > A: _we don't support TLS 1.3 , only TLS 1.2 with Forward Secrecy (FS) This has to be evaluated with the _

- **Row 582** (#redflag): References RTO of 8 hours (now 12 hours per SPARC)
  > A: _8 Hour RTO_

- **Row 747** (#redflag): Says TLS 1.3 not supported (TLS 1.3 available since 2025)
  > A: _We currently do not have services that support TLS 1.3. This is also not a protocol required by FedR_

- **Row 819** (#redflag): References RTO of 8 hours (now 12 hours per SPARC)
  > A: _24 Hour Breach Notification &amp; 8 Hour RTO_

- **Row 864** (#redflag): References RTO of 8 hours (now 12 hours per SPARC)
  > A: _8 Hour RTO in some places._


## Cross-Reference: stale_rows_updated.csv

58 rows were previously corrected in `docs/stale_rows_updated.csv`, covering:
- TLS 1.3 (now supported) — 4 rows
- WAF/Cloudflare (now deployed) — 4 rows
- Disk encryption (Shield + AWS) — 7 rows
- Hyperforce regions (CH, DE now live) — 2 rows
- ISO 27001:2022 — 4 rows
- 99.9% uptime SLA — 7 rows
- Breach notification timelines — 6 rows
- Accessibility/ACRs — 13 rows
- Background checks — 1 row
- End-to-end encryption — 1 row
- RTO/RPO — 5 rows
- Marketing Cloud France — 1 row

These corrections should be applied before ingestion. The original CSV still contains the stale/wrong answers.

## Recommended Ingestion Strategy

### Phase 1 — Immediate Ingest
**3,535 ACCURATE rows** → Load into `Salesforce_Security_Position__c` as-is.

### Phase 2 — Apply Pre-Corrections
**58 corrected rows** from `stale_rows_updated.csv` → Ingest using updated answers.

### Phase 3 — Rewrite WRONG + STALE
**37 WRONG + 15 STALE** → Rewrite answers to match CMDT.

### Phase 4 — SME Review
**198 NEEDS_REVIEW** → Replace "standard exception" with substantive answers.

### Phase 5 — RAG Fill
**2,754 EMPTY** → Generate answers via Data Cloud RAG or manual authoring.

### Rows Ready for Salesforce_Security_Position__c

| Source | Count |
|--------|-------|
| ACCURATE rows | 3,535 |
| Pre-corrected rows | 58 |
| **Total ingestible now** | **3,593** |

## Data Quality Notes

1. **42% of rows have no answer** — flagged questions that were never responded to in the KB. Valid for engine triage but not for answer ingestion.
2. **"?" prefix convention** — Many answers start with "?" as an uncertainty marker. Content after "?" is the actual answer and is evaluated normally.
3. **Conservative validation** — Only flags rows that directly contradict CMDT records or match known correction rules from `accuracy_corrections.md`. ACCURATE rows may have nuance issues not caught by automated rules.
4. **Encryption is the #1 error** — 28 of 37 WRONG rows claim encryption at rest is unavailable. This is the highest-impact correction for ingestion quality.
5. **stale_rows_updated.csv overlap** — Many WRONG rows in this audit overlap with corrections already authored in `stale_rows_updated.csv`. Apply those corrections to resolve ~58 rows.
