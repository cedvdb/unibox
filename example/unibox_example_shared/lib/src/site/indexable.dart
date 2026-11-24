import 'package:unibox_core/unibox_core.dart';

import '../theme.dart';
import 'section.dart';

/// The motivation and the boundary of the shared declaration.
UINode buildIndexableSection({ExampleSeed seed = ExampleSeed.defaultSeed}) {
  final palette = ExamplePalette.materialFor(seed);
  return siteSection(
    background: palette.surfaceContainerLow,
    child: Box(
      width: double.infinity,
      gap: 24,
      children: <UINode>[
        siteHeading(
          palette,
          title: 'Share the content that needs to be found',
          lead:
              'Listing cards, product details, editorial sections and footers often need both '
              'a readable web document and a place in a Flutter application.',
        ),
        const TextNode(
          'Flutter widgets do not provide a server HTML document. Maintaining a separate '
          'HTML implementation of the same content creates another layout to keep in step. '
          'Unibox provides a shared declaration for those regions; it does not convert arbitrary '
          'existing Flutter widgets into HTML or guarantee search rankings.',
        ),
        const TextNode(
          'The server owns URLs, metadata, canonical addresses, assets and deployment. '
          'The Flutter host owns state, data fetching and interaction. Pass data into a declaration '
          'and build a fresh tree when it changes. You can keep the rest of your application in '
          'ordinary Flutter and adopt shared regions where they earn their place.',
        ),
        const Box(
          padding: BoxSpacing.all(20),
          backgroundColor: BoxColor(0xfff7f7fa),
          children: <UINode>[
            TextNode(
              '// shared/region.dart — pure Dart\n'
              'UINode buildRegion(String city) => Box(\n'
              '  gap: 12,\n'
              '  children: <UINode>[\n'
              "    TextNode('Homes in \$city', headingLevel: 2),\n"
              "    LinkNode('/homes', children: [TextNode('See all')]),\n"
              '  ],\n'
              ');',
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ],
        ),
        const TextNode(
          'On the server: toHtml(buildRegion(city)). In the app: '
          'renderFlutter(buildRegion(city)). The hosts decide where the region belongs; '
          'neither renderer needs an application router or a browser state runtime.',
        ),
      ],
    ),
  );
}
