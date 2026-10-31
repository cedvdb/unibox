import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../icons.dart';
import '../theme.dart';
import 'section.dart';

/// The third band: the Material library as one node tree — the type scale, the
/// colour roles and the components.
///
/// The band is a demonstration and a claim at once. Every value on it is a `const`
/// in `unibox_material` — no colour is typed into this file — and every component is
/// a node the two renderers already draw, so nothing here is a screenshot.
///
/// It is a band of the page rather than a page of its own: the heading names what
/// the catalogue is, and each block under it is an `h3`, so the page still has one
/// `h1` and four `h2`s above it. Each block is a `section` on the web, so the document
/// says where one demonstration ends — the block has a heading of its own, which is
/// exactly what makes it one.
UINode buildMaterialSection({ExampleSeed seed = ExampleSeed.defaultSeed}) {
  final MaterialPalette palette = ExamplePalette.materialFor(seed);

  return siteBand(
    background: palette.surface,
    child: Box(
      width: double.infinity,
      gap: 48,
      children: <UINode>[
        // The palette the catalogue documents is chosen in the page's header, and every
        // specimen and hex below follows the seed it names.
        siteHeading(
          palette,
          title: 'Material 3, as values and nodes',
          lead:
              'Every component, then the type scale and the colour roles it is '
              'drawn with — all of them nodes the two renderers already draw.',
        ),
        // Components first: they are what a page is built from, and the scale and the
        // palette are what those components name.
        _section(
          palette,
          'Buttons',
          _buttons(),
          note: 'Four shapes around one ink well: press one.',
        ),
        _section(
          palette,
          'Chips',
          _chips(),
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
          'Text fields',
          _fields(palette),
          note: 'The filled field, with its own focus, label and error.',
        ),
        _section(
          palette,
          'Cards and tiles',
          _cards(palette),
          note:
              'All six heights on the surface Material tints to match, the two other '
              'shapes a card comes in, and a row that says who it is.',
        ),
        _section(
          palette,
          'Navigation bar',
          NavigationDemo(),
          note: 'Three destinations; the chosen one sits on a pill.',
        ),
        _section(
          palette,
          'Tabs',
          TabsDemo(palette: palette),
          note:
              'A tab bar over three pages: the bar says which tab is chosen and the '
              'node draws that page.',
        ),
        _section(
          palette,
          'Secondary tabs',
          _secondaryTabs(palette),
          note:
              'The same three tabs packed, each as wide as its label: the underline '
              'is the label\'s own width, not a share of the bar.',
        ),
        _section(
          palette,
          'Pages',
          _pager(palette),
          note:
              'A scrolling box that settles: `snap: ScrollSnap.page` moves one child at '
              'a time. Swipe it sideways.',
        ),
        _section(
          palette,
          'Scaffold',
          _screens(palette),
          note:
              'A screen: `MaterialScaffold` draws a page under a band and a body that fills the '
              'rest — the bar states a container and the page a surface, so the band reads as '
              'one. Scroll either body: the first bar stays, and the second is drawn again at the '
              'height a store hands it, which a document never runs.',
        ),
        _section(
          palette,
          'App bars',
          _appBars(palette),
          note:
              'The band a page opens with, and the one a list scrolls under: '
              '`MaterialAppBar` states the height its slot keeps, the container it paints, and '
              'the `pin` that makes it stay.',
        ),
        _section(
          palette,
          'Dialog',
          DialogDemo(seed: seed),
          note: 'An OverlayNode: in the tree only while it is open.',
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
UINode _buttons() {
  return GridNode(
    minItemWidth: 150,
    maxColumns: 4,
    gap: 16,
    children: <UINode>[
      _natural(
        MaterialButton.filled(label: const TextNode('Filled'), onTap: () {}),
      ),
      _natural(
        MaterialButton.tonal(label: const TextNode('Tonal'), onTap: () {}),
      ),
      _natural(
        MaterialButton.outlined(
          label: const TextNode('Outlined'),
          onTap: () {},
        ),
      ),
      _natural(
        MaterialButton.text(label: const TextNode('Text'), onTap: () {}),
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
UINode _chips() {
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
            label: const TextNode('Two rooms'),
            selected: true,
            onTap: () {},
            leading: MaterialCheckMark(
              color: onSelected,
              size: MaterialChip.iconSize,
            ),
          ),
          MaterialChip(
            label: const TextNode('Studio'),
            onTap: () {},
            leading: glyphGrid(onPlain, size: MaterialChip.iconSize),
          ),
          MaterialChip(
            label: const TextNode('Map'),
            onTap: () {},
            leading: glyphList(onPlain, size: MaterialChip.iconSize),
          ),
          // A chip that cannot be pressed fades rather than shouting: the last
          // state Material gives one.
          MaterialChip(
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

/// Three tabs as wide as their labels, over a page each: what [MaterialTabs] is.
///
/// The primary demo beside it composes a bar and a pager by hand, because a pager needs to
/// know how wide a page is. This one has nothing to compose — a bar that swaps its page is
/// one component — so it is the component itself, and the four-line shape a caller writes.
UINode _secondaryTabs(MaterialPalette palette) {
  return MaterialTabs(
    variant: MaterialTabVariant.secondary,
    palette: palette,
    tabs: const <MaterialTab>[
      MaterialTab(label: TextNode('Overview')),
      MaterialTab(label: TextNode('Listings')),
      MaterialTab(label: TextNode('Reviews')),
    ],
    pages: <UINode>[
      _page(palette, 'Six flats, from the same tree.'),
      _page(palette, 'A map beside them on a wide screen.'),
      _page(palette, 'What the tenants said.'),
    ],
  );
}

/// Three tabs over a pager: pressing a tab slides the page, and swiping a page moves the bar.
///
/// This is what `MaterialTabs` cannot be on its own: a pager needs a page the size of the box, and
/// the size of a tab's page is the layout's business. So the demo composes the two halves — a
/// [MaterialTabBar] and a snapping box — over one store, which is the model's answer to "one state,
/// two views". The index travels into the box as `page`, and back out of it as the offset the box
/// reports, so neither half can disagree with the other.
final class TabsDemo extends StatefulNode<TabsDemoState, TabsDemoStore> {
  /// Creates the demo, with [palette] answering its colour roles.
  factory TabsDemo({MaterialPalette? palette}) => TabsDemo._(
    view: (TabsDemoState state, TabsDemoStore store) => _tabsView(
      state,
      store,
      palette ?? ExamplePalette.materialFor(ExampleSeed.defaultSeed),
    ),
  );

  TabsDemo._({required super.view}) : super(create: TabsDemoStore.new);
}

/// Which tab is chosen, and how wide the tab view is.
///
/// The width is state because it is what turns an offset into a page: a pager reports pixels, and
/// the bar speaks in indices, so something has to know the divisor. Here, because the demo draws a
/// table of a fixed size — the bar, the pager and every page are the same width, which is what puts
/// the page under the tab that shows it and leaves no strip of view narrower than the bar above it.
///
/// A page has to be a number in the tree, and the number has to fit the column the table is drawn
/// in: a phone's band leaves 280 pixels of a 344 pixel window, so the table is a specimen at every
/// width rather than a pager that pushes the page sideways. It was 720, which is wider than a
/// phone, and the whole catalogue scrolled horizontally because of it.
final class TabsDemoState {
  /// Creates a state showing page [selected], in a view [pageWidth] wide.
  const TabsDemoState({this.selected = 0, this.pageWidth = 280});

  /// The index of the chosen tab, which is also the page the pager shows.
  final int selected;

  /// How wide one page, and the bar above it, is in logical pixels.
  final double pageWidth;

  @override
  bool operator ==(Object other) =>
      other is TabsDemoState &&
      other.selected == selected &&
      other.pageWidth == pageWidth;

  @override
  int get hashCode => Object.hash(selected, pageWidth);

  @override
  String toString() => 'TabsDemoState(selected: $selected)';
}

/// The store of [TabsDemo]: one index, from a press or from a swipe.
///
/// It holds the two directions apart, because the pager and the bar are wired to each other. A
/// press chooses a page and the pager *slides* to it, reporting every offset on the way; read as
/// choices, those offsets send the bar back to where the slide started, and the tab that was
/// pressed never appears chosen. So a press leaves a marker behind, and the offsets of the slide
/// it asked for are ignored until the pager arrives. A swipe sets no marker — every offset a
/// reader makes is theirs.
final class TabsDemoStore extends StateStore<TabsDemoState> {
  /// Creates the store on page 0.
  TabsDemoStore() : super(const TabsDemoState());

  /// The page a press sent the pager to, while it is still on its way there.
  int? _sent;

  /// Chooses the tab at [index].
  void choose(int index) {
    final int chosen = index.clamp(0, 2);
    _sent = chosen;
    _select(chosen);
  }

  /// Follows the reader's swipe: the offset becomes the page it landed on.
  ///
  /// Rounded rather than floored, because a swipe that stops three quarters of the way to the next
  /// page settles on it: the bar should say where the pager came to rest, not where it started.
  void scrolledTo(double offset) {
    final int index = (offset / state.pageWidth).round();
    final int? sent = _sent;

    if (sent != null) {
      // Still arriving where a press sent it: an offset between two pages says nothing about
      // what the reader wants, and the one that reaches the page hands the pager back.
      if (index == sent) {
        _sent = null;
      }

      return;
    }

    if (index != state.selected) {
      _select(index);
    }
  }

  /// Shows the page at [index] without claiming the pager is on its way there.
  void _select(int index) =>
      state = TabsDemoState(selected: index, pageWidth: state.pageWidth);
}

/// The bar, then the pager both are looking at.
UINode _tabsView(
  TabsDemoState state,
  TabsDemoStore store,
  MaterialPalette palette,
) {
  const List<String> captions = <String>[
    'Six flats, from the same tree.',
    'A map beside them on a wide screen.',
    'What the tenants said.',
  ];

  return Box(
    // The bar is as wide as the page under it, which is the width the demo states: a page has to
    // be a number in the tree for the pager to land on one, so the bar is given that number too
    // rather than the whole section. Stretched instead, the bar is as wide as the band and the
    // view under the tabs reads as a narrower strip than the row above it.
    width: state.pageWidth,
    gap: 16,
    children: <UINode>[
      MaterialTabBar(
        palette: palette,
        selected: state.selected,
        onSelect: store.choose,
        tabs: const <MaterialTab>[
          MaterialTab(label: TextNode('Overview')),
          MaterialTab(label: TextNode('Listings')),
          MaterialTab(label: TextNode('Reviews')),
        ],
      ),
      Box(
        width: state.pageWidth,
        height: 96,
        direction: Axis.horizontal,
        overflow: Overflow.scroll,
        snap: ScrollSnap.page,
        page: state.selected,
        onScroll: store.scrolledTo,
        borderRadius: 12,
        children: <UINode>[
          for (final (int index, String caption) in captions.indexed)
            Box(
              key: 'page-$index',
              width: state.pageWidth,
              height: 96,
              children: <UINode>[_page(palette, caption)],
            ),
        ],
      ),
    ],
  );
}

/// One page of the tab demo: a line of text on a surface of its own.
///
/// It paints a fill and a hairline rather than sitting on whatever is behind it, because a page
/// whose extent is invisible is a page a reader cannot place: the outline says where the view
/// under the tabs begins and ends, and shows that it is exactly as wide as the row above it.
UINode _page(MaterialPalette palette, String text) {
  return Box(
    width: double.infinity,
    padding: const BoxSpacing.all(20),
    backgroundColor: palette.surfaceContainerLow,
    border: BoxBorder(color: palette.outlineVariant),
    children: <UINode>[
      TextNode(
        text,
        style: MaterialTypography.bodyMedium.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// A pager: a horizontal scrolling box that settles on a child instead of between two.
///
/// The box is exactly one page wide, which is the contract `ScrollSnap.page` states — a page is a
/// child the size of the box. Stated that way, the two targets agree for a reason rather than by
/// luck: CSS snaps to the child's own `scroll-snap-align` edge, and Flutter's page physics snaps to
/// the viewport's, which is the same edge when the two are the same width.
UINode _pager(MaterialPalette palette) {
  const double page = 240;
  const double height = 120;

  return Box(
    width: page,
    height: height,
    direction: Axis.horizontal,
    overflow: Overflow.scroll,
    snap: ScrollSnap.page,
    borderRadius: 12,
    children: <UINode>[
      for (final (int index, String caption) in <String>[
        'One',
        'Two',
        'Three',
      ].indexed)
        Box(
          width: page,
          height: height,
          padding: const BoxSpacing.all(16),
          backgroundColor: index.isEven
              ? palette.secondaryContainer
              : palette.surfaceContainerHigh,
          crossAlign: CrossAlign.center,
          children: <UINode>[
            TextNode(
              caption,
              style: MaterialTypography.headlineSmall.copyWith(
                color: palette.onSecondaryContainer,
              ),
            ),
          ],
        ),
    ],
  );
}

/// Two screens, one per thing a top app bar can do: stay where it is, or give its height back.
///
/// Both are `MaterialScaffold`s, because a scaffold is what a screen is: the page it is drawn on,
/// the band above it in a container of its own, and a body whose scroll a bar can be wired to.
UINode _screens(MaterialPalette palette) {
  return GridNode(
    minItemWidth: 360,
    maxColumns: 2,
    gap: 24,
    children: <UINode>[
      _specimen(
        palette,
        'An app bar that stays',
        _phone(
          palette,
          MaterialScaffold(
            color: _pageColor,
            body: Box(
              height: double.infinity,
              overflow: Overflow.scroll,
              children: <UINode>[
                // The screen's bar is the first child of the body, so it is the box that pins:
                // it comes to rest at the top of the scroll and the list runs under it.
                MaterialAppBar(
                  title: const TextNode('Apartments'),
                  trailing: const TextNode('24'),
                  pin: BoxPin.start,
                ),
                for (final (String name, String price) in _flats)
                  _flatTile(name, price),
              ],
            ),
          ),
        ),
      ),
      _specimen(
        palette,
        'An app bar that gives its height back',
        _phone(palette, CollapsingAppBarDemo()),
      ),
    ],
  );
}

/// The height the catalogue gives a screen, in logical pixels.
///
/// One number for the frame and for the screen inside it, because a `StatefulNode` cannot take a
/// share of the box it is in: it states no style of its own, so a view that said
/// `height: double.infinity` would be laid out in an unbounded column and thrown on. A screen that
/// is a stateful node states the height the panel gives it, and a screen that is a plain box says
/// `double.infinity` — the same rectangle either way.
const double _screenHeight = 420;

/// The page a catalogue screen is drawn on.
///
/// White, which is what the cards around it are painted with. Material's `surface` is a tone below
/// the container a bar paints, and that difference is the whole of what makes a band read as a
/// band — on a card that is itself tinted, a faint difference is not enough to see.
const BoxColor _pageColor = BoxColor.role(
  MaterialColorRole.surfaceContainerLowest,
);

/// The screen-shaped surface a screen is drawn on: as wide as the card, and a stated height.
///
/// The width is the card's, not a number: `double.infinity` here is "fill the column", which is the
/// same sentence on both targets — CSS stretches a grid item and Flutter hands the cell a tight
/// width. A number was what put a 320-pixel phone in the corner of a 450-pixel card.
UINode _phone(MaterialPalette palette, UINode screen) {
  return Box(
    width: double.infinity,
    height: _screenHeight,
    borderRadius: 20,
    border: BoxBorder(color: palette.outlineVariant),
    // The screen's corners are the frame's, so the frame clips it.
    overflow: Overflow.hidden,
    children: <UINode>[screen],
  );
}

/// A screen whose app bar collapses as it scrolls, the way a pinned sliver app bar does.
///
/// It is the model's answer to a *layout* that moves: the scroll is reported by `onScroll`, a store
/// keeps how far it has gone, and the view is drawn again with a bar whose height is the next
/// number. Nothing eases a layout here — the height is a value a rebuild states, not a tween — and
/// that is why this is a node with a store rather than a token.
final class CollapsingAppBarDemo
    extends StatefulNode<CollapsingAppBarState, CollapsingAppBarStore> {
  /// Creates the demo at the top of its list.
  CollapsingAppBarDemo()
    : super(create: CollapsingAppBarStore.new, view: _collapsingScreen);

  /// The height a top app bar opens at, in logical pixels.
  static const double expanded = MaterialLargeAppBar.largeHeight;

  /// The height it comes to rest at: a small app bar's.
  static const double collapsed = MaterialAppBar.topHeight;
}

/// How far the reader has scrolled, as the share of the way the bar has collapsed.
final class CollapsingAppBarState {
  /// Creates the state at [progress], from `0` to `1`.
  const CollapsingAppBarState({this.progress = 0});

  /// The share of the collapse that has happened, from `0` to `1`.
  final double progress;

  @override
  bool operator ==(Object other) =>
      other is CollapsingAppBarState && other.progress == progress;

  @override
  int get hashCode => progress.hashCode;

  @override
  String toString() => 'CollapsingAppBarState(progress: $progress)';
}

/// The store of [CollapsingAppBarDemo]: the scroll offset, as a collapse.
final class CollapsingAppBarStore extends StateStore<CollapsingAppBarState> {
  /// Creates the store at the top of the list.
  CollapsingAppBarStore() : super(const CollapsingAppBarState());

  /// The pixels the bar takes to give its height back.
  static const double range =
      CollapsingAppBarDemo.expanded - CollapsingAppBarDemo.collapsed;

  /// Follows the reader: the offset becomes the share of the collapse it has reached.
  ///
  /// Rounded to a hundredth, so a bar that is redrawn on every published value is redrawn for a
  /// change a reader can see rather than for every sub-pixel of a fling.
  void scrolledTo(double offset) {
    final double progress = (offset / range).clamp(0.0, 1.0);

    state = CollapsingAppBarState(progress: (progress * 100).round() / 100);
  }
}

/// The screen: a bar whose height and title follow the collapse, and the list under it.
///
/// The height is stated, not shared: a `StatefulNode` carries no style, so the renderer has nothing
/// to turn into a flexible child — the view states the room the panel gives it instead of asking
/// for `double.infinity`, which is a number in an unbounded column.
UINode _collapsingScreen(
  CollapsingAppBarState state,
  CollapsingAppBarStore store,
) {
  final double t = state.progress;

  return MaterialScaffold(
    color: _pageColor,
    height: _screenHeight,
    body: Box(
      height: double.infinity,
      overflow: Overflow.scroll,
      onScroll: store.scrolledTo,
      children: <UINode>[
        MaterialLargeAppBar(
          title: const TextNode('Saved'),
          // The two numbers a pinned sliver app bar states: how tall it opens, and how small it
          // comes to rest. Everything between them is the store's.
          height:
              CollapsingAppBarDemo.collapsed +
              (CollapsingAppBarDemo.expanded - CollapsingAppBarDemo.collapsed) *
                  (1 - t),
          padding: BoxSpacing.all(16 - 4 * t),
          pin: BoxPin.start,
          titleStyle: MaterialTypography.headlineMedium.merge(
            BoxTextStyle(fontSize: 28 - 6 * t),
          ),
        ),
        for (final (String name, String price) in _flats)
          _flatTile(name, price),
      ],
    ),
  );
}

/// The two app bars as components: the small one, one with a glyph before its title, and the
/// large one a page opens with.
///
/// The screens above show them in motion — pinned, and giving their height back — but a component
/// is also worth a specimen of its own, the way every other component here has one.
UINode _appBars(MaterialPalette palette) {
  const BoxColor onPlain = BoxColor.role(MaterialColorRole.onSurfaceVariant);

  return GridNode(
    minItemWidth: 280,
    maxColumns: 3,
    gap: 24,
    children: <UINode>[
      _specimen(
        palette,
        'A title, and a node at the end',
        _framed(
          palette,
          MaterialAppBar(
            title: const TextNode('Shortlist'),
            trailing: const TextNode('12'),
          ),
        ),
      ),
      _specimen(
        palette,
        'A glyph before the title',
        _framed(
          palette,
          MaterialAppBar(
            leading: glyphList(onPlain),
            title: const TextNode('Results'),
            trailing: const TextNode('6 of 24'),
          ),
        ),
      ),
      _specimen(
        palette,
        'The large one, with air above its headline',
        _framed(
          palette,
          MaterialLargeAppBar(title: const TextNode('Garden loft')),
        ),
      ),
    ],
  );
}

/// A bar in the surface a page would put it on, so the bar's own colour reads against it.
UINode _framed(MaterialPalette palette, UINode bar) {
  return Box(
    width: double.infinity,
    backgroundColor: palette.surface,
    borderRadius: 12,
    border: BoxBorder(color: palette.outlineVariant),
    // The bar is flush with the rounded edge, so the frame clips it: without this the bar's
    // corners would square off the frame's.
    overflow: Overflow.hidden,
    children: <UINode>[bar],
  );
}

/// A specimen and the line under it, which is what the block is showing.
UINode _specimen(MaterialPalette palette, String caption, UINode child) {
  return Box(
    width: double.infinity,
    gap: 8,
    // The sample fills the specimen: a card is as wide as the column it is in, and a sample that
    // hugged its content would be a component sitting in the corner of its own card.
    crossAlign: CrossAlign.stretch,
    children: <UINode>[
      TextNode(
        caption,
        style: MaterialTypography.labelMedium.copyWith(
          color: palette.onSurfaceVariant,
        ),
      ),
      child,
    ],
  );
}

/// One flat in a panel: a Material list tile, with its rent at the end of the row.
UINode _flatTile(String name, String price) => MaterialListTile(
  title: TextNode(name),
  trailing: TextNode(price, style: MaterialListTile.subtitleTextStyle),
);

/// The flats every specimen scrolls past.
///
/// Eight of them, which is more than a panel is tall: a panel has to be able to scroll past
/// everything in it, or a band cannot reach the edge it pins to and a band cannot leave far
/// enough for its fold to arrive.
const List<(String, String)> _flats = <(String, String)>[
  ('Garden loft', '€1 280'),
  ('Two rooms by the park', '€1 460'),
  ('Studio, sixth floor', '€ 920'),
  ('Attic with a terrace', '€1 700'),
  ('One room in the old town', '€ 860'),
  ('House on the canal', '€2 100'),
  ('Loft over the bakery', '€1 180'),
  ('Chambre de bonne', '€ 640'),
];

/// A segmented button that keeps the choice it was given.
/// The choice is the state: the view puts the segment the store says is chosen into
/// the button, and a press asks for another one — the same shape as the dialog demo,
/// and the reason a segmented button needs no state of its own.
UINode _segmentedView(int chosen, SegmentedStore store) {
  return MaterialSegmentedButton(
    // The width the grid cell gives it, divided three ways. The segments are equal
    // shares either way — the widest label sets all three — and a width is what puts
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
    // states: a stretched pill takes the cell, and the three shares divide it.
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

/// Two fields, one in each of the label's positions, and both validating.
///
/// The pair is a comparison, so the only thing that differs is the value: the first
/// is empty and its label *is* the line, the second starts with the beginning of an
/// address and its label has floated to the top of the fill. Typing in either asks
/// the same validator, so a half finished address turns the line and the message
/// red and finishing it takes both away — the state is the field's, not the page's.
UINode _fields(MaterialPalette palette) {
  const String hint = 'you@example.com';
  const String helper = 'We only use it for the receipt.';
  String? invalidAddress(String value) =>
      value.contains('@') ? null : 'Enter an address with an @';

  return GridNode(
    minItemWidth: 280,
    maxColumns: 2,
    gap: 24,
    children: <UINode>[
      Box(
        width: double.infinity,
        children: <UINode>[
          MaterialTextField(
            width: double.infinity,
            label: 'Email',
            placeholder: hint,
            helper: helper,
            inputType: InputType.email,
            validator: invalidAddress,
          ),
        ],
      ),
      Box(
        width: double.infinity,
        children: <UINode>[
          MaterialTextField(
            width: double.infinity,
            label: 'Email',
            placeholder: hint,
            helper: helper,
            inputType: InputType.email,
            initialValue: 'ada@',
            validator: invalidAddress,
          ),
        ],
      ),
    ],
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

/// The choice of the navigation demo: which destination is the page.
final class NavigationStore extends StateStore<int> {
  /// Creates the demo with the first destination chosen.
  NavigationStore() : super(0);

  /// Goes to the destination at [index].
  void choose(int index) => state = index;
}

/// A navigation bar that keeps the destination it was given.
///
/// The choice is the state, exactly as it is for the segmented button: the view
/// puts the destination the store says is current into the bar, and a press asks
/// for another one. Nothing about the bar changes — only the index.
final class NavigationDemo extends StatefulNode<int, NavigationStore> {
  /// Creates the demo, with its first destination chosen.
  NavigationDemo() : super(create: NavigationStore.new, view: _navigationView);
}

/// The bar, with a picture per destination in the colour its state needs.
UINode _navigationView(int chosen, NavigationStore store) {
  return MaterialNavigationBar(
    destinations: <MaterialNavigationDestination>[
      MaterialNavigationDestination(
        label: const TextNode('Listings'),
        icon: glyphList(MaterialNavigationBar.inactiveIconColor, size: 20),
        selectedIcon: glyphList(
          MaterialNavigationBar.activeIconColor,
          size: 20,
        ),
      ),
      MaterialNavigationDestination(
        label: const TextNode('Map'),
        icon: glyphPin(MaterialNavigationBar.inactiveIconColor, size: 20),
        selectedIcon: glyphPin(MaterialNavigationBar.activeIconColor, size: 20),
      ),
      MaterialNavigationDestination(
        label: const TextNode('Grid'),
        icon: glyphGrid(MaterialNavigationBar.inactiveIconColor, size: 20),
        selectedIcon: glyphGrid(
          MaterialNavigationBar.activeIconColor,
          size: 20,
        ),
      ),
    ],
    selected: chosen,
    onSelect: store.choose,
  );
}

/// The state of the dialog demo: open, or closed.
final class DialogDemoStore extends StateStore<bool> {
  /// Creates the demo with its dialog closed.
  DialogDemoStore() : super(false);

  /// Opens the dialog.
  void open() => state = true;

  /// Closes the dialog.
  void close() => state = false;
}

/// A button that opens a dialog of its own.
///
/// Presence is the state: the view puts the `MaterialDialog` in the tree while
/// [DialogDemoStore] says it is open, and leaves it out when it closes. That is the
/// whole mechanism a dialog needs — the node carries the barrier and the dismissal.
final class DialogDemo extends StatefulNode<bool, DialogDemoStore> {
  /// Creates the demo, with its dialog closed.
  DialogDemo({this.seed = ExampleSeed.defaultSeed})
    : super(
        create: DialogDemoStore.new,
        view: (bool open, DialogDemoStore store) =>
            _dialogView(open, store, ExamplePalette.materialFor(seed)),
      );

  /// The seed the demo is drawn with, which its own tree reads when it is built.
  final ExampleSeed seed;
}

/// The button, the dialog when it is open, and what the section says about it.
UINode _dialogView(bool open, DialogDemoStore store, MaterialPalette palette) {
  // A grid, so the button and the note beside it stack on a narrow window instead
  // of pushing the page sideways.
  return GridNode(
    minItemWidth: 240,
    maxColumns: 3,
    gap: 24,
    children: <UINode>[
      // At its own size, like every control on this page: a grid item fills its track, and
      // this button without a wrapper became a banner whose tint was wider than its label.
      _natural(
        Box(
          backgroundColor: palette.primary,
          borderRadius: 20,
          children: <UINode>[
            MaterialInkWell(
              onTap: store.open,
              borderRadius: 20,
              ink: palette.onPrimary,
              padding: const BoxSpacing.symmetric(horizontal: 20, vertical: 10),
              child: TextNode(
                'Delete listing',
                style: MaterialTypography.labelLarge.copyWith(
                  color: palette.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      Box(
        width: double.infinity,
        children: <UINode>[
          TextNode(
            'Title, content and actions, on the surface a dialog is raised by. The '
            'button is a MaterialInkWell over a filled box, so a press leaves ink; '
            'the dialog is in the tree only while it is open.',
            style: MaterialTypography.labelSmall.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      ),
      if (open)
        MaterialDialog(
          title: 'Delete listing?',
          content: const TextNode('The photos go with it.'),
          actions: <UINode>[
            MaterialButton.text(
              label: const TextNode('Cancel'),
              onTap: store.close,
            ),
            MaterialButton.text(
              label: const TextNode('Delete'),
              onTap: store.close,
            ),
          ],
          onDismiss: store.close,
        ),
    ],
  );
}
