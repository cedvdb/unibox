import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

import 'support/tree.dart';

/// The pill a chip paints: its fill, its line and its clip.
///
/// A chip paints a surface of its own, so its well is layered — a 48 pixel target, the
/// 32 pixel pill inside it, and the tints over the pill.
Box _pill(MaterialChip chip) {
  final MaterialInkWell well = chip.children.single as MaterialInkWell;
  final MaterialInkStore store = MaterialInkStore();
  final Box target = well.viewFor(store.state, store) as Box;
  store.dispose();

  return target.children.single as Box;
}

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

  /// Every node under [root], depth first.
  Iterable<UINode> everyNode(UINode root) sync* {
    yield root;
    for (final UINode child in root.children) {
      yield* everyNode(child);
    }
  }

  /// The box that scrolls the listings, wherever the page keeps it.
  ///
  /// The page is a stack now — the list scrolls under a floating button — so the box
  /// that scrolls is reached through whatever wraps it rather than at a fixed depth.
  Box scrollingBox(UINode page) {
    UINode node = page;

    while (node is! Box || node.overflow != Overflow.scroll) {
      node = node.children.first;
    }

    return node;
  }

  group('buildApartmentsPage', () {
    test('scrolls instead of growing the page', () {
      final Box page = buildApartmentsPage();
      final Box scrolling = scrollingBox(page);

      expect(scrolling.overflow, Overflow.scroll);
      expect(page.flex, 1);
      expect(page.direction, Axis.vertical);
      // A scrolling box may not distribute its children: they would be pushed
      // out of reach instead of scrolled to.
      expect(scrolling.mainAlign, isNull);
    });

    test('keeps the padding inside the scrolling area', () {
      // Flutter puts the padding of a scrolling box around its viewport, CSS puts
      // it inside the scrollport, so the padding of the page sits one level in.
      final Box page = buildApartmentsPage();

      expect(page.padding, isNull);
      expect(scrollingBox(page).children.single, isA<Box>());
      expect((scrollingBox(page).children.single as Box).padding, isNotNull);
    });

    test(
      'paints the search field on the example panel, not on a Material role',
      () {
        // The palette answers two vocabularies, and the web writes one custom property
        // per role name. A field that asked for `MaterialColorRole.surface` was white on
        // the page — the example's own role won the property — and Material's pink in
        // the app, because Flutter resolved each name separately. The example's role is
        // the one the field means, and it is the only one of the two in the theme's
        // properties.
        final Box field = flatten(buildApartmentsPage())
            .whereType<Box>()
            .firstWhere((Box box) => box.borderRadius == 26);

        expect(field.backgroundColor, const BoxColor.role(ExampleColor.panel));
        expect(
          ExamplePalette.theme.resolve(field.backgroundColor!),
          ExamplePalette.panel,
          reason: 'the field is the example white on both targets',
        );
      },
    );

    test('floats a pill at the bottom centre of the page', () {
      // The listing scrolls under the pill, so the two are siblings in a stack: the
      // scroll box and an aligned cell, which needs no measurement of a window.
      final Box page = buildApartmentsPage();
      final StackNode stack = page.children.single as StackNode;
      final PositionedNode floating = stack.children.last as PositionedNode;

      expect(stack.children.first, isA<Box>());
      expect(floating.alignment, BoxAlignment.bottomCenter);
      expect(
        floating.isUnpositioned,
        isTrue,
        reason: 'an alignment is not an offset',
      );

      // A threshold measures the box it is drawn in, so the cell holds a box that
      // spans the page and centres the pill — a pill placed straight into the cell was
      // drawn on a wide window as well, because there was no box for its `visibleUntil`
      // to measure. The margin is the distance to the bottom of the page, stated by the
      // pill rather than measured by a renderer.
      final Box row = floating.child as Box;
      final Box pill = row.children.single as Box;

      expect(row.width, double.infinity);
      // The box stacks its children, so centring the pill across the page is its cross
      // axis, not its main one.
      expect(row.crossAlign, CrossAlign.center);
      expect(pill.visibleUntil, 900);
      expect(pill.margin, const BoxSpacing.only(bottom: 24));
      expect(pill.shadow, MaterialElevation.level3);
      expect(validateTree(page, theme: ExamplePalette.theme), isEmpty);
    });

    test('offers no way into a map view of its own', () {
      // The map is the column beside the cards, and a narrow page has nowhere to put
      // it: the pill is the shape of a floating action, so nothing in the page opens a
      // second view, and the filter row no longer carries a chip that stood in for one.
      final Box page = buildApartmentsPage();

      expect(flatten(page).whereType<OverlayNode>(), isEmpty);
      expect(
        flatten(page).whereType<MaterialChip>(),
        hasLength(3),
        reason:
            'two rooms, a studio and a garden: three filters, no map control',
      );
    });

    test('draws a filter as a chosen chip with a cross that clears it', () {
      final Box page = buildApartmentsPage();
      final List<MaterialChip> chips = <MaterialChip>[
        for (final UINode node in everyNode(page))
          if (node is MaterialChip) node,
      ];

      MaterialChip chosen = chips.first;
      for (final MaterialChip chip in chips) {
        if (_pill(chip).backgroundColor != null) {
          chosen = chip;
        }
      }

      expect(
        chosen.children.single,
        isA<MaterialInkWell>(),
        reason: 'a chip is a well, which paints the pill and takes the press',
      );
      expect(
        _pill(chosen).backgroundColor,
        const BoxColor.role(MaterialColorRole.secondaryContainer),
      );
      expect(
        chips.where((MaterialChip chip) => _pill(chip).border != null),
        isNotEmpty,
        reason: 'the filters that are not chosen are outlined',
      );
    });

    test('gives the listings one column or a grid, as the switch says', () {
      int columnsOf(ListingsView view) {
        final GridNode grid = everyNode(buildApartmentsPage(view: view))
            .whereType<GridNode>()
            .firstWhere((GridNode node) => node.children.length > 3);

        return grid.maxColumns ?? 0;
      }

      expect(columnsOf(ListingsView.list), 1);
      expect(columnsOf(ListingsView.grid), 2);
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
