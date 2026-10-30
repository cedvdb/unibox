import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// A wrapping box: `Box(wrap: true)` lays its children out in runs, and the runs are the
/// same ones a browser makes with `flex-wrap: wrap`.
///
/// The width is the whole test. A wrap is the one layout whose answer depends on how much
/// room it was given, so every case here states a width and reads back where the children
/// landed — a count of runs, not a rendering.
void main() {
  group('a wrapping box', () {
    /// Six 40 pixel chips with 8 pixels of gap, in a [width] wide box.
    core.Box chips(double width) => core.Box(
      direction: core.Axis.horizontal,
      width: width,
      wrap: true,
      gap: 8,
      children: <core.UINode>[
        for (int i = 0; i < 6; i++) core.Box(key: i, width: 40, height: 40),
      ],
    );

    /// The rows the children of a wrapping box landed in, top to bottom.
    List<double> rows(WidgetTester tester) => <double>{
      for (int i = 0; i < 6; i++)
        tester.getRect(find.byKey(ValueKey<Object>(i))).top,
    }.toList();

    testWidgets('is a Wrap, and spaces its runs itself', (tester) async {
      await pumpNode(tester, chips(128));

      final Wrap wrap = tester.widget<Wrap>(
        inNode(find.byWidgetPredicate((Widget widget) => widget is Wrap)).first,
      );

      // The gap is the wrap's two numbers; a flex adds a SizedBox between children.
      expect(wrap.spacing, 8);
      expect(wrap.runSpacing, 8);
      expect(wrap.children, hasLength(6));
      expect(wrap.direction, Axis.horizontal);
      expect(
        wrap.children.whereType<SizedBox>(),
        isEmpty,
        reason: 'the gap is the wrap\'s, not a child between the boxes',
      );
    });

    testWidgets('breaks a run where the width runs out, like flex-wrap', (
      WidgetTester tester,
    ) async {
      // 128 fits two chips and their gap (40 + 8 + 40 = 88) and not a third (136), so
      // three runs of two — which is what `flex-wrap: wrap` lays out at 128.
      await pumpNode(tester, chips(128));

      final List<double> tops = rows(tester);
      final List<double> lefts = <double>[
        for (int i = 0; i < 6; i++)
          tester.getRect(find.byKey(ValueKey<Object>(i))).left,
      ];

      expect(tops, hasLength(3));
      // Two per run: the third chip starts a new line at the same left edge as the first.
      expect(lefts[2], closeTo(lefts[0], 0.5));
      expect(lefts[3], closeTo(lefts[1], 0.5));
      expect(lefts[0], lessThan(lefts[1]));
      // A 40 pixel chip on a 40 pixel line, with the 8 pixel gap between runs.
      expect(tops[1] - tops[0], closeTo(48, 0.5));
      expect(tops[2] - tops[1], closeTo(48, 0.5));
    });

    testWidgets('keeps one run when the width fits every child', (
      tester,
    ) async {
      await pumpNode(tester, chips(1000));

      expect(rows(tester), hasLength(1));
    });

    testWidgets('distributes one line, not the whole box', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          width: 128,
          wrap: true,
          gap: 8,
          mainAlign: core.MainAlign.spaceBetween,
          crossAlign: core.CrossAlign.center,
          children: <core.UINode>[
            core.Box(key: 'a', width: 40, height: 40),
            core.Box(key: 'b', width: 40, height: 20),
            core.Box(key: 'c', width: 40, height: 40),
          ],
        ),
      );

      final Wrap wrap = tester.widget<Wrap>(
        inNode(find.byWidgetPredicate((Widget widget) => widget is Wrap)).first,
      );

      // `mainAlign` is a run's distribution and `crossAlign` places a child in its line:
      // the two meanings `justify-content` and `align-items` keep inside `flex-wrap`.
      expect(wrap.alignment, WrapAlignment.spaceBetween);
      expect(wrap.crossAxisAlignment, WrapCrossAlignment.center);

      final Rect first = tester.getRect(
        find.byKey(const ValueKey<Object>('a')),
      );
      final Rect second = tester.getRect(
        find.byKey(const ValueKey<Object>('b')),
      );

      // A shorter child is centred in the line rather than stretched over it.
      expect(second.center.dy, closeTo(first.center.dy, 0.5));
      expect(second.height, 20);
    });

    testWidgets('wraps a column into columns when its height runs out', (
      WidgetTester tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 100,
          height: 88,
          wrap: true,
          gap: 8,
          children: <core.UINode>[
            core.Box(key: 'a', width: 40, height: 40),
            core.Box(key: 'b', width: 40, height: 40),
            core.Box(key: 'c', width: 40, height: 40),
          ],
        ),
      );

      // 40 + 8 + 40 = 88 exactly, so two children fill the first run and the third starts
      // a second one beside them.
      final Rect a = tester.getRect(find.byKey(const ValueKey<Object>('a')));
      final Rect c = tester.getRect(find.byKey(const ValueKey<Object>('c')));

      expect(c.left, closeTo(a.left + 48, 0.5));
      expect(c.top, closeTo(a.top, 0.5));
    });

    testWidgets('refuses a flexible child, which no line can share', (
      tester,
    ) async {
      // A `Wrap` has no flex children, and an `Expanded` inside one is a Flutter error.
      // Rather than draw one target's answer, the renderer reports the tree: a box that
      // states a share in a wrap is a construct no line can honour.
      await expectLater(
        pumpNode(
          tester,
          const core.Box(
            direction: core.Axis.horizontal,
            width: 100,
            wrap: true,
            children: <core.UINode>[core.Box(width: 40, height: 10, flex: 1)],
          ),
        ),
        throwsA(
          predicate<Object>((Object error) => '$error'.contains('wrap: true')),
        ),
      );
    });
  });
}
