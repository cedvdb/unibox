import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

void main() {
  group('Box layout', () {
    testWidgets('renders a flex container for an empty box', (tester) async {
      await pumpNode(tester, const core.Box());

      final Flex flex = rootFlex(tester);

      // Nothing is laid out, but the box is still a flex container: the web
      // renderer emits one for every box, and a box that skipped it here would
      // describe the same node differently on the two targets.
      expect(flex.children, isEmpty);
      expect(flex.direction, Axis.vertical);
      expect(tester.getSize(find.byKey(nodeKey)), Size.zero);
    });

    testWidgets('maps a horizontal direction to a Row', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          children: [core.Box(width: 20, height: 20), core.Box(width: 30)],
        ),
      );

      final Flex row = rootFlex(tester);

      expect(row.direction, Axis.horizontal);
      expect(row.children, hasLength(2));
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
      expect(row.crossAxisAlignment, CrossAxisAlignment.start);
      expect(row.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('packs a row from the side the words start on', (tester) async {
      // Arabic in a row is the same rectangle with the children packed from the other
      // side: one token, and not a second tree or a mirrored alignment.
      const Key first = ValueKey<Object>('first');

      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          writingDirection: core.WritingDirection.rtl,
          children: <core.UINode>[
            core.Box(key: 'first', width: 20, height: 20),
            core.Box(width: 60, height: 20),
          ],
        ),
      );

      // The box hugs its children and is 80 wide, so the first child of the row is the one
      // against its right edge.
      final double nodeLeft = tester.getTopLeft(find.byKey(nodeKey)).dx;

      expect(tester.getTopLeft(find.byKey(first)).dx - nodeLeft, 60);
    });

    testWidgets('adds no direction of its own when it states none', (
      tester,
    ) async {
      await pumpNode(tester, const core.Box());

      // The harness already wraps every node in an LTR `Directionality`; a box that says
      // nothing adds none, so the direction a tree inherits is the application's own.
      expect(inNode(find.byType(Directionality)), findsNothing);
    });

    testWidgets('maps a vertical direction to a Column', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.vertical,
          children: [core.Box(height: 20), core.Box(height: 30)],
        ),
      );

      final Flex column = rootFlex(tester);

      expect(column.direction, Axis.vertical);
      expect(column.children, hasLength(2));
    });

    testWidgets('lays children out in a Column without a direction', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          gap: 4,
          crossAlign: core.CrossAlign.center,
          children: [core.Box(height: 10), core.Box(height: 10)],
        ),
      );

      final Flex column = rootFlex(tester);

      expect(column.children, hasLength(3));
      expect((column.children[1] as SizedBox).height, 4);
      expect(column.mainAxisAlignment, MainAxisAlignment.start);
      expect(column.crossAxisAlignment, CrossAxisAlignment.center);
      expect(tester.getSize(find.byKey(nodeKey)).height, 24);
    });

    testWidgets('expands a flexible child without a direction', (tester) async {
      await pumpNode(
        tester,
        const core.Box(children: [core.Box(height: 10, flex: 2)]),
      );

      expect(tester.widget<Expanded>(find.byType(Expanded)).flex, 2);
    });

    testWidgets('inserts horizontal gap separators between children', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          gap: 8,
          children: [
            core.Box(width: 10, height: 10),
            core.Box(width: 10, height: 10),
            core.Box(width: 10, height: 10),
          ],
        ),
      );

      final Flex row = rootFlex(tester);

      expect(row.children, hasLength(5));
      expect((row.children[1] as SizedBox).width, 8);
      expect((row.children[3] as SizedBox).width, 8);
      expect(tester.getSize(find.byKey(nodeKey)).width, 46);
    });

    testWidgets('inserts vertical gap separators between children', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.vertical,
          gap: 4,
          children: [core.Box(height: 10), core.Box(height: 10)],
        ),
      );

      final Flex column = rootFlex(tester);

      expect(column.children, hasLength(3));
      expect((column.children[1] as SizedBox).height, 4);
      expect(tester.getSize(find.byKey(nodeKey)).height, 24);
    });

    testWidgets('maps main and cross alignment', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          mainAlign: core.MainAlign.spaceBetween,
          crossAlign: core.CrossAlign.center,
          children: [core.Box(width: 10, height: 10)],
        ),
      );

      final Flex row = rootFlex(tester);

      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(row.crossAxisAlignment, CrossAxisAlignment.center);
    });

    testWidgets('expands an infinite width child inside a Row', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          children: [
            core.Box(width: double.infinity),
            core.Box(width: 40, height: 20),
          ],
        ),
      );

      expect(tester.widget<Expanded>(find.byType(Expanded)).flex, 1);
      expect(
        tester.getSize(find.byKey(nodeKey)).width,
        tester.getSize(find.byType(Center)).width,
      );
    });

    testWidgets('honours the flex factor of a child', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          children: [core.Box(flex: 2), core.Box(flex: 1)],
        ),
      );

      final List<Expanded> expanded = tester
          .widgetList<Expanded>(find.byType(Expanded))
          .toList();

      expect(expanded.map((Expanded widget) => widget.flex), <int>[2, 1]);
    });
  });

  group('Box sizing', () {
    testWidgets('sizes the box from width and height', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 120,
          height: 40,
          backgroundColor: core.BoxColor.white,
        ),
      );

      expect(tester.getSize(find.byKey(nodeKey)), const Size(120, 40));
    });

    testWidgets('fills the available width for an infinite width', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(width: double.infinity, height: 10),
      );

      expect(
        tester.getSize(find.byKey(nodeKey)).width,
        tester.getSize(find.byType(Center)).width,
      );
    });

    testWidgets('centres a box that fills only up to a measure', (
      tester,
    ) async {
      // `width: 100%; max-width: 400px` in a centred row is 400 wide and 200 from either
      // edge — the shape every band of the site is. Expanded instead of the measure took the
      // whole line, and the 400 was left against the row's leading edge.
      const Key measure = ValueKey<Object>('measure');

      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          width: double.infinity,
          mainAlign: core.MainAlign.center,
          children: <core.UINode>[
            core.Box(key: 'measure', width: double.infinity, maxWidth: 400),
          ],
        ),
      );

      final double rowLeft = tester.getTopLeft(find.byKey(nodeKey)).dx;
      final Rect child = tester.getRect(find.byKey(measure));

      expect(child.width, 400);
      expect(child.left - rowLeft, 200);
    });

    testWidgets('honours min and max constraints', (tester) async {
      await pumpNode(
        tester,
        const core.Box(width: 500, maxWidth: 300, height: 20, minHeight: 30),
      );

      expect(tester.getSize(find.byKey(nodeKey)), const Size(300, 30));
    });

    testWidgets('reserves space for an empty constrained box', (tester) async {
      await pumpNode(tester, const core.Box(minWidth: 50, minHeight: 20));

      expect(tester.getSize(find.byKey(nodeKey)), const Size(50, 20));
    });

    testWidgets('applies padding and margin', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          padding: core.BoxSpacing.all(16),
          margin: core.BoxSpacing.symmetric(horizontal: 4, vertical: 2),
          children: [core.Box(width: 10, height: 10)],
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Padding && widget.padding == const EdgeInsets.all(16),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Padding &&
              widget.padding ==
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
        findsOneWidget,
      );
      // 10 content + 2 * 16 padding + 2 * 4 margin.
      expect(tester.getSize(find.byKey(nodeKey)).width, 50);
    });
  });

  group('Box visuals', () {
    testWidgets('paints nothing for a plain box', (tester) async {
      await pumpNode(tester, const core.Box(width: 10, height: 10));

      expect(decorationOf(tester), isNull);
    });

    testWidgets('paints background, border and radius', (tester) async {
      // The shadow this box also states is painted by the CSS-accurate painter beside the
      // fill, and `box_shadow_test.dart` reads the pixels: a decoration carrying a shadow
      // would be painted through a box that has no fill of its own.
      await pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 100,
          backgroundColor: core.BoxColor.white,
          borderRadius: 12,
          border: core.BoxBorder(width: 2, color: core.BoxColor.black),
          shadows: <core.BoxShadow>[core.BoxShadow()],
        ),
      );

      final BoxDecoration decoration = decorationOf(tester)!;
      final Border border = decoration.border! as Border;

      expect(decoration.color, const Color(0xFFFFFFFF));
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(border.top.width, 2);
      expect(border.top.color, const Color(0xFF000000));
    });

    testWidgets('skips invisible borders', (tester) async {
      await pumpNode(
        tester,
        const core.Box(width: 10, height: 10, border: core.BoxBorder.none()),
      );

      expect(decorationOf(tester), isNull);
    });

    testWidgets('cuts what it hides at the inside of its line', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 60,
          borderRadius: 10,
          border: core.BoxBorder(width: 2),
          overflow: core.Overflow.hidden,
          children: <core.UINode>[core.Box(height: 60)],
        ),
      );

      final Path clip = tester
          .widget<ClipPath>(inNode(find.byType(ClipPath)).first)
          .clipper!
          .getClip(const Size(100, 60));

      // A browser clips an element's overflow to its padding box, so a child that fills a
      // bordered box — the fill of a chosen segment, the tint of a hover — stops at the line
      // instead of painting over it. Flutter clipped the whole box, and the line was the
      // children's to cover.
      expect(clip.getBounds(), const Rect.fromLTRB(2, 2, 98, 58));
      // The corner is the inside of the border's: a radius of 10 less the 2 pixel line, so
      // the children are cut with the curve the line's inner edge has.
      expect(clip.contains(const Offset(3, 3)), isFalse);
      expect(clip.contains(const Offset(12, 3)), isTrue);
    });

    testWidgets('cuts nothing when it hides nothing or draws no line', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 60,
          border: core.BoxBorder(width: 2),
          children: <core.UINode>[core.Box(height: 60)],
        ),
      );

      // A box that hides nothing leaves its children alone, which is what a browser does
      // with a child that reaches over the line: the border paints below it.
      expect(inNode(find.byType(ClipPath)), findsNothing);
    });

    testWidgets('lets flat parameters override the style tokens', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 50,
          height: 50,
          styles: <core.BoxStyle>[
            core.BoxStyle(
              backgroundColor: core.BoxColor.white,
              borderRadius: 4,
            ),
          ],
          backgroundColor: core.BoxColor.black,
        ),
      );

      final BoxDecoration decoration = decorationOf(tester)!;

      expect(decoration.color, const Color(0xFF000000));
      expect(decoration.borderRadius, BorderRadius.circular(4));
    });
  });

  group('Box interactions', () {
    testWidgets('adds no gesture or mouse handling to a plain box', (
      tester,
    ) async {
      await pumpNode(tester, const core.Box(width: 10, height: 10));

      expect(inNode(find.byType(GestureDetector)), findsNothing);
      expect(inNode(find.byType(MouseRegion)), findsNothing);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var taps = 0;

      await pumpNode(
        tester,
        core.Box(
          width: 100,
          height: 40,
          backgroundColor: core.BoxColor.white,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.byKey(nodeKey));

      expect(taps, 1);
      expect(
        tester.widget<MouseRegion>(find.byType(MouseRegion)).cursor,
        SystemMouseCursors.click,
      );
    });

    testWidgets('fires onLongPress when long pressed', (tester) async {
      var presses = 0;

      await pumpNode(
        tester,
        core.Box(width: 100, height: 40, onLongPress: () => presses++),
      );

      await tester.longPress(find.byKey(nodeKey));

      expect(presses, 1);
    });

    testWidgets('swaps to the hover style while the pointer is inside', (
      tester,
    ) async {
      final List<bool> hovers = <bool>[];

      await pumpNode(
        tester,
        core.Box(
          width: 120,
          height: 60,
          backgroundColor: core.BoxColor.white,
          hoverStyle: const core.BoxStyle(backgroundColor: core.BoxColor.black),
          onHover: hovers.add,
        ),
      );

      expect(decorationOf(tester)!.color, const Color(0xFFFFFFFF));

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: const Offset(5, 5));
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byKey(nodeKey)));
      await tester.pumpAndSettle();

      expect(decorationOf(tester)!.color, const Color(0xFF000000));
      expect(hovers, <bool>[true]);

      await gesture.moveTo(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(decorationOf(tester)!.color, const Color(0xFFFFFFFF));
      expect(hovers, <bool>[true, false]);
    });
  });

  group('Box pointer capture', () {
    /// A control with a picture over its corner: the shape a badge is drawn in.
    core.UINode control({
      required bool? badgeTakesPointer,
      required void Function() onTap,
    }) => core.StackNode(
      width: 40,
      height: 40,
      children: <core.UINode>[
        core.Box(width: 40, height: 40, onTap: onTap),
        core.PositionedNode(
          alignment: core.BoxAlignment.topEnd,
          child: core.Box(
            width: 24,
            height: 24,
            capturesPointer: badgeTakesPointer,
            backgroundColor: core.BoxColor.white,
            children: <core.UINode>[const core.TextNode('3')],
          ),
        ),
      ],
    );

    testWidgets('lets a press through a decoration to the control under it', (
      tester,
    ) async {
      // A badge over a button holds a child, so left to itself it is the box a press lands
      // on — and the control under it never hears about the corner a thumb aims at first.
      var taps = 0;

      await pumpNode(
        tester,
        control(badgeTakesPointer: false, onTap: () => taps++),
      );

      await tester.tapAt(tester.getCenter(find.text('3')));

      expect(taps, 1);
    });

    testWidgets('takes the pointer when the box says it does', (tester) async {
      // The same tree without the token: the picture is a target of its own, which is the
      // behaviour the badge has to opt out of rather than the one it gets by accident.
      var taps = 0;

      await pumpNode(
        tester,
        control(badgeTakesPointer: null, onTap: () => taps++),
      );

      await tester.tapAt(tester.getCenter(find.text('3')));

      expect(taps, 0);
    });
  });

  group('Box overflow', () {
    testWidgets('clips overflowing content', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 50,
          height: 20,
          overflow: core.Overflow.hidden,
          children: [core.Box(width: 200, height: 10)],
        ),
      );

      expect(inNode(find.byType(ClipRect)), findsOneWidget);
      expect(tester.getSize(find.byKey(nodeKey)), const Size(50, 20));
    });

    testWidgets('clips a rounded box to its radius', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 50,
          height: 20,
          borderRadius: 12,
          overflow: core.Overflow.hidden,
          children: [core.Box(width: 200, height: 10)],
        ),
      );

      // A browser clips an element with `overflow` to its `border-radius`; a plain
      // ClipRect would cut square corners on one target only.
      expect(
        tester.widget<ClipRRect>(inNode(find.byType(ClipRRect))).borderRadius,
        BorderRadius.circular(12),
      );
      expect(inNode(find.byType(ClipRect)), findsNothing);
    });

    testWidgets('paints the shadow outside the clip it applies', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 50,
          height: 20,
          borderRadius: 12,
          overflow: core.Overflow.hidden,
          shadows: <core.BoxShadow>[
            core.BoxShadow(color: core.BoxColor.black, blurRadius: 6),
          ],
          children: [core.Box(width: 200, height: 10)],
        ),
      );

      // A browser cuts the content to the radius and never its own `box-shadow`,
      // which paints outside the border box: the decoration has to be the outer
      // widget, or a card with `overflow: hidden` is lifted on the web and flat here.
      final Finder decorated = inNode(find.byType(DecoratedBox));
      final Finder clip = inNode(find.byType(ClipRRect));

      expect(
        find.ancestor(of: clip, matching: decorated),
        findsOneWidget,
        reason:
            'the decoration wraps the clip, so its shadow paints outside it',
      );
      expect(
        (tester.widget<DecoratedBox>(decorated).decoration as BoxDecoration)
            .boxShadow,
        isNotNull,
      );
      expect(tester.getSize(find.byKey(nodeKey)), const Size(50, 20));
    });

    testWidgets('clips a rounded scrolling box to its radius', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          height: 100,
          borderRadius: 8,
          overflow: core.Overflow.scroll,
          children: [core.Box(width: 10, height: 400)],
        ),
      );

      expect(
        tester.widget<ClipRRect>(inNode(find.byType(ClipRRect))).borderRadius,
        BorderRadius.circular(8),
      );
    });

    testWidgets('scrolls overflowing content vertically', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          height: 100,
          overflow: core.Overflow.scroll,
          children: [core.Box(width: 10, height: 400)],
        ),
      );

      final SingleChildScrollView view = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );

      expect(view.scrollDirection, Axis.vertical);
      expect(tester.getSize(find.byKey(nodeKey)).height, 100);
      expect(inNode(find.byType(ClipRect)), findsNothing);
    });

    testWidgets('scrolls overflowing content along the box direction', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          height: 20,
          overflow: core.Overflow.scroll,
          children: [core.Box(width: 400, height: 10)],
        ),
      );

      final SingleChildScrollView view = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );

      expect(view.scrollDirection, Axis.horizontal);
    });

    testWidgets('settles on a child when it pages', (tester) async {
      // A pager is a scrolling box with paging physics: a drag that ends between two pages
      // comes to rest on one, which is the whole difference from a list.
      await pumpNode(
        tester,
        const core.Box(
          height: 100,
          overflow: core.Overflow.scroll,
          snap: core.ScrollSnap.page,
          children: <core.UINode>[
            core.Box(height: 100, minHeight: 100),
            core.Box(height: 100, minHeight: 100),
            core.Box(height: 100, minHeight: 100),
          ],
        ),
      );

      final SingleChildScrollView view = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(view.physics, isA<PageScrollPhysics>());

      // A drag of less than a page is enough: the physics finishes the move.
      await tester.drag(find.byKey(nodeKey), const Offset(0, -40));
      await tester.pumpAndSettle();

      final double offset = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
      expect(offset % 100, 0, reason: 'it came to rest on a page boundary');
    });

    testWidgets('reports how far its own content has scrolled', (tester) async {
      final List<double> offsets = <double>[];

      await pumpNode(
        tester,
        core.Box(
          height: 100,
          overflow: core.Overflow.scroll,
          onScroll: offsets.add,
          children: const <core.UINode>[core.Box(width: 10, height: 400)],
        ),
      );

      await tester.drag(find.byKey(nodeKey), const Offset(0, -60));
      await tester.pump();

      expect(offsets, isNotEmpty);
      expect(offsets.last, 60);
    });

    testWidgets('reports nothing for a scrollable nested inside it', (
      tester,
    ) async {
      // A nested scrollable is the nested box's scroll, not the outer one's: the outer
      // callback fires only for its own viewport, and its offset stays where it was.
      final List<double> outer = <double>[];
      final List<double> inner = <double>[];

      await pumpNode(
        tester,
        core.Box(
          height: 100,
          overflow: core.Overflow.scroll,
          onScroll: outer.add,
          children: <core.UINode>[
            core.Box(
              height: 100,
              overflow: core.Overflow.scroll,
              onScroll: inner.add,
              children: const <core.UINode>[core.Box(width: 10, height: 400)],
            ),
          ],
        ),
      );

      await tester.drag(
        inNode(find.byType(SingleChildScrollView).last),
        const Offset(0, -40),
      );
      await tester.pump();

      expect(inner, isNotEmpty);
      expect(
        outer,
        isEmpty,
        reason: 'the outer box did not scroll; the inner one did',
      );
    });
  });

  group('renderFlutter', () {
    testWidgets('toWidget renders the same widget tree', (tester) async {
      const core.Box node = core.Box(
        width: 30,
        height: 30,
        backgroundColor: core.BoxColor.black,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: node.toWidget()),
        ),
      );

      expect(tester.getSize(find.byType(DecoratedBox)), const Size(30, 30));
    });

    test('throws for nodes without a Flutter renderer', () {
      expect(() => renderFlutter(const _UnknownNode()), throwsUnsupportedError);
    });
  });
}

/// A node type no renderer knows about.
class _UnknownNode extends core.UINode {
  const _UnknownNode();
}
