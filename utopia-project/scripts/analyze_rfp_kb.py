#!/usr/bin/env python3
"""
Analyze 'Red and Yellow flag kb - Best.csv' for question themes,
security topic clusters, and candidate new rules for AIRFX engine.
Output: docs/needs_review_analysis.md
"""

import csv
import re
from collections import Counter, defaultdict
from pathlib import Path

CSV_PATH = Path.home() / "Desktop" / "Agentic Utopia" / "utopia-project" / "Red and Yellow flag kb - Best.csv"
OUT_PATH = Path.home() / "utopia-project" / "docs" / "needs_review_analysis.md"

# ── Topic taxonomy ──────────────────────────────────────────────────
# Each topic: (label, list of keyword patterns)
# Patterns are applied to lowercased question text
TOPICS = [
    ("Data Residency / Sovereignty", [
        r'\bdata\s*residen', r'\bdata\s*sovereign', r'\bdata\s*location',
        r'\bdata\s*stor(age|ed)\b.*\bcountry', r'\bgeographic', r'\bjurisdiction',
        r'\bonshore\b', r'\boffshore\b', r'\bdata\s*centre\s*location',
        r'\bdata\s*center\s*location', r'\bhyperforce\b', r'\bdata\s*at\s*rest\b.*\blocation',
    ]),
    ("Encryption", [
        r'\bencrypt', r'\baes[-\s]?256', r'\btls\b', r'\bssl\b',
        r'\bat[-\s]?rest\b.*\bencrypt', r'\bin[-\s]?transit\b.*\bencrypt',
        r'\bcryptograph', r'\bcipher\b', r'\bhsm\b', r'\bkey\s*management',
        r'\bfips\s*140', r'\bbyok\b', r'\bbring\s*your\s*own\s*key',
    ]),
    ("Access Control / Authentication", [
        r'\baccess\s*control', r'\bauthenticat', r'\bauthoriz', r'\brbac\b',
        r'\brole.based', r'\bmulti.factor', r'\bmfa\b', r'\b2fa\b',
        r'\bsso\b', r'\bsingle\s*sign', r'\bsaml\b', r'\bldap\b',
        r'\boauth\b', r'\bprivileged\s*access', r'\bpam\b',
        r'\bidentity\b.*\bmanagement', r'\biam\b', r'\bpassword\b',
        r'\bsession\s*manage', r'\bsession\s*timeout',
    ]),
    ("Audit / Logging", [
        r'\baudit\s*log', r'\baudit\s*trail', r'\blogging\b', r'\blog\s*retention',
        r'\bevent\s*log', r'\bforensic', r'\blog\s*management',
        r'\bsiem\b', r'\bsecurity\s*log', r'\bactivity\s*log',
        r'\baudit\s*capabilit', r'\bauditab',
    ]),
    ("Penetration Testing / Vulnerability Management", [
        r'\bpenetration\s*test', r'\bpen\s*test', r'\bvulnerability',
        r'\bsecurity\s*test', r'\bsecurity\s*scan', r'\bsecurity\s*assessment',
        r'\bvapt\b', r'\bvulnerability\s*assessment',
        r'\bbug\s*bounty', r'\bvdp\b', r'\bvulnerability\s*disclosure',
    ]),
    ("Business Continuity / Disaster Recovery", [
        r'\bbusiness\s*continuity', r'\bdisaster\s*recovery', r'\bbcp\b',
        r'\bdr\s*plan', r'\bdr\b.*\brecovery', r'\bfailover\b', r'\bfail\s*over',
        r'\bbackup\b', r'\brecover[y|able]', r'\brpo\b', r'\brto\b',
        r'\bresilien', r'\bredundanc',
    ]),
    ("Compliance / Certifications", [
        r'\biso\s*27001', r'\biso\s*27017', r'\biso\s*27018', r'\biso\s*9001',
        r'\bsoc\s*[12]', r'\bsoc\s*2', r'\bsoc2\b', r'\bfedramp\b',
        r'\bfed\s*ramp', r'\bhipaa\b', r'\bpci[\s-]*dss', r'\bcomplianc',
        r'\bcertificat', r'\baccredit', r'\battestation',
        r'\birap\b', r'\bism\b.*\bcontrol', r'\bessential\s*eight',
        r'\bnist\b', r'\bcsa\s*star', r'\bstar\s*certif',
    ]),
    ("Data Privacy / GDPR / PII", [
        r'\bgdpr\b', r'\bprivacy\b', r'\bpersonal\s*data', r'\bpii\b',
        r'\bdata\s*protection\b', r'\bdata\s*subject', r'\bright\s*to\s*be\s*forgotten',
        r'\bdata\s*erasure', r'\bdata\s*portability', r'\bdpa\b',
        r'\bprivacy\s*impact', r'\bpia\b', r'\bdpia\b',
        r'\bdata\s*process', r'\bsub.?processor',
    ]),
    ("Incident Response / Breach Notification", [
        r'\bincident\s*respon', r'\bincident\s*manage', r'\bbreach\s*notif',
        r'\bsecurity\s*incident', r'\bdata\s*breach', r'\bincident\s*report',
        r'\bnotif.*\bbreach', r'\bincident\s*detect',
    ]),
    ("SLA / Availability / Uptime", [
        r'\bsla\b', r'\bservice\s*level', r'\bavailability\b', r'\buptime\b',
        r'\b99[\.\d]*%', r'\bdown\s*time', r'\bdowntime\b',
        r'\bsystem\s*availability', r'\bservice\s*availability',
    ]),
    ("Right to Audit", [
        r'\bright\s*to\s*audit', r'\baudit\s*right', r'\baudit\s*access',
        r'\baudit\s*the\s*(contractor|provider|supplier|vendor)',
        r'\bindependent\s*audit', r'\bthird.party\s*audit',
    ]),
    ("Network Security / Firewall", [
        r'\bfirewall\b', r'\bwaf\b', r'\bweb\s*application\s*firewall',
        r'\bnetwork\s*secur', r'\bids\b', r'\bips\b',
        r'\bintrusion\s*(detect|prevent)', r'\bddos\b', r'\banti.ddos',
        r'\bnetwork\s*segment', r'\bnetwork\s*isolat', r'\bvlan\b',
    ]),
    ("Patch Management", [
        r'\bpatch\s*manage', r'\bpatch(ing|es)\b', r'\bsecurity\s*patch',
        r'\bsoftware\s*update', r'\bhotfix',
    ]),
    ("Personnel Security / Background Checks", [
        r'\bbackground\s*check', r'\bpersonnel\s*security', r'\bsecurity\s*clear',
        r'\bvetting\b', r'\bpolice\s*(check|record|clearance)',
        r'\bstaff\s*screen', r'\bemployee\s*screen', r'\bcriminal\s*(check|record)',
        r'\bcitizenship\b', r'\bnational\s*security\s*check',
    ]),
    ("Multi-Tenancy / Data Segregation", [
        r'\bmulti.?tenant', r'\bdata\s*segregat', r'\bdata\s*separat',
        r'\btenant\s*isolat', r'\bshared\s*infrastructure',
        r'\blogical\s*separat', r'\blogical\s*isolat',
    ]),
    ("Data Retention / Deletion / Disposal", [
        r'\bdata\s*retention', r'\bdata\s*delet', r'\bdata\s*dispos',
        r'\bdata\s*destruct', r'\bsanitiz', r'\bdata\s*purge',
        r'\bend\s*of\s*contract', r'\bexit\s*plan', r'\bdata\s*return',
        r'\bdata\s*removal',
    ]),
    ("Accessibility / WCAG / Section 508", [
        r'\baccessib', r'\bwcag\b', r'\bsection\s*508', r'\b508\b',
        r'\bada\b.*\bcompl', r'\bscreen\s*reader', r'\bassistive\s*tech',
    ]),
    ("Performance / Response Time", [
        r'\bperformance\b', r'\bresponse\s*time', r'\blatency\b',
        r'\bthroughput\b', r'\bscalab', r'\bload\s*test',
        r'\bconcurrent\s*user', r'\bperformance\s*test',
    ]),
    ("Sub-Processors / Third Parties", [
        r'\bsub.?processor', r'\bthird.?party\b.*\b(vendor|provider|service)',
        r'\bsupply\s*chain', r'\bsubcontract', r'\bvendor\s*manage',
        r'\bthird.?party\s*risk', r'\bthird.?party\s*access',
    ]),
    ("Change Management", [
        r'\bchange\s*manage', r'\bchange\s*control', r'\brelease\s*manage',
        r'\bconfiguration\s*manage',
    ]),
    ("Physical Security / Data Center", [
        r'\bphysical\s*secur', r'\bdata\s*cent(er|re)\b',
        r'\bfacility\b.*\bsecur', r'\bserver\s*room',
        r'\bcctv\b', r'\bbiometric\b.*\baccess',
    ]),
    ("Pen Test / Security Assessment Access", [
        r'\bcustomer\s*(pen|security)\s*test', r'\ballow.*\bpen(etration)?\s*test',
        r'\bconduct.*\bsecurity\s*test', r'\bindependent\s*security',
    ]),
    ("API Security / Integration", [
        r'\bapi\s*secur', r'\bapi\s*authenticat', r'\brest\s*api\b',
        r'\bintegrat.*\bsecur', r'\boauth\b', r'\bapi\s*key',
        r'\bapi\s*gateway', r'\bwebhook',
    ]),
    ("Secure Development / SDLC", [
        r'\bsdlc\b', r'\bsecure\s*development', r'\bsecure\s*coding',
        r'\bcode\s*review', r'\bstatic\s*analysis', r'\bowas[p]\b',
        r'\bsecurity\s*in\s*development', r'\bdevops\b', r'\bdevsecops\b',
    ]),
    ("Data Classification", [
        r'\bdata\s*classif', r'\bclassif.*\b(protect|official|secret|sensitive)',
        r'\binformation\s*classif', r'\bsecurity\s*classif',
        r'\bprotected\b.*\bclassif', r'\bofficial\b.*\bsensitive',
    ]),
    ("Insurance / Liability / Indemnity", [
        r'\binsurance\b', r'\bliability\b', r'\bindemnit',
        r'\bcyber\s*insurance', r'\bprofessional\s*indemnity',
        r'\berrors\s*and\s*omissions',
    ]),
    ("Mobile Security", [
        r'\bmobile\s*secur', r'\bmobile\s*device\s*manage', r'\bmdm\b',
        r'\bbyod\b', r'\bmobile\s*app.*\bsecur',
    ]),
    ("Government Cloud / FedRAMP / Sovereign", [
        r'\bgovernment\s*cloud', r'\bgov\s*cloud', r'\bsovereign\s*cloud',
        r'\bfedramp\b', r'\bfed\s*ramp', r'\bil[2-6]\b',
        r'\bprotected\b.*\bcloud', r'\bgovcloud\b',
    ]),
    ("Contractual / Legal / Terms", [
        r'\bcontract(ual)?\s*(term|obligation|clause)',
        r'\blegal\b', r'\bterms\s*(of|and)\s*(service|use)',
        r'\bmaster\s*service\s*agreement', r'\bmsa\b',
        r'\blimit(ation)?\s*of\s*liabilit',
    ]),
    ("Training / Security Awareness", [
        r'\bsecurity\s*awareness', r'\bsecurity\s*training',
        r'\bstaff\s*training', r'\bemployee\s*training',
        r'\bsecurity\s*education',
    ]),
]


