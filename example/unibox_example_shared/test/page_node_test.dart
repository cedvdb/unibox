import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

void main() {
  group('ExampleStore', () {
    test('starts with the form the page was given, and no dialog', () {
      final ExampleStore store = ExampleStore(
        initial: const SignupFormState(name: 'Ada'),
      );

      expect(store.state.form.name, 'Ada');
      expect(store.state.signupOpen, isFalse);
    });

    test('follows the bar: the form opens over the page it was opened on', () {
      final ExampleStore store = ExampleStore();

      store.navigate(ExamplePage.signup);
      expect(store.state.signupOpen, isTrue);
      // An account is a dialog, not a destination: the listings stay the page, and
      // the bar goes on highlighting them under the form.
      expect(store.state.current, ExamplePage.signup);

      store.navigate(ExamplePage.apartments);
      expect(store.state.signupOpen, isFalse);
      expect(store.state.current, ExamplePage.apartments);
    });

    test('publishes every field it carries, not only the form', () {
      // The store skips a publish whose state equals the last one, so a field left out
      // of `==` is a change nobody draws: the filter and the layout were silent before
      // they were compared, and the dialog was the only member that could redraw.
      final ExampleStore store = ExampleStore();
      int notifications = 0;
      store.addListener(() => notifications++);

      store.chooseFilter('Studio');
      expect(store.state.filter, 'Studio');

      store.showListings(ListingsView.list);
      expect(store.state.view, ListingsView.list);

      store.openSignup();
      expect(store.state.signupOpen, isTrue);

      expect(
        notifications,
        3,
        reason: 'one publish per change, no more, no less',
      );
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
      )..openSignup();

      store.closeSignup();

      expect(store.state.signupOpen, isFalse);
      expect(store.state.form.name, 'Ada');
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
      final ExamplePageNode node = ExamplePageNode();
      final ExampleStore store = node.create()..openSignup();
      final UINode tree = node.viewFor(store.state, store);

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
  });
}
