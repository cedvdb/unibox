import 'dart:io' show File;
import 'dart:typed_data' show ByteData;

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_flutter/site.dart';

/// Loads the four weights the application ships under the family it names them with.
///
/// A widget test otherwise draws in the test font, which is wider and taller than Roboto: the
/// capture under the tabs wraps to three lines in it and overflows the page it sits in by four
/// pixels. The page was measured against the font the application bundles, so a test of the page
/// measures it against that font — the alternative is a suite that reports a difference no reader
/// can see and hides the one that matters behind it.
Future<void> loadFonts() async {
  for (final String weight in <String>['400', '500', '600', '700']) {
    final ByteData bytes = ByteData.sublistView(
      File('assets/fonts/roboto-$weight.ttf').readAsBytesSync(),
    );

    await (FontLoader(
      'UniboxText',
    )..addFont(Future<ByteData>.value(bytes))).load();
  }
}

/// The site page, as the Flutter host draws it.
///
/// The page itself is the tree `unibox_html` writes at `/`, so what is worth pinning here is
/// what the host alone decides: which address draws which tree, and that the page the
/// document renders is the page this build renders.
void main() {
  group('hostedPageFor', () {
    test('draws the site page at the root of the Flutter build', () {
      expect(
        hostedPageFor(Uri.parse('https://cedvdb.github.io/unibox/flutter/')),
        HostedPage.site,
      );
      expect(
        hostedPageFor(Uri.parse('http://localhost:8000/flutter/')),
        HostedPage.site,
      );
    });

    test('draws the example at the route below it, and in a takeover', () {
      // `/flutter/listings/` is the example served on its own, and a takeover document is
      // the page an HTML frame becomes — neither of them is the site.
      expect(
        hostedPageFor(
          Uri.parse('https://cedvdb.github.io/unibox/flutter/listings/'),
        ),
        HostedPage.example,
      );
      expect(
        hostedPageFor(
          Uri.parse('https://cedvdb.github.io/unibox/web/takeover/?seed=rose'),
        ),
        HostedPage.example,
      );
    });

    test('draws the example where there is no address to route on', () {
      // A phone, a desk and a test have no build whose root they could be.
      expect(
        hostedPageFor(Uri.parse('file:///Users/ada/unibox_example_flutter')),
        HostedPage.example,
      );
      expect(
        hostedPageFor(Uri.parse('http://localhost:3000/')),
        HostedPage.example,
      );
    });
  });

  group('SiteApp', () {
    testWidgets('draws the whole page, down to the catalogue it closes on', (
      tester,
    ) async {
      await loadFonts();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const SiteApp());
      await tester.pump();

      // The claim, the two branches of the diagram and the band that closes the page: three
      // bands that say the tree reached the renderer whole rather than a part of it.
      expect(find.text('Flutter UI. Searchable HTML.'), findsOneWidget);
      expect(find.text('HTML and CSS'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Material'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The spinner in the catalogue owns a ticker, and leaving the page is what stops it.
      await tester.pumpWidget(const SizedBox());
    });
  });
}
