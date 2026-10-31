import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// A row of equal shares, measured: what a segmented button is built on.
///
/// The row measures each child at its max content and lays every share out at the widest,
/// which is Flutter's own arithmetic for a segmented control; a browser reaches the same
/// answer by equalising `fr` tracks. The difference the old hugging rule produced is the
/// reason the token exists: two labels of different lengths used to be two widths.
void main() {
  /// Pumps [node] into a box that offers at most [width] logical pixels.
  ///
  /// Loose, not tight: a box states its own width where it has one, and the case this
  /// pins is the room a parent offers rather than a size it imposes.
  Future<void> pumpAtWidth(
    WidgetTester tester,
    core.UINode node,
    double width,
  ) async {
    await pumpNode(
      tester,
      node,
      wrap: (Widget child) => Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: 600),
          child: child,
        ),
      ),
    );
  }

  const core.Box uneven = core.Box(
    direction: core.Axis.horizontal,
    equalShares: true,
    children: <core.UINode>[
      core.Box(children: <core.UINode>[core.TextNode('Rent')]),
      core.Box(children: <core.UINode>[core.TextNode('Buy for good')]),
    ],
  );

  testWidgets('makes every child as wide as the widest one', (
    WidgetTester tester,
  ) async {
    // No width to divide, so the row measures: the widest child sets the share and the row
    // hugs at the count of them.
    await pumpAtWidth(tester, uneven, 800);

    final Rect first = tester.getRect(find.byType(Expanded).at(0));
    final Rect second = tester.getRect(find.byType(Expanded).at(1));
    final double rent = tester.getRect(find.text('Rent')).width;

    expect(first.width, closeTo(second.width, 0.01));
    expect(
      first.width,
      greaterThan(rent),
      reason:
          'the short label fills a share the long one set, rather than hugging',
    );
    expect(
      tester.getSize(find.byKey(nodeKey)).width,
      closeTo(first.width + second.width, 0.01),
      reason: 'the row hugs at the count of its shares',
    );
  });

  testWidgets('divides the width it was given between the shares', (
    WidgetTester tester,
  ) async {
    await pumpAtWidth(
      tester,
      const core.Box(
        width: 300,
        direction: core.Axis.horizontal,
        equalShares: true,
        children: <core.UINode>[
          core.Box(children: <core.UINode>[core.TextNode('Day')]),
          core.Box(children: <core.UINode>[core.TextNode('Week')]),
          core.Box(children: <core.UINode>[core.TextNode('Month')]),
        ],
      ),
      800,
    );

    for (int index = 0; index < 3; index++) {
      expect(
        tester.getRect(find.byType(Expanded).at(index)).width,
        closeTo(100, 0.01),
      );
    }
  });

  testWidgets('shrinks every share into a parent too narrow for them', (
    WidgetTester tester,
  ) async {
    // The widest label wants more room than the parent has: each share is an equal part of
    // what is there, and the long label is cut rather than pushing the row wider.
    await pumpAtWidth(
      tester,
      const core.Box(
        width: 100,
        crossAlign: core.CrossAlign.stretch,
        children: <core.UINode>[uneven],
      ),
      800,
    );

    final Rect first = tester.getRect(find.byType(Expanded).at(0));
    final Rect second = tester.getRect(find.byType(Expanded).at(1));

    expect(first.width, closeTo(50, 0.01));
    expect(second.width, closeTo(50, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaves a child the width does not draw out of the shares', (
    WidgetTester tester,
  ) async {
    // `display: none` removes a grid item in a browser, and a hidden box keeps no share
    // here either: the two visible children divide the row between them.
    await pumpAtWidth(
      tester,
      const core.Box(
        width: 200,
        direction: core.Axis.horizontal,
        equalShares: true,
        children: <core.UINode>[
          core.Box(children: <core.UINode>[core.TextNode('Day')]),
          core.Box(
            visibleFrom: 900,
            children: <core.UINode>[core.TextNode('Week')],
          ),
          core.Box(children: <core.UINode>[core.TextNode('Month')]),
        ],
      ),
      500,
    );

    expect(find.text('Week'), findsNothing);
    expect(
      tester.getRect(find.byType(Expanded).at(0)).width,
      closeTo(100, 0.01),
    );
    expect(
      tester.getRect(find.byType(Expanded).at(1)).width,
      closeTo(100, 0.01),
    );
  });
}
