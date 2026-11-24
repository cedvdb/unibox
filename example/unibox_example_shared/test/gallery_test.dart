import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

Iterable<UINode> descendants(UINode node) sync* {
  yield node;
  for (final UINode child in node.children) {
    yield* descendants(child);
  }
}

void main() {
  test(
    'the catalogue demonstrates only the supported native Material vocabulary',
    () {
      final List<UINode> nodes = descendants(buildMaterialSection()).toList();
      expect(nodes.whereType<MaterialCard>(), hasLength(3));
      expect(nodes.whereType<MaterialButton>(), hasLength(4));
      expect(nodes.whereType<MaterialChip>(), hasLength(3));
      expect(nodes.whereType<MaterialSegmentedButton>(), hasLength(1));
      expect(nodes.whereType<StatefulNode<Object, Store<Object>>>(), isEmpty);
    },
  );
  test(
    'renders Material and all type roles inline without navigation links',
    () {
      final reference = buildComponentReference();
      final nodes = descendants(reference).toList();
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
