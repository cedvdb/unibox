import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _tap() {}

/// The ink well a chip holds: the one node inside it.
MaterialInkWell _well(MaterialChip chip) =>
    chip.children.single as MaterialInkWell;

/// The box a well draws.
Box _boxOf(MaterialInkWell well) {
  final MaterialInkStore store = MaterialInkStore();
  final Box box = well.viewFor(store.state, store) as Box;
  store.dispose();

  return box;
}

/// The chip's own well, drawn.
Box _box(MaterialChip chip) {
  final MaterialInkStore store = MaterialInkStore();
  final Box box = _well(chip).viewFor(store.state, store) as Box;
  store.dispose();

  return box;
}

/// The box inside the well that carries the chip's padding and its content.
Box _content(MaterialChip chip) =>
    _box(chip).children
        .whereType<StackNode>()
        .single
        .children
        .whereType<Box>()
        .last;

/// The colour a chip draws its label in.
BoxColor? _labelColour(MaterialChip chip) =>
    (_content(chip).children.single as Box).textStyle?.color;

void main() {
  group('MaterialChip', () {
    test('is an outlined pill when it is not chosen', () {
      final MaterialChip chip = MaterialChip(label: const TextNode('Studio'));

      expect(chip, isA<Box>());
      expect(chip.backgroundColor, isNull);
      expect(
        chip.border?.color,
        const BoxColor.role(MaterialColorRole.outline),
      );
      expect(chip.borderRadius, MaterialChip.radius);
      expect(chip.borderRadius, 8);
    });

    test('fills with the secondary container when it is chosen', () {
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Two rooms'),
        selected: true,
      );

      expect(
        chip.backgroundColor,
        const BoxColor.role(MaterialColorRole.secondaryContainer),
      );
      expect(
        chip.border,
        isNull,
        reason: 'the fill is the state, so there is no line as well',
      );
    });

    test(
      'puts the room inside the well, so a tint cannot spill past the pill',
      () {
        final MaterialChip chip = MaterialChip(
          label: const TextNode('Studio'),
          onTap: _tap,
        );
        expect(
          chip.padding,
          isNull,
          reason: 'a second padding would make the tint wider than the pill',
        );
        expect(
          _content(chip).padding,
          const BoxSpacing.symmetric(horizontal: 16, vertical: 6),
        );
        expect(_box(chip).borderRadius, MaterialChip.radius);
        expect(_box(chip).onTap, _tap);
      },
    );

    test('narrows the leading side when it carries a node', () {
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Garden'),
        leading: const TextNode('✓'),
      );

      expect(
        _content(chip).padding,
        const BoxSpacing.symmetric(horizontal: 8, vertical: 6),
      );
    });

    test('is a button that says whether it is chosen', () {
      final Box tappable = _box(
        MaterialChip(
          label: const TextNode('Studio'),
          onTap: _tap,
          selected: true,
        ),
      );
      final Box plain = _box(MaterialChip(label: const TextNode('Studio')));

      expect(tappable.semantics?.role, BoxRole.button);
      expect(tappable.semantics?.selected, isTrue);
      expect(
        plain.semantics,
        isNull,
        reason: 'a chip that cannot be pressed is not a control',
      );
    });

    test('draws its label in the role the state asks for', () {
      expect(
        _labelColour(MaterialChip(label: const TextNode('Studio'))),
        const BoxColor.role(MaterialColorRole.onSurfaceVariant),
      );
      expect(
        _labelColour(
          MaterialChip(label: const TextNode('Studio'), selected: true),
        ),
        const BoxColor.role(MaterialColorRole.onSecondaryContainer),
      );
    });

    test('puts a node in front of the label when it is given one', () {
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Two rooms'),
        leading: const TextNode('check'),
        trailing: const TextNode('after'),
      );
      final Box row = _content(chip).children.single as Box;

      expect(row.direction, Axis.horizontal);
      expect(
        row.children.map((UINode node) => (node as TextNode).text).toList(),
        <String>['check', 'Two rooms', 'after'],
      );
    });

    test('gives a removable chip a close target of its own', () {
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Garden'),
        trailing: const TextNode('x'),
        onRemove: _tap,
        onTap: _tap,
      );
      final Box row = _content(chip).children.single as Box;
      final MaterialInkWell close = row.children.last as MaterialInkWell;

      expect(
        close,
        isNot(same(_well(chip))),
        reason: 'the cross is a second target, not the chip itself',
      );
      expect(_boxOf(close).width, 18);
      expect(_boxOf(close).semantics?.role, BoxRole.button);
      expect(_boxOf(close).semantics?.label, 'Remove');
      // The chip itself still says it can be pressed and whether it is chosen.
      expect(_box(chip).semantics?.role, BoxRole.button);
    });

    test('draws a tree the model can validate', () {
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Studio'),
        leading: const TextNode('✓'),
        onTap: _tap,
      );
      expect(
        validateTree(_box(chip), theme: MaterialPalette.lightTheme),
        isEmpty,
      );
      expect(validateTree(chip, theme: MaterialPalette.lightTheme), isEmpty);
    });
  });
}
