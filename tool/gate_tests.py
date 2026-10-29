"""Tests the gates.

Every other script in `tool/` asks a question about the repository, and it is the thing standing
between a bug and a deploy — a checker that silently stops checking is worse than no checker, because
the green tick is a lie. So each one is handed the case it exists to refuse and the case it must accept.

Usage:
    python3 tool/gate_tests.py

No browser, no build, no network: fixtures are written into a temporary directory.
"""

import gzip
import json
import os
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import doc_check
import lighthouse_budget
import performance_report
import scale_check
import surface_check

PASSED = []
FAILED = []


def check(name, condition, detail=''):
    if condition:
        PASSED.append(name)
    else:
        FAILED.append(name if not detail else f'{name} — {detail}')


def document(body, scripts=()):
    tags = ''.join(f'<script src="{src}"></script>' for src in scripts)

    return (
        '<!DOCTYPE html><html lang="en"><head><title>t</title></head><body>'
        f'{body}<h1>Title</h1>' + '<a href="/x">x</a>' * 4 + body + tags + '</body></html>'
    )


def test_doc_check():
    """The one thing it caught in the real build: a document naming a file that is not there."""
    with tempfile.TemporaryDirectory() as site:
        words = ' '.join(['word'] * 400)
        open(os.path.join(site, 'index.html'), 'w').write(
            document(f'<p>{words}</p>', scripts=('main.js',))
        )
        open(os.path.join(site, 'main.js'), 'w').write('// present')
        open(os.path.join(site, 'robots.txt'), 'w').write('User-agent: *\n')

        original = doc_check.DOCUMENTS
        doc_check.DOCUMENTS = {'index.html': {'words': 100, 'h1': 1, 'links': 1}}

        try:
            # A page whose every file exists, and which says enough, passes.
            problems = doc_check.check('index.html', os.path.join(site, 'index.html'),
                                       doc_check.DOCUMENTS['index.html'])
            check('doc_check accepts a document whose files exist', problems == [], str(problems))

            # The failure it was written for: a relative path that resolves to nothing.
            html = open(os.path.join(site, 'index.html')).read().replace('main.js', 'web/main.js')
            open(os.path.join(site, 'index.html'), 'w').write(html)
            problems = doc_check.check('index.html', os.path.join(site, 'index.html'),
                                       doc_check.DOCUMENTS['index.html'])
            check('doc_check refuses a script that is not in the build',
                  any('web/main.js' in problem for problem in problems), str(problems))

            # And the other: a page that lost most of its text.
            open(os.path.join(site, 'index.html'), 'w').write('<html><body><h1>Title</h1></body></html>')
            problems = doc_check.check('index.html', os.path.join(site, 'index.html'),
                                       doc_check.DOCUMENTS['index.html'])
            check('doc_check refuses a document below its word floor',
                  any('words' in problem for problem in problems), str(problems))
        finally:
            doc_check.DOCUMENTS = original


def report(performance, fcp, lcp, tbt, cls):
    return {
        'categories': {'performance': {'score': performance / 100}},
        'audits': {
            'first-contentful-paint': {'numericValue': fcp},
            'largest-contentful-paint': {'numericValue': lcp},
            'total-blocking-time': {'numericValue': tbt},
            'cumulative-layout-shift': {'numericValue': cls},
        },
    }


def test_lighthouse_budget():
    """Two runs are a median, and the median is what the budget is compared with."""
    with tempfile.TemporaryDirectory() as work:
        paths = []

        # One fast run and one that is over the line: the median of two is their mean, which is inside.
        for index, (score, lcp) in enumerate(((100, 1000), (60, 5000))):
            path = os.path.join(work, f'web-listings@document-{index + 1}.json')
            json.dump(report(score, 900, lcp, 10, 0), open(path, 'w'))
            paths.append(path)

        measured = lighthouse_budget.measure(paths[0])
        check('lighthouse_budget reads a report', measured['performance'] == 100, str(measured))

        failures, _ = lighthouse_budget.evaluate(
            'document', [measured, lighthouse_budget.measure(paths[1])]
        )
        check(
            'lighthouse_budget fails a page whose median is outside',
            'performance' in failures,
            str(failures),
        )

        failures, _ = lighthouse_budget.evaluate('document', [measured])
        check(
            'lighthouse_budget passes a page inside its budget', failures == [], str(failures)
        )


def test_performance_report():
    """The baseline is a direction, not a line: it names what got worse and stays quiet otherwise."""
    with tempfile.TemporaryDirectory() as work:
        reports = os.path.join(work, 'reports')
        site = os.path.join(work, 'site')
        os.makedirs(reports)
        os.makedirs(os.path.join(site, 'web/listings'))
        open(os.path.join(site, 'web/listings/index.html'), 'w').write('x' * 1000)

        json.dump(report(90, 900, 2000, 10, 0),
                  open(os.path.join(reports, 'web-listings@document-1.json'), 'w'))

        pages = performance_report.read(reports)
        check('performance_report reads the pages it is given',
              'web-listings' in pages, str(list(pages)))

        sizes = performance_report.sizes(site)
        check('performance_report measures the bytes, gzipped',
              sizes['document'] == len(gzip.compress(b'x' * 1000, 6)), str(sizes))


