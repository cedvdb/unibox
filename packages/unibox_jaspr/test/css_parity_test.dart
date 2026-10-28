import 'package:jaspr/dom.dart';
import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart' as css;
import 'package:unibox_jaspr/src/stylesheet.dart';
import 'package:unibox_jaspr/src/values.dart';

/// Holds the two CSS mappings to one meaning while both exist.
///
/// `unibox_css` is taking over the token-to-CSS work, family by family, and this
/// package keeps its Jaspr-typed mapping until it is removed. A family that has been
/// ported is proved here: the declarations Jaspr writes and the text `unibox_css`
/// produces have to say the same thing.
///
/// The comparison goes through [inOurSpelling], because the two mappings are allowed to
/// disagree about how they write it. Nothing is released, so `unibox_css` picks the
/// spelling a stylesheet author would — `0` rather than `0px`, the width before the
/// style in a `border` — while Jaspr writes whichever constructor the old mapping
/// happened to reach for. Those are the only allowed differences, and they are all
/// listed in [_reorderings] and [_zeros].
///
/// The file disappears with the package.
void main() {
  group('a colour is spelled the same way', () {
    test('when it is opaque', () {
      const core.BoxColor color = core.BoxColor(0xFF112233);

      expect(
        inOurSpelling(
          declarationsOf(Styles(backgroundColor: toCssColor(color))),
        ),
        'background-color:${css.cssColor(color)}',
      );
    });

    test('when it carries an alpha', () {
      const core.BoxColor color = core.BoxColor.rgba(17, 34, 51, 128);

      expect(
        inOurSpelling(
          declarationsOf(Styles(backgroundColor: toCssColor(color))),
        ),
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
          inOurSpelling(declarationsOf(Styles(width: toCssUnit(value)))),
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
          inOurSpelling(declarationsOf(Styles(padding: toCssSpacing(spacing)))),
          'padding:${css.cssSpacing(spacing)}',
        );
      });
    }
  });
  group('a keyword is spelled the same way', () {
    test('for every axis', () {
      for (final core.Axis axis in core.Axis.values) {
        expect(
          inOurSpelling(
            declarationsOf(Styles(flexDirection: toCssFlexDirection(axis))),
          ),
          'flex-direction:${css.cssFlexDirection(axis)}',
        );
      }
    });

    test('for every main alignment', () {
      for (final core.MainAlign align in core.MainAlign.values) {
        expect(
          inOurSpelling(
            declarationsOf(Styles(justifyContent: toCssJustifyContent(align))),
          ),
          'justify-content:${css.cssJustifyContent(align)}',
        );
      }
    });

    test('for every cross alignment', () {
      for (final core.CrossAlign align in core.CrossAlign.values) {
        expect(
          inOurSpelling(
            declarationsOf(Styles(alignItems: toCssAlignItems(align))),
          ),
          'align-items:${css.cssAlignItems(align)}',
        );
      }
    });

    test('for every overflow', () {
      for (final core.Overflow overflow in core.Overflow.values) {
        expect(
          inOurSpelling(
            declarationsOf(Styles(overflow: toCssOverflow(overflow))),
          ),
          'overflow:${css.cssOverflow(overflow)}',
        );
      }
    });

    test('for every weight and every text alignment', () {
      for (final core.FontWeight weight in core.FontWeight.values) {
        expect(
          inOurSpelling(
            declarationsOf(Styles(fontWeight: toCssFontWeight(weight))),
          ),
          'font-weight:${css.cssFontWeight(weight)}',
        );
      }

      for (final core.TextAlign align in core.TextAlign.values) {
        expect(
          inOurSpelling(
            declarationsOf(Styles(textAlign: toCssTextAlign(align))),
          ),
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
          inOurSpelling(declarationsOf(toTypographyStyles(style)!)),
          css.typographyDeclarations(style)!.text,
        );
      });
    }

    test('when it is the defaults of the model', () {
      // The `:root` rule both renderers start a document from.
      expect(
        inOurSpelling(declarationsOf(defaultTypographyStyles())),
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
      final String text = inOurSpelling(
        declarationsOf(toBoxStyles(const core.BoxStyle(transform: transform))),
      );

      expect(text, contains('transform:${css.cssTransform(transform)}'));
    });

    test('as a transition on a box', () {
      const core.BoxTransition transition = core.BoxTransition(
        duration: Duration(milliseconds: 150),
        curve: core.BoxCurve.easeOut,
      );
      final String text = inOurSpelling(
        declarationsOf(
          toBoxStyles(const core.BoxStyle(transition: transition)),
        ),
      );

      expect(text, contains('transition:${css.cssTransition(transition)}'));
    });
  });

  group('a box is spelled the same way', () {
    const List<core.BoxStyle> styles = <core.BoxStyle>[
      core.BoxStyle(),
      core.BoxStyle(direction: core.Axis.horizontal, gap: 8),
      core.BoxStyle(backgroundColor: core.BoxColor(0xFF112233)),
      core.BoxStyle(backgroundColor: core.BoxColor.rgba(1, 2, 3, 128)),
      core.BoxStyle(border: core.BoxBorder(width: 2)),
      core.BoxStyle(borderRadius: 8, shadow: core.BoxShadow()),
      core.BoxStyle(corners: core.BoxBorderRadius(topLeft: 8, topRight: 8)),
      core.BoxStyle(
        padding: core.BoxSpacing.all(8),
        margin: core.BoxSpacing.only(top: 4),
      ),
      core.BoxStyle(width: 200, height: 100, flex: 1),
      core.BoxStyle(maxWidth: 400, minHeight: 20),
      core.BoxStyle(overflow: core.Overflow.scroll, opacity: 0.5),
      core.BoxStyle(
        transform: core.BoxTransform(scale: 2),
        transition: core.BoxTransition(duration: Duration(milliseconds: 200)),
      ),
      core.BoxStyle(
        mainAlign: core.MainAlign.spaceBetween,
        crossAlign: core.CrossAlign.center,
        textStyle: core.BoxTextStyle(
          fontSize: 20,
          color: core.BoxColor(0xFF00FF00),
        ),
      ),
    ];

    for (final core.BoxStyle style in styles) {
      for (final bool declaredOnly in <bool>[false, true]) {
        for (final core.BoxElement element in core.BoxElement.values) {
          test('as $style, declaredOnly: $declaredOnly, on $element', () {
            // Not "contains": the whole text, because a class name is a hash of it.
            expect(
              inOurSpelling(
                declarationsOf(
                  toBoxStyles(
                    style,
                    declaredOnly: declaredOnly,
                    element: element,
                  ),
                ),
              ),
              css
                  .boxDeclarations(
                    style,
                    declaredOnly: declaredOnly,
                    element: element,
                  )
                  .text,
            );
          });
        }
      }
    }
  });

  group('a node other than a box is spelled the same way', () {
    test('as a text', () {
      const List<core.TextNode> texts = <core.TextNode>[
        core.TextNode('Hi'),
        core.TextNode('Hi', fontSize: 20, fontWeight: core.FontWeight.bold),
        core.TextNode('Hi', textAlign: core.TextAlign.center),
        core.TextNode('Hi', maxLines: 2),
        core.TextNode('Hi', overflow: core.TextOverflow.ellipsis),
        core.TextNode('Hi', headingLevel: 1),
        core.TextNode('Hi', headingLevel: 2, fontSize: 32),
      ];

      for (final core.TextNode node in texts) {
        expect(
          inOurSpelling(declarationsOf(toTextStyles(node))),
          css.textDeclarations(node).text,
        );
      }
    });

    test('as an image', () {
      const List<core.ImageNode> images = <core.ImageNode>[
        core.ImageNode('a.png', alt: 'A'),
        core.ImageNode(
          'a.png',
          width: 200,
          height: 100,
          borderRadius: 8,
          fit: core.ImageFit.cover,
        ),
      ];

      for (final core.ImageNode node in images) {
        expect(
          inOurSpelling(declarationsOf(toImageStyles(node))),
          css.imageDeclarations(node).text,
        );
      }
    });

    test('as a stack and its cell', () {
      expect(
        inOurSpelling(declarationsOf(toStackStyles(const core.StackNode()))),
        css.stackDeclarations(const core.StackNode()).text,
      );
      expect(
        inOurSpelling(declarationsOf(toStackChildStyles())),
        css.stackCellDeclarations().text,
      );
    });
  });

  group('a text input and a state rule are spelled the same way', () {
    test('as a field', () {
      for (final core.BoxSpacing? padding in <core.BoxSpacing?>[
        null,
        core.BoxSpacing.all(12),
        core.BoxSpacing(top: 4, right: 8, bottom: 4, left: 8),
      ]) {
        expect(
          inOurSpelling(declarationsOf(toTextInputStyles(padding: padding))),
          css.textInputDeclarations(padding: padding).text,
        );
      }
    });

    test('as the states of a box', () {
      final core.Box box = core.Box(
        hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor.white),
        stateStyles: <core.BoxState, core.BoxStyle>{
          core.BoxState.focus: core.BoxStyle(opacity: 0.8),
          core.BoxState.pressed: core.BoxStyle(opacity: 0.6),
          core.BoxState.disabled: core.BoxStyle(opacity: 0.4),
        },
      );

      for (final core.BoxState state in core.BoxState.values) {
        final core.BoxStyle? style = box.stateStyle(state);

        expect(
          inOurSpelling(
            declarationsOf(toBoxStyles(style!, declaredOnly: true)),
          ),
          css
              .stateRules(box, 'a')
              .singleWhere(
                (css.CssRule rule) =>
                    rule.selector.endsWith(css.cssStateSelector(state)),
              )
              .declarations
              .text,
        );
      }
    });
  });

  group('a class name is the same in both mappings', () {
    test('for a look', () {
      const String declarations = 'display:flex;width:8px';

      expect(fnv1a(declarations), css.fnv1a(declarations));
    });
  });

  group('a border and a shadow are spelled the same way', () {
    test('as a border', () {
      const core.BoxBorder border = core.BoxBorder(
        width: 2,
        color: core.BoxColor(0xFF112233),
      );

      expect(
        inOurSpelling(declarationsOf(Styles(border: toCssBorder(border)))),
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
        inOurSpelling(declarationsOf(Styles(shadow: toCssBoxShadow(shadow)))),
        'box-shadow:${css.cssBoxShadow(shadow)}',
      );
    });
  });
}

