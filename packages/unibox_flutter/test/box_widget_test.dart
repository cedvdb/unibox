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

    testWidgets('paints background, border, radius and shadow', (tester) async {
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
      expect(decoration.boxShadow, hasLength(1));
      expect(decoration.boxShadow!.single.blurRadius, 4);
      expect(decoration.boxShadow!.single.offset, const Offset(0, 2));
    });

    testWidgets('skips invisible borders', (tester) async {
      await pumpNode(
        tester,
        const core.Box(width: 10, height: 10, border: core.BoxBorder.none()),
      );

      expect(decorationOf(tester), isNull);
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
