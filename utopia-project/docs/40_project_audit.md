# AIRFX 40-Project Full Audit

**Date:** 2026-03-08
**Scope:** 40 projects, 2,910 questions, full triage + answer generation
**Method:** Apex direct via `AIRFX_AgentAction.triageProject()` + `AIRFX_GenerateBatchAnswers` (Queueable chain → ConnectApi → DataCloud_RFP_Answer template with ADL/HECVAT retrievers)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Projects evaluated | 40 |
| Total questions triaged | 2,910 |
| GREEN | 2,275 (78%) |
| YELLOW | 571 (20%) |
| RED | 64 (2%) |
| Triage errors | 0 (17 projects triaged, 0 failures) |
| Yellow answers generated | 571 queued (244 complete at time of audit, 327 in async queue) |
| Countries covered | US, GB, NO, IT, FI, ES, PT, BE, SE, NL, DE, CA, TH, IE |
| Products covered | Core, Shield, Hyperforce, MuleSoft, Tableau, Education Cloud, GovCloud+, B2B Commerce, Agentforce, Data Cloud, Public Sector, Marketing Cloud |

---

## Code Path Verification

**Triage path:** Anonymous Apex → `AIRFX_AgentAction.triageProject()` → `AIRFX_SecurityPreFilter.evaluate()` → `AIRFX_ResponseFlagInvocable.flagResponses()` → DML writes to `GPS_ResponseNew__c`. Same code path the Agentforce agent uses.

**Answer generation path:** Anonymous Apex → `AIRFX_GenerateBatchAnswers` → Queueable chain → `AIRFX_GenerateAnswer.callPromptTemplate()` → `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('DataCloud_RFP_Answer', input)`. This invokes:
- **ADL retriever:** `{!$EinsteinSearch:File_ADL_Rob_Unstructure_1Cx_jB306918510}` (10 results)
- **HECVAT retriever:** `{!$EinsteinSearch:HECVAT_Unified_Filtered}` (10 results)
- **Knowledge retriever:** `{!$EinsteinSearch:Utopia_Knowledge_Clean}` (2 instances, 5 each)
- **CMDT context:** `buildCMDTCapabilityContext(country, product)` → plain-English facts from 6 CMDT objects

SPARC docs, HECVAT assessments, and compliance text files **are** being retrieved. Confirmed by examining answer content — answers cite specific SPARC facts (RPO 4h/RTO 12h, AES-256, dual-site architecture, annual DR testing) that only exist in the ADL corpus.

---

## RED Flag Audit (64 records)

### Distribution by Rule

| Rule | Count | Verdict |
|------|-------|---------|
| CUSTOMER_VM | 37 | 37 CORRECT — cannot deploy to customer Azure/AWS tenant |
| DATA_RESIDENCY | 13 | 3 correct, **10 SHOULD_BE_YELLOW** — rule fires on any question from non-Hyperforce country, not just residency questions |
| RESOLUTION_TIME | 4 | 4 CORRECT_NEGOTIABLE — cannot guarantee resolution times |
| SOURCE_CODE | 3 | 1 correct, **2 SHOULD_BE_YELLOW** — "prevent change to source code" is about change control, not escrow |
| DEDICATED_HARDWARE | 2 | **2 SHOULD_BE_YELLOW** — questions ask for architecture clarification, explicitly accept multitenant |
| CLASSIFIED_DATA | 2 | 2 CORRECT — NATO classified data |
| RPO | 1 | 1 CORRECT — RPO 1hr < Salesforce 4hr |
| RTO | 1 | 1 CORRECT — RTO 8hr < Salesforce 12hr |
| IPS | 1 | **1 SHOULD_BE_YELLOW** — "heating of IPs" is IP warming (translation artifact), not Intrusion Prevention |

### RED Accuracy: 47/64 correct (73%)

| Verdict | Count |
|---------|-------|
| CORRECT_HARD_NO | 42 (66%) |
| CORRECT_NEGOTIABLE | 5 (8%) |
| **SHOULD_BE_YELLOW** | **15 (23%)** |
| SHOULD_BE_GREEN | 2 (3%) |

### Root Causes for RED Misflags

1. **DATA_RESIDENCY overbroad (10 records):** `CONDITIONAL_DATA_RESIDENCY` fires on ANY question from a project with a non-Hyperforce country (NO, PT, BE), even when the question is about GDPR DPAs, pricing, system environments, or backups — not data residency. **Fix:** Add question-content gate — only fire when question text mentions hosting, residency, data location, or storage geography.

