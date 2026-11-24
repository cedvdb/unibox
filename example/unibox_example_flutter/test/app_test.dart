import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_flutter/main.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_example_shared/unibox_example_shared.dart';

Future<void> loadFonts() async {
  for (final weight in <String>['400', '500', '600', '700']) {
    final bytes = ByteData.sublistView(
      File('assets/fonts/roboto-$weight.ttf').readAsBytesSync(),
    );
    await (FontLoader(
      'UniboxText',
    )..addFont(Future<ByteData>.value(bytes))).load();
  }
}

void main() {
  setUpAll(loadFonts);
  testWidgets(
    'renders exactly the text of the shared declaration with no extra controls',
    (tester) async {
      final declaration = buildListingExample(onSave: () {});
      Iterable<core.UINode> flatten(core.UINode node) sync* {
        yield node;
        for (final child in node.children) {
          yield* flatten(child);
        }
      }

      final expected = flatten(declaration)
          .whereType<core.TextNode>()
          .map((node) => node.text)
          .toList();
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();
      final actual = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
          .toList();
      expect(actual, expected);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a keyed region action opens a host-owned native dialog', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save these homes'));
    await tester.pumpAndSettle();
    expect(
      pressRecorded(const <core.BoxPress>[core.BoxPress(key: 'listing-save')]),
      hasLength(1),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Homes saved'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
  for (final width in <double>[375, 1200]) {
    testWidgets('the shared UI fits a $width wide surface with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
