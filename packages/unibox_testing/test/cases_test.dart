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
