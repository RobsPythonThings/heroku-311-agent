# CMDT Wiring Verification

**Date:** 2026-03-08
**Org:** utopia-uat
**Purpose:** Verify that `CMDTCapabilityContext` flows correctly from `flagResponses()` into `FlagResult`

## Test Record

| Field | Value |
|-------|-------|
| Record ID | a217x000001JX4YAAW |
| Record Name | GPS-0031 |
| Project | P-4000 |
| Country | CA (Canada) |
| Product Type | Core - Service Cloud;Agentforce |
| Question | What are the standard response and recovery times in the event of system disruptions? |
| Stored Flag | Yellow |
| Stored Reason | No deterministic rule matched this requirement. Human review required. |

## FlagResult Output

| Field | Value |
|-------|-------|
| `flag` | Yellow |
| `ruleId` | RESPONSE_RECOVERY_TIME |
| `reason` | Salesforce DR targets: RPO 4 hours, RTO 12 hours (SPARC). Premier Support provides P1 response within 15 minutes 24/7. Standard Support provides P1 response within 2 hours during business hours. Customer-specific SLAs on recovery times are not available. |
| `CMDTCapabilityContext` | **Not null** |
| Context length | **3,517 chars** |

## Verification Result: PASS

The `CMDTCapabilityContext` field is correctly:
1. **Populated** — not null, 3,517 characters of structured context
2. **Country-specific** — correctly identifies Canada (CA) with Hyperforce region `ca-central-1`
3. **Product-aware** — includes product-specific data residency info for all clouds
4. **Returned in FlagResult** — accessible to downstream consumers (prompt template, agent)

## Notable: Engine Improvement Detected

The stored flag reason says "No deterministic rule matched" (from a previous triage run), but the current engine now matches rule `RESPONSE_RECOVERY_TIME` with a specific, detailed reason about RPO/RTO targets. This confirms the Yellow mining improvements are working — this project would benefit from re-triage.

## Full CMDT Context (CA, Core - Service Cloud;Agentforce)

```
Salesforce Hyperforce available in Canada: yes (AWS region: ca-central-1).
CDN note: Akamai, CloudFront, Cloudflare, Fastly CDN routes globally regardless of org region. Data may transit any country.
MARKETING_CLOUD data residency in CA: no. Hyperforce availability unconfirmed for this region
DATA_CLOUD data residency in CA: no. Hyperforce availability unconfirmed for this region
MULESOFT data residency in CA: no. MuleSoft Gov Cloud is US federal only. Commercial MuleSoft Hyperforce availability varies.
TABLEAU data residency in CA: no. Tableau Next FedRAMP High Jun 2025. Hyperforce region availability unconfirmed.
SLACK data residency in CA: no. Slack/GovSlack availability outside US unconfirmed
GOVCLOUD data residency in CA: no. GovCloud is US-only. Not available outside United States.
AGENTFORCE data residency in CA: no. Agentforce availability outside US unconfirmed
Certifications applicable: Agentforce: FedRAMP High (High); Core Platform: ISMAP; Data Cloud: FedRAMP High (High); Gov Cloud: FedRAMP Moderate (Moderate); Gov Cloud Plus: FedRAMP High (High); GovSlack: FedRAMP High (High); Marketing Cloud: FedRAMP High (High); MuleSoft Gov Cloud: FedRAMP Moderate (Moderate); MuleSoft on Hyperforce: ISMAP; Salesforce Core: ISO 27001:2022; Service Cloud Voice: FedRAMP High (High); Tableau Cloud on Hyperforce: ISMAP; Tableau Next: FedRAMP High (High).
BYOK (Bring Your Own Key): paid add-on (Shield Platform Encryption). Requires Shield. Supports AWS KMS.
EU Operating Zone: paid add-on (Hyperforce EU Operating Zone). Paid upgrade. EU-based support + data isolation to EU boundary.
Government Cloud Plus: paid add-on (Separate SKU). US only. FedRAMP High. Plus Defense adds IL4/IL5.
Premier Support / Signature Success: paid add-on. Premier and Signature tiers available. Pricing negotiated per deal.
Shield Event Monitoring: paid add-on (Salesforce Shield). Event logs retained 30 days by default. Basic Core Event Monitoring IS included in base.
Shield Field Audit Trail: paid add-on (Salesforce Shield). Extends to 10 years. Up to 60 fields/object. Standard 18-24mo tracking IS included in base.
Shield Full Bundle: paid add-on (Salesforce Shield). Includes Platform Encryption, Event Monitoring, and Field Audit Trail.
Shield Platform Encryption: paid add-on (Salesforce Shield). Does not cover Einstein AI, Marketing Cloud, or Quip. Not all fields supported.
Known hard nos: Customer Approval Before Changes — Salesforce does not require customer approval before platform changes.; Customer VMs — Salesforce does not support customer-provisioned virtual machines.; Customer-Specific NDA — Salesforce uses standard contractual terms. Custom NDAs are not available.; Dedicated Hardware — Salesforce is a multi-tenant SaaS platform. Dedicated hardware is not available.; Defer Upgrades — 3 releases/year, cannot defer; Encryption In Memory — Salesforce does not encrypt data in memory.; FIPS 140-3 — FIPS 140-2 supported. 140-3 is not.; IL6 / Classified Data — Max is IL5/Top Secret unclassified; Intrusion Prevention System — Salesforce uses IDS not IPS; IPv6 — Not supported; ISO 14001 — Not held; ISO 20000 — Not held; ISO 45001 — Not held; On-Premises — Cloud-only except MuleSoft Runtime and Tableau Desktop; SecNumCloud — French ANSSI cert. Not held.; Software Bill of Materials — Salesforce does not provide an SBOM to customers.; Source Code Escrow — Salesforce does not offer source code escrow agreements..
Active__c = false records are excluded — context only reflects activated rules.
```
