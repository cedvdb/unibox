import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A card casts at most the shadow a Flutter card casts, at the same height.
///
/// `unibox_material` is pure Dart and cannot ask Flutter what a level looks like, so
/// `MaterialElevation` writes the numbers down; this is the test that keeps them honest,
/// and it compares the two *drawings* rather than two tables. `kElevationToShadow` is not
/// the oracle it looks like: a `Material` — and so every `Card` — draws its shadow with
/// `Canvas.drawShadow`, one opaque colour through a light model, and the map is what
/// Flutter states for the widgets that *do* need a `BoxShadow` list, such as a menu's
/// panel. A ceiling rather than a match, because a shadow a few per cent over reads as a
/// card raised higher than the card beside it.
void main() {
  testWidgets('a resting card casts at most the shadow a Flutter card casts', (
    WidgetTester tester,
  ) async {
    await _expectSameShadow(
      tester,
      ours: const MaterialCard(width: 200, height: 100),
      elevation: 1,
    );
  });

  testWidgets(
    'a card raised three levels casts at most what a card at three dp casts',
    (WidgetTester tester) async {
      await _expectSameShadow(
        tester,
        ours: const MaterialCard(
          width: 200,
          height: 100,
          shadows: MaterialElevation.level3,
        ),
        elevation: 3,
      );
    },
  );

  testWidgets('an outlined card draws a line and casts nothing', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, MaterialCard.outlined());

    expect(_paintedShadows(tester), isNull);
  });
}

/// Pumps a card of ours beside the framework's own, and holds ours under it.
///
/// The comparison samples the rows under the card's bottom edge and the columns beside
/// its left edge — where an elevation is read. How a shadow is *rasterised* is outside the
/// parity contract, as `unibox_testing` says beside the font face and the line breaking, so
/// each sample allows a fiftieth of the page's contrast of noise above the framework's and
/// a twentieth below it: the ceiling is the decision, a shadow that never reads heavier than
/// the card beside it, and the floor is what keeps a card that casts nothing from passing.
Future<void> _expectSameShadow(
  WidgetTester tester, {
  required MaterialCard ours,
  required double elevation,
}) async {
  // `flutter_test` turns shadows off — it paints a stroked outline in their place, which
  // is what `debugDisableShadows` is for — so the one comparison that is *about* a shadow
  // has to turn them back on, and put the flag back before the test body returns: the
  // binding checks that no painting debug variable was left set.
  debugDisableShadows = false;
  try {
    await _compareShadows(tester, ours: ours, elevation: elevation);
  } finally {
    debugDisableShadows = true;
  }
}

/// Pumps both cards, rasterises them and compares the shadows they painted.
Future<void> _compareShadows(
  WidgetTester tester, {
  required MaterialCard ours,
  required double elevation,
}) async {
  tester.view.physicalSize = const Size(400, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final GlobalKey frameworkKey = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: ThemeData(useMaterial3: true),
        child: RepaintBoundary(
          key: frameworkKey,
          child: _page(
            Card(
              elevation: elevation,
              margin: EdgeInsets.zero,
              child: const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      ),
    ),
  );
  final List<double> framework = await _shadowAround(
    tester,
    frameworkKey,
    tester.getRect(find.byType(Card)),
  );

  final GlobalKey oursKey = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: oursKey,
        child: _page(renderFlutter(ours, theme: MaterialPalette.lightTheme)),
      ),
    ),
  );
  final List<double> painted = await _shadowAround(
    tester,
    oursKey,
    tester.getRect(
      find.byWidgetPredicate(
        (Widget widget) => widget is FlutterBox && widget.box is MaterialCard,
      ),
    ),
  );

  for (int i = 0; i < framework.length; i++) {
    expect(
      painted[i],
      lessThanOrEqualTo(framework[i] + 0.02),
      reason: '${_where(i)} is heavier than the framework at ${elevation}dp',
    );
    expect(
      painted[i],
      greaterThan(framework[i] - 0.06),
      reason: '${_where(i)} is lighter than the framework at ${elevation}dp',
    );
  }
}

/// The darkness of the page around [card], as rows below it and columns beside it.
///
/// Entry `i` below eight is the row `i + 1` under the card's bottom edge, read at its
/// horizontal centre; after that it is the column beside the card's left edge, read at
/// its vertical centre. Zero is white and one is black.
Future<List<double>> _shadowAround(
  WidgetTester tester,
  GlobalKey key,
  Rect card,
) async {
  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image = (await tester.runAsync(() => boundary.toImage()))!;
  final ByteData data = (await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final Uint8List bytes = data.buffer.asUint8List();
  final int width = image.width;

  double at(int x, int y) {
    final int offset = (y * width + x) * 4;
    return 1 -
        (bytes[offset] + bytes[offset + 1] + bytes[offset + 2]) / 3 / 255;
  }

  final int centreX = card.center.dx.round();
  final int centreY = card.center.dy.round();
  final int left = card.left.round();

  image.dispose();
  return <double>[
    for (int i = 0; i < 5; i++) at(centreX, card.bottom.ceil() + i),
    for (int i = 0; i < 4; i++) at(left - 1 - i, centreY),
  ];
}

/// The name of the sample at [index], for a failure message.
String _where(int index) => index < 5
    ? 'the row ${index + 1} under the card'
    : 'the column ${index - 4} beside the card';

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

/// The card on a white page, the way a tree is drawn over a surface.
Widget _page(Widget card) => ColoredBox(
  color: const Color(0xFFFFFFFF),
  child: Center(child: card),
);