def test_surface_check():
    """The rule a reviewer remembers and an assistant does not: a token with no case is not finished."""
    with tempfile.TemporaryDirectory() as work:

        def write(relative, body):
            path = os.path.join(work, relative)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'w').write(body)

        write('packages/unibox_core/lib/src/tokens/box_style.dart',
              'class BoxStyle {\n  final double? gap;\n  final double? wiggle;\n}\n')
        write('packages/unibox_testing/lib/src/appearance.dart',
              'class BoxAppearance {\n  final double? gap;\n}\n')
        write('packages/unibox_core/lib/src/tokens/box_text_style.dart',
              'class BoxTextStyle {\n  final double? fontSize;\n}\n')
        write('packages/unibox_testing/lib/src/text_appearance.dart',
              'class TextAppearance {\n  final double? fontSize;\n}\n')
        write('packages/unibox_core/lib/src/nodes/box.dart',
              'class Box {\n  final TapCallback? onTap;\n}\n')
        write('packages/unibox_flutter/lib/src/box.dart', 'void build() => box.onTap?.call();\n')
        write('packages/unibox_dom/lib/src/events.dart', 'void bind() => box.onTap?.call();\n')

        refused = surface_check.findings(work)
        check('surface_check refuses a token nobody classified',
              any('wiggle' in problem for problem in refused), str(refused))
        check('surface_check accepts a token the table carries',
              not any('`gap`' in problem for problem in refused), str(refused))
        check('surface_check accepts a callback both targets reach',
              not any('onTap' in problem for problem in refused), str(refused))

        # The bug it exists for: `Box.onHover` was declared, used by a component, and bound by
        # nothing for a day, with every suite green.
        write('packages/unibox_dom/lib/src/events.dart', '// nothing is bound here\n')
        unbound = surface_check.findings(work)
        check('surface_check refuses a callback the web never binds',
              any('onTap' in problem for problem in unbound), str(unbound))

        # A reason written down once is what the red asks for, and it is what the map is for.
        surface_check.CLASSIFIED['BoxStyle']['wiggle'] = 'a fixture, not a real token'
        try:
            classified = surface_check.findings(work)
            check('surface_check accepts the same token once it has a reason',
                  not any('wiggle' in problem for problem in classified), str(classified))
        finally:
            del surface_check.CLASSIFIED['BoxStyle']['wiggle']

        # And a reason that outlives its token is the same lie in the other direction.
        surface_check.CLASSIFIED['BoxStyle']['departed'] = 'a token that is not in the file'
        try:
            stale = surface_check.findings(work)
            check('surface_check refuses a reason for a token that is gone',
                  any('departed' in problem for problem in stale), str(stale))
        finally:
            del surface_check.CLASSIFIED['BoxStyle']['departed']
def test_scale_check():
    """A shape that stops being linear is refused, and a shape that is linear is not."""
    baseline = {
        'shapes': {
            'a-shape': {
                'small': {'nodes': 100, 'classes': 2, 'html_bytes': 10, 'css_bytes': 4,
                          'plan_ms': 1.0, 'css_ms': 0.5, 'write_ms': 1.0},
                'large': {'nodes': 200, 'classes': 2, 'html_bytes': 20, 'css_bytes': 4,
                          'plan_ms': 2.0, 'css_ms': 1.0, 'write_ms': 2.0},
            },
        },
    }

    def measured(plan_small, plan_large, **changes):
        small = dict(baseline['shapes']['a-shape']['small'], plan_ms=plan_small)
        large = dict(baseline['shapes']['a-shape']['large'], plan_ms=plan_large)

        for name, value in changes.items():
            small[name] = value

        return {'shapes': {'a-shape': {'small': small, 'large': large}}}

    check('scale_check accepts a linear stage',
          scale_check.judge(measured(1.0, 2.0), baseline) == [],
          str(scale_check.judge(measured(1.0, 2.0), baseline)))

    # The failure it was written for: doubling the tree quadrupled the work.
    problems = scale_check.judge(measured(4.0, 16.0), baseline)
    check('scale_check refuses a stage that goes quadratic',
          any('not linear' in problem for problem in problems), str(problems))

    # A ratio measured on a stage too small to time is noise, not a regression.
    check('scale_check ignores a ratio below its floor',
          scale_check.judge(measured(0.1, 0.5), baseline) == [],
          str(scale_check.judge(measured(0.1, 0.5), baseline)))

    # The exact facts are a function of the tree, so they are compared exactly.
    problems = scale_check.judge(measured(1.0, 2.0, classes=3), baseline)
    check('scale_check refuses a class count that moved',
          any('classes' in problem for problem in problems), str(problems))

    # And a stage that got uniformly slower, which no ratio can see.
    problems = scale_check.judge(measured(50.0, 60.0), baseline)
    check('scale_check refuses a stage far above the baseline',
          any('the baseline' in problem for problem in problems), str(problems))

    # A shape the benchmark stopped measuring is a hole in the guard, not a pass.
    problems = scale_check.judge({'shapes': {}}, baseline)
    check('scale_check refuses a report that lost a shape',
          any('no longer measures' in problem for problem in problems), str(problems))


def main():
    test_doc_check()
    test_lighthouse_budget()
    test_performance_report()
    test_scale_check()
    test_surface_check()

    for name in PASSED:
        print(f'  ok   {name}')

    for name in FAILED:
        print(f'  FAIL {name}')

    if FAILED:
        print(f'\n==> FAILED: {len(FAILED)} gate test(s)', file=sys.stderr)

        return 1

    print(f'\n==> The gates refuse what they are for, and accept what they should.')

    return 0


if __name__ == '__main__':
    sys.exit(main())
