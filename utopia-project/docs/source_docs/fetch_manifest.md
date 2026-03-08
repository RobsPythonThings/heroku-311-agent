# Source Document Fetch Manifest

**Date:** 2026-03-08
**Purpose:** ADL ingestion staging — clean text content from public Salesforce compliance/security pages

---

## Successfully Fetched

| URL | Status | Words | Saved As | Notes |
|-----|--------|-------|----------|-------|
| https://trust.salesforce.com | 200 | 247 | `trust_salesforce_main.txt` | Main trust page with status, advisories |
| https://compliance.salesforce.com | 200 | 214 | `compliance_salesforce_main.txt` | Master certification list, 26+ standards |
| https://compliance.salesforce.com/en/services/salesforce-services-hyperforce | 200 | 278 | `compliance_hyperforce.txt` | Hyperforce certifications, all regions listed |
| https://compliance.salesforce.com/en/services/salesforce-services-first-party | 200 | 210 | `compliance_first_party.txt` | First-party infra, 134+ compliance docs |
| https://compliance.salesforce.com/en/services/mulesoft | 200 | 268 | `compliance_mulesoft.txt` | MuleSoft certs including FedRAMP, IRAP, ISMAP |
| https://compliance.salesforce.com/en/services/slack | 200 | 336 | `compliance_slack.txt` | Combined with slack.com/trust/compliance data |
| https://compliance.salesforce.com/en/services/tableau-cloud | 200 | 186 | `compliance_tableau_cloud.txt` | Tableau Cloud certs, multi-region PCI |
| https://compliance.salesforce.com/en/services/data-cloud | 200 | 185 | `compliance_data_cloud.txt` | Data Cloud certs, FedRAMP, IRAP |
| https://slack.com/trust | 200 | 197 | `slack_trust_main.txt` | Trust center overview, 6 pillars |
| https://slack.com/trust/compliance | 200 | 336 | `compliance_slack.txt` | Full cert list merged into Slack file |
| https://www.salesforce.com/company/privacy/ | 200 | 272 | `salesforce_privacy.txt` | Privacy policy, GDPR bases, data transfers |

## Pre-Existing Files (fetched 2026-03-07)

| File | Words | Notes |
|------|-------|-------|
| `gdpr.txt` | 423 | GDPR-specific content, previously fetched |
| `slack_trust.txt` | 199 | Earlier Slack trust fetch |
| `trust_compliance_full.txt` | 407 | Earlier full compliance fetch |

## Failed / Redirected — Require Alternate Approach

| URL | Status | Resolution | Notes |
|-----|--------|------------|-------|
| https://trust.salesforce.com/en/compliance/ | 307 redirect | Redirects to compliance.salesforce.com (fetched above) | Old URL structure deprecated |
| https://trust.salesforce.com/en/compliance/fedramp/ | 404 | Migrated to compliance.salesforce.com. No direct FedRAMP sub-page found — FedRAMP data is per-service (Hyperforce, GovCloud, etc.) | Try SPARC docs instead |
| https://trust.salesforce.com/en/compliance/irap/ | 404 | Migrated to compliance.salesforce.com. IRAP data present in per-service pages | Covered by Hyperforce + MuleSoft fetches |
| https://trust.salesforce.com/en/compliance/iso-27001/ | 404 | Migrated. ISO 27001:2022 confirmed in Hyperforce page | Covered by compliance_hyperforce.txt |
| https://trust.salesforce.com/en/compliance/soc-2/ | 404 | Migrated. SOC 2 referenced in all service pages | Covered across service files |
| https://trust.salesforce.com/en/compliance/gdpr/ | 404 | Migrated. GDPR referenced in service pages + privacy page | Covered by gdpr.txt + salesforce_privacy.txt |
| https://www.salesforce.com/products/platform/shield/ | 404 | Product page removed or restructured | Shield info not publicly available via this URL. Need help.salesforce.com docs |
| https://help.salesforce.com/s/articleView?id=sf.security_pe_overview.htm | JS-rendered | Help portal returns only framework JS, no content | Requires browser rendering. Manual fetch needed |
| https://www.mulesoft.com/security | 403 Forbidden | Bot protection / WAF blocks automated fetch | Manual browser download required |
| https://trust.mulesoft.com | Connection reset | Socket closed unexpectedly | Likely redirects to trust.salesforce.com |
| https://www.tableau.com/security | 301 redirect | Redirects to compliance.salesforce.com/en/services/tableau — which 404s | Tableau compliance covered by compliance_tableau_cloud.txt |
| https://trust.tableau.com | 301 redirect | Redirects to trust.salesforce.com (main trust page) | No separate Tableau trust site anymore |
| https://compliance.salesforce.com/en/services/agentforce | 404 | No dedicated page yet | Agentforce FedRAMP noted in Certification__mdt |
| https://www.salesforce.com/company/legal/508_702/ | 404 | Accessibility page URL changed | Need updated URL |
| https://www.salesforce.com/company/legal/508_702.jsp | 404 | Old JSP path also gone | Need updated URL |

## Summary

| Metric | Count |
|--------|-------|
| URLs attempted | 16 (original) + 7 (alternates) |
| Successfully fetched | 11 |
| Pre-existing files | 3 |
| Failed (404/403/redirect-only) | 9 |
| **Total clean text files** | **13** |
| **Total word count** | **3,422** |

## What Requires Manual Browser Download

1. **Shield Platform Encryption docs** — help.salesforce.com is JS-rendered, can't scrape
2. **MuleSoft security page** — mulesoft.com blocks automated fetches (403)
3. **Accessibility/508 page** — URL has changed, need to find current path
4. **SPARC documents** — Behind compliance.salesforce.com auth portal (NDA required)
5. **Penetration test summaries** — Behind auth portal

## Recommendation for ADL Ingestion

The 13 fetched files provide a solid certification/compliance index but are **summary-level content**, not deep technical documentation. For substantive RAG grounding, the SPARC documents (behind auth) and HECVAT assessments (already in Data Cloud) are far more valuable. These public pages are best used for:
- Validating certification scope and currency
- Cross-referencing Certification__mdt records
- Confirming product-level compliance coverage
