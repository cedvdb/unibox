import 'package:material_ui/material_ui.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
// Prefixed because Flutter's material library still exports a `material.MaterialButton`, and the
// design system's button is the one a node names.
import 'package:unibox_material/unibox_material.dart' as material;

/// The components this package draws with Flutter's own widgets.
///
/// The tree still describes the screen — a card states its surface, its radius and what it
/// holds; a bar states its destinations and which one is the page — and the document built
/// from the same tree draws those values. Here the *application* says that two of them are
/// drawn by Flutter instead, because a widget carries what a token cannot: the platform's
/// ink, its click, the reader's text scale, and the accessibility work the framework has
/// already done.
///
/// What that costs is the pixel the two renderings shared. A card's shadow is Flutter's
/// ladder rather than the design file's, a bar's indicator is the SDK's size rather than the
/// model's, and a screen whose reveal depends on the bar matching the document should be
/// served as a document instead of taken over. What it may never cost is the information:
/// the same words, in the same order, announced the same way.
///
/// The map is one value an application builds once and hands to `renderFlutter`.
///
/// **Experimental, and small on purpose.** It maps the two components this workspace has the
/// most to learn from — a card, whose shadow Flutter paints its own way, and a bar, whose
/// indicator size is the SDK's — and it will grow a component at a time, if it grows at all:
/// every entry is a place the page and the application are allowed to differ. The signature may
/// move while that question settles.
UniboxSubstitutions materialComponents({
  List<IconData> icons = const <IconData>[],
}) => UniboxSubstitutions(<Type, NodeSubstitution>{
  material.MaterialCard: _card,
  material.MaterialNavigationBar: _navigationBar,
  material.MaterialButton: _button,
  material.MaterialChip: _chip,
  material.MaterialListTile: _listTile,
  material.MaterialSegmentedButton: _segmentedButton,
  material.MaterialTabBar: _tabBar,
  material.MaterialTextField: _textField,
  material.MaterialSpinner: _spinner,
  material.MaterialIconButton: _iconButton,
  material.MaterialProgressRing: _progressRing,
  material.MaterialIcon: (BuildContext c, core.UINode n, Widget? w) =>
      _icon(c, n, w, icons),
});

/// The tokens [node] resolves to under the theme in force.
///
/// A substitution receives the node, not the declarations the renderer had worked out, so
/// it resolves them the way the renderer does: the bags, the flat parameters and the theme
/// that answers the colour roles.
core.BoxStyle _styleOf(BuildContext context, core.Box node) => node
    .computedStyle
    .resolve(UniboxScopeWidget.of(context).theme ?? core.UniboxTheme.none);

/// An icon, drawn with the platform's own widget.
///
/// [icons] is the host's own list of `IconData`, and it is the reason this parameter exists: the
/// icon subsetter keeps a glyph only while an `IconData` naming it is part of the application's
/// program, and a codepoint read out of one (`Icons.sell.codePoint`) is folded to an integer and
/// dropped. Passing the values means the mapping *uses* them, so every glyph in the list ships —
/// and the widget is handed a compile-time constant, which is what `IconData` asks for.
///
/// A glyph the list does not name is still drawn, from an `IconData` built at run time, with the
/// caveat written where it belongs: the font may not contain it.
Widget _icon(
  BuildContext context,
  core.UINode node,
  Widget? content,
  List<IconData> icons,
) {
  final material.MaterialIcon icon = node as material.MaterialIcon;
  final core.BoxStyle style = _styleOf(context, icon);
  final core.BoxTextStyle text = style.textStyle ?? const core.BoxTextStyle();
  final core.BoxColor? ink = text.color;

  // A platform icon, not a glyph of text: `Icon` states its own size, follows the ambient
  // `IconTheme`, and is not scaled by the reader's text size — which is what an icon is in an
  // app. It draws the node's codepoint and family, so the two renderings still say the same
  // thing; only the *shape* of the mark is the platform's.
  //
  // The font still has to be in the binary: Flutter subsets an icon font to the glyphs a const
  // `IconData` in the application names, and the codepoint here is a run-time value. That is the
  // host's side of the bargain, and the reason an application reads its codepoints from
  // `Icons.*` rather than writing literals.
  // The node's codepoint, as the host named it if it did. `IconData` requires a constant, so the
  // list is the only way to hand `Icon` one it can keep — see the note on this function.
  IconData? named;
  for (final IconData known in icons) {
    if (known.codePoint == icon.codePoint &&
        known.fontFamily == icon.fontFamily) {
      named = known;
      break;
    }
  }

  return Icon(
    named ?? _unnamed(icon),
    size: text.fontSize,
    color: ink == null ? null : Color(ink.value),
  );
}

