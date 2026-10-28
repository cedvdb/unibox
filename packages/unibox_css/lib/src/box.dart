import 'package:unibox_core/unibox_core.dart' as core;

import 'declarations.dart';
import 'values.dart';

/// The declarations of a box, as both web renderers write them.
///
/// A box is a flex container that states only what the tree asked for, plus the two
/// floors a flex item needs to behave like a Flutter child: `box-sizing: border-box`,
/// and `min-width`/`min-height` of zero on a box that states a `flex`.
///
/// [interactive] adds a pointer cursor for a box that answers input, and
/// [capturesPointer] says whether the element may be the target of a press at all: the
/// browser aims a press at the topmost element, and Flutter hit-tests a picture and
/// finds nothing to press, so a box that paints and holds nothing takes no pointer and
/// the press reaches the control it was meant for.
///
/// [declaredOnly] turns the filled-in flex layout off, so only the tokens the style
/// actually states are emitted. That is what a state rule needs: a `:hover` rule that
/// restated the whole layout would reset the direction and the alignments of the
/// resting rule, so hovering a row would turn it into a column. A transition is
/// declared on the resting rule only, for the same reason.
CssDeclarations boxDeclarations(
  core.BoxStyle style, {
  bool interactive = false,
  bool capturesPointer = true,
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

  final CssDeclarations declarations = CssDeclarations()
    ..add('box-sizing', 'border-box');

  if (!declaredOnly) {
    declarations.add('display', 'flex');
  }

  declarations
    ..addIf(
      'flex-direction',
      direction == null ? null : cssFlexDirection(direction),
    )
    ..addIf(
      'justify-content',
      mainAlign == null ? null : cssJustifyContent(mainAlign),
    )
    ..addIf(
      'align-items',
      crossAlign == null ? null : cssAlignItems(crossAlign),
    )
    ..addIf('gap', gap == null ? null : cssPixels(gap));

  if (flex != null) {
    declarations
      ..add('flex-grow', cssNumber(flex.toDouble()))
      ..add('flex-shrink', '1')
      // `0` and not `0px`: a basis of zero is a number the layout reads, and the two
      // renderers have to spell it the same way for a class name to match.
      ..add('flex-basis', '0');
  }

  declarations
    ..addIf('width', cssLength(style.width))
    ..addIf('height', cssLength(style.height))
    ..addIf('min-width', cssLength(style.minWidth))
    ..addIf('min-height', cssLength(style.minHeight))
    ..addIf('max-width', cssLength(style.maxWidth))
    ..addIf('max-height', cssLength(style.maxHeight));

  // A `<ul>`, an `<ol>` or a `<figure>` comes with space around it that no Flutter
  // counterpart has, so the reset is written instead of inherited. A token the box
  // states still wins.
  if (padding != null) {
    declarations.add('padding', cssSpacing(padding));
  } else if (!declaredOnly) {
    declarations.addIf('padding', userAgentPadding(element));
  }

  if (margin != null) {
    declarations.add('margin', cssSpacing(margin));
  } else if (!declaredOnly) {
    declarations.addIf('margin', userAgentMargin(element));
  }

  if (backgroundColor != null && roleBackground == null) {
    declarations.add('background-color', cssColor(backgroundColor));
  }

  // Corners the box names are four values in one declaration; a single radius stays
  // the one-value shorthand.
  if (corners == null && borderRadius != null) {
    declarations.add('border-radius', cssPixels(borderRadius));
  }

  if (border != null && border.isVisible) {
    declarations.add(
      'border',
      cssBorder(
        roleBorder == null
            ? border
            : core.BoxBorder(width: border.width, color: core.BoxColor.black),
      ),
    );
  }

  if (shadow != null && roleShadow == null) {
    declarations.add('box-shadow', cssBoxShadow(shadow));
  }

  declarations
    ..addIf('overflow', overflow == null ? null : cssOverflow(overflow))
    ..addIf('opacity', opacity == null ? null : cssNumber(opacity))
    ..addIf('transform', cssTransform(style.transform));

  // A flex item keeps its content as a floor unless it is told not to, which is what
  // makes a column of listings refuse to shrink into a window. A Flutter `Expanded`
  // hands its child a tight size, so a box that states a `flex` states the floor away.
  if (flex != null) {
    declarations
      ..add('min-width', '0')
      ..add('min-height', '0');
  }

  declarations
    ..addIf('background-color', roleBackground)
    ..addIf('border-color', roleBorder);

  if (corners != null) {
    declarations.add('border-radius', cssCorners(corners));
  }

  if (shadow != null && roleShadow != null) {
    declarations.add(
      'box-shadow',
      <String>[
        cssPixels(shadow.offsetX),
        cssPixels(shadow.offsetY),
        cssPixels(shadow.blurRadius),
        cssPixels(shadow.spreadRadius),
        roleShadow,
      ].join(' '),
    );
  }

  declarations.addIf('cursor', interactive ? 'pointer' : null);
  declarations.add('pointer-events', capturesPointer ? 'auto' : 'none');

  final CssDeclarations? typography = typographyDeclarations(
    style.textStyle ?? const core.BoxTextStyle(),
  );

  if (typography != null) {
    declarations.addAllIn(typography);
  }

  final core.BoxTransition? transition = style.transition;

  if (transition != null && !declaredOnly) {
    declarations.add('transition', cssTransition(transition));
  }

  return declarations;
}

/// The padding a user agent puts around [element], cancelled as zero.
///
/// Guarded by the caller against the box declaring its own padding.
String? userAgentPadding(core.BoxElement element) =>
    element == core.BoxElement.ul || element == core.BoxElement.ol ? '0' : null;

/// The margin a user agent puts around [element], cancelled as zero.
String? userAgentMargin(core.BoxElement element) =>
    element == core.BoxElement.ul ||
        element == core.BoxElement.ol ||
        element == core.BoxElement.figure
    ? '0'
    : null;
