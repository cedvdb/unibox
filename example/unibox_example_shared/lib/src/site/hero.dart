import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';
import 'section.dart';

/// A host-supplied frame displaying another example surface.
typedef ShowcaseFrame = UINode Function({
  required String src,
  required String title,
});

/// The primary comparison: a static document and a normal Flutter application.
UINode buildHeroSection({
  required ShowcaseFrame frame,
  ExampleSeed seed = ExampleSeed.defaultSeed,
}) {
  final palette = ExamplePalette.materialFor(seed);
  return siteSection(
    background: palette.surface,
    child: Box(
      width: double.infinity,
      gap: 32,
      children: <UINode>[
        const TextNode(
          'Unibox · shared UI regions',
          style: MaterialTypography.labelLarge,
        ),
        const TextNode(
          'One region. HTML and Flutter.',
          headingLevel: 1,
          style: MaterialTypography.displayMedium,
        ),
        const TextNode(
          'Declare the content both surfaces need in pure Dart. Serve it as HTML and CSS, '
          'then render the same declaration as Flutter widgets inside your application. '
          'Keep your page composition, search, maps, navigation and booking flows in their hosts.',
          style: MaterialTypography.titleMedium,
        ),
        const TextNode(
          'The listing cards below come from one declaration. The server adds a document '
          'title and metadata. The Flutter app adds its own search, filters and dialog. '
          'The two examples run independently: this comparison does not perform a handover.',
        ),
        GridNode(
          minItemWidth: 360,
          maxColumns: 2,
          gap: 24,
          children: <UINode>[
            _preview(
              'Server document',
              'Readable text, photographs and real links. No application runtime.',
              'web/listings/',
              frame,
            ),
            _preview(
              'Flutter application',
              'Native search and filters around the shared listing region.',
              'flutter/listings/',
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
