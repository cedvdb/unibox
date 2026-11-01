import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_testing/unibox_testing.dart';

import 'support/harness.dart';

/// Plays the behaviour table against a widget tree, with real taps on real widgets.
///
/// The table is the one `unibox_dom` plays too, so a state that reaches a page and does not
/// reach a widget tree fails here rather than in front of a user. The three moves are this
/// target's own: a pump, a tap, and the text of the widget a key names — read from the node the
/// renderer drew, never from the tree the case holds.
void main() {
  for (final BehaviourCase behaviourCase in behaviourCases) {
    testWidgets('a widget tree ${behaviourCase.description}', (
      WidgetTester tester,
    ) async {
      final List<String> differences = await behaviourDifferences(
        behaviourCase,
        // A pump of the tree where the component is: the same place in the element tree, so a
        // state of the same type and key keeps its store.
        draw: (core.UINode tree) => pumpNode(tester, tree),
        press: (Object key) async {
          await tester.tap(find.byKey(ValueKey<Object>(key)));
          await tester.pump();
        },
        textAt: (Object key) {
          // A key that is not on the page is `null`, which is what a difference reads as
          // "says nothing" rather than as a failure of the reader.
          final Finder found = find.byKey(ValueKey<Object>(key));

          if (found.evaluate().isEmpty) {
            return null;
          }

          final Widget widget = tester.widget<Widget>(found);

          return widget is FlutterText ? widget.node.text : null;
        },
      );

      expect(differences, isEmpty, reason: behaviourCase.description);
    });
  }
}
