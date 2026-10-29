"""Holds the built documents to what a crawler and a reader need from them.

Usage:
    python3 tool/doc_check.py <site-dir>

Every other check in this repository asks whether the pages *work*: the client answers a press, the
takeover boots, Lighthouse scores them. None of them asks whether the page is still a page — that a
heading is a heading, that the images and scripts a document names exist where it says they are, that
the sitemap lists what was published.

That last one is not hypothetical: the example's document asked for `web/main.client.js` from one
directory down, which resolved to a 404, and every gate passed — the page still served, still scored
well, and did nothing when pressed.
"""

import os
import re
import sys

# What each published document owes. Words are a floor with room: a band may be rewritten, but a page
# that loses two thirds of its text is not a redesign, it is a bug.
DOCUMENTS = {
    'index.html': {'words': 300, 'h1': 1, 'links': 4, 'iframes': 2},
    'web/listings/index.html': {'words': 60, 'h1': 1, 'links': 1, 'inputs': 0},
    'web/takeover/index.html': {'words': 60, 'h1': 1, 'links': 1, 'inputs': 0},
}

# Attributes that name a file the build has to contain.
REFERENCES = ('src', 'href')


def text_of(html):
    body = html[html.index('<body'):]
    body = re.sub(r'<(script|style)[^>]*>.*?</\1>', ' ', body, flags=re.S)

    return re.sub(r'<[^>]+>', ' ', body)


def check(name, path, floors):
    html = open(path).read()
    problems = []

    words = len(text_of(html).split())

    if words < floors['words']:
        problems.append(f'{words} words, floor {floors["words"]}')

    for tag in ('h1', 'a', 'iframe', 'input'):
        key = {'h1': 'h1', 'a': 'links', 'iframe': 'iframes', 'input': 'inputs'}[tag]
        floor = floors.get(key)

        if floor is None:
            continue

        found = len(re.findall(rf'<{tag}[ >]', html))

        if found < floor:
            problems.append(f'{found} <{tag}> elements, floor {floor}')

    # Every script, image and stylesheet the document names has to be in the build. This is the check
    # that catches a wrong relative path, which no browser reports as an error and no score notices.
    for match in re.finditer(r'<(?:script|img|link)\b[^>]*>', html):
        tag = match.group(0)

        for attribute in REFERENCES:
            found = re.search(rf'{attribute}="([^"]+)"', tag)

            if not found:
                continue

            value = found.group(1)

            if value.startswith(('http://', 'https://', 'data:', '#', 'mailto:')):
                continue

            target = os.path.normpath(os.path.join(os.path.dirname(path), value.split('?')[0]))

            if not os.path.exists(target):
                problems.append(f'{tag.split()[0]} points at {value}, which is not in the build')

    return problems


def main():
    site = sys.argv[1]
    url = sys.argv[2] if len(sys.argv) > 2 else ''
    required = ('sitemap.xml', 'robots.txt') if url else ('robots.txt',)
    failures = 0

    for name, floors in DOCUMENTS.items():
        path = os.path.join(site, name)

        if not os.path.isfile(path):
            print(f'  FAIL {name} — not in the build')
            failures += 1

            continue

        problems = check(name, path, floors)

        if problems:
            failures += 1
            print(f'  FAIL {name}')

            for problem in problems:
                print(f'         {problem}')
        else:
            print(f'  ok   {name}')

    for name in required:
        path = os.path.join(site, name)

        if not os.path.isfile(path) or os.path.getsize(path) == 0:
            print(f'  FAIL {name} — missing or empty')
            failures += 1
        else:
            print(f'  ok   {name}')

    if failures:
        print(f'\n==> FAILED: {failures} document check(s)', file=sys.stderr)

        return 1

    print('\n==> The documents still say what a crawler and a reader need.')

    return 0


if __name__ == '__main__':
    sys.exit(main())
