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

/// Why the library exists, and the two shapes a page it describes can be served in.
///
/// This is the argument the repository is built on, so it is written on the page
/// rather than left to a `README` a visitor never opens: a search engine, a link
/// preview and a reader without JavaScript all see the same document, and the screen
/// in the app is not a second design of it.
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
            'A screen drawn in Flutter is a canvas. It is the right thing inside an '
            'app and the wrong thing for a page that has to be found: a search '
            'engine, a link preview and a reader without JavaScript all get an empty '
            'document. Writing that page a second time as HTML gets the page indexed '
            'and gives the team two designs to keep in step, which drift the week '
            'after they are written.',
            style: MaterialTypography.bodyLarge,
            color: palette.onSurfaceVariant,
          ),
          TextNode(
            'Unibox is the one description those two can share. A page that has to '
            'rank is written once as a tree; the export writes it as HTML and CSS, and '
            'the same tree draws the app\'s version of that screen. Nothing is designed '
            'twice, so nothing can disagree — and everything else in the application '
            'stays ordinary Flutter, screen for screen.',
            style: MaterialTypography.bodyLarge,
            color: palette.onSurfaceVariant,
          ),
        ],
      ),
      GridNode(
        minItemWidth: 320,
        // Three cards, three tracks: a fourth would stay empty and squeeze them.
        maxColumns: 3,
        gap: 24,
        children: <UINode>[
          _choice(
            title: 'Indexable, and static',
            body:
                'Server-rendered HTML and CSS with no JavaScript in it: what a '
                'crawler reads and what a reader without scripts keeps. The '
                'listings below are one.',
            href: 'web/listings/',
          ),
          _choice(
            title: 'Indexable, and live',
            body:
                'The same document plus one client bundle, which redraws the same '
                'tree into the same page: the dialog opens, the form validates, the '
                'ink spreads.',
            href: 'web/signup/',
          ),
          _choice(
            title: 'The app, from that tree',
            body:
                'The same screen compiled by Flutter. It is the app beside the page '
                'rather than a takeover of it: Flutter draws to a canvas, so it '
                'cannot adopt server-rendered HTML without repainting it.',
            href: 'flutter/listings/',
          ),
        ],
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
