import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../icons.dart';
import '../theme.dart';
import 'section.dart';

/// The third section: the Material library as one node tree — the type scale, the
/// colour roles and the components.
///
/// The section is a demonstration and a claim at once. Every value on it is a `const`
/// in `unibox_material` — no colour is typed into this file — and every component is
/// a node the two renderers already draw, so nothing here is a screenshot.
///
/// It is a section of the page rather than a page of its own: the heading names what
/// the catalogue is, and each block under it is an `h3`, so the page still has one
/// `h1` and four `h2`s above it. Each block is a `section` on the web, so the document
/// says where one demonstration ends — the block has a heading of its own, which is
/// exactly what makes it one.
UINode buildMaterialSection({
  ExampleSeed seed = ExampleSeed.defaultSeed,
  // The platform's density, which is the host's answer: a desk draws a tighter control than a
  // phone, and the tree states which one it was built for.
  MaterialDensity density = MaterialDensity.standard,
}) {
  final MaterialPalette palette = ExamplePalette.materialFor(seed);

  return siteSection(
    background: palette.surface,
    child: Box(
      width: double.infinity,
      gap: 48,
      children: <UINode>[
        // The palette the catalogue documents is chosen in the page's header, and every
        // specimen and hex below follows the seed it names.
        siteHeading(palette, title: 'Material'),
        // Components first: they are what a page is built from, and the scale and the
        // palette are what those components name.
        _section(
          palette,
          'Buttons',
          _buttons(density),
          note: 'Four shapes around one ink well: press one.',
        ),
        _section(
          palette,
          'Chips',
          _chips(density),
          note: 'A choice, and one with a cross.',
        ),
        _section(
          palette,
          'Segments',
          _segments(),
          note: 'A set of choices in one pill.',
        ),
        _section(
          palette,
          'Cards and tiles',
          _cards(palette),
          note:
              'All six heights on the surface Material tints to match, the two other '
              'shapes a card comes in, and a row that says who it is.',
        ),
        // Then the values. The samples are the argument: fifteen lines of text and a
        // wall of swatches need a name, not a paragraph.
        _section(palette, 'Type scale', _typeScale(palette)),
        _section(palette, 'Colour roles', _palette(palette)),
        // The third value a box can name: its outline. A ring is one path with two
        // circles and the even-odd rule, and the label in its hole is an ordinary child.
        _section(
          palette,
          'Shapes',
          _shapes(palette),
          note:
              'A path in a view box: a hexagon, a circle, and a ring — and that ring '
              'twice over, turning: a progress indicator and the spinner beside it.',
        ),
      ],
    ),
  );
}

/// A titled block of the catalogue: an `h3`, one line under it, and the nodes that
/// show it.
///
/// The line is optional and short on purpose. A catalogue is read by looking at the
/// samples, so a block says what it is and stops; the READMEs are where the long
/// explanation lives.
UINode _section(
  MaterialPalette palette,
  String title,
  UINode content, {
  String? note,
}) {
  return Box(
    width: double.infinity,
    gap: 16,
    // The block is a section: it has a heading of its own, so the web document — and a
    // reader's outline of it — says where the demonstration starts and stops.
    semantics: const BoxSemantics(element: BoxElement.section),
    // The blocks of a section fill it: a tile, a field or a row of chips is as wide
    // as the section, which is also what makes a `width: double.infinity` inside one
    // mean the same thing in Flutter and in a browser.
    crossAlign: CrossAlign.stretch,
    children: <UINode>[
      Box(
        gap: 4,
        children: <UINode>[
          TextNode(
            title,
            style: MaterialTypography.titleLarge,
            headingLevel: 3,
          ),
          if (note != null)
            Box(
              width: double.infinity,
              maxWidth: 720,
              children: <UINode>[
                TextNode(
                  note,
                  style: MaterialTypography.bodyMedium,
                  color: palette.onSurfaceVariant,
                ),
              ],
            ),
        ],
      ),
      content,
    ],
  );
}

