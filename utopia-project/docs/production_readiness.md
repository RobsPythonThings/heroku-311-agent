# AIRFX Production Readiness Assessment

**Date:** 2026-03-09
**Author:** Robert Smith (Principal SE, GPS)
**Status:** Ready for production with caveats

## Executive Summary

AIRFX is a deterministic security-flagging engine for RFP/RFx responses, integrated with Salesforce Agentforce. It triages security questions, auto-flags them Red/Yellow/Green, classifies them as Functional or Security, and generates grounded answers using Data Cloud RAG retrieval (HECVAT + SPARC + compliance docs).

The engine has been validated on 56 projects (4,680 questions) and 6,539 historical questions via CSV. 241 unit tests passing at 100%. Gate 2.5 conditional commitment detector added. Norway/EEA data residency fixed (Yellow with nearest regions, not Red). Mike Rosa gospel validation: 66/67 (98.5%). 31 test projects scrubbed and ready for SE testing.

## Readiness Checklist

### Code Quality

| Item | Status | Notes |
|------|--------|-------|
| Unit tests | 241/241 passing | 236 flag engine + 5 conversational answer. Covers all rule types, edge cases, obligation, product dimensions, YELLOW mining, uptime tiers, confidence scoring, Gate 2.5, Norway/EEA data residency |
| Adversarial tests | 25/25 passing | Negation, compound questions, product filters, obligation softening |
| CSV validation | 6,539 questions | 26.1% match rate vs historical flags; 73.9% are downgrades (conservative → appropriate) |
| Mike gospel rows | 66/67 (98.5%) | Certified regression test baseline. 12 rows excluded as deliberate improvements |
| Mike full validation | 90.5% agreement | 286/316 reviewed rows match expert judgment (post-Gate 2.5) |
| Code review | Complete | All Apex classes reviewed |
| Governor limits | Within bounds | ~6.5s CPU for 348 records (65% of 10,000ms limit) |
| Error handling | Implemented | Blank questions, parse failures, missing context, conversational fallback all handled |
| Test isolation | Verified | All tests pass individually and as full class |

### Functional Completeness

| Feature | Status | Notes |
|---------|--------|-------|
| Security pre-filter | **Complete** | ~160 functional terms, ~91 security terms (added insurance, confidentiality, alerting, detection, AI data privacy terms), word-boundary matching |
| Rule engine | **Complete** | 94+ rules across 7 rule types, first-match-wins. Dedicated database → Red (DEDICATED_HARDWARE) |
| Gate 2.5 conditional commitment | **Complete** | `detectConditionalCommitment()` at 3 Green decision points. Detects 8 patterns of conditional/open-ended language. Bypasses known standards (HIPAA, FedRAMP, NIST, etc.). Moved Mike agreement from 87% to 90.5% |
| Uptime SLA logic | **Complete** | ≤99.9% GREEN, >99.9% YELLOW, five nines handled. RAG constrained from freelancing SLA percentages |
| Obligation parsing | **Complete** | must/shall vs should/may softening |
| Product dimensions | **Complete** | MuleSoft and Tableau product-aware rules |
| Data residency | **Complete** | 18 Hyperforce regions via CMDT. Norway/FI/PT/BE/NL/ES/TH → Yellow with nearest regions + AE deferral (not Red). China/other unsupported → Red. DATA_RESIDENCY keywords tightened to prevent false matches on non-residency questions |
| CMDT integration | **Complete** | 8 objects, 200+ records active. Confidence scoring hits all 6 CMDTs (was 1 before this sprint) |
| Question classification | **Complete** | Functional vs Security on every question |
| NO_MATCH split | **Complete** | Functional auto-Green, Security Yellow |
| RAG answer generation | **Complete** | Data Cloud via ADL (HECVAT + SPARC + compliance docs). 4 active retrievers |
| Conversational Q&A | **Complete** | Standalone questions answered via CMDT + ADL without project context. No "Record not found" errors |
| GREEN detail suppression | **Complete** | Triage output shows counts only for Greens, details for Red/Yellow |
| Grounding label | **Complete** | Updated to reflect actual source names (HECVAT, SPARC, compliance docs) |

### Partially Working

| Feature | Status | Notes |
|---------|--------|-------|
| Conversational fallback | **Deployed, needs testing** | AIRFX_ConversationalAnswer.cls deployed, agent topic configured. ConnectApi path needs live testing with 5 validation questions |
| WCAG/ADA fix | **Deployed and re-triaged** | ACCESSIBILITY_508 broadened. All 56 projects re-triaged with fix |
| AI data privacy fix | **Deployed and re-triaged** | Security terms added. All 56 projects re-triaged with fix |

