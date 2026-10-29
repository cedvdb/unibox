import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_element/unibox_element.dart';

/// What a tree becomes, before anyone writes it.
///
/// The renderers' own suites check the markup they produce; these check the plan they both read,
/// which is why they are about elements rather than about HTML.
void main() {
  ElementPlan planOf(core.UINode node) => planNode(node, Stylesheet());

  group('a node becomes an element', () {
    test('a box is a flex container with one class for its look', () {
      final ElementPlan plan = planOf(const core.Box());

      expect(plan.tag, 'div');
      expect(plan.className, startsWith('unibox-box-'));
      expect(plan.attributes['data-unibox-node'], 'box');
    });

    test('a text is a span, or a heading at the level it states', () {
      expect(planOf(const core.TextNode('Hi')).tag, 'span');
      expect(planOf(const core.TextNode('Hi', headingLevel: 2)).tag, 'h2');
    });

    test('a box is the element its semantics name, with a role only when it adds one', () {
      final ElementPlan main = planOf(
        const core.Box(
          semantics: core.BoxSemantics(element: core.BoxElement.main),
        ),
      );
      final ElementPlan link = planOf(
        const core.Box(
          semantics: core.BoxSemantics(
            element: core.BoxElement.nav,
            role: core.BoxRole.link,
          ),
        ),
      );

      expect(main.tag, 'main');
      expect(main.attributes, isNot(contains('role')));
      // A `<nav>` is a navigation landmark already; `role="link"` is the box saying more.
      expect(link.tag, 'nav');
      expect(link.attributes['role'], 'link');
    });

    test('a keyed node carries its key, and an unkeyed one does not', () {
      expect(
        planOf(const core.Box(key: 'page')).attributes['data-unibox-key'],
        'page',
      );
      expect(
        planOf(const core.Box()).attributes,
        isNot(contains('data-unibox-key')),
      );
    });

    test('a stack puts each child in a cell no node drew', () {
      final ElementPlan plan = planOf(
        const core.StackNode(children: <core.UINode>[core.TextNode('Over')]),
      );
      final ElementPlan cell = plan.children.single;

      expect(cell.className, startsWith('unibox-stack-child-'));
      // A wrapper the renderer invented: no node drew it, so it is not part of the description.
      expect(cell.attributes, isNot(contains('data-unibox-node')));
    });

    test('a look is one class however many elements wear it', () {
      final Stylesheet sheet = Stylesheet();
      final ElementPlan one = planNode(
        const core.Box(backgroundColor: core.BoxColor.white),
        sheet,
      );
      final ElementPlan other = planNode(
        const core.Box(backgroundColor: core.BoxColor.white),
        sheet,
      );

      expect(one.className, other.className);
    });
  });

  group('an embed', () {
    test('is planned by the renderer that can draw it', () {
      // Its payload is the host's, so the plan package cannot decide.
      expect(
        () => planOf(const _BareEmbed()),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

final class _BareEmbed extends core.EmbedNode {
  const _BareEmbed();

  @override
  List<Object> get implementations => <Object>[Object()];
}
