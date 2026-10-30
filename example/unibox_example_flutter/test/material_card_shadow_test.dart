import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// A card casts the shadow the design file gives its level.
///
/// The oracle is `doc/shadows_material_3_pink_seed.png` in `unibox_material`: six
/// cards at levels 0 to 5, rendered at 2x, whose rows were read back out of the image one
/// pixel at a time. That is what a level in `MaterialElevation` is fitted to, so that is
/// what this test holds the renderer to — not a `Card`'s own shadow, which is
/// `Canvas.drawShadow`'s light model and a documented different thing: at level one it
/// reads `56, 40, 28, 17, 9` where the ladder reads `54, 32, 14, 4`, so a card here is a
/// little tighter than the card beside it in a Flutter application, on purpose.
///
/// A row is half a dp: the card is 120 dp wide, rendered at a device pixel ratio of two,
/// so the first row below its edge is half a dp down and the twelfth is six dp down. Six
/// parts of 255 is the allowance — a rasteriser may differ in how it draws a gaussian; the
/// shape is what the table states.
const Map<int, List<int>> _ladder = <int, List<int>>{
  1: <int>[54, 32, 14, 4, 0],
  2: <int>[62, 48, 37, 27, 18, 11, 6, 3, 1],
  3: <int>[64, 54, 45, 39, 32, 26, 19, 14, 10, 7],
  4: <int>[64, 58, 51, 45, 40, 35, 30, 25, 20, 16, 12, 10, 7, 5],
  5: <int>[65, 60, 54, 49, 44, 40, 36, 32, 28, 25, 21, 17, 14, 12, 9, 7],
};

const List<List<core.BoxShadow>> _levels = <List<core.BoxShadow>>[
  MaterialElevation.level1,
  MaterialElevation.level2,
  MaterialElevation.level3,
  MaterialElevation.level4,
  MaterialElevation.level5,
];

void main() {
  for (int level = 1; level <= 5; level++) {
    testWidgets('a card at level $level casts the ladder\'s level $level', (
      WidgetTester tester,
    ) async {
      debugDisableShadows = false;
      try {
        final List<int> painted = await _rowsBelow(tester, _levels[level - 1]);
        final List<int> ladder = _ladder[level]!;

        for (int row = 0; row < ladder.length; row++) {
          expect(
            painted[row],
            closeTo(ladder[row], 6),
            reason:
                'row ${row + 1} under a level $level card reads '
                '${painted[row]} where the ladder reads ${ladder[row]}',
          );
        }
      } finally {
        debugDisableShadows = true;
      }
    });
  }

  testWidgets('an outlined card draws a line and casts nothing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: renderFlutter(
          MaterialCard.outlined(),
          theme: MaterialPalette.lightTheme,
        ),
      ),
    );

    expect(_paintedShadows(tester), isNull);
  });
}

/// The darkness of the page under a card's bottom edge, row by row, out of 255.
///
/// The card is drawn at a device pixel ratio of two so a row is half a dp — the scale the
/// ladder was measured at — and the page is white, so the page's own darkness is zero.
Future<List<int>> _rowsBelow(
  WidgetTester tester,
  List<core.BoxShadow> shadows,
) async {
  tester.view.physicalSize = const Size(400, 400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final GlobalKey key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Center(
            child: renderFlutter(
              MaterialCard(width: 120, height: 120, shadows: shadows.cast()),
              theme: MaterialPalette.lightTheme,
            ),
          ),
        ),
      ),
    ),
  );

  final Rect card = tester.getRect(
    find.byWidgetPredicate(
      (Widget widget) => widget is FlutterBox && widget.box is MaterialCard,
    ),
  );
  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: 2),
  ))!;
  final ByteData data = (await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final Uint8List bytes = data.buffer.asUint8List();
  final int width = image.width;

  double at(int x, int y) {
    final int offset = (y * width + x) * 4;
    return 255 - (bytes[offset] + bytes[offset + 1] + bytes[offset + 2]) / 3;
  }

  final int x = (card.center.dx * 2).round();
  final int bottom = (card.bottom * 2).round();
  final List<int> rows = <int>[
    for (int row = 1; row <= 16; row++) at(x, bottom + row).round(),
  ];

  image.dispose();
  return rows;
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
