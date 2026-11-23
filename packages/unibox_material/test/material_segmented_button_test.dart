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
    'a segmented control declares supplied selection and native rendering',
    () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        selected: 1,
        onSelect: (int value) {},
        segments: const <MaterialSegment>[
          MaterialSegment(label: TextNode('Day')),
          MaterialSegment(label: TextNode('Week')),
        ],
      );
      expect(button.requiresWidgetSubstitution, isTrue);
      expect(button.selected, 1);
      expect(
        nodes(button).whereType<TextNode>().map((TextNode text) => text.text),
        containsAllInOrder(<String>['Day', 'Week']),
      );
      expect(
        nodes(button).whereType<StatefulNode<Object, Store<Object>>>(),
        isEmpty,
      );
    },
  );
  test('destination segments keep real links for the other pages', () {
    final MaterialSegmentedButton button = MaterialSegmentedButton(
      selected: 0,
      segments: const <MaterialSegment>[
        MaterialSegment(label: TextNode('Day'), url: '/day'),
        MaterialSegment(label: TextNode('Week'), url: '/week'),
      ],
    );
    expect(nodes(button).whereType<LinkNode>().single.url, '/week');
  });
}
