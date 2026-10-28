import 'package:jaspr/dom.dart';
import 'package:unibox_core/unibox_core.dart' as core;

/// Converts a Unibox [core.BoxColor] to a CSS [Color].
///
/// Opaque colors become a `#rrggbb` value, translucent ones an `rgba(...)`
/// function whose alpha is rounded to three decimals, which is more precise than
/// the eight bit channel it originates from.
Color toCssColor(core.BoxColor color) {
  if (color.isOpaque) {
    return Color.value(color.value & 0xFFFFFF);
  }
  return Color.rgba(
    color.red,
    color.green,
    color.blue,
    double.parse(color.opacity.toStringAsFixed(3)),
  );
}

/// The custom property of a role colour, or `null` for a colour with its own
/// channels.
///
/// A role is written as `var(--unibox-color-primary)`, so its value lives once, in
/// the `:root` block the renderer emits for the theme, and a host stylesheet or a
/// dark-mode block can outrank it. The name comes from the enum member, so a role
/// is spelled the same way in the tree, in the theme and in the CSS.
String? cssRoleReference(core.BoxColor color) {
  final Enum? role = color.role;

  return role == null ? null : 'var(${core.UniboxTheme.cssNameOf(role)})';
}

/// The `box-shadow` text of [shadow], with [color] as its colour.
String _shadowText(core.BoxShadow shadow, String color) {
  return '${shadow.offsetX}px ${shadow.offsetY}px ${shadow.blurRadius}px '
      '${shadow.spreadRadius}px $color';
}

/// Converts a Unibox dimension to a CSS [Unit].
///
/// `null` remains `null` so callers can omit the property entirely,
/// `double.infinity` expands to the available space (`100%`) and every other
/// value is expressed in logical pixels.
Unit? toCssUnit(double? value) {
  if (value == null) {
    return null;
  }
  if (value.isInfinite) {
    return const Unit.percent(100);
  }
  return Unit.pixels(value);
}

/// Converts a Unibox [core.BoxSpacing] to CSS [Spacing].
///
/// A uniform spacing collapses into the one value shorthand (`8px`), anything
/// else into the four value shorthand (`8px 12px 16px 4px`).
Spacing toCssSpacing(core.BoxSpacing spacing) {
  if (spacing.left == spacing.top &&
      spacing.top == spacing.right &&
      spacing.right == spacing.bottom) {
    return Spacing.all(Unit.pixels(spacing.left));
  }
  return Spacing.fromLTRB(
    Unit.pixels(spacing.left),
    Unit.pixels(spacing.top),
    Unit.pixels(spacing.right),
    Unit.pixels(spacing.bottom),
  );
}

/// Converts a Unibox [core.Axis] to a [FlexDirection].
FlexDirection toCssFlexDirection(core.Axis axis) {
  return switch (axis) {
    core.Axis.horizontal => FlexDirection.row,
    core.Axis.vertical => FlexDirection.column,
  };
}

/// Converts a Unibox [core.MainAlign] to [JustifyContent].
JustifyContent toCssJustifyContent(core.MainAlign align) {
  return switch (align) {
    core.MainAlign.start => JustifyContent.start,
    core.MainAlign.center => JustifyContent.center,
    core.MainAlign.end => JustifyContent.end,
    core.MainAlign.spaceBetween => JustifyContent.spaceBetween,
    core.MainAlign.spaceAround => JustifyContent.spaceAround,
    core.MainAlign.spaceEvenly => JustifyContent.spaceEvenly,
  };
}

/// Converts a Unibox [core.CrossAlign] to [AlignItems].
AlignItems toCssAlignItems(core.CrossAlign align) {
  return switch (align) {
    core.CrossAlign.start => AlignItems.start,
    core.CrossAlign.center => AlignItems.center,
    core.CrossAlign.end => AlignItems.end,
    core.CrossAlign.stretch => AlignItems.stretch,
  };
}