/// The `IconData` a node names.
///
/// `IconData`'s family has to be a compile-time constant, so the two fonts the model names are
/// stated here. `MaterialIcons` is named rather than left to `IconData`'s default: the default is
/// Flutter's, and a platform fork that defaults to no family draws the glyph out of whatever font
/// the text happens to use — and compares unequal to the `Icons.*` constant the same glyph is.
/// A host that ships a third icon font maps this node itself — which is the substitution the map
/// is for.
IconData _materialIcons(int codePoint) => IconData(
  // ignore: non_const_argument_for_const_parameter
  codePoint,
  fontFamily: 'MaterialIcons',
);

IconData _symbols(int codePoint) =>
    // ignore: non_const_argument_for_const_parameter
    IconData(codePoint, fontFamily: 'Material Symbols Outlined');

IconData _unnamed(material.MaterialIcon icon) {
  final int codePoint = icon.codePoint ?? 0;

  return icon.fontFamily == material.MaterialIcon.defaultFontFamily
      ? _symbols(codePoint)
      : _materialIcons(codePoint);
}

Widget _card(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialCard card = node as material.MaterialCard;
  final core.BoxStyle style = _styleOf(context, card);

  // Structure, not paint — but the level *is* structure: a card at level 3 is not a card at
  // level 1. Material spends a level twice, as a shadow and as a tint of the surface, so the
  // widget is given the level and left to draw both its own way.
  //
  // The corner, the fill and the clip are the tree's, not `CardTheme`'s: the node states a
  // radius and a colour role, and `overflow: hidden` on a card is a decision about what a
  // press may paint over — a ripple that spills past a rounded corner is the same card drawn
  // two ways. Without these three, a substituted card is Flutter's card, in Flutter's colour,
  // with a square clip.
  return Card(
    // The margin the tree states is applied around this widget, by the renderer.
    margin: EdgeInsets.zero,
    elevation: _levelOf(style.shadows).toDouble(),
    color: style.backgroundColor == null
        ? null
        : Color(style.backgroundColor!.value),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(style.borderRadius ?? 0),
    ),
    clipBehavior: style.overflow == core.Overflow.hidden
        ? Clip.antiAlias
        : Clip.none,
    child: content,
  );
}

Widget _navigationBar(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialNavigationBar bar =
      node as material.MaterialNavigationBar;

  // The destinations are information; the surface, the indicator and the height are the
  // theme's, so the bar is Flutter's own and its colours arrive the way Material sends them.
  return NavigationBar(
    selectedIndex: bar.selected,
    onDestinationSelected: bar.onSelect,
    destinations: <NavigationDestination>[
      for (final material.MaterialNavigationDestination destination
          in bar.destinations)
        NavigationDestination(
          icon: destination.icon == null
              ? const SizedBox.shrink()
              : renderNode(destination.icon!),
          selectedIcon: destination.selectedIcon == null
              ? null
              : renderNode(destination.selectedIcon!),
          label: _labelOf(destination),
        ),
    ],
  );
}

/// The words a destination says.
///
/// A platform bar takes a `String`, so a destination whose label is a picture or a box
/// cannot be handed to one — that is one of the approximations a substitution accepts, and
/// it is why a label in this tree is a line of text.
String _labelOf(material.MaterialNavigationDestination destination) {
  final String? spoken = destination.semanticsLabel;

  if (spoken != null) {
    return spoken;
  }

  final core.UINode label = destination.label;

  return label is core.TextNode ? label.text : '';
}

Widget _button(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialButton button = node as material.MaterialButton;
  final Widget label = renderNode(button.label);
  final VoidCallback? onPressed = button.enabled ? button.onPressed : null;

  return switch (button.variant) {
    material.MaterialButtonVariant.filled => FilledButton(
      onPressed: onPressed,
      child: label,
    ),
    material.MaterialButtonVariant.tonal => FilledButton.tonal(
      onPressed: onPressed,
      child: label,
    ),
    material.MaterialButtonVariant.outlined => OutlinedButton(
      onPressed: onPressed,
      child: label,
    ),
    material.MaterialButtonVariant.text => TextButton(
      onPressed: onPressed,
      child: label,
    ),
  };
}

/// The elevation level a card states, `0` to `5`, read from the shadow ladder it names.
int _levelOf(List<core.BoxShadow>? shadows) {
  if (shadows == null || shadows.isEmpty) {
    return 0;
  }

  const List<List<core.BoxShadow>> ladder = <List<core.BoxShadow>>[
    material.MaterialElevation.level0,
    material.MaterialElevation.level1,
    material.MaterialElevation.level2,
    material.MaterialElevation.level3,
    material.MaterialElevation.level4,
    material.MaterialElevation.level5,
  ];

  for (int level = 0; level < ladder.length; level++) {
    if (ladder[level] == shadows) {
      return level;
    }
  }

  return 1;
}

