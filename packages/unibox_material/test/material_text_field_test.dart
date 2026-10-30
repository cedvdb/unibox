import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The tree [field] draws, after the user typed [typed] and focused or left it.
Box treeOf(MaterialTextField field, {String? typed, bool focused = false}) {
  // `create` is the typed factory; `createStore` is the erased spelling a
  // renderer needs.
  final MaterialFieldStore store = field.create();
  if (typed != null) {
    store.setValue(typed);
  }
  if (focused) {
    store.setFocused(true);
  }
  return field.view(store.state, store) as Box;
}

/// The painted field: the surface the label and the input sit on.
Box fillOf(Box tree) => tree.children.whereType<Box>().first;

/// The control inside the fill.
TextInputNode inputOf(Box tree) =>
    fillOf(tree).children.whereType<TextInputNode>().single;

/// The line under the field, when it draws one.
String? messageOf(Box tree) {
  final List<Box> boxes = tree.children.whereType<Box>().toList();
  if (boxes.length < 2) {
    return null;
  }

  return (boxes.last.children.single as TextNode).text;
}

void main() {
  group('MaterialTextField', () {
    test('fills the surface and puts the label above the value', () {
      final Box tree = treeOf(
        MaterialTextField(
          label: 'Email',
          value: 'ada@example.com',
          helper: 'We only use it for the receipt.',
        ),
      );
      final Box fill = fillOf(tree);

      expect(
        fill.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerHighest),
      );
      expect(fill.corners, const BoxBorderRadius(topLeft: 4, topRight: 4));
      expect(fill.borderRadius, isNull);
      expect(fill.minHeight, 56);
      expect(fill.border, isNull);

      final Box label = fill.children.first as Box;

      expect((label.children.single as TextNode).text, 'Email');
      expect(label.padding?.left, 16);
      expect(messageOf(tree), 'We only use it for the receipt.');
    });

    test('lets a caller tighten the room inside the field', () {
      final Box tree = treeOf(
        MaterialTextField(
          label: 'Email',
          value: 'ada@example.com',
          helper: 'We only use it for the receipt.',
          contentPadding: const BoxSpacing.symmetric(horizontal: 8),
          messageGap: 2,
        ),
      );

      // The label, the value and the message stay in one column at the width asked for.
      expect((fillOf(tree).children.first as Box).padding?.left, 8);
      expect(inputOf(tree).padding?.left, 8);
      expect(inputOf(tree).padding?.right, 8);
      expect((tree.children.last as Box).padding?.left, 8);
      expect(tree.gap, 2);
    });

    test('stretches to the width it is given, on the field and its wrapper', () {
      final Box tree = treeOf(MaterialTextField(label: 'Email'));

      // A web flex column shrinks a start-aligned child to its content, so the
      // field would be as wide as its label.
      expect(tree.crossAlign, CrossAlign.stretch);
      expect(fillOf(tree).crossAlign, CrossAlign.stretch);
    });

    test('puts the padding on the input, so the whole field is tappable', () {
      final TextInputNode input = inputOf(
        treeOf(MaterialTextField(label: 'Email')),
      );

      // Sixteen above and below a line of body text is Material's 56 pixels with
      // the label resting on that line.
      expect(input.padding?.left, 16);
      expect(input.padding?.right, 16);
      expect(input.padding?.top, 16);
      expect(input.padding?.bottom, 16);
      // The padding is inside the control; the box around it has none.
      expect(fillOf(treeOf(MaterialTextField())).padding, isNull);
    });

    test(
      'moves the label up as the user types, because the field has the state',
      () {
        final MaterialTextField field = MaterialTextField(label: 'Email');
        final Box resting = treeOf(field);
        final Box typing = treeOf(field, typed: 'ada@');

        // At rest the label is the line itself, so it is the input's hint and nothing
        // is drawn above it.
        expect(inputOf(resting).placeholder, 'Email');
        expect(fillOf(resting).children.first, isA<TextInputNode>());

        // One keystroke later the label is a small line at the top of the fill, and
        // the value takes the row under it — no host flag involved.
        expect(fillOf(typing).children.first, isA<Box>());
        expect(inputOf(typing).placeholder, isNull);
        expect(inputOf(typing).padding?.top, 0);
        expect(inputOf(typing).padding?.bottom, 8);
      },
    );

    test('keeps what the input is for', () {
      final TextInputNode input = inputOf(
        treeOf(
          MaterialTextField(
            placeholder: 'you@example.com',
            required: true,
            description: 'Used for the receipt',
          ),
        ),
      );

      // No label to rest on the line, so the placeholder is the hint.
      expect(input.placeholder, 'you@example.com');
      expect(input.required, isTrue);
      expect(input.description, 'Used for the receipt');
    });

    test('waits for the user to touch the field before it complains', () {
      final MaterialTextField field = MaterialTextField(
        label: 'Email',
        helper: 'We only use it for the receipt.',
        validator: (String value) =>
            value.contains('@') ? null : 'Enter an address with an @',
      );

      // Untouched, the field says nothing about the empty value.
      final Box fresh = treeOf(field);
      expect(inputOf(fresh).invalid, isFalse);
      expect(messageOf(fresh), 'We only use it for the receipt.');

      // A keystroke that leaves it wrong turns the line, the label and the message
      // into the error state.
      final Box wrong = treeOf(field, typed: 'ada');
      expect(inputOf(wrong).invalid, isTrue);
      expect(messageOf(wrong), 'Enter an address with an @');
      expect(
        fillOf(wrong).shadows?.single.color,
        const BoxColor.role(MaterialColorRole.error),
      );

      // Fixing it takes the error away and gives the helper back.
      final Box right = treeOf(field, typed: 'ada@example.com');
      expect(inputOf(right).invalid, isFalse);
      expect(messageOf(right), 'We only use it for the receipt.');
    });

    test('starts with the text it was given, unless the form controls it', () {
      // `initialValue` seeds the store, so the field keeps whatever the user types
      // over it; `value` is the form's and follows every rebuild.
      expect(
        inputOf(treeOf(MaterialTextField(initialValue: 'ada@'))).value,
        'ada@',
      );
      expect(
        inputOf(
          treeOf(
            MaterialTextField(value: 'ada@example.com', initialValue: 'ada@'),
          ),
        ).value,
        'ada@example.com',
      );
    });

    test('lets the form overrule the value and the message', () {
      final Box tree = treeOf(
        MaterialTextField(
          label: 'Email',
          value: 'ada@example.com',
          error: 'That address is already registered',
          validator: (String value) => 'the validator is not consulted',
        ),
        typed: 'ignored',
      );

      expect(inputOf(tree).value, 'ada@example.com');
      expect(inputOf(tree).invalid, isTrue);
      expect(messageOf(tree), 'That address is already registered');
    });

    test('draws the bottom line from roles, one colour per operation', () {
      final MaterialTextField field = MaterialTextField(
        validator: (String value) => value.isEmpty ? 'Required' : null,
      );

      expect(
        fillOf(treeOf(field)).shadows?.single.color,
        const BoxColor.role(MaterialColorRole.onSurfaceVariant),
      );
      expect(
        fillOf(treeOf(field, focused: true)).shadows?.single.color,
        const BoxColor.role(MaterialColorRole.primary),
      );
      expect(
        fillOf(treeOf(field, typed: '')).shadows?.single.color,
        const BoxColor.role(MaterialColorRole.error),
      );
      expect(
        fillOf(treeOf(field, typed: '', focused: true)).shadows?.single.color,
        const BoxColor.role(MaterialColorRole.error),
      );
      // Focused, the line is two pixels: the offset is what thickens it.
      expect(fillOf(treeOf(field)).shadows?.single.offsetY, 1);
      expect(fillOf(treeOf(field, focused: true)).shadows?.single.offsetY, 2);
      expect(fillOf(treeOf(field)).shadows?.single.blurRadius, 0);
    });

    test('typesets the value with the body role, in the on-surface colour', () {
      final BoxTextStyle? style = fillOf(treeOf(MaterialTextField())).textStyle;

      expect(style?.color, const BoxColor.role(MaterialColorRole.onSurface));
      expect(style?.fontSize, MaterialTypography.bodyLarge.fontSize);
    });

    test('fades out when disabled, and lifts the line under the pointer', () {
      expect(fillOf(treeOf(MaterialTextField())).opacity, isNull);
      expect(fillOf(treeOf(MaterialTextField(enabled: false))).opacity, 0.38);
      expect(
        fillOf(treeOf(MaterialTextField())).hoverStyle?.shadows?.single.color,
        const BoxColor.role(MaterialColorRole.onSurface),
      );
      expect(
        fillOf(treeOf(MaterialTextField(), focused: true)).hoverStyle,
        isNull,
      );
    });
  });

  group('MaterialFieldStore', () {
    test('publishes a keystroke and remembers that it happened', () {
      final MaterialFieldStore store = MaterialFieldStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      store.setValue('a');
      store.setValue('ad');

      expect(store.state.value, 'ad');
      expect(store.state.touched, isTrue);
      expect(notifications, 2);
    });

    test('counts leaving the field as having looked at it', () {
      final MaterialFieldStore store = MaterialFieldStore();

      store.setFocused(true);
      expect(store.state.touched, isFalse);

      store.setFocused(false);
      expect(store.state.focused, isFalse);
      expect(store.state.touched, isTrue);
    });

    test('says nothing when the state would not change', () {
      final MaterialFieldStore store = MaterialFieldStore(value: 'ada');
      var notifications = 0;
      store.addListener(() => notifications++);

      // The first keystroke is a change even though the text is the same: it is the
      // one that records that the user has typed at all.
      store.setValue('ada');
      expect(notifications, 1);

      // The second changes nothing, so nobody is told.
      store.setValue('ada');
      expect(notifications, 1);
    });
  });
}
