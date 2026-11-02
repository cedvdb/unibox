import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// The viewport every test scrolls: 300 by 400, with the children it is given.
core.Box _viewport(List<core.UINode> children) => core.Box(
  key: 'viewport',
  width: 300,
  height: 400,
  overflow: core.Overflow.scroll,
  children: children,
);

/// A box of the test tree, keyed so a test can ask where it ended up.
core.Box _box(
  String key, {
  double? width,
  double? height,
  core.Axis? direction,
  core.BoxPin? pin,
  double? pinOffset,
  VoidCallback? onTap,
  List<core.UINode> children = const <core.UINode>[],
}) {
  return core.Box(
    key: key,
    width: width,
    height: height,
    direction: direction,
    pin: pin,
    pinOffset: pinOffset,
    onTap: onTap,
    children: children,
  );
}

/// A pinned box whose face carries [key].
///
/// A nested pin is painted where the scroll puts it and never laid out again, so the rectangle
/// a test can read is the one its content is drawn at: the box that holds the pin reports the
/// slot the flow keeps for it, which is where it was and not where it is.
core.Box _panel(
  String key, {
  double width = 100,
  double height = 100,
  core.BoxPin? pin = core.BoxPin.start,
  double? pinOffset,
  VoidCallback? onTap,
}) => core.Box(
  width: width,
  height: height,
  pin: pin,
  pinOffset: pinOffset,
  onTap: onTap,
  children: <core.UINode>[core.Box(key: key, height: height)],
);

/// The distance from the top of the viewport to the top of [key], which is the only
/// position a pin is about.
double _topOf(WidgetTester tester, String key) =>
    tester.getTopLeft(find.byKey(ValueKey<Object>(key))).dy -
    tester.getTopLeft(find.byKey(const ValueKey<Object>('viewport'))).dy;

/// The distance from the left edge of the viewport to the left edge of [key].
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

// A page that owns its scroll, with a panel in the flow of a box below it — the shape a results
// page needs when the map has to sit beside the cards and still leave with them. The box around
// the panel is 600 tall in a 1400-tall page, so where the panel stops is a number the parent
// decides and not the page.
core.Box _columnPage() => _viewport(<core.UINode>[
  _box('hero', height: 400),
  _box(
    'row',
    height: 600,
    children: <core.UINode>[_panel('panel'), _box('list', height: 500)],
  ),
  _box('footer', height: 400),
]);

