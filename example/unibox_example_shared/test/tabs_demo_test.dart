import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

void main() {
  group('the tabs demo', () {
    test('takes a press as the page it names', () {
      final TabsDemoStore store = TabsDemoStore();

      store.choose(1);

      expect(store.state.selected, 1);
    });

    test('takes a swipe as the page the pager settled on', () {
      // The pager reports the page it came to rest on, never the offsets on the way there, so the
      // bar follows a swipe and a press with the same number — and needs no marker to tell them
      // apart, which is what the offsets it used to read required.
      final TabsDemoStore store = TabsDemoStore();

      store.settled(2);
      expect(store.state.selected, 2);

      store.settled(0);
      expect(store.state.selected, 0);
    });

    test('ignores a settle that names the page it is already on', () {
      // A pager reports its own move when it arrives, so the press that asked for it hears the
      // same index a second time: publishing again would rebuild for a state that did not change.
      final TabsDemoStore store = TabsDemoStore();

      store.choose(1);
      store.settled(1);

      expect(store.state.selected, 1);
    });

    test(
      'is a bar and a page of the same width, and that width is a phone',
      () {
        // A page has to be a number in the tree for the pager to land on one, so the bar above
        // it is given that number too: the two are one table, and a page narrower than the row
        // of tabs above it reads as a view that does not belong to them.
        //
        // The number also has to fit the column it is drawn in. The bar keeps 32 pixels of
        // padding on each side, so a 344 pixel window leaves 280 — the width of the table — and
        // anything wider pushed the whole catalogue sideways on a phone.
        expect(const TabsDemoState().pageWidth, 280);
        expect(const TabsDemoState().pageWidth, lessThanOrEqualTo(344 - 64));
      },
    );

    test('draws the page under the bar as a square view', () {
      // A pager clips what it draws to its own outline, so a rounded view cut the corners off
      // the page inside it: the page paints the hairline that says where the view begins and
      // ends, and a corner missing from that hairline reads as a cropped page rather than as a
      // shape.
      final TabsDemoStore store = TabsDemoStore();
      final Box view = TabsDemo().viewFor(store.state, store) as Box;
      final UINode pager = view.children.last;

      expect(pager, isA<PagerNode>());
      expect((pager as PagerNode).computedStyle.overflow, Overflow.scroll);
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
