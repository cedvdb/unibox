import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_element/unibox_element.dart';
import 'package:unibox_html/unibox_html.dart';
import 'package:unibox_material/unibox_material.dart';

/// What a design-system component looks like in a document.
///
/// `unibox_html` does not depend on `unibox_material` — a renderer knows nothing of a
/// design system — but a renderer that cannot draw one is not finished, so the test that
/// proves it lives here and the dependency is a dev one.
void main() {
  group('an ink well in a document', () {
    String renderWell() => toHtml(
      MaterialInkWell(
        onTap: () {},
        borderRadius: 12,
        child: const core.TextNode('Ada Lovelace'),
      ),
      theme: MaterialPalette.light.theme,
    );

    test('draws its resting well, with the content in it', () {
      // A server render reads the state the store starts in: no drop is in flight, so the
      // well is the shape it rests as.
      final String html = renderWell();

      expect(html, contains('>Ada Lovelace</span>'));
      expect(html, contains('border-radius:12px'));
    });

    test('draws its tints as CSS, so hovering and pressing work without JavaScript', () {
      // The tints are state styles, not store state — which is what makes them three
      // rules a document already writes, instead of something only a runtime can do.
      final String html = renderWell();

      expect(html, contains('@media (hover: hover)'));
      expect(html, contains(':hover'));
      expect(html, contains(':active'));
    });

    test('draws no ink, because ink is a state a document cannot reach', () {
      // The ripple is a drop in the store, advanced by a timer and drawn as a layer of
      // boxes. A page without a runtime shows the resting well and no drop — which is the
      // behaviour the ink well's own documentation asks for.
      expect(renderWell(), isNot(contains('unibox-ink')));
    });

    test('resolves its colours through the theme it was given', () {
      // Every colour is a role, so a dark scheme is the host's theme and not a parameter:
      // the document writes the custom property and the `:root` block answers it.
      final String html = renderWell();

      expect(html, contains('var(--unibox-color-'));
      expect(html, contains('--unibox-color-primary:'));
    });

    test('is a region a crawler can read, not a canvas', () {
      final String html = renderWell();

      expect(html, contains('<span class="unibox-text-'));
      expect(html, isNot(contains('<canvas')));
    });
  });

  group('a ripple in the stylesheet', () {
    test('writes the looks a press needs once, so pressing again costs no rule', () {
      // The bug this exists for: a drop used to be given a new size every frame, and on the
      // web a size is a class — one rule a frame, kept for the life of the page. A button
      // pressed all afternoon left thousands of rules behind, and every frame of every press
      // rewrote the whole sheet into the document, so each press was slower than the one
      // before it. A ripple is a fixed set of looks now, and the press point snaps to a pixel.
      final MaterialInkStore store = MaterialInkStore();
      final MaterialInkWell well = MaterialInkWell(
        onTap: () {},
        borderRadius: 12,
        child: const core.TextNode('Ada Lovelace'),
      );
      final Stylesheet sheet = Stylesheet();

      /// One press, planned frame by frame the way a publish plans it.
      void ripple(core.BoxPoint at) {
        store.press(at);

        while (store.state.drops.isNotEmpty) {
          planNode(well.viewFor(store.state, store), sheet);
          store.advance(const Duration(milliseconds: 16));
        }
      }

      ripple(const core.BoxPoint(30.4, 16.7));
      final int first = sheet.length;
      expect(first, greaterThan(0));

      // The same button, tapped again a fraction of a pixel away.
      ripple(const core.BoxPoint(30.2, 16.6));
      expect(
        sheet.length,
        first,
        reason:
            'a ripple draws a fixed set of looks, and a press lands on a pixel',
      );

      // A tap a few pixels along is one look more: where it landed, not when it landed.
      ripple(const core.BoxPoint(34.4, 16.7));
      expect(sheet.length, first + 1);

      store.dispose();
    });
  });

  group('an ink well that navigates', () {
    /// How many anchors [html] holds: a control is one destination, never two.
    int anchorsIn(String html) => RegExp('<a ').allMatches(html).length;

    String render(core.UINode node) =>
        toHtml(node, theme: MaterialPalette.light.theme);

    test('is one anchor, with the look of the well and no role', () {
      final String html = render(
        MaterialInkWell(
          url: '/sign-in',
          padding: const core.BoxSpacing.all(16),
          borderRadius: 12,
          child: const core.TextNode('Sign in'),
        ),
      );

      expect(anchorsIn(html), 1);
      expect(html, contains('href="/sign-in"'));
      // The tag is the role: a `role="button"` would overrule the link, and a tabindex
      // would restate the tab stop an anchor already has.
      expect(html, isNot(contains('role="button"')));
      expect(html, isNot(contains('tabindex')));
      // The whole well is the anchor, padding included: the room is pressable.
      expect(html, contains('padding:16px'));
      expect(html, contains('border-radius:12px'));
    });

    test('is one anchor when the well paints a surface', () {
      // A layered well keeps its fill, its line and its clip on the outer box, so the
      // anchor is that box and the tints are inside it.
      final String html = render(
        MaterialInkWell(
          url: '/sign-in',
          fill: const core.BoxColor.role(MaterialColorRole.primary),
          borderRadius: 12,
          child: const core.TextNode('Sign in'),
        ),
      );

      expect(anchorsIn(html), 1);
      expect(html, contains('href="/sign-in"'));
      expect(html, isNot(contains('role="button"')));
    });

    test('is one anchor when a taller target carries the press', () {
      // The target owns the press *and* the href, because an `<a>` inside an `<a>` is not
      // a link at all: the shape inside it names no destination.
      final String html = render(
        MaterialInkWell(
          url: '/sign-in',
          height: 32,
          tapTargetHeight: 48,
          borderRadius: 8,
          child: const core.TextNode('Sign in'),
        ),
      );

      expect(anchorsIn(html), 1);
      expect(html, contains('href="/sign-in"'));
    });

    test(
      'draws the box the same well would draw, and differs by the anchor',
      () {
        // The well builds one region and only its type changes, so a linked well and a well
        // with a callback have to look alike: the same declarations, one class apart from the
        // two that cancel what a browser paints on a link.
        final Stylesheet plain = Stylesheet();
        final Stylesheet linked = Stylesheet();
        final ElementPlan withTap = planNode(
          MaterialInkWell(
            onTap: () {},
            borderRadius: 12,
            padding: const core.BoxSpacing.all(8),
            child: const core.TextNode('Sign in'),
          ),
          plain,
        );
        final ElementPlan withUrl = planNode(
          MaterialInkWell(
            url: '/sign-in',
            borderRadius: 12,
            padding: const core.BoxSpacing.all(8),
            child: const core.TextNode('Sign in'),
          ),
          linked,
        );

        String ruleOf(Stylesheet sheet, ElementPlan plan) => sheet
            .rulesSince((classes: 0, states: 0))
            .firstWhere((String r) => r.startsWith('.${plan.className!}{'));

        // The body, not the selector: the classes differ, which is the one thing that should.
        String withoutLinkResets(String rule) => rule
            .substring(rule.indexOf('{') + 1)
            .replaceAll('color:inherit;', '')
            .replaceAll('text-decoration:none;', '');

        final String a = withoutLinkResets(ruleOf(plain, withTap));
        final String b = withoutLinkResets(ruleOf(linked, withUrl));

        expect(withTap.tag, isNot('a'));
        expect(withUrl.tag, 'a');
        expect(b, a, reason: 'a link draws the box it would have drawn');
      },
    );

    test('opens in a new tab when it says so', () {
      final String html = render(
        MaterialInkWell(
          url: '/sign-in',
          newTab: true,
          child: const core.TextNode('Sign in'),
        ),
      );

      expect(html, contains('target="_blank"'));
      expect(html, contains('rel="noopener noreferrer"'));
    });
  });

  group('a segmented button of destinations', () {
    String renderCatalogue() => toHtml(
      MaterialSegmentedButton(
        selected: 1,
        width: 300,
        segments: const <MaterialSegment>[
          MaterialSegment(label: core.TextNode('Day'), url: '/?period=day'),
          MaterialSegment(label: core.TextNode('Week'), url: '/?period=week'),
          MaterialSegment(label: core.TextNode('Month'), url: '/?period=month'),
        ],
      ),
      theme: MaterialPalette.light.theme,
    );

    test('draws every unselected choice as one anchor', () {
      final String html = renderCatalogue();

      expect(RegExp('<a ').allMatches(html).length, 2);
      expect(html, contains('href="/?period=day"'));
      expect(html, contains('href="/?period=month"'));
      expect(html, isNot(contains('role="button"')));
    });

    test('marks the chosen one as the page, without a link to itself', () {
      final String html = renderCatalogue();

      expect(html, isNot(contains('href="/?period=week"')));
      expect(html, contains('aria-current="page"'));
      expect(html, isNot(contains('tabindex')));
    });
  });

  group('a card in a document', () {
    test('is a surface: no role, no tab stop, no hand and no padding ring', () {
      final Stylesheet sheet = Stylesheet();
      final ElementPlan plan = planNode(
        MaterialCard(
          children: <core.UINode>[const core.TextNode('Two nights')],
        ),
        sheet,
      );
      final String rule = sheet
          .rulesSince((classes: 0, states: 0))
          .firstWhere((String rule) => rule.startsWith('.${plan.className!}{'));

      // The card is content, not a control: a press belongs to the ink inside it.
      expect(plan.attributes, isNot(contains('role')));
      expect(plan.attributes, isNot(contains('tabindex')));
      expect(rule, isNot(contains('cursor:pointer')));
      expect(rule, isNot(contains('padding')));
    });

    test('is one anchor when its whole surface is the destination', () {
      // The recipe the card documents: surface outside, ink inside, padding on the ink.
      final String html = toHtml(
        MaterialCard(
          overflow: core.Overflow.hidden,
          children: <core.UINode>[
            MaterialInkWell(
              url: '/spots/abc/book',
              padding: const core.BoxSpacing.all(16),
              child: const core.TextNode('Book'),
            ),
          ],
        ),
        theme: MaterialPalette.light.theme,
      );

      expect(RegExp('<a ').allMatches(html).length, 1);
      expect(html, contains('href="/spots/abc/book"'));
    });
  });

  group('a Material control in a document', () {
    /// The declarations of the class [plan] wears.
    String ruleOf(Stylesheet sheet, ElementPlan plan) => sheet
        .rulesSince((classes: 0, states: 0))
        .firstWhere((String rule) => rule.startsWith('.${plan.className!}{'));

    test('keeps the pointer off the count and on the control', () {
      // The badge is a picture: `pointer-events: none` hands the corner it covers back to the
      // control, so the hover, the hand and the press there are the control's.
      final Stylesheet sheet = Stylesheet();
      final ElementPlan row = planNode(
        MaterialIconButton(
          icon: MaterialIcon.codePoint(0xe9b2),
          label: 'Filters',
          badgeCount: 3,
          onTap: () {},
        ),
        sheet,
      );
      final ElementPlan square = row.children.single;
      final ElementPlan control = square.children.first.children.single;
      final ElementPlan badge = square.children.last.children.single;

      expect(
        square.children,
        hasLength(2),
        reason: 'the control and the count',
      );
      expect(ruleOf(sheet, badge), contains('pointer-events:none'));
      expect(ruleOf(sheet, control), contains('pointer-events:auto'));
    });
  });
}
