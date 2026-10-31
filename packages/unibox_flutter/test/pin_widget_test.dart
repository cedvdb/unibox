import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// A band of the test tree, keyed so a test can ask where it ended up.
core.Box _band(
  String key, {
  required double height,
  double width = 300,
  core.BoxPin? pin,
  double? pinOffset,
  VoidCallback? onTap,
}) {
  return core.Box(
    key: key,
    width: width,
    height: height,
    pin: pin,
    pinOffset: pinOffset,
    onTap: onTap,
  );
}

/// The viewport every test scrolls: 300 by 400, with the children it is given.
core.Box _viewport(List<core.UINode> children) => core.Box(
  key: 'viewport',
  width: 300,
  height: 400,
  overflow: core.Overflow.scroll,
  children: children,
);

/// The distance from the top of the viewport to the top of [key], which is the only
/// position a pin is about.
double _topOf(WidgetTester tester, String key) =>
    tester.getTopLeft(find.byKey(ValueKey<Object>(key))).dy -
    tester.getTopLeft(find.byKey(const ValueKey<Object>('viewport'))).dy;

/// Drags the viewport by [dy] and lets the scroll settle.
Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(
    find.byKey(const ValueKey<Object>('viewport')),
    Offset(0, -dy),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a pinned band', () {
    testWidgets('comes to rest at the start edge once it would have scrolled '
        'past, and returns to its slot', (tester) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _band('hero', height: 100),
          _band('toolbar', height: 60, pin: core.BoxPin.start),
          _band('results', height: 600),
        ]),
      );

      expect(_topOf(tester, 'toolbar'), 100);

      await _scroll(tester, 200);

      // The hero has left and the band is at the edge of the viewport.
      expect(_topOf(tester, 'toolbar'), 0);

      // The results did not move with it: the band kept its slot, so the list is where
      // the flow put it rather than where the band was painted.
      expect(_topOf(tester, 'results'), -40);

      await _scroll(tester, -200);

      expect(_topOf(tester, 'toolbar'), 100);
    });

    testWidgets('keeps the inset it is given under the header above it', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _band('header', height: 48),
          _band('toolbar', height: 60, pin: core.BoxPin.start, pinOffset: 48),
          _band('results', height: 600),
        ]),
      );

      await _scroll(tester, 300);

      expect(_topOf(tester, 'toolbar'), 48);
    });

    testWidgets('paints above the content that scrolls under it', (
      tester,
    ) async {
      int bandPresses = 0;
      int resultPresses = 0;

      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _band(
            'toolbar',
            height: 60,
            pin: core.BoxPin.start,
            onTap: () => bandPresses++,
          ),
          _band('results', height: 600, onTap: () => resultPresses++),
        ]),
      );

      await _scroll(tester, 200);

      // The band is at the top of the viewport with the results under it, so a press there
      // is the band's: a browser needs the `z-index` it writes with `position: sticky` for
      // the same reason, and a band left in the flow order would lose the press.
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey<Object>('toolbar'))),
      );
      await tester.pump();

      expect(bandPresses, 1);
      expect(resultPresses, 0);
    });

    testWidgets('leaves the flow a flex container, so nothing else moves', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _band('toolbar', height: 60, pin: core.BoxPin.start),
          _band('results', height: 600),
        ]),
      );

      // The pin is a layer over the viewport and not a different layout: the children are
      // still a column, so `gap`, `crossAlign` and `mainAlign` mean what they always mean.
      expect(inNode(find.byType(SingleChildScrollView)), findsOneWidget);
      expect(
        inNode(find.byWidgetPredicate((Widget widget) => widget is Flex)),
        findsWidgets,
      );
      expect(inNode(find.byType(CustomScrollView)), findsNothing);
    });

    testWidgets('holds an end band at the end edge until its slot arrives', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _band('results', height: 700),
          _band('bar', height: 60, pin: core.BoxPin.end),
        ]),
      );

      // The slot is at 700, below the fold, so the band is drawn at the end edge.
      expect(_topOf(tester, 'bar'), 340);

      await _scroll(tester, 360);

      // The slot arrived exactly where the band was, so nothing jumps at the end.
      expect(_topOf(tester, 'bar'), 340);
      expect(_topOf(tester, 'results'), -360);
    });

    testWidgets('keeps its inset above the end edge', (tester) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _band('results', height: 700),
          _band('bar', height: 60, pin: core.BoxPin.end, pinOffset: 16),
        ]),
      );

      expect(_topOf(tester, 'bar'), 400 - 60 - 16);
    });

    testWidgets('never lifts a band past the end of the content', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _band('results', height: 600),
          _band('footer', height: 60, pin: core.BoxPin.start),
        ]),
      );

      // The content is 660 tall in a 400 viewport, so 260 is as far as it scrolls — and the
      // band is the last thing in it.
      await _scroll(tester, 300);

      // Nothing is left for the band to stay over: it settles where the flow put it rather
      // than coming away from the end of the content.
      expect(_topOf(tester, 'footer'), 340);
    });

    testWidgets('draws a band in the flow when no box in the tree scrolls', (
      tester,
    ) async {
      // The one documented asymmetry: the web pins a band at the top of a page to the
      // document, and the surface an application is drawn on does not scroll.
      await pumpNode(
        tester,
        core.Box(
          key: 'viewport',
          width: 300,
          height: 400,
          children: <core.UINode>[
            _band('header', height: 100),
            _band('toolbar', height: 60, pin: core.BoxPin.start),
          ],
        ),
      );

      expect(_topOf(tester, 'toolbar'), 100);
      expect(inNode(find.byType(SingleChildScrollView)), findsNothing);
    });

    testWidgets('leaves a box without a pin in a plain scroll view', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _band('top', height: 100),
          _band('list', height: 600),
        ]),
      );

      // A pin is what adds the layer over the viewport; a box that states none keeps the
      // layout it always had, so an existing tree is drawn exactly as before.
      expect(inNode(find.byType(SingleChildScrollView)), findsOneWidget);
      expect(inNode(find.byType(CustomScrollView)), findsNothing);
    });
  });
}
