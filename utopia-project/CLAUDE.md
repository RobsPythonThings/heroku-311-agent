# AIRFX — Agentforce RFP Flagging Engine

Owner: Robert Smith
Org: Salesforce (internal tooling for SE/RFx team)
Last updated: 2026-03-08

## Project Overview

AIRFX is a deterministic security-flagging engine for RFP/RFx responses, integrated with Salesforce Agentforce. It triages security questions from RFP questionnaires, auto-flags them Red/Yellow/Green, classifies them as Functional or Security, and generates answers using Data Cloud RAG retrieval (HECVAT + Whitepapers).

## Org Structure

### Agentforce Bundles
```
genAiPlannerBundles/
  Utopia_RFP_Agent/           # Main RFP agent
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
| `AIRFX_AgentAction` | Invocable entry point. Resolves project, calls flagging + content routing. Writes `Security_Flag__c`, `Response_Flag_Reason__c`, `Question_Classification__c`. |
| `AIRFX_SecurityPreFilter` | Keyword pre-filter. ~160 FUNCTIONAL_TERMS, ~84 SECURITY_TERMS. Word-boundary matching. Classifies questions as functional (auto-Green) or security (pass to rules). |
| `AIRFX_ResponseFlagInvocable` | Core 90+-rule deterministic flag engine. First match wins. NO_MATCH split: no security terms → Green (functional), security terms → Yellow (needs review). |
| `AIRFX_ResponseFlagInvocableTest` | 170 tests. Covers all rule types, NO_MATCH split, classification, obligation, product dimensions, adversarial, and YELLOW mining. |
| `AIRFX_GenerateAnswer` | Single answer via `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('DataCloud_RFP_Answer', ...)` |
| `AIRFX_GenerateBatchAnswers` | Batch answer generation for multiple questions |
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
- Prompt template: `DataCloud_RFP_Answer`
- 2 active retrievers: HECVAT, Whitepapers (Knowledge retrievers removed)
- Inputs: `Input:Question`, `Input:PS_Section_Name`

## Triage Pipeline

```
Question → AIRFX_AgentAction.triageProject()
  → Gate 1: AIRFX_SecurityPreFilter.evaluate(question)
      if skipAsGreen=true → GREEN (classification: Functional)
  → Gate 2: AIRFX_ResponseFlagInvocable (74 rules, first match wins)
      if rule matches → flag per rule (classification: Security)
  → Gate 3: NO_MATCH split
      if no security terms → GREEN "NO_MATCH_FUNCTIONAL" (classification: Functional)
      if security terms → YELLOW "NO_MATCH_SECURITY" (classification: Security)
```

### PreFilter Logic
- Normalizes question (lowercase, strip non-alphanumeric, collapse whitespace)
- Scans for FUNCTIONAL_TERMS (~160) and SECURITY_TERMS (~84)
- Security terms always win (pass through to rules)
- Only functional terms → auto-Green
- Neither → pass through (NO_MATCH split decides)
- Word-boundary matching: `' ' + text + ' '` contains `' ' + term + ' '`

### Rule Types
- `BINARY_CAN` — Salesforce can do this → GREEN
- `BINARY_CANNOT` — Salesforce cannot do this → RED
- `BINARY_CAN_DIFFERENTLY` — meets intent but not letter → YELLOW (11 rules)
- `NUMERIC_MIN` / `NUMERIC_MAX` — threshold comparison → GREEN/RED
- `NUMERIC_TIERED_MIN` — 3-tier (e.g., uptime: <99.7% GREEN, 99.7-99.9% YELLOW, >99.9% RED)
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

## Architecture: CMDT Country Logic (Next)

**Goal:** Build `Country_Capability__mdt` to power country×product×capability matrix the agent can query.

**Injection point options:**
1. **Prompt template grounding** — Query CMDT in Apex, inject as structured context into prompt template. Agent gets country-specific facts without needing to reason about the matrix.
2. **Apex engine consumption** — `AIRFX_ResponseFlagInvocable` reads CMDT at runtime instead of hardcoded `ALLOWED_DATA_COUNTRIES`. More rules, less hardcoding.
3. **Both** — Engine uses CMDT for deterministic flags, prompt template gets CMDT summary for answer grounding.

**CMDT schema (proposed):**
```
Country_Capability__mdt
  Country_Code__c        (Text, e.g. 'US', 'DE', 'AU')
  Product_Cloud__c       (Text, e.g. 'Core', 'GovCloud', 'Hyperforce', 'MuleSoft')
  Capability__c          (Text, e.g. 'Data Residency', 'FIPS 140-2', 'Citizen Support')
  Available__c           (Checkbox)
  Notes__c               (Long Text — nuances, caveats, effective dates)
  Region_Name__c         (Text, e.g. 'AWS ap-southeast-2')
```

**Agent weakness this addresses:** Data residency, FIPS, citizen support, and product-specific on-prem questions currently rely on hardcoded Apex or hit NO_MATCH. A CMDT matrix lets the engine answer definitively and gives the prompt template grounding material for country-specific answers.

## Roadmap (Priority Order)

1. **Country CMDT build** — Create `Country_Capability__mdt` with country×product×capability matrix. Wire into engine + prompt template.
2. **Manual source doc downloads** — 5 docs need manual fetch (fedramp, shield, irap, mulesoft, tableau). See `docs/review-needed.md`.
3. **More CAN_DIFFERENTLY rules** — product-specific on-prem (MuleSoft, Tableau Server), per-product ACRs, breach notification timeline.
4. **Bid-specific answer grounding** — inject customer name, industry, region into prompt template.
5. **Full CMDT rule migration** — move `buildRules()` data to `Capability_Rule__mdt`. Hybrid: Apex engine logic + CMDT rule data.

## Performance

- **CPU time**: ~6,500ms for 348 records (65% of 10,000ms governor limit)
- **Estimated max capacity**: ~530 records per invocation
- **Live validation**: Engine confirmed on P-0042 (348 questions, 288G/60Y/0R), P-0014 (66 questions), P-4331 (471 questions)
- **CSV validation**: 6,539 historical questions processed (262 batches, 0 failures)

## Deployment

```bash
# Deploy classes
sf project deploy start --source-dir force-app/main/default/classes -o <org-alias>

# Deploy specific files
sf project deploy start --source-dir force-app/main/default/classes/AIRFX_ResponseFlagInvocable.cls force-app/main/default/classes/AIRFX_ResponseFlagInvocableTest.cls --wait 10

# Run tests
sf apex run test --class-names AIRFX_ResponseFlagInvocableTest --wait 10

# Destructive deploy (delete classes)
sf project deploy start --manifest /path/to/package.xml --post-destructive-changes /path/to/destructiveChanges.xml -o <org-alias>
```

## Git Notes

- Default org: `utopia-uat` (`rsmith2utopia@salesforce.com.2025uat`)
- Do NOT use `git add -A` — repo parent dir contains home directory files. Always stage specific files.
