import 'package:test/test.dart';
import 'package:unibox_testing/unibox_testing.dart';
import 'package:unibox_core/unibox_core.dart' as core;

void main() {
  group('textCases', () {
    test('start from a text node without tokens', () {
      final TextCase plain = textCases.first;

      expect(plain.expected, const TextAppearance());
      expect(plain.node.computedStyle.isEmpty, isTrue);
    });

    test('let every case except the first change the plain text', () {
      // A case whose expected typography is the same as the plain one would pin
      // nothing: a renderer that ignored its token would still pass.
      for (final TextCase textCase in textCases.skip(1)) {
        expect(
          textCase.expected,
          isNot(textCases.first.expected),
          reason: '"${textCase.description}" expects plain text.',
        );
      }
    });

    test('expect a different typesetting for every case', () {
      final Set<TextAppearance> distinct = textCases
          .map((TextCase textCase) => textCase.expected)
          .toSet();

      expect(distinct, hasLength(textCases.length));
    });

    test('give every case a text to render', () {
      // The suites also check that the characters survive the trip through the
      // renderer, which only means something for a text that has some.
      for (final TextCase textCase in textCases) {
        expect(
          textCase.node.text,
          isNotEmpty,
          reason: '"${textCase.description}" renders an empty text.',
        );
      }
    });

    test('turn every token of the text into an expectation', () {
      final TextCase everyToken = textCases.firstWhere(
        (TextCase textCase) => textCase.description.contains('every token'),
      );

      expect(
        everyToken.expected.differencesFrom(const TextAppearance()),
        <String, TokenDifference>{
          'fontSize': (actual: 20.0, expected: null),
          'fontWeight': (actual: core.FontWeight.bold, expected: null),
          'color': (actual: const core.BoxColor(0x80112233), expected: null),
          'lineHeight': (actual: 1.6, expected: null),
          'fontFamily': (actual: 'Inter', expected: null),
          'letterSpacing': (actual: 0.6, expected: null),
          'decoration': (actual: core.TextDecoration.underline, expected: null),
          'decorationColor': (
            actual: const core.BoxColor(0xFF1A1C22),
            expected: null,
          ),
          'textAlign': (actual: core.TextAlign.right, expected: null),
          'maxLines': (actual: 3, expected: null),
          'overflow': (actual: core.TextOverflow.ellipsis, expected: null),
        },
      );
    });

    test('take the tokens from a style and let the flat tokens win', () {
      // The case exists because the precedence is resolved in the model, not in
      // the renderers: both have to receive the same merged typography.
      final TextCase precedence = textCases.firstWhere(
        (TextCase textCase) => textCase.description.contains('flat tokens win'),
      );

      expect(precedence.node.style!.fontSize, 18);
      expect(precedence.expected.fontSize, 22);
      expect(precedence.expected.fontWeight, core.FontWeight.medium);
    });
  });

  group('defaultTextAppearance', () {
    test('describes the typography the model declares as its default', () {
      // The constant is written out by hand so that it reads as a statement about
      // what a page looks like; this test is what keeps it true.
      final core.BoxTextStyle defaults = core.BoxTextStyle.defaults;

      expect(defaultTextAppearance.fontSize, defaults.fontSize);
      expect(defaultTextAppearance.fontWeight, defaults.fontWeight);
      expect(defaultTextAppearance.color, defaults.color);
      expect(defaultTextAppearance.lineHeight, defaults.lineHeight);
      expect(defaultTextAppearance.letterSpacing, defaults.letterSpacing);

      // The model leaves the family unnamed: it means the platform's UI font,
      // which is the one thing no description can pin down.
      expect(defaultTextAppearance.fontFamily, defaults.fontFamily);
      expect(defaultTextAppearance.fontFamily, isNull);

      // Nothing defaults the layout of the text itself.
      expect(defaultTextAppearance.textAlign, isNull);
      expect(defaultTextAppearance.maxLines, isNull);
      expect(defaultTextAppearance.overflow, isNull);
    });

    test('is not what a text node declares', () {
      // The table compares the tokens a node states; the default is what neither
      // the node nor an enclosing box states. They are different questions, so a
      // case that expects plain text still expects no tokens at all.
      expect(
        defaultTextAppearance.differencesFrom(const TextAppearance()),
        isNotEmpty,
      );
    });
  });

  group('TextAppearance', () {
    test('names the tokens that differ', () {
      const TextAppearance actual = TextAppearance(
        fontSize: 16,
        lineHeight: 1.4,
        textAlign: core.TextAlign.left,
      );
      const TextAppearance expected = TextAppearance(
        fontSize: 16,
        lineHeight: 1.6,
        textAlign: core.TextAlign.left,
      );

      // A difference has to fail the assertion, and it has to say which token
      // drifted instead of printing two objects side by side.
      expect(actual.differencesFrom(expected), <String, TokenDifference>{
        'lineHeight': (actual: 1.4, expected: 1.6),
      });
    });

    test('compares an absent token as absent, not as the host default', () {
      // Flutter would paint a text without a font size at 14 and a browser at
      // 16; both are the host's answer, so neither side may report one.
      const TextAppearance declared = TextAppearance(fontSize: 16);

      expect(
        declared.differencesFrom(const TextAppearance()),
        <String, TokenDifference>{'fontSize': (actual: 16.0, expected: null)},
      );
    });

    test('copies with the tokens it is given', () {
      final TextAppearance copy = defaultTextAppearance.copyWith(
        fontSize: 20,
        color: core.BoxColor.white,
        maxLines: 2,
      );

      expect(copy.fontSize, 20);
      expect(copy.color, core.BoxColor.white);
      expect(copy.maxLines, 2);
      expect(copy.lineHeight, defaultTextAppearance.lineHeight);
      expect(copy.letterSpacing, defaultTextAppearance.letterSpacing);
    });

    test('compares equal descriptions as equal', () {
      const TextAppearance one = TextAppearance(
        fontSize: 20,
        fontWeight: core.FontWeight.bold,
        color: core.BoxColor.black,
        lineHeight: 1.6,
        fontFamily: 'Inter',
        letterSpacing: 0.6,
        textAlign: core.TextAlign.right,
        maxLines: 3,
        overflow: core.TextOverflow.ellipsis,
      );
      const TextAppearance other = TextAppearance(
        fontSize: 20,
        fontWeight: core.FontWeight.bold,
        color: core.BoxColor.black,
        lineHeight: 1.6,
        fontFamily: 'Inter',
        letterSpacing: 0.6,
        textAlign: core.TextAlign.right,
        maxLines: 3,
        overflow: core.TextOverflow.ellipsis,
      );

      expect(one, other);
      expect(one.hashCode, other.hashCode);
      expect(one.differencesFrom(other), isEmpty);
    });
  });
}
