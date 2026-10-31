import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';

void main() {
  group('a text input', () {
    test('adopts the typography and the colour of the box around it', () {
      // A field is a replaced element: without this it brings a browser's font,
      // colour, border and padding, which Flutter's `TextField` does not have.
      final CssDeclarations declarations = textInputDeclarations();

      expect(declarations['font'], 'inherit');
      expect(declarations['color'], 'inherit');
      expect(declarations['width'], '100%');
      expect(declarations['box-sizing'], 'border-box');
    });

    test('draws no frame of its own', () {
      // The box around the field draws the border and the padding on both targets.
      final CssDeclarations declarations = textInputDeclarations();

      expect(declarations['border'], 'none');
      expect(declarations['outline'], 'none');
      expect(declarations['background-color'], 'transparent');
      expect(declarations['resize'], 'none');
    });

    test('states the padding it is given', () {
      expect(
        textInputDeclarations(
          padding: const core.BoxSpacing.all(12),
        )['padding'],
        '12px',
      );
      expect(textInputDeclarations()['padding'], '0');
    });
  });

  group('the states of a box', () {
    test('are matched by a pseudo class, or by the attribute it carries', () {
      expect(cssStateSelector(core.BoxState.hover), ':hover');
      expect(cssStateSelector(core.BoxState.focus), ':focus-visible');
      expect(cssStateSelector(core.BoxState.pressed), ':active');
      // The visual and the announced state cannot disagree.
      expect(
        cssStateSelector(core.BoxState.disabled),
        '[aria-disabled="true"]',
      );
    });

    test('are written only when a box declares them', () {
      expect(stateRules(const core.Box(), 'a'), isEmpty);
    });

    test('declare only what the state states, in cascade order', () {
      final core.Box box = core.Box(
        hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor.white),
        stateStyles: <core.BoxState, core.BoxStyle>{
          core.BoxState.focus: core.BoxStyle(opacity: 0.8),
          core.BoxState.pressed: core.BoxStyle(opacity: 0.6),
        },
      );
      final List<CssRule> rules = stateRules(box, 'a');

      expect(rules.map((CssRule rule) => rule.selector), <String>[
        '.a:hover',
        '.a:focus-visible',
        '.a:active',
      ]);
      // Only the look the state states is declared: the layout of the resting rule
      // is absent, so hovering cannot turn a row into a column.
      expect(rules.first.declarations['background-color'], '#ffffff');
      expect(rules.first.declarations.has('display'), isFalse);
      expect(rules.first.declarations.has('flex-direction'), isFalse);
      expect(rules.first.declarations.has('justify-content'), isFalse);
      // And a hover only applies where a pointer can hover, so a phone cannot get
      // stuck in a hovered look after a tap.
      expect(rules.first.media, hoverCapableMediaQuery);
      expect(rules[1].media, isNull);
    });
  });

  group('a box that scrolls', () {
    test('keeps its children at the size the tree states', () {
      // A flex item shrinks to fit by default, which is the opposite of what a viewport means:
      // a hero, a bar and five rows inside a short box were squashed to fit it, so the box had
      // nothing to scroll and a pinned band never moved. Flutter lays the children out at their
      // stated heights, so this declaration is what makes the two agree.
      final List<CssRule> rules = scrollRules(
        'unibox-box-1f3c9a7b',
        const core.BoxStyle(overflow: core.Overflow.scroll),
      );

      expect(rules, hasLength(1));
      expect(rules.single.selector, '.unibox-box-1f3c9a7b > *');
      expect(rules.single.declarations.text, 'flex-shrink:0');
    });

    test('says nothing for a box that does not scroll', () {
      expect(scrollRules('x', const core.BoxStyle()), isEmpty);
      expect(
        scrollRules('x', const core.BoxStyle(overflow: core.Overflow.hidden)),
        isEmpty,
      );
    });

    test(
      'states the shrink once for a pager, on the box and not on the stops',
      () {
        const style = core.BoxStyle(
          overflow: core.Overflow.scroll,
          snap: core.ScrollSnap.page,
        );

        expect(
          snapRules('unibox-box-1f3c9a7b', style).single.declarations.text,
          'scroll-snap-align:start',
        );
        expect(scrollRules('unibox-box-1f3c9a7b', style), hasLength(1));
      },
    );
  });

  group('a theme', () {
    test('is written as custom properties a host can outrank', () {
      const core.UniboxTheme theme = core.UniboxTheme(
        colors: <Enum, core.BoxColor>{_Role.primary: core.BoxColor(0xFF112233)},
      );

      expect(themeDeclarations(theme).text, '--unibox-color-primary:#112233');
    });
  });
}

/// A role a design system names; any enum does.
enum _Role { primary }