Widget _chip(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialChip chip = node as material.MaterialChip;
  final Widget label = renderNode(chip.label);
  final VoidCallback? onDeleted = chip.onDeleted;
  // What the chip carries is information: the glyph before the label, and the cross after it.
  final Widget? avatar = chip.leading == null
      ? null
      : renderNode(chip.leading!);
  final Widget? cross = chip.trailing == null
      ? null
      : renderNode(chip.trailing!);

  // A chip with a cross is the input chip; one without is a choice, and a chip that says it
  // is chosen is a filter. Those are the three Material draws, and the node says which it is
  // by what it carries.
  if (onDeleted != null) {
    return InputChip(
      label: label,
      avatar: avatar,
      deleteIcon: cross,
      onDeleted: onDeleted,
      // A chip whose whole pill drops the filter answers it too, as the node states it: the
      // cross is the second way to the same end, not the only one.
      onPressed: chip.onSelected,
    );
  }

  return FilterChip(
    label: label,
    avatar: avatar,
    // The node drew its own glyph for a chosen chip; Flutter's checkmark would be a second one.
    showCheckmark: false,
    selected: chip.selected,
    onSelected: chip.onSelected == null ? null : (bool _) => chip.onSelected!(),
  );
}

Widget _iconButton(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialIconButton button =
      node as material.MaterialIconButton;
  final Widget icon = renderNode(button.icon);

  return IconButton(
    onPressed: button.onPressed,
    tooltip: button.label,
    icon: icon,
  );
}

Widget _progressRing(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialProgressRing ring =
      node as material.MaterialProgressRing;

  return SizedBox(
    width: ring.size,
    height: ring.size,
    child: CircularProgressIndicator(
      value: ring.determinate ? ring.value.clamp(0, 1).toDouble() : null,
      strokeWidth: ring.thickness,
      semanticsLabel: ring.label,
    ),
  );
}

/// A [ThemeData] built from [palette]: the one source of truth for the widgets a
/// substitution draws.
///
/// The widgets this package swaps in — `FilledButton`, `FilterChip`, `NavigationBar`,
/// `CircularProgressIndicator` — read their colours from `ColorScheme` and their type from
/// `TextTheme`, not from the node they replaced. Without this they take Flutter's baseline
/// scheme (the `6750A4` purple family), and the page and the app disagree about a design
/// that only ever had one answer.
///
/// It is built role by role from the palette rather than from a seed, so the values are the
/// ones the tree is drawn with: no second run of the colour algorithm, and no two versions of
/// `material_color_utilities` to keep in step. The roles a `ColorScheme` names that this
/// palette does not — `tertiary`, `inverseSurface`, `onErrorContainer` — keep Flutter's own
/// defaults, and are written down here rather than left to be discovered.
ThemeData materialThemeData(
  material.MaterialPalette palette, {
  String? fontFamily,
  material.MaterialDensity density = material.MaterialDensity.standard,
}) {
  Color of(core.BoxColor color) => Color(color.value);

  return ThemeData(
    fontFamily: fontFamily,
    // The density the tree was built at, handed to Flutter so its widgets draw the same
    // control the node drew. The model states it (from the platform the host is), so this is
    // Flutter following the model rather than the model following Flutter.
    visualDensity: switch (density) {
      material.MaterialDensity.standard => VisualDensity.standard,
      material.MaterialDensity.compact => VisualDensity.compact,
    },
    // Density is Flutter's own answer and is left alone: `adaptivePlatformDensity` is
    // `compact` on a desk and a browser and `standard` on a phone, so a control the app draws
    // is 32 high on the web and 40 on a phone. That is a fact our side should follow rather
    // than override — which is why the tree's own heights need to learn about density (see
    // the README): until they do, a substituted button is 8 pixels shorter than the drawn one
    // on a desktop, and the comparison page is where that shows.
    colorScheme: ColorScheme(
      brightness: palette.colorScheme == core.BoxColorScheme.dark
          ? Brightness.dark
          : Brightness.light,
      primary: of(palette.primary),
      onPrimary: of(palette.onPrimary),
      primaryContainer: of(palette.primaryContainer),
      onPrimaryContainer: of(palette.onPrimaryContainer),
      secondary: of(palette.secondary),
      onSecondary: of(palette.onSecondary),
      secondaryContainer: of(palette.secondaryContainer),
      onSecondaryContainer: of(palette.onSecondaryContainer),
      error: of(palette.error),
      onError: of(palette.onError),
      surface: of(palette.surface),
      onSurface: of(palette.onSurface),
      onSurfaceVariant: of(palette.onSurfaceVariant),
      surfaceContainerLowest: of(palette.surfaceContainerLowest),
      surfaceContainerLow: of(palette.surfaceContainerLow),
      surfaceContainer: of(palette.surfaceContainer),
      surfaceContainerHigh: of(palette.surfaceContainerHigh),
      surfaceContainerHighest: of(palette.surfaceContainerHighest),
      outline: of(palette.outline),
      outlineVariant: of(palette.outlineVariant),
      scrim: of(palette.scrim),
    ),
  );
}

