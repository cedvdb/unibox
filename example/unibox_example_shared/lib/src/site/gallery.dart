import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The Material library as one node tree: the type scale, the colour roles and the
/// components, drawn by the web renderer like any other page.
///
/// The page is a demonstration and a claim at once. Every value on it is a `const`
/// in `unibox_material` — no colour is typed into this file — and every component is
/// a node the two renderers already draw, so nothing here is a screenshot.
UINode buildMaterialGallery() {
  const MaterialPalette palette = MaterialPalette.light;

  return Box(
    width: double.infinity,
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
        'A button is a box with a state layer: the hover, focus and press tints are '
            'the ink well, painted over the fill so the colour stays, and a press '
            'spreads ink from where it landed. Hold one down to see both.',
        _buttons(palette),
      ),
      _section(
        'Text fields',
        'The filled field: surfaceContainerHighest, a bottom line that thickens and '
            'turns primary on focus, the label inside the fill, and the padding on '
            'the input so the whole field takes focus.',
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
  );
}

/// The name of the package and what the page shows.
UINode _header(MaterialPalette palette) {
  return Box(
    gap: 8,
    children: <UINode>[
      TextNode('Material 3', style: MaterialTypography.displaySmall),
      Box(
        width: 720,
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
    children: <UINode>[
      Box(
        gap: 4,
        children: <UINode>[
          TextNode(title, style: MaterialTypography.titleLarge),
          Box(
            width: 720,
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
        Box(
          direction: Axis.horizontal,
          crossAlign: CrossAlign.start,
          gap: 24,
          children: <UINode>[
            Box(
              width: 180,
              children: <UINode>[
                TextNode(
                  _label(role.name),
                  style: MaterialTypography.labelMedium,
                  color: palette.onSurfaceVariant,
                ),
              ],
            ),
            Box(
              flex: 1,
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

  return Box(
    gap: 16,
    children: <UINode>[
      for (int start = 0; start < roles.length; start += 5)
        Box(
          direction: Axis.horizontal,
          gap: 16,
          children: <UINode>[
            for (final (String name, BoxColor color)
                in roles.skip(start).take(5))
              _swatch(name, color, palette),
          ],
        ),
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
    width: 150,
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
UINode _button(
  String label,
  BoxColor background,
  BoxColor foreground,
  MaterialPalette palette,
) {
  return Box(
    borderRadius: 20,
    backgroundColor: background,
    border: background == palette.surface
        ? BoxBorder(color: palette.outline)
        : null,
    children: <UINode>[
      MaterialInkWell(
        onTap: () {},
        borderRadius: 20,
        ink: foreground,
        padding: const BoxSpacing.symmetric(horizontal: 20, vertical: 10),
        child: TextNode(
          label,
          style: MaterialTypography.labelLarge.copyWith(color: foreground),
        ),
      ),
    ],
  );
}

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
UINode _buttons(MaterialPalette palette) {
  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.center,
    gap: 16,
    children: <UINode>[
      _button('Filled', palette.primary, palette.onPrimary, palette),
      _button(
        'Tonal',
        palette.primaryContainer,
        palette.onPrimaryContainer,
        palette,
      ),
      _button('Outlined', palette.surface, palette.primary, palette),
    ],
  );
}

/// A field at rest and a field that says what is wrong with the value.
UINode _fields(MaterialPalette palette) {
  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.start,
    gap: 24,
    children: <UINode>[
      Box(
        width: 320,
        children: <UINode>[
          MaterialTextField(
            width: double.infinity,
            label: 'Email',
            placeholder: 'you@example.com',
            inputType: InputType.email,
          ),
        ],
      ),
      Box(
        width: 320,
        children: <UINode>[
          MaterialTextField(
            width: double.infinity,
            label: 'Email',
            placeholder: 'you@example.com',
            value: 'ada@',
            invalid: true,
            message: 'Enter a complete address.',
          ),
        ],
      ),
    ],
  );
}

/// A card with a call to action, and two tiled rows.
UINode _cards(MaterialPalette palette) {
  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.start,
    gap: 24,
    children: <UINode>[
      MaterialCard(
        width: 360,
        gap: 8,
        children: <UINode>[
          TextNode('Order summary', style: MaterialTypography.titleLarge),
          TextNode(
            'Two nights, one room. Check-in on Friday.',
            style: MaterialTypography.bodyMedium.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
          _button('Confirm', palette.primary, palette.onPrimary, palette),
        ],
      ),
      Box(
        flex: 1,
        borderRadius: 12,
        border: BoxBorder(color: palette.outlineVariant),
        children: <UINode>[
          MaterialListTile(
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

  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.start,
    gap: 24,
    children: <UINode>[
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
      Box(
        width: 320,
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
            _dialogAction('Cancel', store.close, palette),
            _dialogAction('Delete', store.close, palette),
          ],
          onDismiss: store.close,
        ),
    ],
  );
}

/// One action of the dialog: a label with an ink well over it.
UINode _dialogAction(String label, TapCallback onTap, MaterialPalette palette) {
  return Box(
    borderRadius: 20,
    children: <UINode>[
      MaterialInkWell(
        onTap: onTap,
        borderRadius: 20,
        ink: palette.primary,
        padding: const BoxSpacing.symmetric(horizontal: 12, vertical: 8),
        child: TextNode(
          label,
          style: MaterialTypography.labelLarge.copyWith(color: palette.primary),
        ),
      ),
    ],
  );
}
