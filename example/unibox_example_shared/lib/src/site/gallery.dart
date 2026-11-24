import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';
import 'section.dart';

/// The small Material vocabulary for server documents and native Flutter widgets.
UINode buildMaterialSection({
  ExampleSeed seed = ExampleSeed.defaultSeed,
  MaterialDensity density = MaterialDensity.standard,
  String listingsUrl = 'web/listings/',
}) {
  final MaterialPalette palette = ExamplePalette.materialFor(seed);
  return siteSection(
    background: palette.surface,
    child: Box(
      crossAlign: CrossAlign.stretch,
      gap: 24,
      children: <UINode>[
        siteHeading(
          palette,
          title: 'A small optional Material vocabulary',
          lead: 'Shared colour and type values, plus declarations with native Flutter substitutions. The application installs the mapping; native paint may differ while content and actions agree.',
        ),
        _specimen(
          'Cards',
          const MaterialCard(
            padding: BoxSpacing.all(24),
            children: <UINode>[
              TextNode('A shared card', style: MaterialTypography.titleLarge),
              TextNode(
                'The document and the app share content and design values.',
              ),
            ],
          ),
        ),
        _specimen(
          'Buttons',
          Box(
            wrap: true,
            direction: Axis.horizontal,
            gap: 12,
            children: <UINode>[
              MaterialButton(
                label: const TextNode('View listings'),
                url: listingsUrl,
                density: density,
              ),
              MaterialButton.outlined(
                label: const TextNode('Source'),
                url: 'https://github.com/cedvdb/unibox',
                density: density,
              ),
            ],
          ),
        ),
        _specimen(
          'Chips',
          MaterialChip(
            label: const TextNode('Apartments'),
            selected: true,
            url: listingsUrl,
            density: density,
          ),
        ),
        _specimen(
          'Segments',
          MaterialSegmentedButton(
            density: density,
            showSelectedIcon: false,
            segments: <MaterialSegment>[
              MaterialSegment(
                label: const TextNode('Listings'),
                url: listingsUrl,
              ),
              const MaterialSegment(
                label: TextNode('Source'),
                url: 'https://github.com/cedvdb/unibox',
              ),
            ],
            selected: 0,
          ),
        ),
        _specimen(
          'Type scale',
          const TextNode(
            'One type scale for both renderers.',
            style: MaterialTypography.bodyLarge,
          ),
        ),
        _specimen(
          'Colour roles',
          Box(
            direction: Axis.horizontal,
            wrap: true,
            gap: 12,
            children: <UINode>[
              Box(
                padding: const BoxSpacing.all(16),
                backgroundColor: palette.primary,
                children: <UINode>[
                  TextNode('Primary', color: palette.onPrimary),
                ],
              ),
              Box(
                padding: const BoxSpacing.all(16),
                backgroundColor: palette.secondaryContainer,
                children: <UINode>[
                  TextNode('Container', color: palette.onSecondaryContainer),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

UINode _specimen(String title, UINode content) => Box(
  width: double.infinity,
  gap: 12,
  semantics: const BoxSemantics(element: BoxElement.section),
  children: <UINode>[
    TextNode(title, headingLevel: 3, style: MaterialTypography.titleLarge),
    content,
  ],
);
