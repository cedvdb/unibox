import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_testing/unibox_testing.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/appearance.dart';
import 'support/harness.dart';

/// Checks this renderer against the presentation contract of the workspace.
///
/// Every case in [boxCases] is rendered and the appearance is read back out of
/// the widget tree this renderer built, so a box that loses a token fails here
/// instead of only looking different from the page the web renderer draws. The
/// HTML suite walks the same table, which is what makes the two answers
/// comparable.
///
/// The same is done for [textCases]: the `TextStyle` this renderer declared is
/// compared with the one the table asks for, so a text token that stops reaching
/// Flutter fails here rather than in a screenshot. Both tables are walked by both
/// suites, which is as close to "the two renderings look the same" as a test
/// without a browser can come.
void main() {
  group('box conformance', () {
    for (final BoxCase boxCase in boxCases) {
      testWidgets(boxCase.description, (WidgetTester tester) async {
        await pumpNode(tester, boxCase.box);

        expect(
          appearanceOf(tester).differencesFrom(boxCase.expected),
          isEmpty,
          reason: 'Flutter renders "${boxCase.description}" differently.',
        );
      });
    }
  });

  group('text conformance', () {
    for (final TextCase textCase in textCases) {
      testWidgets(textCase.description, (WidgetTester tester) async {
        await pumpNode(tester, textCase.node);

        expect(
          textAppearanceOf(tester).differencesFrom(textCase.expected),
          isEmpty,
          reason: 'Flutter typesets "${textCase.description}" differently.',
        );
        expect(
          renderedTextOf(tester),
          textCase.node.text,
          reason: 'Flutter renders "${textCase.description}" without its text.',
        );
      });
    }
  });

  group('model default', () {
    testWidgets('typesets an undeclared text with the typography of the model', (
      WidgetTester tester,
    ) async {
      await pumpNode(tester, const core.TextNode('Hello'));

      // Not Flutter's own fallback: the renderer installs the typography of the
      // model at the root of the tree, which is what the web renderer puts in a
      // `:root` rule.
      expect(
        resolvedTextAppearanceOf(tester).differencesFrom(defaultTextAppearance),
        isEmpty,
        reason: 'Flutter typesets an undeclared text differently.',
      );
    });

    testWidgets('lets a declared token win over the default', (tester) async {
      await pumpNode(
        tester,
        const core.TextNode(
          'Hello',
          fontSize: 24,
          color: core.BoxColor.white,
          fontFamily: 'Inter',
        ),
      );

      expect(
        resolvedTextAppearanceOf(tester).differencesFrom(
          defaultTextAppearance.copyWith(
            fontSize: 24,
            color: core.BoxColor.white,
            fontFamily: 'Inter',
          ),
        ),
        isEmpty,
        reason: 'Flutter lets a declared token lose to the default.',
      );
    });
  });
}
