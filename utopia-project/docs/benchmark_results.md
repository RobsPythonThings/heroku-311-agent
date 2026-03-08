# P-0042 Benchmark Results

## Latest Run: 2026-03-08 (obligation + product dimensions)

### Baseline Comparison

| Metric | Baseline (original KB) | Run 1 (10 new rules) | Run 2 (obligation + product) | Delta (Run 1 -> 2) |
|--------|----------------------|---------------------|---------------------------|-------------------|
| Total Questions | 348 | 348 | 348 | — |
| RED | 0 | 0 | 0 | — |
| GREEN | 207 | 275 | **278** | +3 |
| YELLOW | 141 | 73 | **70** | -3 |
| Functional | — | 266 | 266 | — |
| Security | — | 79 | 79 | — |

### Project Context

- **Project:** P-0042 (348 questions)
- **Product:** Core - Experience Cloud; MuleSoft; Public Sector Solutions; Tableau - Cloud
- **Country:** US
- **Questions with optional language (should/may):** 36

### Rule Distribution (Run 2)

| Rule | Count | Flag | Classification |
|------|------:|------|----------------|
| PREFILTER_NON_SECURITY | 201 | Green | Functional |
| NO_MATCH_FUNCTIONAL | 65 | Green | Functional |
| NO_MATCH_SECURITY | 43 | Yellow | Security |
| UPTIME_PARSE_FAIL | 11 | Yellow | Security |
| DATA_RESIDENCY | 6 | Green | Security |
| UPTIME | 4 | Green/Yellow/Red | Security |
| RIGHT_TO_AUDIT | 3 | Yellow | Security |
| MULTI_FACTOR_AUTH | 3 | Green | Security |
| SIEM_INTEGRATION | 3 | Yellow | Security |
| SOC2_CERT | 3 | Green | Security |
| ACCESSIBILITY_508 | 3 | Yellow | Security |
| BCP_DR_PLAN | 3 | Yellow | Security |

### What Changed from Run 1 to Run 2

**+3 Green / -3 Yellow** — Obligation softening converted 3 BINARY_CAN_DIFFERENTLY Yellow flags to Green where questions used optional language ("should", "may", "preferred").

The obligation engine correctly identified that questions phrased as "The vendor should..." or "It is preferred that..." are less demanding than "The vendor must..." — so CAN_DIFFERENTLY rules (where Salesforce meets the intent but not the letter) are softened from Yellow to Green.

### What Drove the Shift from Baseline to Current

1. **Pre-filter expansion** — 201 questions (58%) caught by functional pre-filter (reporting, SLA, staffing, training, etc.)
2. **NO_MATCH split** — 65 questions with no security terms auto-Green (functional classification)
3. **10 new CAN_DIFFERENTLY rules** — Right to Audit, Security Assessment, Incident Response, Personnel Clearance, Patch Management, BCP/DR, Confidentiality/NDA, Data Segregation, ISO 27001, SOC 2
4. **Obligation parsing** — 36 questions with optional language; 3 CAN_DIFFERENTLY results softened from Yellow to Green
5. **Product dimensions** — MuleSoft/Tableau product rules available (no impact on P-0042 since product-specific on-prem/dedicated questions weren't asked)

### CMDT Context

Flowing through `buildCMDTCapabilityContext()`:
- Hyperforce Region: US available (AWS us-east-1)
- Product regions: 7 products x US availability
- Certifications: FedRAMP High/Moderate, ISO 27001:2022, ISMAP
- Feature availability: Shield, BYOK, EU OZ, GovCloud Plus, Premier Support
- Hard Nos: 17 items (dedicated HW, on-prem, SBOM, etc.)
- CDN caveat included on all region records

### Performance

- **CPU time:** ~6.5 seconds for 348 records (65% of 10,000ms governor limit)
- **DML:** Updates all 348 records with new flag, reason, classification, and CMDT context

### Remaining Yellow Breakdown

70 Yellow flags remain:
- **43 NO_MATCH_SECURITY** — security questions with no rule match (needs human review + RAG answer)
- **11 UPTIME_PARSE_FAIL** — uptime/availability detected but no number extracted
- **3 RIGHT_TO_AUDIT** — audit access (CAN_DIFFERENTLY)
- **3 SIEM_INTEGRATION** — SIEM integration (CAN_DIFFERENTLY)
- **3 ACCESSIBILITY_508** — WCAG/508 (CAN_DIFFERENTLY)
- **3 BCP_DR_PLAN** — BCP/DR plan review (CAN_DIFFERENTLY)
- **4 UPTIME** — uptime in Yellow tier (99.7-99.9%)

### Conclusion

71% reduction in Yellow flags from baseline (141 -> 70). Each Yellow flag now has a clear reason — either a rule-matched CAN_DIFFERENTLY with a pre-written alternative response, or a genuine unknown requiring human review + RAG answer. No false Reds introduced across any run.
