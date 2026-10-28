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
  group('a keyword is spelled the same way', () {
    test('for every axis', () {
      for (final core.Axis axis in core.Axis.values) {
        expect(
          declarationsOf(Styles(flexDirection: toCssFlexDirection(axis))),
          'flex-direction:${css.cssFlexDirection(axis)}',
        );
      }
    });

    test('for every main alignment', () {
      for (final core.MainAlign align in core.MainAlign.values) {
        expect(
          declarationsOf(Styles(justifyContent: toCssJustifyContent(align))),
          'justify-content:${css.cssJustifyContent(align)}',
        );
      }
    });

    test('for every cross alignment', () {
      for (final core.CrossAlign align in core.CrossAlign.values) {
        expect(
          declarationsOf(Styles(alignItems: toCssAlignItems(align))),
          'align-items:${css.cssAlignItems(align)}',
        );
      }
    });

    test('for every overflow', () {
      for (final core.Overflow overflow in core.Overflow.values) {
        expect(
          declarationsOf(Styles(overflow: toCssOverflow(overflow))),
          'overflow:${css.cssOverflow(overflow)}',
        );
      }
    });

    test('for every weight and every text alignment', () {
      for (final core.FontWeight weight in core.FontWeight.values) {
        expect(
          declarationsOf(Styles(fontWeight: toCssFontWeight(weight))),
          'font-weight:${css.cssFontWeight(weight)}',
        );
      }

      for (final core.TextAlign align in core.TextAlign.values) {
        expect(
          declarationsOf(Styles(textAlign: toCssTextAlign(align))),
          'text-align:${css.cssTextAlign(align)}',
        );
      }
    });
  });

  group('typography is spelled the same way', () {
    const List<core.BoxTextStyle> styles = <core.BoxTextStyle>[
      core.BoxTextStyle(fontSize: 20),
      core.BoxTextStyle(fontWeight: core.FontWeight.semiBold),
      core.BoxTextStyle(color: core.BoxColor(0xFF112233)),
      core.BoxTextStyle(color: core.BoxColor.role(_Role.primary)),
      core.BoxTextStyle(lineHeight: 1.4, letterSpacing: 0.5),
      core.BoxTextStyle(fontFamily: 'Inter'),
      core.BoxTextStyle(fontFamily: 'Unibox Text', fontSize: 12),
      core.BoxTextStyle(
        fontSize: 20,
        fontWeight: core.FontWeight.bold,
        color: core.BoxColor(0xFF112233),
        lineHeight: 1.2,
        letterSpacing: 2,
        fontFamily: 'Inter',
      ),
    ];

    for (final core.BoxTextStyle style in styles) {
      test('as $style', () {
        expect(
          declarationsOf(toTypographyStyles(style)!),
          css.typographyDeclarations(style)!.text,
        );
      });
    }

    test('when it is the defaults of the model', () {
      // The `:root` rule both renderers start a document from.
      expect(
        declarationsOf(defaultTypographyStyles()),
        css.defaultTypographyDeclarations().text,
      );
    });
  });

  group('a transform and a transition are spelled the same way', () {
    test('as a transform on a box', () {
      const core.BoxTransform transform = core.BoxTransform(
        scale: 1.2,
        rotation: 45,
        offsetX: 8,
        offsetY: 4,
      );
      final String text = declarationsOf(
        toBoxStyles(const core.BoxStyle(transform: transform)),
      );

      expect(text, contains('transform:${css.cssTransform(transform)}'));
    });

    test('as a transition on a box', () {
      const core.BoxTransition transition = core.BoxTransition(
        duration: Duration(milliseconds: 150),
        curve: core.BoxCurve.easeOut,
      );
      final String text = declarationsOf(
        toBoxStyles(const core.BoxStyle(transition: transition)),
      );

      expect(text, contains('transition:${css.cssTransition(transition)}'));
    });
  });

  group('a border and a shadow are spelled the same way', () {
    test('as a border', () {
      const core.BoxBorder border = core.BoxBorder(
        width: 2,
        color: core.BoxColor(0xFF112233),
      );

      expect(
        declarationsOf(Styles(border: toCssBorder(border))),
        'border:${css.cssBorder(border)}',
      );
    });

    test('as a shadow', () {
      const core.BoxShadow shadow = core.BoxShadow(
        color: core.BoxColor(0xFF112233),
        offsetX: 1,
        offsetY: 2,
        blurRadius: 4,
        spreadRadius: 6,
      );

      expect(
        declarationsOf(Styles(shadow: toCssBoxShadow(shadow))),
        'box-shadow:${css.cssBoxShadow(shadow)}',
      );
    });
  });
}

/// A role a design system would name; any enum does.
enum _Role { primary }
