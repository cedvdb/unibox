import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';
import 'hero.dart';
import 'indexable.dart';
import 'vocabulary.dart';
import 'gallery.dart';
import 'section.dart';

/// The project source and documentation.
const String repositoryUrl = 'https://github.com/cedvdb/unibox';

/// The original landing-page structure, with the current shared example.
UINode buildSitePage({
  required ShowcaseFrame frame,
  ExampleSeed seed = ExampleSeed.defaultSeed,
}) {
  final palette = ExamplePalette.materialFor(seed);
  return Box(
    width: double.infinity,
    backgroundColor: palette.surface,
    textStyle: MaterialTypography.bodyMedium.copyWith(color: palette.onSurface),
    children: <UINode>[
      siteSection(
        vertical: 14,
        element: BoxElement.header,
        child: Box(
          width: double.infinity,
          direction: Axis.horizontal,
          mainAlign: MainAlign.spaceBetween,
          crossAlign: CrossAlign.center,
          gap: 16,
          wrap: true,
          children: <UINode>[
            Box(
              direction: Axis.horizontal,
              crossAlign: CrossAlign.center,
              gap: 20,
              children: <UINode>[
                const LinkNode(
                  './',
                  children: <UINode>[
                    TextNode('Unibox', style: MaterialTypography.titleMedium),
                  ],
                ),
                Box(
                  direction: Axis.horizontal,
                  crossAlign: CrossAlign.center,
                  height: 32,
                  gap: 8,
                  children: <UINode>[
                    for (final choice in ExampleSeed.values)
                      Box(
                        width: 22,
                        height: 22,
                        borderRadius: 11,
                        backgroundColor: ExamplePalette.materialFor(choice)
                            .primary,
                        border: BoxBorder(
                          color: choice == seed
                              ? palette.onSurface
                              : palette.outlineVariant,
                          width: choice == seed ? 2 : 1,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const LinkNode(
              repositoryUrl,
              children: <UINode>[
                TextNode('GH  GitHub', style: MaterialTypography.labelLarge),
              ],
            ),
          ],
        ),
      ),
      Box(
        width: double.infinity,
        semantics: const BoxSemantics(element: BoxElement.main),
        children: <UINode>[
          buildHeroSection(frame: frame, seed: seed),
          buildIndexableSection(seed: seed),
          buildVocabularySection(seed: seed),
          buildMaterialSection(seed: seed),
          buildTypographySection(seed: seed),
        ],
      ),
      siteSection(
        vertical: 24,
        element: BoxElement.footer,
        child: const Box(
          direction: Axis.horizontal,
          gap: 24,
          wrap: true,
          children: <UINode>[
            TextNode('Unibox — Flutter UI, searchable HTML.'),
            LinkNode(repositoryUrl, children: <UINode>[TextNode('Source')]),
            LinkNode(
              '$repositoryUrl#readme',
              children: <UINode>[TextNode('README')],
            ),
          ],
        ),
      ),
    ],
  );
}
