# Cross-Reference Analysis: CSV Flag Patterns vs. Current Salesforce Capabilities

Generated: 2026-03-07
Sources:
- CSV Pattern Analysis: 6,539 RFP flag decisions (2021-2023 era)
- Salesforce Capabilities Extract: Spring '26 (v66.0), Infrastructure & Sub-processors (Feb/Mar 2026)
- Web research: Salesforce official documentation and release notes (2025-2026)

---

## Section 1: Encryption / TLS

**CSV Position (77 entries, 57 red / 20 yellow):**
- "TLS 1.3 is not supported at moment" (8+ red flags)
- "We don't support TLS 1.3, only TLS 1.2 with Forward Secrecy"
- "We cannot encrypt ALL data at rest" (9 red flags)
- "We do not provide disk level encryption"
- "We do not support IPSec and do not implement EV SSL"

**Current Salesforce Reality (Spring '26):**
- TLS 1.3 IS NOW SUPPORTED. Salesforce began rolling out TLS 1.3 for incoming connections to Hyperforce and organizations using the Salesforce Edge Network. Starting May 1, 2025, Salesforce phased out RSA key exchanges and recommends TLS 1.3 as the preferred protocol. TLS 1.2 with Perfect Forward Secrecy remains supported as a minimum.
- Shield Platform Encryption uses AES-256-bit encryption at rest (add-on).
- Classic Encryption uses 128-bit AES (standard, limited to 175-char text fields).
- New in 2025: "Database Encryption" feature in Shield that encrypts data transparently, allowing sorting/filtering/SOQL on encrypted data.

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| TLS 1.3 "not supported" (8+ entries) | **OUTDATED — MUST UPDATE** | Change to GREEN. Salesforce supports TLS 1.3 since 2025. |
| "Cannot encrypt ALL data at rest" (9 entries) | STILL PARTIALLY TRUE | Change to YELLOW. Shield provides AES-256 at rest + infrastructure disk encryption via AWS. Not all fields/data types coverable even with Shield. |
| "We do not support IPSec" | CONFIRMED CORRECT | Still accurate. Salesforce uses TLS, not IPSec VPN tunnels. |
| "We do not implement EV SSL" | NEEDS REVIEW | EV SSL certificates broadly deprecated industry-wide. Flag is accurate but the requirement itself is obsolete. |

---

## Section 2: Data Residency / Hyperforce Regions

**CSV Position (4 explicit + many embedded references):**
- "Customer cannot dictate specific data location" (red)
- "MC cloud is not hosted in Australia" (red)
- Various country-specific data residency concerns

**Current Salesforce Reality (Spring '26):**

Hyperforce AWS regions for core Salesforce Services:
> Australia, Brazil, Canada, France, Germany, India, Indonesia, Ireland, Israel, Italy, Japan, Singapore, South Korea, Sweden, Switzerland, UAE, United Kingdom, United States (18 regions)

First-party data centers:
> France, Germany, Sweden, The Netherlands, United Kingdom, United States, Japan

Government Cloud Plus: AWS US-GOV-WEST and US-GOV-EAST (US only)

Service-specific residency limitations:
- Einstein Vision/Language: US only
- Einstein Conversation Insights: some data stored in US regardless
- Sales Cloud Einstein (Lead Scoring, Forecasting, etc.): US only
- Quip: US only
- Heroku: US (additional regions available)
- Marketing Cloud Engagement (pre-Nov 2019 purchases): US only
- Marketing Cloud EMEA disaster recovery: restored to US facility

CDN caveat: Akamai, CloudFront, Cloudflare, Fastly operate GLOBALLY. Data may transit through ANY country via CDN regardless of org region.

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| "MC cloud is not hosted in Australia" | NEEDS VERIFICATION | Marketing Cloud expanded regions since 2021-2023. Re-evaluate per current MC availability. |
| "Customer cannot dictate data location" | PARTIALLY OUTDATED | Customers CAN choose org region from 18+ Hyperforce regions. CDN, Edge, and support remain global. Change to YELLOW. |
| Countries NOT in Hyperforce list | CONFIRMED CORRECT | China, Russia, Mexico, South Africa, Argentina, New Zealand — still RED. |
| Flags written before 18-region expansion | POTENTIALLY OUTDATED | Indonesia, Israel, Italy, South Korea, Sweden, Switzerland, UAE, Ireland are recent additions. |

---

## Section 3: Availability / SLA

**CSV Position (179 entries, 108 red / 71 yellow):**
- "3 9s" (99.9%) flagged as red 26+ times
- "4 9s" (99.99%) flagged as red 17+ times
- "100%" flagged 14 times
- "We cannot commit to 99.99% availability or service credits"

**Current Salesforce Reality (Spring '26):**
- Standard commitment: ~99.9% uptime per calendar month ("commercially reasonable efforts")
- Planned maintenance excluded from SLA calculations
- Service credits may be negotiated via contract (not standard)
- trust.salesforce.com for real-time status

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| 99.99% (4 nines) = RED | CONFIRMED CORRECT | Salesforce does not commit to 99.99%. |
| 100% uptime = RED | CONFIRMED CORRECT | No cloud provider commits to 100%. |
| 99.9% (3 nines) = RED (26+ entries) | SHOULD BE YELLOW | Salesforce's target IS ~99.9%. Can generally meet it but can't contractually guarantee with standard credits. |
| Service credits = RED | CAN DIFFERENTLY | Service credits negotiable via contract. Note as commercial/legal item. |

---

## Section 4: RPO / RTO / Disaster Recovery

**CSV Position (116 entries, 113 red / 3 yellow):**
- Standard exception: RPO of 4 hours, RTO of 12 hours
- "We do not provide RTO and RPO for MC Cloud"
- "We do not store backups offsite"

**Current Salesforce Reality (Spring '26):**
- SPARC: RTO of 12 hours, RPO of 4 hours (TARGET objectives, not guarantees)
- Marketing Cloud: no published RTO/RPO
- Salesforce Backup & Recover (add-on): Continuous Data Protection for near-zero RPO
- Backups within same cloud infrastructure across availability zones

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| RPO 4hrs / RTO 12hrs | CONFIRMED CORRECT | Still per SPARC. |
| No RTO/RPO for Marketing Cloud | CONFIRMED CORRECT | MC has separate unpublished DR commitments. |
| "Do not store backups offsite" | CONFIRMED CORRECT | Multi-tenant, same cloud infra. |
| RPO < 4 hours requests = RED | CAN DIFFERENTLY | Backup & Recover CDP add-on provides near-zero RPO. Should note alternative. |
| RTO 8-12 hours = RED | NEEDS NUANCE | 12-hour target is conservative; actual recovery often faster. YELLOW for 8+ hour requirements. |

---

## Section 5: WAF (Web Application Firewall)

**CSV Position (50+ entries across categories):**
- "We do not use WAF but we have alternative controls in place" (red)
- "We do not use host-based or application firewall" (red)

**Current Salesforce Reality (Spring '26):**
- Cloudflare is an official sub-processor providing: CDN, DNS, WAF, IP reputation filtering, DDoS prevention (March 2026 Infrastructure & Sub-processors document)

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| "We do not use WAF" (50+ entries) | **OUTDATED — SHOULD BE UPDATED** | Cloudflare WAF is now a sub-processor. Platform-level protection, not customer-configurable. Change to YELLOW with nuance. |

Recommended answer: "Salesforce utilizes Cloudflare for WAF, DDoS prevention, and IP reputation filtering at the platform edge. This is not a customer-configurable WAF. Customers requiring custom WAF rules should use third-party solutions."

---

## Section 6: Audit Rights / Compliance

**CSV Position (404 entries, 345 red / 59 yellow):**
- "Right to audit clause applies here" (176+ entries)
- "We do not share audit results and exceptions"
- "We do not provide raw scans and original source documents"

**Current Salesforce Reality (Spring '26):**

Standard (no add-on):
- Login History: 6 months (20,000 records in UI)
- Setup Audit Trail: 180 days
- Field History Tracking: 20 fields/object, 18 months retention
- LogoutEventStream: available to ALL customers

Shield / Event Monitoring Add-on:
- Field Audit Trail: 200 fields/object, indefinite retention
- Real-Time Event Monitoring: 20+ event types
- LoginEvent storage: up to 10 years
- Threat Detection: credential stuffing, session hijacking, anomalies

Compliance artifacts: SOC 2 Type II (Security, Availability, Confidentiality only — no Processing Integrity or Privacy), SOC 1, ISO 27001, IRAP, FedRAMP.

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| Right to audit = RED | CONFIRMED CORRECT | Multi-tenant SaaS — no physical/logical audit rights. |
| Raw scans/workpapers = RED | CONFIRMED CORRECT | Summary reports only via Trust portal. |
| "We do not provide audit logs" | MISLEADING | Distinguish infrastructure audit (RED) vs application audit logging (GREEN standard, enhanced with Shield). |
| SOC 2 no Processing Integrity/Privacy | CONFIRMED CORRECT | Still accurate. |
| Log retention > 6 months | NEEDS NUANCE | Shield LoginEvent = 10 years. Other events exportable. |

---

## Section 7: Personnel / Background Checks

**CSV Position (131 entries, 127 red / 4 yellow):**
- "Background checks" flagged as red 84+ times
- "FBI Background Checks" (red)
- "We cannot commit to the same with Amazon employees"

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| General "background checks" = RED | NEEDS NUANCE | Salesforce DOES perform checks. Cannot meet customer-specific standards. Split: "Do you do them?" (GREEN) vs "Per our policy?" (RED) |
| FBI Background Checks = RED | CONFIRMED CORRECT | Only GC+ (FedRAMP). |
| GC+ personnel security | CAN DIFFERENTLY | FedRAMP High includes NIST 800-53 personnel controls. Note as path for federal RFPs. |

---

## Section 8: Accessibility (WCAG / Section 508)

**CSV Position (292 entries, 206 red / 86 yellow):**
- "Standard exception around accessibility" applied 84 times (all red)
- "508" flagged 148 times (147 red)
- "WCAG 2.1" flagged 15 times (11 red)

**Current Salesforce Reality:**
- Accessibility Conformance Reports (ACRs) published per product
- Lightning Experience has accessibility built into the framework
- WCAG 2.0/2.1 Level A and AA criteria covered
- Conformance is NOT 100% across all products

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| Blanket accessibility RED (292 entries) | OVERLY BROAD | "Do you support WCAG 2.1?" → YELLOW. "FULLY comply?" → RED. "Have a VPAT/ACR?" → GREEN. |

---

## Section 9: Incident Response / Breach Notification

**CSV Position (203 entries, 184 red / 19 yellow):**
- "Immediate Breach Notification" (43 entries, 42 red)
- "24 Hour Breach Notification" (39 entries, 33 red)
- "2 Hour" (13, all red), "1 Hour" (5, all red)

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| Immediate notification = RED | CONFIRMED CORRECT | |
| 1-hour / 2-hour = RED | CONFIRMED CORRECT | Except GC+ (FedRAMP 1-hour commitment). |
| 24-hour = RED (64+ entries) | SHOULD BE YELLOW | Achievable via legal DSR negotiation. |

---

## Section 10: Logging / Monitoring

**CSV Position (36 entries, 10 red / 26 yellow):**
- "We do not provide infrastructure logs"
- "Cannot provide event monitoring to SIEM"
- "We do not retain customer logs for 7 years"

**Verdicts:**

| Finding | Status | Action |
|---------|--------|--------|
| No infrastructure logs = RED | CONFIRMED CORRECT | |
| Cannot provide to SIEM | MISLEADING | Shield Event Monitoring CAN stream to SIEM via Streaming API. Split infra (RED) vs app events (YELLOW/GREEN with Shield). |
| 7-year retention = RED | NEEDS NUANCE | Shield LoginEvent = 10 years natively. Other events: export to external storage. |

---

## Section 11-15: Other Categories

| Category | Verdict Summary |
|----------|----------------|
| Virus/File Scanning | Customer uploads NOT scanned (RED). AppExchange partners available (CAN DIFFERENTLY). |
| Source Code Escrow | Inapplicable to SaaS (RED). Data portability via APIs meets intent (CAN DIFFERENTLY). |
| Multi-tenancy Limits | All flags CONFIRMED CORRECT. Cannot destroy shared media, customize patching, etc. |
| Patching/Vuln Mgmt | Raw scan data = RED. Summary reports available via Trust portal. |
| Privacy/Data Processing | SOC 2 scope confirmed. EU data transfer: Hyperforce Operating Zone now available. |

---

## Summary

| Category | Confirmed | Outdated | Needs Nuance | Can Differently |
|----------|-----------|----------|--------------|-----------------|
| TLS/Encryption | 2 | 2 | 2 | 0 |
| Data Residency | 1 | 2 | 1 | 1 |
| Availability/SLA | 2 | 0 | 1 | 1 |
| RPO/RTO/DR | 4 | 0 | 1 | 1 |
| WAF | 0 | 1 | 0 | 0 |
| Audit/Compliance | 2 | 0 | 2 | 0 |
| Personnel/Background | 2 | 0 | 1 | 1 |
| Accessibility | 0 | 1 | 1 | 1 |
| Incident Response | 2 | 0 | 1 | 1 |
| Logging/Monitoring | 1 | 0 | 2 | 0 |
| File Scanning | 1 | 0 | 0 | 1 |
| Source Code Escrow | 1 | 0 | 0 | 1 |
| Multi-tenancy | 4 | 0 | 0 | 0 |
| Patching/Vuln Mgmt | 2 | 0 | 1 | 0 |
| Privacy/Data Processing | 1 | 1 | 0 | 0 |
| **TOTALS** | **25** | **7** | **13** | **8** |

---

## Top 12 BINARY_CAN_DIFFERENTLY Candidates

| Rank | Topic | Count | Alternative Approach |
|------|-------|-------|---------------------|
| 1 | WAF | ~50+ | Cloudflare WAF is now a sub-processor |
| 2 | TLS 1.3 | 8+ | NOW SUPPORTED — change to GREEN |
| 3 | Accessibility/508/WCAG | 292 | ACRs published per product, Lightning substantial conformance |
| 4 | 24-Hour Breach Notification | 64+ | Achievable via legal DSR negotiation |
| 5 | RPO < 4 hours | ~20 | Backup & Recover CDP add-on |
| 6 | Encrypt ALL data at rest | 9+ | Shield Platform Encryption + AWS disk encryption |
| 7 | Virus/File Scanning | ~15 | AppExchange partners (WithSecure, etc.) |
| 8 | Source Code Escrow | 35 | Data portability via APIs/exports |
| 9 | Log Retention > 1 year | ~10 | Shield LoginEvent 10-year retention + export |
| 10 | Audit Logging / SIEM | ~15 | Shield Event Monitoring 20+ event types to SIEM |
| 11 | Background Checks (general) | 84+ | Salesforce DOES perform checks per own policy |
| 12 | 99.9% Availability | 26+ | Target IS ~99.9%, negotiable via contract |

---

## Priority Action Items

### Immediate (factually incorrect)
1. TLS 1.3 → GREEN (8+ entries)
2. WAF → YELLOW with Cloudflare context (50+ entries)
3. Data residency → review against 18 Hyperforce regions

### Nuance Updates (correct but misleading)
4. Accessibility blanket RED → YELLOW with ACR references (292 entries)
5. 99.9% availability → YELLOW (26+ entries)
6. 24-hour breach notification → YELLOW via DSR (64+ entries)
7. Audit logging → split infrastructure vs application
8. Background checks → split capability vs customization
