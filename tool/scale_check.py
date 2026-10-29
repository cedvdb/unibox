#!/usr/bin/env python3
"""Hold the scale benchmark to its baseline.

Usage:
  python3 tool/scale_check.py build/scale.json             compare, and print the table
  python3 tool/scale_check.py build/scale.json --update    accept it as the baseline

`packages/unibox_html/tool/bench.dart` measures three shapes of tree at two sizes and
writes the report as JSON; `tool/scale.sh` drives both. This file is the judgement, and it
is separate from the measurement so that it can be tested without a build: see
`tool/gate_tests.py`.

Three questions, and the reason each is asked in the currency it is asked in:

  * the exact facts -- class count and byte count -- are equal to the baseline. They are a
    function of the tree and of nothing else, so a change in either is a change in what the
    renderer produces, and that is a decision, not a measurement;
  * the shape -- doubling the tree must at most double and a bit the work. A ratio measured
    in one run on one machine is worth more than an absolute time across machines, and it is
    the question a quadratic stage answers wrongly: it quadruples;
  * the absolute cost, against the baseline, loosely. It catches a stage that got uniformly
    slower, which no ratio can see, and it is the one number a baseline carries that says
    more about the machine than about the code.
"""

import json
import os
import sys

BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'scale_baseline.json')

# What a stage may cost when the tree doubles. Linear work doubles; a stage that has a
# term quadratic in the node count quadruples. The line sits between the two with room for
# a stopping-the-world pause, and it is the check a regression has to fail loudly.
RATIO_LIMIT = 2.6

# A ratio below this is timer noise rather than a measurement: a stage that takes 0.2ms and
# then 0.3ms is not 50% worse, it is unmeasurable at this size.
RATIO_FLOOR_MS = 1.0

# What a measurement may cost against the baseline, and the floor that keeps a stage too
# small to time from failing on rounding.
ABSOLUTE_FACTOR = 4.0
ABSOLUTE_FLOOR_MS = 2.0

# The stages, in the order the table prints them, and the fields that have to match exactly.
STAGES = ('plan_ms', 'css_ms', 'write_ms')
EXACT = ('classes', 'html_bytes', 'css_bytes')

SIZES = ('small', 'large')

SHAPE_WIDTH = 16


def load(path):
    with open(path, encoding='utf-8') as handle:
        return json.load(handle)


def judge(report, baseline):
    """Every way `report` disagrees with `baseline`, as sentences. Empty means it agrees."""
    problems = []
    measured = report.get('shapes', {})
    expected = baseline.get('shapes', {})

    for shape, sizes in expected.items():
        if shape not in measured:
            problems.append(f'{shape}: the benchmark no longer measures it')
            continue

        for size in SIZES:
            if size not in measured[shape]:
                problems.append(f'{shape}: no {size} measurement')
                continue

            row = measured[shape][size]
            want = sizes[size]

            for field in EXACT:
                if row.get(field) != want.get(field):
                    problems.append(
                        f'{shape} ({size}): {field} is {row.get(field)}, '
                        f'the baseline says {want.get(field)}'
                    )

            for stage in STAGES:
                got = row.get(stage)
                was = want.get(stage)

                if got is None or was is None:
                    problems.append(f'{shape} ({size}): no {stage}')
                    continue

                if got > was * ABSOLUTE_FACTOR + ABSOLUTE_FLOOR_MS:
                    problems.append(
                        f'{shape} ({size}): {stage} is {got:.1f}ms, '
                        f'{ABSOLUTE_FACTOR:g}x the baseline {was:.1f}ms'
                    )

        rows = measured[shape]

        if all(size in rows for size in SIZES):
            for stage in STAGES:
                small = rows['small'].get(stage)
                large = rows['large'].get(stage)

                if small is None or large is None or small < RATIO_FLOOR_MS:
                    continue

                if large > small * RATIO_LIMIT:
                    problems.append(
                        f'{shape}: {stage} went {small:.1f}ms -> {large:.1f}ms when the '
                        f'tree doubled ({large / small:.1f}x): the stage is not linear'
                    )

    return problems


def table(report):
    """The report as a table, for whoever accepts a baseline."""
    lines = [
        f'{"shape":<{SHAPE_WIDTH}}{"size":>7}{"nodes":>8}{"classes":>9}'
        f'{"plan":>10}{"css":>10}{"write":>10}{"html":>11}{"css":>11}'
    ]

    for shape, sizes in report.get('shapes', {}).items():
        for size in SIZES:
            row = sizes.get(size)

            if row is None:
                continue

            lines.append(
                f'{shape:<{SHAPE_WIDTH}}{size:>7}{row["nodes"]:>8}{row["classes"]:>9}'
                f'{row["plan_ms"]:>9.1f}ms{row["css_ms"]:>9.1f}ms'
                f'{row["write_ms"]:>9.1f}ms{row["html_bytes"]:>11}{row["css_bytes"]:>11}'
            )

    return '\n'.join(lines)


def main(argv):
    if len(argv) < 2:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    report = load(argv[1])
    update = '--update' in argv

    print(table(report))

    if update:
        with open(BASELINE, 'w', encoding='utf-8') as handle:
            json.dump(report, handle, indent=2, sort_keys=True)
            handle.write('\n')

        print(f'\nWrote {os.path.relpath(BASELINE)}. Read the table above first: a baseline '
              'is a claim about what this pipeline costs.')

        return 0

    problems = judge(report, load(BASELINE))

    if problems:
        print('\nA big page costs more than it did:', file=sys.stderr)

        for problem in problems:
            print(f'  {problem}', file=sys.stderr)

        print('\nIf the change is intended, run tool/scale.sh --update and read the table.',
              file=sys.stderr)

        return 1

    print('\nEvery shape agrees with the baseline.')

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
