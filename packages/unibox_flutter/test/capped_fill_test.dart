import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

void main() {
  for (final double width in <double>[320, 1440]) {
    testWidgets('a centred capped fill yields to a $width pixel row', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: renderFlutter(
              core.Box(
                width: width,
                direction: core.Axis.horizontal,
                mainAlign: core.MainAlign.center,
                children: const <core.UINode>[
                  core.Box(
                    key: 'measure',
                    width: double.infinity,
                    maxWidth: 1080,
                    height: 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final Rect child = tester.getRect(
        find.byKey(const ValueKey<Object>('measure')),
      );
      final double expected = width < 1080 ? width : 1080;
      expect(child.width, expected);
      expect(child.left, (width - expected) / 2);
      expect(tester.takeException(), isNull);
    });
  }
}
