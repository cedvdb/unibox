import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';
import 'section.dart';

/// The HTML a search engine receives, beside the Dart declaration that produced it.
UINode buildIndexableSection({ExampleSeed seed = ExampleSeed.defaultSeed}) {
  final MaterialPalette palette = ExamplePalette.materialFor(seed);

  return siteSection(
    vertical: 80,
    child: Box(
      width: double.infinity,
      gap: 40,
      children: <UINode>[
        siteHeading(
          palette,
          title: 'Make Flutter Web pages indexable',
          lead:
              'Serve real headings, text and links before Flutter loads. '
              'One declaration keeps the HTML and application UI in step.',
        ),
        GridNode(
          minItemWidth: 360,
          maxColumns: 2,
          gap: 24,
          children: <UINode>[
            _code(palette, 'the screen, in Dart', const <String>[
              'Box(',
              '  children: <UINode>[',
              '    TextNode(',
              "      'Apartments in Amsterdam',",
              '      headingLevel: 1,',
              '    ),',
              "    LinkNode('apartments/amsterdam',",
              "      children: <UINode>[TextNode('See all')],",
              '    ),',
              '  ],',
              ')',
            ]),
            _code(palette, 'what a crawler is served', const <String>[
              '<body>',
              '  <div class="unibox-box-...">',
              '    <h1>Apartments in Amsterdam</h1>',
              '    <a href="apartments/amsterdam">',
              '      See all',
              '    </a>',
              '  </div>',
              '</body>',
            ], note: 'class names elided'),
          ],
        ),
        GridNode(
          minItemWidth: 360,
          maxColumns: 2,
          gap: 24,
          children: <UINode>[
            _point(
              palette,
              title: 'Flutter still takes the page over',
              body:
                  'HTML appears first. Flutter takes over when ready, restoring the '
                  'scroll position and replaying an intercepted keyed action.',
            ),
            _point(
              palette,
              title: 'Use your existing Flutter app',
              body:
                  'Share the regions that need an HTML rendering. Your app keeps its '
                  'routing, data and state.',
            ),
          ],
        ),
      ],
    ),
  );
}

/// One card of code: a `figure` whose caption names it, then the lines themselves.
///
/// The lines are text, not a `pre`: a tree that printed its own source would be a
/// picture of the implementation, while these are chosen to be read. Indentation is
/// padding per leading space, because HTML collapses whitespace and Flutter trims it —
/// the same reason a listing's indent is a padding rather than two spaces in a string.
UINode _code(
  MaterialPalette palette,
  String title,
  List<String> lines, {
  String? note,
}) {
  return Box(
    backgroundColor: palette.surfaceContainer,
    border: BoxBorder(color: palette.outlineVariant),
    borderRadius: 18,
    padding: const BoxSpacing.all(22),
    crossAlign: CrossAlign.stretch,
    gap: 2,
    // A sample with a caption is a `figure` in HTML, and the line above it is the
    // `figcaption`: the web then says what the block is rather than that it is a box.
    semantics: const BoxSemantics(element: BoxElement.figure),
    children: <UINode>[
      Box(
        semantics: const BoxSemantics(element: BoxElement.figcaption),
        children: <UINode>[
          TextNode(
            title,
            style: MaterialTypography.labelSmall.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      ),
      // Room between the caption and the first line: a gap on the column would space
      // every line as well, and code is read as one block.
      const Box(height: 10),
      for (final String line in lines) _line(palette, line),
      if (note != null) ...<UINode>[
        const Box(height: 10),
        TextNode(
          note,
          style: MaterialTypography.labelSmall.copyWith(
            color: palette.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}

/// One line of code, indented by the spaces it was written with.
UINode _line(MaterialPalette palette, String line) {
  final int indent = line.length - line.trimLeft().length;

  return Box(
    padding: BoxSpacing.only(left: indent * 6.0),
    children: <UINode>[
      TextNode(
        line.trimLeft(),
        style: MaterialTypography.labelMedium.copyWith(
          color: palette.onSurface,
        ),
      ),
    ],
  );
}

/// One answer to a question the cards raise: a line, and the paragraph under it.
UINode _point(
  MaterialPalette palette, {
  required String title,
  required String body,
}) {
  return Box(
    crossAlign: CrossAlign.stretch,
    gap: 6,
    children: <UINode>[
      TextNode(
        title,
        style: MaterialTypography.titleSmall.copyWith(color: palette.onSurface),
      ),
      TextNode(
        body,
        style: MaterialTypography.bodyMedium.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}
