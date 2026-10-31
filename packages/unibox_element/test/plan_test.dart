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
      // A page keeps the size the tree gives it, and that half belongs to every box that scrolls:
      // a flex item shrinks to fit by default, and three pages that shrink into the width of one
      // leave the box nothing to scroll — a pager with one page.
      expect(sheet.css, contains('.${plan.className} > *{flex-shrink:0}'));
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
  group('a box that navigates', () {
    // One look, written twice: the anchor's rule is the plain one plus the two
    // declarations that cancel what a browser paints on every link.
    const core.Box plain = core.Box(
      padding: core.BoxSpacing.all(12),
      children: <core.UINode>[core.TextNode('Meeting room')],
    );
    const core.Box anchor = core.LinkNode(
      '/?category=meetingRoom',
      padding: core.BoxSpacing.all(12),
      children: <core.UINode>[core.TextNode('Meeting room')],
    );

    ElementPlan planOf(core.UINode node) => planNode(node, Stylesheet());

    /// The plan of [node] in a sheet a test can read the rules of.
    ElementPlan planNodeWith(core.UINode node, Stylesheet sheet) =>
        planNode(node, sheet);

    /// The one rule [className] declares.
    String ruleOf(Stylesheet sheet, String className) => sheet
        .rulesSince((classes: 0, states: 0, frames: 0))
        .firstWhere((String rule) => rule.startsWith('.$className{'));

    test(
      'keeps the children of a scrolling box at the size the tree states',
      () {
        // The rule belongs to the box that scrolls, so it is written against its class and reaches
        // every child: without it a browser shrinks them to fit and the box has nothing to scroll.
        final Stylesheet sheet = Stylesheet();
        final ElementPlan plan = planNode(
          const core.Box(height: 200, overflow: core.Overflow.scroll),
          sheet,
        );

        expect(
          sheet.rulesSince((classes: 0, states: 0, frames: 0)),
          contains('.${plan.className} > *{flex-shrink:0}'),
        );
      },
    );

    test('is the anchor element, with the look and the children it had', () {
      final Stylesheet sheet = Stylesheet();
      final ElementPlan notLinked = planNodeWith(plain, sheet);
      final ElementPlan linked = planNodeWith(anchor, sheet);

      expect(linked.tag, 'a');
      expect(linked.attributes['href'], '/?category=meetingRoom');
      expect(linked.children, hasLength(1));
      // The class is a hash of the declarations, and the anchor declares two more, so the
      // two looks cannot share a rule — a box that navigated would wear the browser's paint.
      expect(linked.className, isNot(notLinked.className));
      expect(ruleOf(sheet, linked.className!), contains('display:flex'));
      expect(ruleOf(sheet, linked.className!), contains('padding:12px'));
      expect(
        ruleOf(sheet, linked.className!),
        contains('text-decoration:none'),
      );
      expect(ruleOf(sheet, linked.className!), contains('color:inherit'));
      expect(
        ruleOf(sheet, notLinked.className!),
        isNot(contains('text-decoration')),
      );
    });

    test('shares one rule between two anchors that look alike', () {
      final Stylesheet sheet = Stylesheet();
      final ElementPlan first = planNodeWith(anchor, sheet);
      final ElementPlan second = planNodeWith(anchor, sheet);

      expect(second.className, first.className);
      // One rule for the look, however many anchors wear it: the text inside them has a
      // class of its own, which is not what this counts.
      expect(
        sheet
            .rulesSince((classes: 0, states: 0, frames: 0))
            .where((String rule) => rule.startsWith('.unibox-box-')),
        hasLength(1),
      );
    });

    test('opens in a new tab when it says so', () {
      final ElementPlan plan = planOf(
        const core.LinkNode('/rooms', newTab: true),
      );

      expect(plan.attributes['target'], '_blank');
      expect(plan.attributes['rel'], 'noopener noreferrer');
    });

    test('opens in the same tab by default', () {
      final ElementPlan plan = planNode(
        const core.LinkNode('/rooms'),
        Stylesheet(),
      );

      expect(plan.attributes, isNot(contains('target')));
      expect(plan.attributes, isNot(contains('rel')));
    });

    test('announces a link, not the button a component asked for', () {
      // The tag is the role: a role attribute on an `<a href>` would overrule the link,
      // and a `tabindex` would restate a tab stop the element already has.
      final ElementPlan plan = planOf(
        const core.LinkNode(
          '/rooms',
          semantics: core.BoxSemantics(
            role: core.BoxRole.button,
            label: 'Meeting room',
            pressed: true,
          ),
        ),
      );

      expect(plan.attributes, isNot(contains('role')));
      expect(plan.attributes, isNot(contains('tabindex')));
      // The name and the current item survive: a destination can say both.
      expect(plan.attributes['aria-label'], 'Meeting room');
    });

    test('says which page it is with aria-current', () {
      final ElementPlan plan = planOf(
        const core.LinkNode(
          '/rooms',
          semantics: core.BoxSemantics(current: core.BoxCurrent.page),
        ),
      );

      expect(plan.attributes['aria-current'], 'page');
    });

    test('says whether a toggle button is pressed, on and off', () {
      // A toggle states its state either way: `false` is how a reader hears "not
      // pressed", and a control that said nothing when it was off would be announced as
      // an ordinary button, which is the bug this pins.
      final ElementPlan on = planOf(
        const core.Box(
          semantics: core.BoxSemantics(
            role: core.BoxRole.button,
            pressed: true,
          ),
        ),
      );
      final ElementPlan off = planOf(
        const core.Box(
          semantics: core.BoxSemantics(
            role: core.BoxRole.button,
            pressed: false,
          ),
        ),
      );

      expect(on.attributes['aria-pressed'], 'true');
      expect(off.attributes['aria-pressed'], 'false');
    });

    test('states no pressed link, because a destination says where it is', () {
      // A pressed state belongs to a button; a link that named one would be a link wearing
      // a control's state, so it says `aria-current` and nothing about a press.
      final ElementPlan link = planOf(
        const core.LinkNode(
          '/rooms',
          semantics: core.BoxSemantics(
            role: core.BoxRole.button,
            pressed: true,
          ),
        ),
      );
      final ElementPlan unset = planOf(
        const core.Box(semantics: core.BoxSemantics(role: core.BoxRole.button)),
      );

      expect(link.attributes, isNot(contains('aria-pressed')));
      expect(unset.attributes, isNot(contains('aria-pressed')));
    });

    test('names no destination when it is disabled', () {
      // A disabled control drops what it does and keeps what it looks like, and a browser
      // that followed the href anyway would do what Flutter refuses to do.
      final ElementPlan plan = planOf(
        const core.LinkNode(
          '/rooms',
          enabled: false,
          semantics: core.BoxSemantics(label: 'Rooms'),
        ),
      );

      expect(plan.tag, 'a');
      expect(plan.attributes, isNot(contains('href')));
      expect(plan.attributes['aria-disabled'], 'true');
    });

    test('is the anchor the box states as well as the one a url makes', () {
      // `<a>` is an element, not an attribute: a box that says it is one is written as one
      // whether or not it names a destination.
      final ElementPlan stated = planNode(
        const core.LinkNode(
          '/rooms',
          semantics: core.BoxSemantics(element: core.BoxElement.a),
        ),
        Stylesheet(),
      );
      final ElementPlan placeholder = planNode(
        const core.Box(
          semantics: core.BoxSemantics(element: core.BoxElement.a),
        ),
        Stylesheet(),
      );

      expect(stated.tag, 'a');
      expect(stated.attributes['href'], '/rooms');
      // A placeholder names no destination, so nothing navigates and nothing is a tab stop.
      expect(placeholder.tag, 'a');
      expect(placeholder.attributes, isNot(contains('href')));
      expect(placeholder.attributes, isNot(contains('tabindex')));
    });

    test('needs no role beside an anchor, because the tag is the role', () {
      final ElementPlan plan = planNode(
        const core.LinkNode(
          '/rooms',
          semantics: core.BoxSemantics(
            element: core.BoxElement.a,
            role: core.BoxRole.link,
          ),
        ),
        Stylesheet(),
      );

      expect(plan.attributes, isNot(contains('role')));
    });

    test('writes no href and no tab stop for a url on some other element', () {
      // `validateTree` reports the pair, so this is the render a release build would make of
      // a tree the debug build refuses: a plain `<nav>`. An href on it would be a link that
      // nothing follows, and a tab stop would make the broken tree reachable by keyboard.
      final ElementPlan plan = planNode(
        const core.LinkNode(
          '/rooms',
          semantics: core.BoxSemantics(element: core.BoxElement.nav),
        ),
        Stylesheet(),
      );

      expect(plan.tag, 'nav');
      expect(plan.attributes, isNot(contains('href')));
      expect(plan.attributes, isNot(contains('tabindex')));
    });

    test('takes the pointer even with nothing inside it', () {
      // A painted leaf takes no pointer; an anchor is never a decoration, so an empty one
      // is still the thing a reader presses.
      final Stylesheet sheet = Stylesheet();
      final ElementPlan plan = planNodeWith(
        const core.LinkNode('/rooms', width: 40, height: 40),
        sheet,
      );

      expect(ruleOf(sheet, plan.className!), contains('pointer-events:auto'));
    });
  });
}
