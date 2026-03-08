# Excluded Rows — Mike Rosa Flagged

**Date:** 2026-03-08
**Source:** Mike Rosa validation (report1772735470744)
**Verified:** Not present in `docs/safe_to_ingest.csv`

## Wrong Answers (4)

| GPS Name | Question | Flag | Reason for Exclusion |
|----------|----------|------|---------------------|
| GPS-4393 | Permission for photos | Yellow | Mike: "Wrong!" — functional question, not security. Engine answer misclassified. |
| GPS-4426 | Have you prior experience of working for Law Enforcement agencies? | Yellow | Mike: "Wrong!" — functional/experience question, not security. |
| GPS-4427 | What is the name and version of the software you are proposing? | Yellow | Mike: "Wrong!" — product info question, not security. |
| GPS-4435 | How is your solution deployed; on-premise, cloud based, etc.? | Green | Mike: "Wrong!" — flag is correct (Green) but answer content needs review. |

## Missing Context (2)

| GPS Name | Question | Flag | Reason for Exclusion |
|----------|----------|------|---------------------|
| GPS-0139 | What are the standard response and recovery times in the event of system disruption? | Yellow | Mike: "Answered with support response times. Missing context." — answer conflates support SLA with DR RTO/RPO. |
| GPS-0221 | Describe all features that your Solution offers to meet the business requirements. | Yellow | Mike: "Missing context." — answer lacks product-specific detail for the deal. |

## Verification

All 6 rows confirmed absent from `docs/safe_to_ingest.csv` (3,534 rows).
These questions are excluded from the agent ingestion pipeline.