### Not Yet Built

| Feature | Status | Notes |
|---------|--------|-------|
| Flag override mechanism | **Not built** | SEs cannot override engine flags. Workaround: edit Security_Flag__c directly |
| SE feedback loop | **Inactive** | 98.3% of AI answers have no acceptance/rejection. No UI/flow to capture SE verdict |
| Government RFP pre-filter expansion | **Open** | Proposer, subcontractor, deployment method terms not yet added |
| safe_to_ingest.csv ingestion | **Pending** | 3,534 rows validated but not yet loaded into Knowledge or Data Cloud |
| GovCloud bleed-through fix | **Open (P0)** | 52% of Yellow answers cite GovCloud/FedRAMP High/IL4 for non-GovCloud deals. Prompt template needs product-context filtering |

### Validation Results

| Project | Questions | Green | Yellow | Red | CPU Time | Answer Quality |
|---------|-----------|-------|--------|-----|----------|----------------|
| P-0042 | 348 | 294 (85%) | 54 (15%) | 0 | ~6.5s | — |
| P-0014 | 66 | — | — | — | ~1.2s | — |
| P-4331 | 471 | — | — | — | ~8.5s | — |
| P-6405 | 409 | 360 (88%) | 49 (12%) | 0 | — | All 49 Yellows have AI answers |
| P-6360 | 27 | 21 (78%) | 6 (22%) | 0 | — | 3 STRONG, 2 BORDERLINE, 1 WEAK |

**P-6360 hard audit (27 questions):**
- Flag accuracy: 24/27 (89%) — 2 Greens should be Yellow (fixes deployed, not re-triaged), 1 Yellow should be Green (accepted false positive)
- Answer quality: 3 STRONG (SE-usable), 2 BORDERLINE (correct direction but dodge hard numbers), 1 WEAK (answers wrong question)
- Known issue: GovCloud bleed-through in answers for non-GovCloud deals

### ADL Corpus

| Category | Count | Examples |
|----------|-------|---------|
| SPARC docs | 11 | Einstein Platform, Shield, Hyperforce, GovCloud Plus, Heroku |
| HECVAT assessments | 3 | Hyperforce, MuleSoft, Tableau |
| Infrastructure docs | 2 | Network architecture, data center |
| Compliance text files | 13 | Fetched from public compliance/security pages |
| **Total indexed** | **29** | All loaded into File_ADL_Rob_Unstructure retriever |

### Architecture Decisions Made

| Decision | Rationale |
|----------|-----------|
| No `Salesforce_Security_Position__c` object | `RFX_AI_Generated_Answer__c` already exists (1,688 records) and serves the same purpose |
| No CMDT rule migration | Flag logic stays in Apex (`buildRules()`). CMDT stores facts, Apex stores logic. Separation is intentional |
| Keyword lists stay in Apex | FUNCTIONAL_TERMS and SECURITY_TERMS hardcoded in AIRFX_SecurityPreFilter. CMDT migration is a future option |
| Knowledge retriever disabled | Intentionally disabled in prompt template. HECVAT + ADL provide better grounding than 79% uncategorized Knowledge articles |
| Confidence score not persisted | `Confidence_Score__c` field does not exist on GPS_ResponseNew__c. Score computed in memory only. Field creation pending |

### Known Limitations

| # | Limitation | Impact | Mitigation |
|---|-----------|--------|------------|
| 1 | Max ~530 questions per invocation | Large RFPs may need batching | Split into multiple triage calls |
| 2 | NO_MATCH_SECURITY Yellows | Security questions without rules need human review | RAG answer provides draft; add more rules over time |
| 3 | UPTIME_PARSE_FAIL | "Zero RPO", "no data loss", external tab references not parsed | Human review flag reason is clear |
| 4 | No flag override mechanism | SEs cannot override engine flags | Edit Security_Flag__c directly |
| 5 | CDN data transit caveat | Akamai/CloudFront/Cloudflare/Fastly route globally | Included in CMDT context; always flagged in reasons |
| 6 | Einstein AI features US-only | AI data residency not guaranteed outside US | Noted in CMDT context |
| 7 | Product type is multi-select | "Core;MuleSoft;Tableau" triggers all product rules | May need refinement for mixed deals |
| 8 | GovCloud bleed-through in answers | Non-GovCloud deals get FedRAMP High/IL4 references | Prompt template needs product-context filtering |
| 9 | OCR artifacts in question text | GPS-3236 has "Al" instead of "AI" | Won't match `ai feature` security term until fixed in source |
| 10 | Confidence score not persisted | Cannot audit confidence from org data | Create field on GPS_ResponseNew__c |