2. **SOURCE_CODE false match (2 records):** "Prevent unauthorised change to source code" matches SOURCE_CODE rule but is about change control, not code access. **Fix:** Add exclude pattern for `change.*source code` or `prevent.*change`.

3. **DEDICATED_HARDWARE overreach (2 records):** Questions asking "single-tenant or multi-tenant?" with explicit "if multi-tenant, describe isolation" acceptance. **Fix:** Add exclude pattern for questions that include `if multi-tenant` or `describe.*isolation`.

4. **IPS false positive (1 record):** French RFP translation artifact — "heating of IPs" mismatched to IPS rule. **Fix:** IPS rule should require `intrusion prevention` or `ips` as standalone, not just `ip` substrings.

---

## GREEN Flag Audit (2,275 records — 400 sampled)

### GREEN Accuracy: ~94% (extrapolated)

Sampled 400 Greens across 7 offset ranges covering 17 projects.

- **CORRECT:** 372/400 (93%)
- **SHOULD_BE_YELLOW:** 28/400 (7%)
- **SHOULD_BE_RED:** 0/400 (0%)

### Extrapolated: ~140-160 misflagged Greens across the full 2,275

### Two Root Causes

**1. Missing SECURITY_TERMS (~24 terms to add):**

| Term | Impact | Example Question |
|------|--------|-----------------|
| `gdpr` | HIGH — affects all EU projects | "How are GDPR requirements ensured?" |
| `data loss` | MEDIUM | "Must not result in any data loss" |
| `data retention` | MEDIUM | "Define and enforce data retention policies" |
| `data protection` | MEDIUM | "Data protection-relevant activities must be logged" |
| `data destruction` | MEDIUM | "Auditable data destruction" |
| `confidentiality` | MEDIUM | "Integrity and confidentiality of assets" |
| `integrity` (security) | MEDIUM | Same — CIA triad |
| `cyber` | MEDIUM | "Cyber insurance for cyber-attacks or data breaches" |
| `pci dss` | LOW | "How is PCI DSS managed?" |
| `iam` | LOW | "Identity and Access Management (IAM)" |
| `supply chain` | LOW | "Development supply chain must be managed" |
| `ddos`, `dos` | LOW | "Malicious activities: DoS, DDoS, brute-force" |
| `malicious` | LOW | "Detect malicious activities" |
| `brute force` | LOW | Brute-force attacks |
| `outage` | LOW | "Restore service after data loss or outage" |
| `restore`, `restoration` | LOW | "Disaster to full service restoration" |
| `fraudulent`, `fraud` | LOW | "Detect and revoke fraudulent accounts" |
| `geo-redundant` | LOW | "Backups in geo-redundant storage areas" |
| `cnil` | LOW | French DPA |
| `bdsg` | LOW | German Federal Data Protection Act |
| `isms` | LOW | Information Security Management System |
| `bsi c5` | LOW | German cloud security standard |

**2. Pluralization gap in word-boundary matching:**
Pre-filter uses exact word boundary matching (`' ' + term + ' '`), so `backup` doesn't match `backups`, `breach` doesn't match `breaches`, `incident` doesn't match `incidents`. Affects ~30% of the Green misflags.

**Fix options:**
- Add all plural forms to SECURITY_TERMS (quick, ~15 terms)
- Change matching to prefix-based: term starts at word boundary but doesn't require ending boundary (higher risk of false matches)

---

## YELLOW Flag Audit (571 records — 60 sampled with answers)

### YELLOW Flag Accuracy: 78%

| Verdict | Count |
|---------|-------|
| CORRECT YELLOW | 47/60 (78%) |
| SHOULD_BE_GREEN | 8/60 (13%) |
| SHOULD_BE_RED | 1/60 (2%) |
| BORDERLINE | 4/60 (7%) |

### Answer Quality Distribution (56 answered)

| Rating | Count | % |
|--------|-------|---|
| **STRONG** | 22 | 39% |
| **BORDERLINE** | 23 | 41% |
| **WEAK** | 11 | 20% |

### Top 5 Best Answers

1. **GPS-0244** (P-0042): Disaster recovery/BCP — cites RPO 4h/RTO 12h, dual-site architecture, continuous site switching, annual DR testing
2. **GPS-0214** (P-0042): Encryption key management — covers Classic Encryption, Shield Platform Encryption, BYOK, FIPS 140-2, AES-256
3. **GPS-2419** (P-3534): KeyStore/certificate management — BYOK, CAC/PIV auth, Connected Apps, FIPS 140-2
4. **GPS-0139** (P-0042): Response/recovery times — four severity levels with exact response times, RPO/RTO targets
5. **GPS-0216** (P-0042): FedRAMP/FIPS 199 — covers FedRAMP High/Moderate, BYOK, SOC 2, data residency, CDN caveat

