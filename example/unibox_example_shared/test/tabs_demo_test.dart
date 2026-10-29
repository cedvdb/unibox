import 'package:test/test.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

void main() {
  group('the tabs demo', () {
    /// The offset of page [index] in [store], which is the width the demo states.
    double at(TabsDemoStore store, int index) => index * store.state.pageWidth;

    test('is not undone by the slide a press starts', () {
      final TabsDemoStore store = TabsDemoStore();

      store.choose(1);

      // The pager slides to page 1 and reports every offset on the way. Read as choices,
      // those offsets would send the bar back to 0 and the pressed tab would never appear
      // chosen — which is what a browser did before the store held the two apart.
      for (final double part in <double>[0, 0.13, 0.4, 0.75, 0.99]) {
        store.scrolledTo(at(store, 0) + part * store.state.pageWidth);

        expect(
          store.state.selected,
          1,
          reason: 'an offset $part of the way is the slide, not a choice',
        );
      }

      store.scrolledTo(at(store, 1));
      expect(store.state.selected, 1);
    });

    test('follows the reader again once the pager has arrived', () {
      final TabsDemoStore store = TabsDemoStore();

      store.choose(2);
      store.scrolledTo(at(store, 2));

      // The pager is where the press sent it, so the next offset is the reader's.
      store.scrolledTo(at(store, 1));
      expect(store.state.selected, 1);

      store.scrolledTo(at(store, 0));
      expect(store.state.selected, 0);
    });

    test('takes a swipe as the page it settles on', () {
      final TabsDemoStore store = TabsDemoStore();

      store.scrolledTo(at(store, 0) + 0.75 * store.state.pageWidth);
      expect(
        store.state.selected,
        1,
        reason: 'three quarters of the way to the next page settles on it',
      );

      store.scrolledTo(at(store, 2));
      expect(store.state.selected, 2);
    });

    test('is a bar and a page of the same width', () {
      // A page has to be a number in the tree for the pager to land on one, so the bar above
      // it is given that number too: the two are one table, and a page narrower than the row
      // of tabs above it reads as a view that does not belong to them.
      expect(const TabsDemoState().pageWidth, greaterThan(0));
      expect(const TabsDemoState().pageWidth, 720);
    });

    test('refuses a tab that is not there', () {
      final TabsDemoStore store = TabsDemoStore();

      store.choose(7);

      expect(store.state.selected, 2);
    });
  });
}