def load_questions(csv_path):
    """Load questions from CSV, return list of dicts."""
    rows = []
    with open(csv_path, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for row in reader:
            q = (row.get('Question') or '').strip()
            flag = (row.get('Flag') or '').strip().lower()
            keywords = (row.get('Keywords') or '').strip()
            answer = (row.get('Answer') or '').strip()
            if q:
                rows.append({
                    'question': q,
                    'flag': flag,
                    'keywords': keywords,
                    'answer': answer,
                })
    return rows


def classify_topics(rows):
    """Classify each row into topics. Returns topic_counts, topic_rows, unmatched."""
    topic_counts = Counter()
    topic_rows = defaultdict(list)
    unmatched = []

    for row in rows:
        q_lower = row['question'].lower()
        matched = False
        for label, patterns in TOPICS:
            for pat in patterns:
                if re.search(pat, q_lower):
                    topic_counts[label] += 1
                    topic_rows[label].append(row)
                    matched = True
                    break
            if matched:
                break  # first topic match wins for counting
        if not matched:
            unmatched.append(row)

    return topic_counts, topic_rows, unmatched


def extract_keyword_freq(rows):
    """Extract keyword column frequency."""
    kw_counts = Counter()
    for row in rows:
        kw = row['keywords'].strip()
        if kw:
            kw_counts[kw] += 1
    return kw_counts


def flag_distribution(rows):
    """Count flag types."""
    flag_counts = Counter()
    for row in rows:
        f = row['flag']
        if 'red' in f:
            flag_counts['Red'] += 1
        elif 'yellow' in f:
            flag_counts['Yellow'] += 1
        elif 'green' in f:
            flag_counts['Green'] += 1
        else:
            flag_counts['Other/Blank'] += 1
    return flag_counts


def find_multi_topic_rows(rows):
    """Find rows matching multiple topics — complex questions."""
    multi = []
    for row in rows:
        q_lower = row['question'].lower()
        matched_topics = []
        for label, patterns in TOPICS:
            for pat in patterns:
                if re.search(pat, q_lower):
                    matched_topics.append(label)
                    break
        if len(matched_topics) >= 3:
            multi.append((row, matched_topics))
    return multi


def analyze_unmatched_for_clusters(unmatched):
    """Simple bigram/trigram analysis on unmatched questions to find clusters."""
    stop_words = {
        'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
        'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
        'should', 'may', 'might', 'shall', 'can', 'must', 'to', 'of', 'in',
        'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through',
        'during', 'before', 'after', 'above', 'below', 'between', 'out',
        'and', 'but', 'or', 'nor', 'not', 'so', 'yet', 'both', 'either',
        'neither', 'each', 'every', 'all', 'any', 'few', 'more', 'most',
        'other', 'some', 'such', 'no', 'than', 'too', 'very', 'just',
        'about', 'up', 'its', 'it', 'this', 'that', 'these', 'those',
        'which', 'who', 'whom', 'what', 'when', 'where', 'why', 'how',
        'if', 'then', 'else', 'also', 'only', 'own', 'same', 'their',
        'them', 'they', 'we', 'our', 'you', 'your', 'he', 'she', 'his',
        'her', 'my', 'me', 'us', 'i', 'am', 'per', 'etc', 'ie', 'eg',
    }

    bigram_counts = Counter()
    for row in unmatched:
        words = re.findall(r'[a-z]+', row['question'].lower())
        words = [w for w in words if w not in stop_words and len(w) > 2]
        for i in range(len(words) - 1):
            bg = f"{words[i]} {words[i+1]}"
            bigram_counts[bg] += 1

    return bigram_counts.most_common(30)


def recommend_rules(topic_counts, topic_rows, flag_counts_by_topic):
    """Recommend top 10 new rules based on frequency and red/yellow density."""
    # Score: count * (red_pct + yellow_pct) — topics with most flags and volume
    scored = []
    for label, count in topic_counts.items():
        reds = flag_counts_by_topic[label].get('Red', 0)
        yellows = flag_counts_by_topic[label].get('Yellow', 0)
        flag_pct = (reds + yellows) / max(count, 1)
        score = count * flag_pct
        # Sample questions for this topic
        examples = []
        for r in topic_rows[label][:5]:
            q = r['question'][:120]
            examples.append(q)
        scored.append({
            'label': label,
            'count': count,
            'reds': reds,
            'yellows': yellows,
            'flag_pct': flag_pct,
            'score': score,
            'examples': examples,
        })
    scored.sort(key=lambda x: x['score'], reverse=True)
    return scored[:10]


def generate_report(rows, topic_counts, topic_rows, unmatched, flag_dist,
                    kw_freq, bigram_clusters, recommendations, multi_topic):
    """Generate markdown report."""
    lines = []
    lines.append("# AIRFX Needs-Review Analysis")
    lines.append(f"\n**Source:** `Red and Yellow flag kb - Best.csv`")
    lines.append(f"**Total rows analyzed:** {len(rows)}")
    lines.append(f"**Date:** 2026-03-07\n")

    # ── Flag distribution ───────────────────────────────
    lines.append("## Flag Distribution\n")
    lines.append("| Flag | Count | % |")
    lines.append("|------|------:|--:|")
    for flag, count in flag_dist.most_common():
        pct = count / len(rows) * 100
        lines.append(f"| {flag} | {count} | {pct:.1f}% |")
    lines.append("")

    # ── Top 20 question themes ──────────────────────────
    lines.append("## Top 20 Question Themes\n")
    lines.append("Rows are classified by first-match against 30 topic patterns applied to the Question column.\n")
    lines.append("| Rank | Theme | Count | % of Total | Red | Yellow |")
    lines.append("|-----:|-------|------:|-----------:|----:|-------:|")
    for i, (label, count) in enumerate(topic_counts.most_common(20), 1):
        pct = count / len(rows) * 100
        reds = sum(1 for r in topic_rows[label] if 'red' in r['flag'])
        yellows = sum(1 for r in topic_rows[label] if 'yellow' in r['flag'])
        lines.append(f"| {i} | {label} | {count} | {pct:.1f}% | {reds} | {yellows} |")

    classified = sum(topic_counts.values())
    lines.append(f"\n**Classified:** {classified} ({classified/len(rows)*100:.1f}%)")
    lines.append(f"**Unclassified:** {len(unmatched)} ({len(unmatched)/len(rows)*100:.1f}%)\n")

    # ── Unmatched clusters ──────────────────────────────
    lines.append("## Unclassified Question Clusters (Bigram Analysis)\n")
    lines.append("Top bigrams from questions that didn't match any topic pattern — potential new categories.\n")
    lines.append("| Bigram | Occurrences |")
    lines.append("|--------|------------:|")
    for bg, count in bigram_clusters[:20]:
        lines.append(f"| {bg} | {count} |")
    lines.append("")

    # ── Existing keyword column frequency ───────────────
    lines.append("## Existing Keywords Column (Top 25)\n")
    lines.append("Keywords already tagged in the source CSV — shows what the original authors flagged.\n")
    lines.append("| Keyword | Count |")
    lines.append("|---------|------:|")
    for kw, count in kw_freq.most_common(25):
        lines.append(f"| {kw} | {count} |")
    lines.append("")

    # ── Missing rule patterns ───────────────────────────
    lines.append("## Patterns Suggesting Missing Rules\n")
    lines.append("Topics with high Red/Yellow density but no corresponding AIRFX rule.\n")

    # Build flag breakdown per topic
    flag_by_topic = defaultdict(Counter)
    for label in topic_counts:
        for r in topic_rows[label]:
            if 'red' in r['flag']:
                flag_by_topic[label]['Red'] += 1
            elif 'yellow' in r['flag']:
                flag_by_topic[label]['Yellow'] += 1

    # Topics sorted by red+yellow count
    missing = []
    for label, count in topic_counts.items():
        reds = flag_by_topic[label].get('Red', 0)
        yellows = flag_by_topic[label].get('Yellow', 0)
        total_flagged = reds + yellows
        if total_flagged > 10:
            missing.append((label, count, reds, yellows, total_flagged))
    missing.sort(key=lambda x: x[4], reverse=True)

    lines.append("| Theme | Total Qs | Red | Yellow | Flag Rate |")
    lines.append("|-------|------:|----:|-------:|----------:|")
    for label, count, reds, yellows, total in missing:
        rate = total / count * 100
        lines.append(f"| {label} | {count} | {reds} | {yellows} | {rate:.0f}% |")
    lines.append("")

    # Example questions per top theme
    lines.append("### Sample Questions by High-Flag Theme\n")
    for label, count, reds, yellows, total in missing[:8]:
        lines.append(f"#### {label} ({total} flagged / {count} total)\n")
        shown = 0
        for r in topic_rows[label]:
            if 'red' in r['flag'] or 'yellow' in r['flag']:
                q = r['question'][:200].replace('\n', ' ')
                flag_label = 'RED' if 'red' in r['flag'] else 'YELLOW'
                lines.append(f"- [{flag_label}] {q}")
                shown += 1
                if shown >= 4:
                    break
        lines.append("")

    # ── Recommended next 10 rules ───────────────────────
    lines.append("## Recommended Next 10 Rules\n")
    lines.append("Ranked by (question volume × flag rate). These topics appear frequently and almost always get flagged, suggesting deterministic rules could handle them.\n")

    for i, rec in enumerate(recommendations, 1):
        lines.append(f"### {i}. {rec['label']}")
        lines.append(f"- **Volume:** {rec['count']} questions")
        lines.append(f"- **Red:** {rec['reds']} | **Yellow:** {rec['yellows']} | **Flag rate:** {rec['flag_pct']*100:.0f}%")
        lines.append(f"- **Rule type suggestion:**")

        # Suggest rule type based on topic
        label = rec['label']
        if label in ('Right to Audit',):
            lines.append(f"  `BINARY_CAN_DIFFERENTLY` — Salesforce provides SOC reports and third-party attestations but does not allow direct customer audits of infrastructure.")
        elif label in ('Accessibility / WCAG / Section 508',):
            lines.append(f"  `BINARY_CAN_DIFFERENTLY` — Salesforce provides a VPAT and works toward WCAG 2.1 AA but cannot guarantee full conformance across all features.")
        elif label in ('Personnel Security / Background Checks',):
            lines.append(f"  `BINARY_CAN_DIFFERENTLY` — Salesforce conducts background checks per local law but does not submit to customer-specific vetting processes.")
        elif label in ('Patch Management',):
            lines.append(f"  `BINARY_CAN_DIFFERENTLY` — Salesforce manages its own patching cadence aligned to industry standards but does not allow customer-directed patch timelines.")
        elif label in ('Network Security / Firewall',):
            lines.append(f"  `BINARY_CAN_DIFFERENTLY` — Salesforce uses Cloudflare WAF and custom controls but does not provide host-based or customer-managed firewalls.")
        elif label in ('Multi-Tenancy / Data Segregation',):
            lines.append(f"  `BINARY_CAN` — Salesforce provides logical tenant isolation in multi-tenant architecture with org-level data segregation.")
        elif label in ('Data Retention / Deletion / Disposal',):
            lines.append(f"  `BINARY_CAN_DIFFERENTLY` — Data deletion follows Salesforce retention policies; media sanitization per NIST 800-88 but no customer-witnessed destruction.")
        elif label in ('Physical Security / Data Center',):
            lines.append(f"  `BINARY_CAN` — AWS data centers provide SOC 2/ISO 27001 certified physical security controls.")
        elif label in ('SLA / Availability / Uptime',):
            lines.append(f"  `NUMERIC_TIERED_MIN` — Use existing 3-tier uptime rule (<99.7% GREEN, 99.7-99.9% YELLOW, >99.9% RED).")
        elif label in ('Incident Response / Breach Notification',):
            lines.append(f"  `BINARY_CAN_DIFFERENTLY` — Salesforce notifies affected customers of confirmed incidents but does not commit to specific SLA timelines for notification.")
        elif label in ('Compliance / Certifications',):
            lines.append(f"  `BINARY_CAN` for held certs (ISO 27001, SOC 2, FedRAMP). `BINARY_CANNOT` for certs not held. Individual rules per certification.")
        elif label in ('Data Privacy / GDPR / PII',):
            lines.append(f"  `BINARY_CAN` — Salesforce provides DPA, is GDPR-compliant, supports data subject access requests via platform tools.")
        elif label in ('Sub-Processors / Third Parties',):
            lines.append(f"  `BINARY_CAN` — Salesforce publishes sub-processor list (AWS, Cloudflare, WithSecure). Customer notification before changes.")
        elif label in ('Encryption',):
            lines.append(f"  `BINARY_CAN` — AES-256 at rest, TLS 1.2+ in transit. `BINARY_CAN_DIFFERENTLY` for FIPS 140-2 (Shield only) and BYOK.")
        elif label in ('Access Control / Authentication',):
            lines.append(f"  `BINARY_CAN` — SSO, SAML, MFA, RBAC all natively supported. Individual rules for specific mechanisms.")
        elif label in ('Business Continuity / Disaster Recovery',):
            lines.append(f"  `NUMERIC_MIN` for RPO/RTO (existing). `BINARY_CAN_DIFFERENTLY` for customer-approved BCP plans.")
        elif label in ('Audit / Logging',):
            lines.append(f"  `BINARY_CAN` — Setup Audit Trail, Login History, Field History Tracking. `BINARY_CAN_DIFFERENTLY` for infrastructure-level logs (not provided).")
        else:
            lines.append(f"  Needs analysis — review sample questions to determine appropriate rule type.")

        lines.append(f"- **Sample questions:**")
        for ex in rec['examples'][:3]:
            lines.append(f"  - _{ex.replace(chr(10), ' ')}_")
        lines.append("")

    # ── Multi-topic complex questions ───────────────────
    lines.append("## Complex Multi-Topic Questions (3+ themes)\n")
    lines.append(f"Found {len(multi_topic)} questions spanning 3+ security topics. These are typically the hardest for deterministic rules and may need RAG answers.\n")
    for row, topics in multi_topic[:15]:
        q = row['question'][:150].replace('\n', ' ')
        flag_label = 'RED' if 'red' in row['flag'] else ('YELLOW' if 'yellow' in row['flag'] else 'GREEN')
        lines.append(f"- [{flag_label}] Topics: {', '.join(topics)}")
        lines.append(f"  _{q}_")
    lines.append("")

    # ── Summary ─────────────────────────────────────────
    lines.append("## Summary & Next Steps\n")
    lines.append(f"1. **{classified} of {len(rows)}** questions ({classified/len(rows)*100:.0f}%) map to {len(topic_counts)} security themes.")
    lines.append(f"2. **{len(unmatched)}** questions ({len(unmatched)/len(rows)*100:.0f}%) are unclassified — mostly functional/product questions, not security.")
    top3 = topic_counts.most_common(3)
    lines.append(f"3. Top 3 themes: **{top3[0][0]}** ({top3[0][1]}), **{top3[1][0]}** ({top3[1][1]}), **{top3[2][0]}** ({top3[2][1]}).")
    lines.append(f"4. The recommended 10 rules would cover the highest-volume, highest-flag-rate topics.")
    lines.append(f"5. Multi-topic questions ({len(multi_topic)}) are best served by RAG, not deterministic rules.")
    lines.append(f"6. Consider adding `BINARY_CAN_DIFFERENTLY` rules first — they cover the most common pattern: 'we do this, but not exactly how you asked.'\n")

    return '\n'.join(lines)


def main():
    print(f"Loading {CSV_PATH}...")
    rows = load_questions(CSV_PATH)
    print(f"Loaded {len(rows)} rows with questions.")

    print("Classifying topics...")
    topic_counts, topic_rows, unmatched = classify_topics(rows)

    print("Computing flag distribution...")
    flag_dist = flag_distribution(rows)

    print("Extracting keyword frequencies...")
    kw_freq = extract_keyword_freq(rows)

    print("Analyzing unmatched clusters...")
    bigram_clusters = analyze_unmatched_for_clusters(unmatched)

    print("Finding multi-topic questions...")
    multi_topic = find_multi_topic_rows(rows)

    print("Generating rule recommendations...")
    flag_by_topic = defaultdict(lambda: defaultdict(int))
    for label in topic_counts:
        for r in topic_rows[label]:
            if 'red' in r['flag']:
                flag_by_topic[label]['Red'] += 1
            elif 'yellow' in r['flag']:
                flag_by_topic[label]['Yellow'] += 1
    recommendations = recommend_rules(topic_counts, topic_rows, flag_by_topic)

    print("Writing report...")
    report = generate_report(rows, topic_counts, topic_rows, unmatched,
                             flag_dist, kw_freq, bigram_clusters,
                             recommendations, multi_topic)

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(report, encoding='utf-8')
    print(f"Report written to {OUT_PATH}")
    print(f"\nQuick stats:")
    print(f"  Total rows: {len(rows)}")
    print(f"  Classified: {sum(topic_counts.values())}")
    print(f"  Unclassified: {len(unmatched)}")
    print(f"  Topics found: {len(topic_counts)}")
    print(f"  Multi-topic questions: {len(multi_topic)}")


if __name__ == '__main__':
    main()