/// Converts a Unibox [core.Overflow] to CSS [Overflow].
///
/// A scrollable box maps to `overflow: auto` so that scrollbars only appear
/// when the content actually overflows, which is what a Flutter
/// `SingleChildScrollView` does as well.
Overflow toCssOverflow(core.Overflow overflow) {
  return switch (overflow) {
    core.Overflow.visible => Overflow.visible,
    core.Overflow.hidden => Overflow.hidden,
    core.Overflow.scroll => Overflow.auto,
  };
}

/// Converts a Unibox [core.BoxBorder] to a CSS [Border].
///
/// Returns `null` for missing or invisible borders so that no `border` property
/// is emitted at all.
Border? toCssBorder(core.BoxBorder? border) {
  if (border == null || !border.isVisible) {
    return null;
  }
  return Border.all(
    color: toCssColor(border.color),
    width: Unit.pixels(border.width),
  );
}

/// Converts a Unibox [core.BoxShadow] to a CSS [BoxShadow].
BoxShadow toCssBoxShadow(core.BoxShadow shadow) {
  return BoxShadow(
    offsetX: Unit.pixels(shadow.offsetX),
    offsetY: Unit.pixels(shadow.offsetY),
    blur: Unit.pixels(shadow.blurRadius),
    spread: Unit.pixels(shadow.spreadRadius),
    color: toCssColor(shadow.color),
  );
}

/// Converts a Unibox [core.FontWeight] to [FontWeight].
FontWeight toCssFontWeight(core.FontWeight weight) {
  return switch (weight) {
    core.FontWeight.normal => FontWeight.w400,
    core.FontWeight.medium => FontWeight.w500,
    core.FontWeight.semiBold => FontWeight.w600,
    core.FontWeight.bold => FontWeight.w700,
  };
}

/// Converts a Unibox [core.TextAlign] to [TextAlign].
TextAlign toCssTextAlign(core.TextAlign align) {
  return switch (align) {
    core.TextAlign.left => TextAlign.left,
    core.TextAlign.center => TextAlign.center,
    core.TextAlign.right => TextAlign.right,
    core.TextAlign.justify => TextAlign.justify,
  };
}

/// Builds the declarations that make the descendants of a box inherit its
/// typography.
///
/// Every token maps to a CSS property that is inherited by default
/// (`font-size`, `font-weight`, `font-family`, `line-height`, `letter-spacing`
/// and `color`), which is what makes a box behave like the `DefaultTextStyle` a
/// Flutter box installs. The line height is written unitless so descendants
/// scale with their own font size, exactly like `TextStyle.height`.
///
/// Returns `null` when [textStyle] sets no token, so a box without typography
/// emits no font declaration at all.
Styles? toTypographyStyles(core.BoxTextStyle textStyle) {
  if (textStyle.isEmpty) {
    return null;
  }

  final core.FontWeight? weight = textStyle.fontWeight;
  final core.BoxColor? color = textStyle.color;
  final String? roleColor = color == null ? null : cssRoleReference(color);
  final String? fontFamily = textStyle.fontFamily;
  final double? fontSize = textStyle.fontSize;
  final double? lineHeight = textStyle.lineHeight;
  final double? letterSpacing = textStyle.letterSpacing;

  return Styles(
    fontSize: fontSize == null ? null : Unit.pixels(fontSize),
    fontWeight: weight == null ? null : toCssFontWeight(weight),
    // A role is a custom property, which the typed API cannot express.
    color: color == null || roleColor != null ? null : toCssColor(color),
    fontFamily: fontFamily == null ? null : FontFamily(fontFamily),
    letterSpacing: letterSpacing == null ? null : Unit.pixels(letterSpacing),
    lineHeight: lineHeight == null ? null : Unit.expression('$lineHeight'),
    raw: roleColor == null ? null : <String, String>{'color': roleColor},
  );
}

/// Builds the declarations of the typography a tree falls back to.
///
/// The tokens are the ones in [core.BoxTextStyle.defaults], so both renderers
/// answer with the same numbers. Only the family is spelled here: the model names
/// none, because a font file is an asset of the application, and unset means "the
/// platform's UI font" — which Flutter gets by saying nothing and CSS by naming
/// the generic `system-ui`.
///
/// The family has to be written raw: a quoted `'system-ui'` would name a font
/// instead of asking for the generic one, and no platform installs a font by that
/// name.
Styles defaultTypographyStyles() {
  final Styles? typography = toTypographyStyles(core.BoxTextStyle.defaults);
  const Styles family = Styles(
    raw: <String, String>{'font-family': 'system-ui'},
  );

  return typography == null ? family : typography.combine(family);
}

