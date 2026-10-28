import 'package:test/test.dart';
import 'package:unibox_example_jaspr/site/page_for_path.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

void main() {
  group('sitePageForPath', () {
    test('finds a page in the directory its document was written to', () {
      expect(sitePageForPath('/material/'), SitePage.material);
      expect(sitePageForPath('/showcase/'), SitePage.showcase);
    });

    test('finds the page whether or not the host keeps the trailing slash', () {
      expect(sitePageForPath('/material'), SitePage.material);
      expect(sitePageForPath('/material/index.html'), SitePage.material);
    });

    test('finds a page of a site served under a path prefix', () {
      expect(sitePageForPath('/unibox/showcase/'), SitePage.showcase);
    });

    test('leaves the home page to the fallback', () {
      expect(sitePageForPath('/'), isNull);
      expect(sitePageForPath('/unibox/'), isNull);
    });
  });

  group('examplePageForPath', () {
    test('finds the page a document was exported for', () {
      expect(examplePageForPath('/web/listings/'), ExamplePage.apartments);
      expect(examplePageForPath('/web/pricing/'), ExamplePage.pricing);
      expect(examplePageForPath('/web/signup/'), ExamplePage.signup);
    });

    test('finds it whether or not the host keeps the trailing slash', () {
      expect(examplePageForPath('/web/listings'), ExamplePage.apartments);
      expect(examplePageForPath('/unibox/web/signup/'), ExamplePage.signup);
    });

    test('finds it when the browser names the document itself', () {
      // The runtime answered `null` here and drew the site's front page over the
      // listing the host had served. A document scrolls and takes its bar with it,
      // while the app keeps the bar and scrolls the list under it, so the same URL
      // looked like two different scroll models rather than two different pages.
      expect(
        examplePageForPath('/web/listings/index.html'),
        ExamplePage.apartments,
      );
      expect(
        examplePageForPath('/unibox/web/pricing/index.html'),
        ExamplePage.pricing,
      );
      expect(
        examplePageForPath('/unibox/web/signup/index.html'),
        ExamplePage.signup,
      );
    });

    test('leaves the site pages to the site', () {
      expect(examplePageForPath('/'), isNull);
      expect(examplePageForPath('/material/'), isNull);
      expect(examplePageForPath('/unibox/showcase/index.html'), isNull);
    });

    test('does not read a destination out of a directory beside it', () {
      expect(examplePageForPath('/listings/'), isNull);
      expect(examplePageForPath('/listings/index.html'), isNull);
      expect(examplePageForPath('/webx/listings/'), isNull);
      expect(examplePageForPath('/web/other/'), isNull);
    });
  });
}
