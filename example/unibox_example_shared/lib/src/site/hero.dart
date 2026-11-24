import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';
import 'section.dart';

/// A host-supplied frame displaying a renderer.
typedef ShowcaseFrame = UINode Function({
  required String src,
  required String title,
});

/// One declaration rendered twice, with a live Flutter handover.
UINode buildHeroSection({
  required ShowcaseFrame frame,
  ExampleSeed seed = ExampleSeed.defaultSeed,
}) {
  final palette = ExamplePalette.materialFor(seed);
  return siteSection(
    vertical: 48,
    background: palette.surface,
    child: Box(
      width: double.infinity,
      gap: 24,
      children: <UINode>[
        const TextNode(
          'One UI. Two renderers.',
          headingLevel: 1,
          style: MaterialTypography.displayMedium,
        ),
        const TextNode(
          'Declare once in Dart. Serve HTML first. Hand over to Flutter when ready.',
          style: MaterialTypography.titleMedium,
        ),
        GridNode(
          minItemWidth: 360,
          maxColumns: 2,
          gap: 24,
          children: <UINode>[
            _preview(
              'HTML and CSS',
              'The server rendering.',
              'web/listings/',
              frame,
            ),
            _preview(
              'Flutter',
              'The same UI, with live handover.',
              'web/takeover/',
              frame,
            ),
          ],
        ),
      ],
    ),
  );
}

UINode _preview(
  String title,
  String caption,
  String src,
  ShowcaseFrame frame,
) => Box(
  width: double.infinity,
  gap: 12,
  children: <UINode>[
    TextNode(title, headingLevel: 2, style: MaterialTypography.titleLarge),
    TextNode(caption),
    Box(
      width: double.infinity,
      height: 620,
      border: const BoxBorder(color: BoxColor(0xffd8d8dd)),
      borderRadius: 12,
      overflow: Overflow.hidden,
      children: <UINode>[frame(src: src, title: title)],
    ),
    LinkNode(src, children: <UINode>[TextNode('Open $title')]),
  ],
);