/// Builds the CSS of a text node.
///
/// Only the typography tokens that are set are emitted, so the text inherits
/// everything else from the surrounding box, just like a Flutter `Text` inherits
/// from `DefaultTextStyle`.
Styles toTextStyles(core.TextNode node) {
  final core.TextAlign? textAlign = node.textAlign;
  final Styles? typography = toTypographyStyles(node.computedStyle);

  final Styles own = Styles(
    textAlign: textAlign == null ? null : toCssTextAlign(textAlign),
    raw: <String, String>{
      ...?_truncationStyles(node.maxLines, node.overflow),
      ...?_headingResetStyles(node),
    },
  );

  return typography == null ? own : own.combine(typography);
}

/// The declarations that cancel what a browser does to a heading by itself.
///
/// An `<h1>`–`<h6>` arrives with a font size, a bold weight and a margin from the
/// user agent stylesheet, none of which is in the model: a heading is structure.
/// The reset is written only for the tokens the node does not declare, so the
/// tree's typography stays in charge and a heading looks exactly like the text it
/// would be without the element.
Map<String, String>? _headingResetStyles(core.TextNode node) {
  final int? level = node.headingLevel;
  if (level == null) {
    return null;
  }

  final core.BoxTextStyle style = node.computedStyle;

  return <String, String>{
    'margin': '0',
    if (style.fontSize == null) 'font-size': 'inherit',
    if (style.fontWeight == null) 'font-weight': 'inherit',
  };
}

/// Builds the CSS that truncates text after [maxLines].
///
/// Clamping to a number of lines needs the prefixed `-webkit-box` layout, which
/// the typed properties do not expose, so the declarations are written raw. A
/// positive [maxLines] clamps the block, otherwise an ellipsis truncates the
/// single line. `TextOverflow.clip` suppresses the ellipsis in both cases.
Map<String, String>? _truncationStyles(
  int? maxLines,
  core.TextOverflow? overflow,
) {
  if (maxLines != null) {
    return <String, String>{
      'display': '-webkit-box',
      '-webkit-box-orient': 'vertical',
      '-webkit-line-clamp': '$maxLines',
      'overflow': 'hidden',
      if (overflow == core.TextOverflow.clip) 'text-overflow': 'clip',
    };
  }

  if (overflow == null) {
    return null;
  }

  return <String, String>{
    'overflow': 'hidden',
    'text-overflow': overflow == core.TextOverflow.ellipsis
        ? 'ellipsis'
        : 'clip',
    if (overflow == core.TextOverflow.ellipsis) 'white-space': 'nowrap',
  };
}

/// Converts a Unibox [core.ImageFit] to the CSS `object-fit` keyword.
///
/// `scaleDown` is a CSS keyword as well, so the model's default means the same
/// thing here as `BoxFit.scaleDown` does in Flutter.
String toCssObjectFit(core.ImageFit fit) {
  return switch (fit) {
    core.ImageFit.cover => 'cover',
    core.ImageFit.contain => 'contain',
    core.ImageFit.fill => 'fill',
    core.ImageFit.scaleDown => 'scale-down',
  };
}

/// Builds the CSS of an image node.
///
/// The image is rendered as a block so it behaves like the leaf box it is in
/// Flutter: no baseline gap under the picture and no line box contribution.
/// `object-fit` is written raw, since the typed properties do not expose it.
Styles toImageStyles(core.ImageNode node) {
  final double? borderRadius = node.borderRadius;

  return Styles(
    display: Display.block,
    width: toCssUnit(node.width),
    height: toCssUnit(node.height),
    radius: borderRadius == null
        ? null
        : BorderRadius.circular(Unit.pixels(borderRadius)),
    // Always written out: left unset, the browser would stretch the picture over
    // its box (`object-fit: fill`), which is not what a Flutter `Image` does.
    raw: <String, String>{'object-fit': toCssObjectFit(node.resolvedFit)},
  );
}

