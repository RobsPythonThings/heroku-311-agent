# P-6360 Hard Audit

**Date:** 2026-03-08
**Project:** P-6360 (a1SMM0000002Gv72AE)
**Product:** B2B Commerce
**Country:** US
**Questions:** 27 (21 Green, 6 Yellow, 0 Red)
**Prior audit:** `docs/p6360_triage_audit.md` — found 3 misflags (89% accuracy), answers were null
**This audit:** Full re-audit with AI-generated answers now populated on all 6 Yellows

---

## Step 1 — Record Summary

All 27 records pulled. Key changes since prior audit:
- **6 Yellow records now have AI_Generated_Answer__c** (previously all null)
- **Confidence_Score__c / Confidence_Level__c** still do not exist as fields on GPS_ResponseNew__c — score is in-memory only, not persisted
- **Fixes deployed since prior audit:** AI data privacy terms added to SECURITY_TERMS (`non-private`, `used for other clients`, `shared with other`, `ai feature`), ACCESSIBILITY_508 broadened (`\bwcag\b`, `\bada\b.*complian`)
- **Fixes NOT re-run:** Engine has not been re-triaged on P-6360, so GPS-3230 and GPS-3236 still show Green in the org despite fixes

---

## Step 2 — GREEN Audit (21 records)

| # | Name | ID | Question (truncated) | Classification | Flag Reason | Verdict | Notes |
|---|------|----|---------------------|:--------------:|-------------|:-------:|-------|
| 1 | GPS-3216 | a217x000001KdXkAAK | Explain how governance works | Functional | NO_MATCH_FUNCTIONAL | CORRECT | Pure product question |
| 2 | GPS-3217 | a217x000001KdXlAAK | Different departments own folders/templates? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | Feature question |
| 3 | GPS-3218 | a217x000001KdXmAAK | How many seats/logins with basic account? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | Licensing question |
| 4 | GPS-3219 | a217x000001KdXnAAK | Built-in approval workflow/process? | Functional | Pre-filter functional (workflow) | CORRECT | |
| 5 | GPS-3220 | a217x000001KdXoAAK | Built-in calendar for scheduling emails? | Functional | Pre-filter functional (calendar) | CORRECT | |
| 6 | GPS-3221 | a217x000001KdXpAAK | Metrics beyond open rates and clicks? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | Analytics question |
| 7 | GPS-3222 | a217x000001KdXqAAK | Create templated, branded emails? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | |
| 8 | GPS-3224 | a217x000001KdXsAAK | Interact with Ellucian Banner/CRMs? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | Integration question |
| 9 | GPS-3225 | a217x000001KdXtAAK | How many higher education clients? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | Reference question |
| 10 | GPS-3226 | a217x000001KdXuAAK | Offer intranet or communication hub? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | |
| 11 | GPS-3227 | a217x000001KdXvAAK | Email require intranet purchase? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | |
| 12 | GPS-3228 | a217x000001KdXwAAK | Google Workspace vs Microsoft 365? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | |
| 13 | GPS-3229 | a217x000001KdXxAAK | Offer SMS messages? | Functional | Pre-filter functional (sms) | CORRECT | |
| 14 | GPS-3230 | a217x000001KdXvAAK | WCAG and ADA compliant? | Functional | NO_MATCH_FUNCTIONAL | **SHOULD_BE_YELLOW** | Fix deployed but not re-run — see notes |
| 15 | GPS-3231 | a217x000001KdXwAAK | Environmental structure / hosting platform? | (null) | DATA_RESIDENCY rule → Green | CORRECT | Classification null is a minor bug |
| 16 | GPS-3234 | a217x000001KdXzAAK | Other services or add-ons? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | |
| 17 | GPS-3235 | a217x000001KdY0AAK | Email templates exclude unsubscribe? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | |
| 18 | GPS-3236 | a217x000001KdY1AAK | AI features — prompts go into non-private KB? | Functional | Pre-filter functional (knowledge base) | **SHOULD_BE_YELLOW** | Fix deployed but not re-run — see notes |
| 19 | GPS-3237 | a217x000001KdY2AAK | Available through NYS OGS, GSA, cooperative contracts? | Functional | NO_MATCH_FUNCTIONAL | CORRECT | |
| 20 | GPS-3241 | a217x000001KdY6AAK | Planned unavailability outside core hours | Security | MAINTENANCE_WINDOWS rule → Green | CORRECT | Good obligation softening |
| 21 | GPS-3242 | a217x000001KdY7AAK | Failure safety through redundancy | Functional | NO_MATCH_FUNCTIONAL | CORRECT | Green is correct regardless |

### GREEN Verdict: 19/21 correct (2 known misflags, fixes deployed but not re-executed)

