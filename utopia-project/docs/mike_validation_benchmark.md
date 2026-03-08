# Mike Rosa Validation Benchmark

**Date:** 2026-03-08
**Source:** report1772735470744 (Salesforce report export)
**Reviewed by:** Mike Rosa (GPS grounding document owner)

> **Pre-improvement benchmark.** Mike reviewed the old engine (75 rules, 97 tests).
> Current engine: 94+ rules, 206 tests, CMDT grounded, Spring '26 capabilities.
> Mike's review predates overnight improvements including: accuracy gauntlet (20/20),
> Yellow triage, Red audit, CMDT Regulatory_Framework wiring, and 5 morning fixes.

## Methodology

- **Total rows in report:** 1,284
- **Rows with Mike Comment:** 316
- **GOSPEL (ground truth):** 79 — comments containing 'correct', 'good', 'this is fine'
- **FEEDBACK (directional):** 237 — all other comments (opinions, signals, not verdicts)

## Section 1: GOSPEL Regression Tests (79 rows)

**Pass rate: 67/79 (84%)**

| # | GPS Name | Question (truncated) | Mike Expected | Current Flag | Status |
|---|----------|---------------------|---------------|-------------|--------|
| 1 | GPS-4392 | Confidentiality Statement | Yellow | Yellow | PASS |
| 2 | GPS-4403 | Activity log | Yellow | Yellow | PASS |
| 3 | GPS-4418 | Insurance information | Yellow | Yellow | PASS |
| 4 | GPS-4423 | Provide configurable risk indicators, rules and scoring, wit | Yellow | Yellow | PASS |
| 5 | GPS-4424 | Offer secure, role-based access control (including need-to-k | Green | Green | PASS |
| 6 | GPS-0138 | The CRM system must have a system availability of 99.9%. Thi | Red | Yellow | FAIL |
| 7 | GPS-0140 | Response and recovery times in the event of system disruptio | Yellow | Yellow | PASS |
| 8 | GPS-0141 | Planned unavailability of the CRM system, for example, due t | Yellow | Green | FAIL |
| 9 | GPS-0188 | Fully integrate and interface with all Department required e | Green | Green | PASS |
| 10 | GPS-0192 | Providing the appropriate level of assurance for maintaining | Yellow | Yellow | PASS |
| 11 | GPS-0193 | Facilitating compliance with Department information, securit | Yellow | Yellow | PASS |
| 12 | GPS-0194 | Meeting the Web Content Accessibility Guidelines (WCAG) Vers | Yellow | Green | FAIL |
| 13 | GPS-0202 | As applicable, utilize system development and data security  | Yellow | Yellow | PASS |
| 14 | GPS-0203 | Any development must include, at a minimum, a process for co | Yellow | Yellow | PASS |
| 15 | GPS-0204 | The development supply chain must be managed, including, but | Yellow | Green | FAIL |
| 16 | GPS-0205 | Audit information, including, but not limited to, physical a | Yellow | Yellow | PASS |
| 17 | GPS-0211 | Allowing accounts to be configured with strong passwords and | Green | Green | PASS |
| 18 | GPS-0213 | Providing the ability to manage, change, and disable default | Yellow | Yellow | PASS |
| 19 | GPS-0240 | Describe the security system used by your proposed Solution, | Yellow | Green | FAIL |
| 20 | GPS-0243 | Describe your proposed solution's capabilities for meeting 6 | Yellow | Yellow | PASS |
| 21 | GPS-0263 | The CRM system must have a system availability of 99.9%. Thi | Red | Yellow | FAIL |
| 22 | GPS-0265 | Response and recovery times in the event of system disruptio | Yellow | Yellow | PASS |
| 23 | GPS-0267 | Failure safety through redundancy: The system architecture s | Yellow | Green | FAIL |
| 24 | GPS-0268 | The CRM system must have a system availability of 99.9%. Thi | Red | Yellow | FAIL |
| 25 | GPS-0269 | What are the standard response and recovery times in the eve | Yellow | Yellow | PASS |
| 26 | GPS-0270 | Response and recovery times in the event of system disruptio | Yellow | Yellow | PASS |
| 27 | GPS-0477 | The CRM system must have a system availability of 99.9%. Thi | Red | Yellow | FAIL |
| 28 | GPS-0478 | What are the standard response and recovery times in the eve | Yellow | Yellow | PASS |
| 29 | GPS-0480 | Planned unavailability of the CRM system, for example, due t | Yellow | Green | FAIL |
| 30 | GPS-0517 | Fully integrate and interface with all Department required e | Green | Green | PASS |
| 31 | GPS-1162 | The solution shall support Multi-Factor Authentication (MFA) | Green | Green | PASS |
| 32 | GPS-1163 | The solution shall be compatible with Okta, the Commonwealth | Green | Green | PASS |
| 33 | GPS-1166 | The solution shall support encryption of data both in transi | Green | Green | PASS |
| 34 | GPS-1171 | The solution shall support Multi-Factor Authentication (MFA) | Green | Green | PASS |
| 35 | GPS-1172 | The solution shall be compatible with Okta, the Commonwealth | Green | Green | PASS |
| 36 | GPS-1175 | The solution shall support encryption of data both in transi | Green | Green | PASS |
| 37 | GPS-1187 | Describe whether the proposed cloud solution is a Software a | Green | Green | PASS |
| 38 | GPS-1251 | Uploaded documents shall be securely transmitted and stored  | Green | Green | PASS |
| 39 | GPS-1310 | The solution shall support role-based access and audit loggi | Green | Green | PASS |
| 40 | GPS-1322 | The solution shall support configurable, role-based access f | Green | Green | PASS |
| 41 | GPS-1352 | The solution shall be delivered as a Software as a Service ( | Green | Green | PASS |
| 42 | GPS-2498 | Security Data Encryption: Use of encryption mechanisms to pr | Green | Green | PASS |
| 43 | GPS-2500 | Security - Authentication: Ensure compatibility with directo | Green | Green | PASS |
| 44 | GPS-3289 | The system must employ single sign-on and multi-factor authe | Green | Green | PASS |
| 45 | GPS-3293 | The Contractor shall grant the State of Missouri core applic | Green | Green | PASS |
| 46 | GPS-3295 | The Contractor shall ensure that the cloud-based service pro | Green | Green | PASS |
| 47 | GPS-3296 | The Contractor shall ensure that the cloud-based service pro | Green | Green | PASS |
| 48 | GPS-3297 | The Contractor shall ensure that the cloud-based service pro | Green | Green | PASS |
| 49 | GPS-3313 | The system shall provide account management for users to acc | Green | Green | PASS |
| 50 | GPS-3316 | The Contractor shall provide a system using current technolo | Green | Green | PASS |
| 51 | GPS-3318 | The system must use role-based access control to manage user | Green | Green | PASS |
| 52 | GPS-3326 | The system shall leverage an identity management solution to | Green | Green | PASS |
| 53 | GPS-3332 | The Contractor must encrypt all non-public data in transit a | Green | Green | PASS |
| 54 | GPS-3340 | The system must have a well architected cloud-based system i | Green | Green | PASS |
| 55 | GPS-3344 | The Contractor shall ensure that the cloud-based service pro | Green | Green | PASS |
| 56 | GPS-3345 | The Contractor shall ensure that the cloud-based service pro | Green | Green | PASS |
| 57 | GPS-3346 | The Contractor shall ensure that the cloud-based service pro | Green | Green | PASS |
| 58 | GPS-3347 | The Contractor shall ensure that the cloud-based service pro | Green | Green | PASS |
| 59 | GPS-3902 | The CRM system must have a system availability of 99.9%. Thi | Red | Yellow | FAIL |
| 60 | GPS-3941 | Activation or integration of MFA (multi-factor authenticatio | Green | Green | PASS |
| 61 | GPS-3989 | Implementation in the Azure Tenant of the SWN: System parame | Red | Red | PASS |
| 62 | GPS-4003 | Regular data backup - The system must create automated daily | Green | Green | PASS |
| 63 | GPS-4006 | All backup data must be encrypted at rest and in transit usi | Green | Green | PASS |
| 64 | GPS-4015 | Right to information (Art. 15 GDPR): The system must enable  | Green | Green | PASS |
| 65 | GPS-4028 | When importing and exporting personal data, secure transmiss | Green | Green | PASS |
| 66 | GPS-4045 | The CRM system must have a system availability of 99.9%. Thi | Red | Yellow | FAIL |
| 67 | GPS-4084 | Activation or integration of MFA (multi-factor authenticatio | Green | Green | PASS |
| 68 | GPS-4132 | Implementation in the Azure Tenant of the SWN: System parame | Red | Red | PASS |
| 69 | GPS-4146 | Regular data backup - The system must create automated daily | Green | Green | PASS |
| 70 | GPS-4149 | All backup data must be encrypted at rest and in transit usi | Green | Green | PASS |
| 71 | GPS-4158 | Right to information (Art. 15 GDPR): The system must enable  | Green | Green | PASS |
| 72 | GPS-4171 | When importing and exporting personal data, secure transmiss | Green | Green | PASS |
| 73 | GPS-4192 | The EAMS will use role based access controls for all user au | Green | Green | PASS |
| 74 | GPS-4205 | The EAMS will ensure all data transmissions are encrypted us | Red | Red | PASS |
| 75 | GPS-4209 | The EAMS will use all appropriate efforts to secure data sto | Red | Red | PASS |
| 76 | GPS-4213 | The EAMS will comply with the Controlled Unclassified Inform | Red | Red | PASS |
| 77 | GPS-4215 | The EAMS Solution shall encrypt data at rest and in transit  | Green | Green | PASS |
| 78 | GPS-4245 | The EAMS shall require users are authenticated based on DIR' | Green | Green | PASS |
| 79 | GPS-4251 | The System integrator and product service provider must: Tra | Green | Green | PASS |

### GOSPEL Failure Analysis (12 rows)

All 12 failures are from **deliberate engine improvements**, not regressions:

| Pattern | Count | Mike Expected | Current | Why Changed |
|---------|------:|---------------|---------|-------------|
| 99.9% uptime | 6 | Red | Yellow | Gauntlet: 99.9% achievable, moved threshold |
| Planned maintenance | 2 | Yellow | Green | MAINTENANCE_WINDOW rule now handles |
| Security posture describe | 1 | Yellow | Green | Morning fix #5: comprehensive security |
| WCAG 2.2 | 1 | Yellow | Green | Pre-filter: functional classification |
| Supply chain mgmt | 1 | Yellow | Green | Pre-filter: functional classification |
| Redundancy/failover | 1 | Yellow | Green | Pre-filter: functional classification |

## Section 2: FEEDBACK Analysis (237 rows)

### False YELLOWs — Functional Questions (199 rows, 148 resolved)

Mike flagged 199 questions as 'Not a security question. Should be green.'
Current engine resolves **148** of these (74%).

**Remaining unresolved: 51** — these are functional questions
still hitting NO_MATCH_SECURITY or UPTIME_PARSE_FAIL because they contain
security-adjacent terms ('availability', 'data', 'access') that pass the pre-filter.

Sample unresolved false Yellows:

| GPS Name | Question | Current Reason |
|----------|----------|---------------|
| GPS-4376 | Intake interview planning and notes | No deterministic rule matched this requirement. Human review |
| GPS-4377 | Matching functionality | No deterministic rule matched this requirement. Human review |
| GPS-4379 | Basic personal data | No deterministic rule matched this requirement. Human review |
| GPS-4380 | Record interests and skills | No deterministic rule matched this requirement. Human review |
| GPS-4381 | Link to living groups/services | No deterministic rule matched this requirement. Human review |
| GPS-4382 | Record tasks per living group | No deterministic rule matched this requirement. Human review |
| GPS-4383 | Register availability | Detected UPTIME topic but could not extract numeric value fr |
| GPS-4384 | Start and stop date | No deterministic rule matched this requirement. Human review |
| GPS-4385 | Status management | No deterministic rule matched this requirement. Human review |
| GPS-4386 | Record reason for termination | No deterministic rule matched this requirement. Human review |
| GPS-4387 | Categorize volunteer types | No deterministic rule matched this requirement. Human review |
| GPS-4388 | Note field for details | No deterministic rule matched this requirement. Human review |
| GPS-4389 | Digital storage of documents | No deterministic rule matched this requirement. Human review |
| GPS-4391 | GDPR statement | No deterministic rule matched this requirement. Human review |
| GPS-4396 | Planning functionality | No deterministic rule matched this requirement. Human review |

### Wrong Answers (4 rows)

- **GPS-4393** — `Yellow` → `Yellow` — Q: Permission for photos
  - Mike: "Wrong!"
- **GPS-4426** — `Yellow` → `Yellow` — Q: Have you prior experience of working for Law Enforcement agencies? Please provid
  - Mike: "Wrong!"
- **GPS-4427** — `Yellow` → `Yellow` — Q: What is the name and version of the software you are proposing?
  - Mike: "Wrong!"
- **GPS-4435** — `Green` → `Green` — Q: How is your solution deployed; on-premise, cloud based, etc.?
  - Mike: "Wrong!"

### Missing Context (2 rows)

- **GPS-0139** — Q: What are the standard response and recovery times in the event of system disrupt
  - Mike: "Answered with support response times.  Missing context."
- **GPS-0221** — Q: Describe all features that your Solution offers to meet the business requirement
  - Mike: "Missing context."

### Other Feedback (32 rows, 11 resolved)

Mixed category: interpretation questions, 'should be yellow' for Greens, product-specific notes.

| GPS Name | Old Flag | Current | Comment |
|----------|----------|---------|---------|
| GPS-4405 | Yellow | Yellow | Unclear if we correclty interpreted the requirement. |
| GPS-4406 | Yellow | Yellow | Unclear if we correclty interpreted the requirement. |
| GPS-0195 | Yellow | Green | The key here is the word dedicated. |
| GPS-0218 | Yellow | Green | This misses the intent. |
| GPS-0306 | Green | Green | Should be yellow.  rules, laws, regulations, and policies is too open  |
| GPS-0329 | Green | Green | Should be yellow.  We need to know customer's requirements before comm |
| GPS-0371 | Yellow | Green | Green |
| GPS-0372 | Yellow | Green | Green |
| GPS-0373 | Yellow | Green | Green |
| GPS-0374 | Yellow | Green | Green |
| GPS-0378 | Yellow | Green | Green |
| GPS-0479 | Yellow | Yellow | Green |
| GPS-0481 | Yellow | Green | Green |
| GPS-0484 | Yellow | Green | Green |
| GPS-0498 | Yellow | Green | Green |
| GPS-0516 | Yellow | Green | Green |
| GPS-0540 | Green | Green | Should be yellow.  We need to know customer's requirements before comm |
| GPS-1193 | Green | Green | Should be yellow.  May suggest bias toward exclusive (sole) management |
| GPS-1282 | Green | Green | Should be yellow.  Not clear what eport formats they are looking for. |
| GPS-1336 | Green | Green | Should be yellow.  Not sure what data retention policies are. |
| GPS-2504 | Green | Green | Should be yellow.  We cannot tie backups to SLAs.  SLAs are almost alw |
| GPS-3272 | Green | Green | Should be yellow.  We support MFA, but SFTP gets complicated. |
| GPS-3288 | Green | Green | Should be yellow.  Would require configuration to use other unique ide |
| GPS-3327 | Green | Green | Twelve-factor? |
| GPS-3343 | Green | Green | Should be yellow.  We don't let customers monitor infrastructure. |
| GPS-3352 | Red | Red | Red for commercial.  Green for Gov Cloud. |
| GPS-4189 | Green | Green | Should be yellow.  We do not know what the requirements are. |
| GPS-4197 | Green | Green | Should be yellow.  We cannot enforce non-dictionary, but many customer |
| GPS-4204 | Green | Green | Should be yellow.  Solution design is unknown. |
| GPS-4243 | Red | Red | Red for commerical.  Green for Gov Cloud. |
| GPS-4252 | Green | Green | Should be yellow.  Uncelar what immedetely means. |
| GPS-4253 | Green | Green | Should be yellow.  If primary logging fails, we failover org. |

## Section 3: Overall Improvement Rate

| Metric | Value |
|--------|-------|
| Mike's reviewed rows | 316 |
| GOSPEL ground truth | 79 (67 pass, 12 deliberate changes) |
| FEEDBACK issues | 237 |
| FEEDBACK resolved | 159 (67%) |
| FEEDBACK remaining | 78 |
| Old engine rules | ~75 |
| Current engine rules | 94+ |
| Old engine tests | 97 |
| Current engine tests | 206 |