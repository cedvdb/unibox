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

    test('a pager snaps to its children, and says so on the container', () {
      // `scroll-snap-align` belongs to the child, so the box that settles writes it for the
      // children it lays out — the one place a parent can describe its own children.
      final Stylesheet sheet = Stylesheet();
      final ElementPlan plan = planNode(
        const core.Box(
          direction: core.Axis.horizontal,
          overflow: core.Overflow.scroll,
          snap: core.ScrollSnap.page,
        ),
        sheet,
      );

      expect(
        sheet.css,
        contains('scroll-snap-type:x mandatory'),
        reason: 'the axis is the box direction, not a second parameter',
      );
      expect(
        sheet.css,
        contains('.${plan.className} > *{scroll-snap-align:start}'),
      );
    });

    test('a box that does not snap writes nothing about snapping', () {
      final Stylesheet sheet = Stylesheet();
      planNode(const core.Box(overflow: core.Overflow.scroll), sheet);

      expect(sheet.css, isNot(contains('scroll-snap')));
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

  shapedTests();

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

void shapedTests() {
  group('a shaped box', () {
    const core.BoxShape hexagon = core.BoxShape(
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      commands: <core.BoxPathCommand>[
        core.BoxPathMoveTo(50, 0),
        core.BoxPathLineTo(93, 25),
        core.BoxPathLineTo(50, 100),
        core.BoxPathClose(),
      ],
    );

    test('carries a paint layer before its content', () {
      // The layer is the first child and paints behind the content, so a shaped box behaves
      // like a painted one.
      final ElementPlan plan = planNode(
        const core.Box(
          shape: hexagon,
          children: <core.UINode>[core.TextNode('Hi')],
        ),
        Stylesheet(),
      );

      expect(plan.children.first.tag, 'svg');
      expect(plan.children.first.className, startsWith('unibox-shape-'));
      expect(plan.children.last.tag, 'span');
    });

    test('stretches its outline with the box', () {
      final ElementPlan plan = planNode(
        const core.Box(shape: hexagon),
        Stylesheet(),
      );
      final ElementPlan layer = plan.children.first;

      expect(layer.attributes['viewBox'], '0 0 100 100');
      expect(layer.attributes['preserveAspectRatio'], 'none');
    });

    test('writes the definition its clip points at', () {
      final ElementPlan layer = planNode(
        const core.Box(shape: hexagon, overflow: core.Overflow.hidden),
        Stylesheet(),
      ).children.first;
      final ElementPlan clip = layer.children.first.children.single;

      expect(clip.tag, 'clipPath');
      expect(clip.attributes['clipPathUnits'], 'objectBoundingBox');
      expect(clip.attributes['id'], startsWith('unibox-shape-'));
    });
  });
}