**GPS-3230 (WCAG/ADA):** Would now be caught on re-triage. Pre-filter finds no functional or security terms for "wcag" → `skipAsGreen=false` → passes to rules → ACCESSIBILITY_508 regex `\bwcag\b` matches → YELLOW (BINARY_CAN_DIFFERENTLY). Fix is deployed, just needs re-triage.

**GPS-3236 (AI data privacy):** Would now be caught on re-triage. Question contains "non-private" which is now in SECURITY_TERMS → security term overrides "knowledge base" functional term → passes to rules → likely NO_MATCH_SECURITY → YELLOW. **Note:** The question text has OCR artifact `Al` (capital-A lowercase-L) instead of `AI`, so `ai feature` won't match, but `non-private` will. Fix is deployed, just needs re-triage.

**No answers on Greens:** Correct — Green records should not have AI-generated answers. None do.

---

## Step 3 — YELLOW Audit (6 records)

### GPS-3223 — Email Compliance Tracking
**ID:** a217x000001KdXoAAK
**URL:** https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdXoAAK/view
**Question:** "Can your emails track compliance? Continue to send emails to a user until they have clicked a link/performed a task?"
**Rule:** NO_MATCH_SECURITY
**Flag verdict:** **SHOULD_BE_GREEN** (unchanged from prior audit)
**Rationale:** "Track compliance" here means email drip campaign completion tracking, not regulatory compliance. False positive on the word "compliance."

**Answer quality: WEAK**
- Answer pivots to Enhanced Transaction Security and Salesforce Shield — completely wrong context
- Customer is asking about email marketing automation (drip sequences, click tracking), not security monitoring
- References "Shield subscriptions" for a B2B Commerce email question — would confuse an SE
- Final paragraph admits the docs don't cover what was asked
- **SE usability:** An SE would NOT use this answer. It answers the wrong question entirely.

---

### GPS-3232 — Disaster Recovery / Availability
**ID:** a217x000001KdXxAAK
**URL:** https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdXxAAK/view
**Question:** "How do you ensure availability during local or regional disasters or disruption of services from cyber attacks or hosting provider outages?"
**Rule:** UPTIME_PARSE_FAIL
**Flag verdict:** CORRECT

**Answer quality: STRONG**
- Covers infrastructure resilience, geographic distribution, ACRC, CSIRT, backup strategy
- Cites specific facts: AWS us-east-1, EBS volumes, 48h RTO / 4h RPO for ACRC, monthly vulnerability scanning
- Well-structured with clear sections
- Addresses all three scenarios asked about: disasters, cyber attacks, hosting outages
- Mentions trust.salesforce.com for incident notification
- Minor issue: References "Government Cloud Plus" heavily — this is a B2B Commerce deal, not GovCloud. Answer should lead with standard Hyperforce capabilities.
- **SE usability:** Yes, with minor editing to de-emphasize GovCloud references.

---

### GPS-3233 — Cybersecurity Policy
**ID:** a217x000001KdXyAAK
**URL:** https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdXyAAK/view
**Question:** "Can you describe your cyber security policy and practices?"
**Rule:** NO_MATCH_SECURITY
**Flag verdict:** CORRECT

**Answer quality: STRONG**
- Comprehensive coverage: trust-first culture, basics (patching, MFA), access controls, monitoring, compliance
- Cites specific controls: AC-5, AC-6, DISA STIGs, CIS Benchmarks
- Mentions ISO 27001:2022, FedRAMP
- Good structure with clear headings
- Minor issue: Again references GovCloud / FedRAMP High / IL4/IL5 — not relevant for B2B Commerce deal
- Minor issue: "Top Secret unclassified (IL5)" is an inaccurate characterization
- **SE usability:** Yes, with edits to remove GovCloud references and fix the IL5 description.

---

### GPS-3238 — 99.9% Uptime SLA
**ID:** a217x000001KdZJAA0
**URL:** https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdZJAA0/view
**Question:** "The CRM system must have a system availability of 99.9%."
**Rule:** UPTIME (NUMERIC_TIERED_MIN)
**Flag verdict:** CORRECT
**Flag reason:** "Requirement: 99.9%. Salesforce standard SLA commits to 99.7%. Requirements up to 99.9% may be achievable with explicit approval — please engage your AE." — Excellent, SE-actionable.

**Answer quality: BORDERLINE**
- Describes HA architecture and ACRC correctly
- **Critical gap:** Never states Salesforce's actual SLA commitment (99.7%) or the gap to the 99.9% requirement
- The flag reason is more useful than the answer — it clearly states the gap
- Avoids the hard truth: "We commit to 99.7%, you need 99.9%, here's how to bridge the gap"
- Last paragraph punts to "contractual agreement" — this is exactly the kind of dodge that frustrates SEs
- **SE usability:** SE would use the flag reason, not the answer. Answer adds architectural context but dodges the core question.

