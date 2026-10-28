"""Reads Lighthouse reports and fails when a page is outside its budget.

Usage:
    python3 tool/lighthouse_budget.py <page> <report.json>...

The budget is the one the plan records, and each number has a reason:

    performance        >= 95    the category a reader and a search engine both feel
    LCP                 <= 2.0s the largest thing on screen arriving late is what a canvas
                                page loses on, and this page has no canvas until somebody
                                asks for the application
    CLS                 <= 0.02 the page must not move under the reader: a document that
                                shifts is the failure the parity work exists to prevent
    total blocking time <= 50ms nothing in a document runs for long, because nothing in a
                                document runs at all until the boot script is asked for

Several reports of one page are read as a median, because a single run on a busy machine
says as much about the machine as about the page.

What this does *not* measure, deliberately: the application. Lighthouse never clicks, so it
scores the document and stops. The cost a reader pays for the handover is a second number and
it needs a built application; see `tool/lighthouse.sh`.
"""

import glob
import json
import statistics
import sys

BUDGET = {
    "performance": 95,
    "largest-contentful-paint": 2000,
    "cumulative-layout-shift": 0.02,
    "total-blocking-time": 50,
}


def measure(path):
    """The metrics one report holds."""
    report = json.load(open(path))
    measured = {"performance": report["categories"]["performance"]["score"] * 100}

    for audit in BUDGET:
        if audit != "performance":
            measured[audit] = report["audits"][audit]["numericValue"]

    return measured


def main():
    page, reports = sys.argv[1], sys.argv[2:]
    runs = [measure(path) for path in reports]
    median = {name: statistics.median([run[name] for run in runs]) for name in BUDGET}
    failures = []

    print(f"  {len(runs)} run(s), median")

    for audit, limit in BUDGET.items():
        actual = median[audit]
        inside = actual >= limit if audit == "performance" else actual <= limit
        print(f"  {'ok  ' if inside else 'FAIL'} {audit}: {actual:.2f} (budget {limit})")

        if not inside:
            failures.append(audit)

    if failures:
        print(f"\n{page}: {', '.join(failures)} outside the budget", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
