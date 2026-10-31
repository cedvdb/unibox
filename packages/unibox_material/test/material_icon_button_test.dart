import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _tap() {}

/// The glyph every test gives a control that has neither text nor a picture of its own.
const UINode _glyph = TextNode('tune');

/// The square the button draws: the well, or the stack that holds it and its badge.
UINode _shape(MaterialIconButton button) => button.children.single;

/// The well a button draws.
MaterialInkWell _well(MaterialIconButton button) {
  final UINode shape = _shape(button);

  return shape is MaterialInkWell
      ? shape
      : (shape as StackNode).children.first as MaterialInkWell;
}

/// The box a well draws: the surface when it has one, and the tints when it has both.
Box _boxOf(MaterialInkWell well) {
  final MaterialInkStore store = MaterialInkStore();
  final Box box = well.viewFor(store.state, store) as Box;
  store.dispose();

  return box;
}

/// The box the well wraps its child in, which carries the room inside the fill.
Box _content(Box well) {
  // The layers of a well go surface → tints → stack → content, and the two that hold a
  // single box are the ones to walk: the stack is where the walk stops.
  UINode node = well;
  while (node is Box &&
      node.children.length == 1 &&
      node.children.single is Box) {
    node = node.children.single;
  }

  final StackNode stack = (node as Box).children.whereType<StackNode>().single;

  return stack.children.last as Box;
}

/// The square the glyph is centred in, inside the room the well gives it.
Box _glyphBox(MaterialIconButton button) =>
    _content(_boxOf(_well(button))).children.single as Box;

