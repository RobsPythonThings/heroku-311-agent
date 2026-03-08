# P-6360 Triage Audit

**Date:** 2026-03-08
**Project:** P-6360 (a1SMM0000002Gv72AE)
**Product:** B2B Commerce
**Country:** US
**Questions:** 27 (21 Green, 6 Yellow, 0 Red)

## Overall Assessment

- **Correct flags:** 24/27 = **89%**
- **Misflags found:** 3 (2 Greens should be Yellow, 1 Yellow should be Green)
- **RED accuracy:** 0 Red is correct — no hard-no questions in this set
- **AI answer quality:** Cannot assess — **all 27 records have null AI_Generated_Answer__c**
- **Confidence scores:** Confidence_Score__c field does not exist on GPS_ResponseNew__c in this org

---

## Misflags (3)

### 1. GPS-3236 — GREEN should be YELLOW (AI Data Privacy)

**Record:** [GPS-3236](https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdY1AAK/view)
**Question:** "Does your platform have any AI features or are you planning AI features in the future? And if so, would FIT prompts or responses go into a non-private knowledge base or be used in any other way for you or other clients?"
**Current flag:** Green (Functional)
**Reason:** Pre-filter matched `knowledge base` as functional term → auto-Green
**Should be:** Yellow (Security)

**Why this is wrong:** The second half of the question asks whether AI prompts and customer responses are shared with other clients or fed into a non-private knowledge base. This is an **AI data privacy question** — Einstein AI has zero-retention commitments, opt-out policies, and US-only processing constraints. An SE needs to explain the Einstein Trust Layer, data isolation, and opt-in/opt-out policies.

**Root cause:** `knowledge base` is in AIRFX_SecurityPreFilter FUNCTIONAL_TERMS (line 32). The pre-filter saw this term and short-circuited to Green before rules could evaluate the AI data privacy aspect. The functional term match overrode the actual intent of the question.

**Recommended fix:** Either:
- Add `ai` or `artificial intelligence` to SECURITY_TERMS (security terms override functional), or
- Add an exclude pattern on the `knowledge base` functional term when combined with AI/privacy context, or
- Add a new rule like `AI_DATA_PRIVACY` with patterns: `'ai.*non-private'`, `'ai.*knowledge base.*other clients'`, `'prompts.*used.*other clients'`

### 2. GPS-3230 — GREEN should be YELLOW (Accessibility Compliance)

**Record:** [GPS-3230](https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdXvAAK/view)
**Question:** "Is your software WCAG and ADA compliant? Are all of your email templates compliant?"
**Current flag:** Green (Functional)
**Reason:** No security terms detected, no rule matched → NO_MATCH_FUNCTIONAL
**Should be:** Yellow (Security) via ACCESSIBILITY_508

**Why this is wrong:** Salesforce claims "substantial conformance" to WCAG 2.1, not full compliance. The existing ACCESSIBILITY_508 rule correctly flags this as BINARY_CAN_DIFFERENTLY — but it requires `wcag 2` (with version number), and this question just says `WCAG` without the version. Also, `ADA` alone is not a trigger pattern. The identical question type on P-0042 (GPS-0217, "Section 508") was flagged Yellow.

**Root cause:** ACCESSIBILITY_508 rule patterns are too narrow: `'wcag 2'`, `'section 508'`, `'vpat'`, `'accessibility conformance'`. The bare terms `wcag` and `ada compliant` don't match.

**Recommended fix:** Add broader patterns to ACCESSIBILITY_508:
- `'\\bwcag\\b'` (WCAG without version number)
- `'\\bada\\b.*complian'` (ADA compliance/compliant)

### 3. GPS-3223 — YELLOW should be GREEN (Email Tracking)

**Record:** [GPS-3223](https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdXoAAK/view)
**Question:** "Can your emails track compliance? Continue to send emails to a user until they have clicked a link/performed a task?"
**Current flag:** Yellow (Security)
**Reason:** NO_MATCH_SECURITY — "compliance" triggered security classification
**Should be:** Green (Functional)

