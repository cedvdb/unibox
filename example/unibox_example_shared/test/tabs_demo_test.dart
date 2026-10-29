import 'package:test/test.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

void main() {
  group('the tabs demo', () {
    test('is not undone by the slide a press starts', () {
      final TabsDemoStore store = TabsDemoStore();

      store.choose(1);

      // The pager slides to page 1 and reports every offset on the way. Read as choices,
      // those offsets would send the bar back to 0 and the pressed tab would never appear
      // chosen — which is what a browser did before the store held the two apart.
      for (final double offset in <double>[0, 30, 96, 180, 239]) {
        store.scrolledTo(offset);
        expect(
          store.state.selected,
          1,
          reason: 'an offset of $offset is the slide, not a choice',
        );
      }

      store.scrolledTo(240);
      expect(store.state.selected, 1);
    });

    test('follows the reader again once the pager has arrived', () {
      final TabsDemoStore store = TabsDemoStore();

      store.choose(2);
      store.scrolledTo(480);

      // The pager is where the press sent it, so the next offset is the reader's.
      store.scrolledTo(240);
      expect(store.state.selected, 1);

      store.scrolledTo(0);
      expect(store.state.selected, 0);
    });

    test('takes a swipe as the page it settles on', () {
      final TabsDemoStore store = TabsDemoStore();

      store.scrolledTo(180);
      expect(
        store.state.selected,
        1,
        reason: 'three quarters of the way to the next page settles on it',
      );

      store.scrolledTo(480);
      expect(store.state.selected, 2);
    });

    test('refuses a tab that is not there', () {
      final TabsDemoStore store = TabsDemoStore();

      store.choose(7);

      expect(store.state.selected, 2);
    });
  });
}
