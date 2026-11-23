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
  test('an icon button keeps its native action, label and count', () {
    int calls = 0;
    final MaterialIconButton button = MaterialIconButton(
      icon: const TextNode('x'),
      label: 'Close',
      badgeCount: 3,
      onTap: () => calls++,
    );
    expect(button.requiresWidgetSubstitution, isTrue);
    expect(button.label, 'Close');
    expect(button.badgeCount, 3);
    button.onPressed?.call();
    expect(calls, 1);
    expect(
      nodes(button).whereType<StatefulNode<Object, Store<Object>>>(),
      isEmpty,
    );
  });
  test(
    'a disabled icon button exposes its disabled state to the native host',
    () {
      expect(
        MaterialIconButton(icon: const TextNode('x'), enabled: false).enabled,
        isFalse,
      );
    },
  );
}