/// Builds the CSS of a stack node.
///
/// The stack is a relative grid into which every child is placed in the same
/// cell. Layering children that way keeps the container sized to the largest
/// child, which is what a Flutter `Stack` does, while still letting absolutely
/// positioned children resolve their offsets against the stack itself.
Styles toStackStyles(core.StackNode node) {
  return Styles(
    position: Position.relative(),
    display: Display.grid,
    width: toCssUnit(node.width),
    height: toCssUnit(node.height),
  );
}

/// The CSS that puts a child into the single cell of its stack.
///
/// Children placed like this overlap each other, painted in source order, so the
/// last one ends up on top.
///
/// The wrapper takes the whole cell and then lays its child out at the start of
/// both axes, which is what a Flutter `Stack` does with a child that is not
/// positioned: the cell is the constraint, the child is its own size. Sizing the
/// wrapper itself to its content (`place-self: start` on the grid item) looks
/// like the same thing and is not: a child that fills the cell — `width:
/// double.infinity`, which the model renders as `100%` — would then resolve its
/// percentage against a wrapper that has no width of its own, and collapse. A flex
/// container keeps both promises: the wrapper stays as big as the cell, its
/// percentage-resolving content box included, and a child that asks for nothing
/// keeps its own size instead of stretching.
Styles toStackChildStyles() {
  return Styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    justifyContent: JustifyContent.start,
    raw: const <String, String>{'grid-area': '1 / 1'},
  );
}

/// Builds the CSS of a [core.PositionedNode] that declares at least one offset.
///
/// The offsets are resolved against the nearest positioned ancestor, which is
/// the stack the node belongs to.
/// The CSS that fills the cell of a stack and places the child inside it.
///
/// `inset: 0` is what a Flutter `Positioned.fill` is, and the flex pair is the same
/// alignment on the two axes — the row direction fixes which of them is horizontal,
/// so a bottom-centred child is `justify-content: center` with `align-items: flex-end`,
/// which is `Alignment.bottomCenter`.
Styles toAlignedStyles(core.BoxAlignment alignment) {
  final core.MainAlign horizontal = switch (alignment) {
    core.BoxAlignment.topStart ||
    core.BoxAlignment.centerStart ||
    core.BoxAlignment.bottomStart => core.MainAlign.start,
    core.BoxAlignment.topCenter ||
    core.BoxAlignment.center ||
    core.BoxAlignment.bottomCenter => core.MainAlign.center,
    core.BoxAlignment.topEnd ||
    core.BoxAlignment.centerEnd ||
    core.BoxAlignment.bottomEnd => core.MainAlign.end,
  };
  final core.CrossAlign vertical = switch (alignment) {
    core.BoxAlignment.topStart ||
    core.BoxAlignment.topCenter ||
    core.BoxAlignment.topEnd => core.CrossAlign.start,
    core.BoxAlignment.centerStart ||
    core.BoxAlignment.center ||
    core.BoxAlignment.centerEnd => core.CrossAlign.center,
    core.BoxAlignment.bottomStart ||
    core.BoxAlignment.bottomCenter ||
    core.BoxAlignment.bottomEnd => core.CrossAlign.end,
  };

  return Styles(
    position: Position.absolute(
      top: Unit.zero,
      right: Unit.zero,
      bottom: Unit.zero,
      left: Unit.zero,
    ),
    display: Display.flex,
    flexDirection: FlexDirection.row,
    justifyContent: toCssJustifyContent(horizontal),
    alignItems: toCssAlignItems(vertical),
  );
}

Styles toPositionedStyles(core.PositionedNode node) {
  return Styles(
    position: Position.absolute(
      top: toCssUnit(node.top),
      right: toCssUnit(node.right),
      bottom: toCssUnit(node.bottom),
      left: toCssUnit(node.left),
    ),
  );
}

