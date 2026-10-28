#!/usr/bin/env python3
"""Print what a crawler gets from each document of a built site.

Usage:
  tool/site.sh
  python3 tool/seo_report.py build/site

The point of the library is that a screen which has to rank is served as text, so
the numbers worth looking at are the ones a search engine reads: the words in the
document, its headings, its links and its fields. The Flutter build of the same
screen is a canvas host, and it shows up here as what it is — a title and nothing
else.
"""

import html
import os
import re
import sys


def visible_text(document: str) -> str:
    """The text a reader (or a crawler) sees, with scripts and styles removed."""
    text = re.sub(r'(?is)<script.*?</script>', ' ', document)
    text = re.sub(r'(?is)<style.*?</style>', ' ', text)
    text = re.sub(r'(?s)<[^>]+>', ' ', text)
    return ' '.join(html.unescape(text).split())


def report(root: str, path: str, label: str) -> None:
    file = os.path.join(root, path)
    if not os.path.exists(file):
        print(f'{label:26} missing: {file}')
        return

    document = open(file, encoding='utf-8', errors='ignore').read()
    text = visible_text(document)
    print(
        f'{label:26} words={len(text.split()):4}'
        f' h1={document.count("<h1")} h2={document.count("<h2")}'
        f' links={document.count("<a ")} fields={document.count("<input")}'
        f' bytes={len(document):6}'
    )
    print(f'{"":26} {text[:96]!r}')


DOCUMENTS = [
    ('index.html', 'html    /'),
    ('web/listings/index.html', 'html    /web/listings/'),
    ('web/signup/index.html', 'html    /web/signup/'),
    ('flutter/index.html', 'flutter /flutter/listings/'),
]


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else 'build/site'
    print(f'What a crawler reads in {root}:')
    for path, label in DOCUMENTS:
        report(root, path, label)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
