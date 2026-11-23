import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

/// Holds the host to the door `unibox_material_flutter` opens.
///
/// Two halves: the map itself, on a tree of one card and one choice, and the page whose subject
/// the comparison is — the catalogue, drawn with the values and drawn with the widgets. What a
/// substitution may change is the paint; what it may not is the words and the segment chosen.
void main() {
  core.UINode tree() => core.Box(
    children: <core.UINode>[
      MaterialCard(
        children: <core.UINode>[const core.TextNode('Order summary')],
      ),
      MaterialSegmentedButton(
        segments: <MaterialSegment>[
          MaterialSegment(label: const core.TextNode('Day')),
          MaterialSegment(label: const core.TextNode('Week')),
          MaterialSegment(label: const core.TextNode('Month')),
        ],
        selected: 1,
        onSelect: (int index) {},
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
                  scope: core.UniboxScope(theme: MaterialPalette.lightTheme),
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
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(find.text('Order summary'), findsOneWidget);
  });

  testWidgets('draws the values when the map is not given', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, substituted: false);

    expect(find.byType(Card), findsNothing);
    expect(find.byType(SegmentedButton<int>), findsNothing);
    expect(find.text('Order summary'), findsOneWidget);
  });

  testWidgets('keeps the words and the segment that is chosen', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, substituted: true);

    final SegmentedButton<int> pill = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );

    expect(pill.selected, <int>{1});
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
  });
}
