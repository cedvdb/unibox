import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import 'icons.dart';
import 'theme.dart';

/// A listing on the apartments page.
///
/// Plain data, like the signup form: the page is a function of the list, so a
/// host can hand it what it loaded from wherever it loads things from without
/// touching the tree.
final class Apartment {
  /// Creates a listing.
  const Apartment({
    required this.name,
    required this.district,
    required this.rooms,
    required this.area,
    required this.rent,
    required this.photo,
    required this.tags,
    this.badge,
  });

  /// The name of the building.
  final String name;

  /// The part of the city it stands in.
  final String district;

  /// How many rooms it has.
  final int rooms;

  /// The living area in square metres.
  final int area;

  /// The monthly rent in euro.
  final int rent;

  /// The photo the card shows, as an absolute url.
  ///
  /// A network photo is what a real listing page shows, and it is also the one
  /// piece of the card the model hands to the platform: an `ImageNode` with an url
  /// is a network request in Flutter and an `<img src>` on the page.
  final String photo;

  /// Two or three words about what the flat feels like.
  final String tags;

  /// What the badge in the corner of the card says: a rating, or `New`.
  final String? badge;

  /// The one line summary under the name.
  String get summary => '$rooms rooms · $area m²';

  /// The asking rent.
  String get priceLine => '€$rent';

  /// Where it is, the way a listing says it.
  String get locationLine => '$district · Brussels';
}

/// The listings the example shows.
///
/// More of them than fit on a normal window, which is the point: the page
/// scrolls under the navigation bar instead of growing the page.
const List<Apartment> exampleApartments = <Apartment>[
  Apartment(
    name: 'Via Bellavista 12',
    district: 'Saint-Gilles',
    rooms: 3,
    area: 84,
    rent: 1850,
    photo: 'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?auto=compress&cs=tinysrgb&w=640',
    tags: 'Bright, quiet street',
    badge: 'New',
  ),
  Apartment(
    name: 'Corso Umberto 4',
    district: 'Ixelles',
    rooms: 2,
    area: 61,
    rent: 1240,
    photo: 'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg?auto=compress&cs=tinysrgb&w=640',
    tags: 'Furnished, balcony',
    badge: '4.5',
  ),
  Apartment(
    name: 'Piazza della Scala 7',
    district: 'Centre',
    rooms: 1,
    area: 44,
    rent: 980,
    photo: 'https://images.pexels.com/photos/265087/pexels-photo-265087.jpeg?auto=compress&cs=tinysrgb&w=640',
    tags: 'Studio, near the station',
    badge: '4.8',
  ),
  Apartment(
    name: 'Vicolo del Forno 3',
    district: 'Anderlecht',
    rooms: 4,
    area: 112,
    rent: 2400,
    photo: 'https://images.pexels.com/photos/259588/pexels-photo-259588.jpeg?auto=compress&cs=tinysrgb&w=640',
    tags: 'Family, garden',
    badge: 'New',
  ),
  Apartment(
    name: 'Lungomare 21',
    district: 'Schaerbeek',
    rooms: 2,
    area: 70,
    rent: 1420,
    photo: 'https://images.pexels.com/photos/271619/pexels-photo-271619.jpeg?auto=compress&cs=tinysrgb&w=640',
    tags: 'Top floor, lift',
    badge: '4.2',
  ),
  Apartment(
    name: 'Salita San Marco 9',
    district: 'Forest',
    rooms: 3,
    area: 95,
    rent: 2100,
    photo: 'https://images.pexels.com/photos/1170412/pexels-photo-1170412.jpeg?auto=compress&cs=tinysrgb&w=640',
    tags: 'Renovated, terrace',
    badge: '4.9',
  ),
];

/// How a page of listings is drawn.
///
/// Two values and not a breakpoint: the segmented button above the listings picks one,
/// and the grid it feeds answers for the width on its own — one column is what a grid
/// with `maxColumns: 1` is, at any width.
/// The filter a listing row starts with.
///
/// It is here and not in the page state so that the page can be built on its own — the
/// state points at this value rather than the other way round.
const String defaultListingFilter = 'Two rooms';

enum ListingsView {
  /// One column: a row per listing.
  list,

  /// A reflowing grid, one or two across.
  grid,
}

