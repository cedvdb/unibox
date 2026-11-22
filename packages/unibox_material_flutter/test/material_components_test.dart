import 'package:material_ui/material_ui.dart';
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

  testWidgets(
    "draws an icon with a platform icon, at the node's size and colour",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: renderFlutter(
              material.MaterialIcon.codePoint(
                0xe570,
                size: 18,
                color: const core.BoxColor(0xFF102030),
                fontFamily: 'MaterialIcons',
              ),
              scope: core.UniboxScope(
                theme: material.MaterialPalette.lightTheme,
              ),
              substitutions: materialComponents(),
            ),
          ),
        ),
      );

      final Icon icon = tester.widget<Icon>(find.byType(Icon));

      expect(icon.icon?.codePoint, 0xe570);
      // The family is the node's, named rather than left to the platform's default: only with
      // it is the value the `Icons.*` constant of the same glyph.
      expect(icon.icon?.fontFamily, 'MaterialIcons');
      expect(icon.size, 18);
      expect(icon.color, const Color(0xFF102030));
    },
  );

  testWidgets(
    "draws an icon from the host's own IconData, so the glyph ships",
    (WidgetTester tester) async {
      // The list is the app's: a glyph the shaker cannot see is a glyph a release build drops, and a
      // codepoint read out of an `IconData` is not enough to keep it.
      const IconData gift = IconData(0xe13e, fontFamily: 'MaterialIcons');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: renderFlutter(
              material.MaterialIcon.codePoint(
                0xe13e,
                fontFamily: 'MaterialIcons',
              ),
              scope: core.UniboxScope(
                theme: material.MaterialPalette.lightTheme,
              ),
              substitutions: materialComponents(icons: const <IconData>[gift]),
            ),
          ),
        ),
      );

      final Icon icon = tester.widget<Icon>(find.byType(Icon));

      expect(
        icon.icon,
        gift,
        reason: 'the very constant the application named',
      );
    },
  );

  testWidgets(
    'names the family of a glyph it was not given, so it is the Icons constant',
    (WidgetTester tester) async {
      // A glyph the host's list does not name still has to draw from the icon font, and to be the
      // value `Icons.*` is: a family left to the platform's default is neither.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: renderFlutter(
              material.MaterialIcon.codePoint(
                0xe567,
                fontFamily: 'MaterialIcons',
              ),
              scope: core.UniboxScope(
                theme: material.MaterialPalette.lightTheme,
              ),
              substitutions: materialComponents(),
            ),
          ),
        ),
      );

      expect(tester.widget<Icon>(find.byType(Icon)).icon, Icons.search);
    },
  );

  testWidgets('falls back for a glyph the host did not name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderFlutter(
            material.MaterialIcon.codePoint(
              0xe570,
              fontFamily: 'MaterialIcons',
            ),
            scope: core.UniboxScope(theme: material.MaterialPalette.lightTheme),
            substitutions: materialComponents(
              icons: const <IconData>[
                IconData(0xe13e, fontFamily: 'MaterialIcons'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<Icon>(find.byType(Icon)).icon?.codePoint, 0xe570);
  });

  material.MaterialSegmentedButton twoChoices({VoidCallback? onRemove}) =>
      material.MaterialSegmentedButton(
        segments: <material.MaterialSegment>[
          const material.MaterialSegment(label: core.TextNode('Rooms')),
          const material.MaterialSegment(label: core.TextNode('Desks')),
        ],
        selected: 0,
        onSelect: (int index) {},
      );

  testWidgets(
    'a pill in a scrolling row hugs its columns, and still expands in a '
    'column that bounds it',
    (WidgetTester tester) async {
      // A row that scrolls gives its children no width at all. A `SegmentedButton` told to expand
      // into that lays out at an infinite width and throws, so the pill hugs instead — which is
      // what the document does with a grid whose parent sizes to content.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: renderFlutter(
              core.Box(
                direction: core.Axis.horizontal,
                overflow: core.Overflow.scroll,
                children: <core.UINode>[twoChoices()],
              ),
              scope: core.UniboxScope(
                theme: material.MaterialPalette.lightTheme,
              ),
              substitutions: materialComponents(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final Size hugged = tester.getSize(find.byType(SegmentedButton<int>));
      expect(hugged.width, lessThan(360));

      // The same pill in a column of the page fills the width it is given.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: renderFlutter(
                twoChoices(),
                scope: core.UniboxScope(
                  theme: material.MaterialPalette.lightTheme,
                ),
                substitutions: materialComponents(),
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SegmentedButton<int>)).width, 360);
    },
  );

  testWidgets('outlines a segmented pill with the hairline the tree names', (
    WidgetTester tester,
  ) async {
    // `SegmentedButton` outlines itself with `ColorScheme.outline` unless it is told otherwise,
    // which is a step darker than the `outlineVariant` a tree states — so the app drew a
    // different pill than the page for the same node.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderFlutter(
            material.MaterialSegmentedButton(
              segments: <material.MaterialSegment>[
                const material.MaterialSegment(label: core.TextNode('Rooms')),
                const material.MaterialSegment(label: core.TextNode('Desks')),
              ],
              selected: 0,
              onSelect: (int index) {},
              border: const core.BoxBorder(
                color: core.BoxColor(0xFF112233),
                width: 2,
              ),
            ),
            scope: core.UniboxScope(theme: material.MaterialPalette.lightTheme),
            substitutions: materialComponents(),
          ),
        ),
      ),
    );

    final SegmentedButton<int> pill = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );

    expect(
      pill.style?.side?.resolve(<WidgetState>{}),
      const BorderSide(color: Color(0xFF112233), width: 2),
    );
  });

  testWidgets('a removable chip answers its own pill as well as its cross', (
    WidgetTester tester,
  ) async {
    int presses = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderFlutter(
            material.MaterialChip(
              label: const core.TextNode('Terrace'),
              selected: true,
              onTap: () => presses++,
              onRemove: () => presses += 10,
              trailing: const core.TextNode('x'),
            ),
            scope: core.UniboxScope(theme: material.MaterialPalette.lightTheme),
            substitutions: materialComponents(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Terrace'));
    expect(presses, 1, reason: 'the whole pill drops the filter');

    await tester.tap(find.text('x'));
    expect(presses, 11, reason: 'so does the cross beside it');
  });
}
