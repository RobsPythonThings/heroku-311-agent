# AIRFX — Agentforce RFP Flagging Engine

Owner: Robert Smith
Org: Salesforce (internal tooling for SE/RFx team)
Last updated: 2026-03-07

## Project Overview

AIRFX is a deterministic security-flagging engine for RFP/RFx responses, integrated with Salesforce Agentforce. It triages security questions from RFP questionnaires, auto-flags them Red/Yellow/Green, and generates answers using Data Cloud RAG retrieval.

**Problem it solves:** Security teams are drowning in Yellow-flagged questions (3,009 Yellows vs 1,272 Greens across the org). Most are functional questions that don't need security review.

## Org Structure

### Agentforce Bundles
```
genAiPlannerBundles/
  Utopia_RFP_Agent/           # Main RFP agent
    plannerActions/
      AnswerQuestionsWithKnowledge   # Data Cloud RAG retriever
    localActions/
      RFP_Project_Management/
        Utopia_Triage_and_Route_Project   # Entry point — calls AIRFX_AgentAction
        Utopia_Check_Answer_Progress      # Polls batch answer status
        Generate_RFP_Answer               # Single-question answer gen
        Utopia_Answer_All_Yellow_Questions # Batch answer for Yellows
  EmployeeCopilotPlanner/     # Separate agent (translations, case studies, CRM)
```

### Apex Classes (Active)

| Class | Purpose |
|-------|---------|
| `AIRFX_AgentAction` | Invocable entry point for Agentforce. Resolves project, calls flagging + content routing. Writes `Security_Flag__c` and `Response_Flag_Reason__c`. |
| `AIRFX_SecurityPreFilter` | Keyword-based pre-filter. Classifies questions as functional (auto-Green) or security (pass through to rules). ~160 FUNCTIONAL_TERMS, ~80 SECURITY_TERMS. Word-boundary matching. |
| `AIRFX_ResponseFlagInvocable` | Core 74-rule deterministic flag engine (~950 lines). Rule types: BINARY_CAN, BINARY_CANNOT, BINARY_CAN_DIFFERENTLY, NUMERIC_MIN, NUMERIC_MAX, NUMERIC_TIERED_MIN, CONDITIONAL_DATA_RESIDENCY. First match wins. |
| `AIRFX_ResponseFlagInvocableTest` | 94 tests. Covers all rule types and edge cases. |
| `AIRFX_GenerateAnswer` | Single answer via `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('DataCloud_RFP_Answer', ...)` |
| `AIRFX_GenerateBatchAnswers` | Batch answer generation for multiple questions |
| `AIRFX_CheckAnswerProgress` | Polls batch job status |
| `AIRFX_MillingResponseOrchestrator` | Orchestrator for response milling workflow |
| `AIRFX_PromptResponseJsonIngestInvocable` | Ingests JSON prompt responses into records |
| `AIRFX_JarvisResponseEngine` | Legacy Jarvis integration (not actively used by AIRFX pipeline) |
| `AIRFX_KnowledgeHtmlStripBatch` | Batch job to strip HTML from Knowledge articles |
| `AIRFX_KnowledgeDraftCleanupBatch` | Batch cleanup of draft Knowledge articles |
| `AskJarvis` / `JarvisService` | Legacy Jarvis service classes |

### Deleted Classes (removed from org 2026-03-07)
- `RFPPreProcessor` / `RFPPreProcessorTest` — early prototype, superseded by AIRFX_SecurityPreFilter
- `YellowFlagQueueable` — debugging utility for re-flagging Yellow records
- `AIRFX_RfpQuestionClassifierService` — called non-existent prompt template, every call threw exception

### Key Objects & Fields
- `GPS_Response__c` — main RFP response record
  - `Security_Flag__c` — Red/Yellow/Green flag
  - `Response_Flag_Reason__c` — human-readable reason
  - `Question_Classification__c` — (exists but NOT written by current pipeline)
  - `Requirement_Type__c` — (exists but NOT written by current pipeline)
  - `PS_Section_Name__c` — section name for RAG context
