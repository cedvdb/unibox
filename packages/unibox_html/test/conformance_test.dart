import 'package:test/test.dart';
import 'package:unibox_html/unibox_html.dart';
import 'package:unibox_testing/unibox_testing.dart';

import 'support/appearance.dart';

/// Holds this renderer to the presentation table both renderers owe.
///
/// The table lives in `unibox_testing`, and the Flutter suite is held to it in exactly the
/// same way. A case that fails here is a document that looks different from the widget the
/// same node draws — which is the drift the whole package exists to prevent.
void main() {
  for (final BoxCase testCase in boxCases) {
    test('a document ${testCase.description}', () {
      final BoxAppearance appearance = appearanceOf(toHtml(testCase.box));

      expect(
        appearance.differencesFrom(testCase.expected),
        isEmpty,
        reason: 'the root box presents differently from the table',
      );
    });
  }

  for (final TextCase testCase in textCases) {
    test('a document ${testCase.description}', () {
      final TextAppearance appearance = textAppearanceOf(toHtml(testCase.node));

      expect(
        appearance.differencesFrom(testCase.expected),
        isEmpty,
        reason: 'the text presents differently from the table',
      );
    });
  }

  for (final OverlayCase testCase in overlayCases) {
    test('a document ${testCase.description}', () {
      final OverlayAppearance appearance = overlayAppearanceOf(
        toHtml(testCase.node, showOverlays: true),
      );

      expect(
        appearance.differencesFrom(testCase.expected),
        isEmpty,
        reason: 'the overlay presents differently from the table',
      );
    });
  }
}