/// The apartments page: a search bar, the filters, the listings and the map.
///
/// The page scrolls, the frame does not. The scrolling box is the page itself
/// and the bar above it belongs to the frame, so the navigation stays where it
/// is while the list moves — on both targets, from `Overflow.scroll`, which is
/// a `SingleChildScrollView` in Flutter and `overflow: auto` in CSS.
///
/// The padding sits on a box *inside* the scrolling one on purpose: Flutter puts
/// the padding of a scrolling box around its viewport (so it stays put), while
/// CSS puts it inside the scrollport (so it scrolls away). Moving it one level
/// in leaves both renderers scrolling the same content.
///
/// The map is a column beside the cards on a wide surface and a view of its own on
/// a narrow one: `visibleFrom` decides which of the two boxes is drawn, and
/// [mapOpen] — the page's own state — decides whether that view is open. Neither
/// is a second tree: the map is in the markup at every width.
Box buildApartmentsPage({
  bool mapOpen = false,
  TapCallback? onOpenMap,
  TapCallback? onCloseMap,
  String? filter = defaultListingFilter,
  ListingsView view = ListingsView.grid,
  void Function(String? filter)? onFilter,
  void Function(ListingsView view)? onView,
}) {
  return Box(
    flex: 1,
    direction: Axis.vertical,
    width: double.infinity,
    // The page is the `<main>` landmark; the stack below it is what a floating
    // control is placed against.
    semantics: const BoxSemantics(element: BoxElement.main),
    children: <UINode>[
      StackNode(
        width: double.infinity,
        height: double.infinity,
        children: <UINode>[
          // The list scrolls under the button rather than with it.
          Box(
            width: double.infinity,
            height: double.infinity,
            direction: Axis.vertical,
            overflow: Overflow.scroll,
            children: <UINode>[
              _content(
                mapOpen: mapOpen,
                onOpenMap: onOpenMap,
                onCloseMap: onCloseMap,
                filter: filter,
                view: view,
                onFilter: onFilter,
                onView: onView,
              ),
            ],
          ),
          PositionedNode(
            alignment: BoxAlignment.bottomCenter,
            child: _mapButton(onOpenMap),
          ),
        ],
      ),
      // The opened map is an overlay over the whole page, so it sits beside the
      // stack rather than inside the box that scrolls.
      if (mapOpen)
        OverlayNode(
          onDismiss: onCloseMap,
          barrierColor: const BoxColor(0x66000000),
          child: Box(
            width: double.infinity,
            height: double.infinity,
            padding: const BoxSpacing.all(16),
            children: <UINode>[_map()],
          ),
        ),
    ],
  );
}

/// Everything the page holds, in the box that scrolls.
Box _content({
  required bool mapOpen,
  required TapCallback? onOpenMap,
  required TapCallback? onCloseMap,
  required String? filter,
  required ListingsView view,
  required void Function(String? filter)? onFilter,
  required void Function(ListingsView view)? onView,
}) {
  return Box(
    direction: Axis.vertical,
    width: double.infinity,
    padding: const BoxSpacing.all(20),
    gap: 16,
    textStyle: ExampleType.body,
    children: <UINode>[
      _heading(),
      _searchBar(),
      _filters(
        filter: filter,
        onFilter: onFilter,
        onOpenMap: onOpenMap,
        view: view,
        onView: onView,
      ),
      Box(
        direction: Axis.horizontal,
        width: double.infinity,
        gap: 16,
        crossAlign: CrossAlign.start,
        children: <UINode>[
          Box(
            flex: 3,
            direction: Axis.vertical,
            gap: 12,
            children: <UINode>[
              _resultLine(),
              // The cards reflow on their own: one column when the column is
              // narrow, two once it can hold them, and the tracks share the
              // width. The count comes from the model's arithmetic on the web
              // as well as in Flutter, so neither target needs a breakpoint.
              GridNode(
                minItemWidth: 240,
                maxColumns: view == ListingsView.list ? 1 : 2,
                gap: 12,
                children: <UINode>[
                  for (final Apartment apartment in exampleApartments)
                    _card(apartment),
                ],
              ),
            ],
          ),
          Box(
            flex: 2,
            direction: Axis.vertical,
            // The map is drawn beside the listings only on a wide surface.
            visibleFrom: 900,
            children: <UINode>[_map()],
          ),
        ],
      ),
    ],
  );
}

/// The title of the page and the line under it.
///
/// The title is marked as a heading, which is what a screen reader announces and
/// what a crawler uses to read the structure of the page: the web renderer writes
/// `role="heading"` and the Flutter one a `Semantics.header`.
UINode _heading() {
  return TextNode('Apartments', headingLevel: 1, style: ExampleType.title);
}

