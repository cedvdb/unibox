import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import '../icons.dart';

/// The Material library as one node tree: the type scale, the colour roles and the
/// components, drawn by the web renderer like any other page.
///
/// The page is a demonstration and a claim at once. Every value on it is a `const`
/// in `unibox_material` — no colour is typed into this file — and every component is
/// a node the two renderers already draw, so nothing here is a screenshot.
UINode buildMaterialGallery() {
  const MaterialPalette palette = MaterialPalette.light;

  // A measure, not the window: the gallery is a catalogue, and a paragraph or a row of
  // buttons stretched across a 27 inch screen is unreadable however well it renders.
  // The column is centred in whatever width the page is given, and fills a phone.
  return Box(
    width: double.infinity,
    direction: Axis.horizontal,
    mainAlign: MainAlign.center,
    children: <UINode>[
      Box(
        width: double.infinity,
        maxWidth: 960,
        padding: const BoxSpacing.symmetric(horizontal: 32, vertical: 32),
        gap: 48,
        children: <UINode>[
          _header(palette),
          _section(
            'Type scale',
            'The fifteen roles as const BoxTextStyle values. A box passes one down; a '
                'text names the one it wants.',
            _typeScale(),
          ),
          _section(
            'Colour roles',
            'MaterialPalette.light and .dark: the roles as const BoxColor values, read '
                'when the tree is built rather than looked up at render time.',
            _palette(palette),
          ),
          _section(
            'Buttons',
            'A MaterialButton is a fill around the ink well, so the hover, focus and '
                'press tints paint over the colour rather than replacing it, and a press '
                'spreads ink from where it landed. Hold one down to see both.',
            _buttons(),
          ),
          _section(
            'Chips',
            'A filter chip is one choice: a 32 pixel pill, filled with '
                'secondaryContainer when it is chosen and outlined when it is not, with '
                'a node in front of the label. An input chip adds a close — onRemove '
                'gives the cross a round 18 pixel target of its own, so a press on it '
                'removes the chip instead of choosing it.',
            _chips(),
          ),
          _section(
            'Segmented buttons',
            'Two to five choices in one 40 pixel pill at radius 20: a shared outline, a '
                '1 pixel rule between the segments, an equal share of the width for '
                'each, and the chosen one filled with secondaryContainer and announced '
                'as selected. The chosen segment trades its icon for Material\'s check '
                '— two bars, drawn from boxes because a font is a host asset — so a '
                'control of pictures still says which one is on.',
            _segments(),
          ),
          _section(
            'Text fields',
            'The filled field: surfaceContainerHighest, a bottom line that thickens and '
                'turns primary on focus, the label on the line while it is empty and at '
                'the top of the fill once it is not. Type in either field: the state is '
                "the field's, so a half finished address says so, and finishing it stops.",
            _fields(palette),
          ),
          _section(
            'Cards and tiles',
            'A card is a box with the Material surface, radius and elevation; a list tile '
                'is a box with a leading, a title, an optional supporting text and a '
                'trailing node.',
            _cards(palette),
          ),
          _section(
            'Dialog',
            'A dialog is an OverlayNode rather than a call: it is in the tree only while '
                'the state says it is open, it covers the page behind a barrier and leaves '
                'on Escape or a press on the barrier. Press the button.',
            DialogDemo(),
          ),
        ],
      ),
    ],
  );
}

/// The name of the package and what the page shows.
UINode _header(MaterialPalette palette) {
  return Box(
    gap: 8,
    children: <UINode>[
      // The page has exactly one h1, and this is it: a crawler and a screen reader
      // build the outline from the headings, and a document without one reads as an
      // untitled fragment.
      TextNode(
        'Material 3',
        style: MaterialTypography.displaySmall,
        headingLevel: 1,
      ),
      Box(
        width: double.infinity,
        maxWidth: 720,
        children: <UINode>[
          TextNode(
            'The fifteen type roles, the colour roles and the components of '
            'Material 3, written as values and nodes. Both renderers draw them '
            'from the same tree.',
            style: MaterialTypography.bodyLarge,
            color: palette.onSurfaceVariant,
          ),
        ],
      ),
    ],
  );
}

