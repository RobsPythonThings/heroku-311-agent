# AIRFX Production Readiness Assessment

**Date:** 2026-03-08
**Author:** Robert Smith (Principal SE, GPS)
**Status:** Ready for production with caveats

## Executive Summary

AIRFX is a deterministic security-flagging engine for RFP/RFx responses, integrated with Salesforce Agentforce. It triages security questions, auto-flags them Red/Yellow/Green, classifies them as Functional or Security, and generates answers using Data Cloud RAG retrieval.

The engine has been validated on 3 production projects (P-0042: 348 questions, P-0014: 66 questions, P-4331: 471 questions) with 154 unit tests passing at 100%.

## Readiness Checklist

### Code Quality

| Item | Status | Notes |
|------|--------|-------|
| Unit tests | 154/154 passing | Covers all rule types, edge cases, obligation, product dimensions |
| Adversarial tests | 25/25 passing | Negation, compound questions, product filters, obligation softening |
| Code review | Complete | All Apex classes reviewed |
| Governor limits | Within bounds | ~6.5s CPU for 348 records (65% of 10,000ms limit) |
| Error handling | Implemented | Blank questions, parse failures, missing context all handled gracefully |
| Test isolation | Verified | All tests pass individually and as full class |

### Functional Completeness

| Feature | Status | Notes |
|---------|--------|-------|
| Security pre-filter | Complete | ~160 functional terms, ~84 security terms, word-boundary matching |
| Rule engine | Complete | 84 rules across 7 rule types, first-match-wins |
| Obligation parsing | Complete | must/shall vs should/may softening |
| Product dimensions | Complete | MuleSoft and Tableau product-aware rules |
| Data residency | Complete | 18 Hyperforce regions, country validation |
| CMDT integration | Complete | 194/195 records active, context injected into prompt template |
| Question classification | Complete | Functional vs Security on every question |
| NO_MATCH split | Complete | Functional auto-Green, Security Yellow |
| RAG answer generation | Complete | Data Cloud via HECVAT + Whitepapers retrievers |

### Validation Results

| Project | Questions | Green | Yellow | Red | CPU Time |
|---------|-----------|-------|--------|-----|----------|
| P-0042 | 348 | 278 (80%) | 70 (20%) | 0 | ~6.5s |
| P-0014 | 66 | — | — | — | ~1.2s |
| P-4331 | 471 | — | — | — | ~8.5s |

### Known Limitations

| # | Limitation | Impact | Mitigation |
|---|-----------|--------|------------|
| 1 | Max ~650 questions per invocation | Large RFPs may need batching | Split into multiple triage calls |
| 2 | 43 NO_MATCH_SECURITY Yellows per P-0042 | Security questions without rules need manual review | RAG answer provides draft; add more rules over time |
| 3 | 11 UPTIME_PARSE_FAIL per P-0042 | "Zero RPO", "no data loss" not parsed as numbers | Improve numeric parser for text-based numbers |
| 4 | No flag override mechanism | SEs cannot override engine flags | Planned feature; edit Security_Flag__c directly |
| 5 | CDN data transit caveat | Akamai/CloudFront/Cloudflare/Fastly route globally | Included in CMDT context; always flagged in reasons |
| 6 | Einstein AI features US-only | AI data residency not guaranteed outside US | Noted in CMDT context |
| 7 | Product type is multi-select | "Core;MuleSoft;Tableau" triggers all product rules | May need refinement for mixed deals |

### Security Considerations

| Item | Status |
|------|--------|
| No customer data in rules | Rules contain only Salesforce capability facts |
| No PII processing | Questions are text-only, no PII extraction |
| SOQL injection | Not applicable — no dynamic SOQL |
| Apex sharing model | Runs in system context (invocable) |
| Field-level security | Respects FLS on GPS_ResponseNew__c fields |

### Dependencies

| Dependency | Version | Status |
|------------|---------|--------|
| Salesforce Platform | v65.0 (Spring '26) | Deployed |
| Data Cloud | Active | 2 retrievers (HECVAT, Whitepapers) |
| CMDT (5 objects) | 194 records | Active (1 held: Marketing Cloud US) |
| Agentforce | Active | Utopia_RFP_Agent planner bundle |
| ConnectApi.EinsteinLLM | Active | Prompt template: DataCloud_RFP_Answer |

### Deployment

```bash
# Deploy classes
sf project deploy start --source-dir force-app/main/default/classes -o <org-alias>

# Run tests
sf apex run test --class-names AIRFX_ResponseFlagInvocableTest --wait 10

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
| False Red (engine says Red, should be Green) | Low | High | 84 rules carefully tuned; adversarial testing passed |
| False Green (engine says Green, should be Red) | Medium | High | Conservative NO_MATCH defaults to Yellow; pre-filter catches most functional |
| Governor limit exceeded | Low | Medium | Capacity tested at 471 questions; batching available |
| Rule conflict (wrong rule fires first) | Low | Medium | First-match-wins with careful ordering; product filters isolate rules |
| Stale CMDT data | Low | Low | CMDT records versioned with source URLs |

## Recommendations Before GA

1. **Add flag override** — let SEs override engine flags with justification, logged in Response_Flag_Reason__c
2. **Improve numeric parser** — handle "zero RPO", "no data loss", "within N minutes"
3. **Add more CAN_DIFFERENTLY rules** — target remaining NO_MATCH_SECURITY topics
4. **Country CMDT build** — full country x product x capability matrix
5. **Batch answer progress** — show real-time progress to agent for large projects
6. **Audit trail** — log engine version, rule count, and timestamp with each triage run

## Approval

| Role | Name | Date | Approved |
|------|------|------|----------|
| Owner / Principal SE | Robert Smith | 2026-03-08 | Pending |
| SE Manager | — | — | Pending |
| Security Review | — | — | Pending |
