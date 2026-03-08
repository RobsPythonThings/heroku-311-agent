# AIRFX Project Health Report

**Date:** 2026-03-08
**Org:** utopia-uat
**Projects queried:** 50

## Active Projects (With Triaged Responses)

| Project | Country | Product Type | Total | Green | Yellow | Red | Unflagged | Green % |
|---------|---------|-------------|------:|------:|-------:|----:|----------:|--------:|
| P-0004 | US | Hyperforce | 90 | 41 | 48 | 1 | 0 | 46% |
| P-0010 | NL | Core - Sales/Service, MC Personalization | 3 | 2 | 1 | 0 | 0 | 67% |
| P-0014 | FI | Tableau - Cloud | 66 | 14 | 52 | 0 | 0 | 21% |
| P-0016 | US | Education Cloud, Mulesoft, Tableau Cloud | 24 | 0 | 0 | 0 | 24 | — |
| P-0034 | US | Core - Service Cloud, Mulesoft, PSS | 28 | 0 | 0 | 0 | 28 | — |
| P-0041 | IT | Core - Experience/Service Cloud | 23 | 0 | 0 | 0 | 23 | — |
| P-0042 | US | Core - Experience, Mulesoft, PSS, Tableau Cloud | 348 | 300 | 48 | 0 | 0 | **86%** |
| P-0045 | US | Core - Platform | 46 | 22 | 21 | 3 | 0 | 48% |

## Projects Without Responses (42 of 50)

These projects exist in the org but have no GPS_ResponseNew__c records loaded yet.

| Project | Country | Product Type |
|---------|---------|-------------|
| P-0005 | US | Core - Experience, Education Cloud, Marketing Cloud |
| P-0006 | CA | Mulesoft |
| P-0007 | US | Analytics, Collaboration, Core, MC, Mulesoft, Pardot, Tableau |
| P-0008 | CA | B2B Commerce, MC CDP |
| P-0009 | AU | Core Sales/Service, MC CDP/Engagement/Intelligence/Personalization, Mulesoft |
| P-0011 | AU | Core Experience/Health Cloud, Mulesoft |
| P-0012 | US | Core Service Cloud, Mulesoft |
| P-0013 | US | Collaboration, Core Experience, PSS |
| P-0015 | US | Analytics, Core Service Cloud |
| P-0017 | US | Analytics, Core Experience/Sales/Service, Education, MC, Mulesoft |
| P-0018 | AU | Public Sector Solutions |
| P-0019 | US | Core Experience/Service, Mulesoft, PSS |
| P-0020 | GB | Mulesoft |
| P-0021 | US | Public Sector Solutions |
| P-0022 | GB | Core Sales Cloud |
| P-0023 | US | Core Experience/Platform, PSS |
| P-0024 | US | Core Health, MC Engagement/Personalization, Mulesoft |
| P-0025 | ID | Core Service Cloud |
| P-0026 | CA | MC CDP |
| P-0027 | US | Public Sector Solutions |
| P-0028 | US | Core Service Cloud, Mulesoft |
| P-0029 | US | Tableau - Server (On Prem) |
| P-0030 | NZ | B2B Commerce |
| P-0031 | US | Core Service Cloud, Mulesoft, PSS |
| P-0032 | IE | Core Platform |
| P-0033 | AU | Core Experience/Platform, MC Engagement, Tableau Cloud |
| P-0035 | IT | (no product set) |
| P-0036 | US | Core Service, Mulesoft, Tableau Cloud |
| P-0037 | CA | Public Sector Solutions |
| P-0038 | US | Analytics, Collaboration, Core Service, Mulesoft |
| P-0039 | US | Collaboration, Core Experience/Platform, Mulesoft, PSS, Tableau Server |
| P-0040 | US | Core Experience, Education Cloud, Pardot |
| P-0043 | US | Core Sales Cloud |
| P-0044 | US | Collaboration, Mulesoft, PSS |
| P-0046 | US | Core Platform, Mulesoft |
| P-0047 | US | Core Experience/Service, Mulesoft, PSS |
| P-0048 | AT | Tableau - Server (On Prem) |
| P-0049 | AU | Mulesoft |
| P-0050 | US | (no product set) |
| P-0051 | US | Mulesoft |
| P-0052 | US | Analytics, Core Experience, Education, MC, Mulesoft |
| P-0053 | AU | Core Service, Mulesoft, PSS |

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total projects | 50 |
| Projects with responses | 8 |
| Total responses triaged | 628 |
| Total Green | 379 (60%) |
| Total Yellow | 170 (27%) |
| Total Red | 4 (0.6%) |
| Unflagged | 75 (12%) |

## Key Observations

1. **P-0042 is the benchmark project** — 348 questions, 86% Green rate, 0 Red. This is the most fully triaged project.
2. **P-0014 (Finland, Tableau Cloud) has high Yellow rate** — 52/66 Yellow (79%). Likely because Tableau Cloud questions hit many security NO_MATCH rules. Candidate for re-triage after engine improvements.
3. **P-0004 (US, Hyperforce) has 1 Red** — only project with Red flags. Worth investigating.
4. **P-0045 (US, Core Platform) has 3 Reds** — second project with Red flags. 48% Green rate.
5. **3 projects have unflagged responses** (P-0016, P-0034, P-0041) — 75 records with no Security_Flag__c. These need triage.
6. **42 projects have no responses loaded** — these are project shells waiting for RFP questions to be imported.
7. **Country distribution**: US (30), AU (5), CA (4), GB (3), IT (2), NL/FI/ID/IE/NZ/AT (1 each)
8. **Product diversity**: Multi-cloud deals common; Mulesoft appears in 20+ projects
