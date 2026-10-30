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

/// The pill: the shape the well paints, which sits inside the taller target.
Box _pill(MaterialChip chip) => _box(chip).children.single as Box;

/// The layer of state tints, which the pill holds because a fill and a tint cannot be
/// the same background.
Box _tints(MaterialChip chip) => _pill(chip).children.single as Box;

/// The box inside the tints that carries the chip's padding and its content.
Box _content(MaterialChip chip) =>
    _tints(chip).children
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
      expect(_pill(chip).backgroundColor, isNull);
      expect(
        _pill(chip).border?.color,
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
        _pill(chip).backgroundColor,
        const BoxColor.role(MaterialColorRole.secondaryContainer),
      );
      expect(
        _pill(chip).border,
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
        expect(_pill(chip).borderRadius, MaterialChip.radius);
        expect(
          _box(chip).borderRadius,
          isNull,
          reason: 'the target paints nothing and clips nothing',
        );
        expect(_box(chip).onTap, _tap);
      },
    );

    test('pads only the side that carries a node', () {
      // Material's chip pads 16 where the label reaches the edge and 8 where an 18
      // pixel glyph does, so the padding is the side's, not the chip's.
      final MaterialChip plain = MaterialChip(label: const TextNode('Garden'));
      final MaterialChip leading = MaterialChip(
        label: const TextNode('Garden'),
        leading: const TextNode('check-18'),
      );
      final MaterialChip trailing = MaterialChip(
        label: const TextNode('Garden'),
        trailing: const TextNode('x'),
      );
      final MaterialChip removable = MaterialChip(
        label: const TextNode('Garden'),
        trailing: const TextNode('x'),
        onRemove: _tap,
      );

      expect(
        _content(plain).padding,
        const BoxSpacing.only(left: 16, right: 16, top: 6, bottom: 6),
      );
      expect(
        _content(leading).padding,
        const BoxSpacing.only(left: 8, right: 16, top: 6, bottom: 6),
      );
      expect(
        _content(trailing).padding,
        const BoxSpacing.only(left: 16, right: 8, top: 6, bottom: 6),
      );
      expect(
        _content(removable).padding,
        const BoxSpacing.only(left: 16, right: 8, top: 6, bottom: 6),
      );
    });

    test('paints 32 in a 48 tall target, and fades when disabled', () {
      final MaterialChip plain = MaterialChip(label: const TextNode('Garden'));
      final MaterialChip withGlyph = MaterialChip(
        label: const TextNode('Garden'),
        leading: const TextNode('check-18'),
      );

      // The pill is Material's 32 whatever the chip carries, and the region a finger
      // gets is the 48 Material states for a touch target: the pill is centred in it,
      // so a glyph taller than the line cannot make one chip taller than its neighbour.
      expect(_pill(plain).height, MaterialChip.controlHeight);
      expect(_pill(withGlyph).height, MaterialChip.controlHeight);
      expect(_box(plain).height, MaterialChip.minTapTarget);
      expect(MaterialChip.minTapTarget, 48);
      expect(plain.minHeight, MaterialChip.minTapTarget);
      expect(plain.opacity, isNull);
      expect(
        MaterialChip(label: const TextNode('Garden'), enabled: false).opacity,
        0.38,
      );
      // The node Material puts inside a chip is 18, which is what the padding and the
      // close target are measured against.
      expect(MaterialChip.iconSize, 18);
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
      expect(tappable.semantics?.pressed, isTrue);
      expect(
        tappable.semantics?.selected,
        isNull,
        reason:
            'a chip is a toggle button: `aria-selected` is not a button state',
      );
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
      // The cross sits in the middle of the target, not against its edge: a well is a
      // column, so a cross without a cross alignment hugs the start, and the ring a
      // hover draws around it lands four pixels off the cross it belongs to.
      expect(_boxOf(close).mainAlign, MainAlign.center);
      expect(_boxOf(close).crossAlign, CrossAlign.center);
      expect(_boxOf(close).semantics?.role, BoxRole.button);
      expect(_boxOf(close).semantics?.label, 'Remove');
      // The chip itself still says it can be pressed and whether it is chosen.
      expect(_box(chip).semantics?.role, BoxRole.button);
    });

    test('lets a caller say which chip its close removes', () {
      // A row of applied filters: a reader hears "Remove Garden" rather than the same
      // "Remove" eleven times.
      final MaterialChip named = MaterialChip(
        label: const TextNode('Garden'),
        trailing: const TextNode('x'),
        onRemove: _tap,
        removeSemanticsLabel: 'Remove Garden',
      );
      final Box row = _content(named).children.single as Box;
      final MaterialInkWell close = row.children.last as MaterialInkWell;

      expect(_boxOf(close).semantics?.label, 'Remove Garden');
      expect(_boxOf(close).semantics?.role, BoxRole.button);
      // The chip itself is still the control it was: the name belongs to the cross.
      expect(named.semantics, isNull);

      // Nothing passed, nothing changed: the cross announces what it always did.
      final MaterialChip plain = MaterialChip(
        label: const TextNode('Garden'),
        trailing: const TextNode('x'),
        onRemove: _tap,
      );
      final Box plainRow = _content(plain).children.single as Box;

      expect(
        _boxOf(plainRow.children.last as MaterialInkWell).semantics?.label,
        'Remove',
      );
    });

    test('lets a caller set the room, the pill and the target', () {
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Studio'),
        padding: const BoxSpacing.all(4),
        height: 40,
        tapTargetHeight: 56,
        borderRadius: 20,
      );

      // The room stays the well's, so a custom inset cannot spill a tint past the pill.
      expect(_content(chip).padding, const BoxSpacing.all(4));
      expect(_pill(chip).height, 40);
      expect(_pill(chip).borderRadius, 20);
      // The target is layout: the pill is centred in it, so a row of chips is this tall.
      expect(_box(chip).height, 56);
      expect(chip.minHeight, 56);
    });

    test('lets a caller type the label and space its nodes', () {
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Two rooms'),
        leading: const TextNode('check'),
        gap: 4,
        labelStyle: MaterialTypography.labelMedium,
      );
      final Box row = _content(chip).children.single as Box;

      expect(row.gap, 4);
      expect(row.textStyle?.fontSize, MaterialTypography.labelMedium.fontSize);
      // The state still owns the colour: the caller's style is the type, not the ink.
      expect(
        row.textStyle?.color,
        const BoxColor.role(MaterialColorRole.onSurfaceVariant),
      );
    });

    test('passes a hover on, so a chip can do more than tint', () {
      bool? hovered;
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Studio'),
        onTap: _tap,
        onHover: (bool value) => hovered = value,
      );

      _box(chip).onHover!(true);

      expect(hovered, isTrue);
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
