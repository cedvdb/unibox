import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

import 'support/tree.dart';

void main() {
  test(
    'the catalogue demonstrates only the supported native Material vocabulary',
    () {
      final List<UINode> nodes = flatten(buildMaterialSection());
      expect(nodes.whereType<MaterialCard>(), hasLength(3));
      expect(nodes.whereType<MaterialButton>(), hasLength(4));
      expect(nodes.whereType<MaterialChip>(), hasLength(3));
      expect(nodes.whereType<MaterialSegmentedButton>(), hasLength(1));
      expect(nodes.whereType<StatefulNode<Object, Store<Object>>>(), isEmpty);
    },
  );
  test('the material section compares the reference in both renderings', () {
    final sources = <String>[];
    final section = buildMaterialComparison(
      frame: ({required src, required title}) {
        sources.add(src);
        return TextNode(title);
      },
    );

    // Two windows over one tree: the document the web renderer writes, and the
    // application that draws it with Flutter's own controls. A specimen drawn on the
    // page as well would be a third rendering to keep in step.
    expect(sources, <String>['web/components/', 'flutter/components/']);
    expect(flatten(section).whereType<MaterialCard>(), isEmpty);
    expect(flatten(section).whereType<MaterialButton>(), isEmpty);
  });
  test('leaves the colour roles out of the catalogue', () {
    // A role is a value, not a specimen: a swatch of four colours compares nothing,
    // and the components are the subject of the page.
    expect(textsIn(buildComponentReference()), isNot(contains('Colour roles')));
  });
  test(
    'renders Material and all type roles inline without navigation links',
    () {
      final reference = buildComponentReference();
      final List<UINode> nodes = flatten(reference);
      expect(nodes.whereType<LinkNode>(), isEmpty);
      expect(
        nodes.whereType<MaterialButton>().every((node) => node.url == null),
        isTrue,
      );
      expect(
        nodes.whereType<MaterialChip>().every((node) => node.url == null),
        isTrue,
      );
      for (final control in nodes.whereType<MaterialSegmentedButton>()) {
        expect(
          control.segments.every((segment) => segment.url == null),
          isTrue,
        );
      }
      final textStyles = nodes
          .whereType<TextNode>()
          .map((node) => node.computedStyle)
          .toList();
      for (final style in MaterialTypography.styles.values) {
        expect(textStyles, contains(style));
      }
    },
  );
}
