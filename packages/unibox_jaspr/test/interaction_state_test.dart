import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

void main() {
  group('transition parts', () {
    testComponents('gives each look the timing of the part that names it', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          backgroundColor: core.BoxColor.white,
          transition: core.BoxTransition(
            duration: Duration(milliseconds: 200),
            parts: <core.BoxTransitionPart>[
              core.BoxTransitionPart(
                properties: core.BoxProperty.paint,
                duration: Duration(milliseconds: 100),
              ),
              core.BoxTransitionPart(
                properties: <core.BoxProperty>{core.BoxProperty.transform},
                duration: Duration(milliseconds: 150),
                delay: Duration(milliseconds: 100),
                curve: core.BoxCurve.easeOut,
              ),
            ],
          ),
        ),
      );

      expect(
        stylesOf(find.tag('div'))['transition'],
        'background-color 100ms ease, border-color 100ms ease, '
        'border-radius 100ms ease, box-shadow 100ms ease, '
        // The paint settles first, then the scale starts and eases out.
        'opacity 200ms ease, transform 150ms ease-out 100ms',
      );
    });
  });

  group('transform and opacity', () {
    testComponents('fades a box without moving it', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          width: 60,
          height: 40,
          opacity: 0.4,
          backgroundColor: core.BoxColor.black,
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div'));

      expect(styles['opacity'], '0.4');
      expect(styles['width'], '60px');
      // No transform-origin: CSS centres one by default, like the Flutter side.
      expect(styles.containsKey('transform-origin'), isFalse);
    });

    testComponents('writes a transform in the order the model states', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          transform: core.BoxTransform(
            scale: 2,
            rotation: 15,
            offsetX: 10,
            offsetY: -4,
          ),
        ),
      );

      expect(
        stylesOf(find.tag('div'))['transform'],
        'translate(10px, -4px) rotate(15deg) scale(2)',
      );
    });

    testComponents('leaves an identity transform out', (tester) async {
      pumpNode(tester, const core.Box(transform: core.BoxTransform(scale: 1)));

      expect(stylesOf(find.tag('div')).containsKey('transform'), isFalse);
    });
  });

  group('transitions', () {
    testComponents('writes the paint properties into a transition', (
      tester,
    ) async {
      // A box without state styles renders its look inline, which is where a
      // transition on the resting style lands.
      pumpNode(
        tester,
        const core.Box(
          backgroundColor: core.BoxColor.white,
          transition: core.BoxTransition(
            duration: Duration(milliseconds: 150),
            curve: core.BoxCurve.easeInOut,
          ),
        ),
      );

      expect(
        stylesOf(find.tag('div'))['transition'],
        'background-color 150ms ease-in-out, border-color 150ms ease-in-out, '
        'border-radius 150ms ease-in-out, box-shadow 150ms ease-in-out, '
        'opacity 150ms ease-in-out, transform 150ms ease-in-out',
      );
    });

    testComponents('keeps the transition out of the state rule', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          backgroundColor: core.BoxColor.white,
          transition: core.BoxTransition(duration: Duration(milliseconds: 150)),
          hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor.black),
        ),
      );

      // A box with a state renders its resting look as a class rule, and the
      // duration belongs to the change rather than to the state that causes it.
      final String css = allCss();
      final int hoverStart = css.indexOf(':hover {');

      expect(hoverStart, greaterThan(-1));
      expect(css, contains('transition: background-color 150ms ease'));
      expect(
        css.substring(hoverStart, css.indexOf('}', hoverStart)),
        isNot(contains('transition')),
      );
    });
  });

  group('state styles', () {
    testComponents('scopes every state into its own rule', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          stateStyles: <core.BoxState, core.BoxStyle>{
            core.BoxState.hover: core.BoxStyle(
              backgroundColor: core.BoxColor.black,
            ),
            core.BoxState.focus: core.BoxStyle(borderRadius: 4),
            core.BoxState.pressed: core.BoxStyle(borderRadius: 8),
            core.BoxState.disabled: core.BoxStyle(
              backgroundColor: core.BoxColor.transparent,
            ),
          },
        ),
      );

      // The look is in a class rule, so the element itself carries no inline
      // style a host could not override.
      expect(elementOf(find.tag('div')).styles, isNull);
      final String className = classesOf(find.tag('div'))!;
      final String css = allCss();

      expect(css, contains('@media all and (hover: hover)'));
      expect(css, contains('.$className:hover'));
      expect(css, contains('.$className:focus-visible'));
      expect(css, contains('.$className:active'));
      expect(css, contains('.$className[aria-disabled="true"]'));
      expect(css, contains('background-color: #000000;'));
      expect(css, contains('border-radius: 4px;'));
      expect(css, contains('border-radius: 8px;'));
    });

    testComponents('writes a class even when no state is styled', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          backgroundColor: core.BoxColor.white,
          stateStyles: <core.BoxState, core.BoxStyle>{},
        ),
      );

      final String className = classesOf(find.tag('div'))!;

      expect(className, matches(RegExp(r'^unibox-box-[0-9a-f]{8}$')));
      expect(elementOf(find.tag('div')).styles, isNull);
      expect(declarationsOf('.$className')['background-color'], '#ffffff');
      // Only the resting rule: no state to scope.
      expect(allCss(), isNot(contains('.$className:hover')));
    });

    testComponents('gives boxes with different states different classes', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          children: <core.UINode>[
            core.Box(
              stateStyles: <core.BoxState, core.BoxStyle>{
                core.BoxState.focus: core.BoxStyle(borderRadius: 4),
              },
            ),
            core.Box(
              stateStyles: <core.BoxState, core.BoxStyle>{
                core.BoxState.focus: core.BoxStyle(borderRadius: 8),
              },
            ),
          ],
        ),
      );

      expect(
        classesOf(find.tag('div').at(1)),
        isNot(classesOf(find.tag('div').at(2))),
      );
    });
  });

  group('semantics', () {
    testComponents('maps the role, the label and the keyboard entry point', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          onTap: _noop,
          semantics: core.BoxSemantics(
            role: core.BoxRole.button,
            label: 'Create account',
          ),
        ),
      );

      expect(attributesOf(find.tag('div')), <String, String>{
        'role': 'button',
        'aria-label': 'Create account',
        'tabindex': '0',
        'data-unibox-node': 'box',
      });
      expect(stylesOf(find.tag('div'))['cursor'], 'pointer');
    });

    testComponents('reports the checked state of a checkbox', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(
            role: core.BoxRole.checkbox,
            checked: true,
          ),
        ),
      );

      expect(attributesOf(find.tag('div'))['aria-checked'], 'true');
    });

    testComponents('renders no semantics for a plain container', (
      tester,
    ) async {
      pumpNode(tester, const core.Box());

      // The node's own name is the only attribute: the name says what an element
      // is, and a container is nothing for a screen reader.
      expect(attributesOf(find.tag('div')), <String, String>{
        'data-unibox-node': 'box',
      });
    });

    testComponents('keeps a box without a role out of the tab order', (
      tester,
    ) async {
      pumpNode(tester, core.Box(onTap: _noop));

      expect(attributesOf(find.tag('div')).containsKey('tabindex'), isFalse);
      expect(elementOf(find.tag('div')).events?.keys, <String>['click']);
    });

    testComponents('marks a disabled box and serves it no listener', (
      tester,
    ) async {
      var taps = 0;
      pumpNode(
        tester,
        core.Box(
          enabled: false,
          onTap: () => taps++,
          semantics: const core.BoxSemantics(
            role: core.BoxRole.button,
            label: 'Create account',
          ),
        ),
      );

      final Map<String, String> attributes = attributesOf(find.tag('div'));
      expect(attributes['aria-disabled'], 'true');
      expect(attributes.containsKey('tabindex'), isFalse);
      expect(elementOf(find.tag('div')).events, isNull);
      expect(stylesOf(find.tag('div')).containsKey('cursor'), isFalse);
      expect(taps, 0);
    });
  });

  group('keyboard activation', () {
    // Activation is a DOM event and `package:web` cannot read event fields on the
    // VM, so what the test can check is the listener registration; the Flutter
    // suite covers the behaviour itself.
    testComponents('registers an enter and space entry point', (tester) async {
      pumpNode(
        tester,
        core.Box(
          onTap: _noop,
          semantics: const core.BoxSemantics(role: core.BoxRole.button),
        ),
      );

      expect(elementOf(find.tag('div')).events?.keys, <String>[
        'click',
        'keydown',
        'keyup',
      ]);
    });

    testComponents('registers no keyboard listener without a role', (
      tester,
    ) async {
      pumpNode(tester, core.Box(onTap: _noop));

      expect(
        elementOf(find.tag('div')).events?.keys,
        isNot(contains('keydown')),
      );
    });

    testComponents('serves a disabled box no keyboard listener at all', (
      tester,
    ) async {
      pumpNode(
        tester,
        core.Box(
          enabled: false,
          onTap: _noop,
          semantics: const core.BoxSemantics(role: core.BoxRole.button),
        ),
      );

      expect(elementOf(find.tag('div')).events, isNull);
    });
  });
}

void _noop() {}
