@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:web/web.dart' as web;

import 'support/document.dart';

/// How wide a browser makes the shares of a segmented button.
///
/// The tree states the rule — a grid with one column per segment — and only a browser
/// resolves it:
/// a track that is as wide as the widest segment when the pill has no width to divide,
/// and an equal part of the width when it has one. The numbers a reader meets are layout,
/// so they are read back off the elements rather than off the stylesheet.
void main() {
  /// The [index]th child element of [parent].
  web.Element child(web.Element parent, [int index = 0]) =>
      parent.children.item(index)!;

  /// Two labels of visibly different lengths: the case a hugging pill got wrong.
  const List<MaterialSegment> uneven = <MaterialSegment>[
    MaterialSegment(label: core.TextNode('Rent')),
    MaterialSegment(label: core.TextNode('Buy for good')),
  ];

  MaterialSegmentedButton pill({
    List<MaterialSegment> segments = uneven,
    double? width,
  }) => MaterialSegmentedButton(
    width: width,
    showSelectedIcon: false,
    segments: segments,
    selected: 0,
    onSelect: (int index) {},
  );

  /// The pill a [view] of one control drew: the root element's only child.
  web.Element controlOf(DomView view) => child(view.element);

  /// The row of shares inside that pill, which is the grid the segments sit in.
  web.Element rowOf(DomView view) => child(controlOf(view));

  /// The widths of the segments of [view]'s pill, in reading order.
  List<double> sharesOf(DomView view) {
    final web.Element row = rowOf(view);

    return <double>[
      for (int i = 0; i < row.children.length; i++)
        child(row, i).getBoundingClientRect().width,
    ];
  }

  test('shrinks every share equally when the room is narrower', () {
    // 100 pixels for a pill whose shares want more than that: the two shares divide what
    // is there and stay equal. Measured before the fix the same pill was 137 and 109 wide
    // — a small button beside a large one inside a single control.
    final DomView view = DomView.mount(
      core.Box(width: 100, children: <core.UINode>[pill()]),
      host(),
      theme: MaterialPalette.lightTheme,
    );
    final List<double> shares = sharesOf(view);
    final web.DOMRect control = controlOf(view).getBoundingClientRect();

    expect(control.width, 100);
    expect(shares, hasLength(2));
    expect(shares.first, closeTo(shares.last, 0.01));
    expect(
      shares.first,
      closeTo((control.width - 2) / 2, 1),
      reason: 'the two shares and the frame either side are the pill',
    );

    view.dispose();
  });

  test('hugs at twice its widest segment when it has no width', () {
    // The consumer's shape: a pill with no width of its own, in a row that scrolls along
    // the axis the pill would otherwise have filled. The widest label and the room each
    // side of it set the share, and the pill is two of those.
    final DomView view = DomView.mount(
      core.Box(
        direction: core.Axis.horizontal,
        overflow: core.Overflow.scroll,
        children: <core.UINode>[pill()],
      ),
      host(),
      theme: MaterialPalette.lightTheme,
    );
    final List<double> shares = sharesOf(view);
    final web.DOMRect control = controlOf(view).getBoundingClientRect();

    expect(shares.first, closeTo(shares.last, 0.01));
    expect(
      control.width,
      closeTo(2 * shares.first + 2, 1),
      reason:
          'the pill is the count times the share, and the frame around them',
    );

    view.dispose();
  });

  test('divides a width it was given equally', () {
    final DomView view = DomView.mount(
      core.Box(
        direction: core.Axis.horizontal,
        children: <core.UINode>[pill(width: 216)],
      ),
      host(),
      theme: MaterialPalette.lightTheme,
    );
    final List<double> shares = sharesOf(view);

    expect(shares, hasLength(2));
    expect(shares.first, closeTo(shares.last, 0.01));
    expect(
      shares.first,
      closeTo(107, 1),
      reason: '216, less the frame, in two',
    );

    view.dispose();
  });
}