/// The search bar: a rounded field with a drawn magnifier.
///
/// The magnifier is two boxes and a transform rather than an icon font, so the
/// example ships no asset for it and both targets draw the same shape.
UINode _searchBar() {
  return Box(
    width: double.infinity,
    minHeight: 52,
    direction: Axis.horizontal,
    crossAlign: CrossAlign.center,
    gap: 12,
    padding: const BoxSpacing.symmetric(horizontal: 18, vertical: 12),
    borderRadius: 26,
    border: const BoxBorder(color: BoxColor.role(MaterialColorRole.outline)),
    backgroundColor: const BoxColor.role(MaterialColorRole.surface),
    children: <UINode>[
      _magnifier(),
      Box(
        flex: 1,
        children: <UINode>[
          TextNode(
            'Brussels · two rooms · under €2 000',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MaterialTypography.bodyLarge.merge(
              BoxTextStyle(
                color: const BoxColor.role(MaterialColorRole.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// A magnifier drawn from two boxes: a ring and a handle at forty-five degrees.
UINode _magnifier() {
  return StackNode(
    children: <UINode>[
      Box(
        width: 12,
        height: 12,
        borderRadius: 999,
        border: const BoxBorder(
          width: 2,
          color: BoxColor.role(MaterialColorRole.onSurfaceVariant),
        ),
      ),
      PositionedNode(
        left: 11,
        top: 11,
        child: Box(
          width: 6,
          height: 2,
          backgroundColor: const BoxColor.role(
            MaterialColorRole.onSurfaceVariant,
          ),
          transform: const BoxTransform(rotation: 45),
        ),
      ),
    ],
  );
}

/// The filters, and how the listings are drawn beside them.
///
/// One row and not two: the chips and the layout switch are the same decision — what the
/// page shows and how it shows it — and a row that spans the page is also the box the
/// width tokens are measured against, so the switch and the two chips a narrow surface
/// cannot hold disappear at the same threshold they always did.
UINode _filters({
  required String? filter,
  required void Function(String? filter)? onFilter,
  required TapCallback? onOpenMap,
  required ListingsView view,
  required void Function(ListingsView view)? onView,
}) {
  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.center,
    mainAlign: MainAlign.spaceBetween,
    gap: 12,
    width: double.infinity,
    children: <UINode>[
      Box(
        flex: 1,
        direction: Axis.horizontal,
        crossAlign: CrossAlign.center,
        gap: 8,
        children: <UINode>[
          _filterChip('Two rooms', filter: filter, onFilter: onFilter),
          _filterChip('Studio', filter: filter, onFilter: onFilter),
          Box(
            visibleFrom: 900,
            children: <UINode>[
              _filterChip('With a garden', filter: filter, onFilter: onFilter),
            ],
          ),
          Box(
            // The toggle to the map view, where the map is not already beside it.
            visibleUntil: 900,
            children: <UINode>[_mapChip(onOpenMap)],
          ),
        ],
      ),
      Box(
        // Below this the row is the chips' and the switch leaves rather than squeeze
        // them: a segmented button has a width, and a width it cannot have is a control
        // that looks broken.
        visibleFrom: 560,
        children: <UINode>[
          MaterialSegmentedButton(
            width: 216,
            segments: <MaterialSegment>[
              MaterialSegment(
                label: const TextNode('List'),
                icon: glyphList(
                  const BoxColor.role(MaterialColorRole.onSurfaceVariant),
                ),
                semanticsLabel: 'As a list',
              ),
              MaterialSegment(
                label: const TextNode('Grid'),
                icon: glyphGrid(
                  const BoxColor.role(MaterialColorRole.onSurfaceVariant),
                ),
                semanticsLabel: 'As a grid',
              ),
            ],
            selected: view == ListingsView.list ? 0 : 1,
            onSelect: (int index) => onView?.call(
              index == 0 ? ListingsView.list : ListingsView.grid,
            ),
          ),
        ],
      ),
    ],
  );
}

/// The floating Map button: the map's way in where it is not already beside the
/// listing.
///
/// It is a `PositionedNode` with an alignment and a margin rather than offsets, so
/// it stays at the bottom centre of the page whatever the window is — and only
/// where the map has no column of its own.
UINode _mapButton(TapCallback? onOpenMap) {
  return Box(
    visibleUntil: 900,
    margin: const BoxSpacing.only(bottom: 24),
    shadow: MaterialElevation.level3,
    borderRadius: 16,
    backgroundColor: const BoxColor.role(MaterialColorRole.primaryContainer),
    children: <UINode>[
      MaterialInkWell(
        onTap: onOpenMap ?? () {},
        borderRadius: 16,
        ink: const BoxColor.role(MaterialColorRole.onPrimaryContainer),
        padding: const BoxSpacing.symmetric(horizontal: 20, vertical: 14),
        semantics: const BoxSemantics(
          role: BoxRole.button,
          label: 'Open the map',
        ),
        child: TextNode(
          'Map',
          style: MaterialTypography.labelLarge.merge(
            BoxTextStyle(
              color: const BoxColor.role(MaterialColorRole.onPrimaryContainer),
            ),
          ),
        ),
      ),
    ],
  );
}

/// The line above the listings: how many there are.
UINode _resultLine() {
  return TextNode(
    '${exampleApartments.length} apartments in Brussels',
    style: ExampleType.muted,
  );
}

/// One filter: chosen, it shows a check in front and a cross that clears it.
///
/// That is Material's filter chip: the check says what is on, the cross says it can be
/// turned off, and both are drawn glyphs rather than a font this example does not ship.
UINode _filterChip(
  String label, {
  required String? filter,
  required void Function(String? filter)? onFilter,
}) {
  final bool selected = filter == label;
  const BoxColor onSelected = BoxColor.role(
    MaterialColorRole.onSecondaryContainer,
  );

  return MaterialChip(
    label: TextNode(label),
    selected: selected,
    leading: selected ? glyphCheck(onSelected, size: 12) : null,
    trailing: selected ? glyphClose(onSelected) : null,
    onRemove: selected ? () => onFilter?.call(null) : null,
    onTap: () => onFilter?.call(selected ? null : label),
  );
}

/// The toggle to the map, where the map has no column of its own.
///
/// A chip with a pin in front: it opens a view rather than choosing a filter, which is
/// why it carries no `selected` and no cross.
UINode _mapChip(TapCallback? onOpenMap) {
  return MaterialChip(
    label: const TextNode('Map'),
    leading: glyphPin(const BoxColor.role(MaterialColorRole.onSurfaceVariant)),
    onTap: onOpenMap ?? () {},
  );
}

/// One listing: a photo, the name, where it is, what it feels like and the rent.
///
/// The card is a `MaterialCard` — a `Box` with Material's surface, radius,
/// elevation and body type — so the example shows the design system as well as the
/// model. Its width is the grid's track and its height is its content; the grid
/// top-aligns the cards of a row, so a shorter card does not stretch.
UINode _card(Apartment apartment) {
  return MaterialCard(
    semantics: const BoxSemantics(element: BoxElement.article),
    padding: const BoxSpacing.all(0),
    direction: Axis.vertical,
    gap: 0,
    overflow: Overflow.hidden,
    children: <UINode>[
      Box(
        width: double.infinity,
        height: 150,
        children: <UINode>[
          ImageNode(
            apartment.photo,
            alt: 'A room in ${apartment.name}',
            width: double.infinity,
            height: 150,
            fit: ImageFit.cover,
          ),
        ],
      ),
      Box(
        direction: Axis.vertical,
        gap: 6,
        crossAlign: CrossAlign.stretch,
        padding: const BoxSpacing.all(14),
        children: <UINode>[
          Box(
            direction: Axis.horizontal,
            width: double.infinity,
            mainAlign: MainAlign.spaceBetween,
            children: <UINode>[
              TextNode(
                apartment.name,
                style: MaterialTypography.titleMedium.merge(
                  BoxTextStyle(
                    color: const BoxColor.role(MaterialColorRole.onSurface),
                  ),
                ),
              ),
              if (apartment.badge != null)
                TextNode(
                  apartment.badge!,
                  style: MaterialTypography.labelMedium.merge(
                    BoxTextStyle(
                      color: const BoxColor.role(MaterialColorRole.primary),
                    ),
                  ),
                ),
            ],
          ),
          TextNode(
            apartment.locationLine,
            style: MaterialTypography.bodyMedium.merge(
              BoxTextStyle(
                color: const BoxColor.role(MaterialColorRole.onSurfaceVariant),
              ),
            ),
          ),
          TextNode(
            apartment.tags,
            style: MaterialTypography.bodySmall.merge(
              BoxTextStyle(
                color: const BoxColor.role(MaterialColorRole.onSurfaceVariant),
              ),
            ),
          ),
          Box(
            direction: Axis.horizontal,
            width: double.infinity,
            mainAlign: MainAlign.spaceBetween,
            crossAlign: CrossAlign.center,
            children: <UINode>[
              TextNode(
                apartment.summary,
                style: MaterialTypography.labelMedium.merge(
                  BoxTextStyle(
                    color: const BoxColor.role(
                      MaterialColorRole.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              TextNode(
                apartment.priceLine,
                style: MaterialTypography.labelLarge.merge(
                  BoxTextStyle(
                    color: const BoxColor.role(MaterialColorRole.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// The map: a rounded panel with roads, districts and the price of three flats.
///
/// It is drawn from nodes rather than embedded, which is the honest thing for an
/// example: a real map is a third-party embed, and this one shows the shape of a
/// map — a surface, a few roads as thin rotated boxes, district names and price
/// pins place by place — without a key, a script or a network call.
UINode _map() {
  const BoxColor plot = BoxColor(0xFFE7EFE4);

  return Box(
    width: double.infinity,
    minHeight: 420,
    borderRadius: 16,
    border: const BoxBorder(
      color: BoxColor.role(MaterialColorRole.outlineVariant),
    ),
    overflow: Overflow.hidden,
    backgroundColor: const BoxColor.role(MaterialColorRole.surfaceContainerLow),
    children: <UINode>[
      StackNode(
        children: <UINode>[
          // The sizer: a stack of positioned children has no size of its own, and a
          // `Stack` needs a bounded one. This child is the map's area; everything
          // else is placed over it.
          Box(width: double.infinity, height: 420),
          // Two parks and three roads: enough to read as a map, and all of it a box.
          PositionedNode(
            left: 40,
            top: 60,
            child: Box(
              width: 130,
              height: 90,
              borderRadius: 12,
              backgroundColor: plot,
            ),
          ),
          PositionedNode(
            left: 250,
            top: 240,
            child: Box(
              width: 110,
              height: 70,
              borderRadius: 12,
              backgroundColor: plot,
            ),
          ),
          PositionedNode(
            left: -40,
            top: 150,
            child: Box(
              width: 520,
              height: 6,
              backgroundColor: const BoxColor.role(
                MaterialColorRole.surfaceContainerHighest,
              ),
              transform: const BoxTransform(rotation: -14),
            ),
          ),
          PositionedNode(
            left: 120,
            top: 320,
            child: Box(
              width: 420,
              height: 6,
              backgroundColor: const BoxColor.role(
                MaterialColorRole.surfaceContainerHighest,
              ),
              transform: const BoxTransform(rotation: 9),
            ),
          ),
          PositionedNode(
            left: 300,
            top: -30,
            child: Box(
              width: 6,
              height: 470,
              backgroundColor: const BoxColor.role(
                MaterialColorRole.surfaceContainerHighest,
              ),
              transform: const BoxTransform(rotation: 6),
            ),
          ),
          // The districts, the way a map names them.
          _mapLabel('Saint-Gilles', left: 24, top: 24),
          _mapLabel('Ixelles', left: 210, top: 120),
          _mapLabel('Centre', left: 40, top: 250),
          _mapLabel('Forest', left: 190, top: 360),
          // What the flats cost, pinned where they are.
          _pricePin('€1850', left: 96, top: 92),
          _pricePin('€1240', left: 232, top: 208),
          _pricePin('€980', left: 60, top: 300),
        ],
      ),
    ],
  );
}

/// A district name on the map.
UINode _mapLabel(String name, {required double left, required double top}) {
  return PositionedNode(
    left: left,
    top: top,
    child: TextNode(
      name,
      style: MaterialTypography.labelSmall.merge(
        BoxTextStyle(
          color: const BoxColor.role(MaterialColorRole.onSurfaceVariant),
        ),
      ),
    ),
  );
}

/// A price pinned on the map: the one shape Material gives a pin.
UINode _pricePin(String price, {required double left, required double top}) {
  return PositionedNode(
    left: left,
    top: top,
    child: Box(
      borderRadius: 999,
      padding: const BoxSpacing.symmetric(horizontal: 12, vertical: 6),
      backgroundColor: const BoxColor.role(MaterialColorRole.primary),
      textStyle: MaterialTypography.labelLarge.merge(
        BoxTextStyle(color: const BoxColor.role(MaterialColorRole.onPrimary)),
      ),
      children: <UINode>[TextNode(price)],
    ),
  );
}
