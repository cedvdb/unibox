import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
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

    test(
      'is a bar and a page of the same width, and that width is a phone',
      () {
        // A page has to be a number in the tree for the pager to land on one, so the bar above
        // it is given that number too: the two are one table, and a page narrower than the row
        // of tabs above it reads as a view that does not belong to them.
        //
        // The number also has to fit the column it is drawn in. The band keeps 32 pixels of
        // padding on each side, so a 344 pixel window leaves 280 — the width of the table — and
        // anything wider pushed the whole catalogue sideways on a phone.
        expect(const TabsDemoState().pageWidth, 280);
        expect(const TabsDemoState().pageWidth, lessThanOrEqualTo(344 - 64));
      },
    );

    test('draws the page under the bar as a square view', () {
      // A scrolling box clips what it draws to its own outline, so a rounded view cut
      // the corners off the page inside it: the page paints the hairline that says where
      // the view begins and ends, and a corner missing from that hairline reads as a
      // cropped page rather than as a shape.
      final TabsDemoStore store = TabsDemoStore();
      final Box view = TabsDemo().viewFor(store.state, store) as Box;
      final Box pager = view.children.last as Box;

      expect(pager.overflow, Overflow.scroll);
      expect(
        pager.borderRadius,
        isNull,
        reason: 'a radius here crops the corners of the page it scrolls',
      );
    });

    test('refuses a tab that is not there', () {
      final TabsDemoStore store = TabsDemoStore();

      store.choose(7);

      expect(store.state.selected, 2);
    });
  });
}
