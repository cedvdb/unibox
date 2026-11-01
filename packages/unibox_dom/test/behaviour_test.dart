@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_testing/unibox_testing.dart';
import 'package:web/web.dart' as web;

/// Plays the behaviour table against a page, with real clicks on real elements.
///
/// The table is the one `unibox_flutter` plays too, so a state that reaches a widget tree and
/// does not reach a document fails here rather than on somebody's site. The three moves are
/// this target's own: a mount or a re-render, a click, and the text of an element by the key
/// its node carried.
void main() {
  for (final BehaviourCase behaviourCase in behaviourCases) {
    test('a page ${behaviourCase.description}', () async {
      final web.HTMLDivElement host =
          web.document.createElement('div') as web.HTMLDivElement;
      web.document.body!.append(host);

      DomView? view;

      String? textAt(Object key) =>
          host.querySelector('[data-unibox-key="$key"]')?.textContent;

      final List<String> differences = await behaviourDifferences(
        behaviourCase,
        draw: (core.UINode tree) async {
          // The first tree is mounted, the ones after it are drawn where it was: the same
          // place in the page, which is what makes a store outlive the node that made it.
          if (view case final DomView drawn) {
            drawn.render(tree);
          } else {
            view = DomView.mount(tree, host);
          }
        },
        press: (Object key) async {
          final web.Element? pressed = host.querySelector(
            '[data-unibox-key="$key"]',
          );

          if (pressed == null) {
            throw StateError('No element carries the key $key.');
          }

          pressed.dispatchEvent(
            web.MouseEvent('click', web.MouseEventInit(bubbles: true)),
          );
        },
        textAt: textAt,
      );

      expect(differences, isEmpty, reason: behaviourCase.description);

      view?.dispose();
      host.remove();
    });
  }
}
