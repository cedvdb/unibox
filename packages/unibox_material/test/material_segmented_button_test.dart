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

  test(
    'a segment puts its label beside the mark, and the pair in the middle',
    () {
      final MaterialSegmentedButton button = MaterialSegmentedButton(
        selected: 0,
        onSelect: (int value) {},
        segments: const <MaterialSegment>[
          MaterialSegment(label: TextNode('Day')),
        ],
      );

      // The row holding the mark and the label: full width, so the pair has a room to be
      // centred in, and centred — which is what Material's own control draws and what the
      // app substitutes for this node. A share of the room here instead put the mark against
      // the segment's edge while the app drew it beside its words.
      final Box row = nodes(button).whereType<Box>().firstWhere(
        (Box box) =>
            box.computedStyle.resolvedDirection == Axis.horizontal &&
            box.children.length == 2,
      );
      expect(row.computedStyle.width, double.infinity);
      expect(row.computedStyle.mainAlign, MainAlign.center);

      // The label hugs its words: a zero share is `flex: 0 1 auto` on the page and a
      // `Flexible` in Flutter, so a label too long for the room still shrinks and cuts
      // rather than widening the pill.
      final Box label = row.children.last as Box;
      expect(label.computedStyle.flex, 0);
      expect(label.computedStyle.width, isNull);
    },
  );
}
