import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';
import 'package:unibox_material/unibox_material.dart';

/// What a segmented button becomes in a document.
///
/// The control is one flex row of boxes, so the browser lays it out with the same two
/// rules Flutter does: a segment that was given a width fills the share it was given, and
/// one that was not is as wide as its label. The first case is what puts the pill across
/// a grid cell; the second is what puts it in a row that scrolls, where a share of an
/// unbounded width is a contradiction rather than a measurement.
void main() {
  const List<MaterialSegment> segments = <MaterialSegment>[
    MaterialSegment(label: core.TextNode('List')),
    MaterialSegment(label: core.TextNode('Grid')),
  ];

  /// The control in the row a consumer puts it in: one that scrolls along the axis the
  /// button would otherwise have filled.
  String render(core.UINode node) => toHtml(
    core.Box(
      direction: core.Axis.horizontal,
      overflow: core.Overflow.scroll,
      children: <core.UINode>[node],
    ),
    theme: MaterialPalette.lightTheme,
  );

  MaterialSegmentedButton button({double? width}) => MaterialSegmentedButton(
    width: width,
    showSelectedIcon: false,
    segments: segments,
    selected: 0,
    onSelect: (int index) {},
  );

  group('a segmented button', () {
    test('fills a segment only when the button was given a width', () {
      expect(render(button(width: 216)), contains('width:100%'));
      expect(
        render(button()),
        isNot(contains('width:100%')),
        reason: 'a segment with no share to fill is as wide as its label',
      );
    });

    test('is the same 40 pixel pill either way', () {
      for (final String html in <String>[
        render(button()),
        render(button(width: 216)),
      ]) {
        expect(html, contains('height:40px'));
        expect(html, contains('border-radius:20px'));
        expect(html, contains('border-color:var(--unibox-color-outline)'));
        expect(html, contains('>List</span>'));
        expect(html, contains('>Grid</span>'));
      }
    });

    test('gives a label a width to be cut at, and one line to be cut on', () {
      final String html = render(
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
      );

      // The box around the label fills the share, so the text inside it has a width to
      // be measured against — which is the whole of why it can be cut instead of
      // pushing the segment wider.
      expect(html, contains('align-items:stretch'));
      // One line, centred in the room it was given, cut with an ellipsis.
      expect(html, contains('-webkit-line-clamp:1'));
      expect(html, contains('text-align:center'));
      expect(html, contains('Salle de réunion'));
    });

    test('paints the line it is given, around and between the segments', () {
      final String html = render(
        MaterialSegmentedButton(
          border: const core.BoxBorder(
            color: core.BoxColor.role(MaterialColorRole.outlineVariant),
          ),
          showSelectedIcon: false,
          segments: segments,
          selected: 0,
          onSelect: (int index) {},
        ),
      );

      expect(
        html,
        contains('border-color:var(--unibox-color-outline-variant)'),
      );
      expect(
        html,
        contains('background-color:var(--unibox-color-outline-variant)'),
        reason: 'the rule between two segments is the same line as the one around them',
      );
      expect(html, isNot(contains('var(--unibox-color-outline)')));
    });
  });
}
