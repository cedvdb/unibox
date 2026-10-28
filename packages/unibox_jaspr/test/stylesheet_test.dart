import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_jaspr/src/stylesheet.dart';
import 'package:unibox_jaspr/unibox_jaspr.dart';

import 'support/harness.dart';

/// How many times [rule] appears in the rendered CSS.
int _ruleCount(String rule) =>
    RegExp(RegExp.escape(rule)).allMatches(allCss()).length;

void main() {
  group('the stylesheet of a rendering', () {
    testComponents('gives two boxes with one look a single class and rule', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          children: <core.UINode>[
            core.Box(backgroundColor: core.BoxColor.white),
            core.Box(backgroundColor: core.BoxColor.white),
          ],
        ),
      );

      final List<String> classes = <String>[
        for (final TestRenderElement element in elementsOf(find.tag('div')))
          if (element.classes != null) element.classes!,
      ];

      // The two children were declared apart and render alike, so they wear the
      // same class and the page states that look once.
      expect(classes[1], classes[2]);
      expect(_ruleCount('.${classes[1]} {'), 1);
    });

    testComponents('gives two different looks two classes', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          children: <core.UINode>[
            core.Box(backgroundColor: core.BoxColor.white),
            core.Box(backgroundColor: core.BoxColor.black),
          ],
        ),
      );

      final List<TestRenderElement> elements = elementsOf(find.tag('div'));

      expect(elements[1].classes, isNot(elements[2].classes));
    });

    testComponents('gives two texts with one style a single class', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          children: <core.UINode>[
            core.TextNode('One', fontSize: 13),
            core.TextNode('Two', fontSize: 13),
          ],
        ),
      );

      final List<TestRenderElement> spans = elementsOf(find.tag('span'));

      expect(spans[0].classes, isNotNull);
      expect(spans[0].classes, spans[1].classes);
      expect(_ruleCount('.${spans[0].classes} {'), 1);
    });

    testComponents('leaves no look inline on any element', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          backgroundColor: core.BoxColor.white,
          padding: core.BoxSpacing.all(16),
          children: <core.UINode>[
            core.TextNode('Unibox', fontWeight: core.FontWeight.bold),
            core.ImageNode('assets/logo.png', width: 32, height: 32),
            core.TextInputNode(placeholder: 'Email'),
            core.StackNode(children: <core.UINode>[core.TextNode('badge')]),
          ],
        ),
      );

      for (final String tag in <String>['div', 'span', 'img', 'input']) {
        for (final TestRenderElement element in elementsOf(find.tag(tag))) {
          expect(
            element.styles,
            isNull,
            reason: 'a <$tag> still carries an inline style',
          );
        }
      }

      // Everything the tree paints is in the one stylesheet instead.
      expect(allCss(), contains('background-color: #ffffff;'));
    });

    testComponents('writes six identical state-styled boxes once', (
      tester,
    ) async {
      const core.Box card = core.Box(
        backgroundColor: core.BoxColor.white,
        hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor.black),
        stateStyles: <core.BoxState, core.BoxStyle>{
          core.BoxState.focus: core.BoxStyle(borderRadius: 4),
          core.BoxState.pressed: core.BoxStyle(borderRadius: 8),
        },
      );

      pumpNode(
        tester,
        const core.Box(
          children: <core.UINode>[card, card, card, card, card, card],
        ),
      );

      // One stylesheet for the tree, and the typography of the model beside it.
      expect(elementsOf(find.tag('style')), hasLength(2));

      final String cardClass = elementsOf(find.tag('div'))[1].classes!;
      expect(<String>[
        for (final TestRenderElement e in elementsOf(find.tag('div')))
          if (e.classes == cardClass) cardClass,
      ], hasLength(6));

      // The resting rule and each state are written once for the six cards.
      expect(_ruleCount('.$cardClass {'), 1);
      expect(_ruleCount('.$cardClass:hover'), 1);
      expect(_ruleCount('.$cardClass:focus-visible'), 1);
      expect(_ruleCount('.$cardClass:active'), 1);
    });

    testComponents(
      'repeats a rule per instance only when a node is rendered alone',
      (tester) async {
        const core.Box card = core.Box(
          hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor.black),
        );

        // No sheet in scope: this is what a host that renders components itself
        // gets, and what the renderer did for every box before the sheet existed.
        tester.pumpComponent(
          Component.fragment(<Component>[
            for (int i = 0; i < 6; i++) JasprBox(box: card),
          ]),
        );

        expect(elementsOf(find.tag('style')), hasLength(6));
      },
    );

    test('sends a look registered after the sheet was written to the sink', () {
      final UniboxStylesheet sheet = UniboxStylesheet();
      final List<String> written = <String>[];

      StyleRule ruleOf(String className, String colour) => StyleRule(
        selector: Selector.className(className),
        styles: Styles(raw: <String, String>{'background-color': colour}),
      );

      // Before a sink is attached the sheet is text for the response, as it is on
      // a server.
      sheet.classFor(
        'box',
        'background-color:red',
        (String name) => <StyleRule>[ruleOf(name, 'red')],
      );

      expect(written, isEmpty);

      sheet.attachSink(written.add);

      sheet.classFor(
        'box',
        'background-color:blue',
        (String name) => <StyleRule>[ruleOf(name, 'blue')],
      );
      // A look it already knows is not written twice.
      sheet.classFor(
        'box',
        'background-color:blue',
        (String name) => <StyleRule>[ruleOf(name, 'blue')],
      );

      expect(written, hasLength(1));
      expect(
        written.single,
        allOf(contains('background-color'), contains('blue')),
      );
    });

    testComponents('names a class after the node it draws', (tester) async {
      pumpNode(tester, const core.TextNode('Unibox'));

      expect(
        classesOf(find.tag('span')),
        matches(RegExp(r'^unibox-text-[0-9a-f]{8}$')),
      );
    });
  });
}
