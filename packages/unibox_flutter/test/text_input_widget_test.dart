import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// The [TextField] widget rendered by the harness.
TextField renderedField(WidgetTester tester) =>
    tester.widget<TextField>(inNode(find.byType(TextField)));

/// The text currently held by the rendered field.
String currentText(WidgetTester tester) =>
    renderedField(tester).controller!.text;

void main() {
  group('TextInputNode', () {
    testWidgets('starts empty without a value', (tester) async {
      await pumpMaterialNode(tester, const core.TextInputNode());

      expect(currentText(tester), isEmpty);
    });

    testWidgets('renders the field without Material chrome', (tester) async {
      // The node says what a field is for, never how it looks, so the field must
      // not draw an underline, a fill or a padding of its own: the box around a
      // field decides that, which is what the plain `<input>` of the web renderer
      // does as well.
      await pumpMaterialNode(
        tester,
        const core.TextInputNode(placeholder: 'Your name'),
      );

      final InputDecoration decoration = renderedField(tester).decoration!;

      expect(decoration, InputDecoration.collapsed(hintText: 'Your name'));
      expect(decoration.isCollapsed, isTrue);
      expect(decoration.contentPadding, EdgeInsets.zero);
      expect(decoration.filled, isFalse);
    });

    testWidgets('shows the controlled value', (tester) async {
      await pumpMaterialNode(tester, const core.TextInputNode(value: 'hello'));

      expect(currentText(tester), 'hello');
    });

    testWidgets('reports changes and accepts typed text', (tester) async {
      final List<String> changes = <String>[];

      await pumpMaterialNode(
        tester,
        core.TextInputNode(onChanged: changes.add),
      );
      await tester.enterText(find.byType(TextField), 'abc');

      expect(changes, <String>['abc']);
      expect(currentText(tester), 'abc');
    });

    testWidgets('reports submission', (tester) async {
      final List<String> submissions = <String>[];

      await pumpMaterialNode(
        tester,
        core.TextInputNode(value: 'hello', onSubmitted: submissions.add),
      );
      await tester.enterText(find.byType(TextField), 'sent');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submissions, <String>['sent']);
    });

    testWidgets('follows a value pushed by the owner', (tester) async {
      await pumpMaterialNode(tester, const core.TextInputNode(value: 'one'));
      await pumpMaterialNode(tester, const core.TextInputNode(value: 'two'));

      expect(currentText(tester), 'two');
    });

    testWidgets('keeps typed text when the owner does not control it', (
      tester,
    ) async {
      await pumpMaterialNode(tester, const core.TextInputNode());
      await tester.enterText(find.byType(TextField), 'typed');
      await pumpMaterialNode(tester, const core.TextInputNode());

      expect(currentText(tester), 'typed');
    });

    testWidgets('gives the hint the typography the node asks for', (
      tester,
    ) async {
      await pumpMaterialNode(
        tester,
        const core.TextInputNode(
          placeholder: 'ada@example.com',
          placeholderStyle: core.BoxTextStyle(
            color: core.BoxColors.grey,
            fontSize: 18,
          ),
        ),
      );

      final TextStyle? hint = renderedField(tester).decoration!.hintStyle;

      expect(hint?.fontSize, 18);
      expect(hint?.color, const Color(0xFF9E9E9E));
    });

    testWidgets('renders the placeholder as a hint', (tester) async {
      await pumpMaterialNode(
        tester,
        const core.TextInputNode(placeholder: 'Email address'),
      );

      expect(find.text('Email address'), findsOneWidget);
    });

    testWidgets('obscures the text', (tester) async {
      await pumpMaterialNode(
        tester,
        const core.TextInputNode(value: 'secret', obscureText: true),
      );

      expect(renderedField(tester).obscureText, isTrue);
    });

    testWidgets('renders a single line field by default', (tester) async {
      await pumpMaterialNode(tester, const core.TextInputNode());

      final TextField field = renderedField(tester);
      expect(field.maxLines, 1);
      expect(field.minLines, isNull);
      expect(field.keyboardType, TextInputType.text);
    });

    testWidgets('renders a multiline field', (tester) async {
      await pumpMaterialNode(
        tester,
        const core.TextInputNode(multiline: true, maxLines: 4),
      );

      final TextField field = renderedField(tester);
      expect(field.maxLines, 4);
      expect(field.minLines, 1);
      expect(field.keyboardType, TextInputType.multiline);
    });

    testWidgets('lets a multiline field grow without a maxLines', (
      tester,
    ) async {
      await pumpMaterialNode(tester, const core.TextInputNode(multiline: true));

      expect(renderedField(tester).maxLines, isNull);
    });

    testWidgets('renders inside a box next to other children', (tester) async {
      await pumpMaterialNode(
        tester,
        const core.Box(
          direction: core.Axis.vertical,
          gap: 8,
          children: [
            core.TextInputNode(placeholder: 'Name'),
            core.TextNode('Send'),
          ],
        ),
      );

      expect(inNode(find.byType(TextField)), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });

    testWidgets('asks for the keyboard of its input type', (tester) async {
      await pumpMaterialNode(
        tester,
        const core.TextInputNode(inputType: core.InputType.email),
      );

      expect(renderedField(tester).keyboardType, TextInputType.emailAddress);
      expect(renderedField(tester).autofillHints, <String>[
        AutofillHints.email,
      ]);
    });

    testWidgets('maps every input type', (tester) async {
      const Map<core.InputType, TextInputType> expected =
          <core.InputType, TextInputType>{
            core.InputType.text: TextInputType.text,
            core.InputType.email: TextInputType.emailAddress,
            core.InputType.number: TextInputType.number,
            core.InputType.phone: TextInputType.phone,
            core.InputType.url: TextInputType.url,
          };

      for (final MapEntry<core.InputType, TextInputType> entry
          in expected.entries) {
        await pumpMaterialNode(
          tester,
          core.TextInputNode(inputType: entry.key),
        );

        expect(
          renderedField(tester).keyboardType,
          entry.value,
          reason: 'for ${entry.key.name}',
        );
      }
    });

    testWidgets('keeps a multiline field on the plain text keyboard', (
      tester,
    ) async {
      await pumpMaterialNode(
        tester,
        const core.TextInputNode(
          multiline: true,
          inputType: core.InputType.email,
        ),
      );

      expect(renderedField(tester).keyboardType, TextInputType.multiline);
      expect(renderedField(tester).autofillHints, isNull);
    });

    testWidgets('disables the field without losing its value', (tester) async {
      await pumpMaterialNode(
        tester,
        const core.TextInputNode(value: 'locked', enabled: false),
      );

      expect(renderedField(tester).enabled, isFalse);
      expect(currentText(tester), 'locked');
    });

    testWidgets('passes read only through', (tester) async {
      await pumpMaterialNode(
        tester,
        const core.TextInputNode(value: 'locked', readOnly: true),
      );

      expect(renderedField(tester).readOnly, isTrue);
    });

    testWidgets('takes focus when it is autofocused', (tester) async {
      await pumpMaterialNode(tester, const core.TextInputNode(autofocus: true));
      await tester.pump();

      expect(renderedField(tester).autofocus, isTrue);
      expect(renderedField(tester).focusNode?.hasFocus, isTrue);
    });

    testWidgets('reports focus changes', (tester) async {
      final List<bool> focuses = <bool>[];

      await pumpMaterialNode(
        tester,
        core.TextInputNode(onFocusChanged: focuses.add),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(focuses, <bool>[true, false]);
    });

    testWidgets('announces its label', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpMaterialNode(
        tester,
        const core.TextInputNode(semanticsLabel: 'Email address'),
      );

      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(
          label: 'Email address',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );

      handle.dispose();
    });
  });

  testWidgets('takes focus from a press inside its padding', (tester) async {
    await pumpMaterialNode(
      tester,
      const core.TextInputNode(padding: core.BoxSpacing.all(16)),
    );

    final Rect box = tester.getRect(find.byType(TextField));

    // The padding belongs to the field, so a press three pixels in is a press on
    // the input: without it, this corner is a dead strip.
    await tester.tapAt(box.topLeft + const Offset(3, 3));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    expect(
      tester
          .widget<TextField>(find.byType(TextField))
          .decoration
          ?.contentPadding,
      const EdgeInsets.all(16),
    );
  });
}