- `Knowledge__kav` — Knowledge articles for RAG retrieval
  - `Answer_Plain_Text__c` — stripped plain text field
- `Content_Source_Config__mdt` — CMDT for content lane routing (Knowledge/HECVAT/Whitepapers)
- `Source_Document__mdt` — CMDT tracking fetched compliance source documents
  - `Source_URL__c` — original URL
  - `Validated__c` — whether content has been validated
  - `Fetched_Date__c` — date content was fetched

### Data Cloud / RAG
- Prompt template: `DataCloud_RFP_Answer`
- 4 Data Cloud retrievers: Knowledge articles, Knowledge no-filter, HECVAT, Whitepapers
- Inputs: `Input:Question`, `Input:PS_Section_Name`

## Triage Pipeline

```
Question → AIRFX_AgentAction.flagResponses()
  → Gate 1: AIRFX_SecurityPreFilter.evaluate(question)
      if skipAsGreen=true → GREEN "Pre-filter: obvious functional/non-security clause"
  → Gate 2: AIRFX_ResponseFlagInvocable (74 deterministic rules, first match wins)
      if rule matches → flag per rule (RED/GREEN + reason + ruleId)
      if no match → YELLOW "NO_MATCH" (needs human review)
```

### PreFilter Logic
- Normalizes question (lowercase, strip non-alphanumeric, collapse whitespace)
- Scans for FUNCTIONAL_TERMS (~160 terms: dashboard, report, workflow, queue, case management, job matching, etc.)
- Scans for SECURITY_TERMS (~80 terms: encryption, mfa, audit, audits, compliance, vulnerabilities, etc.)
- If security terms found → `skipAsGreen=false` (always pass through to rules)
- If only functional terms → `skipAsGreen=true` (auto-Green)
- If neither → `skipAsGreen=false` (pass through to rules)
- Uses word-boundary matching: `' ' + text + ' '` contains `' ' + term + ' '`
- Standalone broad terms removed ('support', 'provide') — replaced with specific compounds to avoid false greens on security questions

### 74 Deterministic Rules (in ResponseFlagInvocable)
Rule types:
- `BINARY_CAN` — Salesforce can do this → GREEN
- `BINARY_CANNOT` — Salesforce cannot do this → RED
- `BINARY_CAN_DIFFERENTLY` — Salesforce meets the intent but not the letter → YELLOW with pre-written alternative
- `NUMERIC_MIN` — must meet minimum threshold → GREEN/RED
- `NUMERIC_MAX` — must not exceed maximum (e.g., RPO <= 4 hours) → GREEN/RED
- `NUMERIC_TIERED_MIN` — 3-tier threshold (e.g., uptime: <99.7% GREEN, 99.7-99.9% YELLOW, >99.9% RED)
- `CONDITIONAL_DATA_RESIDENCY` — country-specific checks against 18 Hyperforce regions

BINARY_CAN_DIFFERENTLY rules (11):
- BREACH_NOTIFY_METHOD — Notification by email per DPA, not by phone/specific method
- WAF_ALTERNATIVE — Cloudflare WAF at platform edge, not customer-configurable
- ACCESSIBILITY_508 — ACRs published, substantial but not 100% conformance
- CDP_BACKUP — Near-zero RPO via Backup & Recover add-on
- ENCRYPT_ALL_DATA — Shield + infrastructure encryption, not all fields coverable
- FILE_SCANNING — AppExchange partners (WithSecure), not native
- LOG_RETENTION_LONG — Shield LoginEvent 10yr, others exportable
- SIEM_INTEGRATION — Shield Event Monitoring to SIEM via Streaming API
- BACKGROUND_CHECK_GENERAL — SF does checks per own policy, not per customer policy
- ESCROW_INTENT — Business continuity via data portability, not source code
- VULN_SCAN_RESULTS — Summary reports via Trust portal, not raw data

## Source Documents (`docs/source_docs/`)

