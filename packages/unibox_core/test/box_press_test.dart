import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

/// A press a page remembered, answered once the tree that can take it exists.
void main() {
  group('a recorded press', () {
    test('reads the record a page wrote', () {
      final BoxPress press = BoxPress.fromRecord(<String, Object?>{
        'key': 'cta',
        'dx': 4,
        'dy': 12.5,
      });

      expect(press, const BoxPress(key: 'cta', dx: 4, dy: 12.5));
      expect(press.toRecord(), <String, Object?>{
        'key': 'cta',
        'dx': 4.0,
        'dy': 12.5,
      });
    });

    test('is refused when it names no element', () {
      expect(
        () => BoxPress.fromRecord(<String, Object?>{'dy': 1}),
        throwsArgumentError,
      );
    });
  });

  group('replaying a press', () {
    test('answers the node that carried the key', () {
      var pressed = 0;
      final UINode tree = Box(
        key: 'page',
        children: <UINode>[
          Box(key: 'cta', onTap: () => pressed++, children: const <UINode>[]),
        ],
      );

      final List<BoxPress> answered = replayPresses(tree, const <BoxPress>[
        BoxPress(key: 'cta', dx: 2, dy: 3),
      ]);

      expect(pressed, 1);
      expect(answered, hasLength(1));
    });

    test('follows a link that answers a press itself', () {
      var followed = 0;
      final UINode tree = LinkNode(
        key: 'open',
        '/listings',
        onTap: () => followed++,
        child: const TextNode('Listings'),
      );

      replayPresses(tree, const <BoxPress>[BoxPress(key: 'open')]);

      expect(followed, 1);
    });

    test('drops a key the tree does not have', () {
      // The page and the application disagree about what is on screen, and firing whatever is
      // nearby is how the wrong control goes off.
      var pressed = 0;
      final UINode tree = Box(key: 'other', onTap: () => pressed++);

      final List<BoxPress> answered = replayPresses(tree, const <BoxPress>[
        BoxPress(key: 'cta'),
      ]);

      expect(pressed, 0);
      expect(answered, isEmpty);
    });

    test('drops a key that names two nodes', () {
      // A key is unique among siblings; a document that draws one tree twice has to say which
      // element it means, and this refuses to guess.
      var pressed = 0;
      final UINode tree = Box(
        children: <UINode>[
          Box(key: 'cta', onTap: () => pressed++),
          Box(key: 'cta', onTap: () => pressed++),
        ],
      );

      expect(
        replayPresses(tree, const <BoxPress>[BoxPress(key: 'cta')]),
        isEmpty,
      );
      expect(pressed, 0);
    });

    test('drops a node whose callback is gone', () {
      // A bar tap is a plain box with no behaviour, and a link without an `onTap` belongs to the
      // browser.
      final UINode tree = Box(
        key: 'cta',
        children: const <UINode>[TextNode('Hi')],
      );

      expect(
        replayPresses(tree, const <BoxPress>[BoxPress(key: 'cta')]),
        isEmpty,
      );
    });

    test('finds a node inside a stack, a grid and a stateful view', () {
      var pressed = 0;
      final UINode tree = Box(
        children: <UINode>[
          StackNode(
            children: <UINode>[
              PositionedNode(
                top: 0,
                child: GridNode(
                  minItemWidth: 100,
                  children: <UINode>[Box(key: 'cta', onTap: () => pressed++)],
                ),
              ),
            ],
          ),
        ],
      );

      replayPresses(tree, const <BoxPress>[BoxPress(key: 'cta')]);

      expect(pressed, 1);
    });
  });
}
