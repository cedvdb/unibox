import 'package:test/test.dart';
import 'package:unibox_example_jaspr/site/page_for_path.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

void main() {
  group('examplePageForPath', () {
    test('finds the page a document was exported for', () {
      expect(examplePageForPath('/web/listings/'), ExamplePage.apartments);
      expect(examplePageForPath('/web/signup/'), ExamplePage.signup);
    });

    test('finds it whether or not the host keeps the trailing slash', () {
      expect(examplePageForPath('/web/listings'), ExamplePage.apartments);
      expect(examplePageForPath('/unibox/web/signup/'), ExamplePage.signup);
    });

    test('finds it when the browser names the document itself', () {
      // The runtime answered `null` here and drew the site's page over the listing the
      // host had served. A document scrolls and takes its bar with it, while the app
      // keeps the bar and scrolls the list under it, so the same URL looked like two
      // different scroll models rather than two different pages.
      expect(
        examplePageForPath('/web/listings/index.html'),
        ExamplePage.apartments,
      );
      expect(
        examplePageForPath('/unibox/web/signup/index.html'),
        ExamplePage.signup,
      );
    });

    test('leaves the site to the site', () {
      expect(examplePageForPath('/'), isNull);
      expect(examplePageForPath('/unibox/'), isNull);
      expect(examplePageForPath('/index.html'), isNull);
    });

    test('does not read a destination out of a directory beside it', () {
      expect(examplePageForPath('/listings/'), isNull);
      expect(examplePageForPath('/listings/index.html'), isNull);
      expect(examplePageForPath('/webx/listings/'), isNull);
      expect(examplePageForPath('/web/other/'), isNull);
    });
  });
}
