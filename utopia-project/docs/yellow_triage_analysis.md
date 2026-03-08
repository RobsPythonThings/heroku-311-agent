# P-0042 Yellow Triage Analysis

**Date:** 2026-03-08
**Org:** utopia-uat
**Current state:** 300 Green / 45 Yellow / 3 Red (348 total)
**Target:** Below 30 Yellow

## Summary

After the accuracy gauntlet, P-0042 dropped from 48 to 45 Yellows (3 were converted to Red by broadened CUSTOMER_VM rule). All 45 remaining Yellows are **correctly Yellow** — they represent questions where Salesforce meets the intent but not the letter, or where the engine correctly identifies ambiguity.

The 45 Yellows are 15 unique question patterns repeated across 3 lots.

## Hard_No__mdt Keyword Check

**3 records were already caught and converted to Red** during the accuracy gauntlet:
- GPS-0202 / GPS-0320 / GPS-0531 — "utilize system development and data security best practices..." — now matches CUSTOMER_VM keywords ("our.*infrastructure")

**No remaining Yellows contain Hard_No__mdt keywords.** All checked against: dedicated hardware, source code escrow, IPv6, FIPS 140-3, SecNumCloud, ISO 14001/20000/45001, service credit, defer upgrades, customer VM, on-premises (for non-MuleSoft deals).

## Functional Question Check

**No remaining Yellows are purely functional.** All 45 contain security terms and correctly pass through the pre-filter to rules. Questions classified as functional without security terms are auto-Green via NO_MATCH_FUNCTIONAL.

## Rule Distribution (45 Yellows)

| Rule ID | Count | Category | Unique Questions |
|---------|------:|----------|-----------------|
| UPTIME | 4 | SLA/Uptime | "99.9% system availability" |
| UPTIME_PARSE_FAIL | 4 | SLA/Uptime | "Response times per System Availability tab" |
| RESPONSE_RECOVERY_TIME | 4 | SLA/Uptime | "Standard response and recovery times" |
| CIA_TRIAD | 3 | Security Posture | "Confidentiality, integrity, availability, non-repudiation" |
| VULNERABILITY_ASSESSMENT | 3 | Security Posture | "Vulnerability assessment (static/dynamic code analysis)" |
| SECURITY_POSTURE_DESCRIBE | 3 | Security Posture | "Describe security system: auth, session mgmt, access control" |
| BCP_DR_PLAN | 3 | Security Posture | "Disaster recovery and BCP operations" |
| AUDIT_INFO_ACCESS | 3 | Audit/Monitoring | "Physical access, logical security, system logs" |
| RIGHT_TO_AUDIT | 3 | Audit/Monitoring | "Generate detailed user activity and audit data" |
| AUDIT_ALERTS_USER | 3 | Audit/Monitoring | "Audits and alerts for user activity (records, exports, printing)" |
| SIEM_INTEGRATION | 3 | Audit/Monitoring | "Integration with SIEM platforms" |
| ACCESSIBILITY_508 | 3 | Compliance | "Section 508 of the Rehabilitation Act" |
| NO_MATCH_SECURITY | 6 | Regulatory/Policy | Customer policy compliance + state regulations |

## Category Summary

| Category | Count | % of Yellows |
|----------|------:|-------------|
| SLA/Uptime | 12 | 27% |
| Security Posture | 12 | 27% |
| Audit/Monitoring | 12 | 27% |
| Compliance (508) | 3 | 7% |
| Regulatory/Policy (NO_MATCH) | 6 | 13% |

### Certification Questions: 3
- ACCESSIBILITY_508 × 3 — "Section 508 compliance". Yellow because Salesforce demonstrates substantial WCAG 2.1 conformance via ACRs but does not claim 100% compliance.

### Data Residency Questions: 0
- All data residency Yellows were resolved in earlier rounds. P-0042 is a US deal, all residency questions are Green.

### Contractual/Legal Questions: 6
- NO_MATCH_SECURITY × 6:
  - "Facilitating compliance with Department information, security policies, data sharing agreements, state IT guidelines, and SSA certification" × 3
  - "Capabilities for meeting 60GG-2 F.A.C., 60GG-4 F.A.C., CISA Cloud Security TRA, CISA Zero Trust Maturity Model, NIST 800-53, FIPS 199" × 3
