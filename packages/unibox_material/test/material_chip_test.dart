import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

Iterable<UINode> nodes(UINode node) sync* {
  yield node;
  for (final UINode child in node.children) {
    yield* nodes(child);
  }
}

void main() {
  test(
    'a chip exposes selection and separate removal without owning state',
    () {
      int calls = 0;
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Brussels'),
        selected: true,
        onRemove: () => calls++,
      );
      expect(chip.requiresWidgetSubstitution, isTrue);
      expect(chip.selected, isTrue);
      chip.onDeleted?.call();
      expect(calls, 1);
      expect(
        nodes(chip).whereType<StatefulNode<Object, Store<Object>>>(),
        isEmpty,
      );
    },
  );
  test('a navigation chip preserves its destination', () {
    final MaterialChip chip = MaterialChip(
      label: const TextNode('Brussels'),
      url: '/brussels',
    );
    expect(chip.url, '/brussels');
    expect(nodes(chip).whereType<LinkNode>().single.url, '/brussels');
  });
}
