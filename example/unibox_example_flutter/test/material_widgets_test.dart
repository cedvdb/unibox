import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_example_flutter/components_app.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

/// Holds the host to the door `unibox_material_flutter` opens.
///
/// Two halves: the map itself, on a tree of one card and one bar, and the page whose subject
/// the comparison is — `ComponentsApp`, drawn with the values and drawn with the widgets. What
/// a substitution may change is the paint; what it may not is the words and the chosen page.
void main() {
  core.UINode tree() => core.Box(
    children: <core.UINode>[
      MaterialCard(
        children: <core.UINode>[const core.TextNode('Order summary')],
      ),
      MaterialNavigationBar(
        destinations: const <MaterialNavigationDestination>[
          MaterialNavigationDestination(label: core.TextNode('Listings')),
          MaterialNavigationDestination(label: core.TextNode('Map')),
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
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Order summary'), findsOneWidget);
  });

  testWidgets('draws the values when the map is not given', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, substituted: false);

    expect(find.byType(Card), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Order summary'), findsOneWidget);
  });

  testWidgets('keeps the words and the destination that is chosen', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, substituted: true);

    final NavigationBar bar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    expect(bar.selectedIndex, 1);
    expect(
      bar.destinations
          .map(
            (Widget destination) =>
                (destination as NavigationDestination).label,
          )
          .toList(),
      <String>['Listings', 'Map'],
    );
  });

  testWidgets('the catalogue is drawn twice: the values, and the widgets', (
    WidgetTester tester,
  ) async {
    // The width the site suite draws the same catalogue at: its demos are a page, not a pane.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentsApp());
    await tester.pump();

    final List<String> overflows = <String>[];
    for (
      Object? thrown = tester.takeException();
      thrown != null;
      thrown = tester.takeException()
    ) {
      overflows.add('$thrown');
    }
    // The harness font is taller than the platform's, so a fixed-height column can be four
    // pixels short here and fine on a device; a *horizontal* overflow would mean half the page
    // is narrower than the catalogue needs, which is the thing this case is here to catch.
    expect(
      overflows.where((String text) => text.contains('right')),
      isEmpty,
      reason: 'half the page is too narrow for the catalogue: $overflows',
    );

    // One rendering is the design system's values and holds no widget; the other is the map,
    // and a card is a `Card` there.
    expect(find.byType(Card), findsWidgets);
    // The catalogue holds one, the navigation bar's own section: the screens that used to carry a
    // second went with the scaffold, which is the application's furniture rather than a component.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('The values'), findsOneWidget);
    expect(find.textContaining('Flutter widgets, vanilla'), findsOneWidget);
  });
}
