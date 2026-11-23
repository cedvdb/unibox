import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

void main() {
  testWidgets('the catalogue draws native components at a narrow width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 375,
              child: FlutterLinkScope(
                open: (String url) {},
                child: renderFlutter(
                  buildMaterialSection(),
                  scope: core.UniboxScope(theme: MaterialPalette.lightTheme),
                  substitutions: materialComponents(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
