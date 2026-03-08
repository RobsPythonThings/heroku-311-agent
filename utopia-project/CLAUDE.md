# AIRFX — Agentforce RFP Flagging Engine

Owner: Robert Smith
Org: Salesforce (internal tooling for SE/RFx team)
Last updated: 2026-03-08 (evening)

## Project Overview

AIRFX is a deterministic security-flagging engine for RFP/RFx responses, integrated with Salesforce Agentforce. It triages security questions from RFP questionnaires, auto-flags them Red/Yellow/Green, classifies them as Functional or Security, and generates answers using Data Cloud RAG retrieval (HECVAT + Whitepapers).

## Org Structure

### Agentforce Bundles
```
genAiPlannerBundles/
  Utopia_RFP_Agent/           # Main RFP agent (2 topics)
    localActions/
      RFP_Project_Management/           # Topic 1: project-based triage
        Utopia_Triage_and_Route_Project    # Entry point — calls AIRFX_AgentAction
        Utopia_Check_Answer_Progress       # Polls batch answer status
        Generate_RFP_Answer                # Single-question answer gen
        Utopia_Answer_All_Yellow_Questions  # Batch answer for Yellows
      Conversational_Security_QA/        # Topic 2: standalone Q&A (no project context)
        Utopia_Conversational_Answer       # CMDT + ADL retrieval, no record lookup
  EmployeeCopilotPlanner/     # Separate agent (translations, case studies, CRM)
```

### Apex Classes (Active)

| Class | Purpose |
|-------|---------|
| `AIRFX_AgentAction` | Invocable entry point. Resolves project, calls flagging + content routing. Writes `Security_Flag__c`, `Response_Flag_Reason__c`, `Question_Classification__c`. |
| `AIRFX_SecurityPreFilter` | Keyword pre-filter. ~160 FUNCTIONAL_TERMS, ~87 SECURITY_TERMS (added AI data privacy terms 2026-03-08). Word-boundary matching. Classifies questions as functional (auto-Green) or security (pass to rules). |
| `AIRFX_ResponseFlagInvocable` | Core 94+-rule deterministic flag engine. First match wins. Gate 2.5 conditional commitment detector downgrades Green → Yellow when question contains open-ended compliance language. NO_MATCH split: no security terms → Green (functional), security terms → Yellow (needs review). Confidence scoring hits all 6 CMDTs. |
| `AIRFX_ResponseFlagInvocableTest` | 236 tests. Covers all rule types, NO_MATCH split, classification, obligation, product dimensions, adversarial, YELLOW mining, uptime tiers, confidence scoring, and Gate 2.5 conditional commitment detection. |
| `AIRFX_ConversationalAnswer` | Standalone Q&A — no project/record context needed. Queries all 6 CMDTs for grounding, calls DataCloud_RFP_Answer template with ADL retrievers. Prevents "Record not found" errors on conversational questions. |
| `AIRFX_ConversationalAnswerTest` | 5 tests. Input validation, CMDT context with/without country/product, null safety. |
| `AIRFX_GenerateAnswer` | Single answer via `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('DataCloud_RFP_Answer', ...)` |
| `AIRFX_GenerateBatchAnswers` | Batch answer generation for multiple questions (Queueable chain) |
| `AIRFX_CheckAnswerProgress` | Polls batch job status |
| `AIRFX_ContentRouter` | Content lane routing (org-only, not in local codebase). Reads `Content_Source_Config__mdt`. |

### Key Objects & Fields
- `GPS_ResponseNew__c` — main RFP response record
  - `Security_Flag__c` — Red/Yellow/Green flag
  - `Response_Flag_Reason__c` — human-readable reason
  - `Question_Classification__c` — 'Functional' or 'Security' (written by engine)
  - `AI_Generated_Answer__c` — RAG-generated answer
  - `PS_Section_Name__c` — section name for RAG context
- `GPS_Project__c` — RFP project record
  - `Product_Type__c` — e.g. 'Sales Cloud', 'Government Cloud Plus'
  - `Country__c` — deal country code (US, DE, AU, etc.)
- `Content_Source_Config__mdt` — CMDT for content lane routing (HECVAT/Whitepapers). Knowledge lane disabled.
- `Source_Document__mdt` — CMDT tracking fetched compliance source documents

### Data Cloud / RAG
- Prompt template: `DataCloud_RFP_Answer` (version _10)
- 4 active retrievers: File_ADL_Rob_Unstructure (10), HECVAT_Unified_Filtered (10), Utopia_Knowledge_Clean (2 instances, 5 each)
- 3 inputs: `Input:Question`, `Input:PS_Section_Name`, `Input:CMDTCapabilityContext`
- ADL corpus: 11 SPARC docs, 3 HECVAT assessments, 2 infra docs, 13 compliance text files
- Knowledge retriever disabled intentionally — kept in CMDT config but inactive in template
- Uptime RAG constraint: prompt template instructs LLM not to freelance SLA percentages

## Triage Pipeline

