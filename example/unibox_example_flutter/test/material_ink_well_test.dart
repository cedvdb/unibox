import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';

/// The ink is a layer of positioned boxes, so the suite can count it: a press
/// adds one drop, and a drop that has spread takes itself away.
///
/// A well lives in `unibox_material`, which no renderer may depend on, so the
/// check of what a press looks like on a real widget sits here, in the example
/// that depends on both.
void main() {
  testWidgets('leaves ink where the press landed, then takes it away', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: renderFlutter(
              Box(
                backgroundColor: const BoxColor(0xFF6750A4),
                borderRadius: 20,
                children: <UINode>[
                  MaterialInkWell(
                    onTap: () {},
                    borderRadius: 20,
                    ink: const BoxColor(0xFFFFFFFF),
                    padding: const BoxSpacing.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: TextNode(
                      'Press me',
                      style: MaterialTypography.labelLarge.copyWith(
                        color: const BoxColor(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // The resting well: the fill, the label, and no ink.
    expect(find.text('Press me'), findsOneWidget);
    expect(find.byType(Positioned), findsNothing);

    await tester.tapAt(tester.getCenter(find.text('Press me')));
    await tester.pump();

    // The press reached the well, which started a drop inside it.
    expect(find.byType(Positioned), findsOneWidget);

    await tester.pump(materialInkDuration + const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byType(Positioned), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
