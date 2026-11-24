import 'package:material_ui/material_ui.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
// Prefixed because Flutter's material library still exports a `material.MaterialButton`, and the
// design system's button is the one a node names.
import 'package:unibox_material/unibox_material.dart' as material;

/// Native widgets for every retained Material declaration.
///
/// Hosts supply const icon values to preserve font tree shaking. The declarations
/// remain useful server HTML; Flutter never falls back to a custom Material control.
UniboxSubstitutions materialComponents({
  List<IconData> icons = const <IconData>[],
}) => UniboxSubstitutions(<Type, NodeSubstitution>{
  material.MaterialCard: _card,
  material.MaterialButton: _button,
  material.MaterialChip: _chip,
  material.MaterialSegmentedButton: _segmentedButton,
  material.MaterialIconButton: _iconButton,
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
      semanticLabel: icon.semantics?.label,
      size: text.fontSize,
      color: ink == null ? null : Color(ink.value),
    );
  }

  throw StateError(
    'Register the icon\'s const IconData in materialComponents(icons: ...).',
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
  return Card(
    // The margin the tree states is applied around this widget, by the renderer.
    margin: EdgeInsets.zero,
    elevation: _levelOf(style.shadows).toDouble(),
    color: style.backgroundColor == null
        ? null
        : Color(style.backgroundColor!.value),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(style.borderRadius ?? 0),
      side: style.border == null || !style.border!.isVisible
          ? BorderSide.none
          : BorderSide(
              width: style.border!.width,
              color: Color(style.border!.color.value),
            ),
    ),
    clipBehavior: style.overflow == core.Overflow.hidden
        ? Clip.antiAlias
        : Clip.none,
    child: content,
  );
}

VoidCallback? _action(
  BuildContext context,
  bool enabled,
  VoidCallback? callback,
  String? url,
) {
  if (!enabled) return null;
  if (callback != null) return callback;
  if (url == null) return null;
  final FlutterLinkOpener? open = FlutterLinkScope.maybeOf(context);
  if (open == null) {
    throw StateError('A native destination needs FlutterLinkScope.');
  }
  return () {
    open(url);
  };
}

/// The state layers a substituted control paints, in the palette's own colours.
///
/// A document paints a hover as `hoverLayer`, a keyboard focus as `focusLayer` and a press as
/// `pressedLayer` — one shade of `onSurface`, whatever a control's fill is. Flutter's own
/// buttons derive theirs from the *foreground* instead, so a filled button lightens with
/// `onPrimary` on one target while the page darkens it with `onSurface`: the same control in
/// two colours, which is what a page that holds the two renderings side by side shows.
/// Handing the widget the palette's layers is what makes one declaration one hover.
///
/// `null` for a theme that states no layers: a host that supplies its own theme keeps the
/// platform's own ink rather than being given a colour no palette named.
WidgetStateProperty<Color?>? _overlay(BuildContext context) {
  final core.UniboxTheme theme =
      UniboxScopeWidget.of(context).theme ?? core.UniboxTheme.none;
  final Color? hover = _layerOf(theme, material.MaterialColorRole.hoverLayer);
  final Color? focus = _layerOf(theme, material.MaterialColorRole.focusLayer);
  final Color? pressed = _layerOf(
    theme,
    material.MaterialColorRole.pressedLayer,
  );

  if (hover == null || focus == null || pressed == null) {
    return null;
  }

  return WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return null;
    if (states.contains(WidgetState.pressed)) return pressed;
    if (states.contains(WidgetState.hovered)) return hover;
    if (states.contains(WidgetState.focused)) return focus;
    return null;
  });
}

/// The colour [role] resolves to under [theme], or `null` when it states none.
Color? _layerOf(core.UniboxTheme theme, material.MaterialColorRole role) {
  final core.BoxColor? colour = theme.colorOf(role);

  return colour == null ? null : Color(colour.value);
}

