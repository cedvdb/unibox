import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

/// The box of the navigation item labelled [label].
///
/// An item that changes the page is a link and the one that opens the sign-up
/// dialog is a button, so the role is not part of the search: the tap is.
Box navItem(UINode page, String label) => flatten(page)
    .whereType<Box>()
    .firstWhere((Box box) => box.onTap != null && textsIn(box).contains(label));

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

      navItem(page, 'Apartments').onTap!();
      navItem(page, 'Sign up').onTap!();

      expect(host.navigations, <ExamplePage>[
        ExamplePage.apartments,
        ExamplePage.signup,
      ]);
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
