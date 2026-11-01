import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// A bar of the test tree, keyed so a test can ask where it ended up.
core.Box _bar(
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

/// The distance from the left edge of the viewport to the left edge of [key], which is the
/// width the box states and the cross alignment it is placed by.
double _leftOf(WidgetTester tester, String key) =>
    tester.getTopLeft(find.byKey(ValueKey<Object>(key))).dx -
    tester.getTopLeft(find.byKey(const ValueKey<Object>('viewport'))).dx;

/// Drags the viewport by [dy] and lets the scroll settle.
Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(
    find.byKey(const ValueKey<Object>('viewport')),
    Offset(0, -dy),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a pinned bar', () {
    testWidgets('comes to rest at the start edge once it would have scrolled '
        'past, and returns to its slot', (tester) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _bar('hero', height: 100),
          _bar('toolbar', height: 60, pin: core.BoxPin.start),
          _bar('results', height: 600),
        ]),
      );

      expect(_topOf(tester, 'toolbar'), 100);

      await _scroll(tester, 200);

      // The hero has left and the bar is at the edge of the viewport.
      expect(_topOf(tester, 'toolbar'), 0);

      // The results did not move with it: the bar kept its slot, so the list is where
      // the flow put it rather than where the bar was painted.
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
          _bar('header', height: 48),
          _bar('toolbar', height: 60, pin: core.BoxPin.start, pinOffset: 48),
          _bar('results', height: 600),
        ]),
      );

      await _scroll(tester, 300);

      expect(_topOf(tester, 'toolbar'), 48);
    });

    testWidgets('paints above the content that scrolls under it', (
      tester,
    ) async {
      int barPresses = 0;
      int resultPresses = 0;

      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _bar(
            'toolbar',
            height: 60,
            pin: core.BoxPin.start,
            onTap: () => barPresses++,
          ),
          _bar('results', height: 600, onTap: () => resultPresses++),
        ]),
      );

      await _scroll(tester, 200);

      // The bar is at the top of the viewport with the results under it, so a press there
      // is the bar's: a browser needs the `z-index` it writes with `position: sticky` for
      // the same reason, and a bar left in the flow order would lose the press.
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey<Object>('toolbar'))),
      );
      await tester.pump();

      expect(barPresses, 1);
      expect(resultPresses, 0);
    });

    testWidgets('leaves the flow a flex container, so nothing else moves', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _bar('toolbar', height: 60, pin: core.BoxPin.start),
          _bar('results', height: 600),
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

    testWidgets('holds an end bar at the end edge until its slot arrives', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _bar('results', height: 700),
          _bar('bar', height: 60, pin: core.BoxPin.end),
        ]),
      );

      // The slot is at 700, below the fold, so the bar is drawn at the end edge.
      expect(_topOf(tester, 'bar'), 340);

      await _scroll(tester, 360);

      // The slot arrived exactly where the bar was, so nothing jumps at the end.
      expect(_topOf(tester, 'bar'), 340);
      expect(_topOf(tester, 'results'), -360);
    });

    testWidgets('keeps its inset above the end edge', (tester) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _bar('results', height: 700),
          _bar('bar', height: 60, pin: core.BoxPin.end, pinOffset: 16),
        ]),
      );

      expect(_topOf(tester, 'bar'), 400 - 60 - 16);
    });

    testWidgets('never lifts a bar past the end of the content', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _bar('results', height: 600),
          _bar('footer', height: 60, pin: core.BoxPin.start),
        ]),
      );

      // The content is 660 tall in a 400 viewport, so 260 is as far as it scrolls — and the
      // bar is the last thing in it.
      await _scroll(tester, 300);

      // Nothing is left for the bar to stay over: it settles where the flow put it rather
      // than coming away from the end of the content.
      expect(_topOf(tester, 'footer'), 340);
    });

    testWidgets('pins a bar that states no height, as tall as its content', (
      tester,
    ) async {
      // A filter row that may take a second line: it cannot state what it does not know, and
      // CSS's `position: sticky` needs nothing stated. The slot it keeps in the flow is the
      // height it laid itself out at, so the results below it sit where the bar actually ends.
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _bar('hero', height: 100),
          core.Box(
            key: 'toolbar',
            pin: core.BoxPin.start,
            gap: 4,
            children: const <core.UINode>[
              core.Box(width: 200, height: 24),
              core.Box(width: 200, height: 40),
            ],
          ),
          _bar('results', height: 600),
        ]),
      );

      // 24 + 4 + 40, measured rather than stated.
      expect(_topOf(tester, 'results'), 168);

      await _scroll(tester, 200);

      expect(_topOf(tester, 'toolbar'), 0);
      expect(
        _topOf(tester, 'results'),
        -32,
        reason:
            'the flow kept the room the bar takes, so the list did not jump',
      );

      await _scroll(tester, -200);

      expect(_topOf(tester, 'toolbar'), 100);
    });

    testWidgets('holds a bar at the floor its minHeight states', (
      tester,
    ) async {
      // A bar of variable content that still keeps a target of its own: 40 of content in a box
      // that says 96 is 96 tall, and the slot follows the box rather than the content.
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          core.Box(
            key: 'toolbar',
            pin: core.BoxPin.start,
            minHeight: 96,
            children: const <core.UINode>[core.Box(width: 200, height: 40)],
          ),
          _bar('results', height: 600),
        ]),
      );

      expect(_topOf(tester, 'results'), 96);
    });

    testWidgets('draws a bar in the flow when no box in the tree scrolls', (
      tester,
    ) async {
      // The one documented asymmetry: the web pins a bar at the top of a page to the
      // document, and the surface an application is drawn on does not scroll.
      await pumpNode(
        tester,
        core.Box(
          key: 'viewport',
          width: 300,
          height: 400,
          children: <core.UINode>[
            _bar('header', height: 100),
            _bar('toolbar', height: 60, pin: core.BoxPin.start),
          ],
        ),
      );

      expect(_topOf(tester, 'toolbar'), 100);
      expect(inNode(find.byType(SingleChildScrollView)), findsNothing);
    });

    testWidgets('gives a bar the width its cross alignment asks for', (
      tester,
    ) async {
      await pumpNode(
        tester,
        core.Box(
          key: 'viewport',
          width: 300,
          height: 400,
          overflow: core.Overflow.scroll,
          crossAlign: core.CrossAlign.center,
          children: <core.UINode>[
            _bar('bar', height: 60, width: 100, pin: core.BoxPin.start),
            _bar('results', height: 600),
          ],
        ),
      );

      await _scroll(tester, 200);

      // The layer that carries the bar is the width of the viewport; the bar inside it is
      // the width the box states, placed by the box's alignment — which is what a flex item
      // in a centred column is, so the two targets give the bar the same rectangle.
      expect(
        tester.getSize(find.byKey(const ValueKey<Object>('bar'))).width,
        100,
      );
      expect(_leftOf(tester, 'bar'), 100);
    });

    testWidgets('leaves a box without a pin in a plain scroll view', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _bar('top', height: 100),
          _bar('list', height: 600),
        ]),
      );

      // A pin is what adds the layer over the viewport; a box that states none keeps the
      // layout it always had, so an existing tree is drawn exactly as before.
      expect(inNode(find.byType(SingleChildScrollView)), findsOneWidget);
      expect(inNode(find.byType(CustomScrollView)), findsNothing);
    });
  });
}