### Top 5 Worst Answers

1. **GPS-3791** (P-0563): Spanish procurement cost breakdown — fills 1,700 chars with irrelevant security certs for a pricing question
2. **GPS-2411** (P-3534): Job retry strategies — pads with DR RPO/RTO info irrelevant to batch job recovery
3. **GPS-2426** (P-3534): SLA major anomaly timeframe — pivots to ReportAnomalyEventStore (wrong kind of "anomaly")
4. **GPS-0055** (P-0004): Severity 1 resolution time — generic language, never states P1 response SLA
5. **GPS-0065** (P-0004): Proactive communication during incidents — no specifics on notification SLAs

### Question Types vs Answer Quality

| Question Type | Typical Quality | Notes |
|---------------|----------------|-------|
| DR / BCP / RPO / RTO | **STRONG** | Consistently cites 4h/12h, dual-site, annual testing |
| Encryption / key management | **STRONG** | BYOK, AES-256, FIPS well-grounded |
| Audit / logging / SIEM | **STRONG** | Event Monitoring well-documented |
| Compliance certifications | **STRONG** | ISO, SOC, FedRAMP well-covered |
| SLA resolution times | **WEAK** | Hedges instead of stating concrete numbers |
| Incident notification process | **BORDERLINE** | "Without undue delay" instead of specific timelines |
| Customer-specific doc references | **WEAK** | Cannot see external tabs/annexes |
| Country-specific regulatory | **WEAK** | Poor coverage of ENS, BDSG, PIPEDA |
| Functional questions misflagged as Yellow | **WEAK** | Answers treat functional as security, pads with irrelevant info |

---

## GovCloud Bleed-Through: Critical Finding

**52% of Yellow answers cite GovCloud/FedRAMP High/IL4/IL5 for non-GovCloud deals.**

This is the #1 answer quality problem. The ADL retriever pulls GovCloud Plus whitepaper content for standard commercial/Hyperforce deals because there is no product-type filter on retrieval.

| Project | Product | GovCloud Bleed Rate |
|---------|---------|:-------------------:|
| P-0004 | Hyperforce, US | 69% (11/16) |
| P-0042 | Core multi-cloud, US | 50% (10/20) |
| P-0563 | Public Sector Foundation, BE | 36% (4/11) |
| P-3534 | unset, CA | 44% (4/9) |

**Dangerous example:** GPS-0214 (P-0042, Core deal in US): "Government Cloud implementation includes specific controls for qualified personnel access and maintains compliance with DoD IL4 and FedRAMP High" — this is a standard Core deal, not GovCloud.

**Fix:** Add product-type filtering to the prompt template. When `Product_Type__c` does not contain "Government Cloud Plus" or "GovCloud", instruct the LLM to suppress GovCloud-specific claims or add a retriever pre-filter.

---

## Data Source Analysis

### Which sources are cited most in answers?

| Source | Frequency in answers | Quality |
|--------|:--------------------:|---------|
| GovCloud Plus whitepaper | 46% | PROBLEMATIC — causes bleed-through |
| HECVAT assessments | 41% | Good — factual, specific |
| RPO/RTO (SPARC) | 39% | Excellent — consistently accurate |
| FedRAMP documentation | 32% | Mixed — often conflates Moderate/High |
| Hyperforce architecture | 30% | Good |
| Event Monitoring (Shield) | 23% | Good — sometimes overstates base vs add-on |
| ISO 27001/27017/27018 | 17% | Good |
| Shield Platform Encryption | 16% | Good — correctly notes add-on |
| SOC 2 Type II | 16% | Good |
| BYOK | 8% | Good |
| Actual SLA percentage | 3% | Very low — answers avoid stating 99.7% |

### What's missing from answers

- TLS version (1.2/1.3) — only 1 record mentions it
- Log retention periods (Login History 6mo, Setup Audit Trail 180d)
- Sub-processor list (AWS, Cloudflare, WithSecure)
- Data deletion timeline (90 days post-termination)
- Support tier response times (P1: 1hr 24/7, P2: 2hr)

---

## Confidence Score Audit

