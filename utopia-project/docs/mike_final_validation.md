# Mike Rosa Validation — Final Report

**Date:** 2026-03-08
**Org:** utopia-uat
**Engine:** AIRFX_ResponseFlagInvocable (94+ rules, 221 tests)
**Validator:** Mike Rosa (Security Architect, domain expert)

## Overall Agreement

| Metric | Value |
|--------|------:|
| Records with Mike feedback | 316 |
| Engine matches Mike | 275 |
| Engine disagrees with Mike | 41 |
| **Agreement rate** | **87.0%** |

## Breakdown by Mike's Verdict

### Mike says GREEN (210 records)

| Engine Response | Count | % |
|----------------|------:|--:|
| Engine agrees (Green) | 196 | 93.3% |
| Engine says Yellow | 14 | 6.7% |
| Engine says Red | 0 | 0.0% |

The 14 records where Mike says Green but engine says Yellow are:
- 3 "availability"/"incident" terms used in non-security context (volunteer scheduling)
- 4 security capability questions Mike considers answered (audit, encryption, SIEM, DR)
- 3 response/recovery time questions Mike considers answered
- 2 WCAG/508 accessibility questions
- 1 AI/skills matching question
- 1 data sovereignty question Mike considers answered

**Pattern:** Mike is more lenient than the engine on questions where Salesforce *has* the capability but the engine flags Yellow because the answer requires nuance. Mike's view: "we can answer this definitively." Engine's view: "this needs a qualified answer."

### Mike says YELLOW (15 records)

| Engine Response | Count | % |
|----------------|------:|--:|
| Engine agrees (Yellow) | 1 | 6.7% |
| Engine says Green | 14 | 93.3% |

The 14 records where Mike says Yellow but engine says Green are the most interesting mismatches. Mike's reasoning:
- "We need to know customer's requirements" (password policies)
- "We cannot tie backups to SLAs"
- "We don't let customers monitor our infrastructure directly"
- "Solution design is unknown"
- "Unclear what immediately means"
- "Not sure what data retention policies they need"

**Pattern:** Mike flags Yellow when the question contains **customer-specific unknowns** — requirements the engine can't evaluate without knowing the customer's exact policies. The engine sees a keyword match (RBAC, password, audit) and auto-Greens. Mike sees "we need more context before committing."

### Mike says RED (1 record)

- GPS-0139: "Standard response and recovery times" — Mike says Red, engine says Yellow.
- Mike's comment: "Answered with support response times. Missing context."

### Mike confirmed current flag (78 records)

78 records where Mike explicitly confirmed the engine's flag is correct.

### Mike says WRONG (4 records)

| Record | Engine Flag | Question |
|--------|-----------|----------|
| GPS-4393 | Green | "Permission for photos" |
| GPS-4426 | Green | "Have you prior experience of working for Law Enforcement?" |
| GPS-4427 | Green | "What is the name and version of the software?" |
| GPS-4435 | Green | "How is your solution deployed; on-premise, cloud based?" |

GPS-4435 is notable — "on-premise" is a security term and the engine Greened it via Tableau on-prem rule. Mike says Wrong because the question deserves more than an auto-Green. The other 3 are functional questions Mike thinks the AI answer quality was wrong (not the flag).

### Mike other comments (8 records)

- GPS-3352: "Red for commercial. Green for Gov Cloud." — Engine says Red. This is the product-context problem: the engine doesn't branch by commercial vs. GovCloud.
- GPS-4243: Same pattern — "Red for commercial. Green for Gov Cloud."
- GPS-0195: "The key here is the word dedicated." — Engine missed the nuance of "dedicated."
- GPS-0218: "This misses the intent." — Engine auto-Greened but answer doesn't address what was asked.

## Error Direction

| Direction | Count | Impact |
|-----------|------:|--------|
| Engine too conservative (Yellow, Mike says Green) | 14 | SEs review questions they don't need to |
| Engine too aggressive (Green, Mike says Yellow) | 14 | SEs miss questions that need nuance |
| Mike says Wrong (answer quality) | 4 | Flag may be right but answer is poor |
| Other (context-dependent) | 8 | GovCloud branching, ambiguous questions |
| Mike says Red, engine says Yellow | 1 | Missing context |

The error is **balanced** — 14 too conservative, 14 too aggressive. Neither direction dominates.

## Remaining Gaps

### 14 records Mike says should be Green (engine says Yellow)

These are candidates for new rules or rule refinements:
- Response/recovery time questions → could become BINARY_CAN with standard RPO/RTO values
- Audit/encryption/SIEM questions → could become BINARY_CAN with Salesforce's known capabilities
- Availability/incident in non-security context → pre-filter refinement needed

### 14 records Mike says should be Yellow (engine says Green)

These are the harder problem. Mike wants Yellow when:
- Customer-specific requirements are referenced but unknown
- The question uses "comply with" language that implies full conformance
- Implementation details matter (e.g., password dictionary checks, SFTP specifics)

These require **contextual reasoning** the deterministic engine can't do — they're genuinely ambiguous without knowing the customer's specific policies.

### 2 GovCloud branching gaps

GPS-3352 and GPS-4243 are Red for commercial but Green for GovCloud. The engine needs product-context awareness to branch these correctly. This is the "GovCloud bleed-through" item on the roadmap.

## Conclusion

**87.0% agreement with Mike Rosa's expert judgment across 316 reviewed records.**

The engine correctly handles 275 of 316 records Mike reviewed. The 41 mismatches split evenly between too-conservative (14) and too-aggressive (14), with 13 edge cases (wrong answers, ambiguous context, GovCloud branching).

The most actionable improvement: the 14 records where Mike says Yellow but the engine says Green. These represent a class of questions where the engine auto-Greens on keyword match but the real answer depends on customer-specific requirements. This is the gap between deterministic rules and expert judgment — and it's where the SE feedback loop would have the most impact.
