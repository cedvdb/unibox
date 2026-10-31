import 'package:unibox_core/unibox_core.dart' as core;

import 'declarations.dart';
import 'nodes.dart';
import 'shape.dart';
import 'values.dart';

/// The declarations of a box, as the web writes them.
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
///
/// [anchor] says the box is the `<a>` element rather than a container, so the two
/// declarations a browser gives every link are cancelled here — a box that navigates is
/// painted by its own look, not by the user agent's blue and underline.
CssDeclarations boxDeclarations(
  core.BoxStyle style, {
  bool interactive = false,
  bool capturesPointer = true,
  bool declaredOnly = false,
  bool anchor = false,
  core.BoxElement element = core.BoxElement.div,
}) {
  final core.Axis? direction = declaredOnly
      ? style.direction
      : style.resolvedDirection;
  final core.WritingDirection? writingDirection = style.writingDirection;
  final core.MainAlign? mainAlign = declaredOnly
      ? style.mainAlign
      : style.mainAlign ?? core.MainAlign.start;
  final core.CrossAlign? crossAlign = declaredOnly
      ? style.crossAlign
      : style.crossAlign ?? core.CrossAlign.start;

  final core.BoxBorder? border = style.border;
  final List<core.BoxShadow>? shadows = style.shadows;
  final core.BoxSpacing? padding = style.padding;
  final core.BoxSpacing? margin = style.margin;
  final core.BoxColor? backgroundColor = style.backgroundColor;
  final core.Overflow? overflow = style.overflow;
  final double? opacity = style.opacity;
  final double? gap = style.gap;
  final double? borderRadius = style.borderRadius;
  final core.BoxBorderRadius? corners = style.corners;
  final core.BoxShape? shape = style.shape;
  final int? flex = style.flex;
  final double? aspectRatio = style.aspectRatio;

  final String? roleBackground = backgroundColor == null
      ? null
      : cssRoleReference(backgroundColor);
  final String? roleBorder = border == null || !border.isVisible
      ? null
      : cssRoleReference(border.color);

  final CssDeclarations declarations = CssDeclarations()
    ..add('box-sizing', 'border-box');

  if (!declaredOnly) {
    declarations.add('display', 'flex');

    if (style.wrap ?? false) {
      declarations
        ..add('flex-wrap', 'wrap')
        // The lines are packed from the start of the box, which is what a Flutter `Wrap`
        // does with its runs. A browser's `align-content: normal` stretches them over the
        // height of the box instead, so a wrapped row in a tall box would sit in bands.
        ..add('align-content', 'flex-start');
    }
  }

  declarations
    // The direction the words flow in, which decides which side `start` is: a row
    // reverses and a `text-align: start` moves with it, and the page's direction is what
    // everything that states none inherits. It is stated by the box rather than resolved,
    // because a tree that says nothing keeps the document's answer.
    ..addIf(
      'direction',
      writingDirection == null ? null : cssWritingDirection(writingDirection),
    )
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
    // A fraction wins over a stated size: the two say the same thing, and `validateTree` reports
    // the box that says both.
    ..addIf('width', cssFraction(style.widthFraction))
    ..addIf('height', cssFraction(style.heightFraction))
    ..addIf(
      'width',
      style.widthFraction == null ? cssLength(style.width) : null,
    )
    ..addIf(
      'height',
      style.heightFraction == null ? cssLength(style.height) : null,
    )
    // A ratio the box divides one side by, written as the number itself: `1.5` is three
    // units across for every two down. A browser drops it when the box states both a width
    // and a height, which is the same answer the Flutter renderer gives a tight box.
    ..addIf('aspect-ratio', aspectRatio == null ? null : cssNumber(aspectRatio))
    // A span is read by the grid the box sits in and by nothing else, and a browser
    // clamps one wider than the track count the way the Flutter renderer does.
    ..addIf(
      'grid-column',
      style.gridSpan == null ? null : 'span ${style.gridSpan}',
    )
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

  if (shape == null && backgroundColor != null && roleBackground == null) {
    declarations.add('background-color', cssColor(backgroundColor));
  }

  // Corners the box names are four values in one declaration; a single radius stays
  // the one-value shorthand.
  if (shape == null && corners == null && borderRadius != null) {
    declarations.add('border-radius', cssPixels(borderRadius));
  }

  if (shape == null && border != null && border.isVisible) {
    declarations.add(
      'border',
      cssBorder(
        roleBorder == null
            ? border
            : core.BoxBorder(width: border.width, color: core.BoxColor.black),
      ),
    );
  }

  if (shape == null && shadows != null && shadows.isNotEmpty) {
    declarations.add('box-shadow', cssBoxShadows(shadows));
  }

  declarations
    ..addIf('overflow', overflow == null ? null : cssOverflow(overflow))
    // A browser hands the rest of a scroll to the page once the box reaches its end; Flutter's
    // viewport keeps it. `contain` is what makes the two agree — and the pull the box keeps is
    // the host telling the reader they are at the end, which is worth keeping: it reveals the
    // box's own `backgroundColor`, so a box that states its surface is a box whose pull shows
    // that surface and never the page behind it.
    ..addIf(
      'overscroll-behavior',
      overflow == core.Overflow.scroll ? 'contain' : null,
    )
    ..addIf(
      'scroll-snap-type',
      cssScrollSnap(style.snap, style.resolvedDirection),
    )
    ..addIf('opacity', opacity == null ? null : cssNumber(opacity))
    ..addIf('transform', cssTransform(style.transform));

  // A pinned box stays at one edge of the box that scrolls it, once it would have
  // scrolled past, and keeps its slot in the flow: `position: sticky` is the whole of it,
  // and it is the same declaration whether the nearest scroll container is a box with
  // `overflow: auto` or the document, which is why a server-rendered page that scrolls
  // itself needs nothing from the client.
  //
  // `z-index` is stated with it because sticky positions the box in the flow order it was
  // written in, so content that follows it would paint over it as it scrolls under; one
  // level is enough, and it is why the pinned band covers the results rather than the
  // reverse.
  //
  // A state rule leaves the three out: a pin is a relation to the viewport, not a look a
  // `:hover` could change, and restating `position` there would reset the stacking the
  // resting rule set up.
  final core.BoxPin? pin = declaredOnly ? null : style.pin;

  if (pin != null) {
    declarations
      ..add('position', 'sticky')
      ..add(cssPinEdge(pin), cssPixels(style.resolvedPinOffset))
      ..add('z-index', '1');
  }

  // A fold runs on the box's own exit from whatever scrolls it, so it names no scroll
  // container and no distance: the two frames are a block of their own, and this rule calls it.
  // A state rule leaves it out, as it leaves the pin out: restating an animation there would
  // start it again from wherever the reader is.
  final core.BoxFold? fold = declaredOnly ? null : style.fold;

  if (fold != null) {
    declarations.addAllIn(foldDeclarations(style));
  }

  // A flex item keeps its content as a floor unless it is told not to, which is what
  // makes a column of listings refuse to shrink into a window. A Flutter `Expanded`
  // hands its child a tight size, so a box that states a `flex` states the floor away.
  if (flex != null) {
    declarations
      ..add('min-width', '0')
      ..add('min-height', '0');
  }

  declarations
    ..addIf('background-color', shape == null ? roleBackground : null)
    ..addIf('border-color', shape == null ? roleBorder : null);

  if (shape == null && corners != null) {
    declarations.add('border-radius', cssCorners(corners));
  }

  if (shape != null) {
    declarations.addAllIn(shapeDeclarations(style, shape));
  }

  declarations.addIf('cursor', interactive ? 'pointer' : null);
  declarations.add('pointer-events', capturesPointer ? 'auto' : 'none');

  // An anchor is the one element whose look the browser states for it: a link is painted
  // blue and underlined. The tree's look is the box's, so the two are cancelled — into
  // the anchor's own class, which is what keeps one rule per look.
  if (anchor && !declaredOnly) {
    declarations.addAllIn(linkDeclarations());
  }

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
/// A zero, the same way every other zero length is written here.
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

/// What a shaped box declares instead of a background, a border and a radius.
///
/// The fill and the stroke become custom properties, because the shape's paint layer is an
/// `<svg>` and the colour belongs to its path, not to the element: a state rule that changes the
/// background of a shaped box has to reach the path, and a custom property is what a pseudo
/// class and a style rule can both set. `fill`, `stroke` and `stroke-width` are CSS properties
/// of SVG, so a change of any of the three eases with the transition the box declares.
///
/// The clip is declared here too, and only when the box asks for one: `overflow: hidden` — or a
/// scrolling box — clips a shaped box to its outline, which needs the definition the layer
/// writes in the same box.
CssDeclarations shapeDeclarations(core.BoxStyle style, core.BoxShape shape) {
  final core.BoxColor? fill = style.backgroundColor;
  final core.BoxBorder? border = style.border;
  final String? fillReference = fill == null ? null : cssColorOrRole(fill);
  final String? strokeReference = border == null || !border.isVisible
      ? null
      : cssColorOrRole(border.color);
  final bool clips =
      style.overflow == core.Overflow.hidden ||
      style.overflow == core.Overflow.scroll;

  return CssDeclarations()
    // The layer is absolutely positioned, and `isolation` keeps its negative `z-index` inside
    // this box instead of letting it fall behind an ancestor. A pinned box is `sticky` here
    // instead of `relative`: both are positioned, so both hold the layer, and only the pin can
    // be the one that moves with the viewport.
    ..add('position', style.pin == null ? 'relative' : 'sticky')
    ..add('isolation', 'isolate')
    ..addIf('clip-path', clips ? 'url(#${cssShapeClipId(shape)})' : null)
    ..add('--unibox-shape-fill', fillReference ?? 'none')
    ..addIf('--unibox-shape-stroke', strokeReference)
    ..addIf(
      '--unibox-shape-stroke-width',
      strokeReference == null ? null : cssPixels(border!.width),
    )
    // Only a non-default cap is written: `butt` is what the path already declares, and a
    // property that repeats a default is a declaration nothing reads.
    ..addIf(
      '--unibox-shape-stroke-cap',
      border != null && border.cap != core.BoxStrokeCap.butt
          ? border.cap.name
          : null,
    );
}