Widget _listTile(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialListTile tile = node as material.MaterialListTile;

  // A tile paints its ink on the nearest `Material`, so a fill behind it — and a box in a
  // tree usually has one — would hide the splash and grey the tile Flutter's default way.
  // A transparent material is Flutter's own answer: the tile keeps its own layer, and the
  // box behind it still states the colour.
  return Material(
    type: MaterialType.transparency,
    child: ListTile(
      title: renderNode(tile.title),
      subtitle: tile.subtitle == null ? null : renderNode(tile.subtitle!),
      leading: tile.leading == null ? null : renderNode(tile.leading!),
      trailing: tile.trailing == null ? null : renderNode(tile.trailing!),
      dense: tile.dense,
      onTap: tile.onPressed,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
  );
}

Widget _textField(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialTextField field = node as material.MaterialTextField;

  // Vanilla on purpose: the field is Flutter's own, with the label, the hint and the message
  // the node states — its chrome is the widget's, which is what a substitution is for.
  return TextField(
    enabled: field.enabled,
    obscureText: field.obscureText,
    maxLines: field.multiline ? null : 1,
    decoration: InputDecoration(
      // The node's field is filled, with a line under it; Flutter states the same shape with
      // these two, and an outlined field is the `border` that states a box instead.
      filled: true,
      border: const UnderlineInputBorder(),
      labelText: field.label,
      hintText: field.placeholder,
      helperText: field.helper,
      errorText: field.error,
    ),
  );
}

Widget _spinner(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialSpinner spinner = node as material.MaterialSpinner;

  return SizedBox(
    width: spinner.size,
    height: spinner.size,
    child: const CircularProgressIndicator(),
  );
}

Widget _tabBar(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialTabBar bar = node as material.MaterialTabBar;

  // The strip is the half of a tab set a node states on its own: the pages beside it are the
  // tree's. A `TabBar` needs a controller, so one is made for it here.
  return DefaultTabController(
    length: bar.tabs.length,
    initialIndex: bar.selected,
    child: TabBar(
      onTap: bar.onSelect,
      // The node's indicator is as wide as the tab, not as the label.
      indicatorSize: TabBarIndicatorSize.tab,
      tabs: <Widget>[
        for (final material.MaterialTab tab in bar.tabs)
          Tab(
            text: tab.label is core.TextNode
                ? (tab.label as core.TextNode).text
                : null,
            icon: tab.icon == null ? null : renderNode(tab.icon!),
          ),
      ],
    ),
  );
}

Widget _segmentedButton(
  BuildContext context,
  core.UINode node,
  Widget? content,
) {
  final material.MaterialSegmentedButton pill =
      node as material.MaterialSegmentedButton;

  // A row that stretches its children hands this a taller box than the control's own height,
  // and `SegmentedButton` then paints its segments at the top of it — leaving the selection
  // fill short of the pill's edge. The height the node states is the height it gets.
  // `Align` first, so the widget is not stretched to the row's height: a tight height makes
  // `SizedBox` meaningless, and a `SegmentedButton` in a taller box paints its selection at the
  // top of it. Loose constraints, then the control's own height.
  //
  // The width is the document's rule, read off the constraints a scroll gives it: a grid with
  // `width: 100%` fills a parent that bounds it and falls back to its own columns in one that
  // sizes to content. So the pill expands where it is bounded — a half-width column it would
  // otherwise overflow and be cut in — and hugs where it is not. A `SegmentedButton` told to
  // expand inside a scrolling row lays out at an infinite width and throws.
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) => Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: pill.density.adjust(
          material.MaterialSegmentedButton.controlHeight,
        ),
        child: SegmentedButton<int>(
          segments: <ButtonSegment<int>>[
            for (int i = 0; i < pill.segments.length; i++)
              ButtonSegment<int>(
                value: i,
                label: renderNode(pill.segments[i].label),
                icon: pill.segments[i].icon == null
                    ? null
                    : renderNode(pill.segments[i].icon!),
              ),
          ],
          selected: <int>{pill.selected},
          onSelectionChanged: pill.onSelect == null
              ? null
              : (Set<int> chosen) => pill.onSelect!(chosen.first),
          showSelectedIcon: pill.showSelectedIcon,
          expandedInsets: constraints.hasBoundedWidth ? EdgeInsets.zero : null,
        ),
      ),
    ),
  );
}
