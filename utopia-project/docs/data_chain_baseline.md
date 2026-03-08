# AIRFX Data Chain Baseline

**Date:** 2026-03-08
**Org:** utopia-uat (rsmith2utopia@salesforce.com.2025uat)
**Method:** All counts queried live from org. No assumptions.

---

## 1. Custom Metadata Types (CMDT)

| Object | Total Records | Active Records | Purpose |
|--------|--------------|----------------|---------|
| Hyperforce_Region__mdt | 31 | 18 available | Country-to-AWS-region mapping. 18 countries with `Available__c = true`. 13 planned/unavailable. |
| Product_Region__mdt | 126 | Varies by product | Product × country availability matrix. 7 products × 18 countries. |
| Certification__mdt | 13 | 13 active | FedRAMP, ISMAP, ISO 27001 certifications by product. |
| Feature_Availability__mdt | 8 | 8 active | Shield features, BYOK, EU Operating Zone, GovCloud Plus, Premier Support. |
| Hard_No__mdt | 17 | 17 active | Keywords that are always Red (on-prem, dedicated hardware, SBOM, etc.). |
| Regulatory_Framework__mdt | 17 | 17 active | Per-country privacy regulation, gov certs, adequacy decisions. |
| Source_Document__mdt | 3 | 3 validated | Tracks fetched source URLs (GDPR page, Slack Trust, Trust Compliance). |
| Content_Source_Config__mdt | 5 | 5 | Content lane routing: HECVAT Hyperforce, HECVAT MuleSoft, HECVAT Tableau Next, Knowledge Base, Whitepaper GovCloud Plus. |

### What CMDTs ground

- **Hyperforce_Region__mdt** → Used by `AIRFX_ResponseFlagInvocable` for `CONDITIONAL_DATA_RESIDENCY` rule. Powers country validation.
- **Hard_No__mdt** → UNVERIFIED whether engine reads this at runtime. Keywords are currently hardcoded in `buildRules()`. CMDT exists but may not be wired into engine yet.
- **Certification__mdt** → UNVERIFIED whether engine reads this at runtime. FedRAMP product scope is hardcoded in rules.
- **Feature_Availability__mdt** → UNVERIFIED whether engine reads this at runtime. Feature facts are hardcoded.
- **Regulatory_Framework__mdt** → UNVERIFIED whether engine reads this at runtime. Built recently (2026-03-08) but wiring status unknown.
- **Product_Region__mdt** → UNVERIFIED whether engine reads this at runtime. Product × country matrix exists but consumption unclear.
- **Content_Source_Config__mdt** → Confirmed consumed by `AIRFX_ContentRouter` for RAG lane routing.
- **Source_Document__mdt** → Tracking only. 3 of 8+ planned docs fetched. 5 still need manual download (see `docs/archive/review-needed.md`).

### CMDT coverage gaps

- Only 3 of 8+ source documents tracked in Source_Document__mdt
- Product_Region__mdt has many "unconfirmed" caveats — Data Cloud, Marketing Cloud, Slack, Tableau, MuleSoft availability outside US marked as unconfirmed for most regions
- No CMDT for: sub-processors, SLA terms, encryption capabilities, log retention periods, breach notification timelines

## 2. Knowledge Base (Knowledge__kav)

| Metric | Value |
|--------|-------|
| Total online articles | 1,881 |
| Sample titles | "Education Cloud Product Overview", "Carahsoft as reseller", "Anti-Deficiency Act Compliance", "Are your APIs secured and encrypted?" |

### What Knowledge contains
- Mix of product overviews, RFP Q&A pairs, compliance responses, and generic sales content
- Used as a Data Cloud retriever source (Knowledge Base lane in Content_Source_Config__mdt)
- UNVERIFIED: Whether Knowledge retriever is currently active. CLAUDE.md states "Knowledge retrievers removed" — only HECVAT and Whitepapers active.

### Knowledge grounding status
- **UNVERIFIED** — Cannot confirm from org query alone whether Knowledge articles are indexed in Data Cloud or actively retrieved during answer generation. CLAUDE.md says Knowledge retrievers were removed, leaving only HECVAT and Whitepapers.

## 3. RFP Response Records (GPS_ResponseNew__c)

| Metric | Value |
|--------|-------|
| Total records | 4,680 |
| Green | 1,634 (34.9%) |
| Yellow | 2,659 (56.8%) |
| Red | 48 (1.0%) |
| Unflagged (null) | 339 (7.2%) |

