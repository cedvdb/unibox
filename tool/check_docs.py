#!/usr/bin/env python3
"""Check that the repository's documentation points at files that exist.

Usage:
  python3 tool/check_docs.py

An index is believed by everyone who reads it, and an assistant reads it as fact: a link to
a file that was renamed is worse than no link, because it sends a reader into a package
that is gone. This is the cheapest possible test of that, and it is why it runs in the fast
loop rather than in a scheduled job.

Three things are checked, and nothing else:

  * every relative link in the repository's documents resolves to a path;
  * every package has the README and CHANGELOG the rest of the workspace has;
  * every document is listed in `llms.txt`, so nothing is discoverable only by name.

Anchors are stripped: a heading's slug is the renderer's business, and a link to a missing
heading is a typo no static check can find without parsing Markdown.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INDEX = 'llms.txt'

# The documents at the root, the two agent files that live beside them, and the node
# reference under `docs/nodes`. Scratch plans are included: a stale path in one still sends
# a reader into a file that is gone.
DOCUMENTS = [
    'README.md',
    'AGENTS.md',
    'AI_INSTRUCTIONS.md',
    'CONTRIBUTING.md',
    'MAINTENANCE.md',
    'CODE_OF_CONDUCT.md',
    'CLAUDE.md',
    'design.md',
    'docs/nodes/README.md',
    'docs/nodes/box.md',
    'docs/nodes/text.md',
    'docs/nodes/image.md',
    'docs/nodes/link.md',
    'docs/nodes/stack.md',
    'docs/nodes/text-input.md',
    'docs/nodes/stateful.md',
    'docs/nodes/grid.md',
    'docs/nodes/overlay.md',
    'docs/nodes/embed.md',
    'RELEASE.md',
    INDEX,
]

LINK = re.compile(r'!?\[[^\]]*\]\(([^)\s]+)\)')


def relative_links(text: str):
    for target in LINK.findall(text):
        if target.startswith(('http://', 'https://', 'mailto:', '#')):
            continue
        yield target.split('#', 1)[0]


def main() -> int:
    problems = []

    for document in DOCUMENTS:
        path = os.path.join(ROOT, document)
        if not os.path.exists(path):
            problems.append(f'{document}: listed in check_docs.py but does not exist')
            continue
        directory = os.path.dirname(path)
        with open(path, encoding='utf-8') as handle:
            for target in relative_links(handle.read()):
                if not target:
                    continue
                if not os.path.exists(os.path.join(directory, target)):
                    problems.append(f'{document}: {target} does not exist')

    packages = sorted(
        name
        for name in os.listdir(os.path.join(ROOT, 'packages'))
        if os.path.isdir(os.path.join(ROOT, 'packages', name))
    )
    for package in packages:
        for required in ('README.md', 'CHANGELOG.md', 'pubspec.yaml'):
            if not os.path.exists(os.path.join(ROOT, 'packages', package, required)):
                problems.append(f'packages/{package}: no {required}')

    with open(os.path.join(ROOT, INDEX), encoding='utf-8') as handle:
        index = handle.read()
    for document in DOCUMENTS:
        if document != INDEX and f'({document})' not in index and f'({document}#' not in index:
            problems.append(f'{INDEX}: {document} is not listed')

    if problems:
        print('The documentation points at something that is not there:', file=sys.stderr)
        for problem in problems:
            print(f'  {problem}', file=sys.stderr)
        print('\nA rename is not finished until the documents agree with it.', file=sys.stderr)
        return 1

    print(f'{len(DOCUMENTS)} documents and {len(packages)} packages agree with the tree')
    return 0


if __name__ == '__main__':
    sys.exit(main())
