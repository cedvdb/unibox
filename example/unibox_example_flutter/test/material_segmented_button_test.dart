import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A segmented button is a box around a well, and a well is a box around a layer.
///
/// The label therefore sits where the box's alignment says, not at the top of the
/// layer: the browser centres the layer in the pill, and Flutter put the label at the
/// top of it until the stack learned to read the pair. Two targets, one pill.
void main() {
  /// Renders [node] where the test can measure it, and returns the pill's rectangle.
  Future<Rect> pumpControl(WidgetTester tester, core.UINode node) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: renderFlutter(node, theme: MaterialPalette.lightTheme),
          ),
        ),
      ),
    );

    return tester.getRect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FlutterBox && widget.box is MaterialSegmentedButton,
      ),
    );
  }

  /// A pill of [segments], optionally given a width, inside a box [parentWidth] wide.
  core.UINode pill(
    List<MaterialSegment> segments, {
    double? width,
    double parentWidth = 250,
  }) => core.Box(
    width: parentWidth,
    children: <core.UINode>[
      MaterialSegmentedButton(
        width: width,
        showSelectedIcon: false,
        segments: segments,
        selected: 0,
        onSelect: (int index) {},
      ),
    ],
  );

  /// Two labels of visibly different lengths: the case a hugging pill got wrong.
  const List<MaterialSegment> uneven = <MaterialSegment>[
    MaterialSegment(label: core.TextNode('Rent')),
    MaterialSegment(label: core.TextNode('Buy for good')),
  ];

  testWidgets('keeps the line of the pill out of its segments', (
    WidgetTester tester,
  ) async {
    final Finder control = find.byWidgetPredicate(
      (Widget widget) =>
          widget is FlutterBox && widget.box is MaterialSegmentedButton,
    );

    final Rect pill = await pumpControl(
      tester,
      MaterialSegmentedButton(
        width: 216,
        showSelectedIcon: false,
        segments: const <MaterialSegment>[
          MaterialSegment(label: core.TextNode('List')),
          MaterialSegment(label: core.TextNode('Grid')),
        ],
        selected: 0,
        onSelect: (int index) {},
      ),
    );
    final Path clip = tester
        .widget<ClipPath>(
          find.descendant(of: control, matching: find.byType(ClipPath)).first,
        )
        .clipper!
        .getClip(pill.size);

    // The pill hides what leaves it, and it hides it inside its line, which is where a
    // browser cuts the overflow of a bordered box: the chosen segment's fill stops at the
    // outline and the tint of a hover stops there too. Flutter cut the whole box, so the
    // chosen segment covered the line where it met it — the outline Material's own
    // segmented button keeps around a chosen segment.
    expect(
      clip.getBounds(),
      Rect.fromLTRB(1, 1, pill.width - 1, pill.height - 1),
    );
  });

  testWidgets('centres every label in its segment, like the browser', (
    WidgetTester tester,
  ) async {
    final Rect control = await pumpControl(
      tester,
      MaterialSegmentedButton(
        width: 216,
        showSelectedIcon: false,
        segments: const <MaterialSegment>[
          MaterialSegment(label: core.TextNode('List')),
          MaterialSegment(label: core.TextNode('Grid')),
        ],
        selected: 0,
        onSelect: (int index) {},
      ),
    );
    final Rect list = tester.getRect(find.text('List'));
    final Rect grid = tester.getRect(find.text('Grid'));

    expect(
      control.size,
      const Size(216, MaterialSegmentedButton.controlHeight),
    );

    // A 40 pixel pill with a 20 pixel label line: ten above and ten below, which is
    // where `justify-content: center` puts it on the web.
    expect(list.center.dy, closeTo(control.center.dy, 0.5));
    expect(grid.center.dy, closeTo(control.center.dy, 0.5));

    // Two equal shares of the 216 the pill was given — 108 each — and each label in the
    // middle of its own share. The rule between them is painted inside the second share
    // rather than laid out between the two, so it takes no room from either.
    expect(list.center.dx, closeTo(control.left + 54, 0.5));
    expect(grid.center.dx, closeTo(control.left + 162, 0.5));
  });

  testWidgets('gives two labels of different lengths two equal segments', (
    WidgetTester tester,
  ) async {
    // The bug this pins: a pill with no width used to size each segment to its own label,
    // so "Rent" beside "Buy for good" was a small button and a large one inside a single
    // control. Before the fix the two shares of a 250 pixel pill were 137 and 109 wide.
    final Rect control = await pumpControl(tester, pill(uneven));
    final Rect rent = tester.getRect(find.text('Rent'));
    final Rect buy = tester.getRect(find.text('Buy for good'));

    // The pill is the width its parent gave it, and the shares divide it equally: the
    // long label sits as far from the end as the short one sits from the start.
    expect(control.width, 250);
    expect(
      rent.center.dx - control.left,
      closeTo(control.right - buy.center.dx, 0.5),
      reason: 'each label is centred in a share of the same width',
    );
  });

  testWidgets('hugs its shares when it is given no width', (
    WidgetTester tester,
  ) async {
    // The consumer's shape: a control with no width of its own, in a row that scrolls
    // along the axis the control would fill. Nothing hands it a width to divide, so it
    // measures its widest segment and is two of those.
    final Rect control = await pumpControl(
      tester,
      core.Box(
        direction: core.Axis.horizontal,
        overflow: core.Overflow.scroll,
        children: <core.UINode>[
          MaterialSegmentedButton(
            showSelectedIcon: false,
            segments: uneven,
            selected: 0,
            onSelect: (int index) {},
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);

    final Rect rent = tester.getRect(find.text('Rent'));
    final Rect buy = tester.getRect(find.text('Buy for good'));

    expect(control.height, MaterialSegmentedButton.controlHeight);

    // Two shares of 193.2 — the widest label and the 12 pixels of room each side of it —
    // so the pill is 386.4 wide and the short label sits in the middle of a share it did
    // not have to pay for.
    expect(control.width, closeTo(2 * (buy.width + 24), 0.5));
    expect(rent.center.dx - control.left, closeTo(96.6, 0.5));
    expect(buy.center.dx - control.left, closeTo(289.8, 0.5));
  });

  testWidgets('shrinks every share equally when the room is narrower', (
    WidgetTester tester,
  ) async {
    // A parent narrower than `count × widest`: the shares divide the 100 rather than
    // overhanging it, and they stay equal, so the long label is cut rather than the short
    // one being made to pay for it.
    final Rect control = await pumpControl(
      tester,
      pill(uneven, parentWidth: 100),
    );
    final Rect rent = tester.getRect(find.text('Rent'));
    final Rect buy = tester.getRect(find.text('Buy for good'));

    expect(control.width, 100);
    expect(rent.center.dx - control.left, closeTo(25, 0.5));
    expect(buy.center.dx - control.left, closeTo(75, 0.5));
  });

  testWidgets('divides a width it was given between the shares', (
    WidgetTester tester,
  ) async {
    final Rect control = await pumpControl(
      tester,
      MaterialSegmentedButton(
        width: 216,
        showSelectedIcon: false,
        segments: uneven,
        selected: 0,
        onSelect: (int index) {},
      ),
    );
    final Rect rent = tester.getRect(find.text('Rent'));
    final Rect buy = tester.getRect(find.text('Buy for good'));

    // 216 divided two ways is 108 each, whatever the labels are.
    expect(control.width, 216);
    expect(rent.center.dx - control.left, closeTo(54, 0.5));
    expect(buy.center.dx - control.left, closeTo(162, 0.5));
  });

  testWidgets('cuts a label that is longer than its share, at any text scale', (
    WidgetTester tester,
  ) async {
    // "Salle de réunion" in a 168 pixel control: 59.5 pixels of room in a segment of
    // 83.5, which the label does not fit at either scale. Before the label was given a
    // width to be cut at, the row laid it out at its own width and Flutter raised
    // `A RenderFlex overflowed by 150 pixels on the right` — a translation, or any
    // label at a larger text scale, failing a build rather than reading short.
    for (final double scale in <double>[1, 2]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: renderFlutter(
                  MaterialSegmentedButton(
                    width: 168,
                    showSelectedIcon: false,
                    segments: const <MaterialSegment>[
                      MaterialSegment(label: core.TextNode('Salle de réunion')),
                      MaterialSegment(label: core.TextNode('Salon')),
                    ],
                    selected: 1,
                    onSelect: (int index) {},
                  ),
                  theme: MaterialPalette.lightTheme,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull, reason: 'at a scale of $scale');

      final Rect control = tester.getRect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is FlutterBox && widget.box is MaterialSegmentedButton,
        ),
      );
      final Finder label = find.text('Salle de réunion');
      final Rect cut = tester.getRect(label);
      final Text text = tester.widget<Text>(label);

      // One line, ellipsised, and drawn inside the share it was given rather than over
      // the segment beside it.
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(cut.right, lessThanOrEqualTo(control.center.dx));
      expect(cut.left, greaterThanOrEqualTo(control.left + 12));
      expect(cut.width, lessThan(control.width / 2));
    }
  });

  testWidgets('paints the line it is given, around and between its segments', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: renderFlutter(
              MaterialSegmentedButton(
                width: 216,
                showSelectedIcon: false,
                // Material's own SegmentedButton draws this control with the quieter
                // outline variant; before the line was a parameter, a themed
                // application could not say so.
                border: const core.BoxBorder(
                  color: core.BoxColor.role(MaterialColorRole.outlineVariant),
                ),
                segments: const <MaterialSegment>[
                  MaterialSegment(label: core.TextNode('List')),
                  MaterialSegment(label: core.TextNode('Grid')),
                ],
                selected: 0,
                onSelect: (int index) {},
              ),
              theme: MaterialPalette.lightTheme,
            ),
          ),
        ),
      ),
    );

    final Finder control = find.byWidgetPredicate(
      (Widget widget) =>
          widget is FlutterBox && widget.box is MaterialSegmentedButton,
    );
    final BoxDecoration decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: control,
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;

    // The role resolved through the theme the renderer was given, which is
    // `MaterialPalette.light.outlineVariant`.
    expect(decoration.border, Border.all(color: const Color(0xFFCAC4D0)));
  });
}