```
Question → AIRFX_AgentAction.triageProject()
  → Gate 1: AIRFX_SecurityPreFilter.evaluate(question)
      if skipAsGreen=true → check Gate 2.5, then GREEN (classification: Functional)
  → Gate 2: AIRFX_ResponseFlagInvocable (94+ rules, first match wins)
      if BINARY_CAN matches → check Gate 2.5, then GREEN (classification: Security)
  → Gate 2.5: detectConditionalCommitment(question)
      if conditional language found → YELLOW (overrides Green from Gate 1/2/3)
      bypasses known standards (HIPAA, FedRAMP, NIST, etc.)
  → Gate 3: NO_MATCH split
      if no security terms → check Gate 2.5, then GREEN "NO_MATCH_FUNCTIONAL"
      if security terms → YELLOW "NO_MATCH_SECURITY" (classification: Security)
```

### PreFilter Logic
- Normalizes question (lowercase, strip non-alphanumeric, collapse whitespace)
- Scans for FUNCTIONAL_TERMS (~160) and SECURITY_TERMS (~87)
- Security terms always win (pass through to rules)
- Only functional terms → auto-Green
- Neither → pass through (NO_MATCH split decides)
- Word-boundary matching: `' ' + text + ' '` contains `' ' + term + ' '`

### Rule Types
- `BINARY_CAN` — Salesforce can do this → GREEN
- `BINARY_CANNOT` — Salesforce cannot do this → RED
- `BINARY_CAN_DIFFERENTLY` — meets intent but not letter → YELLOW (11 rules)
- `NUMERIC_MIN` / `NUMERIC_MAX` — threshold comparison → GREEN/RED
- `NUMERIC_TIERED_MIN` — 3-tier (e.g., uptime: ≤99.9% GREEN, >99.9% YELLOW, five nines handled)
- `CONDITIONAL_DATA_RESIDENCY` — country checks against 18 Hyperforce regions

## Salesforce Capabilities (Spring '26)

Key facts for rule authoring:
- **Hyperforce regions**: AU, BR, CA, FR, DE, IN, ID, IE, IL, IT, JP, SG, KR, SE, CH, AE, UK, US
- **Gov Cloud Plus**: AWS US-GOV-WEST/EAST, FedRAMP High authorized
- **RPO/RTO**: 4 hours / 12 hours (SPARC targets)
- **Log retention**: Login History 6mo, Setup Audit Trail 180d, Field History 18mo, Shield LoginEvent 10yr
- **Sub-processors**: AWS (primary), Cloudflare (WAF/DDoS/CDN), WithSecure (file scanning)
- **CDN**: Akamai, CloudFront, Cloudflare, Fastly — ALL global, data transits any country
- **Einstein/AI data residency**: Many features US-only

## Yellow Flag Semantics

Engine produces two kinds of Yellow:
1. **Rule-matched Yellow** (`BINARY_CAN_DIFFERENTLY`) — "We meet the intent but not the letter." Pre-written alternative response included.
2. **NO_MATCH_SECURITY Yellow** — Security question with no rule match. Needs human review + RAG answer.

Functional questions (no security terms) that don't match rules are auto-Green (`NO_MATCH_FUNCTIONAL`), not Yellow.

## Architecture: CMDT Integration (Delivered)

**Status:** Delivered and live. 8 CMDT objects with 200+ records power both the flag engine and prompt template grounding.

**Implementation:** Option 3 (Both) — engine reads CMDT at runtime for deterministic flags, prompt template gets CMDT plain-English summary for answer grounding via `buildCMDTCapabilityContext()`.

**Active CMDT objects:**
| Object | Records | Purpose |
|--------|---------|---------|
| `Hyperforce_Region__mdt` | 31 | Country → AWS region mapping, availability |
| `Product_Region__mdt` | 126 | Product × country data residency matrix |
| `Certification__mdt` | 13 | ISO, FedRAMP, SOC certifications by product |
| `Feature_Availability__mdt` | 8 | Base vs add-on features (Shield, BYOK, etc.) |
| `Hard_No__mdt` | 17 | Absolute capability limits (on-prem, escrow, etc.) |
| `Regulatory_Framework__mdt` | 17 | Country regulations, adequacy, cross-border transfer |
| `Content_Source_Config__mdt` | 5 | Content lane routing (HECVAT/Whitepapers) |
| `Source_Document__mdt` | 3 | Fetched compliance source document tracking |

**Architecture decisions:**
- No `Salesforce_Security_Position__c` object — `RFX_AI_Generated_Answer__c` already exists and serves the same purpose
- No CMDT rule migration — flag logic stays in Apex (`buildRules()`). CMDT stores facts, Apex stores logic.
- Keyword lists (FUNCTIONAL_TERMS, SECURITY_TERMS) remain hardcoded in Apex — CMDT migration is a future option but not prioritized
- Knowledge retriever disabled intentionally in prompt template — HECVAT + ADL provide better grounding

## Roadmap (Priority Order)

