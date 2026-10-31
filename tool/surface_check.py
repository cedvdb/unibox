#!/usr/bin/env python3
"""Check that every token and every callback has a decided place in the contract.

Usage:
  python3 tool/surface_check.py

`packages/unibox_testing` is where the expected appearance of a token is written down, and the rule
is that a token without a case there is not finished. `test/cases_test.dart` checks that the table is
consistent — no two cases expect the same presentation, and the last case carries every token it
lists — but nothing in it can see the model. A token added to `BoxStyle` with no case is a token
nobody compares, and both renderer suites stay green because they only test the cases that exist.
A human reviewer notices that. An assistant does not.

So this checks one thing, by name: every token declared in `box_style.dart` and `box_text_style.dart`
is either a field of the appearance the two renderers are held to, or named in the map below with
the reason it is not. **The map is the point.** A token that arrives unclassified turns the gate red,
which is the decision being asked for — not a demand that every token be comparable. Sixteen of the
thirty box tokens are deliberately outside the table, because a browser and a Flutter `Text` never
agree about them; those sixteen are now written down instead of remembered.

The same, for the callbacks on the nodes: each one has to be reached by the Flutter renderer and by
`packages/unibox_dom/lib/src/events.dart`, or be classified. `Box.onHover` was declared, used by a
component, bound by nothing for a day, and every suite passed.

What this cannot see, and does not claim to: whether a binding calls a callback *correctly* (that is
behaviour, and each renderer's suite pins it), and whether two different tokens happen to produce the
same output (that is `test/cases_test.dart`). It checks that a name is reached, not that it works.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# A field, as these files spell one: two spaces of indentation, `final`, a type, a name, a semicolon.
# A type with a package prefix (`core.BoxSpacing?`) and a type with a comma in it come out of the
# same line, which is why the name is taken from the end rather than from a shape.
FIELD = re.compile(r'^  final [^\n]*?([A-Za-z_]\w*);', re.MULTILINE)

# A callback on a node: the model names them all `on<Something>`, typed by a typedef ending `Callback`.
CALLBACK = re.compile(r'^  final [A-Za-z_.]*Callback\? (on[A-Za-z]\w*);', re.MULTILINE)

# What the model declares, and where the appearance a renderer is held to lives.
CONTRACTS = (
    {
        'tokens': 'packages/unibox_core/lib/src/tokens/box_style.dart',
        'contract': 'packages/unibox_testing/lib/src/appearance.dart',
        'name': 'BoxStyle',
        'appearance': 'BoxAppearance',
    },
    {
        'tokens': 'packages/unibox_core/lib/src/tokens/box_text_style.dart',
        'contract': 'packages/unibox_testing/lib/src/text_appearance.dart',
        'name': 'BoxTextStyle',
        'appearance': 'TextAppearance',
    },
)

# Every token that is not a field of the appearance, and why. A new token lands here or in the table;
# leaving it in neither is the state this refuses, because that is the state where nobody compares it.
CLASSIFIED = {
    'BoxStyle': {
        'flex': 'a share of a parent, and the appearance describes one box without one',
        'overflow': 'clipping and scrolling need a viewport neither output hands back',
        'snap': 'where a scrolling box comes to rest; meaningless without `overflow`',
        'page': 'which child a pager shows at rest, which is a position rather than a look',
        'pin': 'where a band comes to rest in a viewport, which is a fact about scrolling and not '
        'about the box at rest: the band looks the same pinned or not, and the two renderer '
        'suites scroll it instead',
        'pinOffset': 'the room a pinned band keeps from its edge, which moves nothing until the '
        'content scrolls past it',
        'heightFraction': 'the table carries the width fraction only; a height fraction is pinned '
        'by the node suites',
        'minWidth': 'a constraint rather than a measurement: the output reports the size it settled on',
        'maxWidth': 'a constraint rather than a measurement',
        'minHeight': 'a constraint rather than a measurement',
        'maxHeight': 'a constraint rather than a measurement',
        'border': 'spread into `borderWidth` and `borderColor`',
        'shadows': 'blur, spread and offset stay approximate on purpose, so the suites assert that a '
        'shadow is emitted and not what it blurs to',
        'shape': 'a path in a view box, which neither output hands back',
        'gridSpan': 'compared by `GridAppearance` in `grid_cases.dart`, because what decides whether '
        'a span is honoured is the grid the box sits in and not the box that states it',
        'wrap': 'where a wrap breaks its lines depends on the width the box is drawn at, which the '
        'appearance of one box at no particular width cannot carry; the node suites compare the '
        'rows at a stated width instead',
        'textStyle': 'typography is compared through `TextAppearance`, not through a box',
        'transition': 'spread into `transitionDuration` and `transitionCurve`',
        'visibleFrom': 'the width a box is drawn at, and the appearance describes a box at no '
        'particular width',
        'visibleUntil': 'the width a box stops being drawn at, for the same reason',
    },
    # Every text token but one is in `TextAppearance`; a token that is not has a place to be
    # explained here.
    'BoxTextStyle': {
        'decorationThickness': 'a length in logical pixels, and only the web can draw one: Flutter '
        'scales the thickness the font asks for, so the app draws the font\'s own line. The '
        'asymmetry is recorded in design.md and in the Flutter README',
    },
}


# The callbacks, and the two places each one has to arrive: the widget, and the event binding.
CALLBACKS = {
    'declares': 'packages/unibox_core/lib/src/nodes',
    'reaches': (
        ('the Flutter renderer', ('packages/unibox_flutter/lib/src',)),
        ('the web runtime', ('packages/unibox_dom/lib/src/events.dart',)),
    ),
}

# A callback deliberately bound on one target only, and why. Empty today: every callback the model
# declares is reached by both.
CALLBACKS_CLASSIFIED = {}


def read(root, relative):
    """One file of the tree, as text."""
    with open(os.path.join(root, relative), encoding='utf-8') as handle:
        return handle.read()


def read_all(root, where):
    """Every `.dart` file under each path in `where`, joined into one text."""
    if isinstance(where, str):
        where = (where,)

    text = []
    for relative in where:
        path = os.path.join(root, relative)
        if os.path.isdir(path):
            text.extend(
                read(root, os.path.join(relative, name))
                for name in sorted(os.listdir(path))
                if name.endswith('.dart')
            )
        else:
            text.append(read(root, relative))

    return '\n'.join(text)


def names(root, relative, pattern):
    """The identifiers `pattern` finds in one file."""
    return set(pattern.findall(read(root, relative)))


def declared_callbacks(root):
    """Every callback the node tree declares."""
    declared = set()
    for name in sorted(os.listdir(os.path.join(root, CALLBACKS['declares']))):
        if name.endswith('.dart'):
            declared |= names(root, os.path.join(CALLBACKS['declares'], name), CALLBACK)
    return declared


def findings(root):
    """Everything that has no decided place, as sentences. Empty means the tree agrees."""
    problems = []

    for contract in CONTRACTS:
        tokens = names(root, contract['tokens'], FIELD)
        compared = names(root, contract['contract'], FIELD)
        classified = CLASSIFIED[contract['name']]
        where = os.path.basename(contract['contract'])

        for token in sorted(tokens - compared - set(classified)):
            problems.append(
                f'{contract["tokens"]}: `{token}` is not a field of {contract["appearance"]} and has '
                'no reason in the CLASSIFIED map of tool/surface_check.py'
            )

        for token in sorted(set(classified) & compared):
            problems.append(
                f'{contract["tokens"]}: `{token}` is classified as outside {contract["appearance"]} '
                f'and is also a field of {where} — one of the two is now the wrong one'
            )

        for token in sorted(set(classified) - tokens):
            problems.append(
                f'{contract["tokens"]}: `{token}` is classified in tool/surface_check.py and is no '
                'longer a token — a reason for something that is gone reads as a fact'
            )

    declared = declared_callbacks(root)
    reached = {label: read_all(root, where) for label, where in CALLBACKS['reaches']}

    for callback in sorted(declared - set(CALLBACKS_CLASSIFIED)):
        for label, text in reached.items():
            if not re.search(rf'\b{callback}\b', text):
                problems.append(
                    f'`{callback}` is declared in {CALLBACKS["declares"]} and is never reached by '
                    f'{label} — a callback no renderer binds is a control that looks alive and does '
                    'nothing'
                )

    for callback in sorted(set(CALLBACKS_CLASSIFIED) - declared):
        problems.append(
            f'`{callback}` is classified in tool/surface_check.py and is no longer declared by a node'
        )

    return problems


def main():
    problems = findings(ROOT)

    if problems:
        print('A token or a callback has no decided place in the contract:', file=sys.stderr)
        for problem in problems:
            print(f'  {problem}', file=sys.stderr)
        print(
            '\nAdd the case in packages/unibox_testing, or the reason in tool/surface_check.py.\n'
            'A token nobody classified is a token nobody compares.',
            file=sys.stderr,
        )
        return 1

    tokens = sum(len(names(ROOT, contract['tokens'], FIELD)) for contract in CONTRACTS)
    compared = sum(
        len(names(ROOT, contract['contract'], FIELD) & names(ROOT, contract['tokens'], FIELD))
        for contract in CONTRACTS
    )
    classified = sum(len(reasons) for reasons in CLASSIFIED.values())

    print(
        f'{tokens} tokens and {len(declared_callbacks(ROOT))} callbacks have a decided place: '
        f'{compared} compared by the table, {classified} outside it with a reason'
    )
    return 0


if __name__ == '__main__':
    sys.exit(main())
