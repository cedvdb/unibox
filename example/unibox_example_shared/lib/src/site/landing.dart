import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The front page: why the library exists, and the ways into it.
///
/// The page answers the question a visitor arrives with — "what is this for?" — before
/// it shows anything. The answer is a search one: a screen drawn in Flutter is a canvas
/// that a crawler cannot read and a screen written again as HTML is a second design to
/// keep in step, so a page that has to rank is written once here and drawn by both.
///
/// Both sections are [GridNode]s: the hero and the cards fold from two columns to one
/// as the window narrows, without a breakpoint written into the tree. A page about a
/// mobile web cannot be one that overflows a phone.
UINode buildLanding() {
  const MaterialPalette palette = MaterialPalette.light;

  return Box(
    width: double.infinity,
    padding: const BoxSpacing.symmetric(horizontal: 32, vertical: 64),
    gap: 56,
    children: <UINode>[
      GridNode(
        minItemWidth: 420,
        // Two children, two tracks: `auto-fill` would open a third empty one on a
        // wide screen and leave the hero two thirds as wide as the page.
        maxColumns: 2,
        gap: 48,
        children: <UINode>[
          Box(
            gap: 16,
            children: <UINode>[
              TextNode(
                'Describe a screen once.',
                style: MaterialTypography.displayMedium,
                headingLevel: 1,
              ),
              TextNode(
                'Unibox is one immutable tree of nodes — boxes, text, images, links, '
                'stacks, fields, overlays — drawn by two renderers from that single '
                'description: Flutter widgets in an application, and HTML with CSS in '
                'a browser. They agree because one table of expected appearance holds '
                'both renderer suites to the same answer.',
                style: MaterialTypography.bodyLarge,
                color: palette.onSurfaceVariant,
              ),
              TextNode(
                'The tree is pure Dart with no dependencies. Layout, spacing, colours, '
                'typography and the accessibility tree are written once, state lives '
                'in a store the tree owns, and a design system is a package of values '
                'and nodes rather than a renderer — which is what unibox_material is.',
                style: MaterialTypography.bodyLarge,
                color: palette.onSurfaceVariant,
              ),
            ],
          ),
          Box(
            maxWidth: 480,
            gap: 8,
            children: <UINode>[
              ImageNode(
                'assets/hero-compact.svg',
                // A grid decides its row height from its tallest slot, so the
                // figure states one: the two targets then reserve the same space
                // while the columns change.
                height: 300,
                alt:
                    'One node tree splits into a Flutter panel drawing it through '
                    'tree.toWidget() and a Jaspr panel drawing it through '
                    'tree.toComponent(); both panels show the same card.',
                width: double.infinity,
              ),
              TextNode(
                'The figure is a node tree too: this site is drawn with the library '
                'it documents.',
                style: MaterialTypography.labelSmall.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      _why(palette),
      Box(
        gap: 16,
        children: <UINode>[
          TextNode(
            'Where to go',
            style: MaterialTypography.titleLarge,
            headingLevel: 2,
          ),
          GridNode(
            minItemWidth: 320,
            maxColumns: 2,
            gap: 24,
            children: <UINode>[
              _choice(
                title: 'The Material library',
                body:
                    'The fifteen type roles, the colour roles and six components, '
                    'typeset and painted by the same node tree.',
                href: 'material/',
              ),
              _choice(
                title: 'The same tree, drawn twice',
                body:
                    'The example page rendered by Jaspr on the left and Flutter on '
                    'the right. Resize the window: both answer the same breakpoint.',
                href: 'showcase/',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Why the library exists, and the two ways to serve a page written this way.
///
/// This is the argument the repository is built on, so it is written on the page
/// rather than left to a `README` a visitor never opens: a search engine, a link
/// preview and a reader without JavaScript all see the same empty document in a
/// Flutter screen, and writing that page again is how a team ends up with two designs
/// that drift. The two strategies are the choice that removes the second design.
UINode _why(MaterialPalette palette) {
  return Box(
    gap: 16,
    children: <UINode>[
      TextNode(
        'Why this exists',
        style: MaterialTypography.headlineMedium,
        headingLevel: 2,
      ),
      Box(
        maxWidth: 760,
        gap: 16,
        children: <UINode>[
          TextNode(
            'A search engine, a link preview and a reader without JavaScript all get '
            'the same thing from a Flutter screen: nothing. Flutter draws into a '
            'canvas, so there is no text to index. Writing the page again as HTML '
            'fixes that and leaves a team with two designs to keep in step.',
            style: MaterialTypography.bodyLarge,
            color: palette.onSurfaceVariant,
          ),
          TextNode(
            'Unibox removes the second design. The screen is written once as a tree, '
            'and you choose how to serve it.',
            style: MaterialTypography.bodyLarge,
            color: palette.onSurface,
          ),
        ],
      ),
      GridNode(
        minItemWidth: 320,
        maxColumns: 2,
        gap: 24,
        children: <UINode>[
          _strategy(
            title: 'Strategy 1: the Flutter app takes over',
            body:
                'The server renders the screen as a read-only page — the text, the '
                'headings and the links are in the HTML. Flutter then takes the page '
                'over and draws the same screen from the same tree, so a visitor gets '
                'one screen rather than two versions of it. The handover is a '
                'repaint, so expect a brief flash.',
            link: 'Flutter, drawing that tree',
            href: 'flutter/listings/',
          ),
          _strategy(
            title: 'Strategy 2: Jaspr serves the page',
            body:
                'The same tree is exported as HTML and CSS and made interactive by '
                'one small bundle. No Flutter on that page at all: a phone downloads '
                'a page and a script instead of an application, and what the crawler '
                'reads and what the visitor uses are the same document.',
            link: 'The pricing page, served this way',
            href: 'web/pricing/',
          ),
        ],
      ),
      Box(
        maxWidth: 760,
        gap: 12,
        children: <UINode>[
          TextNode(
            'The difference is measurable: a crawler reads 132 words, a single h1 and '
            'three links on the listings page of this site, and 4 words in the Flutter '
            'build of the same screen.',
            style: MaterialTypography.bodyLarge,
            color: palette.onSurfaceVariant,
          ),
          TextNode(
            'Only the pages that have to be found need either strategy. Everything '
            'else stays ordinary Flutter, screen for screen.',
            style: MaterialTypography.bodyLarge,
            color: palette.onSurfaceVariant,
          ),
        ],
      ),
    ],
  );
}

/// One of the two ways to serve a page: a heading, what it means, and a link to a
/// page served that way.
UINode _strategy({
  required String title,
  required String body,
  required String link,
  required String href,
}) {
  return Box(
    gap: 8,
    padding: const BoxSpacing.all(20),
    borderRadius: 12,
    border: const BoxBorder(
      color: BoxColor.role(MaterialColorRole.outlineVariant),
    ),
    children: <UINode>[
      TextNode(title, style: MaterialTypography.titleLarge, headingLevel: 3),
      TextNode(
        body,
        style: MaterialTypography.bodyMedium.copyWith(
          color: const BoxColor.role(MaterialColorRole.onSurfaceVariant),
        ),
      ),
      LinkNode(
        href,
        child: Box(
          children: <UINode>[
            TextNode(
              link,
              style: MaterialTypography.labelLarge.copyWith(
                color: const BoxColor.role(MaterialColorRole.primary),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// One way in: a bordered card that is a link and tints under the pointer.
///
/// The tint is a state layer inside the border, not around it, because a layer
/// paints *above* the surface it belongs to: wrapped the other way round, the
/// card's own background would cover it. The card fills the slot it is given, so a
/// [GridNode] decides how many fit and the page folds to one column on a phone.
UINode _choice({
  required String title,
  required String body,
  required String href,
}) {
  return LinkNode(
    href,
    child: Box(
      width: double.infinity,
      borderRadius: 12,
      border: const BoxBorder(
        color: BoxColor.role(MaterialColorRole.outlineVariant),
      ),
      children: <UINode>[
        Box(
          borderRadius: 12,
          padding: const BoxSpacing.all(20),
          transition: const BoxTransition(
            duration: Duration(milliseconds: 100),
          ),
          stateStyles: const <BoxState, BoxStyle>{
            BoxState.hover: BoxStyle(
              backgroundColor: BoxColor.role(MaterialColorRole.hoverLayer),
            ),
          },
          children: <UINode>[
            Box(
              gap: 8,
              children: <UINode>[
                TextNode(title, style: MaterialTypography.titleLarge),
                TextNode(
                  body,
                  style: MaterialTypography.bodyMedium.copyWith(
                    color: const BoxColor.role(
                      MaterialColorRole.onSurfaceVariant,
                    ),
                  ),
                ),
                TextNode(
                  href,
                  style: MaterialTypography.labelSmall.copyWith(
                    color: const BoxColor.role(MaterialColorRole.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
