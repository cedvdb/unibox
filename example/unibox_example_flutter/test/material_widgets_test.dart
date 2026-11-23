import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart' as material;
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

/// Holds the host to the door `unibox_material_flutter` opens.
///
/// Two halves: the map itself, on a tree of one card and one button, and the page whose subject
/// the comparison is — the catalogue, drawn with the values and drawn with the widgets. What a
/// substitution may change is the paint; what it may not is the words, and a press answering.
void main() {
  late int presses;

  setUp(() => presses = 0);

  core.UINode tree() => core.Box(
    children: <core.UINode>[
      material.MaterialCard(
        children: <core.UINode>[const core.TextNode('Order summary')],
      ),
      material.MaterialButton.filled(
        label: const core.TextNode('Save'),
        onTap: () => presses++,
      ),
    ],
  );

  Future<void> pumpTree(WidgetTester tester, {required bool substituted}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 360,
                child: renderFlutter(
                  tree(),
                  scope: core.UniboxScope(
                    theme: material.MaterialPalette.lightTheme,
                  ),
                  substitutions: substituted
                      ? materialComponents()
                      : const UniboxSubstitutions.none(),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('draws the components with the platform widgets it was given', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, substituted: true);

    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Order summary'), findsOneWidget);
  });

  testWidgets('draws the values when the map is not given', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, substituted: false);

    expect(find.byType(Card), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Order summary'), findsOneWidget);
  });

  testWidgets('keeps the words and the press, whichever painter draws it', (
    WidgetTester tester,
  ) async {
    // The bargain in one test: the same node says the same thing and answers the same press,
    // whether a Flutter widget or the values drew it.
    await pumpTree(tester, substituted: true);
    await tester.tap(find.text('Save'));
    expect(presses, 1, reason: 'the substituted button answers its press');

    await pumpTree(tester, substituted: false);
    await tester.tap(find.text('Save'));
    expect(presses, 2, reason: 'so does the one drawn from the tree values');
  });
}
