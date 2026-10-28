import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';

/// A role of a design system, which names the custom property a colour is written
/// as. Any enum does: the model does not own the vocabulary of an application.
enum _Role { primary }

void main() {
  group('a length', () {
    test('is written in pixels, without a needless decimal', () {
      expect(cssPixels(8), '8px');
      expect(cssPixels(8.5), '8.5px');
      expect(cssPixels(0), '0px');
    });

    test('expands an infinite dimension to the space available', () {
      // A box that fills its parent is how the model states "as big as I am given".
      expect(cssLength(double.infinity), '100%');
      expect(cssLength(-double.infinity), '100%');
    });

    test('is left out when the model declares nothing', () {
      expect(cssLength(null), isNull);
    });
  });

  group('a spacing', () {
    test('collapses to one value when every edge is the same', () {
      expect(cssSpacing(const core.BoxSpacing.all(8)), '8px');
    });

    test('is written top, right, bottom, left when the edges differ', () {
      // CSS's order, which is also the order a reader of the output expects.
      expect(
        cssSpacing(
          const core.BoxSpacing(top: 8, right: 12, bottom: 16, left: 4),
        ),
        '8px 12px 16px 4px',
      );
    });

    test('states a zero rather than dropping the declaration', () {
      // A reset that cancels what a user agent applies has to be written down.
      expect(cssSpacing(core.BoxSpacing.zero), '0px');
    });
  });

  group('a colour', () {
    test('is written as six hexadecimal digits when it is opaque', () {
      expect(cssColor(const core.BoxColor(0xFF112233)), '#112233');
    });

    test('is written as rgba when it carries an alpha', () {
      expect(
        cssColor(const core.BoxColor.rgba(17, 34, 51, 128)),
        'rgba(17, 34, 51, 0.502)',
      );
    });

    test('is a custom property when it names a role', () {
      final core.BoxColor? role = core.BoxColor.role(_Role.primary);

      expect(cssRoleReference(role!), startsWith('var(--unibox-color-'));
      expect(cssColorOrRole(role), cssRoleReference(role));
    });

    test('falls back to its channels when it names no role', () {
      expect(cssRoleReference(const core.BoxColor(0xFF112233)), isNull);
      expect(cssColorOrRole(const core.BoxColor(0xFF112233)), '#112233');
    });
  });

  group('an image fit', () {
    test('is the keyword CSS uses for the same crop', () {
      expect(cssObjectFit(core.ImageFit.cover), 'cover');
      expect(cssObjectFit(core.ImageFit.contain), 'contain');
      expect(cssObjectFit(core.ImageFit.fill), 'fill');
      expect(cssObjectFit(core.ImageFit.scaleDown), 'scale-down');
    });
  });

  group('a layout keyword', () {
    test('names the axis as CSS does', () {
      expect(cssFlexDirection(core.Axis.horizontal), 'row');
      expect(cssFlexDirection(core.Axis.vertical), 'column');
    });

    test('distributes as CSS does', () {
      expect(cssJustifyContent(core.MainAlign.start), 'start');
      expect(cssJustifyContent(core.MainAlign.center), 'center');
      expect(cssJustifyContent(core.MainAlign.end), 'end');
      expect(cssJustifyContent(core.MainAlign.spaceBetween), 'space-between');
      expect(cssJustifyContent(core.MainAlign.spaceAround), 'space-around');
      expect(cssJustifyContent(core.MainAlign.spaceEvenly), 'space-evenly');
    });

    test('aligns as CSS does', () {
      expect(cssAlignItems(core.CrossAlign.start), 'start');
      expect(cssAlignItems(core.CrossAlign.center), 'center');
      expect(cssAlignItems(core.CrossAlign.end), 'end');
      expect(cssAlignItems(core.CrossAlign.stretch), 'stretch');
    });

    test('scrolls only when the content overflows', () {
      // `auto` rather than `scroll`: a scrollbar appears when there is something to
      // scroll, which is what a Flutter `SingleChildScrollView` does.
      expect(cssOverflow(core.Overflow.visible), 'visible');
      expect(cssOverflow(core.Overflow.hidden), 'hidden');
      expect(cssOverflow(core.Overflow.scroll), 'auto');
    });

    test('aligns text as CSS does', () {
      expect(cssTextAlign(core.TextAlign.left), 'left');
      expect(cssTextAlign(core.TextAlign.center), 'center');
      expect(cssTextAlign(core.TextAlign.right), 'right');
      expect(cssTextAlign(core.TextAlign.justify), 'justify');
    });

    test('states a weight as a number rather than a name', () {
      // `bold` resolves differently in different fonts; 700 does not.
      expect(cssFontWeight(core.FontWeight.normal), '400');
      expect(cssFontWeight(core.FontWeight.medium), '500');
      expect(cssFontWeight(core.FontWeight.semiBold), '600');
      expect(cssFontWeight(core.FontWeight.bold), '700');
    });
  });

  group('typography', () {
    test('is written for the tokens a style states, and no others', () {
      // Only what is set: everything else inherits from the surrounding box, which
      // is what a Flutter `Text` does inside a `DefaultTextStyle`.
      final CssDeclarations? declarations = typographyDeclarations(
        const core.BoxTextStyle(fontSize: 20),
      );

      expect(declarations!.text, 'font-size:20px');
    });

    test('writes a line height unitless, so descendants scale with it', () {
      final CssDeclarations? declarations = typographyDeclarations(
        const core.BoxTextStyle(lineHeight: 1.4, letterSpacing: 0.5),
      );

      expect(declarations!.text, 'letter-spacing:0.5px;line-height:1.4');
    });

    test('quotes a family as one family, not as a fallback list', () {
      expect(cssFontFamily('Inter'), "'Inter'");
      expect(cssFontFamily('Unibox Text'), "'Unibox Text'");
      expect(cssFontFamily("O'Neill"), '"O\'Neill"');
    });

    test('writes a role colour as a custom property', () {
      final CssDeclarations? declarations = typographyDeclarations(
        const core.BoxTextStyle(color: core.BoxColor.role(_Role.primary)),
      );

      expect(declarations!.text, 'color:var(--unibox-color-primary)');
    });

    test('is left out entirely when the style states nothing', () {
      expect(typographyDeclarations(const core.BoxTextStyle()), isNull);
    });

    test('starts from the model defaults, with the platform font family', () {
      // The model names no family — a font file is the application's — so the
      // document asks CSS for the generic `system-ui`, unquoted.
      expect(
        defaultTypographyDeclarations().text,
        'color:#000000;font-family:system-ui;font-size:16px;'
        'font-weight:400;letter-spacing:0px;line-height:1.5',
      );
    });
  });

  group('a border, a shadow and a corner', () {
    test('are written in the order CSS reads them', () {
      expect(
        cssBorder(
          const core.BoxBorder(width: 2, color: core.BoxColor(0xFF112233)),
        ),
        'solid #112233 2px',
      );
      expect(
        cssBoxShadow(
          const core.BoxShadow(
            color: core.BoxColor(0xFF112233),
            offsetX: 1,
            offsetY: 2,
            blurRadius: 4,
            spreadRadius: 6,
          ),
        ),
        '1px 2px 4px 6px #112233',
      );
      expect(
        cssCorners(
          const core.BoxBorderRadius(
            topLeft: 8,
            topRight: 8,
            bottomRight: 0,
            bottomLeft: 0,
          ),
        ),
        '8px 8px 0px 0px',
      );
    });
  });
}
