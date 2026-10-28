import 'package:jaspr/dom.dart';
import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart' as css;
import 'package:unibox_jaspr/src/stylesheet.dart';
import 'package:unibox_jaspr/src/values.dart';

/// Holds the two CSS mappings to one text while both exist.
///
/// `unibox_css` is taking over the token-to-CSS work, family by family, and this
/// package keeps its Jaspr-typed mapping until it is removed. A family that has been
/// ported is proved here: the declarations Jaspr writes for a value and the text
/// `unibox_css` produces for the same value have to be identical, because a class
/// name is a hash of that text and two spellings of one look would name it twice.
///
/// The file disappears with the package.
void main() {
  group('a colour is spelled the same way', () {
    test('when it is opaque', () {
      const core.BoxColor color = core.BoxColor(0xFF112233);

      expect(
        declarationsOf(Styles(backgroundColor: toCssColor(color))),
        'background-color:${css.cssColor(color)}',
      );
    });

    test('when it carries an alpha', () {
      const core.BoxColor color = core.BoxColor.rgba(17, 34, 51, 128);

      expect(
        declarationsOf(Styles(backgroundColor: toCssColor(color))),
        'background-color:${css.cssColor(color)}',
      );
    });

    test('when it names a role', () {
      const core.BoxColor color = core.BoxColor.role(_Role.primary);

      expect(cssRoleReference(color), css.cssRoleReference(color));
    });
  });

  group('a dimension is spelled the same way', () {
    for (final double? value in <double?>[null, 0, 8, 8.5, double.infinity]) {
      test('as $value', () {
        final String expected = css.cssLength(value) ?? '';

        expect(
          declarationsOf(Styles(width: toCssUnit(value))),
          expected.isEmpty ? '' : 'width:$expected',
        );
      });
    }
  });

  group('a spacing is spelled the same way', () {
    const List<core.BoxSpacing> spacings = <core.BoxSpacing>[
      core.BoxSpacing.zero,
      core.BoxSpacing.all(8),
      core.BoxSpacing(top: 8, right: 12, bottom: 16, left: 4),
      core.BoxSpacing.symmetric(horizontal: 24, vertical: 12),
    ];

    for (final core.BoxSpacing spacing in spacings) {
      test('as $spacing', () {
        expect(
          declarationsOf(Styles(padding: toCssSpacing(spacing))),
          'padding:${css.cssSpacing(spacing)}',
        );
      });
    }
  });
}

/// A role a design system would name; any enum does.
enum _Role { primary }
