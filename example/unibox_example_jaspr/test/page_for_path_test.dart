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
}
