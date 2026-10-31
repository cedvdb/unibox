import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('MaterialAppBar', () {
    test('is a box with the tokens Material gives a small app bar', () {
      final MaterialAppBar bar = MaterialAppBar(
        title: const TextNode('Results'),
      );

      expect(bar, isA<Box>());
      expect(bar.height, MaterialAppBar.topHeight);
      expect(
        bar.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainer),
      );
      // Material 3 draws no divider; a bar that draws one states it, and the hairline is the
      // value both targets can draw without knowing that the content has scrolled.
      expect(bar.border, MaterialAppBar.hairline);
      expect(bar.direction, Axis.horizontal);
      expect(bar.mainAlign, MainAlign.spaceBetween);
      expect(bar.crossAlign, CrossAlign.center);
      // A band is a header of what it sits over, on the web and in an accessibility tree.
      expect(bar.semantics?.element, BoxElement.header);
    });

    test(
      'pins by stating the edge, so the inset and the end edge come free',
      () {
        final MaterialAppBar start = MaterialAppBar(
          title: const TextNode('Filters'),
          pin: BoxPin.start,
        );
        final MaterialAppBar under = MaterialAppBar(
          title: const TextNode('Two rooms'),
          pin: BoxPin.start,
          pinOffset: MaterialAppBar.topHeight,
        );
        final MaterialAppBar end = MaterialAppBar(
          title: const TextNode('Continue'),
          pin: BoxPin.end,
        );

        expect(start.pin, BoxPin.start);
        expect(start.pinOffset, isNull);
        expect(under.pinOffset, MaterialAppBar.topHeight);
        expect(end.pin, BoxPin.end);
        // A bar that does not pin states no edge at all: the same component is a header.
        expect(MaterialAppBar(title: const TextNode('Results')).pin, isNull);
      },
    );

    test('paints the container one step above the page', () {
      // The screen behind a bar is the scaffold's `surface`; the bar itself is a container, which
      // is the difference that makes a band read as a band.
      final MaterialAppBar bar = MaterialAppBar(
        title: const TextNode('Results'),
      );

      expect(bar.backgroundColor, MaterialAppBar.surface);
      expect(
        bar.backgroundColor,
        isNot(MaterialScaffold.surface),
        reason: 'a bar the colour of the page is the first row of the list',
      );
    });

    test('puts the title at the start and the trailing node at the end', () {
      final MaterialAppBar bar = MaterialAppBar(
        title: const TextNode('Results'),
        trailing: const TextNode('6 of 24'),
      );

      expect(bar.children, hasLength(2));
      expect(bar.children.last, isA<TextNode>());
      expect(
        bar.textStyle,
        isNull,
        reason: 'the bar sets type on its title, not on itself',
      );
    });
  });

  group('MaterialLargeAppBar', () {
    test('is a box with the tokens Material gives a large app bar', () {
      final MaterialLargeAppBar band = MaterialLargeAppBar(
        title: const TextNode('Six flats, one tree'),
      );

      expect(band, isA<Box>());
      expect(band.height, MaterialLargeAppBar.largeHeight);
      expect(band.backgroundColor, MaterialLargeAppBar.surface);
      // The headline sits on the floor of the band: the air is above it.
      expect(band.mainAlign, MainAlign.end);
      expect(band.crossAlign, CrossAlign.start);
      expect(band.semantics?.element, BoxElement.header);
    });

    test('folds, and keeps the height it states while it does', () {
      const BoxFold fold = BoxFold(
        to: BoxStyle(opacity: 0.1, transform: BoxTransform(scale: 0.62)),
      );
      final MaterialLargeAppBar band = MaterialLargeAppBar(
        title: const TextNode('Six flats, one tree'),
        fold: fold,
      );

      expect(band.fold, fold);
      // The fold is paint: the band's height is the room the flow keeps, whatever it paints.
      expect(band.height, MaterialLargeAppBar.largeHeight);
      expect(band.fold!.looks, contains(BoxProperty.opacity));
    });

    test('pins, so a band whose height a store drives can stay at the top', () {
      final MaterialLargeAppBar band = MaterialLargeAppBar(
        title: const TextNode('Apartments'),
        pin: BoxPin.start,
      );

      // A collapse is a height a rebuild states, so the band that collapses is the band that has
      // to be able to pin: without the edge it would scroll away as it shrank.
      expect(band.pin, BoxPin.start);
      expect(
        MaterialLargeAppBar(
          title: const TextNode('Apartments'),
          pin: BoxPin.start,
          pinOffset: 8,
        ).pinOffset,
        8,
      );
    });

    test('shares the surface of the small bar, so the pair are one colour', () {
      expect(MaterialLargeAppBar.surface, MaterialAppBar.surface);
    });
  });
}