/// The declarations of the look tokens a box states in raw CSS.
///
/// `transform-origin` is not written: CSS centres a transform by default and the
/// Flutter renderer does the same, so both turn and scale about the middle of the
/// box. The three functions are always listed in the model's order — translate,
/// rotate, scale — because CSS only interpolates two transforms function by
/// function when the lists match.
Map<String, String>? _lookDeclarations(core.BoxTransform? transform) {
  if (transform == null || transform.isIdentity) {
    return null;
  }

  return <String, String>{
    'transform':
        'translate(${_pixels(transform.offsetX)}, '
        '${_pixels(transform.offsetY)}) '
        'rotate(${_number(transform.rotation)}deg) '
        'scale(${_number(transform.scale)})',
  };
}

/// A length in logical pixels, as CSS writes it.
/// The four corner radii as CSS reads them: top left, top right, bottom right,
/// bottom left.
String _cornersText(core.BoxBorderRadius corners) =>
    corners.radii.map(_pixels).join(' ');

String _pixels(double value) => '${_number(value)}px';

/// A number without a needless `.0`, which both CSS and a reader prefer.
String _number(double value) =>
    value == value.roundToDouble() ? '${value.toInt()}' : '$value';

/// The `transition` shorthand of [transition].
///
/// Only the paint properties are listed. A list that named layout would let the
/// two targets agree on the duration and disagree on what moves, and a border
/// width is left out for the same reason: CSS animates it as a layout change and
/// Flutter as a paint change.
String _transitionOf(core.BoxTransition transition) {
  return <String>[
    for (final MapEntry<core.BoxProperty, String> entry
        in _transitionedProperties.entries)
      '${entry.value} ${_timingOf(transition, entry.key)}',
  ].join(', ');
}

/// The `duration curve delay` of the look [look], as CSS writes it.
///
/// The delay is omitted when a part does not have one, which is the common case
/// and the shorter declaration.
String _timingOf(core.BoxTransition transition, core.BoxProperty look) {
  final core.BoxTransitionTiming timing = transition.timingOf(look);
  final String base =
      '${timing.duration.inMilliseconds}ms ${_cssCurve(timing.curve)}';

  return timing.delay == Duration.zero
      ? base
      : '$base ${timing.delay.inMilliseconds}ms';
}

/// The CSS timing function of [curve].
String _cssCurve(core.BoxCurve curve) {
  return switch (curve) {
    core.BoxCurve.linear => 'linear',
    core.BoxCurve.ease => 'ease',
    core.BoxCurve.easeIn => 'ease-in',
    core.BoxCurve.easeOut => 'ease-out',
    core.BoxCurve.easeInOut => 'ease-in-out',
  };
}

/// The CSS property of every look, in the order a transition lists them.
///
/// The paint first, then what is painted on top of it.
const Map<core.BoxProperty, String> _transitionedProperties =
    <core.BoxProperty, String>{
      core.BoxProperty.backgroundColor: 'background-color',
      core.BoxProperty.borderColor: 'border-color',
      core.BoxProperty.borderRadius: 'border-radius',
      core.BoxProperty.shadow: 'box-shadow',
      core.BoxProperty.opacity: 'opacity',
      core.BoxProperty.transform: 'transform',
    };

/// The padding a user agent puts around [element], cancelled as `0`.
///
/// A list comes with an indent, which a Flutter `Column` knows nothing about; the
/// renderer states the reset so the two targets agree. Guarded by the caller
/// against the box declaring its own padding.
Spacing? _userAgentPadding(core.BoxElement element) {
  return element == core.BoxElement.ul || element == core.BoxElement.ol
      ? Spacing.zero
      : null;
}

/// The margin a user agent puts around [element], cancelled as `0`.
///
/// A list and a `figure` bring outer space from the user agent stylesheet that no
/// Flutter counterpart has.
Spacing? _userAgentMargin(core.BoxElement element) {
  return element == core.BoxElement.ul ||
          element == core.BoxElement.ol ||
          element == core.BoxElement.figure
      ? Spacing.zero
      : null;
}

