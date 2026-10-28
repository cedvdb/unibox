import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

void main() {
  group('headings', () {
    testComponents('renders the level as its element', (tester) async {
      for (final int level in <int>[1, 2, 3, 4, 5, 6]) {
        pumpNode(tester, core.TextNode('Title', headingLevel: level));

        expect(find.tag('h$level'), findsOneComponent);
        expect(find.tag('span'), findsNothing);
      }
    });

    testComponents('cancels the heading look the browser brings', (
      tester,
    ) async {
      pumpNode(tester, const core.TextNode('Title', headingLevel: 1));

      final Map<String, String> styles = stylesOf(find.tag('h1'));

      // The user agent gives a heading a margin, a size and a bold weight; none
      // of those are in the model, so the tree keeps deciding how it looks.
      expect(styles['margin'], '0');
      expect(styles['font-size'], 'inherit');
      expect(styles['font-weight'], 'inherit');
    });

    testComponents('keeps the tokens the node declares', (tester) async {
      pumpNode(
        tester,
        const core.TextNode(
          'Title',
          headingLevel: 2,
          fontSize: 24,
          fontWeight: core.FontWeight.bold,
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('h2'));

      // A declared token is not replaced by the reset: the reset only fills in
      // what the node left open.
      expect(styles['font-size'], '24px');
      expect(styles['font-weight'], '700');
      expect(styles['margin'], '0');
    });
  });

  group('elements', () {
    testComponents('renders a landmark as its own element', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(element: core.BoxElement.main),
          children: <core.UINode>[core.TextNode('Page')],
        ),
      );

      expect(find.tag('main'), findsOneComponent);
      expect(find.tag('div'), findsNothing);
      // `<main>` is a landmark by itself, so no role repeats the tag.
      expect(attributesOf(find.tag('main')).containsKey('role'), isFalse);
    });

    testComponents('renders a list and its items', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(element: core.BoxElement.ul),
          children: <core.UINode>[
            core.Box(
              semantics: core.BoxSemantics(element: core.BoxElement.li),
              children: <core.UINode>[core.TextNode('One')],
            ),
          ],
        ),
      );

      expect(find.tag('ul'), findsOneComponent);
      expect(find.tag('li'), findsOneComponent);
    });

    testComponents('cancels the indent and the margin of a list', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(element: core.BoxElement.ol),
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('ol'));

      // A browser indents a list and spaces it out; a Flutter `Column` does not.
      expect(styles['padding'], '0');
      expect(styles['margin'], '0');
    });

    testComponents('keeps a padding the list declares', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          padding: core.BoxSpacing.all(8),
          semantics: core.BoxSemantics(element: core.BoxElement.ul),
        ),
      );

      expect(stylesOf(find.tag('ul'))['padding'], '8px');
    });

    testComponents('cancels the margin of a figure', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(element: core.BoxElement.figure),
        ),
      );

      expect(stylesOf(find.tag('figure'))['margin'], '0');
    });

    testComponents('still writes a role the element does not imply', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(
            element: core.BoxElement.div,
            role: core.BoxRole.link,
          ),
        ),
      );

      expect(attributesOf(find.tag('div'))['role'], 'link');
    });

    testComponents('writes a role that overrides the one of its element', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(
            element: core.BoxElement.section,
            role: core.BoxRole.heading,
          ),
        ),
      );

      // A `<section>` implies `region`, so a heading role has to be written out.
      expect(attributesOf(find.tag('section'))['role'], 'heading');
    });
  });

  group('form fields', () {
    testComponents('says a field is required, wrong and why', (tester) async {
      pumpNode(
        tester,
        const core.TextInputNode(
          required: true,
          invalid: true,
          description: 'Use the address we can reach you at.',
        ),
      );

      final Map<String, String> attributes = attributesOf(find.tag('input'));

      // `aria-description` carries the text itself, so no element has to be
      // referenced by an id and the Flutter side can hand the same string to
      // `Semantics.hint`.
      expect(attributes['aria-required'], 'true');
      expect(attributes['aria-invalid'], 'true');
      expect(
        attributes['aria-description'],
        'Use the address we can reach you at.',
      );
    });

    testComponents('says nothing about a plain field', (tester) async {
      pumpNode(tester, const core.TextInputNode());

      final Map<String, String> attributes = attributesOf(find.tag('input'));

      expect(attributes.containsKey('aria-required'), isFalse);
      expect(attributes.containsKey('aria-invalid'), isFalse);
      expect(attributes.containsKey('aria-description'), isFalse);
    });
  });

  group('current item', () {
    testComponents('says which kind of current the item is', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(
            role: core.BoxRole.link,
            current: core.BoxCurrent.page,
          ),
          children: <core.UINode>[core.TextNode('Sign up')],
        ),
      );

      expect(attributesOf(find.tag('div'))['aria-current'], 'page');
    });

    testComponents('says nothing current about a plain box', (tester) async {
      pumpNode(tester, const core.Box());

      expect(
        attributesOf(find.tag('div')).containsKey('aria-current'),
        isFalse,
      );
    });
  });

  group('figures', () {
    testComponents('renders a caption as its own element', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(element: core.BoxElement.figure),
          children: <core.UINode>[
            core.Box(
              semantics: core.BoxSemantics(element: core.BoxElement.figcaption),
              children: <core.UINode>[core.TextNode('The old town')],
            ),
          ],
        ),
      );

      expect(find.tag('figure'), findsOneComponent);
      expect(find.tag('figcaption'), findsOneComponent);
      // No role repeats what the tag already says.
      expect(attributesOf(find.tag('figcaption')).containsKey('role'), isFalse);
    });
  });

  group('accessibility state', () {
    testComponents('writes the state both platforms expose', (tester) async {
      pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(
            expanded: true,
            selected: false,
            liveRegion: true,
          ),
          children: <core.UINode>[core.TextNode('Saved')],
        ),
      );

      final Map<String, String> attributes = attributesOf(find.tag('div'));

      expect(attributes['aria-expanded'], 'true');
      expect(attributes['aria-selected'], 'false');
      expect(attributes['aria-live'], 'polite');
    });

    testComponents('tells a toggle button apart from a selected item', (
      tester,
    ) async {
      pumpNode(
        tester,
        core.Box(
          onTap: () {},
          semantics: const core.BoxSemantics(
            role: core.BoxRole.button,
            pressed: true,
          ),
          children: <core.UINode>[core.TextNode('Two rooms')],
        ),
      );

      final Map<String, String> attributes = attributesOf(find.tag('div'));

      // A filter chip is a toggle button: a browser honours `aria-pressed` on a
      // `button` and ignores `aria-selected` there, so the state a chosen chip used
      // to write was announced by nothing.
      expect(attributes['role'], 'button');
      expect(attributes['aria-pressed'], 'true');
      expect(attributes.containsKey('aria-selected'), isFalse);
    });

    testComponents('writes a toggle button that is off as not pressed', (
      tester,
    ) async {
      pumpNode(
        tester,
        core.Box(
          onTap: () {},
          semantics: const core.BoxSemantics(
            role: core.BoxRole.button,
            pressed: false,
          ),
          children: <core.UINode>[core.TextNode('Studio')],
        ),
      );

      expect(attributesOf(find.tag('div'))['aria-pressed'], 'false');
    });

    testComponents('hides a box without taking it out of the layout', (
      tester,
    ) async {
      pumpNode(
        tester,
        core.Box(
          onTap: () {},
          semantics: const core.BoxSemantics(
            role: core.BoxRole.button,
            label: 'Decorative',
            hidden: true,
          ),
          children: <core.UINode>[const core.TextNode('Decorative')],
        ),
      );

      final Map<String, String> attributes = attributesOf(find.tag('div'));

      expect(attributes['aria-hidden'], 'true');
      // Hidden from a reader, so it cannot be focusable: an `aria-hidden`
      // element with a tabindex is a contradiction a browser reports.
      expect(attributes.containsKey('tabindex'), isFalse);
      expect(find.text('Decorative'), findsOneComponent);
    });
  });
}
