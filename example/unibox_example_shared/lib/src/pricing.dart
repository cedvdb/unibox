import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import 'page.dart';
import 'theme.dart';

/// One band of the price page: what a home of this size costs, and what the rent
/// pays for.
final class RentBand {
  /// Creates a band.
  const RentBand({
    required this.name,
    required this.price,
    required this.cadence,
    required this.pitch,
    required this.includes,
  });

  /// The name of the band, which is the shape of the home.
  final String name;

  /// The price a visitor reads first.
  final String price;

  /// What the price is per.
  final String cadence;

  /// One line about who the home is for.
  final String pitch;

  /// What the rent includes, one line each.
  final List<String> includes;
}

/// The three bands, written once and drawn by both renderers.
const List<RentBand> _bands = <RentBand>[
  RentBand(
    name: 'Studio',
    price: '€780',
    cadence: 'per month',
    pitch: 'One room with a kitchen corner, for one person.',
    includes: <String>[
      'Water, heating and the upkeep of the building',
      'A bike store in the courtyard',
      'A visit inside two days',
    ],
  ),
  RentBand(
    name: 'Two rooms',
    price: '€1,180',
    cadence: 'per month',
    pitch: 'A bedroom and a living room, for a couple or a flatmate.',
    includes: <String>[
      'Everything the studio includes',
      'A cellar of your own',
      'A kitchen with a window',
    ],
  ),
  RentBand(
    name: 'Loft',
    price: '€1,650',
    cadence: 'per month',
    pitch: 'The top floor of the building, with the roof terrace.',
    includes: <String>[
      'Everything two rooms includes',
      'The terrace, shared with the neighbour below',
      'A parking space under the building',
    ],
  ),
];

/// The questions a visitor asks before a visit, and their answers.
const List<(String, String)> _questions = <(String, String)>[
  (
    'What is in the rent?',
    'Water, heating and the upkeep of the building. Electricity, internet and '
        'your own contents are not, and the lease lists both sides; the figure on '
        'this page is the one that leaves your account every month.',
  ),
  (
    'What does the deposit cover?',
    'Two months of rent, held in a blocked account and returned within a month of '
        'the keys coming back, less whatever the check-out report names.',
  ),
  (
    'How long does an application take?',
    'A visit, then a file with your identity and three payslips. The answer comes '
        'within five working days, and the homes go in the order the files are '
        'complete.',
  ),
  (
    'Can I bring a pet?',
    'Cats and small dogs are welcome. Say so at the visit, because the lease names '
        'the animals that live in the flat.',
  ),
];

/// The price page: what a home costs, what the rent covers, and what people ask.
///
/// It is the shape the library is meant for. Every section is a node tree, so the
/// page is served as HTML and CSS that a crawler reads, and the same tree is the
/// screen inside the app — the Flutter build of it is `/flutter/pricing/`.
///
/// [onStart] is the primary call to action: it opens the sign-up dialog, which is
/// page state and not a link, and [onNavigate] follows the secondary one to the
/// listings.
UINode buildPricingPage({
  required TapCallback onStart,
  required void Function(ExamplePage page) onNavigate,
}) {
  return Box(
    // A marketing page is longer than a window, so the page scrolls and the bar
    // above it does not: the scrolling box is the page itself, the same way the
    // listings page does it, and `Overflow.scroll` is what makes that true on both
    // targets.
    flex: 1,
    direction: Axis.vertical,
    width: double.infinity,
    overflow: Overflow.scroll,
    // The page is the `<main>` landmark, and it is the box that scrolls.
    semantics: const BoxSemantics(element: BoxElement.main),
    padding: const BoxSpacing.symmetric(horizontal: 32, vertical: 48),
    gap: 48,
    children: <UINode>[
      _hero(onStart: onStart),
      _bandsSection(),
      _questionsSection(),
      _footer(onNavigate: onNavigate),
    ],
  );
}

