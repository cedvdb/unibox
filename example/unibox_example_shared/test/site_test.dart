import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

void main() {
  test(
    'shows HTML beside a live handover with only the two selling points',
    () {
      final sources = <String>[];
      final page = buildSitePage(
        frame: ({required src, required title}) {
          sources.add(src);
          return TextNode(title);
        },
      );
      expect(sources, <String>['web/listings/', 'web/takeover/']);
      final text = textsIn(page).join(' ');
      expect(text, contains('One UI. Two renderers.'));
      expect(text, contains('HTML first. Flutter next.'));
      expect(text.split(RegExp(r'\s+')).length, lessThan(180));
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