Compliance source documents fetched for RAG grounding and rule validation. Each has a corresponding `Source_Document__mdt` record.

| File | Source | Status |
|------|--------|--------|
| `trust_compliance_full.txt` | compliance.salesforce.com | Fetched 2026-03-07 |
| `gdpr.txt` | salesforce.com/company/privacy/ | Fetched 2026-03-07 |
| `slack_trust.txt` | slack.com/trust/compliance | Fetched 2026-03-07 |
| `fedramp.txt` | — | Manual download required |
| `shield.txt` | — | Manual download required (JS-rendered) |
| `irap.txt` | — | Manual download required |
| `mulesoft_trust.txt` | — | Manual download required (403) |
| `tableau_trust.txt` | — | Manual download required (redirects) |

See `docs/review-needed.md` for failed fetch details and alternate URLs.

## Historical Flag Analysis (CSV: 6,542 rows, 2021-2023)

Analyzed `/Users/rsmith2/Downloads/Red and Yellow flag kb - Best (1).csv`:
- 3,151 Red flags, 1,425 Yellow flags (4,576 with non-empty answers)
- 14 "standard exception" patterns covering 204 entries
- Top categories: Accessibility (84), Availability (59), Audit Rights (17), RTO (12), RPO (11)

Full analysis: `/tmp/csv_analysis.md`

## Cross-Reference Findings (CSV vs Spring '26 Docs)

