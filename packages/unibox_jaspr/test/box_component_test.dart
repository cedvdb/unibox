import 'dart:async';

import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_jaspr/src/box.dart';
import 'package:unibox_jaspr/unibox_jaspr.dart';

import 'support/harness.dart';

void main() {
  group('Box layout', () {
    testComponents('renders an empty box as a single div', (tester) async {
      pumpNode(tester, const core.Box());

      expect(find.tag('div'), findsOneComponent);
      expect(stylesOf(find.tag('div')), <String, String>{
        'box-sizing': 'border-box',
        'display': 'flex',
        'flex-direction': 'column',
        'justify-content': 'start',
        'align-items': 'start',
        // Nothing to press, so nothing takes the press: see the rule below.
        'pointer-events': 'none',
      });
    });

    testComponents('lets a press through a painted leaf, and takes it when it '
        'listens', (tester) async {
      // The browser aims a press at the topmost element; Flutter hit-tests a picture
      // and finds nothing to press. A decoration drawn over a control — the ink a
      // well spreads, a panel a stack paints behind a pin — must therefore not be the
      // target, or the control beneath it is dead on the web alone.
      pumpNode(
        tester,
        core.Box(
          children: <core.UINode>[
            const core.Box(backgroundColor: core.BoxColor(0xFF000000)),
            core.Box(
              backgroundColor: const core.BoxColor(0xFF000000),
              onTap: () {},
              children: const <core.UINode>[core.Box()],
            ),
          ],
        ),
      );

      final Finder divs = find.tag('div');
      final Map<String, String> leaf = stylesOf(divs.at(1));
      final Map<String, String> listening = stylesOf(divs.at(2));

      expect(leaf['pointer-events'], 'none');
      expect(listening['pointer-events'], 'auto');
    });

    testComponents('omits styles for unset tokens', (tester) async {
      pumpNode(tester, const core.Box(children: [core.Box()]));

      final Map<String, String> styles = stylesOf(find.tag('div').first);

      expect(styles.containsKey('gap'), isFalse);
      expect(styles.containsKey('width'), isFalse);
      expect(styles.containsKey('padding'), isFalse);
      expect(styles.containsKey('background-color'), isFalse);
    });

    testComponents('lays children out in a column without a direction', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          gap: 6,
          crossAlign: core.CrossAlign.center,
          children: [core.Box(height: 20), core.Box(height: 30)],
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div').first);

      expect(styles['display'], 'flex');
      expect(styles['flex-direction'], 'column');
      expect(styles['align-items'], 'center');
      expect(styles['gap'], '6px');
    });

    testComponents('maps a horizontal direction to a flex row', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          children: [core.Box(width: 20, height: 20), core.Box(width: 30)],
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div').first);

      expect(find.tag('div'), findsNComponents(3));
      expect(styles['display'], 'flex');
      expect(styles['flex-direction'], 'row');
      expect(styles['justify-content'], 'start');
      expect(styles['align-items'], 'start');
      expect(styles.containsKey('gap'), isFalse);
    });

    testComponents('maps a vertical direction to a flex column', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.vertical,
          mainAlign: core.MainAlign.spaceBetween,
          crossAlign: core.CrossAlign.center,
          gap: 12,
          children: [core.Box(height: 20), core.Box(height: 30)],
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div').first);

      expect(styles['flex-direction'], 'column');
      expect(styles['justify-content'], 'space-between');
      expect(styles['align-items'], 'center');
      expect(styles['gap'], '12px');
    });

    testComponents('maps main axis alignment', (tester) async {
      const Map<core.MainAlign, String> mainAligns = {
        core.MainAlign.center: 'center',
        core.MainAlign.end: 'end',
        core.MainAlign.spaceAround: 'space-around',
        core.MainAlign.spaceEvenly: 'space-evenly',
      };

      for (final MapEntry<core.MainAlign, String> entry in mainAligns.entries) {
        pumpNode(
          tester,
          core.Box(direction: core.Axis.horizontal, mainAlign: entry.key),
        );

        expect(stylesOf(find.tag('div').first)['justify-content'], entry.value);
      }
    });

    testComponents('stretches children across the cross axis', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          crossAlign: core.CrossAlign.stretch,
        ),
      );

      expect(stylesOf(find.tag('div'))['align-items'], 'stretch');
    });

    testComponents('renders child nodes as nested divs', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.vertical,
          children: [core.Box(height: 10), core.Box(height: 20)],
        ),
      );

      expect(find.tag('div'), findsNComponents(3));
      expect(stylesOf(find.tag('div').at(1))['height'], '10px');
      expect(stylesOf(find.tag('div').at(2))['height'], '20px');
    });
  });

  group('Box styling', () {
    testComponents('maps dimensions and expands infinite ones', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          width: 120,
          height: double.infinity,
          minWidth: 40,
          maxWidth: 60.5,
          minHeight: 10,
          maxHeight: 20,
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div'));

      expect(styles['width'], '120px');
      expect(styles['height'], '100%');
      expect(styles['min-width'], '40px');
      expect(styles['max-width'], '60.5px');
      expect(styles['min-height'], '10px');
      expect(styles['max-height'], '20px');
    });

    testComponents('maps padding and margin to four sided spacing', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          padding: core.BoxSpacing.only(left: 4, top: 8, right: 12, bottom: 16),
          margin: core.BoxSpacing.all(6),
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div'));

      expect(styles['padding'], '8px 12px 16px 4px');
      expect(styles['margin'], '6px');
    });

    testComponents('maps background, radius, border and shadow', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          backgroundColor: core.BoxColor.rgb(0x2D, 0x6C, 0xF3),
          borderRadius: 12,
          border: core.BoxBorder(width: 2, color: core.BoxColor.black),
          shadow: core.BoxShadow(
            offsetX: 0,
            offsetY: 4,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div'));

      expect(styles['background-color'], '#2d6cf3');
      expect(styles['border-radius'], '12px');
      expect(styles['border'], 'solid #000000 2px');
      expect(styles['box-shadow'], '0px 4px 8px 2px #000000');
    });

    testComponents('maps translucent colors to rgba', (tester) async {
      pumpNode(
        tester,
        const core.Box(backgroundColor: core.BoxColor.rgba(0, 0, 0, 128)),
      );

      expect(
        stylesOf(find.tag('div'))['background-color'],
        'rgba(0, 0, 0, 0.502)',
      );
    });

    testComponents('drops invisible borders', (tester) async {
      pumpNode(tester, const core.Box(border: core.BoxBorder.none()));

      expect(stylesOf(find.tag('div')).containsKey('border'), isFalse);
    });

    testComponents('maps overflow values', (tester) async {
      const Map<core.Overflow, String> overflows = {
        core.Overflow.visible: 'visible',
        core.Overflow.hidden: 'hidden',
        core.Overflow.scroll: 'auto',
      };

      for (final MapEntry<core.Overflow, String> entry in overflows.entries) {
        pumpNode(tester, core.Box(overflow: entry.key));

        expect(stylesOf(find.tag('div'))['overflow'], entry.value);
      }
    });

    testComponents('maps flex to a flex item', (tester) async {
      pumpNode(tester, const core.Box(flex: 2));

      final Map<String, String> styles = stylesOf(find.tag('div'));

      expect(styles['flex-grow'], '2');
      expect(styles['flex-shrink'], '1');
      expect(styles['flex-basis'], '0');
    });

    testComponents('flat parameters win over style tokens', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          width: 50,
          styles: <core.BoxStyle>[core.BoxStyle(width: 200, height: 30)],
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div'));

      expect(styles['width'], '50px');
      expect(styles['height'], '30px');
    });
  });

  group('Box interactions', () {
    testComponents('calls onTap when clicked and shows a pointer cursor', (
      tester,
    ) async {
      var taps = 0;
      pumpNode(
        tester,
        core.Box(onTap: () => taps++, children: const [core.Box()]),
      );

      expect(stylesOf(find.tag('div').first)['cursor'], 'pointer');

      await tester.click(find.tag('div').first);

      expect(taps, 1);
    });

    testComponents('keeps a static box free of listeners', (tester) async {
      pumpNode(tester, const core.Box());

      expect(elementOf(find.tag('div')).events, isNull);
      expect(stylesOf(find.tag('div')).containsKey('cursor'), isFalse);
    });

    testComponents('reports hover changes', (tester) async {
      final List<bool> hovers = <bool>[];
      pumpNode(tester, core.Box(onHover: hovers.add));

      tester.dispatchEvent(find.tag('div'), 'mouseenter');
      tester.dispatchEvent(find.tag('div'), 'mouseleave');

      expect(hovers, <bool>[true, false]);
    });

    testComponents('fires onLongPress after the press threshold', (
      tester,
    ) async {
      var longPresses = 0;
      pumpNode(tester, core.Box(onLongPress: () => longPresses++));

      tester.dispatchEvent(find.tag('div'), 'pointerdown');
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(longPresses, 1);

      tester.dispatchEvent(find.tag('div'), 'pointerup');
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(longPresses, 1);
    });

    testComponents('cancels the long press when the pointer is released', (
      tester,
    ) async {
      var longPresses = 0;
      pumpNode(tester, core.Box(onLongPress: () => longPresses++));

      tester.dispatchEvent(find.tag('div'), 'pointerdown');
      tester.dispatchEvent(find.tag('div'), 'pointerup');
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(longPresses, 0);
    });
  });

  group('Box hover styles', () {
    testComponents('scopes hover styles into a stylesheet', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          width: 80,
          backgroundColor: core.BoxColor.white,
          hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor.black),
        ),
      );

      expect(elementOf(find.tag('div')).styles, isNull);

      final String className = classesOf(find.tag('div'))!;
      expect(className, matches(RegExp(r'^unibox-box-[0-9a-f]{8}$')));

      final String css = allCss();
      expect(css, contains('.$className {'));
      expect(css, contains('.$className:hover {'));
      expect(css, contains('background-color: #ffffff;'));
      expect(css, contains('background-color: #000000;'));
      expect(css, contains('width: 80px;'));
    });

    testComponents('leaves the flex layout out of a state rule', (
      tester,
    ) async {
      // A state rule is layered over the resting rule, exactly like a state
      // style is merged over the resting style in Flutter. Restating the flex
      // layout there would reset it: hovering this row would turn it into a
      // column and move the label to the start.
      pumpNode(
        tester,
        const core.Box(
          direction: core.Axis.horizontal,
          mainAlign: core.MainAlign.center,
          onTap: _noop,
          hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor.black),
        ),
      );

      final String className = classesOf(find.tag('div'))!;
      final String css = allCss();
      final String hoverRule = _ruleOf(css, '.$className:hover');

      expect(hoverRule, contains('background-color: #000000;'));
      expect(hoverRule, isNot(contains('flex-direction')));
      expect(hoverRule, isNot(contains('justify-content')));
      expect(hoverRule, isNot(contains('align-items')));
      expect(hoverRule, isNot(contains('display')));
    });

    testComponents('derives the same class name for identical styles', (
      tester,
    ) async {
      const core.BoxStyle hoverStyle = core.BoxStyle(
        backgroundColor: core.BoxColor.black,
      );
      pumpNode(
        tester,
        const core.Box(
          children: [
            core.Box(hoverStyle: hoverStyle),
            core.Box(hoverStyle: hoverStyle),
          ],
        ),
      );

      expect(
        classesOf(find.tag('div').at(1)),
        classesOf(find.tag('div').at(2)),
      );
    });
  });

  group('renderJaspr', () {
    testComponents('toComponent renders the same tree', (tester) async {
      const core.Box node = core.Box(
        width: 30,
        height: 30,
        backgroundColor: core.BoxColor.black,
      );

      tester.pumpComponent(node.toComponent());

      expect(stylesOf(find.tag('div'))['width'], '30px');
    });

    test('throws for nodes without a Jaspr renderer', () {
      expect(() => renderJaspr(const _UnknownNode()), throwsUnsupportedError);
    });
  });
  group('Box press event', () {
    testComponents('listens for the press when the tree asks for it', (
      tester,
    ) async {
      pumpNode(tester, core.Box(onTapDown: (core.BoxTapEvent event) {}));

      final TestRenderElement element = elementsOf(find.tag('div')).first;

      expect(element.events?.keys, contains('pointerdown'));
    });

    test('measures a press from the box, not from what it hit', () {
      // The label of a button sits 40 across and 12 down from the box's corner, and
      // the pointer lands at 90, 30 in client coordinates: the press is 50, 18
      // inside the box. `offsetX` would have measured from the label instead, which
      // is where the ink used to start.
      expect(
        pressPointInside(clientX: 90, clientY: 30, originX: 40, originY: 12),
        const core.BoxPoint(50, 18),
      );
    });

    testComponents('adds no listener to a box that does not ask', (
      tester,
    ) async {
      pumpNode(tester, const core.Box());

      final TestRenderElement element = elementsOf(find.tag('div')).first;

      expect(element.events, isNull);
    });
  });
}

/// A node type no renderer knows about.
class _UnknownNode extends core.UINode {
  const _UnknownNode();
}

/// Does nothing, for a box that only needs to be interactive.
void _noop() {}

/// The body of the CSS rule [selector] in [css].
///
/// The hover rule of a box lives inside an `@media` block, so the assertions of
/// a state rule have to look at that rule alone instead of the whole stylesheet.
String _ruleOf(String css, String selector) {
  final int start = css.indexOf('$selector {');
  if (start == -1) {
    throw StateError('No rule for $selector in:\n$css');
  }

  final int end = css.indexOf('}', start);
  return css.substring(start, end);
}