**Cannot audit from org data.** `Confidence_Score__c` and `Confidence_Level__c` do not exist as fields on `GPS_ResponseNew__c`. The confidence scoring logic in `AIRFX_ResponseFlagInvocable.calculateConfidence()` computes scores in memory during triage but has no persisted field to write to.

**Impact:** Confidence scores are computed but invisible. SEs cannot see confidence in the org. The agent receives them in the triage summary but they're transient.

**Recommendation:** Create `Confidence_Score__c` (Number 4,1) and `Confidence_Level__c` (Text 10) on GPS_ResponseNew__c. Update `AIRFX_ResponseFlagInvocable.flagResponses()` to write these fields during triage DML.

---

## Overall Accuracy

### Flag Accuracy Summary

| Flag | Total | Correct | Misflagged | Accuracy |
|------|-------|---------|------------|----------|
| GREEN | 2,275 | ~2,115 | ~160 (should be Yellow) | **~93%** |
| YELLOW | 571 | ~445 | ~74 should be Green, ~11 should be Red, ~41 borderline | **~78%** |
| RED | 64 | 47 | 15 should be Yellow, 2 should be Green | **73%** |
| **TOTAL** | **2,910** | **~2,607** | **~303** | **~90%** |

### Answer Quality Summary (60 sampled with answers)

| Rating | Count | % |
|--------|-------|---|
| STRONG | 22 | 39% |
| BORDERLINE | 23 | 41% |
| WEAK | 11 | 20% |

---

## Projects Tested

| # | Project | Product | Country | Questions | G | Y | R | Newly Triaged? |
|---|---------|---------|---------|-----------|---|---|---|:-:|
| 1 | P-6405 | B2B Commerce; Agentforce | — | 409 | 355 | 49 | 5 | |
| 2 | P-0042 | Core; MuleSoft; PSS; Tableau | US | 348 | 292 | 56 | 0 | |
| 3 | P-5889 | Core; Shield | GB | 327 | 228 | 93 | 6 | |
| 4 | P-0189 | Core; DC; GovCloud+; MC; MuleSoft; Shield; Tableau; AF | GB | 228 | 177 | 51 | 0 | |
| 5 | P-3333 | (unset) | NO | 148 | 97 | 32 | 19 | |
| 6 | P-4601 | Education Cloud; MC; MuleSoft | US | 143 | 100 | 30 | 13 | |
| 7 | P-4666 | B2B Commerce; Sales Cloud | US | 143 | 100 | 30 | 13 | |
| 8 | P-0107 | MuleSoft | FI | 107 | 93 | 14 | 0 | |
| 9 | P-3001 | (unset) | US | 102 | 85 | 15 | 2 | |
| 10 | P-3002 | (unset) | US | 92 | 81 | 11 | 0 | |
| 11 | P-0004 | Hyperforce | US | 90 | 73 | 16 | 1 | |
| 12 | P-0162 | Core; MC; MuleSoft; PSS | ES | 84 | 76 | 8 | 0 | |
| 13 | P-0686 | Salesforce - SELA | IT | 76 | 60 | 16 | 0 | |
| 14 | P-0014 | Tableau - Cloud | FI | 66 | 62 | 4 | 0 | |
| 15 | P-4963 | Analytics; Core; MC; PSS; Shield | IT | 62 | 60 | 2 | 0 | |
| 16 | P-0045 | Core - Platform | US | 46 | 29 | 17 | 0 | |
| 17 | P-0286 | Data Cloud; PSS; Agentforce | IT | 41 | 37 | 4 | 0 | |
| 18 | P-4450 | Shield | DE | 40 | 18 | 22 | 0 | * |
| 19 | P-3334 | Vlocity; Agentforce | NO | 40 | 22 | 15 | 3 | |
| 20 | P-3464 | (unset) | NO | 33 | 30 | 3 | 0 | * |
| 21 | P-0153 | Customer Community; PSS | PT | 32 | 29 | 2 | 1 | * |
| 22 | P-0034 | Core; MuleSoft; PSS | US | 28 | 18 | 10 | 0 | * |
| 23 | P-0563 | Public Sector Foundation | BE | 28 | 16 | 11 | 1 | * |
| 24 | P-6360 | B2B Commerce | US | 27 | 20 | 7 | 0 | |
| 25 | P-4333 | (unset) | TH | 25 | 17 | 8 | 0 | * |
| 26 | P-0016 | Education Cloud; MuleSoft; Tableau | US | 24 | 19 | 5 | 0 | * |
| 27 | P-0041 | Core - Experience/Service Cloud | IT | 23 | 21 | 2 | 0 | * |
| 28 | P-4200 | (unset) | GB | 20 | 12 | 8 | 0 | * |
| 29 | P-3534 | (unset) | CA | 17 | 8 | 9 | 0 | * |
| 30 | P-0056 | Core - Sales/Service Cloud | SE | 10 | 6 | 4 | 0 | |
| 31 | P-6390 | Core - Sales/Service Cloud | — | 10 | 6 | 4 | 0 | |
| 32 | P-3335 | (unset) | US | 6 | 5 | 1 | 0 | * |
| 33 | P-3500 | (unset) | CA | 5 | 3 | 2 | 0 | * |
| 34 | P-6389 | Agentforce | — | 5 | 3 | 2 | 0 | * |
| 35 | P-4700 | Nonprofit Cloud | US | 5 | 3 | 2 | 0 | |
| 36 | P-4343 | Education Cloud | US | 5 | 3 | 2 | 0 | * |
| 37 | P-4242 | (unset) | IE | 5 | 3 | 2 | 0 | * |
| 38 | P-3462 | (unset) | US | 5 | 3 | 2 | 0 | * |
| 39 | P-0010 | Core; MC Personalization | NL | 3 | 3 | 0 | 0 | |
| 40 | P-0473 | Core; MC CDP/Engagement | GB | 2 | 2 | 0 | 0 | |

