import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

void main() {
  group('PagerNode', () {
    test('is a box that scrolls, without being told to', () {
      // The scroll is what the node means rather than a token the caller remembers: a pager
      // that only clipped would have nothing to page.
      const pager = PagerNode(height: 96);

      expect(pager, isA<Box>());
      expect(pager.computedStyle.overflow, Overflow.scroll);
    });

    test('keeps the scroll when a bag or the caller says otherwise', () {
      // A pager whose `overflow` could be set would be a pager that is not one, which is the
      // state a node is for making unrepresentable.
      const pager = PagerNode(
        height: 96,
        styles: <BoxStyle>[BoxStyle(overflow: Overflow.hidden)],
      );

      expect(pager.computedStyle.overflow, Overflow.scroll);
    });

    test(
      'carries the page it shows and the report of where it came to rest',
      () {
        final List<int> settled = <int>[];
        final pager = PagerNode(
          height: 96,
          index: 0,
          onPageChanged: settled.add,
        );

        // 0 is a page and not "no answer": the bug every nullable int field invites.
        expect(pager.index, 0);
        expect(pager.onPageChanged, isNotNull);
        pager.onPageChanged!(1);
        expect(settled, <int>[1]);
      },
    );

    test('answers to its own name in an inspector', () {
      expect(const PagerNode(height: 96).debugLabel, 'pager');
    });
  });
}
