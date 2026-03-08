# AIRFX Needs-Review Analysis

**Source:** `Red and Yellow flag kb - Best.csv`
**Total rows analyzed:** 6539
**Date:** 2026-03-07

## Flag Distribution

| Flag | Count | % |
|------|------:|--:|
| Red | 4269 | 65.3% |
| Yellow | 2270 | 34.7% |

## Top 20 Question Themes

Rows are classified by first-match against 30 topic patterns applied to the Question column.

| Rank | Theme | Count | % of Total | Red | Yellow |
|-----:|-------|------:|-----------:|----:|-------:|
| 1 | Compliance / Certifications | 677 | 10.4% | 422 | 255 |
| 2 | SLA / Availability / Uptime | 606 | 9.3% | 463 | 143 |
| 3 | Business Continuity / Disaster Recovery | 430 | 6.6% | 336 | 94 |
| 4 | Data Privacy / GDPR / PII | 364 | 5.6% | 209 | 155 |
| 5 | Accessibility / WCAG / Section 508 | 331 | 5.1% | 240 | 91 |
| 6 | Access Control / Authentication | 281 | 4.3% | 189 | 92 |
| 7 | Incident Response / Breach Notification | 272 | 4.2% | 202 | 70 |
| 8 | Encryption | 261 | 4.0% | 173 | 88 |
| 9 | Penetration Testing / Vulnerability Management | 228 | 3.5% | 146 | 82 |
| 10 | Personnel Security / Background Checks | 209 | 3.2% | 147 | 62 |
| 11 | Performance / Response Time | 179 | 2.7% | 110 | 69 |
| 12 | Sub-Processors / Third Parties | 122 | 1.9% | 79 | 43 |
| 13 | Audit / Logging | 113 | 1.7% | 55 | 58 |
| 14 | Contractual / Legal / Terms | 56 | 0.9% | 31 | 25 |
| 15 | Data Residency / Sovereignty | 55 | 0.8% | 33 | 22 |
| 16 | Network Security / Firewall | 53 | 0.8% | 36 | 17 |
| 17 | Right to Audit | 45 | 0.7% | 37 | 8 |
| 18 | Physical Security / Data Center | 38 | 0.6% | 26 | 12 |
| 19 | Patch Management | 34 | 0.5% | 25 | 9 |
| 20 | Government Cloud / FedRAMP / Sovereign | 30 | 0.5% | 18 | 12 |

**Classified:** 4504 (68.9%)
**Unclassified:** 2035 (31.1%)

## Unclassified Question Clusters (Bigram Analysis)

Top bigrams from questions that didn't match any topic pattern — potential new categories.

| Bigram | Occurrences |
|--------|------------:|
| source code | 67 |
| information security | 62 |
| non disclosure | 54 |
| service provider | 51 |
| third party | 49 |
| liquidated damages | 49 |
| security requirements | 47 |
| under contract | 41 |
| contractor provide | 41 |
| https www | 38 |
| security policy | 37 |
| within days | 36 |
| customer data | 33 |
| disclosure agreement | 33 |
| confidential information | 33 |
| security plan | 32 |
| escrow agreement | 32 |
| background investigation | 31 |
| within hours | 30 |
| security breach | 30 |

## Existing Keywords Column (Top 25)

Keywords already tagged in the source CSV — shows what the original authors flagged.

