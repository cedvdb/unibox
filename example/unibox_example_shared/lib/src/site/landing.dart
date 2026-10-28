import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The front page: one promise, three lines about how it is kept, and the numbers.
///
/// It is a sales page, so it does one thing: say what the library is for, show the
/// evidence, and offer the two places to look. The catalogue and the comparison live
/// in the bar, where a reader who wants them will go looking.
UINode buildLanding() {
  const MaterialPalette palette = MaterialPalette.light;

  return Box(
    width: double.infinity,
    direction: Axis.horizontal,
    mainAlign: MainAlign.center,
    children: <UINode>[
      Box(
        width: double.infinity,
        maxWidth: 1080,
        padding: const BoxSpacing.symmetric(horizontal: 32, vertical: 64),
        gap: 72,
        children: <UINode>[
          _hero(palette),
          _promises(palette),
          _evidence(palette),
        ],
      ),
    ],
  );
}

/// The claim, the two things to click, and the figure.
UINode _hero(MaterialPalette palette) {
  return GridNode(
    minItemWidth: 380,
    maxColumns: 2,
    gap: 48,
    children: <UINode>[
      Box(
        gap: 20,
        children: <UINode>[
          TextNode(
            'Describe a screen once.',
            style: MaterialTypography.displayMedium,
            headingLevel: 1,
          ),
          TextNode(
            'The page a search engine reads and the screen in your Flutter app come '
            'from the same Dart tree, so there is no second design to keep in step. '
            'Serve the web version on its own, or let the app take the page over.',
            style: MaterialTypography.titleMedium.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
          Box(
            direction: Axis.horizontal,
            crossAlign: CrossAlign.center,
            gap: 12,
            children: <UINode>[
              LinkNode(
                'web/pricing/',
                child: MaterialButton.filled(
                  label: const TextNode('See a page it serves'),
                  onTap: () {},
                ),
              ),
              LinkNode(
                'flutter/listings/',
                child: MaterialButton.text(
                  label: const TextNode('The same screen in Flutter'),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
      Box(
        maxWidth: 480,
        gap: 8,
        children: <UINode>[
          ImageNode(
            'assets/hero-compact.svg',
            alt:
                'One node tree splitting into a Flutter panel and a browser panel that '
                'show the same card.',
            width: double.infinity,
            height: 260,
          ),
          TextNode(
            'This page is drawn with the library it is selling.',
            style: MaterialTypography.labelSmall.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Three lines, no cards: what you write, what draws it, and what stops the two from
/// drifting apart.
UINode _promises(MaterialPalette palette) {
  return GridNode(
    minItemWidth: 220,
    maxColumns: 3,
    gap: 32,
    children: <UINode>[
      _promise(
        'One description',
        'Boxes, text, images, links, stacks, fields and overlays, written once in '
            'plain Dart with no dependencies.',
      ),
      _promise(
        'Two renderers',
        'Flutter widgets in the app, HTML and CSS on the web — the same tree, drawn '
            'by each target with what it already has.',
      ),
      _promise(
        'Held together',
        'One table of expected appearance, and both renderer suites measured '
            'against it, so the two cannot quietly disagree.',
      ),
    ],
  );
}

/// One of the three promises.
UINode _promise(String title, String body) {
  return Box(
    gap: 6,
    children: <UINode>[
      TextNode(title, style: MaterialTypography.titleMedium, headingLevel: 2),
      TextNode(
        body,
        style: MaterialTypography.bodyMedium.copyWith(
          color: const BoxColor.role(MaterialColorRole.onSurfaceVariant),
        ),
      ),
    ],
  );
}

/// The numbers, because a claim about search is worth exactly as much as the document
/// a crawler gets. `tool/seo_report.py` prints them.
UINode _evidence(MaterialPalette palette) {
  return Box(
    maxWidth: 760,
    gap: 12,
    padding: const BoxSpacing.only(top: 24),
    shadow: BoxShadow(
      color: palette.outlineVariant,
      offsetY: -1,
      blurRadius: 0,
    ),
    children: <UINode>[
      TextNode(
        'The difference is measurable',
        style: MaterialTypography.titleLarge,
        headingLevel: 2,
      ),
      TextNode(
        'A crawler reads 132 words, a single h1 and three links on the listings page '
        'of this site. The Flutter build of the same screen is 4 words and a canvas.',
        style: MaterialTypography.bodyLarge.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
      LinkNode(
        'web/listings/',
        child: Box(
          children: <UINode>[
            TextNode(
              'Open the page a crawler reads',
              style: MaterialTypography.labelLarge.copyWith(
                color: palette.primary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
