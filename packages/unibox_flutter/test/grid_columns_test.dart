import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// A grid that states its columns, measured: what a segmented button is built on.
///
/// The grid measures each child at its max content and lays every column out at its factor,
/// which is Flutter's own arithmetic for a segmented control; a browser reaches the same
/// answer with `grid-template-columns: repeat(n, minmax(0, 1fr))`. The difference the old
/// hugging rule produced is the reason the form exists: two labels of different lengths used
/// to be two widths.
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

  /// Two columns of one factor each: equal widths, whatever the labels say.
  const core.GridNode uneven = core.GridNode.columns(
    <int>[1, 1],
    children: <core.UINode>[
      core.Box(children: <core.UINode>[core.TextNode('Rent')]),
      core.Box(children: <core.UINode>[core.TextNode('Buy for good')]),
    ],
  );

  /// Pumps [node] into a row that scrolls, which hands it no width at all.
  Future<void> pumpUnbounded(WidgetTester tester, core.UINode node) =>
      pumpAtWidth(
        tester,
        core.Box(
          direction: core.Axis.horizontal,
          overflow: core.Overflow.scroll,
          children: <core.UINode>[node],
        ),
        800,
      );

  testWidgets('measures its columns when nothing hands it a width', (
    WidgetTester tester,
  ) async {
    // No width to divide, so the grid measures: the widest child sets the column and the
    // row hugs at the count of them.
    await pumpUnbounded(tester, uneven);

    final Rect first = tester.getRect(find.byType(Expanded).at(0));
    final Rect second = tester.getRect(find.byType(Expanded).at(1));
    final double rent = tester.getRect(find.text('Rent')).width;

    expect(first.width, closeTo(second.width, 0.01));
    expect(
      first.width,
      greaterThan(rent),
      reason: 'the short label fills a column the long one set, rather than hugging',
    );
    expect(
      tester.getSize(find.byKey(nodeKey)).width,
      closeTo(first.width + second.width, 0.01),
      reason: 'the row hugs at the count of its columns',
    );
  });

  testWidgets('divides the width it was given between the columns', (
    WidgetTester tester,
  ) async {
    await pumpAtWidth(
      tester,
      const core.Box(
        width: 300,
        // A box hands its width to a row that is stretched across it, as a column does; the
        // row divides what it is given and hugs what it is not.
        crossAlign: core.CrossAlign.stretch,
        children: <core.UINode>[
          core.GridNode.columns(
            <int>[1, 1, 1],
            children: <core.UINode>[
              core.Box(children: <core.UINode>[core.TextNode('Day')]),
              core.Box(children: <core.UINode>[core.TextNode('Week')]),
              core.Box(children: <core.UINode>[core.TextNode('Month')]),
            ],
          ),
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

  testWidgets('gives a column twice the width for twice its factor', (
    WidgetTester tester,
  ) async {
    // `1fr 2fr 1fr`, measured rather than divided: the unit is the widest content per
    // factor, so the middle column is two of it and the row is four.
    await pumpUnbounded(
      tester,
      const core.GridNode.columns(
        <int>[1, 2, 1],
        children: <core.UINode>[
          core.Box(children: <core.UINode>[core.TextNode('Day')]),
          core.Box(children: <core.UINode>[core.TextNode('Weekend')]),
          core.Box(children: <core.UINode>[core.TextNode('Month')]),
        ],
      ),
    );

    final double first = tester.getRect(find.byType(Expanded).at(0)).width;
    final double middle = tester.getRect(find.byType(Expanded).at(1)).width;
    final double last = tester.getRect(find.byType(Expanded).at(2)).width;

    expect(middle, closeTo(2 * first, 0.01));
    expect(last, closeTo(first, 0.01));
    expect(
      tester.getSize(find.byKey(nodeKey)).width,
      closeTo(first + middle + last, 0.01),
      reason:
          'the row is the sum of its factors, times the unit the content set',
    );
  });

  testWidgets('shrinks every column into a parent too narrow for them', (
    WidgetTester tester,
  ) async {
    // The widest label wants more room than the parent has: each column is an equal part of
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

  testWidgets('leaves a child the width does not draw out of the columns', (
    WidgetTester tester,
  ) async {
    // `display: none` removes a grid item in a browser, and a hidden box keeps no column
    // here either: the two visible children divide the row between them.
    await pumpAtWidth(
      tester,
      const core.Box(
        width: 200,
        crossAlign: core.CrossAlign.stretch,
        children: <core.UINode>[
          core.GridNode.columns(
            <int>[1, 1, 1],
            children: <core.UINode>[
              core.Box(children: <core.UINode>[core.TextNode('Day')]),
              core.Box(
                visibleFrom: 900,
                children: <core.UINode>[core.TextNode('Week')],
              ),
              core.Box(children: <core.UINode>[core.TextNode('Month')]),
            ],
          ),
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
