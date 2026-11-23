import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';

/// What a tree becomes, before anyone writes it.
///
/// The renderers' own suites check the markup they produce; these check the plan they both read,
/// which is why they are about elements rather than about HTML.
void main() {
  test('a declared keyboard action is eligible for handover without a server callback', () {
    final ElementPlan plan = planNode(
      const core.Box(
        key: 'search',
        semantics: core.BoxSemantics(role: core.BoxRole.button),
      ),
      Stylesheet(),
    );
    expect(plan.attributes['data-unibox-action'], '');
  });

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

    test('names a progress bar, which is what a label may sit on', () {
      // A label on an element that is not allowed one is a name with nothing to name: a browser
      // reports `aria-label` on a bare `div` as prohibited, which is exactly what a labelled
      // progress ring used to be. The role is what makes the name legal, and what a reader hears.
      final ElementPlan plan = planOf(
        const core.Box(
          semantics: core.BoxSemantics(
            role: core.BoxRole.progressBar,
            label: '42% complete',
            progress: core.BoxProgress(value: 0.42),
          ),
        ),
      );

      expect(plan.tag, 'div');
      expect(plan.attributes['role'], 'progressbar');
      expect(plan.attributes['aria-label'], '42% complete');
      // The figure, and the range it sits in: a fraction of a turn unless the tree states more.
      expect(plan.attributes['aria-valuenow'], '0.42');
      expect(plan.attributes['aria-valuemin'], '0.0');
      expect(plan.attributes['aria-valuemax'], '1.0');
      // Structural: a reader is told a value rather than offered one, so it takes no tab stop.
      expect(plan.attributes, isNot(contains('tabindex')));
    });

    test('leaves the figure out of a bar that has none', () {
      // An indeterminate bar: the role, and no value to read. That is how a spinner is announced,
      // and it is the same element a determinate one is.
      final ElementPlan plan = planOf(
        const core.Box(
          semantics: core.BoxSemantics(
            role: core.BoxRole.progressBar,
            label: 'Loading',
          ),
        ),
      );

      expect(plan.attributes['role'], 'progressbar');
      expect(plan.attributes, isNot(contains('aria-valuenow')));
      expect(plan.attributes, isNot(contains('aria-valuemin')));
      expect(plan.attributes, isNot(contains('aria-valuemax')));
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
        const core.PagerNode(direction: core.Axis.horizontal),
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
      // A page keeps the size the tree gives it, and that half belongs to every box that scrolls:
      // a flex item shrinks to fit by default, and three pages that shrink into the width of one
      // leave the box nothing to scroll — a pager with one page.
      expect(sheet.css, contains('.${plan.className} > *{flex-shrink:0}'));
      // The node is the scroll, so the tree never says `overflow` for one.
      expect(sheet.css, contains('overflow:auto'));
    });

    test('a box that is not a pager writes nothing about snapping', () {
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

  group('a look is composed once', () {
    test('gives two boxes that look alike one class', () {
      final Stylesheet sheet = Stylesheet();
      final ElementPlan first = planNode(
        const core.Box(padding: core.BoxSpacing.all(8)),
        sheet,
      );
      final ElementPlan second = planNode(
        const core.Box(padding: core.BoxSpacing.all(8)),
        sheet,
      );

      expect(second.className, first.className);
      expect(
        sheet.length,
        1,
        reason: 'one look is one rule, however many nodes wear it',
      );
    });

    test('keeps two boxes apart when only their states differ', () {
      // What a sheet remembers has to include the state styles, not only the resting look: two
      // boxes that rest alike and tint differently would otherwise wear one class, and the tint
      // of the first would answer a press on the second.
      final Stylesheet sheet = Stylesheet();
      final ElementPlan plain = planNode(
        const core.Box(padding: core.BoxSpacing.all(8)),
        sheet,
      );
      final ElementPlan tinted = planNode(
        const core.Box(
          padding: core.BoxSpacing.all(8),
          hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor(0xFF00FF00)),
        ),
        sheet,
      );

      expect(tinted.className, isNot(plain.className));
      expect(sheet.css, contains('.${tinted.className}:hover'));
      expect(
        sheet.css,
        isNot(contains('.${plain.className}:hover')),
        reason: 'a box that states no hover has no hover rule',
      );
    });

    test('keeps two texts apart when only their alignment differs', () {
      final Stylesheet sheet = Stylesheet();
      final ElementPlan start = planNode(const core.TextNode('Hi'), sheet);
      final ElementPlan centred = planNode(
        const core.TextNode('Hi', textAlign: core.TextAlign.center),
        sheet,
      );

      expect(centred.className, isNot(start.className));
    });

    test('keeps two texts apart when only one of them is a heading', () {
      // A heading's class carries the reset that takes a browser's own heading look apart, so
      // a heading and a plain text of the same typography are two looks. Sharing one let
      // whichever was planned first answer for both — and when that was a plain text, the
      // `<h2>` wore a class that said nothing about its element and the user agent drew it at
      // `1.5em` with `0.83em` margins: a dialog's title a third taller, and the card with it.
      final Stylesheet sheet = Stylesheet();
      final ElementPlan plain = planNode(const core.TextNode('Flat'), sheet);
      final ElementPlan heading = planNode(
        const core.TextNode('Flat', headingLevel: 2),
        sheet,
      );

      expect(heading.className, isNot(plain.className));
      expect(
        sheet.css,
        contains('.${heading.className}{'),
        reason: 'a heading has a rule of its own to state the reset in',
      );
      expect(
        RegExp('\\.${RegExp.escape(heading.className!)}\\{([^}]*)\\}')
            .firstMatch(sheet.css)!
            .group(1),
        contains('margin:0'),
      );
    });
  });

  group('a sheet forgets what nothing wears', () {
    test('forgets the rules of a class that is not worn, and its states', () {
      final Stylesheet sheet = Stylesheet();
      final ElementPlan kept = planNode(
        const core.Box(backgroundColor: core.BoxColor(0xFF00FF00)),
        sheet,
      );
      final ElementPlan gone = planNode(
        const core.Box(
          backgroundColor: core.BoxColor(0xFF0000FF),
          hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor(0xFFFF0000)),
        ),
        sheet,
      );

      expect(sheet.retain(<String>{kept.className!}), isTrue);
      expect(sheet.css, contains(kept.className!));
      expect(
        sheet.css,
        isNot(contains(gone.className!)),
        reason: 'a state rule goes with the class it belongs to',
      );
      expect(sheet.length, 1);
    });

    test('keeps every rule when the page wears every class', () {
      // A prune that finds nothing to forget is a walk and no change, which is what a renderer
      // reads the answer for: nothing to write.
      final Stylesheet sheet = Stylesheet();
      final ElementPlan box = planNode(
        const core.Box(backgroundColor: core.BoxColor(0xFF00FF00)),
        sheet,
      );
      final String before = sheet.css;

      expect(sheet.retain(<String>{box.className!}), isFalse);
      expect(sheet.css, before);
    });

    test('gives a look the name it had when it comes back', () {
      // A class is a hash of the declarations, so forgetting a look costs nothing when it
      // returns — which is what makes it safe to forget one at all.
      final Stylesheet sheet = Stylesheet();
      const core.Box box = core.Box(backgroundColor: core.BoxColor(0xFF00FF00));
      final ElementPlan first = planNode(box, sheet);

      sheet.retain(const <String>{});
      expect(sheet.length, 0);
      expect(sheet.css, isEmpty);

      final ElementPlan again = planNode(box, sheet);

      expect(again.className, first.className);
      expect(sheet.length, 1);
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
