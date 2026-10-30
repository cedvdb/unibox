import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../theme.dart';
import 'section.dart';

/// The second band: what the whole vocabulary amounts to, once, as one card.
///
/// The band's claim is the smallest sentence the library can be described in: a screen is
/// containers, and a container holds text, a picture, a field or more containers. Nothing
/// else is on offer — there is no widget to learn beside a box — which is why the four nodes
/// a card is built from are the four a reader would otherwise never notice: a picture, a
/// stack, a child placed at an offset and a field with no chrome.
///
/// So the band is one small card, the same card taken apart, and the two calls the taken
/// apart tree is for. The picture is not a screenshot of the card — it *is* the list beside
/// it, which is the whole of what the library claims, and it is why the card is text a
/// crawler reads rather than an image of text it cannot.
UINode buildVocabularySection({ExampleSeed seed = ExampleSeed.defaultSeed}) {
  final MaterialPalette palette = ExamplePalette.materialFor(seed);

  return siteBand(
    // A tint, so the band stands apart from the two bands around it: the claim above it
    // and the catalogue below it are both the surface colour.
    background: palette.surfaceContainer,
    vertical: 80,
    child: Box(
      width: double.infinity,
      gap: 40,
      children: <UINode>[
        siteHeading(
          palette,
          title: 'Just boxes',
          lead:
              'A screen is containers: a box holds text, a picture, a field, or more '
              'boxes, and there is no widget or element to learn beside it. The four '
              'nodes this page had not drawn yet are the parts a card is made of — a '
              'field with no chrome, a stack, a picture, and a child placed at an '
              'offset. The list beside the card is that card, taken apart.',
        ),
        GridNode(
          minItemWidth: 360,
          maxColumns: 2,
          gap: 40,
          children: <UINode>[
            _card(palette),
            // The list and the two calls are one column: the calls are what that list is
            // for, and a reader who has just read the nodes should meet them next rather
            // than on the far side of the card.
            Box(
              crossAlign: CrossAlign.stretch,
              gap: 16,
              children: <UINode>[_tree(palette), _calls(palette)],
            ),
          ],
        ),
        TextNode(
          'The hero, the catalogue and this band are the same nodes, drawn by the same '
          'two calls.',
          style: MaterialTypography.labelMedium.copyWith(
            color: palette.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

/// The listing card: a field over a photograph with a price on its corner, and the
/// two lines that say what the photograph is of.
///
/// Every box here is `crossAlign: stretch`, because the width of a column is what its
/// children fill: a photograph that is `double.infinity` wide inside a column that
/// sizes to its own content is a percentage of nothing.
UINode _card(MaterialPalette palette) {
  return Box(
    crossAlign: CrossAlign.stretch,
    gap: 16,
    children: <UINode>[
      // A field with no chrome of its own: the hint is the whole of what an empty one
      // says, and no browser draws its border, radius or focus ring around it.
      Box(
        borderRadius: 12,
        backgroundColor: palette.surfaceContainerHighest,
        padding: const BoxSpacing.symmetric(horizontal: 14, vertical: 12),
        children: <UINode>[
          TextInputNode(
            placeholder: 'Search the listings',
            placeholderStyle: MaterialTypography.bodyMedium.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      ),
      Box(
        backgroundColor: palette.surface,
        border: BoxBorder(color: palette.outlineVariant),
        borderRadius: 18,
        // The photograph takes the card's own corners: the clip is the card's, not a
        // radius the image asks for, so the price badge inside is clipped with it.
        overflow: Overflow.hidden,
        children: <UINode>[
          StackNode(
            width: double.infinity,
            height: 220,
            children: <UINode>[
              ImageNode(
                'assets/photos/apartment-2.jpg',
                alt: 'A living room with tall windows and a staircase',
                width: double.infinity,
                height: 220,
                fit: ImageFit.cover,
              ),
              // Pinned to a corner of the stack rather than laid out after it: the
              // photograph never learns that a badge is on top of it.
              PositionedNode(
                top: 12,
                right: 12,
                child: Box(
                  backgroundColor: palette.primary,
                  borderRadius: 999,
                  padding: const BoxSpacing.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  children: <UINode>[
                    TextNode(
                      '€ 1\u00A0850',
                      style: MaterialTypography.labelLarge.copyWith(
                        color: palette.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Box(
            padding: const BoxSpacing.all(16),
            crossAlign: CrossAlign.stretch,
            gap: 4,
            children: <UINode>[
              TextNode(
                'Over the rooftops, two rooms',
                style: MaterialTypography.titleMedium,
              ),
              TextNode(
                '72 m² · Paris · available now',
                style: MaterialTypography.bodySmall.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// The two calls the list above is the argument for: one tree, a widget tree and a
/// document.
///
/// They sit under the node list rather than in a paragraph, because the list is what a
/// reader has just read: those nodes are the tree, and these are the only two things
/// anything does with it. Neither name is this page's invention — `toWidget()` is the
/// Flutter renderer's extension and `toHtml()` the web renderer's function.
UINode _calls(MaterialPalette palette) {
  return Box(
    backgroundColor: palette.surface,
    border: BoxBorder(color: palette.outlineVariant),
    borderRadius: 18,
    padding: const BoxSpacing.all(22),
    crossAlign: CrossAlign.stretch,
    gap: 10,
    children: <UINode>[
      TextNode(
        'the same tree, two calls',
        style: MaterialTypography.labelSmall.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
      _call(palette, 'tree.toWidget()', 'Flutter widgets'),
      _call(palette, 'toHtml(tree)', 'an HTML string'),
    ],
  );
}

/// One line of the pair: the call on the left, what it returns on the right.
///
/// The call takes the rest of the width, so the two results end on the same edge as the
/// tokens of the list above rather than after each call's own label.
UINode _call(MaterialPalette palette, String call, String result) {
  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.center,
    gap: 12,
    children: <UINode>[
      Box(
        flex: 1,
        children: <UINode>[
          TextNode(
            call,
            style: MaterialTypography.labelLarge.copyWith(
              color: palette.primary,
            ),
          ),
        ],
      ),
      TextNode(
        result,
        style: MaterialTypography.labelSmall.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// The card on the left, as the nodes it is.
///
/// The list is written by hand, not derived. A renderer could walk the tree and print
/// it, and a page that printed its own tree would say what the code does rather than
/// what a reader is meant to take from it: the four names below are chosen, and the
/// depth of each row is the nesting.
UINode _tree(MaterialPalette palette) {
  return Box(
    backgroundColor: palette.surface,
    border: BoxBorder(color: palette.outlineVariant),
    borderRadius: 18,
    padding: const BoxSpacing.all(22),
    crossAlign: CrossAlign.stretch,
    gap: 2,
    children: <UINode>[
      TextNode(
        'the card, node by node',
        style: MaterialTypography.labelSmall.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
      // Room between the title and the first row: a gap on the column would space every
      // row as well, and a list is read as one object.
      const Box(height: 10),
      _row(palette, 0, 'Box', 'crossAlign, gap'),
      _row(palette, 1, 'TextInputNode', 'placeholder'),
      _row(palette, 1, 'Box', 'radius, overflow'),
      _row(palette, 2, 'StackNode', 'height'),
      _row(palette, 3, 'ImageNode', 'src, alt, fit'),
      _row(palette, 3, 'PositionedNode', 'top, right'),
      _row(palette, 4, 'Box', 'radius, backgroundColor'),
      _row(palette, 5, 'TextNode', 'labelLarge'),
      _row(palette, 2, 'Box', 'padding, gap'),
      _row(palette, 3, 'TextNode', 'titleMedium'),
      _row(palette, 3, 'TextNode', 'bodySmall'),
    ],
  );
}

/// One line of the list: a dot, the name of the node, and what it carries.
///
/// The indent is padding on the row rather than a box around it, so a row is one
/// element however deep it sits — and the dot is a box, because a bullet is a shape
/// and the model has shapes.
UINode _row(MaterialPalette palette, int depth, String name, String carries) {
  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.center,
    gap: 10,
    padding: BoxSpacing.only(left: depth * 16.0, top: 3, bottom: 3),
    children: <UINode>[
      Box(
        width: 6,
        height: 6,
        borderRadius: 3,
        backgroundColor: depth == 0 ? palette.primary : palette.outlineVariant,
      ),
      // The name gets a column of its own, so the tokens line up down the list: a
      // proportional font makes a ragged second column look like an accident, and a
      // table is read by its columns rather than its rows.
      Box(
        width: 112,
        children: <UINode>[
          TextNode(name, style: MaterialTypography.labelLarge),
        ],
      ),
      // The rest of the width, so a list of tokens wraps inside the card instead of
      // pushing its column wider than the card beside it.
      Box(
        flex: 1,
        children: <UINode>[
          TextNode(
            carries,
            style: MaterialTypography.labelSmall.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ],
  );
}