/// The first screen: the promise, and the two ways forward.
UINode _hero({required TapCallback onStart}) {
  return Box(
    width: double.infinity,
    maxWidth: 720,
    gap: 16,
    children: <UINode>[
      TextNode(
        'Rent in Brussels without the runaround.',
        style: ExampleType.title,
        headingLevel: 1,
      ),
      TextNode(
        'Six apartments, visited and measured before they are listed. The rent on '
        'the card is the rent on the lease, the map shows the street rather than '
        'the postcode, and an application is a form instead of a phone call.',
        style: ExampleType.body,
        color: ExamplePalette.muted,
      ),
      Box(
        direction: Axis.horizontal,
        crossAlign: CrossAlign.center,
        gap: 12,
        children: <UINode>[
          Box(
            borderRadius: 10,
            backgroundColor: ExamplePalette.accent,
            children: <UINode>[
              MaterialInkWell(
                onTap: onStart,
                borderRadius: 10,
                ink: ExamplePalette.panel,
                padding: const BoxSpacing.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: const TextNode('Create an account'),
              ),
            ],
          ),
          LinkNode(
            ExampleRoutes.listings,
            child: Box(
              padding: const BoxSpacing.symmetric(horizontal: 20, vertical: 12),
              borderRadius: 10,
              border: const BoxBorder(color: ExamplePalette.border),
              children: <UINode>[
                const TextNode('See the listings', style: ExampleType.muted),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

/// The three bands, side by side until the window cannot hold them.
UINode _bandsSection() {
  return Box(
    width: double.infinity,
    gap: 16,
    children: <UINode>[
      TextNode('What it costs', style: ExampleType.title, headingLevel: 2),
      GridNode(
        minItemWidth: 260,
        maxColumns: 3,
        gap: 16,
        children: <UINode>[for (final RentBand band in _bands) _bandCard(band)],
      ),
    ],
  );
}

/// One band: its rent, who the home is for, and what the rent includes.
UINode _bandCard(RentBand band) {
  return Box(
    width: double.infinity,
    gap: 12,
    padding: const BoxSpacing.all(20),
    borderRadius: 16,
    backgroundColor: ExamplePalette.panel,
    border: const BoxBorder(color: ExamplePalette.border),
    children: <UINode>[
      TextNode(band.name, style: ExampleType.navCurrent, headingLevel: 3),
      // The price over what it is per, rather than beside it: a row of two texts
      // is as wide as the two of them, and a card a third of a phone is narrower.
      Box(
        gap: 2,
        children: <UINode>[
          TextNode(band.price, style: ExampleType.title),
          TextNode(band.cadence, style: ExampleType.muted),
        ],
      ),
      TextNode(band.pitch, style: ExampleType.body),
      Box(
        gap: 6,
        children: <UINode>[
          for (final String line in band.includes)
            TextNode('- $line', style: ExampleType.muted),
        ],
      ),
    ],
  );
}

/// The questions, as a list of pairs: a question a heading, an answer the text
/// under it, because that is the outline a search engine and a screen reader both
/// read.
UINode _questionsSection() {
  return Box(
    width: double.infinity,
    maxWidth: 720,
    gap: 16,
    children: <UINode>[
      TextNode('Questions', style: ExampleType.title, headingLevel: 2),
      for (final (String question, String answer) in _questions)
        Box(
          gap: 4,
          children: <UINode>[
            TextNode(question, style: ExampleType.navCurrent, headingLevel: 3),
            TextNode(
              answer,
              style: ExampleType.body,
              color: ExamplePalette.muted,
            ),
          ],
        ),
    ],
  );
}

/// The last line of the page: a way to the rest of the example, and the reminder
/// that this page is not a special case.
UINode _footer({required void Function(ExamplePage page) onNavigate}) {
  return Box(
    width: double.infinity,
    maxWidth: 720,
    gap: 8,
    padding: const BoxSpacing.only(top: 16),
    // A border draws on all four sides, so the hairline above the footer is one
    // offset pixel of a shadow with no blur — the same tokens in both renderers.
    shadow: const BoxShadow(
      color: ExamplePalette.border,
      offsetY: -1,
      blurRadius: 0,
    ),
    children: <UINode>[
      TextNode(
        'This page is a node tree like every other screen of the example: it is '
        'served as HTML and CSS, and it is also the app screen at '
        '/flutter/pricing/.',
        style: ExampleType.muted,
      ),
      LinkNode(
        ExampleRoutes.listings,
        // The tree switches the page, so the browser does not load the document as
        // well: the href is for a reader without the runtime.
        onTap: () => onNavigate(ExamplePage.apartments),
        child: Box(
          children: <UINode>[
            const TextNode('Go to the listings', style: ExampleType.nav),
          ],
        ),
      ),
    ],
  );
}