1. **Government RFP pre-filter expansion** — Add proposer, subcontractor, deployment method terms to FUNCTIONAL_TERMS/SECURITY_TERMS for better gov RFP classification.
2. **SE feedback loop** — Currently inactive (98.3% of AI answers have no acceptance/rejection). Need UI or flow to capture SE verdict on generated answers.
3. **Flag override mechanism** — Let SEs override engine flags with justification, logged in Response_Flag_Reason__c. Not yet built.
4. **Norway country verification** — P-3333/P-3334 have Norway context; verify Hyperforce_Region__mdt and Product_Region__mdt coverage for NO.
5. **safe_to_ingest.csv ingestion** — 3,534 rows of validated Q&A pairs pending ingestion into Knowledge or Data Cloud.
6. **More CAN_DIFFERENTLY rules** — product-specific on-prem (MuleSoft, Tableau Server), per-product ACRs, breach notification timeline.
7. **Bid-specific answer grounding** — inject customer name, industry, region into prompt template.
8. **GovCloud bleed-through fix** — Prompt template answers for non-GovCloud deals cite FedRAMP High / IL4/IL5. Template needs product-context filtering.

## Performance

- **CPU time**: ~6,500ms for 348 records (65% of 10,000ms governor limit)
- **Estimated max capacity**: ~530 records per invocation
- **Live validation**: Engine confirmed on P-0042 (348q, 294G/54Y/0R), P-0014 (66q), P-4331 (471q), P-6405 (409q, 360G/49Y/0R), P-6360 (27q, 21G/6Y/0R)
- **CSV validation**: 6,539 historical questions processed (262 batches, 0 failures)
- **Mike gospel rows**: 79 certified regression test rows
- **Mike validation**: 90.5% agreement (286/316) with expert judgment (post-Gate 2.5)

## Active Docs (`docs/`)

| File | Purpose |
|------|---------|
| `accuracy_corrections.md` | 14 cross-reference findings against Spring '26 grounding — KB staleness audit |
| `accuracy_gauntlet.md` | 20-question stress test: Run 1 (10/20), root causes, fixes, Run 2 (20/20) |
| `yellow_triage_analysis.md` | P-0042 Yellow breakdown (45→28 path), category analysis, conversion recommendations |
| `suspicious_reds.md` | Red audit: 51 records, 4 action items (SOURCE_CODE, CUI, CUSTOMER_VM, Norway) |
| `morning_fixes_results.md` | 5 targeted fixes: SOURCE_CODE, CUI, CUSTOMER_VM, BREACH_TIMELINE, SECURITY_POSTURE |
| `project_health_report.md` | Overall engine health: rule coverage, test counts, performance, deployment status |
| `cmdt_wiring_verification.md` | Regulatory_Framework__mdt CMDT integration verification |
| `benchmark_final.md` | Latest benchmark results (P-0042, P-0014, P-4331) |
| `csv_final_accuracy_report.md` | CSV validation: 6,539 historical questions, accuracy breakdown |
| `adversarial_tests.md` | Adversarial test scenarios and results |
| `production_readiness.md` | Production readiness checklist |
| `SE_GUIDE.md` | SE-facing guide for using AIRFX flags |
| `monday_slack.md` | Slack update draft for Monday standup |
| `yellow_to_green_upgrades.md` | Yellow-to-Green conversion tracking |
| `p6360_triage_audit.md` | P-6360 triage audit: 24/27 correct (89%), 3 misflags, root causes |
| `p6360_hard_audit.md` | P-6360 hard audit: full answer quality review (3 STRONG, 2 BORDERLINE, 1 WEAK) |
| `gate25_validation.md` | Gate 2.5 conditional commitment detector: validation results, Mike comparison, org impact |
| `mike_final_validation.md` | Mike Rosa validation: 316 records, agreement analysis, error direction |
| `source_docs/` | Fetched compliance source documents |

Superseded files archived to `docs/archive/`.

## Deployment

```bash
# Deploy classes
sf project deploy start --source-dir force-app/main/default/classes -o <org-alias>

# Deploy specific files
sf project deploy start --source-dir force-app/main/default/classes/AIRFX_ResponseFlagInvocable.cls force-app/main/default/classes/AIRFX_ResponseFlagInvocableTest.cls --wait 10

# Run all AIRFX tests (241 tests)
sf apex run test --class-names AIRFX_ResponseFlagInvocableTest AIRFX_ConversationalAnswerTest --wait 10

# Deploy agent bundle
sf project deploy start --source-dir force-app/main/default/genAiPlannerBundles/Utopia_RFP_Agent -o <org-alias> --wait 10

# Destructive deploy (delete classes)
sf project deploy start --manifest /path/to/package.xml --post-destructive-changes /path/to/destructiveChanges.xml -o <org-alias>
```

## Git Notes

- Default org: `utopia-uat` (`rsmith2utopia@salesforce.com.2025uat`)
- Do NOT use `git add -A` — repo parent dir contains home directory files. Always stage specific files.
