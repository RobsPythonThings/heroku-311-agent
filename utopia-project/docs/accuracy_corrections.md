# AIRFX Accuracy Corrections — Cross-Reference Findings

**Source:** docs/cross_reference_findings.md
**Date:** 2026-03-08
**Grounding:** Salesforce Spring '26 (v66.0)

---

## Findings Requiring Correction

### 1. TLS 1.3 "Not Supported" (8+ KB entries)

**Old answer:** "TLS 1.3 is not supported at moment. We support TLS 1.2 with Forward Secrecy."
**Correct answer (Spring '26):** Salesforce supports TLS 1.3 for incoming connections on Hyperforce and Salesforce Edge Network since 2025. TLS 1.2 with Perfect Forward Secrecy remains the minimum. TLS 1.0 and 1.1 have been disabled.
**Updated flag:** GREEN (was RED)
**Affects Apex rules:** No — TLS rule already exists as BINARY_CAN (TLS_SUPPORT). KB correction only.

### 2. "We Do Not Use WAF" (50+ KB entries)

**Old answer:** "We do not use WAF but we have alternative controls in place."
**Correct answer:** Salesforce utilizes Cloudflare as a sub-processor for WAF, DDoS prevention, and IP reputation filtering at the platform edge. This is platform-managed and not customer-configurable. Customers requiring custom WAF rules should use third-party solutions in front of Experience Cloud sites.
**Updated flag:** YELLOW (was RED)
**Affects Apex rules:** No — WAF_ALTERNATIVE rule already implemented as BINARY_CAN_DIFFERENTLY. KB correction only.

### 3. Disk-Level Encryption "Not Provided" (9+ KB entries)

**Old answer:** "We do not provide disk level encryption."
**Correct answer:** Hyperforce infrastructure provides disk-level encryption via AWS (AES-256). Shield Platform Encryption (add-on) provides application-layer AES-256 encryption at rest with customer key management (BYOK). Not all field types can be encrypted at the application layer even with Shield.
**Updated flag:** YELLOW (was RED)
**Affects Apex rules:** No — ENCRYPTION_AT_REST rule exists as BINARY_CAN. ENCRYPT_ALL_DATA exists as BINARY_CAN_DIFFERENTLY. KB correction only.

### 4. ISO 27001:2013 References (multiple KB entries)

**Old answer:** References "ISO 27001:2013" certification.
**Correct answer:** Salesforce holds ISO 27001:2022 certification (updated from 2013 standard). The transition to ISO 27001:2022 was completed.
**Updated flag:** No flag change
**Affects Apex rules:** No — ISO_27001_CERT rule references "iso 27001" generically without version. KB correction only.

### 5. "Customer Cannot Dictate Data Location" (4+ KB entries)

**Old answer:** "Customer cannot dictate specific data location."
**Correct answer:** Customers can choose their org region from 18 Hyperforce regions (AU, BR, CA, FR, DE, IN, ID, IE, IL, IT, JP, SG, KR, SE, CH, AE, UK, US). CDN (Akamai, CloudFront, Cloudflare, Fastly), Edge Network, and support operations remain globally distributed. Data may transit any country via CDN.
**Updated flag:** YELLOW (was RED)
**Affects Apex rules:** No — DATA_RESIDENCY rule already handles via CONDITIONAL_DATA_RESIDENCY. KB correction only.

### 6. Hyperforce Region Lists (pre-2024 entries)

**Old answer:** Missing regions: Indonesia, Israel, Italy, South Korea, Sweden, Switzerland, UAE, Ireland.
**Correct answer:** 18 Hyperforce regions available as of Spring '26. All 8 recently added regions are now live.
**Updated flag:** Varies per question
**Affects Apex rules:** Yes — `ALLOWED_DATA_COUNTRIES` set in AIRFX_ResponseFlagInvocable.cls should include all 18. **Verified: already includes all 18 regions.**

### 7. 99.9% Uptime = RED (26+ KB entries)

**Old answer:** 99.9% flagged as RED.
**Correct answer:** Salesforce's standard SLA commits to 99.7% uptime. 99.9% is achievable and can be negotiated with AE involvement. Requirements above 99.9% (99.99%, 99.999%) are Red.
**Updated flag:** YELLOW (was RED)
**Affects Apex rules:** No — UPTIME rule already uses 3-tier model: <99.7% GREEN, 99.7-99.9% YELLOW, >99.9% RED. Correctly implemented.

### 8. 24-Hour Breach Notification = RED (64+ KB entries)

**Old answer:** Blanket RED for any breach notification timeline.
**Correct answer:** Salesforce commits to timely notification of confirmed security incidents. 72-hour notification is the GDPR standard and generally achievable. 24-hour notification may be achievable via Data Security Rider (DSR) negotiation. Immediate (1-hour, 2-hour) notification remains Red. Government Cloud Plus customers have FedRAMP-aligned 1-hour notification for US-CERT.
**Updated flag:** YELLOW for 24-72 hour, RED for <24 hour (except GovCloud Plus)
**Affects Apex rules:** Yes — BREACH_NOTIFY_GOV rule exists but general 24-hour notification is not covered. **Recommendation: add BREACH_NOTIFY_TIMELINE CAN_DIFFERENTLY rule for 24-72 hour requests.**

### 9. "We Do Not Provide Audit Logs" (misleading, multiple entries)

**Old answer:** Conflates infrastructure audit with application audit logging.
**Correct answer:** Infrastructure/OS/network logs are not available (multi-tenant SaaS). Application-level audit logging is comprehensive: Setup Audit Trail (180 days), Login History (6 months), Field History Tracking (18 months). With Shield Event Monitoring (add-on): 20+ event types, LoginEvent up to 10 years, real-time streaming to SIEM.
**Updated flag:** YELLOW (was RED) — split infrastructure (RED) vs application (GREEN/YELLOW)
**Affects Apex rules:** No — SIEM_INTEGRATION and AUDIT_INFO_ACCESS rules already cover this. KB correction only.

### 10. Background Checks = Blanket RED (84+ KB entries)

**Old answer:** All background check questions flagged RED.
**Correct answer:** Salesforce DOES perform background checks on employees per its global policy and local law requirements. Customer-specific vetting standards, clearance levels, or sharing of check results cannot be accommodated. For US federal customers, Government Cloud Plus meets NIST 800-53 personnel security controls via FedRAMP High authorization.
**Updated flag:** Split: "Do you perform background checks?" → GREEN. "Per our specific policy?" → RED. "FBI/federal checks?" → YELLOW (GovCloud Plus path).
**Affects Apex rules:** No — BACKGROUND_CHECK_GENERAL rule already exists as BINARY_CAN_DIFFERENTLY. KB correction only.

### 11. Accessibility/508 = Blanket RED (292 KB entries)

**Old answer:** "Standard exception around accessibility applies here" — blanket RED.
**Correct answer:** Salesforce publishes product-specific Accessibility Conformance Reports (ACRs) demonstrating substantial WCAG 2.1 Level A/AA conformance for Lightning Experience. Full 100% conformance is not claimed across all products. ACRs available at salesforce.com/company/legal/508_accessibility/.
**Updated flag:** YELLOW (was RED)
**Affects Apex rules:** No — ACCESSIBILITY_508 rule already exists as BINARY_CAN_DIFFERENTLY. KB correction only.

### 12. Log Retention > 1 Year (10+ KB entries)

**Old answer:** RED for any log retention > 6 months.
**Correct answer:** Standard: Login History 6 months, Setup Audit Trail 180 days, Field History 18 months. Shield Event Monitoring: LoginEvent up to 10 years natively. Other event types can be exported to external SIEM/storage for long-term retention.
**Updated flag:** YELLOW (was RED)
**Affects Apex rules:** No — LOG_RETENTION_LONG rule already exists as BINARY_CAN_DIFFERENTLY. KB correction only.

### 13. "Cannot Provide to SIEM" (15+ KB entries)

**Old answer:** "Cannot provide event monitoring to SIEM."
**Correct answer:** Shield Event Monitoring (add-on) provides 20+ application event types that can be streamed to external SIEM tools via the Streaming API. This covers login events, API events, report exports, permission changes, and more. Infrastructure/OS/network logs are not available.
**Updated flag:** YELLOW (was RED)
**Affects Apex rules:** No — SIEM_INTEGRATION rule already exists as BINARY_CAN_DIFFERENTLY. KB correction only.

### 14. RPO < 4 Hours = Blanket RED (20+ KB entries)

**Old answer:** Any RPO requirement under 4 hours = RED.
**Correct answer:** Standard SPARC RPO is 4 hours. For near-zero RPO, Salesforce Backup & Recover with Continuous Data Protection (add-on) is available. Customers can also implement backup via Data Loader, APIs, or AppExchange partners (OwnBackup, Odaseva).
**Updated flag:** YELLOW for near-zero RPO (was RED)
**Affects Apex rules:** No — CDP_BACKUP rule already exists as BINARY_CAN_DIFFERENTLY. KB correction only.

---

## Summary

| # | Finding | Entries Affected | Flag Change | Apex Rule Impact |
|---|---------|-----------------|-------------|-----------------|
| 1 | TLS 1.3 | 8+ | RED → GREEN | None (rule correct) |
| 2 | WAF | 50+ | RED → YELLOW | None (rule correct) |
| 3 | Disk encryption | 9+ | RED → YELLOW | None (rule correct) |
| 4 | ISO 27001:2013 | Multiple | No change | None |
| 5 | Data location | 4+ | RED → YELLOW | None (rule correct) |
| 6 | Hyperforce regions | Multiple | Varies | Verified correct |
| 7 | 99.9% uptime | 26+ | RED → YELLOW | None (rule correct) |
| 8 | 24-hour breach | 64+ | RED → YELLOW | **Add BREACH_NOTIFY_TIMELINE rule** |
| 9 | Audit logs | Multiple | RED → YELLOW | None (rule correct) |
| 10 | Background checks | 84+ | RED → YELLOW/GREEN | None (rule correct) |
| 11 | Accessibility/508 | 292 | RED → YELLOW | None (rule correct) |
| 12 | Log retention | 10+ | RED → YELLOW | None (rule correct) |
| 13 | SIEM | 15+ | RED → YELLOW | None (rule correct) |
| 14 | RPO < 4 hours | 20+ | RED → YELLOW | None (rule correct) |

**Key finding:** 13 of 14 accuracy issues are already correctly handled by existing Apex rules. Only #8 (24-hour breach notification) requires a new rule. The KB data is the primary source of staleness — the engine is ahead of the KB.
