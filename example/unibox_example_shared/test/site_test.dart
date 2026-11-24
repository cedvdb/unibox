import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

void main() {
  UINode frame({required String src, required String title}) => TextNode(title);
  test(
    'restores the original section order with the current matching examples',
    () {
      final sources = <String>[];
      final page = buildSitePage(
        frame: ({required src, required title}) {
          sources.add(src);
          return TextNode(title);
        },
      );
      expect(sources, <String>[
        'web/listings/',
        'web/takeover/',
        // The Material section is the same declaration in both renderings, so it frames
        // the component reference twice: once as markup, once as Flutter's own controls.
        'web/components/',
        'flutter/components/',
      ]);
      final headings = flatten(page)
          .whereType<TextNode>()
          .where((node) => node.headingLevel != null && node.headingLevel! <= 2)
          .map((node) => node.text)
          .toList();
      expect(headings, <String>[
        'Flutter UI. Searchable HTML.',
        'HTML and CSS',
        'Flutter',
        'Make Flutter Web pages indexable',
        'Just boxes',
        'Material',
        'Typography',
      ]);
      expect(
        validateTree(
          page,
          scope: UniboxScope(
            theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
          ),
        ),
        isEmpty,
      );
    },
  );
  test(
    'keeps the restored hero copy short and its branching diagram visible',
    () {
      final hero = buildHeroSection(frame: frame);
      expect(
        textsIn(hero).join(' ').split(RegExp(r'\s+')).length,
        lessThan(110),
      );
      final keys = flatten(hero).map((node) => node.key);
      expect(
        keys,
        containsAll(<String>['hero-flow-html', 'hero-flow-flutter']),
      );
    },
  );
}