TextStyle _labelStyle(core.BoxTextStyle text) => TextStyle(
  fontSize: text.fontSize,
  fontFamily: text.fontFamily,
  fontWeight: switch (text.fontWeight) {
    core.FontWeight.light => FontWeight.w300,
    core.FontWeight.normal => FontWeight.w400,
    core.FontWeight.medium => FontWeight.w500,
    core.FontWeight.semiBold => FontWeight.w600,
    core.FontWeight.bold => FontWeight.w700,
    null => null,
  },
  height: text.lineHeight,
  letterSpacing: text.letterSpacing,
);

Widget _button(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialButton button = node as material.MaterialButton;
  final Widget label = button.icon == null
      ? renderNode(button.label)
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            renderNode(button.icon!),
            const SizedBox(width: 8),
            renderNode(button.label),
          ],
        );
  final VoidCallback? onPressed = _action(
    context,
    button.enabled,
    button.onPressed,
    button.url,
  );

  final core.BoxStyle declared = button.controlStyle.resolve(
    UniboxScopeWidget.of(context).theme ?? core.UniboxTheme.none,
  );
  final core.BoxTextStyle? text = declared.textStyle;
  final core.BoxBorder? border = declared.border;
  final ButtonStyle style = ButtonStyle(
    textStyle: text == null
        ? null
        : WidgetStatePropertyAll<TextStyle>(_labelStyle(text)),
    minimumSize: WidgetStatePropertyAll<Size>(
      Size(declared.minWidth ?? 0, declared.minHeight ?? 0),
    ),
    fixedSize: WidgetStatePropertyAll<Size>(
      Size(
        declared.width ?? double.infinity,
        declared.height ?? double.infinity,
      ),
    ),
    padding: declared.padding == null
        ? null
        : WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.fromLTRB(
              declared.padding!.left,
              declared.padding!.top,
              declared.padding!.right,
              declared.padding!.bottom,
            ),
          ),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(declared.borderRadius ?? 20),
      ),
    ),
    side: border == null
        ? null
        : WidgetStatePropertyAll<BorderSide>(
            BorderSide(width: border.width, color: Color(border.color.value)),
          ),
    backgroundColor: declared.backgroundColor == null
        ? null
        : WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.disabled)
                ? null
                : Color(declared.backgroundColor!.value),
          ),
    foregroundColor: text?.color == null
        ? null
        : WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.disabled)
                ? null
                : Color(text!.color!.value),
          ),
    // The layer a press and a hover paint, from the palette the tree is drawn with — see
    // [_overlay]. Flutter's own buttons derive it from their foreground, which is a different
    // tint on a filled button: a light wash of `onPrimary` where the page paints `onSurface`.
    overlayColor: _overlay(context),
  );

  final Widget control = switch (button.variant) {
    material.MaterialButtonVariant.filled => FilledButton(
      onPressed: onPressed,
      onLongPress: button.onLongPress,
      style: style,
      child: label,
    ),
    material.MaterialButtonVariant.tonal => FilledButton.tonal(
      onPressed: onPressed,
      onLongPress: button.onLongPress,
      style: style,
      child: label,
    ),
    material.MaterialButtonVariant.outlined => OutlinedButton(
      onPressed: onPressed,
      onLongPress: button.onLongPress,
      style: style,
      child: label,
    ),
    material.MaterialButtonVariant.text => TextButton(
      onPressed: onPressed,
      onLongPress: button.onLongPress,
      style: style,
      child: label,
    ),
  };
  return declared.width == null
      // A box of its own, at the size the label asks for, and never wider. The node's outer box
      // *is* a row and this substitution replaces it, so the widget has to answer the same way
      // the row does: hug the label, and left-align it when a parent hands over a width it did
      // not use. `widthFactor: 1` is the whole of it — a plain `Align` fills the width a `Wrap`
      // gives each child, which put every button in a wrapping row on a line of its own, and a
      // `Row` feeds its child an unbounded width, which overflowed by fourteen pixels instead of
      // letting a long label wrap.
      ? Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: control,
        )
      : SizedBox(width: declared.width, child: control);
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
  final Widget label = DefaultTextStyle.merge(
    style: _labelStyle(
      chip.controlStyle.textStyle ?? const core.BoxTextStyle(),
    ),
    child: renderNode(chip.label),
  );
  final VoidCallback? onDeleted = chip.enabled ? chip.onDeleted : null;
  final VoidCallback? onPressed = _action(
    context,
    chip.enabled,
    chip.onSelected,
    chip.url,
  );
  // What the chip carries is information: the glyph before the label, and the cross after it.
  final Widget? avatar = chip.leading == null
      ? null
      : renderNode(chip.leading!);
  final Widget? cross = chip.trailing == null
      ? null
      : renderNode(chip.trailing!);

  final core.BoxStyle declared = chip.controlStyle.resolve(
    UniboxScopeWidget.of(context).theme ?? core.UniboxTheme.none,
  );
  final OutlinedBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(declared.borderRadius ?? 0),
  );

  // The pill is the declaration's, and the declaration's default is the one Flutter paints — so
  // a chip that states nothing is passed nothing. A caller who asks for a tighter pill gets the
  // step that carries the widget there: Flutter's chip follows a density step by two pixels,
  // which the suite pins by measuring the declared heights.
  final double declaredHeight =
      declared.height ?? material.MaterialChip.controlHeight;
  final VisualDensity? density =
      declaredHeight == material.MaterialChip.controlHeight
      ? null
      : VisualDensity(vertical: (declaredHeight - _defaultPill) / 2);

  // A chip with a cross is the input chip; one without is a choice, and a chip that says it
  // is chosen is a filter. Those are the three Material draws, and the node says which it is
  // by what it carries.
  final Widget pill;
  if (chip.onDeleted != null) {
    pill = InputChip(
      selected: chip.selected,
      isEnabled: chip.enabled,
      shape: shape,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: density,
      label: label,
      avatar: avatar,
      deleteIcon: cross,
      deleteButtonTooltipMessage: chip.removeLabel,
      onDeleted: onDeleted,
      // A chip whose whole pill drops the filter answers it too, as the node states it: the
      // cross is the second way to the same end, not the only one.
      onPressed: onPressed,
    );
  } else if (onPressed == null && chip.onDeleted == null) {
    pill = RawChip(
      shape: shape,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: density,
      label: label,
      avatar: avatar,
      selected: chip.selected,
      isEnabled: chip.enabled,
      showCheckmark: false,
    );
  } else {
    pill = FilterChip(
      shape: shape,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: density,
      label: label,
      avatar: avatar,
      // The node drew its own glyph for a chosen chip; Flutter's checkmark would be a second one.
      showCheckmark: false,
      selected: chip.selected,
      onSelected: onPressed == null ? null : (bool _) => onPressed(),
    );
  }

  // The pill the tree paints sits inside a 48 pixel target, and Flutter's chip is a single box:
  // handed the target's height it stretches, and a chip a third taller than the one on the page
  // is a different component. The width is the label's, because a chip that filled its box would
  // tint the whole row on hover; the height is the target's, which is what centres the pill and
  // what a finger gets.
  return Align(alignment: Alignment.center, widthFactor: 1, child: pill);
}