/// A titled block of the gallery.
UINode _section(String title, String description, UINode content) {
  const MaterialPalette palette = MaterialPalette.light;

  return Box(
    width: double.infinity,
    gap: 16,
    // The blocks of a section fill it: a tile, a field or a row of chips is as wide
    // as the section, which is also what makes a `width: double.infinity` inside one
    // mean the same thing in Flutter and in a browser.
    crossAlign: CrossAlign.stretch,
    children: <UINode>[
      Box(
        gap: 4,
        children: <UINode>[
          // A section title is an `h2`: the page has one `h1` and everything below it,
          // which is the outline a crawler and a screen reader both read.
          TextNode(
            title,
            style: MaterialTypography.titleLarge,
            headingLevel: 2,
          ),
          Box(
            width: double.infinity,
            maxWidth: 720,
            children: <UINode>[
              TextNode(
                description,
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
UINode _typeScale() {
  const MaterialPalette palette = MaterialPalette.light;

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
      MaterialButton.filled(label: const TextNode('Filled'), onTap: () {}),
      MaterialButton.tonal(label: const TextNode('Tonal'), onTap: () {}),
      MaterialButton.outlined(label: const TextNode('Outlined'), onTap: () {}),
      MaterialButton.text(label: const TextNode('Text'), onTap: () {}),
    ],
  );
}

/// The two controls that pick from a small set.
///
/// The chips show the three shapes Material gives one: a chosen chip with a check in
/// front, a plain one, and an input chip whose cross removes it. The glyphs are drawn
/// by `icons.dart`, because an icon font is an asset the example does not ship.
/// The two kinds of chip: a filter, and one that can be closed.
///
/// Each group keeps its children at their natural size, so a chip never stretches
/// into the space its grid track has: the tracks fold to one column on a phone.
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
        // Four chips need more than the width one cell of this grid holds on a phone,
        // and a chip is a control with a fixed size: the row scrolls rather than
        // pushing the page sideways, which is what the listings page does with its
        // cards and what `Overflow.scroll` means on both targets.
        overflow: Overflow.scroll,
        children: <UINode>[
          MaterialChip(
            label: const TextNode('Two rooms'),
            selected: true,
            onTap: () {},
            // Material's chip glyph is 18, and the check is drawn rather than set:
            // a font is a host asset and this package ships none.
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
          // A chip that cannot be pressed fades rather than shouting: the last state
          // Material gives one.
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
    // The same reason as the row of filter chips above: two pills and their crosses
    // are wider than a phone's cell, so the row scrolls instead of widening the page.
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
///
/// The choice is the state: the view puts the segment the store says is chosen into
/// the button, and a press asks for another one — the same shape as the dialog demo,
/// and the reason a segmented button needs no state of its own.
UINode _segmentedView(int chosen, SegmentedStore store) {
  return MaterialSegmentedButton(
    // The width the grid cell gives it, divided three ways. Without one each segment
    // hugs its label while the outline still takes the cell — a 40 pixel pill with
    // two thirds of it empty, which is the one thing a segmented button never is.
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
    // states: a stretched pill whose segments hug is a pill with room to spare.
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

/// A card with a call to action, and two tiled rows.
UINode _cards(MaterialPalette palette) {
  return GridNode(
    minItemWidth: 320,
    maxColumns: 2,
    gap: 24,
    children: <UINode>[
      MaterialCard(
        width: double.infinity,
        gap: 8,
        children: <UINode>[
          TextNode('Order summary', style: MaterialTypography.titleLarge),
          TextNode(
            'Two nights, one room. Check-in on Friday.',
            style: MaterialTypography.bodyMedium.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
          MaterialButton.filled(label: const TextNode('Confirm'), onTap: () {}),
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
  DialogDemo() : super(create: DialogDemoStore.new, view: _dialogView);
}

/// The button, the dialog when it is open, and what the section says about it.
UINode _dialogView(bool open, DialogDemoStore store) {
  const MaterialPalette palette = MaterialPalette.light;

  // A grid, so the button and the note beside it stack on a narrow window instead
  // of pushing the page sideways.
  return GridNode(
    minItemWidth: 240,
    maxColumns: 3,
    gap: 24,
    children: <UINode>[
      // The component, not a hand-rolled copy of it: a button already knows how to
      // keep its fill and its ink the size of its label.
      MaterialButton.filled(
        label: const TextNode('Delete listing'),
        onTap: store.open,
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