void main() {
  group('MaterialIconButton', () {
    test('is a 40 pixel square around a 24 pixel glyph', () {
      final MaterialIconButton button = MaterialIconButton(
        icon: _glyph,
        label: 'Filters',
        onTap: _tap,
      );
      final Box well = _boxOf(_well(button));

      expect(button, isA<Box>());
      expect(well.width, MaterialIconButton.controlHeight);
      expect(well.height, MaterialIconButton.controlHeight);
      expect(well.borderRadius, MaterialIconButton.radius);
      expect(well.semantics?.role, BoxRole.button);
      expect(well.semantics?.label, 'Filters');
      expect(well.onTap, _tap);

      final Box room = _content(well);
      expect(room.padding, const BoxSpacing.all(8));

      final Box glyph = _glyphBox(button);
      expect(glyph.width, MaterialIconButton.defaultIconSize);
      expect(glyph.height, MaterialIconButton.defaultIconSize);
      expect(glyph.children.single, same(_glyph));
    });

    test('paints the four shapes from roles, and no value', () {
      MaterialIconButton button(MaterialIconButtonVariant variant) =>
          MaterialIconButton(
            icon: _glyph,
            label: 'Filters',
            variant: variant,
            onTap: _tap,
          );

      final Map<MaterialIconButtonVariant, BoxColor?> fills =
          <MaterialIconButtonVariant, BoxColor?>{
            for (final MaterialIconButtonVariant variant
                in MaterialIconButtonVariant.values)
              variant: _boxOf(_well(button(variant))).backgroundColor,
          };

      expect(fills, <MaterialIconButtonVariant, BoxColor?>{
        MaterialIconButtonVariant.standard: null,
        MaterialIconButtonVariant.filled: const BoxColor.role(
          MaterialColorRole.primary,
        ),
        MaterialIconButtonVariant.tonal: const BoxColor.role(
          MaterialColorRole.secondaryContainer,
        ),
        MaterialIconButtonVariant.outlined: null,
      });

      // The line belongs to the outlined shape alone.
      for (final MaterialIconButtonVariant variant
          in MaterialIconButtonVariant.values) {
        final Box well = _boxOf(_well(button(variant)));

        expect(
          well.border?.color,
          variant == MaterialIconButtonVariant.outlined
              ? const BoxColor.role(MaterialColorRole.outline)
              : isNull,
          reason: 'the ${variant.name} shape',
        );
      }

      // The glyph contrasts with the fill it sits on, which is what makes a dark theme
      // a theme rather than a parameter.
      expect(
        _glyphBox(button(MaterialIconButtonVariant.tonal)).textStyle?.color,
        const BoxColor.role(MaterialColorRole.onSecondaryContainer),
      );
      expect(
        _glyphBox(button(MaterialIconButtonVariant.filled)).textStyle?.color,
        const BoxColor.role(MaterialColorRole.onPrimary),
      );
      expect(
        _glyphBox(button(MaterialIconButtonVariant.standard)).textStyle?.color,
        const BoxColor.role(MaterialColorRole.onSurfaceVariant),
      );
    });

    test('places a count over the corner without widening the square', () {
      final MaterialIconButton button = MaterialIconButton(
        icon: _glyph,
        label: 'Notifications',
        badgeCount: 3,
        onTap: _tap,
      );
      final UINode shape = _shape(button);

      expect(shape, isA<StackNode>());
      expect(
        (shape as StackNode).width,
        MaterialIconButton.controlHeight,
        reason: 'the badge is placed in the square, not added to it',
      );
      expect(shape.height, MaterialIconButton.controlHeight);

      final PositionedNode at = shape.children.last as PositionedNode;
      expect(at.alignment, BoxAlignment.topEnd);
      // The glyph's own top right corner: 40 - (8 + 24) is where the pill starts.
      expect(at.top, isNull);
      expect(at.left, isNull);

      final Box pill = at.child as Box;
      expect(pill.height, 16);
      expect(pill.minWidth, 16);
      expect(pill.borderRadius, 8);
      expect(
        pill.backgroundColor,
        const BoxColor.role(MaterialColorRole.error),
      );
      expect(
        pill.textStyle?.color,
        const BoxColor.role(MaterialColorRole.onError),
      );
      // A count nobody is told is a picture, so the pill stays out of the reading order.
      expect(pill.semantics?.hidden, isTrue);
      // And it is a picture to the pointer too: the corner it covers belongs to the control.
      expect(pill.capturesPointer, isFalse);
      expect((pill.children.single as TextNode).text, '3');
      // The control still says what it is, once.
      expect(_boxOf(_well(button)).semantics?.label, 'Notifications');
    });

    test('draws no badge for a count of nothing', () {
      for (final int? count in <int?>[null, 0]) {
        final MaterialIconButton button = MaterialIconButton(
          icon: _glyph,
          label: 'Notifications',
          badgeCount: count,
          onTap: _tap,
        );

        expect(_shape(button), isA<MaterialInkWell>());
      }
    });

    test('lets a caller set the square, its glyph and its room', () {
      final MaterialIconButton button = MaterialIconButton(
        icon: _glyph,
        label: 'Filters',
        height: 48,
        iconSize: 20,
        borderRadius: 24,
        padding: const BoxSpacing.all(12),
        ink: const BoxColor(0xFF000000),
        onTap: _tap,
      );
      final Box well = _boxOf(_well(button));

      // A control that names only a height is as wide as it is tall.
      expect(well.width, 48);
      expect(well.height, 48);
      expect(well.borderRadius, 24);
      expect(_content(well).padding, const BoxSpacing.all(12));
      expect(_glyphBox(button).width, 20);

      final MaterialIconButton wide = MaterialIconButton(
        icon: _glyph,
        width: 64,
        height: 40,
        onTap: _tap,
      );

      expect(_boxOf(_well(wide)).width, 64);
    });

    test('fades as one control when it is disabled', () {
      expect(MaterialIconButton(icon: _glyph, onTap: _tap).opacity, isNull);
      expect(
        MaterialIconButton(icon: _glyph, onTap: _tap, enabled: false).opacity,
        0.38,
      );
    });

    test('draws a tree the model can validate', () {
      for (final MaterialIconButtonVariant variant
          in MaterialIconButtonVariant.values) {
        final MaterialIconButton button = MaterialIconButton(
          icon: const TextNode('tune'),
          label: 'Filters',
          variant: variant,
          badgeCount: 12,
          onTap: _tap,
        );

        expect(
          validateTree(button, theme: MaterialPalette.lightTheme),
          isEmpty,
          reason: 'the ${variant.name} shape',
        );
      }
    });
  });
}
