# P-0042 Benchmark Results

## Run Date: 2026-03-08

### Baseline vs Updated Engine

| Metric | Baseline | Updated | Delta |
|--------|----------|---------|-------|
| Total Questions | 348 | 348 | — |
| RED | 0 | 0 | — |
| GREEN | 207 | 275 | **+68 (+33%)** |
| YELLOW | 141 | 73 | **-68 (-48%)** |
| Functional | 0 | 266 | +266 |
| Security | 0 | 79 | +79 |

### Changes That Drove the Shift

1. **CMDT Context Now Active** — 194/195 records activated. CMDT capability context (3,395 chars for US) is being built and passed through the pipeline.

2. **NO_MATCH Split** — Questions with no rule match are now split:
   - No security terms → GREEN (`NO_MATCH_FUNCTIONAL`, classified Functional)
   - Has security terms → YELLOW (`NO_MATCH_SECURITY`, classified Security)

3. **Pre-filter Expansion** — ~160 functional terms + ~84 security terms with data processing/transfer terms added. More functional questions caught early → auto-Green.

4. **10 New CAN_DIFFERENTLY Rules** — Right to Audit, Security Assessment Access, Incident Response, Personnel Clearance, Patch Management, BCP/DR Plan, Confidentiality/NDA, Vulnerability Scan Results. These converted some NO_MATCH_SECURITY Yellows to rule-matched Yellows with better reasons.

5. **Obligation Detection** — `must/shall` (mandatory) vs `should/may` (optional) language now softens flags:
   - BINARY_CANNOT + optional → YELLOW instead of RED
   - BINARY_CAN_DIFFERENTLY + optional → GREEN instead of YELLOW

6. **Question Classification** — All 348 questions now classified: 266 Functional, 79 Security, 3 unclassified.

### CMDT Context Sample (US, no product filter)

Flowing through `AIRFX_ResponseFlagInvocable.buildCMDTCapabilityContext()`:
- Hyperforce Region: US available (AWS us-east-1)
- Product regions: 7 products × US availability
- Certifications: FedRAMP High/Moderate, ISO 27001:2022, ISMAP
- Feature availability: Shield, BYOK, EU OZ, GovCloud Plus, Premier Support
- Hard Nos: 17 items (dedicated HW, on-prem, SBOM, etc.)
- CDN caveat included on all region records

### Country/Product End-to-End Verification

Tested `buildCMDTCapabilityContext()` with 5 countries:

| Country | Context Length | Hyperforce |
|---------|--------------|------------|
| AU | 3,478 chars | yes (ap-southeast-2) |
| DE | 3,518 chars | yes (eu-central-1) |
| JP | 3,466 chars | yes (ap-northeast-1) |
| US | 3,395 chars | yes (us-east-1) |
| NO | 2,852 chars | **no** |

Country and product flow confirmed: Agent → AIRFX_AgentAction → AIRFX_ResponseFlagInvocable → buildCMDTCapabilityContext → FlagResult.CMDTCapabilityContext → AIRFX_GenerateAnswer → Prompt Template.

### MuleSoft/Tableau Rule Ordering Fix

Product-specific rules (MuleSoft on-prem, Tableau on-prem, etc.) moved before generic BINARY_CANNOT rules. First-match-wins requires product exceptions to fire before generic blocks. 134/134 tests passing after fix.

### Conclusion

68 fewer Yellows means 68 fewer questions requiring human review per P-0042. The engine is now classifying correctly and the CMDT context provides deterministic grounding for prompt template answers. No false Reds introduced.
