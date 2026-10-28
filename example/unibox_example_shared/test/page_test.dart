import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

/// The control the bar offers for [label]: the link of a destination, or the button
/// that opens the form.
///
/// A destination is a `LinkNode` around a label, because its `href` is what a reader
/// without a client runtime follows; the sign-up form is a `Box` with the button role,
/// because an account is an action and not a place to go.
UINode navControl(UINode page, String label) => flatten(page).firstWhere(
  (UINode node) =>
      (node is LinkNode && textsIn(node).contains(label)) ||
      (node is Box && node.onTap != null && textsIn(node).contains(label)),
);

/// The box the bar draws its label for [label] in, which is what a reader sees.
///
/// It is found by its role — a link for a destination, a button for the form — because
/// the page behind the bar carries the same word in a heading.
Box navLabelBox(UINode page, String label) =>
    flatten(page).whereType<Box>().firstWhere(
      (Box box) =>
          (box.semantics?.role == BoxRole.link ||
              box.semantics?.role == BoxRole.button) &&
          textsIn(box).contains(label),
    );

void main() {
  group('ExamplePage', () {
    test('names the destinations of the example', () {
      expect(ExamplePage.values, hasLength(2));
      expect(ExamplePage.apartments.label, 'Apartments');
      expect(ExamplePage.signup.label, 'Sign up');
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

    test(
      'stacks the picker and the navigation above the page it was given',
      () {
        final Box content = Box(key: 'content');
        final List<UINode> children = RecordingHost()
            .frame(page: content)
            .children;

        // The palette row, the bar, the page: the picker is above the bar because it
        // restyles everything below it, including the bar itself.
        expect(children, hasLength(3));
        expect(children.first, isA<Box>());
        expect(children.last, same(content));
      },
    );

    test('offers a swatch per seed, as a link to this page with that seed', () {
      final Box page = RecordingHost().frame();
      final List<LinkNode> swatches = flatten(page)
          .whereType<LinkNode>()
          .where((LinkNode link) => link.url.startsWith('?seed='))
          .toList();

      expect(swatches, hasLength(ExampleSeed.values.length));
      expect(swatches.map((LinkNode link) => link.url), <String>[
        for (final ExampleSeed seed in ExampleSeed.values) '?seed=${seed.name}',
      ]);
      // Each swatch is painted with the accent its seed grows and says which one it
      // is, because a circle of colour has no text to read.
      for (final LinkNode link in swatches) {
        final Box swatch = link.child as Box;
        final ExampleSeed seed = ExampleSeed.values[swatches.indexOf(link)];

        expect(swatch.backgroundColor, seed.accent);
        expect(swatch.semantics?.label, contains(seed.label));
      }
    });

    test('rings the seed the page is drawn with', () {
      final Box page = RecordingHost().frame(seed: ExampleSeed.rose);
      final Map<String, double?> widths = <String, double?>{
        for (final LinkNode link in flatten(page).whereType<LinkNode>())
          if (link.url.startsWith('?seed='))
            link.url: (link.child as Box).border?.width,
      };

      expect(widths['?seed=rose'], 2);
      expect(widths['?seed=blue'], 1);
    });

    test('offers a link per destination and a button for the form', () {
      final Box page = RecordingHost().frame();

      // A destination is a document, so it is a link; an account is an action, so it
      // is a button beside the navigation.
      expect(navControl(page, 'Apartments'), isA<LinkNode>());
      expect(navControl(page, 'Sign up'), isA<Box>());
      expect(
        (navControl(page, 'Sign up') as Box).semantics?.role,
        BoxRole.button,
      );
    });

    test('reports the destination an item asks for', () {
      final RecordingHost host = RecordingHost();
      final Box page = host.frame();

      final LinkNode destination = navControl(page, 'Apartments') as LinkNode;
      destination.onTap!();
      (navControl(page, 'Sign up') as Box).onTap!();

      expect(host.navigations, <ExamplePage>[
        ExamplePage.apartments,
        ExamplePage.signup,
      ]);
    });

    test('marks the open page and not the others', () {
      final Box page = RecordingHost().frame(current: ExamplePage.apartments);

      final Box open = navLabelBox(page, 'Apartments');
      final Box other = navLabelBox(page, 'Sign up');

      expect(
        open.backgroundColor,
        const BoxColor.role(ExampleColor.accentSurface),
      );
      expect(open.textStyle?.color, const BoxColor.role(ExampleColor.accent));
      expect(other.backgroundColor, const BoxColor.role(ExampleColor.accent));
      expect(other.textStyle?.color, ExampleType.button.color);
    });

    test('keeps the page that is open reachable from the keyboard', () {
      // A destination is a link, which is what puts it in the tab order: without a
      // role a box is a plain container.
      final Box item = navLabelBox(RecordingHost().frame(), 'Apartments');

      expect(item.semantics?.role, BoxRole.link);
      expect(item.isFocusable, isTrue);
      expect(item.stateStyle(BoxState.hover), isNotNull);
    });

    test('opens the sign-up form as a dialog, not a page', () {
      final Box page = RecordingHost().frame();

      final Box trigger = navLabelBox(page, 'Sign up');

      expect(trigger.semantics?.role, BoxRole.button);
      // A dialog is not a document, so the trigger never claims to be current.
      expect(trigger.semantics?.current, isNull);
    });

    test('puts the dialog above the page when the host has one', () {
      final OverlayNode dialog = RecordingHost().dialog();

      final List<UINode> children = RecordingHost()
          .frame(dialog: dialog)
          .children;

      expect(children, hasLength(4));
      expect(children.last, same(dialog));
    });

    test('reports a dismissal of the dialog', () {
      final RecordingHost host = RecordingHost();

      host.dialog().onDismiss!();

      expect(host.dismissals, 1);
    });
  });
}
