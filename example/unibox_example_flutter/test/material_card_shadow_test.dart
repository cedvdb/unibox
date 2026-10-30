import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A card casts the layers the framework states for its level, in black at 87%.
///
/// `unibox_material` is pure Dart and cannot ask Flutter what a level looks like, so the
/// geometry is written out in `MaterialElevation`; this is the test that keeps it honest.
/// A card is pumped and the shadows it paints are read back out of the widget tree: the
/// offsets, blurs and spreads have to be `kElevationToShadow`'s, layer for layer, and the
/// ink that map's opacities at 87% — because the three layers stacked come out heavier
/// than the single softer shadow a `Material` actually draws, and a card that read heavier
/// than the card beside it is the drift this pins shut.
void main() {
  testWidgets('a resting card casts the framework’s level one shadow', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, const MaterialCard());

    _expectTheMapsLayers(_paintedShadows(tester), kElevationToShadow[1]!);
  });

  testWidgets('a card raised three levels casts the shadow of that level', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, MaterialCard(shadows: MaterialElevation.level3));

    _expectTheMapsLayers(_paintedShadows(tester), kElevationToShadow[3]!);
  });

  testWidgets('an outlined card draws a line and casts nothing', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, MaterialCard.outlined());

    expect(_paintedShadows(tester), isNull);
  });
}

/// [painted] is [framework]'s geometry, cast in black at 87%.
void _expectTheMapsLayers(List<BoxShadow>? painted, List<BoxShadow> framework) {
  expect(painted, isNotNull);
  final List<BoxShadow> layers = painted!;
  expect(layers, hasLength(framework.length));

  for (int i = 0; i < framework.length; i++) {
    expect(layers[i].offset, framework[i].offset, reason: 'layer ${i + 1}');
    expect(
      layers[i].blurRadius,
      framework[i].blurRadius,
      reason: 'layer ${i + 1}',
    );
    expect(
      layers[i].spreadRadius,
      framework[i].spreadRadius,
      reason: 'layer ${i + 1}',
    );
    // A colour's alpha is a share of one in the current API, so 87% of the map's opacity
    // is a multiplication rather than a byte to round.
    expect(
      layers[i].color.a,
      closeTo(framework[i].color.a * 0.87, 0.005),
      reason: 'layer ${i + 1} is the map’s shade at 87%',
    );
  }
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
