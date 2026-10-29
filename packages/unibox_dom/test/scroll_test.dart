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

/// The content of a scroll box: bigger than the box, and held there.
///
/// A flex item shrinks to fit its container by default, so a box that has to overflow states
/// a `minHeight` as well as a `height` — without it the browser squashes it into the frame
/// and there is nothing to scroll.
const core.UINode tall = core.Box(
  width: 400,
  height: 400,
  minWidth: 400,
  minHeight: 400,
);

/// A scroll box, keyed so a test can find the element it became.
core.Box scroller({
  required String key,
  required List<double> into,
  core.Axis direction = core.Axis.vertical,
  double? width,
  List<core.UINode> children = const <core.UINode>[tall],
}) {
  return core.Box(
    key: key,
    direction: direction,
    width: width,
    height: 100,
    overflow: core.Overflow.scroll,
    onScroll: into.add,
    children: children,
  );
}

web.Element elementFor(web.Element place, String key) =>
    place.querySelector('[data-unibox-key="$key"]')!;

void main() {
  group('a scrolling box', () {
    test('reports how far its own content has scrolled', () {
      // The number a browser reports for its own element, which is the same number
      // `ScrollMetrics.pixels` gives in Flutter: distance along the main axis.
      final List<double> offsets = <double>[];
      final web.HTMLDivElement place = host();
      DomView.mount(scroller(key: 'outer', into: offsets), place);

      elementFor(place, 'outer')
        ..scrollTop = 40
        ..dispatchEvent(web.Event('scroll'));

      expect(offsets, <double>[40]);
    });

    test('reports the horizontal offset of a row', () {
      final List<double> offsets = <double>[];
      final web.HTMLDivElement place = host();
      DomView.mount(
        // Narrow, so the content is wider than the box: a row the width of the page has
        // nothing to scroll.
        scroller(
          key: 'row',
          into: offsets,
          direction: core.Axis.horizontal,
          width: 100,
        ),
        place,
      );

      elementFor(place, 'row')
        ..scrollLeft = 24
        ..dispatchEvent(web.Event('scroll'));

      expect(offsets, <double>[24]);
    });

    test('reports nothing for a scrollable nested inside it', () {
      // `scroll` does not bubble, so the outer box never hears the inner one — the same
      // rule Flutter gets from a notification's depth.
      final List<double> outer = <double>[];
      final List<double> inner = <double>[];

      final web.HTMLDivElement place = host();
      DomView.mount(
        scroller(
          key: 'outer',
          into: outer,
          children: <core.UINode>[scroller(key: 'inner', into: inner)],
        ),
        place,
      );

      elementFor(place, 'inner')
        ..scrollTop = 30
        ..dispatchEvent(web.Event('scroll'));

      expect(inner, <double>[30]);
      expect(outer, isEmpty);
    });

    test('stops reporting once the view is disposed', () {
      final List<double> offsets = <double>[];
      final web.HTMLDivElement place = host();
      final DomView view = DomView.mount(
        scroller(key: 'outer', into: offsets),
        place,
      );
      final web.Element box = elementFor(place, 'outer');

      view.dispose();
      box
        ..scrollTop = 10
        ..dispatchEvent(web.Event('scroll'));

      expect(offsets, isEmpty);
    });
  });
}