| Keyword | Count |
|---------|------:|
| Security Policy and Standards | 2 |
| 508 WCAG Accessibility | 1 |
| DR Disaster Recovery | 1 |
| Accreditation | 1 |
| Contract  Handling Standards | 1 |
| SSP System Security Plan | 1 |
| Change and Patch Management | 1 |
| Patch Management | 1 |
| Vulnerability Management | 1 |
| Web Application Firewall (WAF) | 1 |
| Security Monitoring | 1 |
| Security Review/Audit | 1 |
| Incident Management | 1 |
| Performance Requirements | 1 |
| Service Level Agreement | 1 |
| Availability | 1 |
| Reporting? | 1 |
| - MC cloud is not hosted within Australian BordersNFR.101 - The solution ensures that any data originating from outside the Bank, that is to be received and processed by the System, is scanned for malicious code such as viruses,malware and other attacks or active content and/or sanitised before processing, storage or passing to another System.#yellowflagWe do not scan for viruses on our platform, this will be agencies responsibilityNFR.125 - The solution can clearly mark the sensitivity based on information classification of its content (in aggregate, and against each information asset).#yellowflag?- I am not sure if you can mark fields in MC, but this can be achieved on core. | 1 |
| (f) Media preservation and protection. When a Contractor discovers a cyber incident has occurred, the Contractor shall preserve and protect images of all known affected information systems identified in paragraph (d) of this clause and all relevant monitoring/packet capture data for at least 90 days from the submission of the cyber incident report to allow DoD to request the media or decline interest. (we don't do this) | 1 |
| (cannot do customer specific training) This training must include, at a minimum: Instructions on how to identify Metro Government Information. | 1 |
| (as long as it is CSV) Contractor shall backup business critical information at a frequency determined by Metro Government business owner. | 1 |
| ?our RPO is 4 hours.10.12.1 Business Impact is 5 5 5Q - what does this mean?10.12.2 Security risk tolerance is 3Q - what does this mean?KPI Model tab - KPI 11 There are various % figures here for availability that I do not think we will be able to support. One for legal to review. | 1 |

## Patterns Suggesting Missing Rules

Topics with high Red/Yellow density but no corresponding AIRFX rule.

| Theme | Total Qs | Red | Yellow | Flag Rate |
|-------|------:|----:|-------:|----------:|
| Compliance / Certifications | 677 | 422 | 255 | 100% |
| SLA / Availability / Uptime | 606 | 463 | 143 | 100% |
| Business Continuity / Disaster Recovery | 430 | 336 | 94 | 100% |
| Data Privacy / GDPR / PII | 364 | 209 | 155 | 100% |
| Accessibility / WCAG / Section 508 | 331 | 240 | 91 | 100% |
| Access Control / Authentication | 281 | 189 | 92 | 100% |
| Incident Response / Breach Notification | 272 | 202 | 70 | 100% |
| Encryption | 261 | 173 | 88 | 100% |
| Penetration Testing / Vulnerability Management | 228 | 146 | 82 | 100% |
| Personnel Security / Background Checks | 209 | 147 | 62 | 100% |
| Performance / Response Time | 179 | 110 | 69 | 100% |
| Sub-Processors / Third Parties | 122 | 79 | 43 | 100% |
| Audit / Logging | 113 | 55 | 58 | 100% |
| Contractual / Legal / Terms | 56 | 31 | 25 | 100% |
| Data Residency / Sovereignty | 55 | 33 | 22 | 100% |
| Network Security / Firewall | 53 | 36 | 17 | 100% |
| Right to Audit | 45 | 37 | 8 | 100% |
| Physical Security / Data Center | 38 | 26 | 12 | 100% |
| Patch Management | 34 | 25 | 9 | 100% |
| Government Cloud / FedRAMP / Sovereign | 30 | 18 | 12 | 100% |
| Multi-Tenancy / Data Segregation | 24 | 18 | 6 | 100% |
| Data Retention / Deletion / Disposal | 19 | 8 | 11 | 100% |
| Training / Security Awareness | 19 | 10 | 9 | 100% |
| Data Classification | 14 | 8 | 6 | 100% |
| Insurance / Liability / Indemnity | 13 | 8 | 5 | 100% |

### Sample Questions by High-Flag Theme

#### Compliance / Certifications (677 flagged / 677 total)

- [RED] 3.2 Accreditation3.2.1 The Contractor is required to maintain accreditation (or similar) for the term of the contract, such as:a. ISO 9001:20158 <a href="https://www.iso.org/standard/62085.html" alt="
- [RED] 3.3 Contact Handling Standards3.3.1 - The Contractor is required to ensure that all Contact handling complies with call handling standards published by:Auscontact Association<a href="https://www.ausco
- [RED] 3.8 - Information Security3.8.2 - The Contractor must allow the Department or its agent to audit the processes and systems in use to ensure compliance with sections 2.8.1, 2.2.1 and 2.5.2.
- [RED] #Requirement 6 - That ICT services supporting operations to be on shore, not be delivered from overseas. This includes the management of systems from overseas, and support staff. If there are off-shor

#### SLA / Availability / Uptime (606 flagged / 606 total)

- [RED] #36 Service Levels#[
- [RED] #37 System Availability
- [RED] #38 System Operating and Support HoursThe Contractor shall provide statistical report on the System Availability inside the monthly progress report.
- [RED] 16 - Security Other requirements16.1 Respondent must describe how the Application will meet ACT Government availability requirements.?Uptime Guarantee: System uptime as an ACT Government Business Crit

#### Business Continuity / Disaster Recovery (430 flagged / 430 total)

- [RED] Business Continuity and Disaster Recovery Plans3.13.1 - The Contractor must develop and deliver to the Department for its approval a business continuity and disaster recovery plan as part of the Proce
- [YELLOW] #44 Hosting and Environment ManagementThe Contractor shall propose and implement backup and recovery plans. The plans shall specify the following information:
- [RED] 16.4 The Application should provide ability for both environment and data level restoration capability.? Recovery Point Objective: Data loss resulting from accidental deletion or hardware failure shou
- [RED] NFR3 System Reliability1. The Recovery Point Objective (RPO) of the solution shall be no loss of current user data 2. The Recovery Time Objective (RTO) of the Solution shall be 15 Minutes

#### Data Privacy / GDPR / PII (364 flagged / 364 total)

- [RED] 6.2.19 StandardsNR-STA-01 The solution will be compliant with DELWP, Agency and Victorian Government legislation, standards, policies etc. including: ? Privacy and Data Protection Act 2004 ? Public Ad
- [RED] I also reviewed the following document ?2_W3047-23Q-Tend-B---DRAFT-Minor-Works---SERVICES-Agreement-2016-Council.pdf?11. Confidentiality and privacy#[
- [RED] 2.2 Context - in Scope Non-Functional15 - The Seller reports all security incidents, including but not limited to data confidentiality, privacy or integrity breaches. The Seller is required to provide
- [RED] 2. Information Handling2.1 The Contractor shall not transfer security-classified information or personal data held in connection with the Contract Singapore, or allow parties outside Singapore to have

#### Accessibility / WCAG / Section 508 (331 flagged / 331 total)

- [RED] Accessibility of Documents3.10.1 Website accessibility encompasses all disabilities that affect access to the web, including visual, auditory, physical, speech, cognitive and neurological disabilities
- [RED] NFR 1.1 - AccessibilityThe Solution must be capable of meeting the digital service standard accessibility guidelines: https://www.dta.gov.au/standard/9-make-it-accessible/.
- [RED] NFR 1.2 - Website ConformanceThe Solution must conform to WCAG 2.1 Level AA.
- [RED] 2.3. Web Content Accessibility2.3.1. The Supplier will ensure that any website, associated material and/or online publications (where applicable) complies with the Web Content AccessibilityGuidelines 

#### Access Control / Authentication (281 flagged / 281 total)

- [RED] NFR.1.54 - MandatoryThe Supplier must perform authenticated monthly vulnerability scanning on all Supplier managed Information Communication Technology and Operational Technology devices that transmit
- [RED] S4.80 to S4.91 User Identity and Access ManagementNote: - The solution will be hosted on a DH Azure environment in the department's existing tenancy. Please respond to the following questions in the c
- [RED] ImmunityNFR-50 File Upload ProtectionFile content will be screened for malware during upload through web applications and during uploads into file stores.? MIME based file upload restrictions applied 
- [RED] 7.1 - Access Control policy

#### Incident Response / Breach Notification (272 flagged / 272 total)

- [RED] 9. ICT and Data Security Incident Management9.8 The Supplier shall notify Authority and Authority designated representative within the specified time upon detection of incident. The Supplier shall adh
- [RED] #[17]? Do you agree to notify SOH as soon as possible and no later than 24 hoursfor security breaches impacting on the service or which includes SOH data?How will you notify SOH
- [RED] 51A.4 If there is any occurrence of a Security Breach Event, the Contractor shall, at no cost to the Authority:(b) within forty-eight (48) hours of such occurrence, prepare and provide the Authority w
- [RED] 51A.5 The Incident Report shall set out:

#### Encryption (261 flagged / 261 total)

- [YELLOW] NFR.1.37 - MandatoryThe Supplier must ensure back-ups of Customer Data are encrypted and meet the requirements of the Queensland Government Data Encryption Standard.
- [YELLOW] Security Requirements7 ConfidentialityEnsure appropriate isolation of the NSW Government data, for instance assigning separate encryption keys for each customer for encrypting the data-at-rest
- [YELLOW] 12 Data Management12.1 Data backups, restoration, archiving and encryption to be managed by the vendor as per the relevant Cloud Agreement.
- [RED] SSC7 Transport Encryption#[

## Recommended Next 10 Rules

Ranked by (question volume × flag rate). These topics appear frequently and almost always get flagged, suggesting deterministic rules could handle them.

### 1. Compliance / Certifications
- **Volume:** 677 questions
- **Red:** 422 | **Yellow:** 255 | **Flag rate:** 100%
- **Rule type suggestion:**
  `BINARY_CAN` for held certs (ISO 27001, SOC 2, FedRAMP). `BINARY_CANNOT` for certs not held. Individual rules per certification.
- **Sample questions:**
  - _3.2 Accreditation3.2.1 The Contractor is required to maintain accreditation (or similar) for the term of the contract, s_
  - _3.3 Contact Handling Standards3.3.1 - The Contractor is required to ensure that all Contact handling complies with call _
  - _3.8 - Information Security3.8.2 - The Contractor must allow the Department or its agent to audit the processes and syste_

### 2. SLA / Availability / Uptime
- **Volume:** 606 questions
- **Red:** 463 | **Yellow:** 143 | **Flag rate:** 100%
- **Rule type suggestion:**
  `NUMERIC_TIERED_MIN` — Use existing 3-tier uptime rule (<99.7% GREEN, 99.7-99.9% YELLOW, >99.9% RED).
- **Sample questions:**
  - _#36 Service Levels#[_
  - _#37 System Availability_
  - _#38 System Operating and Support HoursThe Contractor shall provide statistical report on the System Availability inside _

### 3. Business Continuity / Disaster Recovery
- **Volume:** 430 questions
- **Red:** 336 | **Yellow:** 94 | **Flag rate:** 100%
- **Rule type suggestion:**
  `NUMERIC_MIN` for RPO/RTO (existing). `BINARY_CAN_DIFFERENTLY` for customer-approved BCP plans.
- **Sample questions:**
  - _Business Continuity and Disaster Recovery Plans3.13.1 - The Contractor must develop and deliver to the Department for it_
  - _#44 Hosting and Environment ManagementThe Contractor shall propose and implement backup and recovery plans. The plans sh_
  - _16.4 The Application should provide ability for both environment and data level restoration capability.? Recovery Point _

### 4. Data Privacy / GDPR / PII
- **Volume:** 364 questions
- **Red:** 209 | **Yellow:** 155 | **Flag rate:** 100%
- **Rule type suggestion:**
  `BINARY_CAN` — Salesforce provides DPA, is GDPR-compliant, supports data subject access requests via platform tools.
- **Sample questions:**
  - _6.2.19 StandardsNR-STA-01 The solution will be compliant with DELWP, Agency and Victorian Government legislation, standa_
  - _I also reviewed the following document ?2_W3047-23Q-Tend-B---DRAFT-Minor-Works---SERVICES-Agreement-2016-Council.pdf?11._
  - _2.2 Context - in Scope Non-Functional15 - The Seller reports all security incidents, including but not limited to data c_

### 5. Accessibility / WCAG / Section 508
- **Volume:** 331 questions
- **Red:** 240 | **Yellow:** 91 | **Flag rate:** 100%
- **Rule type suggestion:**
  `BINARY_CAN_DIFFERENTLY` — Salesforce provides a VPAT and works toward WCAG 2.1 AA but cannot guarantee full conformance across all features.
- **Sample questions:**
  - _Accessibility of Documents3.10.1 Website accessibility encompasses all disabilities that affect access to the web, inclu_
  - _NFR 1.1 - AccessibilityThe Solution must be capable of meeting the digital service standard accessibility guidelines: ht_
  - _NFR 1.2 - Website ConformanceThe Solution must conform to WCAG 2.1 Level AA._

### 6. Access Control / Authentication
- **Volume:** 281 questions
- **Red:** 189 | **Yellow:** 92 | **Flag rate:** 100%
- **Rule type suggestion:**
  `BINARY_CAN` — SSO, SAML, MFA, RBAC all natively supported. Individual rules for specific mechanisms.
- **Sample questions:**
  - _NFR.1.54 - MandatoryThe Supplier must perform authenticated monthly vulnerability scanning on all Supplier managed Infor_
  - _S4.80 to S4.91 User Identity and Access ManagementNote: - The solution will be hosted on a DH Azure environment in the d_
  - _ImmunityNFR-50 File Upload ProtectionFile content will be screened for malware during upload through web applications an_

### 7. Incident Response / Breach Notification
- **Volume:** 272 questions
- **Red:** 202 | **Yellow:** 70 | **Flag rate:** 100%
- **Rule type suggestion:**
  `BINARY_CAN_DIFFERENTLY` — Salesforce notifies affected customers of confirmed incidents but does not commit to specific SLA timelines for notification.
- **Sample questions:**
  - _9. ICT and Data Security Incident Management9.8 The Supplier shall notify Authority and Authority designated representat_
  - _#[17]? Do you agree to notify SOH as soon as possible and no later than 24 hoursfor security breaches impacting on the s_
  - _51A.4 If there is any occurrence of a Security Breach Event, the Contractor shall, at no cost to the Authority:(b) withi_

### 8. Encryption
- **Volume:** 261 questions
- **Red:** 173 | **Yellow:** 88 | **Flag rate:** 100%
- **Rule type suggestion:**
  `BINARY_CAN` — AES-256 at rest, TLS 1.2+ in transit. `BINARY_CAN_DIFFERENTLY` for FIPS 140-2 (Shield only) and BYOK.
- **Sample questions:**
  - _NFR.1.37 - MandatoryThe Supplier must ensure back-ups of Customer Data are encrypted and meet the requirements of the Qu_
  - _Security Requirements7 ConfidentialityEnsure appropriate isolation of the NSW Government data, for instance assigning se_
  - _12 Data Management12.1 Data backups, restoration, archiving and encryption to be managed by the vendor as per the releva_

### 9. Penetration Testing / Vulnerability Management
- **Volume:** 228 questions
- **Red:** 146 | **Yellow:** 82 | **Flag rate:** 100%
- **Rule type suggestion:**
  Needs analysis — review sample questions to determine appropriate rule type.
- **Sample questions:**
  - _21. Vulnerability Management21.12 The Contractor shall mitigate and remediate all vulnerabilities discovered through the_
  - _8. Security Testing8.13 to 8.15 - Ad-hoc Security Review / Audit_
  - _Monitoring, Logs &amp; AlertsNFR22- On request, the Vendor agrees to undergo a Network Penetration Test (as per Industry_

### 10. Personnel Security / Background Checks
- **Volume:** 209 questions
- **Red:** 147 | **Yellow:** 62 | **Flag rate:** 100%
- **Rule type suggestion:**
  `BINARY_CAN_DIFFERENTLY` — Salesforce conducts background checks per local law but does not submit to customer-specific vetting processes.
- **Sample questions:**
  - _#requirement 23 Contractor personnel must be able to complete the ATO Pre-engagement Integrity Check (PEIC) which includ_
  - _S5.37 - Cyber Security - Personnel SecurityThe suppliers personnel may be required to sign a deed of confidentiality or _
  - _20 - Data Security20.1.6 - prohibit and prevent any of the Supplier?s Staff who do not have the appropriate level of sec_

## Complex Multi-Topic Questions (3+ themes)

Found 322 questions spanning 3+ security topics. These are typically the hardest for deterministic rules and may need RAG answers.

- [RED] Topics: SLA / Availability / Uptime, Accessibility / WCAG / Section 508, Physical Security / Data Center
  _NF013 - Technical / Infrastructure - ReliabilityAVAILABILITY: It should be operational and accessible when required for use, with an uptime of more th_
- [RED] Topics: Data Privacy / GDPR / PII, Accessibility / WCAG / Section 508, Data Classification
  _6.2.19 StandardsNR-STA-01 The solution will be compliant with DELWP, Agency and Victorian Government legislation, standards, policies etc. including: _
- [RED] Topics: Business Continuity / Disaster Recovery, SLA / Availability / Uptime, Contractual / Legal / Terms
  _AR15 - System Availability and Resilience:The proposed Legal Case Management Solution needs to provide 99.99% availability with planned maintenance ou_
- [YELLOW] Topics: Penetration Testing / Vulnerability Management, SLA / Availability / Uptime, Patch Management, Contractual / Legal / Terms
  _AR27 - Patching:The supplier needs to ensure that the Legal Case Management Solution, database, firmware, OS and environment are currentwith patches a_
- [RED] Topics: Compliance / Certifications, Accessibility / WCAG / Section 508, Contractual / Legal / Terms
  _Legal Requirements &amp; ComplianceL11 The solution shall comply with latest Web Content Accessibility Guidelines (WCAG)._
- [RED] Topics: SLA / Availability / Uptime, Patch Management, Change Management
  _9. Maintainability - 9.02 Patch ManagementDeploy Emergency patches within 1 day of availability The timeline for releasing critical patches 5 days of _
- [RED] Topics: Data Residency / Sovereignty, Business Continuity / Disaster Recovery, SLA / Availability / Uptime, Physical Security / Data Center
  _5.2.4 AvailabilityThe assurance that the platform has suitable recoverability and protection from system failures, natural disasters or malicious atta_
- [YELLOW] Topics: Compliance / Certifications, Incident Response / Breach Notification, SLA / Availability / Uptime
  _M.BT28: "There must be regular service evaluation meetings.At a minimum, these discussions must cover SLA compliance over a defined observation period_
- [RED] Topics: Penetration Testing / Vulnerability Management, Compliance / Certifications, SLA / Availability / Uptime, Performance / Response Time
  _Page 53: "Without prejudice to any other right of audit or access granted to the NAO pursuant to the Contract Agreement, the NAO shall be entitled at _
- [RED] Topics: Access Control / Authentication, Compliance / Certifications, Accessibility / WCAG / Section 508
  _14.10. Section 508 Compliance. Unless specifically authorized in the Contract, any electronic or information technology offered to the State of Arizon_
- [RED] Topics: Access Control / Authentication, Compliance / Certifications, Accessibility / WCAG / Section 508
  _Section 508 Compliance. Unless specifically authorized in the Contract, any electronic or information technology offered to the State of Arizona under_
- [RED] Topics: Access Control / Authentication, Audit / Logging, Compliance / Certifications
  _Pg. 153 - The Contractor shall maintain an audit trail and record data access of authorized users and the authorization level of access granted to inf_
- [RED] Topics: Audit / Logging, Incident Response / Breach Notification, Performance / Response Time
  _The State shall have the right to participate in the investigation of a security incident involving its data or conduct its own independent investigat_
- [RED] Topics: Business Continuity / Disaster Recovery, SLA / Availability / Uptime, Physical Security / Data Center
  _DATA CENTER RESILIENCY - Ability to maintain resilient data centers resulting in zero customer downtime in the event of a failure or compromise of one_
- [RED] Topics: Compliance / Certifications, Data Privacy / GDPR / PII, Sub-Processors / Third Parties
  _3.4.3 - 3.4.3 Right of Audits by City/Security Review Rights. City and its agents, auditors (internal and external), regulators, and other representat_

## Summary & Next Steps

1. **4504 of 6539** questions (69%) map to 30 security themes.
2. **2035** questions (31%) are unclassified — mostly functional/product questions, not security.
3. Top 3 themes: **Compliance / Certifications** (677), **SLA / Availability / Uptime** (606), **Business Continuity / Disaster Recovery** (430).
4. The recommended 10 rules would cover the highest-volume, highest-flag-rate topics.
5. Multi-topic questions (322) are best served by RAG, not deterministic rules.
6. Consider adding `BINARY_CAN_DIFFERENTLY` rules first — they cover the most common pattern: 'we do this, but not exactly how you asked.'
