import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_testing/unibox_testing.dart';

/// A component of this test's own, so a wrong expectation can be played against a real store.
final class _Store extends core.StateStore<int> {
  _Store() : super(0);

  void raise() => state = state + 1;
}

final class _Counter extends core.StatefulNode<int, _Store> {
  _Counter()
    : super(
        create: _Store.new,
        view: (int state, _Store store) => core.Box(
          key: 'raise',
          onTap: store.raise,
          children: <core.UINode>[core.TextNode('$state', key: 'count')],
        ),
      );
}

void main() {
  group('the behaviour table', () {
    for (final BehaviourCase behaviourCase in behaviourCases) {
      test(behaviourCase.description, () async {
        expect(await playBehaviour(behaviourCase), isEmpty);
      });
    }

    test('asks for a text the step has to change', () {
      // A step whose expectation the tree already satisfies tests nothing: it would pass on a
      // renderer that answers no press and reconciles no store at all.
      for (final BehaviourCase behaviourCase in behaviourCases) {
        final BehaviourRun run = BehaviourRun(behaviourCase);
        run.draw(behaviourCase.tree);

        for (final BehaviourStep step in behaviourCase.steps) {
          final Map<Object, String?> before = <Object, String?>{
            for (final Object key in step.expected.keys) key: run.textAt(key),
          };

          if (step.key case final Object key) {
            run.press(key);
          } else if (step.node case final core.UINode node) {
            run.draw(node);
          }

          expect(
            step.expected.entries.any(
              (MapEntry<Object, String> entry) =>
                  before[entry.key] != entry.value,
            ),
            isTrue,
            reason:
                '${behaviourCase.description}: ${step.description} expects the '
                'text the tree already showed',
          );
        }

        run.dispose();
      }
    });

    test('reports the step whose text the page does not show', () async {
      final BehaviourCase wrong = BehaviourCase(
        description: 'a page that does not add up',
        tree: _Counter(),
        steps: <BehaviourStep>[
          BehaviourStep.press('raise', <Object, String>{'count': '7'}),
        ],
      );

      expect(await playBehaviour(wrong), hasLength(1));
    });

    test('refuses a tree it has no store to play', () async {
      final BehaviourCase noStore = BehaviourCase(
        description: 'a case over a plain node',
        tree: const core.TextNode('nothing to mount'),
        steps: const <BehaviourStep>[],
      );

      expect(
        () => BehaviourRun(noStore).draw(noStore.tree),
        throwsArgumentError,
      );
    });
  });
}
