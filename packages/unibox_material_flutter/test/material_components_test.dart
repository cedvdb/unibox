import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart' as material;
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

/// Holds the map to the bargain it makes.
///
/// A component an application draws with the platform's own widget may look different — that
/// is the point — but it may not say anything different. These cases pin both halves: the
/// widget is there when the map is, the tree's own values are there when it is not, and the
/// words and the chosen destination are the same either way.
void main() {
  core.UINode tree() => core.Box(
    children: <core.UINode>[
      material.MaterialCard(
        children: <core.UINode>[const core.TextNode('Order summary')],
      ),
      material.MaterialNavigationBar(
        destinations: const <material.MaterialNavigationDestination>[
          material.MaterialNavigationDestination(
            label: core.TextNode('Listings'),
          ),
          material.MaterialNavigationDestination(label: core.TextNode('Map')),
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

  testWidgets('draws the components the application owns with its widgets', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, substituted: true);

    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('draws the tree values when nothing is substituted', (
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

    expect(find.text('Order summary'), findsOneWidget);

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

  testWidgets('draws the four controls with the platform widgets too', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderFlutter(
            core.Box(
              children: <core.UINode>[
                material.MaterialButton.filled(
                  label: const core.TextNode('Save'),
                  onTap: () {},
                ),
                material.MaterialChip(
                  label: const core.TextNode('Two rooms'),
                  selected: true,
                  onTap: () {},
                ),
                material.MaterialIconButton(
                  icon: const core.TextNode('I'),
                  label: 'More',
                  onTap: () {},
                ),
                material.MaterialProgressRing(value: 0.4, label: '40%'),
              ],
            ),
            scope: core.UniboxScope(theme: material.MaterialPalette.lightTheme),
            substitutions: materialComponents(),
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(FilterChip), findsOneWidget);
    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The words are the tree's either way.
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Two rooms'), findsOneWidget);
  });

  testWidgets('draws a tile too', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderFlutter(
            core.Box(
              children: <core.UINode>[
                material.MaterialListTile(
                  title: const core.TextNode('Ada Lovelace'),
                  onTap: () {},
                ),
              ],
            ),
            scope: core.UniboxScope(theme: material.MaterialPalette.lightTheme),
            substitutions: materialComponents(),
          ),
        ),
      ),
    );

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('draws a field and a spinner with the platform widgets too', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderFlutter(
            core.Box(
              children: <core.UINode>[
                material.MaterialTextField(
                  label: 'Email',
                  placeholder: 'ada@example.com',
                ),
                material.MaterialSpinner(),
              ],
            ),
            scope: core.UniboxScope(theme: material.MaterialPalette.lightTheme),
            substitutions: materialComponents(),
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('draws a tab strip with the platform widget too', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderFlutter(
            material.MaterialTabBar(
              tabs: const <material.MaterialTab>[
                material.MaterialTab(label: core.TextNode('Overview')),
                material.MaterialTab(label: core.TextNode('Details')),
              ],
              selected: 1,
            ),
            scope: core.UniboxScope(theme: material.MaterialPalette.lightTheme),
            substitutions: materialComponents(),
          ),
        ),
      ),
    );

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('a substituted card', () {
    testWidgets('wears the corner, the fill and the clip the tree states', (
      WidgetTester tester,
    ) async {
      // A card is not `CardTheme`'s card: the node states a radius, a colour role and whether
      // a press may paint past its edge. A ripple outside a rounded corner is one card drawn
      // two ways, and a fill from the wrong palette is two designs.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: renderFlutter(
              material.MaterialCard(
                color: const core.BoxColor(0xFF102030),
                borderRadius: 12,
                overflow: core.Overflow.hidden,
                children: <core.UINode>[const core.TextNode('Order summary')],
              ),
              substitutions: materialComponents(),
            ),
          ),
        ),
      );

      final Card card = tester.widget<Card>(find.byType(Card));

      expect(card.color, const Color(0xFF102030));
      expect(card.clipBehavior, Clip.antiAlias);
      expect(
        (card.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(12),
      );
    });
  });
}
