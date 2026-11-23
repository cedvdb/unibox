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
  material.MaterialButton: _button,
  material.MaterialChip: _chip,
  material.MaterialListTile: _listTile,
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
/// A glyph the list does not name is drawn as the *character* it is, from the node's own font
/// family: no `IconData` is built at run time, because one would cost the application its whole
/// icon subsetter. `flutter build` records every `IconData` construction and refuses to subset the
/// fonts when an argument is not a constant — "This application cannot tree shake icons fonts. It
/// has non-constant instances of IconData." — and a codepoint read from a tree is never one. Text
/// draws the same glyph out of the same font; it only loses `Icon`'s ambient `IconTheme`, which
/// this sets from the node.
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

  if (named != null) {
    // A platform icon, not a glyph of text: `Icon` states its own size, follows the ambient
    // `IconTheme`, and is not scaled by the reader's text size — which is what an icon is in an
    // app.
    return Icon(
      named,
      size: text.fontSize,
      color: ink == null ? null : Color(ink.value),
    );
  }

  return Text(
    String.fromCharCode(icon.codePoint ?? 0),
    style: TextStyle(
      // The node's own family: a `MaterialIcon` always names one, so the glyph is drawn from the
      // font the tree asked for rather than whatever the ambient text style happens to use.
      fontFamily: icon.fontFamily,
      fontSize: text.fontSize,
      color: ink == null ? null : Color(ink.value),
    ),
    // The one thing a glyph of text has to be told: an icon does not grow with the reader's text
    // size, and neither did the `Icon` this replaces.
    textScaler: TextScaler.noScaling,
  );
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
  // The line too: an outlined card is a fill *and* a hairline, and `Card` draws a border only
  // when its shape names one. Without it the outlined variant was a card with no edge, while
  // the page drew the line the tree states.
  final core.BoxBorder? border = style.border;

  return Card(
    // The margin the tree states is applied around this widget, by the renderer.
    margin: EdgeInsets.zero,
    elevation: _levelOf(style.shadows).toDouble(),
    color: style.backgroundColor == null
        ? null
        : Color(style.backgroundColor!.value),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(style.borderRadius ?? 0),
      side: border == null || !border.isVisible
          ? BorderSide.none
          : BorderSide(color: Color(border.color.value), width: border.width),
    ),
    clipBehavior: style.overflow == core.Overflow.hidden
        ? Clip.antiAlias
        : Clip.none,
    child: content,
  );
}

Widget _button(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialButton button = node as material.MaterialButton;
  final Widget label = renderNode(button.label);
  final VoidCallback? onPressed = button.enabled ? button.onPressed : null;

  final Widget pill = switch (button.variant) {
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

  // A button is as wide as its label unless the tree states a width — the values draw it that
  // way, and a Material button handed a stretched parent fills it instead. `Align` gives the
  // widget the loose constraints it needs to hug; a stated width is what it fills.
  final double? width = button.fillWidth;

  return width == null
      ? Align(alignment: AlignmentDirectional.centerStart, child: pill)
      : SizedBox(width: width, child: pill);
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
  // The corner and the tap target are the tree's. `FilterChip` rounds itself into a stadium and
  // pads its box to Material's 48 pixel tap target, where the node paints 32 pixels with an 8
  // pixel corner — so a substituted chip was taller and rounder than the page's.
  final core.BoxStyle style = _styleOf(context, chip);
  final OutlinedBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(style.borderRadius ?? 0),
  );

  if (onDeleted != null) {
    return InputChip(
      label: label,
      avatar: avatar,
      deleteIcon: cross,
      onDeleted: onDeleted,
      shape: shape,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    shape: shape,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

Widget _spinner(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialSpinner spinner = node as material.MaterialSpinner;

  return SizedBox(
    width: spinner.size,
    height: spinner.size,
    child: const CircularProgressIndicator(),
  );
}
