import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

void main() {
  test(
    'compares independent hosts and keeps handover a separate destination',
    () {
      final sources = <String>[];
      final page = buildSitePage(
        frame: ({required src, required title}) {
          sources.add(src);
          return TextNode(title);
        },
      );
      expect(sources, <String>['web/listings/', 'flutter/listings/']);
      expect(
        flatten(page).whereType<LinkNode>().map((node) => node.url),
        contains('web/takeover/'),
      );
      expect(
        flatten(page)
            .whereType<TextNode>()
            .where((node) => node.headingLevel == 1),
        hasLength(1),
      );
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
}
