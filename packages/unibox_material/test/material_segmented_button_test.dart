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

    test('shares a width equally, and lets a segment hug without one', () {
      MaterialSegmentedButton button({double? width}) =>
          MaterialSegmentedButton(
            segments: _segments,
            selected: 0,
            onSelect: _select,
            width: width,
          );

      for (final UINode child in <UINode>[
        button(width: 300).children.first,
        button(width: 300).children[2],
        button(width: 300).children.last,
      ]) {
        expect((child as Box).flex, 1);
      }

      // Without a width there is nothing to divide, and a `flex` in an unbounded row
      // is a layout error in Flutter: every segment hugs its label instead.
      expect((button().children.first as Box).flex, isNull);
      expect(button().width, isNull);
    });

    test('asks a segment to fill only a width it was given', () {
      // A segment that shares the button's width fills its share; one that hugs its
      // label has nothing to fill, and `double.infinity` there is a constraint with no
      // bound behind it — Flutter refuses it in an unbounded row, a horizontally
      // scrolling one included.
      final MaterialSegmentedButton shared = MaterialSegmentedButton(
        segments: _segments,
        selected: 0,
        onSelect: _select,
        width: 300,
      );
      final MaterialSegmentedButton hugging = MaterialSegmentedButton(
        segments: _segments,
        selected: 0,
        onSelect: _select,
      );

      for (final UINode child in shared.children) {
        if (child is! Box || child.width == 1) {
          continue;
        }
        final Box well = _wellBox(child);
        expect(well.width, double.infinity);
        expect(_contentOf(well).width, double.infinity);
      }

      for (final UINode child in hugging.children) {
        if (child is! Box || child.width == 1) {
          continue;
        }
        final Box well = _wellBox(child);
        expect(well.width, isNull);
        expect(_contentOf(well).width, isNull);
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
      expect(semantics.map((BoxSemantics s) => s.pressed ?? false), <bool>[
        true,
        false,
        false,
      ]);
      expect(
        semantics.map((BoxSemantics s) => s.selected),
        everyElement(isNull),
        reason: 'a segment is a toggle button, not an item of a tab strip',
      );
    });

    test('puts a check on the chosen segment, in place of its icon', () {
      const UINode icon = TextNode('grid');
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: const <MaterialSegment>[
          MaterialSegment(label: TextNode('List'), icon: icon),
          MaterialSegment(label: TextNode('Grid'), icon: icon),
        ],
        selected: 1,
        onSelect: _select,
      );
      final List<Box> segments = button.children.whereType<Box>().toList();

      // A chosen segment shows the check *instead of* its icon, which is what
      // Material does: a control that carries pictures still says which one is on.
      expect(_checkOf(_wellBox(segments.last)), isA<MaterialCheckMark>());
      expect(_nodesOf(_wellBox(segments.last)), isNot(contains(same(icon))));
      expect(_checkOf(_wellBox(segments.first)), isNull);
      expect(_nodesOf(_wellBox(segments.first)), contains(same(icon)));
    });

    test('keeps the icon when the check is turned off', () {
      const UINode icon = TextNode('grid');
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: const <MaterialSegment>[
          MaterialSegment(label: TextNode('List'), icon: icon),
        ],
        selected: 0,
        onSelect: _select,
        showSelectedIcon: false,
      );
      final Box chosen = button.children.whereType<Box>().single;

      expect(_checkOf(_wellBox(chosen)), isNull);
      expect(_nodesOf(_wellBox(chosen)), contains(same(icon)));
    });

    test('fades as one control when it is disabled', () {
      expect(
        MaterialSegmentedButton(
          segments: _segments,
          selected: 0,
          onSelect: _select,
        ).opacity,
        isNull,
      );
      expect(
        MaterialSegmentedButton(
          segments: _segments,
          selected: 0,
          onSelect: _select,
          enabled: false,
        ).opacity,
        0.38,
      );
    });

    test('lets a caller set the pill, its room, its type and its icon gap', () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: const <MaterialSegment>[
          MaterialSegment(label: TextNode('List'), icon: TextNode('grid')),
        ],
        selected: 0,
        onSelect: _select,
        height: 48,
        borderRadius: 24,
        padding: const BoxSpacing.symmetric(horizontal: 20),
        iconGap: 6,
        labelStyle: MaterialTypography.labelMedium,
      );
      final Box segment = button.children.single as Box;
      final Box pill = _wellBox(segment);
      final Box content =
          ((pill.children.single as StackNode).children.last as Box)
                  .children
                  .single
              as Box;

      expect(button.height, 48);
      expect(button.borderRadius, 24);
      expect(pill.height, 48);
      expect(content.padding, const BoxSpacing.symmetric(horizontal: 20));
      expect(
        content.textStyle?.fontSize,
        MaterialTypography.labelMedium.fontSize,
      );
      expect(
        content.textStyle?.color,
        const BoxColor.role(MaterialColorRole.onSecondaryContainer),
      );
      // The chosen segment shows the check, and the gap is the caller's.
      expect((content.children.single as Box).gap, 6);
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

/// The content a well draws: the box inside the layer its shapes sizes to.
///
/// A well is a layer of boxes — the shape, the tint layer, the stack and the content —
/// so the box the caller handed it is the one at the bottom of that stack.
Box _contentOf(Box well) =>
    ((well.children.single as StackNode).children.last as Box).children.single
        as Box;

/// Every node of [root], depth first.
List<UINode> _nodesOf(UINode root) => <UINode>[
  root,
  ...switch (root) {
    Box(:final List<UINode> children) ||
    GridNode(:final List<UINode> children) ||
    StackNode(:final List<UINode> children) => children.expand(_nodesOf),
    PositionedNode(:final UINode child) ||
    LinkNode(:final UINode child) => _nodesOf(child),
    _ => const <UINode>[],
  },
];

/// The check of a chosen segment, which is the icon sized stack, or `null`.
StackNode? _checkOf(UINode root) => _nodesOf(root)
    .whereType<StackNode>()
    .where((StackNode node) => node.width == MaterialSegmentedButton.iconSize)
    .firstOrNull;
