import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

/// The link of the navigation item labelled [label].
///
/// The link is the control: its `href` is the document a page without a runtime goes
/// to, and its `onTap` is what the store hears once there is one. The box inside is
/// how the label looks, so the tests that care about appearance ask for that.
LinkNode navLink(UINode page, String label) => flatten(page)
    .whereType<LinkNode>()
    .firstWhere(
      (LinkNode link) => link.onTap != null && textsIn(link).contains(label),
    );

/// The box of the navigation item labelled [label].
///
/// An item that changes the page is a link and the one that opens the sign-up
/// dialog is a button, so the role is not part of the search: the tap is.
Box navItem(UINode page, String label) => navLink(page, label).child as Box;

void main() {
  group('ExamplePage', () {
    test('names the destinations of the example', () {
      expect(ExamplePage.values, hasLength(3));
      expect(ExamplePage.signup.label, 'Sign up');
      expect(ExamplePage.apartments.label, 'Apartments');
      expect(ExamplePage.pricing.label, 'Pricing');
    });
  });

  group('buildPricingPage', () {
    test('is a marketing page a crawler can read', () {
      final UINode page = buildPricingPage(
        onStart: () {},
        onNavigate: (ExamplePage page) {},
      );
      final List<String> headings = _headings(page);

      // One h1, and a heading per section: that is the outline a search engine and
      // a screen reader both build the page from.
      expect(
        headings.where((String text) => text.startsWith('1|')),
        hasLength(1),
      );
      expect(headings, contains('2|What it costs'));
      expect(headings, contains('2|Questions'));
      expect(validateTree(page, theme: ExamplePalette.theme), isEmpty);
    });

    test('says what a home costs and what people ask', () {
      final UINode page = buildPricingPage(
        onStart: () {},
        onNavigate: (ExamplePage page) {},
      );
      final List<String> texts = _texts(page);

      // The page sells the homes, not the library: a visitor reads what a studio
      // costs and what the rent covers, and the questions are the ones a tenant
      // asks before a visit.
      expect(texts, containsAll(<String>['Studio', 'Two rooms', 'Loft']));
      expect(texts, contains('€1,180'));
      expect(texts, contains('What is in the rent?'));
    });
  });

  group('buildExamplePage', () {
    test('fills the host surface', () {
      final Box page = RecordingHost().frame();

      expect(page.width, double.infinity);
      expect(page.height, double.infinity);
      // The frame names the canvas role; the palette says what it is worth.
      expect(page.backgroundColor, const BoxColor.role(ExampleColor.canvas));
      expect(page.direction, Axis.vertical);
    });

    test('stacks the navigation above the page it was given', () {
      final Box content = Box(key: 'content');
      final List<UINode> children = RecordingHost()
          .frame(page: content)
          .children;

      expect(children, hasLength(2));
      expect(children.first, isA<Box>());
      expect(children.last, same(content));
    });

    test('offers one item per destination', () {
      final Box page = RecordingHost().frame();

      expect(navItem(page, 'Sign up'), isA<Box>());
      expect(navItem(page, 'Apartments'), isA<Box>());
    });

    test('reports the destination an item asks for', () {
      final RecordingHost host = RecordingHost();
      final Box page = host.frame();

      navLink(page, 'Apartments').onTap!();
      navLink(page, 'Sign up').onTap!();

      expect(host.navigations, <ExamplePage>[
        ExamplePage.apartments,
        ExamplePage.signup,
      ]);
    });

    test('keeps a document for every destination on its link', () {
      // The href is what a page without the client runtime follows, so it names the
      // document of the destination rather than the page being drawn.
      final Box page = RecordingHost().frame();

      expect(navLink(page, 'Apartments').url, ExampleRoutes.listings);
      expect(navLink(page, 'Sign up').url, ExampleRoutes.signup);
      expect(navLink(page, 'Pricing').url, ExampleRoutes.pricing);
    });

    test('marks the open page and not the others', () {
      final Box page = RecordingHost().frame(current: ExamplePage.apartments);

      final Box open = navItem(page, 'Apartments');
      final Box other = navItem(page, 'Sign up');

      expect(open.backgroundColor, ExamplePalette.accentSurface);
      expect(open.textStyle?.color, ExamplePalette.accent);
      expect(other.backgroundColor, isNull);
      expect(other.textStyle?.color, ExamplePalette.muted);
    });

    test('keeps the page that is open reachable from the keyboard', () {
      // A navigation item is a link, which is what puts it in the tab order:
      // without a role a box is a plain container.
      final Box item = navItem(RecordingHost().frame(), 'Apartments');

      expect(item.semantics?.role, BoxRole.link);
      expect(item.isFocusable, isTrue);
      expect(item.stateStyle(BoxState.hover), isNotNull);
    });

    test('opens the sign-up form as a dialog, not a page', () {
      final Box page = RecordingHost().frame();

      final Box trigger = navItem(page, 'Sign up');

      expect(trigger.semantics?.role, BoxRole.button);
      // A dialog is not a document, so the trigger never claims to be current.
      expect(trigger.semantics?.current, isNull);
    });

    test('puts the dialog above the page when the host has one', () {
      final OverlayNode dialog = RecordingHost().dialog();

      final List<UINode> children = RecordingHost()
          .frame(dialog: dialog)
          .children;

      expect(children, hasLength(3));
      expect(children.last, same(dialog));
    });

    test('reports a dismissal of the dialog', () {
      final RecordingHost host = RecordingHost();

      host.dialog().onDismiss!();

      expect(host.dismissals, 1);
    });
  });
}

/// The texts of a tree, in reading order.
List<String> _texts(UINode root) => <String>[
  for (final UINode node in _flatten(root))
    if (node is TextNode) node.text,
];

/// The headings of a tree as `level|text`, which is the outline of the page.
List<String> _headings(UINode root) => <String>[
  for (final UINode node in _flatten(root))
    if (node is TextNode && node.headingLevel != null)
      '${node.headingLevel}|${node.text}',
];

/// Every node of a tree, depth first.
Iterable<UINode> _flatten(UINode root) sync* {
  yield root;
  if (root is Box) {
    for (final UINode child in root.children) {
      yield* _flatten(child);
    }
  } else if (root is GridNode) {
    for (final UINode child in root.children) {
      yield* _flatten(child);
    }
  } else if (root is StackNode) {
    for (final UINode child in root.children) {
      yield* _flatten(child);
    }
  } else if (root is LinkNode) {
    yield* _flatten(root.child);
  }
}
