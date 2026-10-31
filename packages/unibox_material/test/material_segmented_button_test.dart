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
    test('is one rounded container of equal shares', () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: _segments,
        selected: 1,
        onSelect: _select,
      );

      expect(button, isA<Box>());
      expect(button.height, MaterialSegmentedButton.controlHeight);
      expect(button.borderRadius, MaterialSegmentedButton.radius);
      expect(
        button.direction,
        isNull,
        reason: 'a box that names no direction is a column, and the pill holds one row',
      );
      expect(
        button.overflow,
        Overflow.hidden,
        reason: 'the fill of a chosen segment is cut to the rounded ends',
      );
      // The columns are the grid's, not the segments': one node inside the pill, and no
      // rule laid out between two of them that would sit outside every column.
      expect(button.children.single, isA<GridNode>());

      final GridNode grid = button.children.single as GridNode;

      expect(grid.columns, <int>[
        1,
        1,
        1,
      ], reason: 'one column per segment, every one of one factor');
      expect(grid.crossAlign, CrossAlign.stretch);
      expect(grid.children, hasLength(3));
      expect(grid.children, everyElement(isA<Box>()));
    });

    test('states no width on a segment, whatever the labels say', () {
      MaterialSegmentedButton button({double? width}) =>
          MaterialSegmentedButton(
            segments: _segments,
            selected: 0,
            onSelect: _select,
            width: width,
          );

      // A segment that states a width, a flex or a share would be a second answer to the
      // question the pill already answered: `validateTree` reports one, and the two
      // renderers would then measure it differently.
      for (final MaterialSegmentedButton control in <MaterialSegmentedButton>[
        button(),
        button(width: 300),
      ]) {
        for (final UINode child in _gridOf(control).children) {
          final Box segment = child as Box;
          expect(segment.width, isNull);
          expect(segment.flex, isNull);
          expect(segment.widthFraction, isNull);
        }
      }

      // Without a width the pill hugs its shares; a width is the pill's own, and the
      // shares divide it.
      expect(button().width, isNull);
      expect(button(width: 300).width, 300);
    });

    test('fills the column it was given, and cuts a label at it', () {
      // Every segment is a share of the pill — measured from the widest one when the pill
      // hugs, divided when it was given a width — so a segment fills what it is handed in
      // both cases, and a label too long for that width is cut inside it rather than
      // pushing the segment wider.
      for (final MaterialSegmentedButton control in <MaterialSegmentedButton>[
        MaterialSegmentedButton(
          segments: _segments,
          selected: 0,
          onSelect: _select,
          width: 300,
        ),
        MaterialSegmentedButton(
          segments: _segments,
          selected: 0,
          onSelect: _select,
        ),
      ]) {
        for (final UINode child in _gridOf(control).children) {
          final Box well = _wellBox(child as Box);
          final Box content = _contentOf(well);

          expect(well.width, double.infinity);
          expect(content.width, double.infinity);
          expect(
            content.crossAlign,
            CrossAlign.center,
            reason: 'the label is centred in the share, not in the room beside a rule',
          );
        }
      }
    });

    test('lays the rule between two segments over the segment it opens', () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: _segments,
        selected: 0,
        onSelect: _select,
      );

      // The first segment begins at the pill's own border, and every later one begins with
      // a line the colour of it. The line is positioned rather than laid out, so it takes
      // no room from the share and the label stays centred on it.
      expect(_ruleOf(_gridOf(button).children.first as Box), isNull);

      for (final UINode child in _gridOf(button).children.skip(1)) {
        final PositionedNode? rule = _ruleOf(child as Box);

        expect(rule, isNotNull);
        expect(rule!.alignment, BoxAlignment.centerStart);
        expect((rule.child as Box).width, 1);
        expect(
          (rule.child as Box).backgroundColor,
          const BoxColor.role(MaterialColorRole.outline),
        );
      }
    });

    test('gives a label beside an icon the room it asks to fill', () {
      const UINode icon = TextNode('grid');
      const TextNode label = TextNode('List');

      MaterialSegmentedButton button({double? width}) =>
          MaterialSegmentedButton(
            width: width,
            showSelectedIcon: false,
            segments: const <MaterialSegment>[
              MaterialSegment(label: label, icon: icon),
              MaterialSegment(label: TextNode('Grid')),
            ],
            selected: 0,
            onSelect: _select,
          );

      // The row holds the icon and the label. A row is as wide as its content, so the
      // room the label asks for needs a width to be a room of: the grid column bounds the
      // segment, and the row fills it in both cases — a pill that hugs its columns and a
      // pill that divides a width it was given.
      for (final MaterialSegmentedButton control in <MaterialSegmentedButton>[
        button(),
        button(width: 216),
      ]) {
        final Box segment = _gridOf(control).children.first as Box;
        final Box row = _contentOf(_wellBox(segment)).children.single as Box;

        // The layer states that it fills the column, so the fill and the label span the
        // segment rather than hugging their words, and the row inside it has a width to
        // divide between the icon and the room beside it.
        expect(segment.crossAlign, CrossAlign.stretch);
        expect(row.direction, Axis.horizontal);
        expect(row.width, double.infinity);
        expect((row.children.last as Box).flex, 1);
      }
    });

    test(
      'wears the line it is given, around the pill and between segments',
      () {
        final MaterialSegmentedButton plain = MaterialSegmentedButton(
          segments: _segments,
          selected: 0,
          onSelect: _select,
        );

        // Material's own outline, unchanged: the default is a 1 pixel line the same
        // colour as the rules between the segments.
        expect(
          plain.border,
          const BoxBorder(color: BoxColor.role(MaterialColorRole.outline)),
        );
        expect(
          (_ruleOf(_gridOf(plain).children[1] as Box)!.child as Box)
              .backgroundColor,
          const BoxColor.role(MaterialColorRole.outline),
        );

        // A theme that draws its control with outlineVariant says it once, and the rules
        // between the segments follow: one line, not a border and a different divider.
        const BoxBorder variant = BoxBorder(
          width: 2,
          color: BoxColor.role(MaterialColorRole.outlineVariant),
        );
        final MaterialSegmentedButton themed = MaterialSegmentedButton(
          segments: _segments,
          selected: 0,
          onSelect: _select,
          border: variant,
        );

        expect(themed.border, variant);
        expect(
          (_ruleOf(_gridOf(themed).children[1] as Box)!.child as Box).width,
          2,
        );
        expect(
          (_ruleOf(_gridOf(themed).children[1] as Box)!.child as Box)
              .backgroundColor,
          const BoxColor.role(MaterialColorRole.outlineVariant),
        );
      },
    );

    test('fills the chosen segment with the secondary container', () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        segments: _segments,
        selected: 2,
        onSelect: _select,
      );

      final List<Box> segments = _gridOf(button).children
          .whereType<Box>()
          .toList();

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
        for (final Box segment in _gridOf(button).children.whereType<Box>())
          _wellBox(segment).semantics!,
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
      final List<Box> segments = _gridOf(button).children
          .whereType<Box>()
          .toList();

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
      final Box chosen = _gridOf(button).children.whereType<Box>().single;

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
      final Box segment = _gridOf(button).children.single as Box;
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

/// The grid of columns a segmented button is.
GridNode _gridOf(MaterialSegmentedButton button) =>
    button.children.single as GridNode;

/// The rule at the start of [segment], or `null` for the first segment of a pill.
///
/// A segment is a layer — the well under the rule it opens — so the rule is the
/// positioned child of the stack the segment holds.
PositionedNode? _ruleOf(Box segment) => (segment.children.single as StackNode)
    .children
    .whereType<PositionedNode>()
    .firstOrNull;

/// The box the ink well of [segment] draws.
MaterialInkWell _wellOf(Box segment) => (segment.children.single as StackNode)
    .children
    .whereType<MaterialInkWell>()
    .single;

/// What the well of [segment] draws, with its state resolved.
Box _wellBox(Box segment) {
  final MaterialInkWell well = _wellOf(segment);
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
    PositionedNode(:final UINode child) => _nodesOf(child),
    _ => const <UINode>[],
  },
];

/// The check of a chosen segment, which is the icon sized stack, or `null`.
StackNode? _checkOf(UINode root) => _nodesOf(root)
    .whereType<StackNode>()
    .where((StackNode node) => node.width == MaterialSegmentedButton.iconSize)
    .firstOrNull;
