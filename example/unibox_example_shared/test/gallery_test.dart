import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('the Material gallery', () {
    test('gives a segmented button the width its segments divide', () {
      // Measured at 375 and at 1440: the gallery's grid hands each of these buttons a
      // cell, so a button without a width is a 40 pixel pill stretched across it with
      // its segments hugging the left — two thirds of a control that is not there.
      // With a width, each segment takes an equal share: 102, 102, 102 at 375 and
      // 144, 144, 144 at 1440.
      final List<MaterialSegmentedButton> buttons = _nodesOf(
        buildMaterialGallery(),
      ).whereType<MaterialSegmentedButton>().toList();

      expect(buttons, hasLength(2));
      for (final MaterialSegmentedButton button in buttons) {
        expect(button.width, double.infinity);
        expect(
          button.children.whereType<Box>().where((Box box) => box.flex == 1),
          hasLength(3),
          reason: 'three segments share the width, so the dividers take none',
        );
      }
    });

    test('lets the rows of chips scroll rather than widen the page', () {
      // Four chips need 368 pixels and a phone's cell gives 311, so a row that neither
      // shrinks nor scrolls pushes the page sideways: the gallery measured a 400 pixel
      // document in a 375 pixel window before these rows scrolled.
      final List<Box> scrollers = _nodesOf(buildMaterialGallery())
          .whereType<Box>()
          .where((Box box) => box.overflow == Overflow.scroll)
          .toList();

      expect(scrollers, hasLength(2));
      expect(_textsIn(scrollers.first), contains('Two rooms'));
      expect(_textsIn(scrollers.last), contains('Garden'));
    });

    test(
      'draws the chosen segment with Material’s check, in place of its icon',
      () {
        final List<UINode> nodes = _nodesOf(buildMaterialGallery());

        // The chosen chip and the chosen segment of each of the two buttons: three
        // marks, and no text glyph standing in for one.
        expect(nodes.whereType<MaterialCheckMark>(), hasLength(3));
        // A segment that is not chosen still draws its own icon.
        expect(
          _textsIn(buildMaterialGallery()),
          containsAll(<String>['Grid', 'Map']),
        );
      },
    );
  });
}

/// Every node of [root], depth first, with every stateful node's first frame drawn.
///
/// A [StatefulNode] has no children until a renderer mounts it — the labels of the
/// chips and of the segments live inside their ink wells — so a plain walk of the
/// tree stops at the control and sees nothing inside it.
List<UINode> _nodesOf(UINode root) {
  final List<UINode> nodes = <UINode>[root];

  if (root is StatefulNode<Object, Store<Object>>) {
    final Store<Object> store = root.createStore();
    nodes.addAll(_nodesOf(root.viewFor(store.state, store)));
    store.dispose();
  }
  for (final UINode child in root.children) {
    nodes.addAll(_nodesOf(child));
  }

  return nodes;
}

/// The text of every [TextNode] in [root], depth first, with stateful nodes mounted.
List<String> _textsIn(UINode root) =>
    _nodesOf(root)
        .whereType<TextNode>()
        .map((TextNode node) => node.text)
        .toList();
