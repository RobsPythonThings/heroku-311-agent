#!/usr/bin/env python3
"""
AIRFX CSV Validation Script
Reads rfp_history_clean.csv, sends questions through AIRFX engine via anonymous Apex,
compares engine flags against original flags, and generates validation reports.
"""

import csv
import subprocess
import json
import os
import re
import sys
import time

CSV_PATH = "/Users/rsmith2/Desktop/Agentic Utopia/utopia-project/utopia-rfp-resolver/rfp_history_clean.csv"
DOCS_DIR = "/Users/rsmith2/utopia-project/docs"
BATCH_SIZE = 25  # questions per anonymous Apex invocation (Apex anonymous script size limit)
ORG_ALIAS = "utopia-uat"

def escape_apex_string(s):
    """Escape a string for use in an Apex single-quoted string literal."""
    if s is None:
        return ''
    # Remove any control characters and non-ASCII
    s = re.sub(r'[\x00-\x1f\x7f]', ' ', s)
    # Replace non-ASCII with space (Apex string literal safety)
    s = s.encode('ascii', errors='replace').decode('ascii')
    # Escape backslashes first, then single quotes
    s = s.replace('\\', '\\\\')
    s = s.replace("'", "\\'")
    return s

def parse_csv():
    """Read CSV and return list of (row_index, question, original_flag)."""
    rows = []
    with open(CSV_PATH, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            question = row.get('Question', '').strip()
            flag_raw = row.get('Flag', '').strip()
            # Map original flags
            if flag_raw == '#redflag':
                orig_flag = 'RED'
            elif flag_raw == '#yellowflag':
                orig_flag = 'YELLOW'
            else:
                orig_flag = 'NONE'
            if question:  # skip empty questions
                rows.append((i + 1, question, orig_flag))
    return rows

def build_apex_script(questions_batch):
    """Generate anonymous Apex that calls validateQuestions and prints results."""
    lines = ["List<String> qs = new List<String>();"]
    for q in questions_batch:
        escaped = escape_apex_string(q)
        # Truncate very long questions to avoid Apex script size limit
        if len(escaped) > 500:
            escaped = escaped[:500]
        lines.append(f"qs.add('{escaped}');")
    lines.append("List<String> results = AIRFX_ResponseFlagInvocable.validateQuestions(qs);")
    lines.append("for (Integer i = 0; i < results.size(); i++) {")
    lines.append("    System.debug('VRESULT|' + i + '|' + results[i]);")
    lines.append("}")
    return '\n'.join(lines)

def run_apex(script):
    """Execute anonymous Apex and return debug log output."""
    # Write script to temp file
    tmp_path = '/tmp/airfx_validation_batch.apex'
    with open(tmp_path, 'w') as f:
        f.write(script)

    result = subprocess.run(
        ['sf', 'apex', 'run', '--file', tmp_path, '-o', ORG_ALIAS],
        capture_output=True, text=True, timeout=120
    )

    output = result.stdout + result.stderr
    return output

def parse_results(output, batch_size):
    """Parse VRESULT lines from Apex debug output."""
    # Decode HTML entities (sf CLI encodes | as &#124;)
    output = output.replace('&#124;', '|')
    results = {}
    for line in output.split('\n'):
        if 'VRESULT|' in line:
            # Extract the VRESULT part
            match = re.search(r'VRESULT\|(\d+)\|(.+)', line)
            if match:
                idx = int(match.group(1))
                parts = match.group(2).split('||', 2)
                if len(parts) == 3:
                    results[idx] = {
                        'flag': parts[0].strip(),
                        'ruleId': parts[1].strip(),
                        'reason': parts[2].strip()
                    }
    return results

def classify_comparison(orig_flag, engine_flag):
    """Classify the comparison between original and engine flags."""
    if orig_flag == 'RED' and engine_flag == 'Red':
        return 'MATCH'
    elif orig_flag == 'YELLOW' and engine_flag == 'Yellow':
        return 'MATCH'
    elif orig_flag == 'NONE' and engine_flag == 'Green':
        return 'NEW_GREEN'
    elif orig_flag == 'RED' and engine_flag in ('Yellow', 'Green'):
        return 'DOWNGRADE'
    elif orig_flag == 'NONE' and engine_flag == 'Red':
        return 'UPGRADE'
    elif orig_flag == 'NONE' and engine_flag == 'Yellow':
        return 'NEW_YELLOW'
    elif orig_flag == 'YELLOW' and engine_flag == 'Red':
        return 'UPGRADE'
    elif orig_flag == 'YELLOW' and engine_flag == 'Green':
        return 'DOWNGRADE'
    elif orig_flag == 'RED' and engine_flag == 'Red':
        return 'MATCH'
    else:
        # Partial match or other
        return 'MISMATCH'

def main():
    print("=== AIRFX CSV Validation ===")
    print(f"Reading CSV: {CSV_PATH}")

    rows = parse_csv()
    total = len(rows)
    print(f"Total questions: {total}")

    # Process in batches
    all_results = []  # list of (row_idx, question, orig_flag, engine_flag, engine_ruleId, engine_reason, category)

    batch_count = (total + BATCH_SIZE - 1) // BATCH_SIZE
    failed_batches = 0

    for batch_num in range(batch_count):
        start = batch_num * BATCH_SIZE
        end = min(start + BATCH_SIZE, total)
        batch_rows = rows[start:end]
        batch_questions = [r[1] for r in batch_rows]

        print(f"\nBatch {batch_num + 1}/{batch_count} (rows {start+1}-{end})...", end=' ', flush=True)

        script = build_apex_script(batch_questions)
        output = run_apex(script)

        # Decode HTML entities for error checking too
        output_decoded = output.replace('&#124;', '|')

        # Check for compilation/runtime errors
        if ('Compilation failed' in output or 'Script too large' in output or
            ('EXCEPTION' in output and 'VRESULT' not in output_decoded)):
            print(f"ERROR - batch failed")
            failed_batches += 1
            # Mark all rows in this batch as ERROR
            for i, (row_idx, question, orig_flag) in enumerate(batch_rows):
                all_results.append((row_idx, question, orig_flag, 'ERROR', '', 'Batch execution failed', 'ERROR'))
            continue

        results = parse_results(output, len(batch_questions))

        parsed_count = len(results)
        print(f"OK ({parsed_count}/{len(batch_questions)} parsed)")

        for i, (row_idx, question, orig_flag) in enumerate(batch_rows):
            if i in results:
                r = results[i]
                category = classify_comparison(orig_flag, r['flag'])
                all_results.append((row_idx, question, orig_flag, r['flag'], r['ruleId'], r['reason'], category))
            else:
                all_results.append((row_idx, question, orig_flag, 'PARSE_FAIL', '', 'Result not captured', 'ERROR'))

        # Small delay to avoid API throttling
        if batch_num < batch_count - 1:
            time.sleep(1)

    # Generate output files
    os.makedirs(DOCS_DIR, exist_ok=True)

    # Matches
    matches = [r for r in all_results if r[6] == 'MATCH']
    with open(os.path.join(DOCS_DIR, 'validation_matches.csv'), 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Row', 'Question', 'Original_Flag', 'Engine_Flag', 'Rule_ID', 'Reason'])
        for r in matches:
            writer.writerow([r[0], r[1][:200], r[2], r[3], r[4], r[5][:200]])

    # Discrepancies
    discrepancies = [r for r in all_results if r[6] not in ('MATCH',)]
    with open(os.path.join(DOCS_DIR, 'validation_discrepancies.csv'), 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Row', 'Question', 'Original_Flag', 'Engine_Flag', 'Rule_ID', 'Reason', 'Category'])
        for r in discrepancies:
            writer.writerow([r[0], r[1][:200], r[2], r[3], r[4], r[5][:200], r[6]])

    # Summary report
    categories = {}
    for r in all_results:
        cat = r[6]
        categories[cat] = categories.get(cat, 0) + 1

    engine_flags = {}
    for r in all_results:
        ef = r[3]
        engine_flags[ef] = engine_flags.get(ef, 0) + 1

    orig_flags = {}
    for r in all_results:
        of = r[2]
        orig_flags[of] = orig_flags.get(of, 0) + 1

    # Rule ID distribution for discrepancies
    rule_dist = {}
    for r in discrepancies:
        rid = r[4] if r[4] else 'N/A'
        rule_dist[rid] = rule_dist.get(rid, 0) + 1

    with open(os.path.join(DOCS_DIR, 'validation_report.txt'), 'w') as f:
        f.write("AIRFX CSV Validation Report\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Source: rfp_history_clean.csv\n")
        f.write(f"Total questions processed: {total}\n")
        f.write(f"Batches: {batch_count} (batch size: {BATCH_SIZE})\n")
        f.write(f"Failed batches: {failed_batches}\n\n")

        f.write("Original Flag Distribution:\n")
        for k in sorted(orig_flags.keys()):
            f.write(f"  {k}: {orig_flags[k]}\n")

        f.write("\nEngine Flag Distribution:\n")
        for k in sorted(engine_flags.keys()):
            f.write(f"  {k}: {engine_flags[k]}\n")

        f.write("\nComparison Categories:\n")
        for k in sorted(categories.keys()):
            f.write(f"  {k}: {categories[k]}\n")

        f.write(f"\nTotal Matches: {categories.get('MATCH', 0)} ({100*categories.get('MATCH', 0)/total:.1f}%)\n")
        f.write(f"Total Discrepancies: {len(discrepancies)} ({100*len(discrepancies)/total:.1f}%)\n")

        f.write("\nDiscrepancy Rule ID Distribution (top 20):\n")
        for rid, count in sorted(rule_dist.items(), key=lambda x: -x[1])[:20]:
            f.write(f"  {rid}: {count}\n")

        f.write("\n" + "=" * 50 + "\n")
        f.write("Generated by AIRFX CSV Validation Script\n")

    print(f"\n=== Validation Complete ===")
    print(f"Total: {total}")
    print(f"Matches: {categories.get('MATCH', 0)}")
    print(f"Discrepancies: {len(discrepancies)}")
    print(f"Files written to {DOCS_DIR}/")
    for k in sorted(categories.keys()):
        print(f"  {k}: {categories[k]}")

if __name__ == '__main__':
    main()
