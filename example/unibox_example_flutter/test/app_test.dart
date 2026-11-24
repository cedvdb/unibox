import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_flutter/main.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_core/unibox_core.dart' as core;

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
  testWidgets('host search rebuilds the shared region with filtered data', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(FilterChip), findsOneWidget);
    expect(find.text('Rue de Turenne 12'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Berlin');
    await tester.pumpAndSettle();
    expect(find.text('Rue de Turenne 12'), findsNothing);
    expect(find.text('Oranienstraße 4'), findsOneWidget);
    expect(find.text('1 home across Europe'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.byType(FilterChip));
    await tester.pumpAndSettle();
    expect(find.text('2 homes across Europe'), findsOneWidget);
    expect(find.text('Rue de Turenne 12'), findsNothing);
    expect(find.text('Calle de la Palma 9'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
  testWidgets('a keyed region action opens a host-owned native dialog', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save this search'));
    await tester.pumpAndSettle();
    expect(
      pressRecorded(const <core.BoxPress>[core.BoxPress(key: 'listing-save')]),
      hasLength(1),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Search saved'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
  for (final width in <double>[375, 1200]) {
    testWidgets(
      'the mixed host fits a $width wide surface with enlarged text',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(const ExampleApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
