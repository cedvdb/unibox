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
      expect(nodes.whereType<MaterialCard>(), hasLength(1));
      expect(nodes.whereType<MaterialButton>(), hasLength(2));
      expect(nodes.whereType<MaterialChip>(), hasLength(1));
      expect(nodes.whereType<MaterialSegmentedButton>(), hasLength(1));
      expect(nodes.whereType<StatefulNode<Object, Store<Object>>>(), isEmpty);
    },
  );
}