/// A role a design system would name; any enum does.
enum _Role { primary }

/// The declarations of [jaspr] — Jaspr's output — written the way `unibox_css` writes
/// them, so the two can be compared for meaning rather than for bytes.
String inOurSpelling(String jaspr) =>
    jaspr.split(';').map(_declarationInOurSpelling).join(';');

String _declarationInOurSpelling(String declaration) {
  final int colon = declaration.indexOf(':');

  if (colon == -1) {
    return declaration;
  }

  final String property = declaration.substring(0, colon);
  String value = declaration.substring(colon + 1).replaceAll(_zeros, '0');

  // A uniform four-value spacing is written once here.
  final List<String> parts = value.split(' ');

  if (parts.length == 4 && parts.toSet().length == 1) {
    value = parts.first;
  }

  final List<String> reordered =
      _reorderings[property]?.call(value) ?? <String>[];

  if (reordered.isNotEmpty) {
    value = reordered.join(' ');
  }

  return '$property:$value';
}

/// Every `0px` that stands on its own, which this library writes `0`.
final RegExp _zeros = RegExp(r'\b0px\b');

/// The properties whose three tokens are stated in a different order.
final Map<String, List<String> Function(String)> _reorderings =
    <String, List<String> Function(String)>{
      // A border is written `width style colour`, the way a stylesheet is written by
      // hand; Jaspr states it `style colour width`.
      'border': (String value) => <String>[...value.split(' ')]
        ..sort(
          (String a, String b) => _borderOrder(a).compareTo(_borderOrder(b)),
        ),
    };

int _borderOrder(String token) {
  if (token.endsWith('px')) {
    return 0;
  }

  if (token.startsWith('#')) {
    return 2;
  }

  return 1;
}
