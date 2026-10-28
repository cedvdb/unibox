import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import 'page.dart';
import 'theme.dart';

/// A plan on the pricing page: what it costs and what it is for.
final class Plan {
  /// Creates a plan.
  const Plan({
    required this.name,
    required this.price,
    required this.cadence,
    required this.pitch,
    required this.includes,
  });

  /// The name of the plan.
  final String name;

  /// The price a visitor reads first.
  final String price;

  /// What the price is per.
  final String cadence;

  /// One line about who the plan is for.
  final String pitch;

  /// What it includes, one line each.
  final List<String> includes;
}

/// The three plans, written once and drawn by both renderers.
const List<Plan> _plans = <Plan>[
  Plan(
    name: 'Solo',
    price: '€0',
    cadence: 'forever',
    pitch: 'One screen that has to rank, for a side project.',
    includes: <String>[
      'One page described as a tree',
      'Static HTML and CSS export',
      'Flutter and web renderers',
    ],
  ),
  Plan(
    name: 'Studio',
    price: '€12',
    cadence: 'per month',
    pitch: 'A team shipping marketing pages beside an app.',
    includes: <String>[
      'Every page is a tree',
      'The Material 3 package',
      'Conformance checks in CI',
      'One design, both targets',
    ],
  ),
  Plan(
    name: 'Agency',
    price: '€39',
    cadence: 'per month',
    pitch: 'Agencies that hand a client pages a crawler can read.',
    includes: <String>[
      'Everything in Studio',
      'A second design system',
      'Static export per route',
    ],
  ),
];

/// The questions a visitor asks before they buy, and their answers.
const List<(String, String)> _questions = <(String, String)>[
  (
    'What does a search engine see?',
    'The page as HTML and CSS, with the words, the headings and the links in it — '
        'not a canvas waiting for JavaScript. Run tool/seo_report.py on a build to '
        'see exactly what it reads.',
  ),
  (
    'Do I have to write the app this way?',
    'No. The screens that have to be found are trees; everything else stays the '
        'Flutter you already write.',
  ),
  (
    'What happens when the page has to react?',
    'The same document loads a client bundle that redraws the same tree into it: a '
        'dialog opens, a field validates. Without the bundle the page is still the '
        'page.',
  ),
  (
    'Does it work on a phone?',
    'The tree says how it folds — a grid gives up columns as the window narrows — '
        'and every page of this site fits a 375 pixel viewport.',
  ),
];

/// A pricing page: what it costs, why it exists, and what people ask.
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
      _plansSection(),
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
        'A page that has to be found, written once.',
        style: ExampleType.title,
        headingLevel: 1,
      ),
      TextNode(
        'Unibox describes a screen as one tree of nodes. It is exported as HTML and '
        'CSS for the crawlers and the readers without scripts, it becomes the app '
        'screen in Flutter, and the same document turns interactive where it has '
        'to be.',
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
                ink: ExamplePalette.surface,
                padding: const BoxSpacing.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: const TextNode('Start free'),
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

/// The three plans, side by side until the window cannot hold them.
UINode _plansSection() {
  return Box(
    width: double.infinity,
    gap: 16,
    children: <UINode>[
      TextNode('What it costs', style: ExampleType.title, headingLevel: 2),
      GridNode(
        minItemWidth: 260,
        maxColumns: 3,
        gap: 16,
        children: <UINode>[for (final Plan plan in _plans) _planCard(plan)],
      ),
    ],
  );
}

/// One plan: its price, who it is for, and what it includes.
UINode _planCard(Plan plan) {
  return Box(
    width: double.infinity,
    gap: 12,
    padding: const BoxSpacing.all(20),
    borderRadius: 16,
    backgroundColor: ExamplePalette.surface,
    border: const BoxBorder(color: ExamplePalette.border),
    children: <UINode>[
      TextNode(plan.name, style: ExampleType.navCurrent, headingLevel: 3),
      Box(
        direction: Axis.horizontal,
        crossAlign: CrossAlign.center,
        gap: 6,
        children: <UINode>[
          TextNode(plan.price, style: ExampleType.title),
          TextNode(plan.cadence, style: ExampleType.muted),
        ],
      ),
      TextNode(plan.pitch, style: ExampleType.body),
      Box(
        gap: 6,
        children: <UINode>[
          for (final String line in plan.includes)
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
        child: Box(
          onTap: () => onNavigate(ExamplePage.apartments),
          children: <UINode>[
            const TextNode('Go to the listings', style: ExampleType.nav),
          ],
        ),
      ),
    ],
  );
}