/// The pill Flutter's own chip paints at the standard density, measured by the suite.
///
/// It is not a token: [material.MaterialChip.controlHeight] is the pill a declaration states,
/// and it is this number — which is why a chip at the default is passed no density at all.
/// A caller that asks for another height is a chip that departs from the widget's own answer,
/// and the difference is what the step is made of: Flutter follows a step by two pixels.
const double _defaultPill = 38;

Widget _iconButton(BuildContext context, core.UINode node, Widget? content) {
  final material.MaterialIconButton button =
      node as material.MaterialIconButton;
  final Widget glyph = renderNode(button.icon);
  final int? count = button.badgeCount;
  final Widget icon = count == null || count <= 0
      ? glyph
      : Badge.count(count: count, child: glyph);

  final VoidCallback? onPressed = _action(
    context,
    button.enabled,
    button.onPressed,
    button.url,
  );
  final core.BoxStyle declared = button.controlStyle.resolve(
    UniboxScopeWidget.of(context).theme ?? core.UniboxTheme.none,
  );
  final core.BoxBorder? border = declared.border;
  final core.BoxSpacing? padding = declared.padding;
  final ButtonStyle style = IconButton.styleFrom(
    fixedSize: Size(declared.width ?? 40, declared.height ?? 40),
    minimumSize: Size(declared.width ?? 40, declared.height ?? 40),
    padding: padding == null
        ? null
        : EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            padding.bottom,
          ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(declared.borderRadius ?? 20),
    ),
    side: border == null
        ? null
        : BorderSide(width: border.width, color: Color(border.color.value)),
    // The same state layers the page paints — see [_overlay].
  ).copyWith(overlayColor: _overlay(context));
  return switch (button.variant) {
    material.MaterialIconButtonVariant.standard => IconButton(
      onPressed: onPressed,
      tooltip: button.label,
      style: style,
      icon: icon,
    ),
    material.MaterialIconButtonVariant.filled => IconButton.filled(
      onPressed: onPressed,
      tooltip: button.label,
      style: style,
      icon: icon,
    ),
    material.MaterialIconButtonVariant.tonal => IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: button.label,
      style: style,
      icon: icon,
    ),
    material.MaterialIconButtonVariant.outlined => IconButton.outlined(
      onPressed: onPressed,
      tooltip: button.label,
      style: style,
      icon: icon,
    ),
  };
}

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

