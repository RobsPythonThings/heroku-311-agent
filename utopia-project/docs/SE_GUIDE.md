# AIRFX SE Guide

**Audience:** Solution Engineers using the Utopia RFP Agent
**Last updated:** 2026-03-08

## What is AIRFX?

AIRFX (Agentforce RFP Flagging Engine) is a deterministic security-flagging engine that triages RFP/RFx questions. When the agent processes a project, AIRFX auto-flags every question as Red, Yellow, or Green and classifies it as Functional or Security.

## Flag Meanings

| Flag | Meaning | SE Action |
|------|---------|-----------|
| **Green** | Salesforce can do this, or it's a functional (non-security) question | Review AI-generated answer, submit |
| **Yellow** | Salesforce can meet the intent but not the letter, OR no rule matched for this security question | Review AI-generated answer, customize for customer context |
| **Red** | Salesforce cannot do this (hard no) | Do NOT submit the AI answer. Write a manual response explaining the gap or proposing an alternative |

## How It Works

### Pipeline

```
Question arrives
  -> Gate 1: Pre-filter (~160 functional terms, ~84 security terms)
     Functional terms only -> GREEN (auto-classified as Functional)
  -> Gate 2: 90+-rule deterministic engine (first match wins)
     Rule match -> flag per rule type
  -> Gate 3: NO_MATCH split
     No security terms -> GREEN "Functional"
     Has security terms -> YELLOW "Needs review"
```

### Rule Types

| Type | Example | Flag |
|------|---------|------|
| BINARY_CAN | "Do you support TLS 1.2?" | Green |
| BINARY_CANNOT | "Can you provide source code escrow?" | Red |
| BINARY_CAN_DIFFERENTLY | "Do you provide right to audit?" | Yellow |
| NUMERIC (uptime) | "Guarantee 99.99% uptime" | Red (exceeds 99.9% max) |
| NUMERIC (RPO/RTO) | "RPO of 1 hour" | Red (SF RPO is 4 hours) |
| DATA_RESIDENCY | "Data must reside in Australia" | Green (AU is Hyperforce) |
| DATA_RESIDENCY | "Data must reside in Norway" | Red (no Hyperforce region) |

### Obligation Parsing

The engine detects whether a requirement uses mandatory or optional language:

- **Mandatory** (must, shall, required): standard flagging
- **Optional** (should, may, preferred, recommended): flags soften by one level
  - BINARY_CANNOT Red -> Yellow ("optional language — flagged Yellow instead of Red")
  - BINARY_CAN_DIFFERENTLY Yellow -> Green ("optional language — meets the intent")

This means "The vendor should provide escrow" gets Yellow instead of Red.

### Product Dimensions

AIRFX is product-aware for MuleSoft and Tableau:

- **MuleSoft deals** — on-prem, dedicated hardware, private cloud, customer VM questions are all Green (MuleSoft Anypoint Runtime supports these)
- **Tableau deals** — on-prem, dedicated hardware, private cloud questions are all Green (Tableau Server supports these)
- **All other products** — on-prem and dedicated hardware are Red (Salesforce is SaaS-only)

The product type comes from `GPS_Project__c.Product_Type__c`.

## What SEs Need to Know

### Red Flags — Hard Nos

These are capabilities Salesforce genuinely cannot provide:

| Topic | Why Red |
|-------|---------|
| Source code escrow | Inapplicable to SaaS |
| Dedicated hardware | Multi-tenant SaaS |
| On-premises deployment | SaaS-only (except MuleSoft/Tableau) |
| Private cloud hosting | SaaS-only (except MuleSoft/Tableau) |
| Service credit SLAs | No financial penalties |
| IL6 | Not currently supported |
| SecNumCloud | Not certified |
| SBOM | Not provided |
| Customer VMs | Salesforce runs on AWS |
| ISO 14001 / ISO 45001 | Not certified |
| Guaranteed resolution times | Response times only (Premier/Signature) |

### Yellow Flags — Can Differently

These are "yes, but" answers. The AI-generated response explains the alternative:

| Topic | Alternative |
|-------|-------------|
| WAF | Cloudflare platform-managed, not customer-configurable |
| Right to audit | SOC 2 / ISO 27001 attestation reports instead |
| Virus scanning | WithSecure via AppExchange, not native |
| SIEM integration | Shield Event Monitoring add-on, not infrastructure logs |
| Section 508 / WCAG | ACRs demonstrate substantial conformance, not 100% |
| Incident response | SF has IR program; no customer-format reports |
| Background checks | SF conducts per own policy; no customer-specific vetting |
| Patch management | SF manages cadence; no customer-directed timelines |
| BCP/DR plan | SF has BCP/DR; plans not shared for customer review |

### Green Flags — Fully Supported

The engine auto-Greens questions about: encryption at rest/in transit, TLS 1.2/1.3, BYOK, MFA, SSO, RBAC, IL5, penetration testing, backup, event monitoring, data export, ISO 27001, SOC 2, and more.

## Working with CMDT Context

Every flagged question includes a CMDT capability context block injected into the prompt template. This contains:
- Hyperforce region availability for the deal country
- Product-specific region details
- Certifications held (FedRAMP, ISO, ISMAP, etc.)
- Feature availability (Shield, BYOK, GovCloud Plus, etc.)
- Hard Nos list (things Salesforce cannot do)
- CDN data transit caveats

This context grounds the AI-generated answer with country- and product-specific facts.

## Common SE Questions

**Q: A question got flagged Yellow but I know the answer is Green. What happened?**
The engine uses first-match-wins. If the question hits NO_MATCH_SECURITY, it means no rule matched but security terms were detected. The engine is conservative — it flags Yellow and lets the AI generate an answer for your review.

**Q: Why is an uptime question Yellow instead of Red?**
The engine uses a 3-tier model: <99.7% Green (within SLA), 99.7-99.9% Yellow (achievable with AE approval), >99.9% Red (cannot meet).

**Q: Can I override a flag?**
Not yet in the engine. Flag overrides are a planned feature. For now, edit the `Security_Flag__c` field directly if needed.

**Q: How do I re-triage a project?**
Ask the agent: "Triage project P-XXXX" — the agent will call `AIRFX_AgentAction.triageProject()` which re-runs the engine on all questions.

**Q: What if the deal country is wrong?**
Data residency flags depend on `GPS_Project__c.Country__c`. If the country is blank or wrong, data residency questions will get Yellow (no country to check). Update the project record and re-triage.

## Performance

- **Capacity:** ~650 questions per invocation (within 10,000ms CPU governor limit)
- **P-0042 benchmark (348 questions):** ~6.5 seconds, 288 Green / 60 Yellow / 0 Red
- **Unit tests:** 170/170 passing
- **Adversarial tests:** 20/20 correct (trick questions, negation traps, compound queries)
