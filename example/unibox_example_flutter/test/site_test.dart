import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_flutter/site.dart';

import 'app_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  test('selects the component reference and the shared example rendering', () {
    expect(
      hostedPageFor(Uri.parse('https://example.com/flutter/components/')),
      HostedPage.components,
    );
    expect(
      hostedPageFor(Uri.parse('https://example.com/flutter/listings/')),
      HostedPage.example,
    );
    expect(
      hostedPageFor(Uri.parse('https://example.com/web/takeover/')),
      HostedPage.example,
    );
    expect(
      hostedPageFor(Uri.parse('https://example.com/flutter/')),
      HostedPage.site,
    );
  });
  for (final width in <double>[375, 1440]) {
    testWidgets('the renderer comparison renders at $width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SiteApp());
      await tester.pumpAndSettle();
      expect(find.text('Flutter UI. Searchable HTML.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