void main() {
  group('a pin inside a box the viewport scrolls', () {
    testWidgets(
      'rests at the top of the box it is in and leaves with that box',
      (tester) async {
        await pumpNode(tester, _columnPage());

        // At rest the panel is where the flow put it: the slot it keeps is its own height, so
        // the list below it starts under it.
        expect(_topOf(tester, 'panel'), 400);
        expect(_topOf(tester, 'list'), 500);

        await _scroll(tester, 500);

        // The hero has left and the panel is at the top of the viewport — a pin the viewport's
        // own layer did not draw, held at the edge the scroll names.
        expect(_topOf(tester, 'panel'), 0);
        expect(
          _topOf(tester, 'list'),
          0,
          reason: 'the list moves with the scroll: the panel kept its slot',
        );

        await _scroll(tester, 200);

        // Still pinned, and still above the list that is scrolling under it.
        expect(_topOf(tester, 'panel'), 0);
        expect(_topOf(tester, 'list'), -200);

        await _scroll(tester, 250);

        // 950 of the page has gone: the row's bottom edge is 50 from the top of the viewport,
        // so the panel stops 50 above it and its own bottom is the row's bottom. A pin drawn at
        // the edge of the viewport alone would still be at 0 here.
        expect(_topOf(tester, 'panel'), -50);
      },
    );

    testWidgets('leaves with the box it is in when that box leaves', (
      tester,
    ) async {
      await pumpNode(tester, _columnPage());

      await _scroll(tester, 1000);

      // The end of the scroll: the row has gone past the top of the viewport, so the panel
      // has gone with it rather than staying behind at the top of the page.
      expect(_topOf(tester, 'panel'), -100);
    });

    testWidgets(
      'pins a panel beside a column of cards without moving it across',
      (tester) async {
        await pumpNode(
          tester,
          _viewport(<core.UINode>[
            _box(
              'row',
              height: 600,
              direction: core.Axis.horizontal,
              children: <core.UINode>[
                _box('cards', width: 100, height: 600),
                _panel('panel'),
              ],
            ),
            _box('footer', height: 400),
          ]),
        );

        // A pin holds a vertical edge, so the panel stays where its parent put it sideways.
        expect(_leftOf(tester, 'panel'), 100);

        await _scroll(tester, 200);

        expect(_topOf(tester, 'panel'), 0);
        expect(_leftOf(tester, 'panel'), 100);

        await _scroll(tester, 350);

        // The cards are 50 from the top of the viewport and the panel leaves with their box.
        expect(_topOf(tester, 'panel'), -50);
      },
    );
    testWidgets(
      'keeps the inset it is given, beside a bar the viewport draws',
      (tester) async {
        await pumpNode(
          tester,
          _viewport(<core.UINode>[
            _box('bar', height: 48, pin: core.BoxPin.start),
            _box(
              'row',
              height: 500,
              children: <core.UINode>[
                _panel('panel', pinOffset: 48),
                _box('list', height: 400),
              ],
            ),
            _box('footer', height: 400),
          ]),
        );

        await _scroll(tester, 300);

        // Two pins in one viewport: the bar is drawn by the viewport's own layer, the panel by
        // itself, and the panel's inset is measured from the viewport — not from the bar it is
        // not a child of.
        expect(_topOf(tester, 'bar'), 0);
        expect(_topOf(tester, 'panel'), 48);

        await _scroll(tester, 200);

        // The bar stays with the page; the panel leaves with its own box.
        expect(_topOf(tester, 'bar'), 0);
        expect(_topOf(tester, 'panel'), -52);
      },
    );

    testWidgets('is pressed where it is painted', (tester) async {
      int panelPresses = 0;
      int listPresses = 0;

      await pumpNode(
        tester,
        _viewport(<core.UINode>[
          _box('hero', height: 400),
          _box(
            'row',
            height: 600,
            children: <core.UINode>[
              _panel('panel', onTap: () => panelPresses++),
              // Shorter than the box around it, so the panel is painted over nothing but the
              // box's own empty room: a pin paints in the order its parent drew it, and a
              // later sibling that overlapped it would be the one a press found.
              _box('list', height: 300, onTap: () => listPresses++),
            ],
          ),
          _box('footer', height: 400),
        ]),
      );

      await _scroll(tester, 700);

      // The panel's slot is 700 above the viewport by now, and the press is at the place it is
      // painted: a rectangle that moved has to move for the pointer as well.
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey<Object>('panel'))),
      );
      await tester.pump();

      expect(panelPresses, 1);
      expect(listPresses, 0);
    });

    testWidgets('follows a scroll view the tree does not own', (tester) async {
      // The host's own `ListView` is a viewport above the tree, and the pin reads its edge the
      // same way: the geometry comes from the nearest viewport and the nearest box, not from a
      // box the tree happens to know about.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListView(children: <Widget>[renderFlutter(_columnPage())]),
        ),
      );

      final Finder face = find.byKey(const ValueKey<Object>('panel'));

      expect(tester.getTopLeft(face).dy, 400);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(face).dy, 0);
    });

    testWidgets('is drawn in the flow when no box in the tree scrolls', (
      tester,
    ) async {
      // The one documented asymmetry, unchanged by how deep a pin sits: the surface an
      // application is drawn on has no viewport to pin to, so the box keeps its resting place.
      await pumpNode(
        tester,
        _box(
          'viewport',
          width: 300,
          height: 400,
          children: <core.UINode>[
            _box('hero', height: 100),
            _box('row', children: <core.UINode>[_panel('panel', height: 60)]),
          ],
        ),
      );

      expect(_topOf(tester, 'panel'), 100);
      expect(inNode(find.byType(SingleChildScrollView)), findsNothing);
    });
  });
}
