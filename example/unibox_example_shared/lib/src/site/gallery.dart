import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';
import 'section.dart';

// Specimens demonstrate control paint and press feedback without navigation.
void _press() {}
void _select(int index) {}

/// Material and typography specimens, shared by the two reference hosts.
UINode buildComponentReference({
  ExampleSeed seed = ExampleSeed.defaultSeed,
  MaterialDensity density = MaterialDensity.standard,
}) => Box(
  width: double.infinity,
  children: <UINode>[
    buildMaterialSection(seed: seed, density: density),
    buildTypographySection(seed: seed),
  ],
);

/// Rendered Material controls, not links to other pages.
UINode buildMaterialSection({
  ExampleSeed seed = ExampleSeed.defaultSeed,
  MaterialDensity density = MaterialDensity.standard,
}) {
  final palette = ExamplePalette.materialFor(seed);
  return siteSection(
    background: palette.surface,
    child: Box(
      width: double.infinity,
      crossAlign: CrossAlign.stretch,
      gap: 32,
      children: <UINode>[
        siteHeading(
          palette,
          title: 'Material',
          lead: 'Shared declarations. Native Flutter controls.',
        ),
        _specimen(
          'Cards',
          GridNode(
            minItemWidth: 240,
            maxColumns: 3,
            gap: 16,
            children: <UINode>[
              MaterialCard.filled(
                padding: const BoxSpacing.all(24),
                gap: 8,
                children: _cardText('Filled'),
              ),
              MaterialCard(
                padding: const BoxSpacing.all(24),
                gap: 8,
                children: _cardText('Elevated'),
              ),
              MaterialCard.outlined(
                padding: const BoxSpacing.all(24),
                gap: 8,
                children: _cardText('Outlined'),
              ),
            ],
          ),
        ),
        _specimen(
          'Buttons',
          Box(
            direction: Axis.horizontal,
            wrap: true,
            gap: 12,
            crossAlign: CrossAlign.center,
            children: <UINode>[
              MaterialButton.filled(
                label: const TextNode('Filled'),
                onTap: _press,
                density: density,
              ),
              MaterialButton.tonal(
                label: const TextNode('Tonal'),
                onTap: _press,
                density: density,
              ),
              MaterialButton.outlined(
                label: const TextNode('Outlined'),
                onTap: _press,
                density: density,
              ),
              MaterialButton.text(
                label: const TextNode('Text'),
                onTap: _press,
                density: density,
              ),
            ],
          ),
        ),
        _specimen(
          'Chips',
          Box(
            direction: Axis.horizontal,
            wrap: true,
            gap: 12,
            children: <UINode>[
              MaterialChip(
                label: const TextNode('Choice'),
                onTap: _press,
                density: density,
              ),
              MaterialChip(
                label: const TextNode('Selected'),
                selected: true,
                onTap: _press,
                density: density,
              ),
              MaterialChip(
                label: const TextNode('Removable'),
                trailing: const TextNode('×', fontSize: 18),
                onTap: _press,
                onRemove: _press,
                density: density,
              ),
            ],
          ),
        ),
        _specimen(
          'Segments',
          MaterialSegmentedButton(
            density: density,
            showSelectedIcon: false,
            segments: const <MaterialSegment>[
              MaterialSegment(label: TextNode('Day')),
              MaterialSegment(label: TextNode('Week')),
              MaterialSegment(label: TextNode('Month')),
            ],
            selected: 1,
            onSelect: _select,
          ),
        ),
        _specimen(
          'Colour roles',
          GridNode(
            minItemWidth: 180,
            maxColumns: 4,
            gap: 12,
            children: <UINode>[
              _swatch('Primary', palette.primary, palette.onPrimary),
              _swatch(
                'Secondary',
                palette.secondaryContainer,
                palette.onSecondaryContainer,
              ),
              _swatch('Tertiary', palette.tertiary, palette.onTertiary),
              _swatch(
                'Surface',
                palette.surfaceContainerHighest,
                palette.onSurface,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

List<UINode> _cardText(String title) => <UINode>[
  TextNode(title, style: MaterialTypography.titleMedium),
  const TextNode(
    'The same content and design values.',
    style: MaterialTypography.bodyMedium,
  ),
];

UINode _swatch(String name, BoxColor colour, BoxColor foreground) => Box(
  padding: const BoxSpacing.all(20),
  borderRadius: 12,
  backgroundColor: colour,
  children: <UINode>[TextNode(name, color: foreground)],
);

/// The Material type scale, displayed directly in the page.
UINode buildTypographySection({ExampleSeed seed = ExampleSeed.defaultSeed}) {
  final palette = ExamplePalette.materialFor(seed);
  return siteSection(
    background: palette.surfaceContainerLow,
    child: Box(
      width: double.infinity,
      gap: 32,
      children: <UINode>[
        siteHeading(
          palette,
          title: 'Typography',
          lead: 'One type scale for both renderers.',
        ),
        GridNode(
          minItemWidth: 420,
          maxColumns: 2,
          gap: 40,
          children: <UINode>[
            _specimen(
              'Display',
              const Box(
                gap: 12,
                children: <UINode>[
                  TextNode(
                    'Display large',
                    style: MaterialTypography.displayLarge,
                  ),
                  TextNode(
                    'Display medium',
                    style: MaterialTypography.displayMedium,
                  ),
                  TextNode(
                    'Display small',
                    style: MaterialTypography.displaySmall,
                  ),
                ],
              ),
            ),
            _specimen(
              'Headline',
              const Box(
                gap: 12,
                children: <UINode>[
                  TextNode(
                    'Headline large',
                    style: MaterialTypography.headlineLarge,
                  ),
                  TextNode(
                    'Headline medium',
                    style: MaterialTypography.headlineMedium,
                  ),
                  TextNode(
                    'Headline small',
                    style: MaterialTypography.headlineSmall,
                  ),
                ],
              ),
            ),
            _specimen(
              'Title',
              const Box(
                gap: 12,
                children: <UINode>[
                  TextNode('Title large', style: MaterialTypography.titleLarge),
                  TextNode(
                    'Title medium',
                    style: MaterialTypography.titleMedium,
                  ),
                  TextNode('Title small', style: MaterialTypography.titleSmall),
                ],
              ),
            ),
            _specimen(
              'Body',
              const Box(
                gap: 12,
                children: <UINode>[
                  TextNode(
                    'Body large — clear, readable text.',
                    style: MaterialTypography.bodyLarge,
                  ),
                  TextNode(
                    'Body medium — clear, readable text.',
                    style: MaterialTypography.bodyMedium,
                  ),
                  TextNode(
                    'Body small — clear, readable text.',
                    style: MaterialTypography.bodySmall,
                  ),
                ],
              ),
            ),
            _specimen(
              'Label',
              const Box(
                gap: 12,
                children: <UINode>[
                  TextNode('Label large', style: MaterialTypography.labelLarge),
                  TextNode(
                    'Label medium',
                    style: MaterialTypography.labelMedium,
                  ),
                  TextNode('Label small', style: MaterialTypography.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

UINode _specimen(String title, UINode content) => Box(
  width: double.infinity,
  gap: 16,
  semantics: const BoxSemantics(element: BoxElement.section),
  children: <UINode>[
    TextNode(title, headingLevel: 3, style: MaterialTypography.titleLarge),
    content,
  ],
);