---

### GPS-3239 — Response/Recovery Times
**ID:** a217x000001KdZKAA0
**URL:** https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdZKAA0/view
**Question:** "What are the standard response and recovery times in the event of system disruptions?"
**Rule:** RESPONSE_RECOVERY_TIME
**Flag verdict:** CORRECT
**Flag reason:** "RPO 4 hours, RTO 12 hours (SPARC). Premier Support provides P1 response within 15 minutes 24/7." — Excellent, specific, SE-actionable.

**Answer quality: STRONG**
- Cites exact numbers: RTO 12 hours, RPO 4 hours for both GovCloud Plus and Hyperforce
- Covers Heroku tiered recovery
- Notes exclusions (multi-AZ disasters, sandbox)
- Mentions annual DR testing
- Minor issue: Heroku recovery details are irrelevant for B2B Commerce
- **SE usability:** Yes. Combined with the flag reason, an SE has everything needed.

---

### GPS-3240 — Response/Recovery per "System Availability" Tab
**ID:** a217x000001KdZLAA0
**URL:** https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdZLAA0/view
**Question:** "Response and recovery times per 'System Availability' tab. Can you guarantee these? Additional costs?"
**Rule:** UPTIME_PARSE_FAIL
**Flag verdict:** CORRECT

**Answer quality: BORDERLINE**
- Correctly identifies that it can't answer the specific question (references an external tab we don't have)
- Provides general DR capabilities and CSIRT info as fallback
- Admits limitations clearly in the final section
- **Critical gap:** Doesn't state the actual RTO/RPO numbers (4h/12h) that GPS-3239 got right — inconsistent
- Doesn't address the "additional costs" question at all
- **SE usability:** Partially. SE would need to combine this with GPS-3239's answer and add cost discussion manually.

---

### YELLOW Summary

| Name | Flag | Answer Quality | SE Usable? | Verdict |
|------|:----:|:--------------:|:----------:|:-------:|
| GPS-3223 | **SHOULD_BE_GREEN** | WEAK | No | Wrong flag + wrong answer |
| GPS-3232 | CORRECT | STRONG | Yes (edit GovCloud refs) | CORRECT + STRONG |
| GPS-3233 | CORRECT | STRONG | Yes (edit GovCloud refs) | CORRECT + STRONG |
| GPS-3238 | CORRECT | BORDERLINE | Flag reason > answer | CORRECT + BORDERLINE |
| GPS-3239 | CORRECT | STRONG | Yes | CORRECT + STRONG |
| GPS-3240 | CORRECT | BORDERLINE | Partially | CORRECT + BORDERLINE |

---

## Step 4 — RED Verification (0 Red)

Reviewed all 27 questions for hidden hard-nos in a B2B Commerce / US context:

- **No source code access requests** — none of the 27 questions ask to review Salesforce source code
- **No custom VM / dedicated hardware demands** — no on-prem, dedicated server, or bare-metal requests
- **No FIPS 140-2/3 requirements** — no cryptographic module questions
- **No impossible certifications** — no IL5/IL6, no ITAR, no classified data handling
- **No IPv6 requirements** — not asked
- **No data deletion/destruction guarantees** beyond standard — not asked
- **99.9% uptime** is correctly Yellow, not Red (achievable with AE engagement)
- **DR/response times** are correctly Yellow, not Red (we publish 4h/12h targets)

**Verdict: 0 Red is correct.** No questions in this set require a hard-no for B2B Commerce.

---

## Step 5 — Confidence Score Audit

**Not applicable.** `Confidence_Score__c` and `Confidence_Level__c` do not exist as fields on `GPS_ResponseNew__c`. The confidence scoring logic in `AIRFX_ResponseFlagInvocable.calculateConfidence()` computes scores in memory but has no persisted field.

**Recommendation:** To enable confidence audits, create `Confidence_Score__c` (Number 4,1) and `Confidence_Level__c` (Text) on GPS_ResponseNew__c. Until then, confidence cannot be audited from org data.

---

## Step 6 — Overall Verdict

### Flag Accuracy: 24/27 correct (89%)

| Misflag | Current | Should Be | Status |
|---------|:-------:|:---------:|--------|
| GPS-3230 (WCAG/ADA) | Green | Yellow | **Fix deployed, needs re-triage** |
| GPS-3236 (AI data privacy) | Green | Yellow | **Fix deployed, needs re-triage** |
| GPS-3223 (email tracking) | Yellow | Green | Accepted false positive (safe direction) |

All 3 misflags are unchanged from the prior audit. The code fixes are deployed but the engine hasn't been re-run on P-6360.

### Answer Quality: 3 STRONG / 2 BORDERLINE / 1 WEAK

