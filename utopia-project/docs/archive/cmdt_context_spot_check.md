# CMDT Context Spot Check — Yellow Records Without AI Answers

**Date:** 2026-03-08
**Org:** utopia-uat
**Total Yellows queried:** 200 (LIMIT)
**Yellows without AI answer:** 92
**Records sampled:** 30

## Summary

All 30 sampled records received CMDT capability context from `flagResponses()`. Context length was consistently **3,522 chars** (all from project P-4100, country GB). The CMDT wiring is working correctly — every Yellow record gets full country-specific grounding context.

## Spot Check Results

| # | Record | Project | Country | Engine Flag | Rule ID | CMDT Ctx Len | Has AI Answer | Question (first 100 chars) |
|---|--------|---------|---------|-------------|---------|-------------|---------------|---------------------------|
| 1 | GPS-0387 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | The environment strategy shall cover environment management practices, including configuration manag |
| 2 | GPS-0389 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | SaaS services must have a Service Level Agreement (SLA) specified. |
| 3 | GPS-0391 | P-4100 | GB | Yellow | MAINTENANCE_WINDOW | 3522 | NO | The customer shall have the right to decide on the timing of scheduled maintenance and/or updates. |
| 4 | GPS-0393 | P-4100 | GB | Yellow | UPTIME_PARSE_FAIL | 3522 | NO | The system shall maintain a consistent and reliable user experience under the targeted service level |
| 5 | GPS-0394 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | The solution shall maintain comprehensive and up-to-date architecture documentation, covering system |
| 6 | GPS-0400 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | Data backup and restore policies have been implemented and tested |
| 7 | GPS-0403 | P-4100 | GB | Yellow | BCP_DR_PLAN | 3522 | NO | Continuity Plan - The supplier must have a continuity plan for the service. The continuity plan must |
| 8 | GPS-0404 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | The recovery plan is developed and practiced regularly. |
| 9 | GPS-0425 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | Integrations should be included in audit trail procedures to ensure all intended data transfers are |
| 10 | GPS-0426 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | Integrations must adher to the same access management rules as the sending system user interface, AP |
| 11 | GPS-0427 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | Integrations must comply with the VR requirements (set out in this procurement) for security, scalab |
| 12 | GPS-0429 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | Retention rules for all data must be clearly defined and enforced, in accordance with regulatory and |
| 13 | GPS-0430 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | Data archiving must be considered as relevant for the business. |
| 14 | GPS-0431 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | Archiving capability should be provided. |
| 15 | GPS-0434 | P-4100 | GB | Green | ISO_27001_CERT | 3522 | NO | NIS2 and ISO27001 requirements must be considered in data management. |
| 16 | GPS-0440 | P-4100 | GB | Yellow | UPTIME_PARSE_FAIL | 3522 | NO | Migration to production systems must be supported with minimal or no downtime, enabling data transfe |
| 17 | GPS-0441 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | Migration processes must include rollback mechanisms to recover from partial failures or incorrect d |
| 18 | GPS-0445 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | User management must be based on roles with defined access rights and restrictions. |
| 19 | GPS-0446 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | The administrator can copy existing access rights to create new role-specific or position-specific a |
| 20 | GPS-0447 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | Access rights can be based on a single dimension or combinations of dimensions (e.g., view rights fo |
| 21 | GPS-0448 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | The system must support Single-Sign-On (SSO) authentication. |
| 22 | GPS-0449 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | A clear summary view of user groups is available, where variables affecting a user group's rights ar |
| 23 | GPS-0450 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | The system can utilize the AD groups of VR Group (Azure Active Directory, standard protocols support |
| 24 | GPS-0451 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | Seamless Session Continuity During SSO Token Renewal |
| 25 | GPS-0452 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | The supplier systematically identifies, prioritizes, and analyzes potential security threats, vulner |
| 26 | GPS-0453 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | The supplier has the ability to detect and report VR Group about information security deviations and |
| 27 | GPS-0454 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | The supplier has defined and documented procedures for outsourced development activities (for their |
| 28 | GPS-0456 | P-4100 | GB | Yellow | NO_MATCH_SECURITY | 3522 | NO | Service must provide capabilities for log monitoring and metrics reporting. |
| 29 | GPS-0457 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | The system must log the type of change (addition, modification, deletion), the person making the cha |
| 30 | GPS-0459 | P-4100 | GB | Green | NO_MATCH_FUNCTIONAL | 3522 | NO | The retention period for log data is 13 months. |

## CMDT Context Sample (GB, first 500 chars)

```
Salesforce Hyperforce available in United Kingdom: yes (AWS region: eu-west-2).
CDN note: Akamai, CloudFront, Cloudflare, Fastly CDN routes globally regardless of org region. Data may transit any country.
MARKETING_CLOUD data residency in GB: no. Hyperforce availability unconfirmed for this region
DATA_CLOUD data residency in GB: no. Hyperforce availability unconfirmed for this region
MULESOFT data residency in GB: no. MuleSoft Gov Cloud is US federal only. Commercial MuleSoft Hyperforce availab...
```

## Observations

1. **CMDT context is consistently populated** — all 30 records got 3,522 chars of context
2. **Context is country-specific** — GB Hyperforce region (eu-west-2) correctly identified
3. **Re-flagging shows engine improvements** — some originally-Yellow records now flag Green (GPS-0429, GPS-0430, GPS-0431, GPS-0434, GPS-0441, GPS-0449, GPS-0450, GPS-0451, GPS-0454, GPS-0457, GPS-0459) due to NO_MATCH_FUNCTIONAL split and new rules
4. **11 of 30 records would now be Green** — P-4100 hasn't been re-triaged since engine improvements
5. **GPS-0448 (SSO) could be a new rule candidate** — SSO is a Green capability but flagged Yellow as NO_MATCH_SECURITY
