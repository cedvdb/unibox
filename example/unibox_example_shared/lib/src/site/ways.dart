import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';

import 'section.dart';

/// The band that says why there are two ways to serve a tree, and which one to pick.
///
/// It sits between the claim and the catalogue because it is the question a reader
/// has once the frames have answered *does it work*: two renderings of one tree is a
/// fact, and *what do I deploy* is the decision that follows it. The catalogue
/// underneath is evidence for the design system, so it is the wrong place to explain
/// a deployment.
///
/// The two cards are the two shapes of application, and each names what it costs:
/// the handover is the cheap one because the application already exists, and a page
/// that draws itself costs the interactions it cannot invent. Naming the cost is the
/// point — a band that only lists benefits leaves the reader to discover the trade on
/// their own timeline.
UINode buildWaysSection({ExampleSeed seed = ExampleSeed.defaultSeed}) {
  final MaterialPalette palette = ExamplePalette.materialFor(seed);

  return siteBand(
    background: palette.surfaceContainerLow,
    child: Box(
      width: double.infinity,
      gap: 40,
      children: <UINode>[
        siteHeading(
          palette,
          title: 'Two ways to serve one tree',
          lead:
              'Both start from the same node tree and both are readable without '
              'JavaScript. What separates them is how much of your application the '
              'tree has to describe.',
        ),
        GridNode(
          minItemWidth: 380,
          maxColumns: 2,
          gap: 20,
          children: <UINode>[
            _way(
              palette,
              label: 'Least to change',
              title: 'Flutter takes the page over',
              lead:
                  'Render the screen a visitor lands on, and let the app draw '
                  'everything after it.',
              points: const <String>[
                'A document a crawler reads, then the same screen from Flutter',
                'The scroll and the presses survive the handover',
                'Dialogs, forms and the screens behind them stay ordinary Flutter',
              ],
            ),
            _way(
              palette,
              label: 'Nothing of Flutter',
              title: 'The page draws itself',
              lead:
                  'The document is the application: a small bundle compiles from '
                  'the same tree and adopts the markup.',
              points: const <String>[
                'No engine, no binary — a folder of files on any static host',
                'Adopts the server markup, so a reader keeps their place',
                'Every interaction is a node, so a dialog is part of the tree',
              ],
            ),
          ],
        ),
        // The sentence that keeps the band honest: neither way is a rewrite of an
        // application, which is the objection a reader arrives with.
        TextNode(
          'The rest of the application stays ordinary Flutter, screen for screen: a '
          'settings page gains nothing from being indexable.',
          style: MaterialTypography.bodyMedium.copyWith(
            color: palette.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

/// One of the two ways: what it is, and what it costs.
UINode _way(
  MaterialPalette palette, {
  required String label,
  required String title,
  required String lead,
  required List<String> points,
}) {
  return MaterialCard.filled(
    color: palette.surface,
    border: BoxBorder(color: palette.outlineVariant),
    children: <UINode>[
      TextNode(
        label,
        style: MaterialTypography.labelMedium.copyWith(color: palette.primary),
      ),
      TextNode(title, style: MaterialTypography.titleLarge),
      TextNode(
        lead,
        style: MaterialTypography.bodyMedium.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
      Box(
        gap: 8,
        children: <UINode>[
          for (final String point in points)
            Box(
              direction: Axis.horizontal,
              crossAlign: CrossAlign.start,
              gap: 10,
              children: <UINode>[
                // A bullet the model can draw: a text, not a marker only one
                // renderer's list styling would produce.
                TextNode(
                  '·',
                  style: MaterialTypography.bodyMedium.copyWith(
                    color: palette.primary,
                  ),
                ),
                Box(
                  flex: 1,
                  children: <UINode>[
                    TextNode(
                      point,
                      style: MaterialTypography.bodySmall.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
