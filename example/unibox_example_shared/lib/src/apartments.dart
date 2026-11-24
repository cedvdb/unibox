import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// A listing on the apartments page.
///
/// Hosts supply this data to the listing region after loading or filtering it.
final class Apartment {
  /// Creates a listing.
  const Apartment({
    required this.name,
    required this.district,
    required this.city,
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

  /// The capital it stands in.
  ///
  /// A site that only ever shows one city is a site about that city, so the list spans
  /// six capitals and the city is data like the district: the lines that count them are
  /// computed from this field rather than written into a sentence.
  final String city;

  /// How many rooms it has.
  final int rooms;

  /// The living area in square metres.
  final int area;

  /// The monthly rent in euro.
  final int rent;

  /// The photo the card shows, as the name of a bundled file: `apartment-1.jpg`.
  ///
  /// Bundled rather than fetched from a photo host, and that is a decision about this example rather
  /// than about the model: a remote image makes the page's largest paint a third party's latency, and
  /// a page whose number belongs to somebody else's server cannot be held to a budget. Six thumbnails
  /// are 152 kB, all of them local.
  ///
  /// The name is a file, not a path: where that file sits is the host's fact, because a document two
  /// directories deep and an application's asset bundle reach the same file from different places.
  final String photo;

  /// Two or three words about what the flat feels like.
  final String tags;

  /// What the badge in the corner of the card says: a rating, or `New`.
  final String? badge;

  /// The one line summary under the name.
  String get summary => '$rooms ${rooms == 1 ? 'room' : 'rooms'} · $area m²';

  /// The asking rent.
  String get priceLine => '€$rent';

  /// Where it is, the way a listing says it.
  String get locationLine => '$district · $city';
}

const List<Apartment> exampleApartments = <Apartment>[
  Apartment(
    name: 'Rue de Turenne 12',
    district: 'Le Marais',
    city: 'Paris',
    rooms: 3,
    area: 84,
    rent: 1850,
    photo: 'apartment-1.jpg',
    tags: 'Bright, quiet street',
    badge: 'New',
  ),
  Apartment(
    name: 'Oranienstraße 4',
    district: 'Kreuzberg',
    city: 'Berlin',
    rooms: 2,
    area: 61,
    rent: 1240,
    photo: 'apartment-2.jpg',
    tags: 'Furnished, balcony',
    badge: '4.5',
  ),
  Apartment(
    name: 'Rua da Bica 7',
    district: 'Alfama',
    city: 'Lisbon',
    rooms: 1,
    area: 44,
    rent: 980,
    photo: 'apartment-3.jpg',
    tags: 'Studio, near the station',
    badge: '4.8',
  ),
  Apartment(
    name: 'Kirchengasse 3',
    district: 'Neubau',
    city: 'Vienna',
    rooms: 4,
    area: 112,
    rent: 2400,
    photo: 'apartment-4.jpg',
    tags: 'Family, garden',
    badge: 'New',
  ),
  Apartment(
    name: 'Calle de la Palma 9',
    district: 'Malasaña',
    city: 'Madrid',
    rooms: 2,
    area: 70,
    rent: 1420,
    photo: 'apartment-5.jpg',
    tags: 'Top floor, lift',
    badge: '4.2',
  ),
  Apartment(
    name: 'Via della Scala 7',
    district: 'Trastevere',
    city: 'Rome',
    rooms: 3,
    area: 95,
    rent: 2100,
    photo: 'apartment-6.jpg',
    tags: 'Renovated, terrace',
    badge: '4.9',
  ),
];

/// A shared listing region; the host supplies data and action callbacks.
UINode buildListingRegion({
  List<Apartment> apartments = exampleApartments,
  String photoPrefix = '',
  TapCallback? onSave,
}) => Box(
  width: double.infinity,
  gap: 24,
  children: <UINode>[
    TextNode(
      '${apartments.length} ${apartments.length == 1 ? 'home' : 'homes'} across Europe',
      headingLevel: 2,
      style: MaterialTypography.headlineSmall,
    ),
    if (apartments.isEmpty)
      const TextNode('No homes match your search. Try another city.'),
    GridNode(
      minItemWidth: 280,
      maxColumns: 2,
      gap: 16,
      children: <UINode>[
        for (final Apartment apartment in apartments)
          buildApartmentCard(
            apartment,
            photoPrefix: photoPrefix,
            ahead: apartment == apartments.first,
          ),
      ],
    ),
    if (onSave != null)
      MaterialButton(
        key: 'listing-save',
        label: const TextNode('Save these homes'),
        onTap: onSave,
      ),
    const LinkNode(
      'https://github.com/cedvdb/unibox',
      children: <UINode>[TextNode('Source')],
    ),
  ],
);

/// The exact same example declaration used by the HTML and Flutter renderers.
///
/// Only asset locations and the host callback differ between targets. Layout,
/// typography, content and action keys are declared here once.
UINode buildListingExample({
  String photoPrefix = '',
  required TapCallback onSave,
}) => Box(
  width: double.infinity,
  backgroundColor: const BoxColor.role(MaterialColorRole.surface),
  textStyle: MaterialTypography.bodyMedium.copyWith(
    fontFamily: 'UniboxText',
    color: const BoxColor.role(MaterialColorRole.onSurface),
  ),
  crossAlign: CrossAlign.center,
  padding: const BoxSpacing.all(24),
  children: <UINode>[
    Box(
      width: double.infinity,
      maxWidth: 912,
      gap: 24,
      semantics: const BoxSemantics(element: BoxElement.main),
      children: <UINode>[
        const TextNode(
          'Find your next home',
          headingLevel: 1,
          style: MaterialTypography.headlineMedium,
        ),
        buildListingRegion(photoPrefix: photoPrefix, onSave: onSave),
      ],
    ),
  ],
);

/// A shared content card, with a real photograph and no application state.
UINode buildApartmentCard(
  Apartment apartment, {
  String photoPrefix = '',
  bool ahead = false,
}) {
  return MaterialCard(
    semantics: const BoxSemantics(element: BoxElement.article),
    direction: Axis.vertical,
    gap: 0,
    overflow: Overflow.hidden,
    children: <UINode>[
      Box(
        width: double.infinity,
        height: 150,
        children: <UINode>[
          ImageNode(
            '${photoPrefix}assets/photos/${apartment.photo}',
            alt: 'A room in ${apartment.name}',
            fetchPriority: ahead
                ? ImageFetchPriority.high
                : ImageFetchPriority.auto,
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
                headingLevel: 3,
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
