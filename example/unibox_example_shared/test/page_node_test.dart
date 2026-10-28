import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

void main() {
  group('ExampleStore', () {
    test('starts with the form and the dialog the page was given', () {
      final ExampleStore store = ExampleStore(
        initial: const SignupFormState(name: 'Ada'),
        openSignup: true,
      );

      expect(store.state.form.name, 'Ada');
      expect(store.state.signupOpen, isTrue);
      expect(store.state.current, ExamplePage.signup);
    });

    test('follows the bar: the form is open, the listings are current', () {
      final ExampleStore store = ExampleStore();

      store.navigate(ExamplePage.signup);
      expect(store.state.signupOpen, isTrue);
      expect(store.state.current, ExamplePage.signup);

      store.navigate(ExamplePage.apartments);
      expect(store.state.signupOpen, isFalse);
      expect(store.state.current, ExamplePage.apartments);
    });

    test('publishes a change and nothing for the same value', () {
      final ExampleStore store = ExampleStore();
      int notifications = 0;
      store.addListener(() => notifications++);

      store.setName('Ada');
      store.setName('Ada');
      store.setEmail('ada@example.com');

      // The second name is the value it already had, so there is nothing to draw
      // again; the email is a change.
      expect(notifications, 2);
    });

    test('clears a confirmation when a value changes', () {
      final ExampleStore store = ExampleStore(
        initial: const SignupFormState(
          name: 'Ada',
          email: 'ada@example.com',
          submitted: true,
        ),
      );

      store.setEmail('ada@example.org');

      expect(store.state.form.submitted, isFalse);
    });

    test('confirms only a complete form', () {
      final ExampleStore store = ExampleStore()..submit();

      expect(store.state.form.submitted, isFalse);

      store
        ..setName('Ada')
        ..setEmail('ada@example.com')
        ..submit();

      expect(store.state.form.submitted, isTrue);
    });

    test('closes the dialog without touching the form', () {
      final ExampleStore store = ExampleStore(
        initial: const SignupFormState(name: 'Ada'),
        openSignup: true,
      );

      store.closeSignup();

      expect(store.state.signupOpen, isFalse);
      expect(store.state.form.name, 'Ada');
    });

    test('publishes the map, which is a view of its own', () {
      // The map is a member of the state like the dialog, so opening it has to be a
      // change the store publishes: a field left out of `ExampleState ==` is a
      // toggle that draws nothing.
      final ExampleStore store = ExampleStore();
      int notifications = 0;
      store.addListener(() => notifications++);

      store.openMap();
      expect(store.state.mapOpen, isTrue);
      expect(notifications, 1);

      store.closeMap();
      expect(store.state.mapOpen, isFalse);
      expect(notifications, 2);
    });
  });

  group('ExamplePageNode', () {
    test('draws the listings and no dialog while it is closed', () {
      final UINode tree = viewOf(ExamplePageNode());

      expect(textsIn(tree), contains('Via Bellavista 12'));
      expect(textsIn(tree), isNot(contains('Join Unibox')));
      expect(flatten(tree).whereType<OverlayNode>(), isEmpty);
    });

    test('draws the dialog over the listings while it is open', () {
      final UINode tree = viewOf(ExamplePageNode(signupOpen: true));

      expect(flatten(tree).whereType<OverlayNode>(), hasLength(1));
      expect(textsIn(tree), contains('Join Unibox'));
      // The page is still there: the dialog is a layer, not another page.
      expect(textsIn(tree), contains('Via Bellavista 12'));
    });

    test('draws the values its store publishes', () {
      final ExamplePageNode node = ExamplePageNode();
      final ExampleStore store = node.create()
        ..navigate(ExamplePage.signup)
        ..setName('Ada')
        ..setEmail('ada@example.com');

      final UINode tree = node.viewFor(store.state, store);

      // The store opened the dialog, so the form it filled is in the tree.
      expect(flatten(tree).whereType<OverlayNode>(), hasLength(1));
      expect(flatten(tree).whereType<TextInputNode>().first.value, 'Ada');
      expect(textsIn(tree), contains('Looks good - press Create account.'));
    });

    test('starts in the state the export asks for', () {
      final ExamplePageNode node = ExamplePageNode(signupOpen: true);
      final ExampleStore store = node.create();

      expect(store.state.signupOpen, isTrue);
      expect(
        flatten(node.viewFor(store.state, store)).whereType<OverlayNode>(),
        hasLength(1),
      );
    });
  });
}
