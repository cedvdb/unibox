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
      expect(cssPixels(0), '0');
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
      expect(cssSpacing(core.BoxSpacing.zero), '0');
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
      const core.BoxColor role = core.BoxColor.role(_Role.primary);

      expect(cssRoleReference(role), startsWith('var(--unibox-color-'));
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

    test('names the direction the words flow in', () {
      // The same two words the `dir` attribute takes, so the element and the page cannot
      // describe one page two ways.
      expect(cssWritingDirection(core.WritingDirection.ltr), 'ltr');
      expect(cssWritingDirection(core.WritingDirection.rtl), 'rtl');
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
      // The alphabetic baseline, which is the only one `align-items` can name.
      expect(cssAlignItems(core.CrossAlign.baseline), 'baseline');
    });

    test('scrolls only when the content overflows', () {
      // `auto` rather than `scroll`: a scrollbar appears when there is something to
      // scroll, which is what a Flutter `SingleChildScrollView` does.
      expect(cssOverflow(core.Overflow.visible), 'visible');
      expect(cssOverflow(core.Overflow.hidden), 'hidden');
      expect(cssOverflow(core.Overflow.scroll), 'auto');
    });

    test('names the edge a pin holds', () {
      // The two edges a pin holds are the vertical ones, so they are written as the
      // physical properties rather than as a logical pairing.
      expect(cssPinEdge(core.BoxPin.start), 'top');
      expect(cssPinEdge(core.BoxPin.end), 'bottom');
    });

    test('aligns text as CSS does', () {
      expect(cssTextAlign(core.TextAlign.left), 'left');
      expect(cssTextAlign(core.TextAlign.center), 'center');
      expect(cssTextAlign(core.TextAlign.right), 'right');
      expect(cssTextAlign(core.TextAlign.justify), 'justify');
    });

    test('states a weight as a number rather than a name', () {
      // `bold` resolves differently in different fonts; 700 does not.
      expect(cssFontWeight(core.FontWeight.light), '300');
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

    test('writes a decoration, and what paints it, in an order a browser reads', () {
      // The shorthand resets the colour and the thickness, so it has to be the
      // first of the three for the other two to win.
      final CssDeclarations? declarations = typographyDeclarations(
        const core.BoxTextStyle(
          decoration: core.TextDecoration.lineThrough,
          decorationColor: core.BoxColor(0xFF1A1C22),
          decorationThickness: 2,
        ),
      );

      expect(
        declarations!.text,
        'text-decoration:line-through;text-decoration-color:#1a1c22;'
        'text-decoration-thickness:2px',
      );
    });

    test('keeps a struck through line when the run has no other token', () {
      // A decoration is typography, so a node that declares only a line still
      // declares something: the class must not come out empty.
      final CssDeclarations? declarations = typographyDeclarations(
        const core.BoxTextStyle(decoration: core.TextDecoration.none),
      );

      expect(declarations!.text, 'text-decoration:none');
    });

    test('names each decoration the way CSS names it', () {
      expect(cssTextDecoration(core.TextDecoration.none), 'none');
      expect(
        cssTextDecoration(core.TextDecoration.lineThrough),
        'line-through',
      );
      expect(cssTextDecoration(core.TextDecoration.underline), 'underline');
    });

    test('writes a role decoration colour as a custom property', () {
      final CssDeclarations? declarations = typographyDeclarations(
        const core.BoxTextStyle(
          decoration: core.TextDecoration.underline,
          decorationColor: core.BoxColor.role(_Role.primary),
        ),
      );

      expect(
        declarations!.text,
        'text-decoration:underline;'
        'text-decoration-color:var(--unibox-color-primary)',
      );
    });

    test('starts from the model defaults, with the platform font family', () {
      // The model names no family — a font file is the application's — so the
      // document asks CSS for the generic `system-ui`, unquoted.
      expect(
        defaultTypographyDeclarations().text,
        'color:#000000;font-family:system-ui;font-size:16px;'
        'font-weight:400;letter-spacing:0;line-height:1.5',
      );
    });

    test('adds the one piece of browser chrome a page starts without', () {
      // The tap highlight is a flash the browser paints over what it thinks was pressed.
      // It sits on the root rather than on a control, because it inherits: a tree answers a
      // press with its own ink and state layers, so the platform's answer is switched off
      // once for every element.
      expect(
        rootDeclarations().text,
        '-webkit-tap-highlight-color:transparent;color:#000000;'
        'font-family:system-ui;font-size:16px;font-weight:400;'
        'letter-spacing:0;line-height:1.5',
      );
    });
  });

  group('a transform and a transition', () {
    test('list the transform functions in the order CSS interpolates', () {
      expect(
        cssTransform(
          const core.BoxTransform(
            scale: 1.2,
            rotation: 45,
            offsetX: 8,
            offsetY: 4,
          ),
        ),
        // Two factors, one per axis: a control can grow sideways at its full height.
        'translate(8px, 4px) rotate(45deg) scale(1.2, 1.2)',
      );
    });

    test('write nothing when the transform changes nothing', () {
      expect(cssTransform(null), isNull);
      expect(cssTransform(const core.BoxTransform()), isNull);
    });

    test('name only the paint, so two targets can agree on what moves', () {
      // A border width is left out: CSS animates it as layout, Flutter as paint.
      expect(transitionedProperties.values, <String>[
        'background-color',
        'border-color',
        'border-radius',
        'box-shadow',
        'opacity',
        'transform',
      ]);
    });

    test('carry a delay only when a part has one', () {
      const core.BoxTransition transition = core.BoxTransition(
        duration: Duration(milliseconds: 150),
        curve: core.BoxCurve.easeOut,
      );

      expect(cssTiming(transition, core.BoxProperty.opacity), '150ms ease-out');
      expect(
        cssTransition(transition),
        'background-color 150ms ease-out, border-color 150ms ease-out, '
        'border-radius 150ms ease-out, box-shadow 150ms ease-out, '
        'opacity 150ms ease-out, transform 150ms ease-out',
      );
    });

    test('name every curve CSS knows', () {
      expect(cssCurve(core.BoxCurve.linear), 'linear');
      expect(cssCurve(core.BoxCurve.ease), 'ease');
      expect(cssCurve(core.BoxCurve.easeIn), 'ease-in');
      expect(cssCurve(core.BoxCurve.easeOut), 'ease-out');
      expect(cssCurve(core.BoxCurve.easeInOut), 'ease-in-out');
    });
  });

  group('a border, a shadow and a corner', () {
    test('are written in the order CSS reads them', () {
      expect(
        cssBorder(
          const core.BoxBorder(width: 2, color: core.BoxColor(0xFF112233)),
        ),
        '2px solid #112233',
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
        '1px 2px 5.62px 6px #112233',
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
        '8px 8px 0 0',
      );
    });

    test('write a blur in the unit a browser reads', () {
      // The model keeps Flutter's unit: a radius of `r` is a gaussian of `0.57735 * r +
      // 0.5` there, where a browser reads a `blur-radius` of `b` as a gaussian of `b / 2`.
      // One number written through untouched paints two shadows, and the tighter one is
      // the one under a card's edge, where a shadow is read.
      expect(cssShadowBlur(4), '5.62px');
      expect(cssShadowBlur(2), '3.31px');

      final double sigmaInCss = 5.62 / 2;
      final double sigmaInFlutter = 0.57735 * 4 + 0.5;

      expect(sigmaInCss, closeTo(sigmaInFlutter, 0.01));
    });

    test('keep a shadow with no blur a hard edge', () {
      // A hairline is a shadow with no blur — a line, not a glow — and Flutter's formula
      // leaves only half a pixel of deviation there, which nothing can see, where a whole
      // CSS pixel of it would smear the line into a band.
      expect(cssShadowBlur(0), '0');
      expect(
        cssBoxShadow(const core.BoxShadow(offsetY: 1, blurRadius: 0)),
        '0 1px 0 0 #000000',
      );
    });

    test('stack several shadows as one comma separated list', () {
      // An elevation is three layers in Material and in Flutter, and CSS paints a list
      // in the order it is written: the first entry ends up on top, which is why the
      // model keeps the same order.
      expect(
        cssBoxShadows(const <core.BoxShadow>[
          core.BoxShadow(
            color: core.BoxColor(0x33000000),
            offsetY: 2,
            blurRadius: 1,
            spreadRadius: -1,
          ),
          core.BoxShadow(
            color: core.BoxColor(0x1F000000),
            offsetY: 1,
            blurRadius: 3,
          ),
        ]),
        '0 2px 2.15px -1px rgba(0, 0, 0, 0.2), '
        '0 1px 4.46px 0 rgba(0, 0, 0, 0.122)',
      );
    });

    test('keeps a role shadow pointed at its custom property', () {
      // A shadow may be a role like any other colour, and then it has to stay a
      // variable: a theme or a dark-mode block outranks the tree, and a literal would
      // pin one level's shade into the stylesheet.
      expect(
        cssBoxShadows(const <core.BoxShadow>[
          core.BoxShadow(
            color: core.BoxColor.role(_Role.primary),
            blurRadius: 3,
          ),
        ]),
        '0 2px 4.46px 0 var(--unibox-color-primary)',
      );
    });
  });
}
