import 'package:test/test.dart';
import 'package:unibox_testing/unibox_testing.dart';
import 'package:unibox_core/unibox_core.dart' as core;

void main() {
  group('boxCases', () {
    test('start from a box without tokens', () {
      final BoxCase plain = boxCases.first;

      expect(plain.expected, const BoxAppearance());
      expect(plain.box.computedStyle.resolvedDirection, core.Axis.vertical);
    });

    test('let every case except the first change the plain box', () {
      // A case whose expected presentation is the same as the plain one would
      // pin nothing: a renderer that ignored its token would still pass.
      for (final BoxCase boxCase in boxCases.skip(1)) {
        expect(
          boxCase.expected,
          isNot(boxCases.first.expected),
          reason: '"${boxCase.description}" expects the plain box.',
        );
      }
    });

    test('expect a different presentation for every case', () {
      final Set<BoxAppearance> distinct = boxCases
          .map((BoxCase boxCase) => boxCase.expected)
          .toSet();

      expect(distinct, hasLength(boxCases.length));
    });

    test('turn every token of the box into an expectation', () {
      final BoxCase everyToken = boxCases.firstWhere(
        (BoxCase boxCase) => boxCase.description.contains('every token'),
      );

      expect(
        everyToken.expected.differencesFrom(const BoxAppearance()),
        <String, TokenDifference>{
          'direction': (
            actual: core.Axis.horizontal,
            expected: core.Axis.vertical,
          ),
          'mainAlign': (
            actual: core.MainAlign.spaceBetween,
            expected: core.MainAlign.start,
          ),
          'crossAlign': (
            actual: core.CrossAlign.center,
            expected: core.CrossAlign.start,
          ),
          'gap': (actual: 8, expected: 0),
          'padding': (
            actual: core.BoxSpacing.symmetric(horizontal: 18, vertical: 12),
            expected: core.BoxSpacing.zero,
          ),
          'margin': (
            actual: core.BoxSpacing.all(6),
            expected: core.BoxSpacing.zero,
          ),
          'height': (actual: 96, expected: null),
          'backgroundColor': (actual: core.BoxColor.white, expected: null),
          'borderRadius': (actual: 10, expected: 0),
          'borderWidth': (actual: 1, expected: 0),
          'borderColor': (
            actual: core.BoxColor.rgb(0xE5, 0xE7, 0xEB),
            expected: null,
          ),
          'transitionDuration': (
            actual: const Duration(milliseconds: 120),
            expected: null,
          ),
          'widthFraction': (actual: 0.75, expected: null),
          'transitionCurve': (actual: core.BoxCurve.easeIn, expected: null),
          'opacity': (actual: 0.75, expected: null),
          'transform': (
            actual: const core.BoxTransform(
              scaleX: 1.25,
              scaleY: 1,
              fractionY: 0.25,
            ),
            expected: null,
          ),
        },
      );
    });
  });

  group('gridCases', () {
    test('pin a different placement for every case', () {
      final Set<GridAppearance> distinct = gridCases
          .map((GridCase gridCase) => gridCase.expected)
          .toSet();

      expect(distinct, hasLength(gridCases.length));
    });

    test('key every child, so a renderer can be asked which became which', () {
      // The Flutter suite measures a child by its key and the web suite reads the
      // class of the element that carries it, so an unkeyed child cannot be read
      // back out of either output.
      for (final GridCase gridCase in gridCases) {
        expect(gridCase.node.children, isNotEmpty);

        for (final core.UINode child in gridCase.node.children) {
          expect(
            child.key,
            isNotNull,
            reason: '"${gridCase.description}" leaves a child unkeyed.',
          );
        }
      }
    });

    test('expect one span per child, and never more than the columns', () {
      for (final GridCase gridCase in gridCases) {
        expect(
          gridCase.expected.spans,
          hasLength(gridCase.node.children.length),
          reason:
              '"${gridCase.description}" describes another number of children.',
        );

        for (final int span in gridCase.expected.spans) {
          expect(span, inInclusiveRange(1, gridCase.columns));
        }
      }
    });
  });

  group('GridAppearance', () {
    test('names the child that took another number of tracks', () {
      const GridAppearance actual = GridAppearance(spans: <int>[1, 1, 1]);
      const GridAppearance expected = GridAppearance(spans: <int>[1, 2, 1]);

      expect(actual.differencesFrom(expected), <String, TokenDifference>{
        'span 1': (actual: 1, expected: 2),
      });
    });

    test('reports a placement of another length as one difference', () {
      const GridAppearance actual = GridAppearance(spans: <int>[1, 1]);
      const GridAppearance expected = GridAppearance(spans: <int>[1, 1, 1]);
      final Map<String, TokenDifference> differences = actual.differencesFrom(
        expected,
      );

      // The two lists describe placement of another length, so there is no child
      // to point at: the difference is the whole placement.
      expect(differences.keys, <String>['spans']);
      expect(differences['spans']?.actual, same(actual.spans));
      expect(differences['spans']?.expected, same(expected.spans));
    });

    test('compares equal placements as equal', () {
      const GridAppearance one = GridAppearance(spans: <int>[1, 2, 1]);
      const GridAppearance other = GridAppearance(spans: <int>[1, 2, 1]);

      expect(one, other);
      expect(one.hashCode, other.hashCode);
      expect(one, isNot(const GridAppearance(spans: <int>[2, 1, 1])));
    });
  });

  group('BoxAppearance', () {
    test(
      'treats an absent token and a zero token as the same presentation',
      () {
        const BoxAppearance absent = BoxAppearance();
        const BoxAppearance zeros = BoxAppearance(
          gap: 0,
          padding: core.BoxSpacing.zero,
          margin: core.BoxSpacing.zero,
          borderRadius: 0,
          borderWidth: 0,
        );

        expect(zeros, absent);
        expect(zeros.differencesFrom(absent), isEmpty);
        expect(zeros.hashCode, absent.hashCode);
      },
    );

    test('ignores the colour of a border that draws no line', () {
      const BoxAppearance colourless = BoxAppearance(borderWidth: 0);
      const BoxAppearance painted = BoxAppearance(
        borderWidth: 0,
        borderColor: core.BoxColor.black,
      );

      expect(painted, colourless);
      expect(painted.hashCode, colourless.hashCode);
    });

    test('ignores a border that is only a colour', () {
      // A border with no width is not painted on either target, so a colour
      // left over next to it describes nothing.
      const BoxAppearance painted = BoxAppearance(
        borderColor: core.BoxColor.black,
      );

      expect(painted, const BoxAppearance());
      expect(painted.differencesFrom(const BoxAppearance()), isEmpty);
    });

    test('distinguishes a border with a width', () {
      const BoxAppearance bordered = BoxAppearance(
        borderWidth: 1,
        borderColor: core.BoxColor.black,
      );

      expect(bordered, isNot(const BoxAppearance()));
      expect(
        bordered.differencesFrom(const BoxAppearance()),
        <String, TokenDifference>{
          'borderWidth': (actual: 1.0, expected: 0),
          'borderColor': (actual: core.BoxColor.black, expected: null),
        },
      );
    });

    test('names the tokens that differ', () {
      const BoxAppearance actual = BoxAppearance(gap: 4, width: 10);
      const BoxAppearance expected = BoxAppearance(gap: 8, width: 10);

      // A difference has to fail the assertion, and it has to say which token
      // drifted instead of printing two objects side by side.
      expect(actual.differencesFrom(expected), <String, TokenDifference>{
        'gap': (actual: 4.0, expected: 8.0),
      });
    });
  });
}