---

## Top 5 Things Working Well

1. **Functional pre-filter is highly effective.** 78% of all questions correctly auto-Green. The ~160 functional terms catch most non-security questions accurately.

2. **DR/BCP answers are the strongest category.** RPO 4h / RTO 12h cited consistently and accurately from SPARC docs. Dual-site architecture, annual DR testing, ACRC all well-grounded.

3. **Zero triage failures.** 17 projects triaged, 0 errors. Engine handles projects from 2 to 409 questions without governor limit issues.

4. **Zero false Reds on genuinely functional questions.** No functional question was flagged Red. All Red misflags are security questions that should be Yellow, not Green.

5. **CMDT context injection is working.** Answers reference certifications, Hyperforce regions, and hard nos that come from CMDT, not just RAG retrieval. The grounding layer adds verifiable facts.

## Top 5 Gaps to Fix

1. **GovCloud bleed-through (52% of answers).** The ADL retriever pulls GovCloud Plus content for all deals. SEs on commercial deals get told they have FedRAMP High / IL4 — dangerous for customer trust. **Priority: P0.**

2. **DATA_RESIDENCY rule overbroad (10 false Reds).** Fires on any question from a non-Hyperforce country project, even when the question isn't about data residency. Needs a question-content gate. **Priority: P1.**

3. **Missing SECURITY_TERMS (~24 terms, ~160 false Greens).** GDPR, data loss, data retention, confidentiality, integrity, cyber, PCI DSS, IAM not in the security term list. Major gap for EU projects. **Priority: P1.**

4. **Pluralization gap in pre-filter.** `backup`/`backups`, `breach`/`breaches`, `incident`/`incidents` don't match each other. Affects ~30% of Green misflags. **Priority: P2.**

5. **Confidence score not persisted.** Computed in memory but no field on GPS_ResponseNew__c. Cannot audit, cannot show to SEs, cannot use for answer quality triage. **Priority: P2.**

---

## Recommendations

| Priority | Action | Impact | Effort |
|----------|--------|--------|--------|
| **P0** | Add product-type filter to prompt template — suppress GovCloud content for non-GovCloud deals | Fixes 52% answer quality issue | Medium — template edit + retriever filter |
| **P1** | Add ~24 missing SECURITY_TERMS (gdpr, data loss, confidentiality, etc.) | Fixes ~160 false Green misflags | Low — pre-filter edit + tests |
| **P1** | Add question-content gate to DATA_RESIDENCY rule | Fixes 10 false Red misflags | Low — rule pattern edit |
| **P2** | Add plural forms to SECURITY_TERMS | Fixes ~50 false Green misflags | Low — pre-filter edit |
| **P2** | Create Confidence_Score__c field on GPS_ResponseNew__c | Enables confidence auditing | Low — field + DML update |
| **P2** | Add SLA response time table to retriever corpus | Fixes weak SLA answers | Low — doc upload |
| **P3** | Add country-specific regulatory content (ENS, BDSG, PIPEDA) | Fixes weak EU/CA answers | Medium — content sourcing |
| **P3** | Fix SOURCE_CODE rule to exclude "change control" context | Fixes 2 false Red misflags | Low — exclude pattern |