| Rating | Records | Pattern |
|--------|---------|---------|
| STRONG | GPS-3232, GPS-3233, GPS-3239 | Specific facts, structured, cites sources |
| BORDERLINE | GPS-3238, GPS-3240 | Correct direction but dodges the hard numbers or punts to "check your contract" |
| WEAK | GPS-3223 | Answers the wrong question entirely (Shield monitoring vs email marketing) |

### Confidence Score Reliability
Cannot assess — field not persisted. See Step 5.

### Top 3 Things Working Well

1. **Functional pre-filter accuracy** — 17/19 clean functional Greens are unambiguously correct. The pre-filter handles higher-ed email/CRM questions well.
2. **Rule-matched Yellows are excellent** — GPS-3238 (uptime tiered) and GPS-3239 (RPO/RTO) have precise, SE-actionable flag reasons with specific numbers. These are better than the AI answers.
3. **RAG answer depth** — GPS-3232 and GPS-3233 produce genuinely detailed, well-sourced answers covering multiple security dimensions. The HECVAT and whitepaper retrievers are working.

### Top 3 Gaps to Fix

1. **GovCloud bleed-through in answers** — GPS-3232, GPS-3233 heavily reference Government Cloud Plus, FedRAMP High, and IL4/5 for a B2B Commerce deal. The prompt template needs product-context awareness to suppress irrelevant GovCloud content. This is the #1 answer quality issue.
2. **Answer dodging on hard numbers** — GPS-3238 knows the requirement is 99.9% and the SLA is 99.7% (flag reason says it) but the answer refuses to state the gap. GPS-3240 doesn't cite RTO/RPO at all despite GPS-3239 proving the retriever has that data. The prompt template should instruct the LLM to lead with specific numbers when available.
3. **Re-triage not triggered after code deploy** — GPS-3230 and GPS-3236 would now be correctly flagged Yellow but the engine hasn't been re-run. Need a process to re-triage projects after rule/pre-filter changes, or at minimum flag which projects were triaged on a pre-fix version.

### Records Requiring Manual Review

| Record | URL | Action |
|--------|-----|--------|
| GPS-3236 | https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdY1AAK/view | Re-triage to Yellow, review AI data privacy answer. OCR artifact: "Al" → "AI" in question text. |
| GPS-3230 | https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdXvAAK/view | Re-triage to Yellow (ACCESSIBILITY_508). Verify WCAG/ADA answer. |
| GPS-3238 | https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdZJAA0/view | Answer is borderline — consider manually editing to state the 99.7% vs 99.9% gap explicitly. |
| GPS-3223 | https://utopia-uat.lightning.force.com/lightning/r/GPS_ResponseNew__c/a217x000001KdXoAAK/view | False Yellow — SE should manually set to Green and discard the Shield-focused answer. |

---

## Action Items

| Priority | Item | Owner | Impact |
|----------|------|-------|--------|
| **P1** | Re-run triage on P-6360 to pick up deployed fixes (GPS-3230, GPS-3236) | Robert | 2 misflags → 1 misflag |
| **P1** | Fix GovCloud bleed-through — add product context to prompt template so B2B Commerce answers don't cite FedRAMP/IL5 | Robert | Answer quality for non-GovCloud deals |
| **P2** | Instruct prompt template to lead with specific numbers when flag reason contains them (uptime %, RPO/RTO) | Robert | GPS-3238 and GPS-3240 answer quality |
| **P2** | Fix OCR artifact on GPS-3236: "Al" → "AI" in Question__c | Robert | Won't match `ai feature` security term until fixed |
| **P3** | Create `Confidence_Score__c` and `Confidence_Level__c` fields on GPS_ResponseNew__c | Robert | Enables confidence auditing |
| **P3** | GPS-3223: Manually flip to Green, clear answer | Robert | Cosmetic — safe false positive |
| **P3** | GPS-3231: Set Question_Classification__c to 'Security' | Robert | Cosmetic — null classification |

---

## Comparison: Prior Audit → Hard Audit

| Metric | Prior Audit (2026-03-08 AM) | Hard Audit (2026-03-08 PM) |
|--------|:---------------------------:|:--------------------------:|
| Flag accuracy | 24/27 (89%) | 24/27 (89%) — unchanged, fixes not re-run |
| Yellow answers | 0/6 populated | **6/6 populated** |
| Answer quality | N/A | 3 STRONG / 2 BORDERLINE / 1 WEAK |
| Code fixes deployed | No | Yes (AI terms, WCAG broadening) |
| Code fixes effective | N/A | Deployed but not re-triaged on P-6360 |
| Confidence scores | Field doesn't exist | Field still doesn't exist |
| New findings | — | GovCloud bleed-through, answer number-dodging, OCR artifact |
