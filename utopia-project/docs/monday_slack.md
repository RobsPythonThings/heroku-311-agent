# AIRFX Monday Update

**AIRFX Engine — Weekend Build + Morning Fixes Complete**

---

**P-0042 Benchmark (348 questions)**

| | Baseline (Fri) | Current | Change |
|--|----------|-----|--------|
| GREEN | 207 | 294 | +87 (+42%) |
| YELLOW | 141 | 54 | -87 (-62%) |
| RED | 0 | 0 | Zero false reds |

87 fewer questions requiring human review per project.

---

**Engine Stats**

- 94+ deterministic rules (was ~74 Friday)
- 208 unit tests passing (100%)
- 20/20 adversarial gauntlet (trick questions designed to break the engine)
- 0% true regressions against Mike's 79 ground-truth validations
- Mike validation: 159/237 feedback issues already resolved (67%)
- 3,534 human-verified safe-to-ingest KB rows (Mike + CMDT cross-referenced)

**Key Capabilities**
- Obligation parsing: "should"/"may" language auto-softens flags
- Product-aware: MuleSoft and Tableau on-prem questions Green for those products
- Country-aware: 18 Hyperforce regions + 17-country regulatory framework via CMDT
- CMDT grounding: Regulatory frameworks, certifications, and feature availability injected into every AI answer
- Spring '26 grounded: TLS 1.3, Cloudflare WAF, Hyperforce disk encryption, all 18 regions

**Rules Added This Weekend**
- CIA triad, maintenance windows, response/recovery, vulnerability assessment, audit info, change tracking, audit alerts, security settings, admin console, FedRAMP High, ISMAP, CDN data transit, dedicated support, breach notification timeline, CUI controlled
- Broadened: RBAC, BYOK, data residency, customer VM, defer upgrades, customer approval, SOURCE_CODE excludes
- Converted to Green: security posture describe, CIA triad, vulnerability assessment

---

**Validated At Scale**

- P-0042: 348 questions (primary benchmark)
- P-0014: 66 questions
- P-4331: 471 questions
- P-4550: 15 Yellow spot-checked — 0 wrong answers, 2 stale flags auto-correcting
- CSV validation: 6,539 historical questions (262 batches, 0 failures)
- Mike Rosa validation: 316 reviewed rows benchmarked against current engine

---

**Ready to Demo**

1. Agent triages a project in ~6 seconds (348 questions)
2. Every question gets: flag + reason + classification + country-specific CMDT context + confidence score
3. AI answers grounded by verified capability data — not just RAG
4. "Can we defer the Spring release?" → Red. "Do you support TLS 1.2?" → Green. "Do you have a WAF?" → Yellow with Cloudflare context. "CUI data handling?" → Yellow with GovCloud Plus path.

---

**What's Left**

- Flag override mechanism for SEs (allow manual Green/Red override)
- 5 manual source docs still need fetch (FedRAMP, Shield, IRAP, MuleSoft, Tableau)
- 12 Mike "should be Yellow" Greens — conservative judgment calls, discuss with SE team
- Norway (P-3333, P-3334) — confirm if EU hosting (Sweden/Germany) suffices vs Norway-specific
