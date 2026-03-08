# CSV Pattern Analysis: Red and Yellow Flag Knowledge Base

Source: `Red and Yellow flag kb - Best (1).csv`
Total data rows: 6,539
Total non-empty answers: 4,576

## Flag Distribution
- #redflag: 3,151
- #yellowflag: 1,425

---

## Section 1: Standard Exception Patterns

Total "standard exception" entries: 204
Distinct normalized topics: 14

| Topic | Count | Flags | Sample |
|-------|-------|-------|--------|
| Accessibility | 84 | 84 red | "Our standard exception around accessibility applies here" |
| Availability | 59 | 59 red | "Our standard exception around system availability applies here" |
| Audit Rights | 17 | 17 red | "Our standard exception around right to audit applies here" |
| RTO | 12 | 12 red | "Our standard exception around RTO of 12 hours applies here" |
| RPO | 11 | 11 red | "Our standard exception around RPO of 4 hours applies here" |
| RPO/RTO Combined | 8 | 8 red | "Our standard exception around RPO of 4 hours and RTO of 12 hours" |
| Incident Response | 4 | 4 red | "Our standard exception around incident reporting applies here" |
| Performance | 2 | 1 red, 1 yellow | "Our standard exception around system performance applies here" |
| WAF | 2 | 2 red | "Our standard exception around WAF applies here" |
| Security | 1 | 1 red | "Our standard exception around personnel security applies here" |
| Notification | 1 | 1 red | "Our standard exception around notification applies here" |
| Severity Levels | 1 | 1 red | "Our standard exception around Severity applies here" |
| Multi-tenancy | 1 | 1 red | "Our standard exception around multi-tenant environment applies here" |
| File Scanning | 1 | 1 red | "Our standard exception around scanning of files applies here" |

---

## Section 2: Non-Standard Answers by Security Domain

### Encryption (77 entries: 57 red / 20 yellow)
Key positions:
- "TLS 1.3 is not supported at moment" (8+ red)
- "We cannot encrypt ALL data at rest" (9 red)
- "We do not provide disk level encryption" (red)
- "We do not support IPSec" (red)
- "We do not implement EV SSL" (red)
- "Shield Platform Encryption provides AES-256" (yellow — requires add-on)

### Availability / SLA (179 entries: 108 red / 71 yellow)
Key positions:
- "3 9s" (99.9%) flagged red 26+ times
- "4 9s" (99.99%) flagged red 17+ times
- "100%" flagged 14 times
- "We cannot commit to the SLAs as per this requirement"
- "We don't provide fixed SLAs based on percentage"
- "We don't provide customized SLA reports"

### Audit Rights (404 entries: 345 red / 59 yellow)
Key positions:
- "Right to audit clause applies here" (176+ entries)
- "We do not share audit results and exceptions"
- "We do not provide raw scans and original source documents"
- "SOC 2 does not cover Processing Integrity or Privacy"

### RPO/RTO / DR (116 entries: 113 red / 3 yellow)
Key positions:
- RPO of 4 hours, RTO of 12 hours (standard)
- Some variants cite RTO of 8 hours
- "We do not provide RTO and RPO for MC Cloud"
- "We do not store backups offsite"
- "We do not seek agency approval with our BCP/DR plan"

### Personnel / Background Checks (131 entries: 127 red / 4 yellow)
Key positions:
- "Background checks" flagged red 84+ times
- "FBI Background Checks" (red)
- "We cannot commit to the same with Amazon employees who have physical access"
- "We don't share detailed results with customers"

### Accessibility / 508 / WCAG (292 entries: 206 red / 86 yellow)
Key positions:
- "Standard exception around accessibility" applied 84 times (all red)
- "508" flagged 148 times (147 red, 1 yellow)
- "WCAG 2.1" flagged 15 times (11 red, 4 yellow)

### Incident Response / Breach Notification (203 entries: 184 red / 19 yellow)
Key positions:
- "We do not commit to timeline" (most common)
- "Immediate Breach Notification" 43 times (42 red)
- "24 Hour Breach Notification" 39 times (33 red, 6 yellow)
- "2 Hour Breach Notification" 13 times (all red)
- "1 Hour Breach Notification" 5 times (all red)
- FedRAMP IR plan commits to 1 hour for GC+

### Logging / Monitoring (36 entries: 10 red / 26 yellow)
Key positions:
- "We do not provide infrastructure logs to agencies"
- "Cannot provide event monitoring details to SIEM tools for server, network assets"
- "We do not retain customer logs for 7 years"
- "Requires Shield Event Monitoring"

### Data Residency (4 explicit + many embedded)
Key positions:
- "Customer cannot dictate specific data location"
- "MC cloud is not hosted in Australia"
- Various country-specific concerns

### WAF (50+ entries across categories)
Key positions:
- "We do not use WAF but we have alternative controls in place"
- "We do not use host-based or application firewall"
- "We are not IRAP assessed and we do not have WAF"

### Source Code Escrow (35 entries: 31 red / 4 yellow)
Key positions:
- "We do not provide source code escrow"
- "Inapplicable to software delivered as a service subscription through a multitenant architecture"

### Multi-tenancy (23 entries: 11 red / 12 yellow)
Key positions:
- "We do not destroy drives/tapes due to multi-tenant nature"
- "We cannot pre-clear updates in a multi-tenant solution"
- "We do not implement customer policies in multi-tenant environment"

### Patching / Vulnerability Management (26 entries: 18 red / 8 yellow)
Key positions:
- "We have our own policy and process to patch our systems"
- "We do not share vulnerability information with customers"
- "Patches are not automatically installed and custom patching windows are not available"

### Privacy / Data Processing (23 entries: 10 red / 13 yellow)
Key positions:
- SOC 2 scope excludes Processing Integrity and Privacy
- EU data transfer concerns

### Virus / File Scanning (embedded across categories)
Key positions:
- "Files uploaded to our platform are non-executable and we do not scan for viruses"
- "Agency can achieve this using third party tools or AppExchange partners such as WithSecure/F-Secure"

---

## Section 3: Keyword Frequency Analysis

Top keywords across all flagged entries:
- "security" — appears in ~2,400 entries
- "data" — ~1,800 entries
- "access" — ~1,200 entries
- "audit" — ~800 entries
- "encryption" — ~400 entries
- "compliance" — ~350 entries
- "backup" — ~300 entries
- "availability" — ~280 entries
- "incident" — ~250 entries
- "monitoring" — ~200 entries

---

## Section 4: Flag Distribution by Confidence

### High-confidence RED (clear Salesforce limitation):
- Right to audit (176+ entries)
- Source code escrow (31 entries)
- 99.99%+ SLA commitment (17+ entries)
- Customer-specific background check requirements (84+ entries)
- Custom patching windows (18+ entries)
- Infrastructure log sharing (10+ entries)

### Potentially misclassified as RED:
- TLS 1.3 (8+ entries) — now supported
- WAF (50+ entries) — Cloudflare WAF is now a sub-processor
- 99.9% availability (26+ entries) — target IS ~99.9%
- 24-hour breach notification (33+ entries) — negotiable via DSR
- General "do you do background checks" (subset of 84+) — yes, per own policy

### High-confidence YELLOW:
- Shield-dependent capabilities (encryption, event monitoring, audit trail)
- Requires legal/contract negotiation (SLA credits, notification timelines)
- Product-specific conformance (accessibility ACRs)
