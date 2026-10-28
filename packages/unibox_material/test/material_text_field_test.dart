import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The painted field: the surface the label and the input sit on.
Box fillOf(MaterialTextField field) => field.children.whereType<Box>().first;

TextInputNode inputOf(MaterialTextField field) =>
    fillOf(field).children.whereType<TextInputNode>().single;

void main() {
  group('MaterialTextField', () {
    test('fills the surface and keeps the label inside it', () {
      final field = MaterialTextField(
        label: 'Email',
        value: 'ada@example.com',
        message: 'We only use it for the receipt.',
      );
      final Box fill = fillOf(field);

      expect(
        fill.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerHighest),
      );
      expect(fill.corners, const BoxCorners(topLeft: 4, topRight: 4));
      expect(fill.borderRadius, isNull);
      expect(fill.minHeight, 56);
      expect(fill.border, isNull);

      final Box label = fill.children.first as Box;

      expect((label.children.single as TextNode).text, 'Email');
      expect(label.padding?.left, 16);
      expect(field.children.last, isA<Box>());
    });

    test('puts the padding on the input, so the whole field is tappable', () {
      final TextInputNode input = inputOf(MaterialTextField(label: 'Email'));

      // Sixteen above and below a line of body text is Material's 56 pixels with
      // the label resting on that line.
      expect(input.padding?.left, 16);
      expect(input.padding?.right, 16);
      expect(input.padding?.top, 16);
      expect(input.padding?.bottom, 16);
      // The padding is inside the control; the box around it has none.
      expect(fillOf(MaterialTextField()).padding, isNull);
    });

    test('moves the label to the top of the fill once there is a value', () {
      final MaterialTextField resting = MaterialTextField(label: 'Email');
      final MaterialTextField filled = MaterialTextField(
        label: 'Email',
        value: 'ada@',
      );

      // At rest the label is the line itself, so it is the input's hint and nothing
      // is drawn above it.
      expect(inputOf(resting).placeholder, 'Email');
      expect(fillOf(resting).children.first, isA<TextInputNode>());

      // With a value it is a small label at the top, and the input takes the row
      // under it.
      expect(fillOf(filled).children.first, isA<Box>());
      expect(inputOf(filled).placeholder, isNull);
      expect(inputOf(filled).padding?.top, 0);
      expect(inputOf(filled).padding?.bottom, 8);
    });

    test('keeps the input and its state', () {
      final TextInputNode input = inputOf(
        MaterialTextField(
          placeholder: 'you@example.com',
          required: true,
          invalid: true,
          description: 'Used for the receipt',
        ),
      );

      // No label to rest on the line, so the placeholder is the hint.
      expect(input.placeholder, 'you@example.com');
      expect(input.required, isTrue);
      expect(input.invalid, isTrue);
      expect(input.description, 'Used for the receipt');
    });

    test('draws the bottom line from roles, one colour per state', () {
      BoxColor lineOf(MaterialTextField field) => fillOf(field).shadow!.color;

      expect(
        lineOf(MaterialTextField()),
        const BoxColor.role(MaterialColorRole.onSurfaceVariant),
      );
      expect(
        lineOf(MaterialTextField(focused: true)),
        const BoxColor.role(MaterialColorRole.primary),
      );
      expect(
        lineOf(MaterialTextField(invalid: true)),
        const BoxColor.role(MaterialColorRole.error),
      );
      expect(
        lineOf(MaterialTextField(invalid: true, focused: true)),
        const BoxColor.role(MaterialColorRole.error),
      );
      // Focused, the line is two pixels: the offset is what thickens it.
      expect(fillOf(MaterialTextField()).shadow?.offsetY, 1);
      expect(fillOf(MaterialTextField(focused: true)).shadow?.offsetY, 2);
      expect(fillOf(MaterialTextField()).shadow?.blurRadius, 0);
    });

    test('typesets the value with the body role, in the on-surface colour', () {
      final BoxTextStyle? style = fillOf(MaterialTextField()).textStyle;

      expect(style?.color, const BoxColor.role(MaterialColorRole.onSurface));
      expect(style?.fontSize, MaterialTypography.bodyLarge.fontSize);
    });

    test('fades out when disabled, and lifts the line under the pointer', () {
      expect(fillOf(MaterialTextField()).opacity, isNull);
      expect(fillOf(MaterialTextField(enabled: false)).opacity, 0.38);
      expect(
        fillOf(MaterialTextField()).hoverStyle?.shadow?.color,
        const BoxColor.role(MaterialColorRole.onSurface),
      );
      expect(fillOf(MaterialTextField(focused: true)).hoverStyle, isNull);
    });
  });
}
