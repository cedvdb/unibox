import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';
import 'package:unibox_material/unibox_material.dart';

/// What a design-system component looks like in a document.
///
/// `unibox_html` does not depend on `unibox_material` — a renderer knows nothing of a
/// design system — but a renderer that cannot draw one is not finished, so the test that
/// proves it lives here and the dependency is a dev one.
void main() {
  group('a ripple in the stylesheet', () {});

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
      scope: core.UniboxScope(theme: MaterialPalette.light.theme),
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
      // A pressed state belongs to a button, and every segment here is a link.
      expect(html, isNot(contains('aria-pressed')));
    });
  });

  group('a segmented button of choices', () {
    String renderChoices() => toHtml(
      MaterialSegmentedButton(
        selected: 1,
        onSelect: (int index) {},
        width: 300,
        segments: const <MaterialSegment>[
          MaterialSegment(label: core.TextNode('Day')),
          MaterialSegment(label: core.TextNode('Week')),
          MaterialSegment(label: core.TextNode('Month')),
        ],
      ),
      scope: core.UniboxScope(theme: MaterialPalette.light.theme),
    );

    test('says which choice is pressed, and says which ones are not', () {
      // The bug this pins: a selecting segment announced "button" and no state, so the
      // fill and the check were the only things saying which choice was on. A toggle
      // button states its state either way, so the two that are off say so too.
      final String html = renderChoices();

      expect(html, contains('aria-pressed="true"'));
      expect(RegExp('aria-pressed="false"').allMatches(html).length, 2);
    });
  });

  group('a filter chip in a document', () {
    String renderChip({bool selected = false, String? url}) => toHtml(
      MaterialChip(
        label: const core.TextNode('Studio'),
        selected: selected,
        onTap: url == null ? () {} : null,
        url: url,
      ),
      scope: core.UniboxScope(theme: MaterialPalette.light.theme),
    );

    test('says whether it is chosen with aria-pressed', () {
      expect(renderChip(selected: true), contains('aria-pressed="true"'));
      // A chip that is not chosen is a toggle that is off, not a chip with no state.
      expect(renderChip(), contains('aria-pressed="false"'));
    });

    test('states no press when it is a destination', () {
      // A selected destination chip is the page the reader is on: `aria-current`, never
      // `aria-pressed`, for the reason the segment above says none.
      final String html = renderChip(
        selected: true,
        url: '/spots?filter=studio',
      );

      expect(html, contains('aria-current="page"'));
      expect(html, isNot(contains('aria-pressed')));
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
          .rulesSince((classes: 0, states: 0, frames: 0))
          .firstWhere((String rule) => rule.startsWith('.${plan.className!}{'));

      // The card is content, not a control: a press belongs to the ink inside it.
      expect(plan.attributes, isNot(contains('role')));
      expect(plan.attributes, isNot(contains('tabindex')));
      expect(rule, isNot(contains('cursor:pointer')));
      expect(rule, isNot(contains('padding')));
    });
  });

  group('a Material control in a document', () {
    /// The declarations of the class [plan] wears.
    String ruleOf(Stylesheet sheet, ElementPlan plan) => sheet
        .rulesSince((classes: 0, states: 0, frames: 0))
        .firstWhere((String rule) => rule.startsWith('.${plan.className!}{'));

    test('puts the floor on the press, not on the pill around it', () {
      // A minimum on the fill paints a pill bigger than the box that answers the pointer, so
      // the ends of a button look pressable and are dead. The fill hugs a press that states
      // the floor itself.
      final MaterialButton roomy = MaterialButton.outlined(
        label: const core.TextNode('Sign in'),
        padding: const core.BoxSpacing.symmetric(horizontal: 16, vertical: 4),
        onTap: () {},
      );
      final MaterialButton pinned = MaterialButton.filled(
        label: const core.TextNode('Sign in'),
        width: 220,
        onTap: () {},
      );

      for (final MaterialButton button in <MaterialButton>[roomy, pinned]) {
        final Stylesheet sheet = Stylesheet();
        final ElementPlan row = planNode(button, sheet);
        final ElementPlan pill = row.children.single;
        final ElementPlan press = pill.children.single;
        final String pillRule = ruleOf(sheet, pill);
        final String pressRule = ruleOf(sheet, press);

        expect(pressRule, contains('min-width:64px'));
        expect(pressRule, contains('min-height:40px'));
        expect(pillRule, isNot(contains('min-width')));
        expect(pillRule, isNot(contains('min-height')));
      }

      // A pinned width is the press's as well, or the sides of the pill are dead.
      final Stylesheet sheet = Stylesheet();
      final ElementPlan row = planNode(pinned, sheet);
      final ElementPlan pill = row.children.single;
      final ElementPlan press = pill.children.single;

      expect(ruleOf(sheet, pill), contains('width:220px'));
      expect(ruleOf(sheet, press), contains('width:220px'));
    });

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
