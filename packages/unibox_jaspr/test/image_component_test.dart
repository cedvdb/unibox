import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

void main() {
  group('ImageNode', () {
    testComponents('renders an img with the source and an empty alt', (
      tester,
    ) async {
      pumpNode(tester, const core.ImageNode('https://example.com/a.png'));

      expect(find.tag('img'), findsOneComponent);
      expect(attributesOf(find.tag('img')), <String, String>{
        'src': 'https://example.com/a.png',
        'alt': '',
        // The defaults are written out: the model's answer, not the user agent's.
        'loading': 'eager',
        'fetchpriority': 'auto',
        'data-unibox-node': 'image',
      });
      expect(stylesOf(find.tag('img')), <String, String>{
        'display': 'block',
        'object-fit': 'scale-down',
      });
    });

    testComponents('sets the alt text', (tester) async {
      pumpNode(
        tester,
        const core.ImageNode('assets/logo.png', alt: 'Unibox logo'),
      );

      expect(attributesOf(find.tag('img'))['alt'], 'Unibox logo');
    });

    testComponents('maps dimensions to css units', (tester) async {
      pumpNode(
        tester,
        const core.ImageNode(
          'assets/logo.png',
          width: 200,
          height: double.infinity,
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('img'));

      expect(styles['width'], '200px');
      expect(styles['height'], '100%');
    });

    testComponents('writes the candidates of a responsive image', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.ImageNode(
          'assets/logo.png',
          srcSet: <int, String>{800: 'logo-800.png', 200: 'logo-200.png'},
          sizes: '(min-width: 800px) 640px, 100vw',
        ),
      );

      final Map<String, String> attributes = attributesOf(find.tag('img'));

      expect(attributes['srcset'], 'logo-200.png 200w, logo-800.png 800w');
      expect(attributes['sizes'], '(min-width: 800px) 640px, 100vw');
    });

    testComponents('writes when and how hard to fetch', (tester) async {
      pumpNode(
        tester,
        const core.ImageNode(
          'assets/hero.png',
          loading: core.ImageLoading.lazy,
          fetchPriority: core.ImageFetchPriority.high,
        ),
      );

      final Map<String, String> attributes = attributesOf(find.tag('img'));

      expect(attributes['loading'], 'lazy');
      expect(attributes['fetchpriority'], 'high');
    });

    testComponents('gives the browser the aspect ratio before it fetches', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.ImageNode('assets/logo.png', width: 200, height: 120.6),
      );

      final Map<String, String> attributes = attributesOf(find.tag('img'));

      expect(attributes['width'], '200');
      expect(attributes['height'], '121');
    });

    testComponents('leaves the attributes off a size the browser cannot use', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.ImageNode('assets/logo.png', height: double.infinity),
      );

      final Map<String, String> attributes = attributesOf(find.tag('img'));

      expect(attributes.containsKey('width'), isFalse);
      expect(attributes.containsKey('height'), isFalse);
    });

    testComponents('maps every image fit to object-fit', (tester) async {
      const Map<core.ImageFit, String> fits = {
        core.ImageFit.cover: 'cover',
        core.ImageFit.contain: 'contain',
        core.ImageFit.fill: 'fill',
        core.ImageFit.scaleDown: 'scale-down',
      };

      for (final MapEntry<core.ImageFit, String> entry in fits.entries) {
        pumpNode(tester, core.ImageNode('assets/logo.png', fit: entry.key));

        expect(stylesOf(find.tag('img'))['object-fit'], entry.value);
      }
    });

    testComponents('maps the corner radius', (tester) async {
      pumpNode(
        tester,
        const core.ImageNode(
          'assets/logo.png',
          width: 64,
          height: 64,
          borderRadius: 8,
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('img'));

      expect(styles['border-radius'], '8px');
      expect(styles['object-fit'], 'scale-down');
    });

    testComponents(
      'writes the default fit instead of leaving it to the browser',
      (tester) async {
        pumpNode(tester, const core.ImageNode('assets/logo.png'));

        // A browser stretches an image over its box when `object-fit` is absent,
        // while a Flutter `Image` scales it down: the model decides, not the user
        // agent.
        expect(stylesOf(find.tag('img'))['object-fit'], 'scale-down');
      },
    );

    testComponents('renders inside a box next to text', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          gap: 8,
          children: [
            core.ImageNode('assets/logo.png', width: 32, height: 32),
            core.TextNode('Unibox'),
          ],
        ),
      );

      expect(find.tag('div'), findsOneComponent);
      expect(find.tag('img'), findsOneComponent);
      expect(find.tag('span'), findsOneComponent);
    });
  });
}