Cross-referenced historical flags against:
- Salesforce Security Implementation Guide (Spring '26, v66.0)
- Infrastructure & Sub-processors document (March 2026)

### Outdated Flags (MUST UPDATE)
1. **TLS 1.3 "not supported"** (8+ entries) — NOW SUPPORTED since 2025. Change to GREEN.
2. **"We do not use WAF"** (50+ entries) — Cloudflare WAF is now a sub-processor. Change to YELLOW.
3. **Data residency limitations** — Hyperforce expanded to 18 regions (added Indonesia, Israel, Italy, South Korea, Sweden, Switzerland, UAE, Ireland)

### Flags Needing Nuance (correct but misleading)
4. Accessibility blanket RED (292 entries) → YELLOW with product-specific ACR references
5. 99.9% availability = RED (26+ entries) → YELLOW (target IS ~99.9%, negotiable)
6. 24-hour breach notification = RED (64+ entries) → YELLOW (negotiable via legal DSR)
7. Audit logging conflation → split infrastructure (RED) vs application/Shield (GREEN)
8. Background checks blanket RED (131 entries) → split "do you?" (GREEN) vs "per our policy?" (RED)

### Confirmed Still Correct (25 flags)
- Right to audit = RED
- Source code escrow = RED
- Multi-tenancy limits (no drive destruction, no custom patching) = RED
- 99.99%+ availability = RED
- RPO 4hrs / RTO 12hrs targets = confirmed accurate
- Raw scan data sharing = RED

Full analysis: `/tmp/cross_reference_findings.md`

## Salesforce Capabilities (Spring '26)

Key facts for rule authoring:
- **MFA**: Contractually required for all logins
- **Shield**: Add-on (Platform Encryption AES-256, Event Monitoring 20+ event types, Field Audit Trail)
- **Classic Encryption**: 128-bit AES, 175-char limit, no search/filter
- **Hyperforce regions**: AU, BR, CA, FR, DE, IN, ID, IE, IL, IT, JP, SG, KR, SE, CH, AE, UK, US
- **Gov Cloud Plus**: AWS US-GOV-WEST/EAST, FedRAMP High authorized
- **Log retention**: Login History 6mo, Setup Audit Trail 180d, Field History 18mo, Shield LoginEvent 10yr
- **RPO/RTO**: 4 hours / 12 hours (SPARC targets, not guarantees)
- **Sub-processors**: AWS (primary), Cloudflare (WAF/DDoS/CDN), WithSecure (support case file scanning)
- **CDN**: Akamai, CloudFront, Cloudflare, Fastly — ALL global, data transits any country
- **Einstein/AI data residency**: Many features US-only (Vision, Language, Conversation Insights, Lead Scoring)
- **Support access**: From 23 countries globally

## Team Feedback (Weekly RFx+SE Sync)

### Yellow Flag Definition (from team)
Yellow does NOT mean "unknown/unmatched." Yellow means:
> "We meet the intent of the requirement, but perhaps not the explicit letter."
> Example: "Must notify of breach by phone" → We will notify by email, not phone. Intent met, letter not met.

This maps to a proposed new rule type: `BINARY_CAN_DIFFERENTLY`

### Current Engine Yellow
Engine's current Yellow means "no rule matched, unknown — needs human research." This is the NO_MATCH bucket (3,009 questions).

### Completed
- ✅ `BINARY_CAN_DIFFERENTLY` rule type — 11 rules implemented
- ✅ `NUMERIC_TIERED_MIN` rule type — 3-tier uptime/availability
- ✅ Pre-filter expanded to ~160 functional / ~80 security terms
- ✅ RPO/RTO regex word-boundary fix
- ✅ Red flag drill-down instructions in Agentforce planner bundle
- ✅ Source_Document__mdt created with 3 records
- ✅ 94 tests passing

### Roadmap (Priority Order)
1. **NO_MATCH split** — in `AIRFX_AgentAction`, use PreFilter's `matchedSecurityTerms` at NO_MATCH: empty → Green (functional), non-empty → Yellow (real security question). Biggest Yellow-reduction lever (~100+ per project).
2. **Write Question_Classification__c** — tag records as 'Functional' or 'Security' based on PreFilter. Piggybacks on #1. Enables team list view filtering.
3. **Manual source doc downloads** — 5 docs failed automated fetch (fedramp, shield, irap, mulesoft, tableau). Drop files in `docs/source_docs/`, then create CMDT records. See `docs/review-needed.md`.
4. **More CAN_DIFFERENTLY rules** — team identified ~12-15 standard exceptions, 11 done. Candidates: product-specific on-prem (MuleSoft Anypoint, Tableau Server), accessibility per-product ACRs, breach notification timeline.
5. **Knowledge retriever toggle** — gate RAG retrieval by category so agent can skip for certain question types.
6. **Bid-specific answer grounding** — prompt template refinement to inject customer name, industry, region into generated answers.
7. **CMDT rule migration** — move rule data from `buildRules()` Apex to `Capability_Rule__mdt`. Hybrid approach agreed. Bigger lift, enables admin editing without deploys.

## Architecture Decision (Pending)

**Question:** Should capability rules live in Apex (`buildRules()`) or CMDT (`Capability_Rule__mdt`)?

**Recommendation: Hybrid**
- Apex for engine logic (rule evaluation, keyword matching, flag assignment) — testable, type-safe
- CMDT for rule data (topic, keywords, flag, reason, alternative) — admin-editable, no deploys
- Country×cloud×product matrix is too large for hardcoded Apex, needs CMDT

**Concern from team:** Country-specific rules across all clouds are complex. Not all country×cloud combinations are known. A security-only agent is doable but complex.

## Performance

- **CPU time**: ~5,354ms for 348 records (53.5% of 10,000ms governor limit)
- **Estimated max capacity**: ~650 records per invocation
- **RPO/RTO keywords**: Use `\b` regex word-boundary (`\\brpo\\b`, `\\brto\\b`) to prevent substring false positives (e.g., 'corporate' matching 'rpo')
- **Live validation**: Engine output confirmed exact match with Agentforce agent on P-0042 (348 questions) and P-0014

## Deployment

```bash
# Deploy classes
sf project deploy start --source-dir force-app/main/default/classes -o <org-alias>

# Destructive deploy (delete classes)
# Requires package.xml + destructiveChanges.xml in same directory
sf project deploy start --manifest /path/to/package.xml --post-destructive-changes /path/to/destructiveChanges.xml -o <org-alias>

# Run tests
sf apex run test --test-level RunLocalTests -o <org-alias> --wait 10
```
