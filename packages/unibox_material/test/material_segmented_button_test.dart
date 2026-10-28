import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _select(int index) {}

/// The three choices a segmented button is usually given.
const List<MaterialSegment> _segments = <MaterialSegment>[
  MaterialSegment(label: TextNode('Day')),
  MaterialSegment(label: TextNode('Week')),
  MaterialSegment(label: TextNode('Month')),
];

void main() {
  group('MaterialSegmentedButton', () {
    test('is one rounded container of equal segments and dividers', () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: _segments,
        selected: 1,
        onSelect: _select,
      );

      expect(button, isA<Box>());
      expect(button.height, MaterialSegmentedButton.controlHeight);
      expect(button.borderRadius, MaterialSegmentedButton.radius);
      expect(button.direction, Axis.horizontal);
      expect(
        button.overflow,
        Overflow.hidden,
        reason: 'the fill of a chosen segment is cut to the rounded ends',
      );
      // Three segments and the two rules between them.
      expect(button.children, hasLength(5));
      expect(button.children[1], isA<Box>());
      expect((button.children[1] as Box).width, 1);
    });

    test('gives every segment an equal share', () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: _segments,
        selected: 0,
        onSelect: _select,
      );

      for (final UINode child in <UINode>[
        button.children.first,
        button.children[2],
        button.children.last,
      ]) {
        expect((child as Box).flex, 1);
      }
    });

    test('fills the chosen segment with the secondary container', () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: _segments,
        selected: 2,
        onSelect: _select,
      );

      final List<Box> segments = <Box>[
        for (final UINode child in button.children)
          if (child is Box && child.width != 1) child,
      ];

      expect(segments, hasLength(3));
      expect(
        segments.map((Box segment) => segment.backgroundColor).toList(),
        <BoxColor?>[
          null,
          null,
          const BoxColor.role(MaterialColorRole.secondaryContainer),
        ],
      );
    });

    test('makes a button of every segment, and says which is chosen', () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: _segments,
        selected: 0,
        onSelect: _select,
      );
      final List<BoxSemantics> semantics = <BoxSemantics>[
        for (final UINode child in button.children)
          if (child is Box && child.width != 1) _wellBox(child).semantics!,
      ];

      expect(semantics, hasLength(3));
      expect(
        semantics.map((BoxSemantics s) => s.role),
        everyElement(BoxRole.button),
      );
      expect(semantics.map((BoxSemantics s) => s.selected ?? false), <bool>[
        true,
        false,
        false,
      ]);
    });

    test('draws a tree the model can validate', () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: _segments,
        selected: 1,
        onSelect: _select,
      );

      expect(validateTree(button, theme: MaterialPalette.lightTheme), isEmpty);
    });
  });
}

/// The box the ink well of [segment] draws.
Box _wellBox(Box segment) {
  final MaterialInkWell well = segment.children.single as MaterialInkWell;
  final MaterialInkStore store = MaterialInkStore();
  final Box box = well.viewFor(store.state, store) as Box;
  store.dispose();

  return box;
}
