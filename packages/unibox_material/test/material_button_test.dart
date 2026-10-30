import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _tap() {}

void _longPress() {}

void _hover(bool isHovered) {}

/// The fill: the box inside the row that keeps the button at its natural size.
Box _fill(MaterialButton button) => button.children.single as Box;

/// The ink well inside the fill, which is what carries the room and the press.
MaterialInkWell _well(MaterialButton button) =>
    _fill(button).children.single as MaterialInkWell;

/// The room the button keeps around its label: the box the well pads, inside its
/// stack of ink.
BoxSpacing? _padding(MaterialButton button) =>
    ((_surface(button).children.single as StackNode).children.last as Box)
        .padding;

/// The surface the button's ink well draws for its resting state.
Box _surface(MaterialButton button) {
  final MaterialInkWell well = _well(button);
  final Store<Object> store = well.createStore() as Store<Object>;

  return well.viewFor(store.state, store) as Box;
}

/// The box the button states its typography on: the label, or the row holding the
/// icon and the label.
Box _labelBox(MaterialButton button) {
  final Box content =
      (_surface(button).children.single as StackNode).children.last as Box;

  return content.children.single as Box;
}

/// The label node itself.
UINode _labelNode(MaterialButton button) => _labelBox(button).children.last;

void main() {
  group('MaterialButton', () {
    test('is a box with a fill around the ink', () {
      final button = MaterialButton(label: const TextNode('Save'));

      expect(button, isA<Box>());
      expect(_fill(button).borderRadius, 20);
      expect(_fill(button).children.single, isA<MaterialInkWell>());
      expect(button.label, isA<TextNode>());
    });

    test('keeps its fill as wide as the label, not as wide as the parent', () {
      final button = MaterialButton.filled(label: const TextNode('Save'));

      // A parent that stretches its children — a card's column, a grid track —
      // stretches the row, and the row is invisible. The fill inside it has no width
      // of its own, so it takes the size the label asks for and the ink well inside
      // it can never be wider than the button.
      expect(button.direction, Axis.horizontal);
      expect(button.width, isNull);
      expect(_fill(button).width, isNull);

      // A width pins the fill instead, which is how a full-width button is asked for.
      expect(
        _fill(MaterialButton(label: const TextNode('Save'), width: 240)).width,
        240,
      );
    });

    test(
      'fills a filled button with the accent and paints its label on it',
      () {
        final button = MaterialButton.filled(label: const TextNode('Save'));

        expect(
          _fill(button).backgroundColor,
          const BoxColor.role(MaterialColorRole.primary),
        );
        expect(_fill(button).border, isNull);
        expect(
          _labelBox(button).textStyle?.color,
          const BoxColor.role(MaterialColorRole.onPrimary),
        );
      },
    );

    test('tones a tonal button down to the container colour', () {
      final button = MaterialButton.tonal(label: const TextNode('Later'));

      expect(
        _fill(button).backgroundColor,
        const BoxColor.role(MaterialColorRole.primaryContainer),
      );
      expect(
        _labelBox(button).textStyle?.color,
        const BoxColor.role(MaterialColorRole.onPrimaryContainer),
      );
    });

    test('outlines a button with no fill', () {
      final button = MaterialButton.outlined(label: const TextNode('Cancel'));

      expect(_fill(button).backgroundColor, isNull);
      expect(
        _fill(button).border?.color,
        const BoxColor.role(MaterialColorRole.outline),
      );
      expect(
        _labelBox(button).textStyle?.color,
        const BoxColor.role(MaterialColorRole.primary),
      );
    });

    test('draws a text button with neither fill nor line', () {
      final button = MaterialButton.text(label: const TextNode('Learn more'));

      expect(_fill(button).backgroundColor, isNull);
      expect(_fill(button).border, isNull);
      expect(
        _labelBox(button).textStyle?.color,
        const BoxColor.role(MaterialColorRole.primary),
      );
    });

    test('typesets every variant with the label role', () {
      for (final MaterialButton button in <MaterialButton>[
        MaterialButton(label: const TextNode('a')),
        MaterialButton.tonal(label: const TextNode('b')),
        MaterialButton.outlined(label: const TextNode('c')),
        MaterialButton.text(label: const TextNode('d')),
      ]) {
        expect(
          _labelBox(button).textStyle?.fontSize,
          MaterialTypography.labelLarge.fontSize,
        );
      }
    });

    test('inks the press over the fill, at the label colour', () {
      final filled = MaterialButton.filled(
        label: const TextNode('Save'),
        onTap: _tap,
      );
      final surface = _surface(filled);

      // The ink needs the press, and it is clipped to the button's radius.
      expect(surface.onTapDown, isNotNull);
      expect(surface.overflow, Overflow.hidden);
      expect(surface.borderRadius, 20);
    });

    test('is a button only when it can be tapped', () {
      final resting = MaterialButton(label: const TextNode('Save'));
      final tappable = MaterialButton(
        label: const TextNode('Save'),
        onTap: _tap,
      );

      expect(_surface(resting).semantics, isNull);
      expect(_surface(resting).isFocusable, isFalse);
      expect(_surface(tappable).semantics?.role, BoxRole.button);
      expect(_surface(tappable).isFocusable, isTrue);
    });

    test('keeps a disabled button out of the ink', () {
      final button = MaterialButton(
        label: const TextNode('Save'),
        onTap: _tap,
        enabled: false,
      );

      expect(_surface(button).onTapDown, isNull);
      expect(_surface(button).enabled, isFalse);
    });

    test('puts an icon beside the label when it is given one', () {
      final button = MaterialButton(
        label: const TextNode('Delete'),
        icon: const TextNode('x'),
      );
      final Box row = _labelBox(button);

      expect(row.direction, Axis.horizontal);
      expect(row.gap, 8);
      expect(row.children, hasLength(2));
      expect(_labelNode(button), isA<TextNode>());
    });

    test('paints the same forty pixels whichever shape it is', () {
      // Material's minimum height, and what makes a text button line up with a
      // filled one in a row of actions. The line is the label role's own: 20 of
      // `labelLarge`, plus ten above and ten below.
      final double line =
          MaterialTypography.labelLarge.fontSize! *
          MaterialTypography.labelLarge.lineHeight!;

      for (final MaterialButton button in <MaterialButton>[
        MaterialButton(label: const TextNode('a')),
        MaterialButton.tonal(label: const TextNode('b')),
        MaterialButton.outlined(label: const TextNode('c')),
        MaterialButton.text(label: const TextNode('d')),
      ]) {
        expect(_padding(button)!.vertical + line, 40);
        expect(_fill(button).minHeight, 40);
      }
    });

    test('keeps Material 24 across on the three filled shapes', () {
      for (final MaterialButton button in <MaterialButton>[
        MaterialButton(label: const TextNode('a')),
        MaterialButton.tonal(label: const TextNode('b')),
        MaterialButton.outlined(label: const TextNode('c')),
      ]) {
        expect(_padding(button)!.horizontal, 48);
      }

      // The quietest shape is narrower, and that is the only difference in its room.
      expect(
        _padding(MaterialButton.text(label: const TextNode('d'))),
        const BoxSpacing.symmetric(horizontal: 12, vertical: 10),
      );
    });

    test('is at least 64 wide, and centres its label in what it is given', () {
      final MaterialButton natural = MaterialButton(
        label: const TextNode('OK'),
      );
      final MaterialButton pinned = MaterialButton(
        label: const TextNode('OK'),
        width: 240,
        height: 56,
      );

      expect(_fill(natural).minWidth, 64);
      // A parent that stretches the row must not leave the label at the left of a
      // wider fill: the box centres what the label sizes and the well centres itself.
      expect(_fill(natural).mainAlign, MainAlign.center);
      expect(_fill(natural).crossAlign, CrossAlign.center);
      expect(_fill(pinned).width, 240);
      expect(_fill(pinned).height, 56);
    });

    test('lets a caller say how far the icon sits from the label', () {
      final Box row = _labelBox(
        MaterialButton(
          label: const TextNode('Delete'),
          icon: const TextNode('x'),
          iconGap: 12,
        ),
      );

      expect(row.gap, 12);
    });

    test('lines an outlined button, and lets a caller redraw the line', () {
      final MaterialButton outlined = MaterialButton.outlined(
        label: const TextNode('Cancel'),
      );
      final MaterialButton drawn = MaterialButton.outlined(
        label: const TextNode('Cancel'),
        border: const BoxBorder(width: 2, color: BoxColors.red),
      );

      expect(
        _fill(outlined).border,
        const BoxBorder(color: BoxColor.role(MaterialColorRole.outline)),
      );
      expect(_fill(drawn).border?.width, 2);
      expect(_fill(drawn).border?.color, BoxColors.red);
    });

    test('binds the long press and the hover on every shape', () {
      for (final MaterialButton button in <MaterialButton>[
        MaterialButton.tonal(
          label: const TextNode('a'),
          onLongPress: _longPress,
          onHover: _hover,
        ),
        MaterialButton.outlined(
          label: const TextNode('b'),
          onLongPress: _longPress,
          onHover: _hover,
        ),
        MaterialButton.text(
          label: const TextNode('c'),
          onLongPress: _longPress,
          onHover: _hover,
        ),
      ]) {
        expect(_surface(button).onLongPress, isNotNull);
        expect(_surface(button).onHover, isNotNull);
      }
    });

    test('lets a caller replace the ink, the radius and the room', () {
      final button = MaterialButton(
        label: const TextNode('Save'),
        ink: BoxColors.red,
        borderRadius: 8,
        padding: const BoxSpacing.all(4),
      );

      expect(_fill(button).borderRadius, 8);
      expect(_surface(button).borderRadius, 8);
    });

    test('is named for an inspector', () {
      expect(
        MaterialButton(label: const TextNode('Save')).debugName,
        'material-button',
      );
    });
  });
}
