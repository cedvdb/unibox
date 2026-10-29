"""Reads the reports `tool/performance.sh` collected, and compares them with the baseline.

Usage:
    python3 tool/performance_report.py <site-dir> <reports-dir> [--update]

The baseline is `tool/performance_baseline.json`, committed: it is the last set of numbers somebody
looked at and accepted. A budget answers "is this inside the line"; the baseline answers "is this worse
than it was", which is the question a Flutter or SDK upgrade raises. Numbers that drift while staying
inside the budget are the ones nobody notices without it.
"""

import glob
import gzip
import json
import os
import statistics
import sys

BASELINE = 'tool/performance_baseline.json'

# What a report is read for, and whether more is better.
METRICS = {
    'performance': True,
    'first-contentful-paint': False,
    'largest-contentful-paint': False,
    'total-blocking-time': False,
    'cumulative-layout-shift': False,
}


def read(reports):
    """The median of every metric, per page, from the reports one measurement produced."""
    pages = {}

    # The names `tool/lighthouse.sh` writes: the path with its slashes hyphenated, then the kind
    # of promise it makes. The front page is the one with no path, so its marker comes first.
    for page in ('web-listings@document', '@application'):
        runs = []

        for path in sorted(glob.glob(os.path.join(reports, f'{page}*.json'))):
            report = json.load(open(path))
            score = report['categories']['performance']['score']

            if score is None:
                continue

            measured = {'performance': round(score * 100, 1)}

            for audit in METRICS:
                if audit != 'performance':
                    measured[audit] = round(report['audits'][audit]['numericValue'], 1)

            runs.append(measured)

        if runs:
            pages[page.split('@')[0] or 'front'] = {name: statistics.median([run[name] for run in runs]) for name in METRICS}

    return pages


def sizes(site):
    """The bytes each part of the build costs, gzipped as a host would send it."""
    def gzipped(path):
        if not os.path.isfile(path):
            return 0
        return len(gzip.compress(open(path, 'rb').read(), 6))

    fonts = glob.glob(os.path.join(site, 'assets/fonts/*.woff2'))
    photos = glob.glob(os.path.join(site, 'assets/photos/*.jpg'))

    return {
        'document': gzipped(os.path.join(site, 'web/listings/index.html')),
        'client': gzipped(os.path.join(site, 'web/main.client.js')),
        'fonts': sum(gzipped(path) for path in fonts),
        'photos': sum(gzipped(path) for path in photos),
    }


def main():
    site, reports = sys.argv[1], sys.argv[2]
    update = '--update' in sys.argv
    measured = {'pages': read(reports), 'sizes': sizes(site)}

    baseline = {}
    if os.path.isfile(BASELINE):
        baseline = json.load(open(BASELINE))

    print('\n  %-42s %12s %12s' % ('', 'measured', 'baseline'))

    for page, metrics in measured['pages'].items():
        for name, value in metrics.items():
            was = baseline.get('pages', {}).get(page, {}).get(name)
            print('  %-42s %12s %12s' % (f'{page} {name}', value, '—' if was is None else was))

    for name, value in measured['sizes'].items():
        was = baseline.get('sizes', {}).get(name)
        print('  %-42s %12s %12s' % (f'bytes {name}', value, '—' if was is None else was))

    if update:
        json.dump(measured, open(BASELINE, 'w'), indent=2, sort_keys=True)
        print(f'\n  baseline written to {BASELINE}')
        return 0

    if not baseline:
        print(f'\n  no baseline yet: run with --update to accept these numbers')
        return 0

    # A budget is a line; this is a direction. Anything worse than the baseline by more than a tenth
    # is reported, and nothing fails a build on a machine that is not the one the baseline was taken on.
    worse = []

    for page, metrics in measured['pages'].items():
        for name, value in metrics.items():
            was = baseline.get('pages', {}).get(page, {}).get(name)

            if was is None or was == 0:
                continue

            better_when_higher = METRICS[name]
            change = (value - was) / was if better_when_higher else (was - value) / was

            if change < -0.1:
                worse.append(f'{page} {name}: {was} -> {value}')

    if worse:
        print('\n  worse than the baseline:')

        for line in worse:
            print(f'    {line}')

    return 0


if __name__ == '__main__':
    sys.exit(main())