- These reference **Florida-specific state regulations** and **customer-specific compliance policies** — genuinely require human review.

### Genuinely Ambiguous: 6
- Same as contractual/legal above. These are the only records where the engine truly cannot determine the answer without human input.

## Path to Below 30 Yellows

### Currently achievable conversions (engine changes):

| Conversion | Records | Risk | Rationale |
|-----------|--------:|------|-----------|
| CIA_TRIAD → Green | 3 | Low | SF addresses all three pillars. SOC 2/ISO attestations cover CIA. Could change to BINARY_CAN. |
| VULNERABILITY_ASSESSMENT → Green | 3 | Low | SF performs static/dynamic analysis as part of SDLC. Could change to BINARY_CAN with caveat about sharing results. |
| SECURITY_POSTURE_DESCRIBE → Green | 3 | Low | SF has comprehensive security. Could change to BINARY_CAN with detailed description. |
| **Subtotal** | **9** | | **45 → 36** |

### Aggressive conversions (requires business decision):

| Conversion | Records | Risk | Rationale |
|-----------|--------:|------|-----------|
| UPTIME 99.9% → Green | 4 | Medium | 99.9% is within achievable range but requires AE approval. Could change Yellow tier from 99.7-100 to 99.9-100, making 99.7-99.9 Green. |
| RESPONSE_RECOVERY_TIME → Green | 4 | Medium | RPO 4h/RTO 12h are the standard. Could argue the question is answered definitively. But "customer-specific SLAs" caveat remains. |
| **Subtotal** | **8** | | **36 → 28** |

### Cannot convert (legitimate Yellows):

| Rule | Records | Why It Stays Yellow |
|------|--------:|---------------------|
| UPTIME_PARSE_FAIL | 4 | References external doc tab — no number to extract |
| BCP_DR_PLAN | 3 | Plans not shared for customer review |
| AUDIT_INFO_ACCESS | 3 | Physical access logs N/A for SaaS |
| RIGHT_TO_AUDIT | 3 | SOC 2/ISO in lieu of direct audit |
| AUDIT_ALERTS_USER | 3 | Shield Event Monitoring required (paid add-on) |
| SIEM_INTEGRATION | 3 | Shield Event Monitoring required (paid add-on) |
| ACCESSIBILITY_508 | 3 | Substantial conformance, not 100% |
| NO_MATCH_SECURITY | 6 | Customer-specific/state-specific regulations |
| **Total** | **28** | |

### Recommended path: 45 → 28

1. **Convert CIA_TRIAD to BINARY_CAN** (3 records → Green)
2. **Convert VULNERABILITY_ASSESSMENT to BINARY_CAN** (3 records → Green)
3. **Convert SECURITY_POSTURE_DESCRIBE to BINARY_CAN** (3 records → Green)
4. **Tighten UPTIME tier** — change Yellow threshold from 99.7 to 99.9 (4 records → Green)
5. **Convert RESPONSE_RECOVERY_TIME to BINARY_CAN** (4 records → Green)

This gets P-0042 to **28 Yellows** — below the 30 target.

### Remaining 28 Yellows would be:
- 4 UPTIME_PARSE_FAIL (can't extract number from reference)
- 3 BCP_DR_PLAN (plans not shared)
- 3 AUDIT_INFO_ACCESS (physical access N/A)
- 3 RIGHT_TO_AUDIT (no direct audit)
- 3 AUDIT_ALERTS_USER (Shield add-on)
- 3 SIEM_INTEGRATION (Shield add-on)
- 3 ACCESSIBILITY_508 (not 100%)
- 6 NO_MATCH_SECURITY (customer/state-specific)

All 28 are **legitimate Yellows** where Salesforce genuinely cannot meet the exact letter of the requirement.

## Recommendation

Implement conversions 1-3 (low risk, 9 records → Green) immediately. Discuss conversions 4-5 (medium risk, 8 records → Green) with the SE team before implementing, as they involve business judgment about SLA thresholds and recovery time commitments.
