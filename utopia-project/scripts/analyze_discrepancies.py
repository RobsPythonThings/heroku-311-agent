#!/usr/bin/env python3
"""Analyze validation_discrepancies.csv and write docs/discrepancy_analysis.md"""

import csv
from collections import Counter, defaultdict
from pathlib import Path

CSV_PATH = Path.home() / "utopia-project" / "docs" / "validation_discrepancies.csv"
OUT_PATH = Path.home() / "utopia-project" / "docs" / "discrepancy_analysis.md"

def main():
    rows = []
    with open(CSV_PATH, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)

    total = len(rows)
    print(f"Loaded {total} discrepancies")

    # Category breakdown
    cat_counts = Counter(r.get('Category', '').strip() for r in rows)

    # Rule ID breakdown
    rule_counts = Counter(r.get('Rule_ID', '').strip() for r in rows)

    # Original vs Engine flag transitions
    transitions = Counter()
    for r in rows:
        orig = r.get('Original_Flag', '').strip()
        eng = r.get('Engine_Flag', '').strip()
        transitions[(orig, eng)] += 1

    # DOWNGRADE analysis: where Original=Red, Engine=Green or Yellow
    downgrades = [r for r in rows if r.get('Category', '').strip() == 'DOWNGRADE']
    upgrades = [r for r in rows if r.get('Category', '').strip() == 'UPGRADE']

    # NO_MATCH breakdown
    no_match_security = [r for r in rows if r.get('Rule_ID', '').strip() == 'NO_MATCH_SECURITY']
    no_match_functional = [r for r in rows if r.get('Rule_ID', '').strip() == 'NO_MATCH_FUNCTIONAL']
    prefilter = [r for r in rows if r.get('Rule_ID', '').strip() == 'PREFILTER_NON_SECURITY']
    parse_fails = [r for r in rows if '_PARSE_FAIL' in r.get('Rule_ID', '')]

    # Analyze NO_MATCH_SECURITY questions for topic clusters
    from collections import Counter as C
    security_topics = {
        'Right to Audit / Security Audit': ['right to audit', 'audit the', 'security audit', 'audit access', 'audit of the'],
        'Security Policy Compliance': ['security policy', 'security standard', 'security requirement', 'comply with.*security', 'information security management'],
        'Incident Response / Breach Process': ['incident', 'breach', 'security event'],
        'Personnel Security / Clearance': ['security clearance', 'personnel security', 'background', 'vetting', 'police check', 'staff.*security'],
        'Patch / Vulnerability Management': ['patch', 'vulnerability', 'remediat'],
        'Business Continuity / DR Plan': ['business continuity', 'disaster recovery', 'bcp', 'dr plan', 'continuity plan'],
        'Data Segregation / Multi-tenant': ['segregat', 'separat.*data', 'tenant', 'multi-tenant', 'isolation'],
        'Certifications (ISO/SOC)': ['iso 27001', 'soc 2', 'soc2', 'certification', 'accredit'],
        'Confidentiality / NDA': ['confidential', 'non-disclosure', 'nda', 'non disclosure'],
        'Security Assessment / Review': ['security assessment', 'security review', 'security testing', 'independent.*assess'],
        'Encryption (general)': ['encrypt', 'cryptograph'],
        'Access Control': ['access control', 'access management', 'identity management'],
        'Data Protection / Privacy': ['data protection', 'privacy', 'personal data', 'gdpr'],
        'Logging / Monitoring': ['log', 'monitor', 'audit trail'],
    }

    nms_topics = Counter()
    nms_unmatched = 0
    for r in no_match_security:
        q = r.get('Question', '').lower()
        matched = False
        for topic, keywords in security_topics.items():
            for kw in keywords:
                if kw in q:
                    nms_topics[topic] += 1
                    matched = True
                    break
            if matched:
                break
        if not matched:
            nms_unmatched += 1

    # NO_MATCH_FUNCTIONAL analysis: what SHOULD have been caught
    nmf_topics = Counter()
    for r in no_match_functional:
        q = r.get('Question', '').lower()
        orig = r.get('Original_Flag', '').strip()
        if 'accessibility' in q or 'wcag' in q or '508' in q:
            nmf_topics['Accessibility/WCAG (missed by engine)'] += 1
        elif 'performance' in q or 'response time' in q:
            nmf_topics['Performance (not security)'] += 1
        elif 'availability' in q or 'uptime' in q:
            nmf_topics['Availability (missed by engine)'] += 1
        elif 'backup' in q or 'recovery' in q:
            nmf_topics['Backup/Recovery (missed by engine)'] += 1
        elif 'sla' in q or 'service level' in q:
            nmf_topics['SLA (not security)'] += 1
        else:
            nmf_topics['Other functional'] += 1

    # Generate report
    lines = []
    lines.append("# Validation Discrepancy Analysis")
    lines.append(f"\n**Source:** `docs/validation_discrepancies.csv`")
    lines.append(f"**Total discrepancies:** {total}")
    lines.append(f"**Date:** 2026-03-08\n")

    lines.append("## Overview\n")
    lines.append("A discrepancy occurs when the AIRFX engine produces a different flag than the original human-assigned flag from the KB. Not all discrepancies are errors — the engine may be *correctly* downgrading over-flagged questions.\n")

    lines.append("## Category Breakdown\n")
    lines.append("| Category | Count | % |")
    lines.append("|----------|------:|--:|")
    for cat, count in cat_counts.most_common():
        lines.append(f"| {cat} | {count} | {count/total*100:.1f}% |")
    lines.append("")

    lines.append("## Flag Transitions\n")
    lines.append("| Original | Engine | Count | Direction |")
    lines.append("|----------|--------|------:|-----------|")
    for (orig, eng), count in sorted(transitions.items(), key=lambda x: -x[1]):
        direction = 'DOWNGRADE' if (orig == 'RED' or orig == 'Red') and eng in ('Green', 'Yellow') else (
            'UPGRADE' if (orig == 'YELLOW' or orig == 'Yellow') and eng == 'Red' else 'OTHER')
        lines.append(f"| {orig} | {eng} | {count} | {direction} |")
    lines.append("")

    lines.append("## Engine Rule Distribution\n")
    lines.append("Which engine rules are producing discrepancies:\n")
    lines.append("| Rule ID | Count | % | Meaning |")
    lines.append("|---------|------:|--:|---------|")
    rule_meanings = {
        'NO_MATCH_SECURITY': 'Security Q, no rule matched → Yellow',
        'NO_MATCH_FUNCTIONAL': 'No security terms, no rule → Green',
        'PREFILTER_NON_SECURITY': 'Pre-filter caught functional terms → Green',
        'UPTIME': 'Uptime rule matched (numeric)',
        'UPTIME_PARSE_FAIL': 'Uptime detected but number extraction failed',
        'RPO_PARSE_FAIL': 'RPO detected but number extraction failed',
        'RTO_PARSE_FAIL': 'RTO detected but number extraction failed',
        'ACCESSIBILITY_508': 'WCAG/508 matched → Yellow (CAN_DIFFERENTLY)',
        'WAF_ALTERNATIVE': 'WAF matched → Yellow (CAN_DIFFERENTLY)',
        'FILE_SCANNING': 'Virus/malware scanning → Yellow (CAN_DIFFERENTLY)',
        'DATA_RESIDENCY': 'Data residency detected, no country → Yellow',
        'PEN_TEST_CUSTOMER': 'Pen test matched → Green (CAN)',
        'BREACH_NOTIFY_GOV': 'Breach notification (numeric) → varies',
        'SAAS_DELIVERY': 'SaaS/cloud delivery → Green (CAN)',
        'ISO_14001': 'ISO 14001 → Red (CANNOT)',
        'ISO_45001': 'ISO 45001 → Red (CANNOT)',
        'RPO': 'RPO matched (numeric)',
        'TLS': 'TLS matched → Green (CAN)',
    }
    for rule, count in rule_counts.most_common(20):
        meaning = rule_meanings.get(rule, '')
        lines.append(f"| {rule} | {count} | {count/total*100:.1f}% | {meaning} |")
    lines.append("")

    lines.append("## Root Cause Analysis\n")

    lines.append("### 1. NO_MATCH_SECURITY — Engine says Yellow, Original says Red\n")
    lines.append(f"**Count:** {len(no_match_security)} ({len(no_match_security)/total*100:.1f}% of all discrepancies)\n")
    lines.append("These are security questions the engine has no rule for. The engine correctly says 'I don't know' (Yellow), but the original KB flagged them Red.\n")
    lines.append("**Topic breakdown within NO_MATCH_SECURITY:**\n")
    lines.append("| Topic | Count |")
    lines.append("|-------|------:|")
    for topic, count in nms_topics.most_common():
        lines.append(f"| {topic} | {count} |")
    lines.append(f"| (No topic match) | {nms_unmatched} |")
    lines.append("")

    lines.append("### 2. NO_MATCH_FUNCTIONAL — Engine says Green, Original says Red/Yellow\n")
    lines.append(f"**Count:** {len(no_match_functional)} ({len(no_match_functional)/total*100:.1f}% of all discrepancies)\n")
    lines.append("Engine classified these as functional (no security terms detected) and auto-Greened. But the original KB flagged them Red or Yellow. Two sub-cases:\n")
    lines.append("- **Genuine functional:** Engine is correct — these are non-security questions that were over-flagged in the KB.\n")
    lines.append("- **Misclassified:** Security-adjacent questions where the engine's term list doesn't detect them (e.g., 'accessibility', 'WCAG', 'background check').\n")
    lines.append("**Sub-topic breakdown:**\n")
    lines.append("| Sub-topic | Count |")
    lines.append("|-----------|------:|")
    for topic, count in nmf_topics.most_common():
        lines.append(f"| {topic} | {count} |")
    lines.append("")

    lines.append("### 3. PREFILTER_NON_SECURITY — Engine says Green, Original says Red/Yellow\n")
    lines.append(f"**Count:** {len(prefilter)} ({len(prefilter)/total*100:.1f}% of all discrepancies)\n")
    lines.append("Pre-filter detected functional terms and auto-Greened. Most are correct downgrades — SLA, performance, reporting questions that aren't actually security.\n")

    lines.append("### 4. PARSE_FAIL — Engine says Yellow, Original says Red\n")
    lines.append(f"**Count:** {len(parse_fails)} ({len(parse_fails)/total*100:.1f}% of all discrepancies)\n")
    lines.append("Engine detected the right topic (uptime/RPO/RTO) but couldn't extract a number. Common causes:\n")
    lines.append("- RPO/RTO phrased as 'no data loss' or 'zero RPO' (no numeric)\n")
    lines.append("- Question mentions topic in header but number is in a table not included\n")
    lines.append("- Mixed units or ambiguous phrasing\n")

    lines.append("### 5. UPGRADE — Engine says Red, Original says Yellow\n")
    lines.append(f"**Count:** {len(upgrades)} ({len(upgrades)/total*100:.1f}% of all discrepancies)\n")
    lines.append("Engine correctly identifies a BINARY_CANNOT (e.g., ISO 14001, ISO 45001). Original KB was lenient with Yellow.\n")

    lines.append("\n## Key Findings\n")
    lines.append(f"1. **{len(no_match_security)} discrepancies ({len(no_match_security)/total*100:.0f}%)** are NO_MATCH_SECURITY — the engine's biggest gap. Adding rules for the top topics (audit, security policy, incident response, personnel security, patch management) would address the majority.")
    lines.append(f"2. **{len(no_match_functional)} discrepancies ({len(no_match_functional)/total*100:.0f}%)** are NO_MATCH_FUNCTIONAL — many are legitimate downgrades (accessibility and performance are not security). Some (~{nmf_topics.get('Accessibility/WCAG (missed by engine)', 0)}) are accessibility questions that need broader keyword coverage in the pre-filter or ACCESSIBILITY_508 rule.")
    lines.append(f"3. **{len(parse_fails)} discrepancies ({len(parse_fails)/total*100:.0f}%)** are PARSE_FAIL — the engine correctly identifies the topic but can't extract a number. Improving the numeric parser for 'zero RPO', 'no data loss', and 'within X minutes' patterns would fix these.")
    lines.append(f"4. **{len(upgrades)} discrepancies ({len(upgrades)/total*100:.0f}%)** are UPGRADE — the engine is stricter than the original KB. These are correct.")
    lines.append(f"5. Most DOWNGRADE discrepancies are **intentional** — the engine is more conservative than the original KB, preferring Yellow ('I don't know') over Red ('Salesforce can't do this') when no rule matches.\n")

    lines.append("## Recommendations\n")
    lines.append("### Immediate (10 new rules)")
    lines.append("Add rules for the highest-volume NO_MATCH_SECURITY topics:")
    lines.append("1. RIGHT_TO_AUDIT (CAN_DIFFERENTLY) — SOC 2/ISO 27001 attestations, no direct audit access")
    lines.append("2. SECURITY_ASSESSMENT_ACCESS (CAN_DIFFERENTLY) — independent assessments, no customer-directed audits")
    lines.append("3. INCIDENT_RESPONSE_PROCESS (CAN_DIFFERENTLY) — SF has IR program, no customer-format reports")
    lines.append("4. SECURITY_CLEARANCE_PERSONNEL (CAN_DIFFERENTLY) — background checks per own policy, not customer vetting")
    lines.append("5. PATCH_MGMT_PROCESS (CAN_DIFFERENTLY) — SF manages patching cadence, no customer-directed timelines")
    lines.append("6. DATA_SEGREGATION (CAN) — logical tenant isolation in multi-tenant architecture")
    lines.append("7. ISO_27001_CERT (CAN) — ISO 27001 certification held")
    lines.append("8. SOC2_CERT (CAN) — SOC 2 Type II attestation held")
    lines.append("9. BCP_DR_PLAN (CAN_DIFFERENTLY) — SF has BCP/DR, no customer review/approval")
    lines.append("10. CONFIDENTIALITY_NDA (CAN_DIFFERENTLY) — SF NDA, not customer-specific NDAs\n")

    lines.append("### Future improvements")
    lines.append("- Broaden ACCESSIBILITY_508 keywords to catch more WCAG/accessibility variants")
    lines.append("- Improve numeric parser for 'zero RPO', 'no data loss', 'within N minutes' patterns")
    lines.append("- Add security terms to pre-filter: 'clearance', 'vetting', 'audit' (currently missed)")

    report = '\n'.join(lines)
    OUT_PATH.write_text(report, encoding='utf-8')
    print(f"Report written to {OUT_PATH}")

if __name__ == '__main__':
    main()