/// One row per type role: the role's name and a line of text typeset with it.
UINode _typeScale(MaterialPalette palette) {
  return Box(
    gap: 12,
    children: <UINode>[
      for (final MaterialTypeRole role in MaterialTypeRole.values)
        // A grid, so the role's name sits above its sample on a narrow window: a
        // 57 pixel line cannot share a row with a 180 pixel label and stay put.
        GridNode(
          minItemWidth: 240,
          maxColumns: 2,
          gap: 24,
          children: <UINode>[
            Box(
              width: double.infinity,
              children: <UINode>[
                TextNode(
                  _label(role.name),
                  style: MaterialTypography.labelMedium,
                  color: palette.onSurfaceVariant,
                ),
              ],
            ),
            Box(
              width: double.infinity,
              children: <UINode>[
                TextNode(
                  'Sphinx of black quartz',
                  style: MaterialTypography.of(role),
                ),
              ],
            ),
          ],
        ),
    ],
  );
}

/// The palette as rows of swatches: the colour, its role and its value.
UINode _palette(MaterialPalette palette) {
  final List<(String, BoxColor)> roles = <(String, BoxColor)>[
    ('primary', palette.primary),
    ('onPrimary', palette.onPrimary),
    ('primaryContainer', palette.primaryContainer),
    ('onPrimaryContainer', palette.onPrimaryContainer),
    ('secondary', palette.secondary),
    ('onSecondary', palette.onSecondary),
    ('secondaryContainer', palette.secondaryContainer),
    ('onSecondaryContainer', palette.onSecondaryContainer),
    ('surface', palette.surface),
    ('onSurface', palette.onSurface),
    ('onSurfaceVariant', palette.onSurfaceVariant),
    ('surfaceContainerLowest', palette.surfaceContainerLowest),
    ('surfaceContainerLow', palette.surfaceContainerLow),
    ('surfaceContainer', palette.surfaceContainer),
    ('surfaceContainerHigh', palette.surfaceContainerHigh),
    ('surfaceContainerHighest', palette.surfaceContainerHighest),
    ('outline', palette.outline),
    ('outlineVariant', palette.outlineVariant),
    ('error', palette.error),
    ('onError', palette.onError),
    ('scrim', palette.scrim),
  ];

  // One grid, not rows of five: the swatches fold to however many fit, which is
  // what keeps the catalogue readable on a phone.
  return GridNode(
    minItemWidth: 150,
    maxColumns: 4,
    gap: 16,
    children: <UINode>[
      for (final (String name, BoxColor color) in roles)
        _swatch(name, color, palette),
    ],
  );
}

