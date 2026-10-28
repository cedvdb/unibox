import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _tap() {}

/// The surface the button's ink well draws for its resting state.
Box _surface(MaterialButton button) {
  final MaterialInkWell well = button.children.single as MaterialInkWell;
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
      expect(button.borderRadius, 20);
      expect(button.children.single, isA<MaterialInkWell>());
      expect(button.label, isA<TextNode>());
    });

    test(
      'fills a filled button with the accent and paints its label on it',
      () {
        final button = MaterialButton.filled(label: const TextNode('Save'));

        expect(
          button.backgroundColor,
          const BoxColor.role(MaterialColorRole.primary),
        );
        expect(button.border, isNull);
        expect(
          _labelBox(button).textStyle?.color,
          const BoxColor.role(MaterialColorRole.onPrimary),
        );
      },
    );

    test('tones a tonal button down to the container colour', () {
      final button = MaterialButton.tonal(label: const TextNode('Later'));

      expect(
        button.backgroundColor,
        const BoxColor.role(MaterialColorRole.primaryContainer),
      );
      expect(
        _labelBox(button).textStyle?.color,
        const BoxColor.role(MaterialColorRole.onPrimaryContainer),
      );
    });

    test('outlines a button with no fill', () {
      final button = MaterialButton.outlined(label: const TextNode('Cancel'));

      expect(button.backgroundColor, isNull);
      expect(
        button.border?.color,
        const BoxColor.role(MaterialColorRole.outline),
      );
      expect(
        _labelBox(button).textStyle?.color,
        const BoxColor.role(MaterialColorRole.primary),
      );
    });

    test('draws a text button with neither fill nor line', () {
      final button = MaterialButton.text(label: const TextNode('Learn more'));

      expect(button.backgroundColor, isNull);
      expect(button.border, isNull);
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

    test('lets a caller replace the ink, the radius and the room', () {
      final button = MaterialButton(
        label: const TextNode('Save'),
        ink: BoxColors.red,
        borderRadius: 8,
        padding: const BoxSpacing.all(4),
      );

      expect(button.borderRadius, 8);
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