**Why this is wrong:** "Track compliance" here means tracking whether users completed a required action (clicked a link, did a task) — email automation compliance, not regulatory/security compliance. The second sentence clarifies the intent: it's about email drip campaigns with task completion tracking. This is pure marketing automation functionality.

**Root cause:** `compliance` is in SECURITY_TERMS, so the question passed through the pre-filter to rules. No rule matched → NO_MATCH_SECURITY → Yellow. The word "compliance" is being treated as a security signal when it's used in a non-security context.

**Recommended fix:** This is a hard one — `compliance` genuinely is a security term in most RFP contexts. Options:
- Accept this as a known false positive (conservative — human review confirms it's functional, low cost)
- Add a pre-filter exclude: if question contains `email` + `compliance` + `click` → treat as functional

**Recommendation:** Accept as-is. A false Yellow is safe (human reviewer clears it quickly). Making `compliance` context-sensitive risks missing real compliance questions.

---

## GREEN Audit (21 records)

| # | Name | Question (truncated) | Classification | Verdict |
|---|------|---------------------|:-------------:|:-------:|
| 1 | GPS-3216 | Explain how governance works | Functional | Correct |
| 2 | GPS-3217 | Can different departments have own folders/templates? | Functional | Correct |
| 3 | GPS-3218 | How many seats/logins come with basic account? | Functional | Correct |
| 4 | GPS-3219 | Is there a built-in approval workflow/process? | Functional | Correct |
| 5 | GPS-3220 | Built-in calendar for scheduling emails? | Functional | Correct |
| 6 | GPS-3221 | What metrics beyond open rates and clicks? | Functional | Correct |
| 7 | GPS-3222 | Can platform create templated, branded emails? | Functional | Correct |
| 8 | GPS-3224 | Does software interact with Ellucian Banner/CRMs? | Functional | Correct |
| 9 | GPS-3225 | How many higher education clients? | Functional | Correct |
| 10 | GPS-3226 | Do you offer intranet or communication hub? | Functional | Correct |
| 11 | GPS-3227 | Does email require intranet purchase? | Functional | Correct |
| 12 | GPS-3228 | Integrate with Google Workspace vs Microsoft 365? | Functional | Correct |
| 13 | GPS-3229 | Do you offer SMS messages? | Functional | Correct |
| 14 | GPS-3230 | WCAG and ADA compliant? | Functional | **MISFLAG** |
| 15 | GPS-3231 | Environmental structure / hosting platform? | (null) | Correct |
| 16 | GPS-3234 | What other services or add-ons? | Functional | Correct |
| 17 | GPS-3235 | Email templates exclude unsubscribe? | Functional | Correct |
| 18 | GPS-3236 | AI features — prompts go into non-private KB? | Functional | **MISFLAG** |
| 19 | GPS-3237 | Available through NYS OGS, GSA, cooperative contracts? | Functional | Correct |
| 20 | GPS-3241 | Planned unavailability outside core hours | Security | Correct |
| 21 | GPS-3242 | Failure safety through redundancy | Functional | Correct |

### Notes on specific records

- **GPS-3231** (hosting platform): Correctly went through DATA_RESIDENCY rule → Green for US. Classification is null — minor bug, should be Security.
- **GPS-3241** (maintenance windows): Correctly classified as Security, Green via MAINTENANCE_WINDOWS rule with obligation softening ("should" language). Good call.
- **GPS-3242** (redundancy): Classified as Functional — debatable since it's about infrastructure HA. But Green flag is correct regardless (Salesforce has multi-AZ redundancy). Low priority.

---

## YELLOW Audit (6 records)

| # | Name | Question (truncated) | Rule | Flag Reason | Verdict |
|---|------|---------------------|------|-------------|:-------:|
| 1 | GPS-3223 | Track email compliance / task completion | NO_MATCH_SECURITY | No rule matched | **MISFLAG** |
| 2 | GPS-3232 | Availability during disasters/cyber attacks | UPTIME_PARSE_FAIL | No numeric to extract | Correct |
| 3 | GPS-3233 | Describe cyber security policy and practices | NO_MATCH_SECURITY | No rule matched | Correct |
| 4 | GPS-3238 | System availability 99.9% | UPTIME (tiered) | 99.9% > standard 99.7% | Correct |
| 5 | GPS-3239 | Standard response/recovery times | RESPONSE_RECOVERY_TIME | RPO 4h / RTO 12h | Correct |
| 6 | GPS-3240 | Response/recovery per "System Availability" tab | UPTIME_PARSE_FAIL | External reference, no numeric | Correct |

### YELLOW answer quality

**All 6 YELLOW records have null AI_Generated_Answer__c.** Answers have not been generated yet. The flag reasons themselves serve as interim guidance:

- **GPS-3238** reason is strong: "Requirement: 99.9%. Salesforce standard SLA commits to 99.7%." — SE-usable.
- **GPS-3239** reason is strong: "RPO 4 hours, RTO 12 hours (SPARC). Premier Support provides P1 response within 15 minutes 24/7." — SE-usable.
- **GPS-3232, GPS-3233, GPS-3240** reasons are generic ("Human review needed") — need AI answers generated.

**Answer quality rating: N/A (no answers generated)**

**Recommendation:** Run `Utopia: Answer All Yellow Questions` on P-6360 to generate grounded answers for the 5 legitimate Yellows.

---

## RED Audit (0 records)

**0 Red is correct.** Reviewed all 27 questions for B2B Commerce / US context:

- No questions about source code access, customer VMs, on-prem deployment
- No questions about FIPS 140-3, IL6/classified data, dedicated hardware
- No questions about encryption in memory, IPv6, or ISO certifications Salesforce doesn't hold
- No questions requiring capabilities that Salesforce cannot provide
- The "99.9% uptime" question is correctly Yellow (achievable with AE engagement), not Red

---

## Patterns

### What the engine handles well
- **Functional screening**: 17/21 Greens are clean functional questions with no security content. The pre-filter correctly routes them.
- **Uptime/availability rules**: 99.9% SLA, DR response/recovery — well-calibrated, accurate reasons.
- **Obligation softening**: GPS-3241 ("should" language) correctly Green instead of Yellow.
- **Data residency**: GPS-3231 correctly resolved US as supported Hyperforce region.

### What the engine handles poorly
- **Multi-intent questions**: GPS-3236 has a functional first half ("do you have AI?") and a security second half ("is my data shared?"). Pre-filter sees functional term and stops.
- **Bare compliance terms**: `compliance` as a standalone word is too broad — catches email tracking alongside real compliance questions.
- **Narrow accessibility patterns**: ACCESSIBILITY_508 requires `wcag 2` (with version) but real-world questions often say just `WCAG` or `ADA compliant`.

### This RFP's profile
This is a **higher-ed email/CRM RFP** — mostly functional questions about email features, integrations, and licensing. Only 6/27 (22%) are security-related. The engine's functional pre-filter is doing most of the work correctly. The 3 misflags are all edge cases at the boundary between functional and security classification.

---

## Action Items

| Priority | Item | Impact |
|----------|------|--------|
| **High** | GPS-3236: Review AI data privacy answer manually | SE risk — customer is asking about data sharing |
| **Medium** | Broaden ACCESSIBILITY_508 rule to match bare `wcag` and `ada compliant` | Consistency with P-0042 GPS-0217 |
| **Medium** | Add AI data privacy rule or add `artificial intelligence` to SECURITY_TERMS | Prevents future false Greens on AI privacy questions |
| **Low** | GPS-3223: Accept false Yellow (safe direction) | Human reviewer clears quickly |
| **Low** | Generate AI answers for 5 legitimate Yellow questions | Answers not yet generated |
| **Low** | GPS-3231: Fix null classification (should be Security) | Cosmetic |

---

## Confidence Score Audit

**Not applicable.** The field `Confidence_Score__c` does not exist on `GPS_ResponseNew__c` in the utopia-uat org. The confidence scoring feature referenced in AIRFX_ResponseFlagInvocable.cls computes a score in memory but has no field to persist it. To enable this audit in future, create `Confidence_Score__c` (Number) on GPS_ResponseNew__c and deploy.
