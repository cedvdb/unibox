import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A card casts the shadows the framework itself states for its level.
///
/// `unibox_material` is pure Dart and cannot ask Flutter what a level looks like, so
/// the numbers are written out in `MaterialElevation`; this is the test that keeps
/// them honest. A card is pumped, the shadows it paints are read back out of the widget
/// tree, and the whole list is compared with `kElevationToShadow` — the map `Material`
/// itself draws from, three layers and all. A level that stops matching that map is a
/// card that no longer looks like the Material card beside it in a Flutter application.
void main() {
  testWidgets('a resting card casts the framework’s level one shadows', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, const MaterialCard());

    expect(_paintedShadows(tester), kElevationToShadow[1]);
  });

  testWidgets('a card raised two levels casts the shadows of that level', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, MaterialCard(shadows: MaterialElevation.level3));

    expect(_paintedShadows(tester), kElevationToShadow[3]);
  });

  testWidgets('an outlined card draws a line and casts nothing', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, MaterialCard.outlined());

    expect(_paintedShadows(tester), isNull);
  });
}

/// Pumps one card at the root, the way a host draws a tree.
Future<void> _pumpCard(WidgetTester tester, MaterialCard card) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: renderFlutter(card, theme: MaterialPalette.lightTheme),
    ),
  );
}

/// The shadows painted inside the card, read back from its decoration.
List<BoxShadow>? _paintedShadows(WidgetTester tester) {
  final Finder card = find.byWidgetPredicate(
    (Widget widget) => widget is FlutterBox && widget.box is MaterialCard,
  );

  final Iterable<DecoratedBox> painted = tester.widgetList<DecoratedBox>(
    find.descendant(of: card, matching: find.byType(DecoratedBox)),
  );

  for (final DecoratedBox box in painted) {
    final Decoration decoration = box.decoration;
    final List<BoxShadow>? shadows = decoration is BoxDecoration
        ? decoration.boxShadow
        : null;

    if (shadows != null && shadows.isNotEmpty) {
      return shadows;
    }
  }

  return null;
}