### AI_Generated_Answer__c field
- Long text field on GPS_ResponseNew__c
- Cannot filter on it via SOQL (long text limitation)
- Confirmed populated for at least 15 Yellow records on P-0042 (see Task 2 assessment)
- UNVERIFIED: Total count of records with AI-generated answers across all projects

### Answer generation path
1. Agent calls `AIRFX_GenerateAnswer` or `AIRFX_GenerateBatchAnswers`
2. These call `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('DataCloud_RFP_Answer', ...)`
3. Prompt template uses 2 active retrievers: HECVAT, Whitepapers
4. Inputs: `Input:Question`, `Input:PS_Section_Name`
5. Generated answer written to `AI_Generated_Answer__c`

## 4. RFP Question Answer Bank (RFP_Pursuit_Question_Answer_Bank__c)

| Metric | Value |
|--------|-------|
| Total records | 141 |

- UNVERIFIED: Whether this is actively used by AIRFX or is a legacy Avnio object
- UNVERIFIED: Relationship to Knowledge__kav or GPS_ResponseNew__c
- Likely from earlier RFP tooling (Avnio namespace objects also present in org)

## 5. Avnio (Legacy RFP Tool)

Objects present in org with `avnio__` namespace:
- `avnio__AlternativeAnswer__c`
- `avnio__AlternativeAnswerVersion__c`
- `avnio__AlternativeAnswerLibrarySync__c`
- `avnio__RFxProjectConfiguration__c`
- `avnio__RFxResponseConfiguration__c`
- `avnio__AvnioRFxConfigSetting__c`
- `avnio__AvnioRFxSmartComposeSetting__c`

### Status
- UNVERIFIED: Whether Avnio is still active or deprecated
- UNVERIFIED: Whether any Avnio data feeds into AIRFX pipeline
- Likely legacy — AIRFX was built as a replacement

## 6. Data Cloud / RAG Pipeline

### Confirmed
- Prompt template: `DataCloud_RFP_Answer` — confirmed via code references
- 2 active retrievers: HECVAT Assessments, Whitepapers — confirmed via Content_Source_Config__mdt
- Answer generation uses `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate` — confirmed via code

### UNVERIFIED
- What Data Cloud objects/DMOs are configured
- What search indices exist and their record counts
- Whether HECVAT documents are chunked and indexed or queried differently
- Whether Whitepaper GovCloud Plus content is actually ingested
- Whether Data Cloud is the source of truth or if Knowledge__kav feeds into it
- Retriever configuration (chunk size, overlap, similarity threshold)

## 7. Honest Gaps Assessment

### What IS grounded (confirmed in CMDT + engine)
- Hyperforce region availability (18 countries) — in CMDT and engine
- Hard No keywords (17) — in CMDT (engine wiring UNVERIFIED)
- FedRAMP certification scope (13 products) — in CMDT (engine wiring UNVERIFIED)
- Content lane routing (5 configs) — in CMDT, consumed by ContentRouter
- Deterministic triage rules (90+ rules) — hardcoded in Apex, not in CMDT
- Pre-filter terms (~160 functional, ~84 security) — hardcoded in Apex

### What we THINK is grounded but cannot confirm
- Knowledge article quality and currency (1,881 articles, content not audited)
- HECVAT document accuracy (source PDFs not version-checked)
- Whitepaper content freshness
- AI-generated answer factual accuracy (RAG retrieval quality unknown)
- Whether Product_Region__mdt "unconfirmed" caveats are resolved or stale

### What is NOT grounded
- Sub-processor details (Cloudflare, AWS, WithSecure) — no CMDT
- SLA terms (RPO/RTO, uptime commitments) — hardcoded in Apex only
- Encryption capabilities by product — no CMDT
- Log retention periods by feature — hardcoded in Apex only
- Breach notification timelines — hardcoded in Apex only
- Country × product × capability matrix — partially in Product_Region__mdt but most entries say "unconfirmed"
- 339 unflagged GPS_ResponseNew__c records — not triaged

### Critical unknowns
1. **Data Cloud indexing status** — Cannot verify from Apex/SOQL what is actually indexed and retrievable. Need Data Cloud admin UI inspection.
2. **RAG retrieval quality** — AI-generated answers exist but grounding quality is unaudited. Sample review (Task 2) shows coherent but unverified prose.
3. **CMDT → Engine wiring** — 5 of 8 CMDTs may not be consumed by the engine at runtime. They exist as reference data but the engine still uses hardcoded values.
4. **Source document completeness** — Only 3 of 8+ planned source docs are tracked. FedRAMP, Shield, IRAP, MuleSoft, and Tableau docs still need manual fetch.