/// Builds the CSS of a single line text input or a text area.
///
/// Inputs are replaced elements: the browser gives them an intrinsic width, its
/// own padding, its own border, its own font and its own colour. Stretching the
/// field over the available width with `box-sizing: border-box` reproduces the
/// layout a Flutter `TextField` gets from the column it lives in, `font: inherit`
/// makes the field adopt the typography of the enclosing box — including the line
/// height, which is what sizes the field — and `color: inherit` keeps the text it
/// receives the same colour as the text around it.
///
/// Everything else is stripped away, down to the border and the padding, because
/// the Flutter renderer renders a field without Material's decoration as well:
/// the box around a field draws the border and the padding on both targets, so a
/// field looks the same on either of them and not like a browser widget on one
/// and a Material widget on the other.
///
/// The focus ring goes with them. A browser draws it around the field itself,
/// which sits inside the padding and the border of the box that wraps it, so a
/// focused field would show a second frame inside the one the tree asked for —
/// and Flutter has no counterpart to it, where a collapsed `TextField` only draws
/// its caret.
///
/// The cost is that a focused field now has no frame of its own, because the
/// tree cannot draw one either: a box raises its `focus` state by being focused
/// itself, not by holding a focused child, and a browser only matches
/// `:focus-visible` on the focused element. So a focused field shows its caret and
/// nothing else, on both targets — the same cue on both is worth more than a
/// browser frame on one.
Styles toTextInputStyles({core.BoxSpacing? padding}) {
  return Styles(
    boxSizing: BoxSizing.borderBox,
    width: const Unit.percent(100),
    raw: <String, String>{
      'font': 'inherit',
      'color': 'inherit',
      'border': 'none',
      'padding': padding == null ? '0' : _cssSpacingShorthand(padding),
      'background-color': 'transparent',
      'outline': 'none',
      // A text area comes with a grip in its bottom corner that lets the user
      // resize it, and Flutter has no counterpart to it. `resize` is ignored by
      // an `<input>`, so the declaration only ever reaches a text area.
      'resize': 'none',
    },
  );
}

/// A [core.BoxSpacing] as the four-value CSS shorthand.
String _cssSpacingShorthand(core.BoxSpacing spacing) {
  String px(double value) =>
      value == value.roundToDouble() ? '${value.toInt()}px' : '${value}px';

  return '${px(spacing.top)} ${px(spacing.right)} '
      '${px(spacing.bottom)} ${px(spacing.left)}';
}

