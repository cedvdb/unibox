import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

/// The band that answers *what do I deploy*.
///
/// It is written as copy rather than as a diagram, so a test is the only thing that keeps
/// the two cards honest: each one has to name a way and what it costs, because a band
/// that lists only benefits leaves the reader to find the trade on their own.
Iterable<UINode> _nodes(UINode root) sync* {
  yield root;
  for (final UINode child in root.children) {
    yield* _nodes(child);
  }
}

List<String> _texts(UINode root) =>
    _nodes(root)
        .whereType<TextNode>()
        .map((TextNode text) => text.text)
        .toList();

void main() {
  group('the ways band', () {
    test('names both ways, and what each costs', () {
      final UINode band = buildWaysSection();
      final String copy = _texts(band).join('\n');

      expect(copy, contains('Flutter takes the page over'));
      expect(copy, contains('The page draws itself'));

      // The cost of the handover is what it does *not* require, and the cost of a page
      // that draws itself is what it does.
      expect(copy, contains('stay ordinary Flutter'));
      expect(copy, contains('Every interaction is a node'));
    });

    test('is two cards, so the two ways read as alternatives', () {
      final List<MaterialCard> cards = _nodes(buildWaysSection())
          .whereType<MaterialCard>()
          .toList();

      expect(cards, hasLength(2));
      // Each card holds its own label, title, a lead and three points; the points carry a
      // bullet as a node, so the words alone are not the count.
      for (final MaterialCard card in cards) {
        expect(_texts(card).first, isNotEmpty);
        expect(_texts(card).where((String text) => text != '·'), hasLength(6));
      }
    });

    test('keeps the rest of an application out of it', () {
      // The objection a reader arrives with is that all of their app has to move; the
      // band answers it in one sentence rather than leaving it to the README.
      expect(
        _texts(buildWaysSection()).join(' '),
        contains('stays ordinary Flutter, screen for screen'),
      );
    });
  });
}
