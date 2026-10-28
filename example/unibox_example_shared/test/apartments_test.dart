import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

import 'support/tree.dart';

void main() {
  group('Apartment', () {
    test('summarises itself for the card', () {
      const Apartment apartment = Apartment(
        name: 'Via Bellavista 12',
        district: 'Saint-Gilles',
        rooms: 3,
        area: 84,
        rent: 1850,
        photo: 'https://example.com/a.jpg',
        tags: 'Bright, quiet street',
      );

      expect(apartment.summary, '3 rooms · 84 m²');
      expect(apartment.priceLine, '€1850');
      expect(apartment.locationLine, 'Saint-Gilles · Brussels');
    });

    test('gives every listing in the example its own name', () {
      final Set<String> names = exampleApartments
          .map((Apartment apartment) => apartment.name)
          .toSet();

      expect(exampleApartments.length, greaterThan(4));
      expect(names, hasLength(exampleApartments.length));
    });
  });

  group('buildApartmentsPage', () {
    test('scrolls instead of growing the page', () {
      final Box page = buildApartmentsPage();

      expect(page.overflow, Overflow.scroll);
      expect(page.flex, 1);
      expect(page.direction, Axis.vertical);
      // A scrolling box may not distribute its children: they would be pushed
      // out of reach instead of scrolled to.
      expect(page.mainAlign, isNull);
    });

    test('keeps the padding inside the scrolling area', () {
      // Flutter puts the padding of a scrolling box around its viewport, CSS puts
      // it inside the scrollport, so the padding of the page sits one level in.
      final Box page = buildApartmentsPage();

      expect(page.padding, isNull);
      expect(page.children.single, isA<Box>());
      expect((page.children.single as Box).padding, isNotNull);
    });

    test('lists every apartment of the example', () {
      final List<String> texts = textsIn(buildApartmentsPage());

      expect(texts.first, 'Apartments');
      for (final Apartment apartment in exampleApartments) {
        expect(texts, contains(apartment.name));
        expect(texts, contains(apartment.summary));
        expect(texts, contains(apartment.priceLine));
      }
    });

    test('lays the cards out as a reflowing grid of Material cards', () {
      // The cards are the grid with the most children: the filters are a grid too,
      // because a row of pills has to wrap on a narrow surface.
      final GridNode grid = flatten(buildApartmentsPage())
          .whereType<GridNode>()
          .reduce(
            (GridNode a, GridNode b) =>
                a.children.length >= b.children.length ? a : b,
          );

      // Two columns beside the map, one when the column cannot hold two.
      expect(grid.minItemWidth, 240);
      expect(grid.maxColumns, 2);
      expect(grid.gap, 12);
      expect(grid.children, hasLength(exampleApartments.length));
      expect(
        grid.children.whereType<MaterialCard>(),
        hasLength(exampleApartments.length),
      );
    });
  });
}
