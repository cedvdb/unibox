import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// What the box under test painted, as the pixels it wrote.
///
/// Rasterising is the one thing a widget test leaves its own clock for, so the layer becomes
/// an image inside [WidgetTester.runAsync].
Future<({ByteData pixels, int width})> _painted(WidgetTester tester) async {
  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byType(RepaintBoundary).last,
  );
  final ui.Image image = (await tester.runAsync(boundary.toImage))!;
  final ByteData pixels = (await tester.runAsync<ByteData>(
    () async => (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!,
  ))!;
  final int width = image.width;

  image.dispose();

  return (pixels: pixels, width: width);
}

/// One channel of the pixel at ([x], [y]) — red first, alpha last.
int _channel(ByteData pixels, int width, int x, int y, int channel) =>
    pixels.getUint8((y * width + x) * 4 + channel);

/// What a box paints of its shadows, which is the one thing about them a tree cannot state.
///
/// The expected answer is CSS's: an outer shadow is drawn as if the box were opaque and
/// clipped to the outside of it, so a hairline is one pixel below the box and a box with no
/// fill does not paint its own rectangle.
void main() {
  const double pad = 8;

  /// Renders [node] on a layer with room around it for a shadow to land in.
  Future<void> pumpShadowed(WidgetTester tester, core.UINode node) => pumpNode(
    tester,
    node,
    wrap: (Widget child) => RepaintBoundary(
      child: Padding(padding: const EdgeInsets.all(pad), child: child),
    ),
  );

  testWidgets('paints a shadow outside the box and not through it', (
    tester,
  ) async {
    await pumpShadowed(
      tester,
      const core.Box(
        width: 100,
        height: 40,
        // The hairline the catalogue's tab bar draws under its tabs.
        shadows: <core.BoxShadow>[
          core.BoxShadow(color: core.BoxColor(0xFF000000), offsetY: 1),
        ],
      ),
    );

    final ({ByteData pixels, int width}) canvas = await _painted(tester);
    final int x = pad.toInt() + 50;

    // Inside the box: nothing. The bug this pins made a 48-pixel tab bar a solid band of its
    // own hairline, because the shadow was painted *through* a box that paints no fill.
    expect(_channel(canvas.pixels, canvas.width, x, pad.toInt() + 20, 3), 0);
    // The pixel the one-pixel offset puts outside the box: the hairline itself.
    expect(
      _channel(canvas.pixels, canvas.width, x, pad.toInt() + 40, 3),
      greaterThan(0),
    );
  });

  testWidgets('leaves the fill of a shadowed box alone', (tester) async {
    // The same clipping from the other side: a shadow under a fill is hidden by it, so the
    // inside is one rectangle of the background rather than a darker one where they overlap.
    await pumpShadowed(
      tester,
      const core.Box(
        width: 100,
        height: 40,
        backgroundColor: core.BoxColor(0xFFFF0000),
        shadows: <core.BoxShadow>[
          core.BoxShadow(color: core.BoxColor(0xFF0000FF), offsetY: 2),
        ],
      ),
    );

    final ({ByteData pixels, int width}) canvas = await _painted(tester);
    final int x = pad.toInt() + 50;
    final int y = pad.toInt() + 20;

    expect(_channel(canvas.pixels, canvas.width, x, y, 0), 255);
    expect(_channel(canvas.pixels, canvas.width, x, y, 1), 0);
    expect(_channel(canvas.pixels, canvas.width, x, y, 2), 0);
  });
}