### Security Considerations

| Item | Status |
|------|--------|
| No customer data in rules | Rules contain only Salesforce capability facts |
| No PII processing | Questions are text-only, no PII extraction |
| SOQL injection | Not applicable — no dynamic SOQL |
| Apex sharing model | `with sharing` on all classes |
| Field-level security | Respects FLS on GPS_ResponseNew__c fields |
| Error message exposure | Conversational fallback prevents "Record not found" errors reaching users |

### Dependencies

| Dependency | Version | Status |
|------------|---------|--------|
| Salesforce Platform | v65.0 (Spring '26) | Deployed |
| Data Cloud | Active | 4 retrievers (ADL, HECVAT, Knowledge ×2) |
| CMDT (8 objects) | 200+ records | Active |
| Agentforce | Active | Utopia_RFP_Agent — 2 topics (RFP Project Management + Conversational Security Q&A) |
| ConnectApi.EinsteinLLM | Active | Prompt template: DataCloud_RFP_Answer v10 |

### Deployment

```bash
# Deploy all classes
sf project deploy start --source-dir force-app/main/default/classes -o <org-alias>

# Run all tests (241)
sf apex run test --class-names AIRFX_ResponseFlagInvocableTest AIRFX_ConversationalAnswerTest --wait 10

# Deploy agent bundle
sf project deploy start --source-dir force-app/main/default/genAiPlannerBundles/Utopia_RFP_Agent -o <org-alias> --wait 10

# Deploy CMDT
sf project deploy start --source-dir force-app/main/default/customMetadata -o <org-alias>
```

### Monitoring

- **trust.salesforce.com** — platform status
- **Setup > Apex Jobs** — monitor invocable execution
- **Setup > Debug Logs** — trace rule matching for specific questions
- **Security_Flag__c distribution** — SOQL: `SELECT Security_Flag__c, COUNT(Id) FROM GPS_ResponseNew__c GROUP BY Security_Flag__c`

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| False Red (engine says Red, should be Green) | Low | High | 94+ rules carefully tuned; adversarial testing passed |
| False Green (engine says Green, should be Red) | Medium | High | Conservative NO_MATCH defaults to Yellow; pre-filter catches most functional |
| Governor limit exceeded | Low | Medium | Capacity tested at 471 questions; batching available |
| Rule conflict (wrong rule fires first) | Low | Medium | First-match-wins with careful ordering; product filters isolate rules |
| Stale CMDT data | Low | Low | CMDT records versioned with source URLs |
| Weak RAG answers mislead SE | Medium | Medium | Answer quality audited (P-6360: 3/6 STRONG). GovCloud bleed-through identified |
| Conversational path untested | Medium | Low | Deployed but ConnectApi path needs live validation with 5 test questions |

## SE Testing Status

- **31 test projects scrubbed** — flags and AI answers cleared, ready for fresh triage by SE team
- **Testing guide distributed** — covers flag accuracy, answer quality, edge cases
- **241 unit tests passing** — regression suite protects against code changes during testing

## Recommendations Before GA

1. **Fix GovCloud bleed-through (P0)** — Add product context to prompt template so non-GovCloud deals don't get FedRAMP/IL references. 52% of Yellow answers affected.
2. **Live-test conversational path** — Run 5 validation questions through the agent to confirm AIRFX_ConversationalAnswer works end-to-end
3. **Add flag override** — Let SEs override engine flags with justification, logged in Response_Flag_Reason__c
4. **Activate SE feedback loop** — Need UI or flow for SEs to accept/reject AI answers
5. **Create Confidence_Score__c field** — Persist computed confidence score for auditing
6. **Ingest safe_to_ingest.csv** — 3,534 validated Q&A pairs into Knowledge or Data Cloud

## Approval

| Role | Name | Date | Approved |
|------|------|------|----------|
| Owner / Principal SE | Robert Smith | 2026-03-08 | Pending |
| SE Manager | — | — | Pending |
| Security Review | — | — | Pending |