/// Builds the CSS of a box from its resolved [core.BoxStyle].
///
/// Unset token values are omitted so that browser defaults (and inherited
/// typography) apply, mirroring how the Flutter renderer leaves unset
/// properties to `DefaultTextStyle`. The flex properties are the exception:
/// every box is a flex container, and a box without a direction is a column,
/// which is the `Column` the same node renders to in Flutter.
///
/// [interactive] adds a pointer cursor for boxes that react to input.
///
/// [declaredOnly] turns the filled in flex layout off, so only the tokens the
/// style actually sets are emitted. That is what a state rule needs: a `:hover`
/// rule that restated the whole flex layout would reset the `flex-direction`,
/// `justify-content` and `align-items` of the resting rule, so hovering a row
/// would silently turn it into a column — the browser layers a state rule over
/// the resting one the same way the Flutter renderer merges a state style, and
/// both may only contribute what the state mentions.
Styles toBoxStyles(
  core.BoxStyle style, {
  bool interactive = false,
  bool declaredOnly = false,
  core.BoxElement element = core.BoxElement.div,
}) {
  final core.Axis? direction = declaredOnly
      ? style.direction
      : style.resolvedDirection;
  final core.MainAlign? mainAlign = declaredOnly
      ? style.mainAlign
      : style.mainAlign ?? core.MainAlign.start;
  final core.CrossAlign? crossAlign = declaredOnly
      ? style.crossAlign
      : style.crossAlign ?? core.CrossAlign.start;
  final core.BoxBorder? border = style.border;
  final core.BoxShadow? shadow = style.shadow;
  final core.BoxSpacing? padding = style.padding;
  final core.BoxSpacing? margin = style.margin;
  final core.BoxColor? backgroundColor = style.backgroundColor;
  final core.Overflow? overflow = style.overflow;
  final core.BoxTransform? transform = style.transform;
  final double? opacity = style.opacity;
  final double? gap = style.gap;
  final double? borderRadius = style.borderRadius;
  final core.BoxBorderRadius? corners = style.corners;
  final int? flex = style.flex;
  final String? roleBackground = backgroundColor == null
      ? null
      : cssRoleReference(backgroundColor);
  final String? roleBorder = border == null || !border.isVisible
      ? null
      : cssRoleReference(border.color);
  final String? roleShadow = shadow == null
      ? null
      : cssRoleReference(shadow.color);

  final Styles boxStyles = Styles(
    boxSizing: BoxSizing.borderBox,
    display: declaredOnly ? null : Display.flex,
    flexDirection: direction == null ? null : toCssFlexDirection(direction),
    justifyContent: mainAlign == null ? null : toCssJustifyContent(mainAlign),
    alignItems: crossAlign == null ? null : toCssAlignItems(crossAlign),
    gap: gap == null ? null : Gap.all(Unit.pixels(gap)),
    flex: flex == null
        ? null
        : Flex(grow: flex.toDouble(), shrink: 1, basis: Unit.zero),
    width: toCssUnit(style.width),
    height: toCssUnit(style.height),
    minWidth: toCssUnit(style.minWidth),
    minHeight: toCssUnit(style.minHeight),
    maxWidth: toCssUnit(style.maxWidth),
    maxHeight: toCssUnit(style.maxHeight),
    // A `<ul>`, an `<ol>` or a `<figure>` comes with space around it that no
    // Flutter counterpart has, so the renderer writes the reset instead of
    // inheriting it. A token the box declares still wins.
    padding: padding == null
        ? (declaredOnly ? null : _userAgentPadding(element))
        : toCssSpacing(padding),
    margin: margin == null
        ? (declaredOnly ? null : _userAgentMargin(element))
        : toCssSpacing(margin),
    backgroundColor: backgroundColor == null || roleBackground != null
        ? null
        : toCssColor(backgroundColor),
    // Corners the box names are four values in one declaration, which the typed
    // radius cannot express; a single radius stays typed.
    radius: corners != null || borderRadius == null
        ? null
        : BorderRadius.circular(Unit.pixels(borderRadius)),
    // A role is written as a custom property; `raw` is emitted after the typed
    // properties, so the border is declared here and its colour overridden below.
    border: border == null || !border.isVisible
        ? null
        : Border.all(
            color: roleBorder == null
                ? toCssColor(border.color)
                : Color.value(0x000000),
            width: Unit.pixels(border.width),
          ),
    shadow: shadow == null || roleShadow != null
        ? null
        : toCssBoxShadow(shadow),
    overflow: overflow == null ? null : toCssOverflow(overflow),
    opacity: opacity,
    raw: <String, String>{
      ...?_lookDeclarations(transform),
      // A flex item keeps its content as a floor unless it is told not to:
      // `min-width: auto` (and `min-height: auto`) is the used value of a flex item,
      // which is what makes a column of 1953 pixels of listings refuse to shrink into
      // a thousand pixel window. Flutter's `Expanded` has no such floor — it hands the
      // child a tight size — so a box that states `flex` states the floor away, and
      // the two targets agree about how much room a share is.
      if (flex != null) ...<String, String>{
        'min-width': '0',
        'min-height': '0',
      },
      'background-color': ?roleBackground,
      'border-color': ?roleBorder,
      if (corners != null) 'border-radius': _cornersText(corners),
      if (shadow != null && roleShadow != null)
        'box-shadow': _shadowText(shadow, roleShadow),
    },
    cursor: interactive ? Cursor.pointer : null,
  );

  final Styles? typography = toTypographyStyles(
    style.textStyle ?? const core.BoxTextStyle(),
  );

  Styles result = typography == null
      ? boxStyles
      : boxStyles.combine(typography);

  final core.BoxTransition? transition = style.transition;

  // The transition is declared on the resting rule only: a state rule that
  // restated it would be repeating a duration the change does not own.
  if (transition != null && !declaredOnly) {
    result = result.combine(
      Styles(raw: <String, String>{'transition': _transitionOf(transition)}),
    );
  }

  return result;
}