/// One palette entry: the colour, its role and its value.
///
/// The swatch fills the cell: a box with a height and no width is a column's child
/// with no cross size, which is a colour nobody can see. That is exactly what
/// happened the first time this page was published.
UINode _swatch(String name, BoxColor color, MaterialPalette palette) {
  return Box(
    width: double.infinity,
    gap: 6,
    children: <UINode>[
      Box(
        width: double.infinity,
        height: 56,
        borderRadius: 8,
        backgroundColor: color,
        border: BoxBorder(color: palette.outlineVariant),
      ),
      TextNode(name, style: MaterialTypography.labelMedium),
      TextNode(
        _hex(color),
        style: MaterialTypography.labelSmall.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// The outlines a box can wear: a hexagon, a circle and a ring.
///
/// Each one is a `BoxShape` — a path in a 100 by 100 view box — so the same value
/// draws the same silhouette at 40 pixels and at 96. Nothing else about the box
/// changes: the label inside the ring is a child that the column centres.
UINode _shapes(MaterialPalette palette) {
  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.center,
    gap: 24,
    children: <UINode>[
      _badge(_hexagon, palette.primary, palette.onPrimary, '6'),
      _badge(
        BoxShape.circle,
        palette.primaryContainer,
        palette.onPrimaryContainer,
        'Ada',
        outline: palette.primary,
      ),
      // The two components built on the shape: a value, and a value nobody knows.
      MaterialProgressRing(
        value: 0.42,
        size: 96,
        thickness: 8,
        label: '42% complete',
      ),
      MaterialSpinner(size: 96, thickness: 8, label: 'Loading'),
    ],
  );
}

/// One shape with its label, both centred in the box's rectangle.
///
/// [outline] draws a border along the outline rather than around the rectangle,
/// which is what a shape does with the same token a square box uses.
UINode _badge(
  BoxShape shape,
  BoxColor fill,
  BoxColor ink,
  String label, {
  BoxColor? outline,
}) {
  return Box(
    width: 96,
    height: 96,
    shape: shape,
    backgroundColor: fill,
    border: outline == null ? null : BoxBorder(width: 2, color: outline),
    mainAlign: MainAlign.center,
    crossAlign: CrossAlign.center,
    children: <UINode>[
      TextNode(
        label,
        style: MaterialTypography.labelLarge.copyWith(color: ink),
      ),
    ],
  );
}

/// A hexagon: six edges of the view box.
const BoxShape _hexagon = BoxShape(
  viewBoxWidth: 100,
  viewBoxHeight: 100,
  commands: <BoxPathCommand>[
    BoxPathMoveTo(50, 0),
    BoxPathLineTo(93, 25),
    BoxPathLineTo(93, 75),
    BoxPathLineTo(50, 100),
    BoxPathLineTo(7, 75),
    BoxPathLineTo(7, 25),
    BoxPathClose(),
  ],
);

/// A Material button: a filled surface with a [MaterialInkWell] over it.
///
/// The tint and the ink have to sit *above* the fill, so the fill is the box around
/// the ink well; the other way round the background would hide both. The ink is the
/// label's colour, because that is the one value here that is known to contrast
/// with the fill.
/// `surfaceContainerLow` as `Surface container low`, for a label a reader can scan.
String _label(String camelCase) {
  final String spaced = camelCase.replaceAllMapped(
    RegExp('[A-Z]'),
    (Match match) => ' ${match[0]!.toLowerCase()}',
  );
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

/// A colour as `#RRGGBB`, the way a reader checks it against a design tool.
String _hex(BoxColor color) {
  final String digits = color.value.toRadixString(16).padLeft(8, '0');
  return '#${digits.substring(2).toUpperCase()}';
}

/// The button shapes, each in a resting state a static page can show.
UINode _buttons(MaterialDensity density) {
  return GridNode(
    minItemWidth: 150,
    maxColumns: 4,
    gap: 16,
    children: <UINode>[
      _natural(
        MaterialButton.filled(
          density: density,
          label: const TextNode('Filled'),
          onTap: () {},
        ),
      ),
      _natural(
        MaterialButton.tonal(
          density: density,
          label: const TextNode('Tonal'),
          onTap: () {},
        ),
      ),
      _natural(
        MaterialButton.outlined(
          density: density,
          label: const TextNode('Outlined'),
          onTap: () {},
        ),
      ),
      _natural(
        MaterialButton.text(
          density: density,
          label: const TextNode('Text'),
          onTap: () {},
        ),
      ),
    ],
  );
}

/// Keeps [child] at its own size inside a grid track.
///
/// A track is as wide as its column and a box inside one fills that width, which
/// turned every button on this page into a banner with its hover tint stretched
/// across it. A row lays the control out at its natural size and leaves the rest of
/// the track empty.
UINode _natural(UINode child) => Box(
  direction: Axis.horizontal,
  crossAlign: CrossAlign.center,
  children: <UINode>[child],
);

/// The two kinds of chip: a filter, and one that can be closed.
///
/// The chips show the shapes Material gives one: a chosen chip with a check in
/// front, plain ones, a disabled one, and an input chip whose cross removes it. The
/// chosen chip's check is `MaterialCheckMark` — drawn, because an icon font is an
/// asset the example does not ship — and the other glyphs come from `icons.dart`.
///
/// Each group keeps its children at their natural size, so a chip never stretches
/// into the space its grid track has, and each row scrolls rather than pushing the
/// page sideways on a phone.
UINode _chips(MaterialDensity density) {
  const BoxColor onSelected = BoxColor.role(
    MaterialColorRole.onSecondaryContainer,
  );
  const BoxColor onPlain = BoxColor.role(MaterialColorRole.onSurfaceVariant);

  return GridNode(
    minItemWidth: 280,
    maxColumns: 2,
    gap: 24,
    children: <UINode>[
      Box(
        direction: Axis.horizontal,
        crossAlign: CrossAlign.center,
        gap: 8,
        // Four chips need more than one cell of this grid holds on a phone, and a
        // chip is a control with a fixed size: the row scrolls rather than pushing
        // the page sideways.
        key: 'catalogue-chips',
        overflow: Overflow.scroll,
        children: <UINode>[
          MaterialChip(
            density: density,
            label: const TextNode('Two rooms'),
            selected: true,
            onTap: () {},
            leading: MaterialCheckMark(
              color: onSelected,
              size: MaterialChip.iconSize,
            ),
          ),
          MaterialChip(
            density: density,
            label: const TextNode('Studio'),
            onTap: () {},
            leading: glyphGrid(onPlain, size: MaterialChip.iconSize),
          ),
          MaterialChip(
            density: density,
            label: const TextNode('Map'),
            onTap: () {},
            leading: glyphList(onPlain, size: MaterialChip.iconSize),
          ),
          // A chip that cannot be pressed fades rather than shouting: the last
          // state Material gives one.
          MaterialChip(
            density: density,
            label: const TextNode('Sold'),
            enabled: false,
            leading: glyphList(onPlain, size: MaterialChip.iconSize),
          ),
        ],
      ),
      RemovableChips(),
    ],
  );
}

/// The segmented buttons: one that picks from a set, and one that switches a view.
UINode _segments() {
  return GridNode(
    minItemWidth: 280,
    maxColumns: 2,
    gap: 24,
    children: <UINode>[SegmentedDemo(), ViewSwitchDemo()],
  );
}

/// The chips that are left after the crosses were pressed.
final class ChipsStore extends StateStore<Set<String>> {
  /// Creates the demo with every chip still there.
  ChipsStore() : super(const <String>{'Garden', 'Balcony'});

  /// Removes the chip called [label].
  void remove(String label) =>
      state = <String>{...state.where((String chip) => chip != label)};
}

/// Input chips: a cross in each, and a chip that goes away when it is pressed.
///
/// It takes a `StackNode` with an empty first child because a view may not read as an
/// empty layer: the row is the stack's sizer, so a removed chip leaves a gap rather
/// than collapsing the demo.
final class RemovableChips extends StatefulNode<Set<String>, ChipsStore> {
  /// Creates the demo, with both chips there.
  RemovableChips() : super(create: ChipsStore.new, view: _removableView);
}

/// The row of chips the store still holds.
UINode _removableView(Set<String> chips, ChipsStore store) {
  const BoxColor ink = BoxColor.role(MaterialColorRole.onSurfaceVariant);

  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.center,
    gap: 8,
    // Two pills and their crosses are wider than a phone's cell, so the row scrolls
    // instead of widening the page.
    key: 'catalogue-pills',
    overflow: Overflow.scroll,
    children: <UINode>[
      for (final String chip in chips)
        MaterialChip(
          label: TextNode(chip),
          trailing: glyphClose(ink),
          onRemove: () => store.remove(chip),
        ),
      if (chips.isEmpty)
        TextNode(
          'All filters removed',
          style: MaterialTypography.labelLarge.copyWith(
            color: const BoxColor.role(MaterialColorRole.onSurfaceVariant),
          ),
        ),
    ],
  );
}

/// A segmented button that keeps the choice it was given.
/// The choice is the state: the view puts the segment the store says is chosen into
/// the button, and a press asks for another one — the same shape as the dialog demo,
/// and the reason a segmented button needs no state of its own.
UINode _segmentedView(int chosen, SegmentedStore store) {
  return MaterialSegmentedButton(
    // The width the grid cell gives it, divided three ways. The segments are equal
    // columns either way — the widest label sets all three — and a width is what puts
    // them across the cell rather than hugging the start of it.
    width: double.infinity,
    segments: const <MaterialSegment>[
      MaterialSegment(label: TextNode('Day'), semanticsLabel: 'Per day'),
      MaterialSegment(label: TextNode('Week'), semanticsLabel: 'Per week'),
      MaterialSegment(label: TextNode('Month'), semanticsLabel: 'Per month'),
    ],
    selected: chosen,
    onSelect: store.choose,
  );
}

/// The choice of the view switcher: which way the listings are drawn.
final class ViewStore extends StateStore<int> {
  /// Creates the switcher with the list chosen.
  ViewStore() : super(0);

  /// Chooses the view at [index].
  void choose(int index) => state = index;
}

/// A segmented button led by icons, which is where a segment's glyph earns its
/// place: a list, a grid and a map are pictures before they are words.
final class ViewSwitchDemo extends StatefulNode<int, ViewStore> {
  /// Creates the switcher, with its first segment chosen.
  ViewSwitchDemo() : super(create: ViewStore.new, view: _viewSwitchView);
}

/// The three ways to draw a page of listings.
UINode _viewSwitchView(int chosen, ViewStore store) {
  const BoxColor onSurface = BoxColor.role(MaterialColorRole.onSurface);

  return MaterialSegmentedButton(
    // The same width divided three ways, for the reason the day/week/month control
    // states: a stretched pill takes the cell, and the three columns divide it.
    width: double.infinity,
    segments: <MaterialSegment>[
      MaterialSegment(
        label: const TextNode('List'),
        icon: glyphList(onSurface, size: MaterialSegmentedButton.iconSize),
        semanticsLabel: 'As a list',
      ),
      MaterialSegment(
        label: const TextNode('Grid'),
        icon: glyphGrid(onSurface, size: MaterialSegmentedButton.iconSize),
        semanticsLabel: 'As a grid',
      ),
      MaterialSegment(
        label: const TextNode('Map'),
        icon: glyphPin(onSurface, size: MaterialSegmentedButton.iconSize),
        semanticsLabel: 'On the map',
      ),
    ],
    selected: chosen,
    onSelect: store.choose,
  );
}

/// Six cards climbing the elevation scale, the two other shapes a card comes in,
/// and two tiled rows.
///
/// Material states elevation twice over: the shadow a surface casts and the tone it
/// is tinted with. A shadow alone is 12% black over a few pixels, so a card raised on
/// the page's own tone reads as flat; each height here takes the pair Material pairs —
/// `level0` on `surfaceContainerLowest` up to `level3` on `surfaceContainerHigh` — which
/// is what makes the climb visible, and what Flutter's own card does with its tint. The
/// palette has five container tones for six heights, so the two highest cards share
/// `surfaceContainerHighest` and the shadow is what tells them apart: level zero, which
/// casts none, is the page's own height and reads as one.
UINode _cards(MaterialPalette palette) {
  return GridNode(
    minItemWidth: 300,
    maxColumns: 3,
    gap: 24,
    children: <UINode>[
      _heightCard(
        palette,
        title: 'Level 0',
        note: 'surfaceContainerLowest · no shadow',
        shadows: MaterialElevation.level0,
        surface: palette.surfaceContainerLowest,
      ),
      _heightCard(
        palette,
        title: 'Level 1',
        note: 'surfaceContainerLow',
        shadows: MaterialElevation.level1,
        surface: palette.surfaceContainerLow,
      ),
      _heightCard(
        palette,
        title: 'Level 2',
        note: 'surfaceContainer',
        shadows: MaterialElevation.level2,
        surface: palette.surfaceContainer,
      ),
      _heightCard(
        palette,
        title: 'Level 3',
        note: 'surfaceContainerHigh',
        shadows: MaterialElevation.level3,
        surface: palette.surfaceContainerHigh,
      ),
      _heightCard(
        palette,
        title: 'Level 4',
        note: 'surfaceContainerHighest',
        shadows: MaterialElevation.level4,
        surface: palette.surfaceContainerHighest,
      ),
      // The tone ladder runs out one rung before the shadow ladder does, so the last
      // card repeats the tone above it: a browser and an app both read the shadow.
      _heightCard(
        palette,
        title: 'Level 5',
        note: 'surfaceContainerHighest · shadow only',
        shadows: MaterialElevation.level5,
        surface: palette.surfaceContainerHighest,
      ),
      // The two shapes a card comes in besides the raised one: a line instead of a
      // shadow, and a tone with neither.
      MaterialCard.outlined(
        width: double.infinity,
        gap: 8,
        padding: const BoxSpacing.all(16),
        color: palette.surface,
        children: <UINode>[
          TextNode('Outlined', style: MaterialTypography.titleMedium),
          _cardNote(palette, 'surface · outlineVariant'),
          MaterialButton.filled(label: const TextNode('Confirm'), onTap: () {}),
        ],
      ),
      MaterialCard.filled(
        width: double.infinity,
        gap: 8,
        padding: const BoxSpacing.all(16),
        color: palette.surfaceContainerHighest,
        children: <UINode>[
          TextNode('Filled', style: MaterialTypography.titleMedium),
          _cardNote(palette, 'surfaceContainerHighest'),
        ],
      ),
      Box(
        width: double.infinity,
        borderRadius: 12,
        border: BoxBorder(color: palette.outlineVariant),
        // The rows are flush with the rounded edge, so the container clips them:
        // without this their hover tint squares off the corners.
        overflow: Overflow.hidden,
        children: <UINode>[
          // The gallery has no destination, so the press is the whole point: a
          // tile that listens leaves ink where it was pressed.
          MaterialListTile(
            onTap: () {},
            leading: TextNode(
              'AL',
              style: MaterialTypography.titleMedium,
              color: palette.primary,
            ),
            title: const TextNode('Ada Lovelace'),
            subtitle: const TextNode('ada@example.com'),
            trailing: TextNode(
              '2m',
              style: MaterialTypography.labelMedium.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
          ),
          MaterialListTile(
            onTap: () {},
            title: const TextNode('Charles Babbage'),
            subtitle: const TextNode('charles@example.com'),
            trailing: TextNode(
              '1h',
              style: MaterialTypography.labelMedium.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// One card of the elevation row: the level it is raised to, the tone Material pairs
/// with it, and the pair written on the card so the catalogue can be read.
UINode _heightCard(
  MaterialPalette palette, {
  required String title,
  required String note,
  required List<BoxShadow> shadows,
  required BoxColor surface,
}) {
  return MaterialCard(
    width: double.infinity,
    gap: 8,
    padding: const BoxSpacing.all(16),
    shadows: shadows,
    color: surface,
    children: <UINode>[
      TextNode(title, style: MaterialTypography.titleMedium),
      _cardNote(palette, note),
    ],
  );
}

/// The line under a card's name: what the card is made of, in the roles the catalogue
/// is drawn with.
UINode _cardNote(MaterialPalette palette, String text) => TextNode(
  text,
  style: MaterialTypography.bodySmall.copyWith(color: palette.onSurfaceVariant),
);

/// The choice of the segmented demo: which segment is on.
final class SegmentedStore extends StateStore<int> {
  /// Creates the demo with the first segment chosen.
  SegmentedStore() : super(0);

  /// Chooses the segment at [index].
  void choose(int index) => state = index;
}

/// A segmented button that keeps what was pressed.
final class SegmentedDemo extends StatefulNode<int, SegmentedStore> {
  /// Creates the demo, with its first segment chosen.
  SegmentedDemo() : super(create: SegmentedStore.new, view: _segmentedView);
}
