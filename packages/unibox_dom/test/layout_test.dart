@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:web/web.dart' as web;

/// Where a view is drawn in the test page.
web.HTMLDivElement host() {
  final web.HTMLDivElement element =
      web.document.createElement('div') as web.HTMLDivElement;
  web.document.body!.append(element);

  return element;
}

/// The element [key] became, inside [place].
web.Element elementFor(web.Element place, String key) =>
    place.querySelector('[data-unibox-key="$key"]')!;

/// Where [key] is drawn, relative to the box that scrolls it.
web.DOMRect rectOf(web.Element place, String key) {
  final web.DOMRect box = elementFor(place, key).getBoundingClientRect();
  final web.DOMRect viewport = elementFor(
    place,
    'viewport',
  ).getBoundingClientRect();

  return web.DOMRect(
    box.left - viewport.left,
    box.top - viewport.top,
    box.width,
    box.height,
  );
}

void main() {
  group('a stretch inside a line with no end', () {
    test(
      'makes the line as tall as the tallest child, which the rest fill',
      () {
        // The same numbers the Flutter suite reads: a results column beside a map panel, in a
        // column that scrolls, so nothing above the row states a height. The browser resolves
        // `align-items: stretch` against the row's own content, and Flutter measures the row
        // once to get there.
        final web.HTMLDivElement place = host();

        DomView.mount(
          core.Box(
            key: 'viewport',
            width: 300,
            height: 400,
            overflow: core.Overflow.scroll,
            children: <core.UINode>[
              core.Box(
                key: 'row',
                direction: core.Axis.horizontal,
                crossAlign: core.CrossAlign.stretch,
                children: const <core.UINode>[
                  core.Box(key: 'cards', width: 100, height: 300),
                  core.Box(key: 'map', width: 100),
                ],
              ),
            ],
          ),
          place,
        );

        expect(rectOf(place, 'row').height, 300);
        expect(rectOf(place, 'map').height, 300);
      },
    );
  });

  group('a pinned bar', () {
    test('keeps its own room in the flow with no stated height', () {
      // `position: sticky` needs no height, because the bar keeps its own room in the flow:
      // the results below it start where its content ends, and the bar holds the edge as the
      // content scrolls under it. Flutter measures the bar it draws for exactly this number.
      final web.HTMLDivElement place = host();

      DomView.mount(
        core.Box(
          key: 'viewport',
          width: 300,
          height: 400,
          overflow: core.Overflow.scroll,
          children: <core.UINode>[
            core.Box(key: 'hero', width: 300, height: 100),
            core.Box(
              key: 'toolbar',
              pin: core.BoxPin.start,
              gap: 4,
              children: const <core.UINode>[
                core.Box(width: 200, height: 24),
                core.Box(width: 200, height: 40),
              ],
            ),
            core.Box(key: 'results', width: 300, height: 600),
          ],
        ),
        place,
      );

      expect(
        rectOf(place, 'toolbar').height,
        68,
        reason: '24 + 4 + 40, measured by the browser',
      );
      expect(
        rectOf(place, 'results').top,
        168,
        reason: 'the hero and the bar keep their room in the flow',
      );

      elementFor(place, 'viewport').scrollTop = 200;

      expect(rectOf(place, 'toolbar').top, 0);
      expect(
        rectOf(place, 'results').top,
        -32,
        reason: 'the content scrolled; the bar did not',
      );
    });
  });

  group('a pin deeper than the box that scrolls it', () {
    // The page owns its scroll and the panel sits in the flow of a box below it — a results
    // page with a map beside the cards. `position: sticky` resolves its edge against the
    // scrollport and its travel against the containing block, so the panel rests at the top of
    // the viewport while the cards scroll and leaves with the bottom of the box around it.
    //
    // The stated floors are the browser's own: a flex item shrinks to fit its container, so a
    // column that has to overflow says how short each child may get.
    core.Box page() => core.Box(
      key: 'viewport',
      width: 300,
      height: 400,
      overflow: core.Overflow.scroll,
      children: <core.UINode>[
        core.Box(key: 'hero', width: 300, height: 400, minHeight: 400),
        core.Box(
          key: 'row',
          width: 300,
          height: 600,
          minHeight: 600,
          children: <core.UINode>[
            core.Box(
              key: 'panel',
              width: 100,
              height: 100,
              minHeight: 100,
              pin: core.BoxPin.start,
            ),
            core.Box(key: 'list', width: 100, height: 500, minHeight: 500),
          ],
        ),
        core.Box(key: 'footer', width: 300, height: 400, minHeight: 400),
      ],
    );

    test('rests at the top of the box it is in and leaves with that box', () {
      final web.HTMLDivElement place = host();

      DomView.mount(page(), place);

      expect(
        rectOf(place, 'panel').top,
        400,
        reason: 'at rest the panel is where the flow put it',
      );

      final web.Element viewport = elementFor(place, 'viewport');

      viewport.scrollTop = 500;

      expect(rectOf(place, 'panel').top, 0);
      expect(
        rectOf(place, 'list').top,
        0,
        reason: 'the list moves with the scroll: the panel kept its slot',
      );

      viewport.scrollTop = 950;

      // The row's bottom edge is 50 from the top of the viewport, so the panel stops there:
      // a pin bounded by the viewport alone would still be at 0.
      expect(rectOf(place, 'panel').top, -50);

      viewport.scrollTop = 1000;

      expect(
        rectOf(place, 'panel').top,
        -100,
        reason: 'the box around it has left, so the panel left with it',
      );
    });
  });
}
