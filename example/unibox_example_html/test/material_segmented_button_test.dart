import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';
import 'package:unibox_material/unibox_material.dart';

/// What a segmented button becomes in a document.
///
/// The control is one row whose children are equal shares of it, and the web's way of
/// saying that is a grid of auto-placed `1fr` columns: a browser gives every track the
/// widest child's max-content width when the grid has no width to divide, and an equal
/// part of the width when it has one. The Flutter renderer applies the same rule by
/// measuring the children, so the two targets equalise the same way.
void main() {
  const List<MaterialSegment> segments = <MaterialSegment>[
    MaterialSegment(label: core.TextNode('Rent')),
    MaterialSegment(label: core.TextNode('Buy for good')),
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

  /// The declarations of the class the pill itself wears.
  ///
  /// The document is a sheet of hashed classes, so the pill's own rule is found through
  /// the element that names it: a test about the layout of this control must not read the
  /// declarations of the boxes inside it.
  String pillDeclarations(String html) {
    final RegExpMatch element = RegExp(
      r'class="(unibox-box-[0-9a-f]+)" data-unibox-node="material-segmented-button"',
    ).firstMatch(html)!;
    final String name = RegExp.escape(element.group(1)!);

    return RegExp('\\.$name\\{([^}]*)\\}').firstMatch(html)!.group(1)!;
  }

  group('a segmented button', () {
    test('divides itself into equal shares, whatever the labels say', () {
      for (final String html in <String>[
        render(button()),
        render(button(width: 216)),
      ]) {
        // One grid, one track per child, each track an equal part of the row: the rule
        // that makes a two choice control two halves rather than two buttons. A grid has
        // no flex direction, and the shares are what say how the row is divided.
        final String pill = pillDeclarations(html);

        expect(pill, contains('display:grid'));
        expect(pill, contains('grid-auto-flow:column'));
        expect(pill, contains('grid-auto-columns:minmax(0, 1fr)'));
        expect(pill, isNot(contains('flex-direction')));

        // Every segment fills the share it is given, which is what puts the fill and the
        // tint across the whole segment rather than around its label.
        expect(html, contains('width:100%'));
      }
    });

    test('states a width on the pill, and none on a segment', () {
      // Without a width the grid is as wide as its tracks and hugs them; the width, when
      // there is one, belongs to the pill and is divided rather than handed to a segment.
      expect(render(button(width: 216)), contains('width:216px'));
      expect(
        render(button()),
        isNot(contains('width:216px')),
        reason: 'a pill with no width is as wide as its shares',
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
        expect(html, contains('>Rent</span>'));
        expect(html, contains('>Buy for good</span>'));
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
      // pushing the segment wider. A share is also the only width a label is given: the
      // widest one set the track, so a label is cut only by a parent narrower than them.
      expect(html, contains('align-items:stretch'));
      // One line, centred in the room it was given, cut with an ellipsis.
      expect(html, contains('-webkit-line-clamp:1'));
      expect(html, contains('text-align:center'));
      expect(html, contains('Salle de réunion'));
    });

    test('paints the rule at the start of the segment it opens', () {
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
        reason:
            'the rule inside a segment is the same line as the one around them',
      );
      expect(html, isNot(contains('var(--unibox-color-outline)')));
    });
  });
}
