import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A card casts the shadow the framework itself states for its level.
///
/// `unibox_material` is pure Dart and cannot ask Flutter what a level looks like, so
/// the numbers are written out in `MaterialElevation`; this is the test that keeps
/// them honest. A card is pumped, the shadow it paints is read back out of the widget
/// tree, and it is compared with `kElevationToShadow` — the map `Material` itself
/// draws from. A level that stops matching that map is a card that no longer looks
/// like the Material card beside it in a Flutter application.
void main() {
  testWidgets('a resting card casts the framework’s level one shadow', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, const MaterialCard());

    expect(_paintedShadow(tester), kElevationToShadow[1]!.last);
  });

  testWidgets('a card raised two levels casts the shadow of that level', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, MaterialCard(shadow: MaterialElevation.level3));

    expect(_paintedShadow(tester), kElevationToShadow[3]!.last);
  });

  testWidgets('an outlined card draws a line and casts nothing', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, MaterialCard.outlined());

    expect(_paintedShadow(tester), isNull);
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

/// The single shadow painted inside the card, read back from its decoration.
BoxShadow? _paintedShadow(WidgetTester tester) {
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
      return shadows.single;
    }
  }

  return null;
}
