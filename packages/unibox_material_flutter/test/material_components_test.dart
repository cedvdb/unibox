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
      material.MaterialButton.filled(
        label: const core.TextNode('Save'),
        onTap: () {},
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
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('draws the tree values when nothing is substituted', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, substituted: false);

    expect(find.byType(Card), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Order summary'), findsOneWidget);
  });

  testWidgets('keeps the words, and the press that answers them', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, substituted: true);

    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
      reason: 'a button a tree says is pressable answers its press either way',
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

  testWidgets('draws a spinner with the platform widget too', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderFlutter(
            material.MaterialSpinner(),
            scope: core.UniboxScope(theme: material.MaterialPalette.lightTheme),
            substitutions: materialComponents(),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
    "draws a glyph the host did not name as text, so no IconData is built at run time",
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

      // A run-time `IconData` costs the application its icon subsetter, so the fallback is the
      // character itself, out of the family the node names.
      expect(find.byType(Icon), findsNothing);
      final Text glyph = tester.widget<Text>(
        find.text(String.fromCharCode(0xe570)),
      );

      expect(glyph.style?.fontFamily, 'MaterialIcons');
      expect(glyph.style?.fontSize, 18);
      expect(glyph.style?.color, const Color(0xFF102030));
      // An icon does not grow with the reader's text size.
      expect(glyph.textScaler, TextScaler.noScaling);
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
    'names the family of a glyph it was not given, so it draws from the icon font',
    (WidgetTester tester) async {
      // A glyph the host's list does not name still has to draw from the icon font: a family left
      // to the ambient text style would draw it out of whatever font the text happens to use.
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

      final Text glyph = tester.widget<Text>(
        find.text(String.fromCharCode(0xe567)),
      );

      expect(glyph.style?.fontFamily, 'MaterialIcons');
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

    expect(find.text(String.fromCharCode(0xe570)), findsOneWidget);
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