Widget _segmentedButton(
  BuildContext context,
  core.UINode node,
  Widget? content,
) {
  final material.MaterialSegmentedButton pill =
      node as material.MaterialSegmentedButton;
  final core.BoxStyle style = _styleOf(context, pill);
  final core.BoxBorder? border = style.border;

  // A row that stretches its children hands this a taller box than the control's own height,
  // and `SegmentedButton` then paints its segments at the top of it — leaving the selection
  // fill short of the pill's edge. The height the node states is the height it gets.
  // `Align` first, so the widget is not stretched to the row's height: a tight height makes
  // `SizedBox` meaningless, and a `SegmentedButton` in a taller box paints its selection at the
  // top of it. Loose constraints, then the control's own height.
  //
  // The node's width decides, as it does on the page: a pill that states one divides it between its
  // segments, and one that does not is as wide as its columns — which is what a row that scrolls
  // holds. Reading it off the node rather than the constraints keeps the widget free of a
  // `LayoutBuilder`, and a `LayoutBuilder` cannot answer an intrinsic measurement — which is what
  // a viewport wrapped around this control asks for when the row it is in hugs.
  return Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(
      height:
          style.height ??
          pill.density.adjust(material.MaterialSegmentedButton.controlHeight),
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
        onSelectionChanged: !pill.enabled
            ? null
            : (Set<int> chosen) {
                final int index = chosen.first;
                final String? url = pill.segments[index].url;
                final VoidCallback? action = _action(
                  context,
                  true,
                  url == null ? () => pill.onSelect?.call(index) : null,
                  url,
                );
                action?.call();
              },
        showSelectedIcon: pill.showSelectedIcon,
        expandedInsets: pill.width == null ? null : EdgeInsets.zero,
        // The node's hairline, not the theme's. `SegmentedButton` otherwise outlines the pill
        // with `ColorScheme.outline`, a step darker than the `outlineVariant` the tree names, so
        // the same control was drawn in two colours — the app's against the page's.
        style: SegmentedButton.styleFrom(
          textStyle: _labelStyle(pill.labelStyle),
          padding: EdgeInsets.fromLTRB(
            pill.segmentPadding.left,
            pill.segmentPadding.top,
            pill.segmentPadding.right,
            pill.segmentPadding.bottom,
          ),
          side: border == null || !border.isVisible
              ? null
              : BorderSide(
                  color: Color(border.color.value),
                  width: border.width,
                ),
        ),
      ),
    ),
  );
}
