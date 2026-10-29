@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_testing/unibox_testing.dart';

import 'support/document.dart';

/// Holds the client renderer to the presentation table every renderer owes.
///
/// The table lives in `unibox_testing`; the Flutter suite reads the widget tree, the string suite
/// reads the markup, and this one reads the elements a browser actually holds plus the stylesheet
/// it was given. A case that fails here is a page that looks different from the widget the same node
/// draws — which is the drift the whole package exists to prevent.
void main() {
  for (final BoxCase testCase in boxCases) {
    test('a client ${testCase.description}', () {
      final DomView view = DomView.mount(testCase.box, host());

      expect(
        boxAppearanceIn(documentOf(view)).differencesFrom(testCase.expected),
        isEmpty,
        reason: 'the root box presents differently from the table',
      );

      view.dispose();
    });
  }

  for (final TextCase testCase in textCases) {
    test('a client ${testCase.description}', () {
      final DomView view = DomView.mount(testCase.node, host());

      expect(
        textAppearanceIn(documentOf(view)).differencesFrom(testCase.expected),
        isEmpty,
        reason: 'the text presents differently from the table',
      );

      view.dispose();
    });
  }

  for (final OverlayCase testCase in overlayCases) {
    test('a client ${testCase.description}', () {
      final DomView view = DomView.mount(testCase.node, host());

      expect(
        overlayAppearanceIn(documentOf(view))
            .differencesFrom(testCase.expected),
        isEmpty,
        reason: 'the overlay presents differently from the table',
      );

      view.dispose();
    });
  }
}
