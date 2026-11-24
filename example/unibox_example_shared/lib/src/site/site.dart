import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';
import 'hero.dart';
import 'handover.dart';
import 'section.dart';

/// The project source and documentation.
const String repositoryUrl = 'https://github.com/cedvdb/unibox';

/// A documentation page; application examples remain separate host compositions.
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
        vertical: 20,
        element: BoxElement.header,
        child: const Box(
          width: double.infinity,
          gap: 16,
          wrap: true,
          direction: Axis.horizontal,
          mainAlign: MainAlign.spaceBetween,
          children: <UINode>[
            TextNode('Unibox', style: MaterialTypography.titleLarge),
            LinkNode(repositoryUrl, children: <UINode>[TextNode('GitHub')]),
          ],
        ),
      ),
      Box(
        width: double.infinity,
        semantics: const BoxSemantics(element: BoxElement.main),
        children: <UINode>[
          buildHeroSection(frame: frame, seed: seed),
          buildHandoverSection(seed: seed),
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
            LinkNode(
              repositoryUrl,
              children: <UINode>[TextNode('Documentation')],
            ),
            LinkNode(
              'web/components/',
              children: <UINode>[TextNode('Material components')],
            ),
          ],
        ),
      ),
    ],
  );
}
