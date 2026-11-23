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
  test('a button declares content and navigation without owning a store', () {
    final MaterialButton button = MaterialButton.outlined(
      label: const TextNode('Save'),
      url: '/save',
    );
    expect(button.requiresWidgetSubstitution, isTrue);
    expect(button.variant, MaterialButtonVariant.outlined);
    expect(button.url, '/save');
    expect(nodes(button).whereType<LinkNode>().single.url, '/save');
    expect(nodes(button).whereType<TextNode>().single.text, 'Save');
    expect(
      nodes(button).whereType<StatefulNode<Object, Store<Object>>>(),
      isEmpty,
    );
  });
  test('a disabled button disables its document action and native state', () {
    final MaterialButton button = MaterialButton(
      label: const TextNode('Save'),
      enabled: false,
      onTap: () {},
    );
    expect(button.enabled, isFalse);
    expect(
      nodes(button)
          .whereType<Box>()
          .where((Box box) => box.onTap != null)
          .every((Box box) => !box.enabled),
      isTrue,
    );
  });
}
