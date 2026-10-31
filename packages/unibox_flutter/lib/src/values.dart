import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

/// Converts a Unibox [core.BoxColor] to a Flutter [Color].
Color toColor(core.BoxColor color) => Color(color.value);

/// Converts a Unibox [core.BoxSpacing] to Flutter [EdgeInsets].
EdgeInsets toEdgeInsets(core.BoxSpacing spacing) => EdgeInsets.fromLTRB(
  spacing.left,
  spacing.top,
  spacing.right,
  spacing.bottom,
);

/// Converts a Unibox [core.Axis] to a Flutter [Axis].
Axis toAxis(core.Axis axis) =>
    axis == core.Axis.horizontal ? Axis.horizontal : Axis.vertical;

/// Converts a Unibox [core.MainAlign] to Flutter [MainAxisAlignment].
MainAxisAlignment toMainAxisAlignment(core.MainAlign align) {
  return switch (align) {
    core.MainAlign.start => MainAxisAlignment.start,
    core.MainAlign.center => MainAxisAlignment.center,
    core.MainAlign.end => MainAxisAlignment.end,
    core.MainAlign.spaceBetween => MainAxisAlignment.spaceBetween,
    core.MainAlign.spaceAround => MainAxisAlignment.spaceAround,
    core.MainAlign.spaceEvenly => MainAxisAlignment.spaceEvenly,
  };
}

/// Converts a Unibox [core.CrossAlign] to Flutter [CrossAxisAlignment].
///
/// A baseline alignment makes Flutter demand a [TextBaseline] as well, which the
/// renderer states as the alphabetic one: it is the baseline CSS names, and the
/// only one the two targets can agree on.
CrossAxisAlignment toCrossAxisAlignment(core.CrossAlign align) {
  return switch (align) {
    core.CrossAlign.start => CrossAxisAlignment.start,
    core.CrossAlign.center => CrossAxisAlignment.center,
    core.CrossAlign.end => CrossAxisAlignment.end,
    core.CrossAlign.stretch => CrossAxisAlignment.stretch,
    core.CrossAlign.baseline => CrossAxisAlignment.baseline,
  };
}

/// The baseline Flutter lays a baseline aligned flex out against.
///
/// Alphabetic, which is where a line of Latin text sits and the only baseline CSS
/// can name: `align-items: baseline` has no ideographic counterpart, so the model
/// offers one baseline rather than a token one target could not honour.
const TextBaseline uniboxTextBaseline = TextBaseline.alphabetic;

/// Converts a Unibox [core.MainAlign] to the [WrapAlignment] of a wrapping box.
///
/// The six values are the same six: CSS distributes the children of *one line* with
/// `justify-content`, and a `Wrap` distributes one run with this, so a wrapping box
/// keeps the meaning the token already had.
WrapAlignment toWrapAlignment(core.MainAlign align) {
  return switch (align) {
    core.MainAlign.start => WrapAlignment.start,
    core.MainAlign.center => WrapAlignment.center,
    core.MainAlign.end => WrapAlignment.end,
    core.MainAlign.spaceBetween => WrapAlignment.spaceBetween,
    core.MainAlign.spaceAround => WrapAlignment.spaceAround,
    core.MainAlign.spaceEvenly => WrapAlignment.spaceEvenly,
  };
}

/// Converts a Unibox [core.CrossAlign] to the [WrapCrossAlignment] of a wrapping box,
/// or `null` for the two values a wrap cannot state.
///
/// `stretch` and `baseline` place a child against a line the flex layout has already
/// stretched or measured across, which a `Wrap` does not do; `validateTree` reports both
/// on a wrapping box rather than a renderer picking one and drifting from the browser.
WrapCrossAlignment? toWrapCrossAlignment(core.CrossAlign align) {
  return switch (align) {
    core.CrossAlign.start => WrapCrossAlignment.start,
    core.CrossAlign.center => WrapCrossAlignment.center,
    core.CrossAlign.end => WrapCrossAlignment.end,
    core.CrossAlign.stretch || core.CrossAlign.baseline => null,
  };
}

/// A model [core.CrossAlign] as the alignment a band drawn over a viewport is given.
///
/// A band drawn over a viewport is handed the whole width of it, tight, where a flex
/// container hands its child the room it asks for; `null` means the child fills that
/// width, which is what [core.CrossAlign.stretch] asks for and what the band does by
/// default. A baseline is a line a row aligns on and a box laid out by a viewport is a
/// column, which `validateTree` reports, so the value lands on the nearest edge here.
AlignmentGeometry? toBandAlignment(core.CrossAlign align) {
  return switch (align) {
    core.CrossAlign.start ||
    core.CrossAlign.baseline => AlignmentDirectional.centerStart,
    core.CrossAlign.center => AlignmentDirectional.center,
    core.CrossAlign.end => AlignmentDirectional.centerEnd,
    core.CrossAlign.stretch => null,
  };
}

/// Converts a Unibox [core.FontWeight] to a Flutter [FontWeight].
FontWeight toFontWeight(core.FontWeight weight) {
  return switch (weight) {
    core.FontWeight.light => FontWeight.w300,
    core.FontWeight.normal => FontWeight.w400,
    core.FontWeight.medium => FontWeight.w500,
    core.FontWeight.semiBold => FontWeight.w600,
    core.FontWeight.bold => FontWeight.w700,
  };
}

/// Converts a Unibox [core.TextAlign] to a Flutter [TextAlign].
TextAlign toTextAlign(core.TextAlign align) {
  return switch (align) {
    core.TextAlign.left => TextAlign.left,
    core.TextAlign.center => TextAlign.center,
    core.TextAlign.right => TextAlign.right,
    core.TextAlign.justify => TextAlign.justify,
  };
}

/// Converts a Unibox [core.TextOverflow] to a Flutter [TextOverflow].
TextOverflow toTextOverflow(core.TextOverflow overflow) {
  return switch (overflow) {
    core.TextOverflow.clip => TextOverflow.clip,
    core.TextOverflow.ellipsis => TextOverflow.ellipsis,
  };
}

/// Converts a Unibox [core.TextDecoration] to Flutter's [TextDecoration].
TextDecoration toTextDecoration(core.TextDecoration decoration) {
  return switch (decoration) {
    core.TextDecoration.none => TextDecoration.none,
    core.TextDecoration.lineThrough => TextDecoration.lineThrough,
    core.TextDecoration.underline => TextDecoration.underline,
  };
}

/// Converts the typography of a box or a text node into a Flutter [TextStyle].
///
/// Only the tokens that are set end up in the result, so Flutter keeps
/// inheriting every other token from the enclosing `DefaultTextStyle` — which is
/// exactly how the web renderer lets CSS inherit. Returns `null` when [style]
/// sets no token.
///
/// `decorationThickness` is the one typography token this target does not pass
/// on: CSS measures a decoration in logical pixels, and Flutter can only scale the
/// thickness the font asks for, so the two would draw different lines for the
/// same number. The web renderer honours it; here the line is the font's own and
/// `packages/unibox_flutter/README.md` says so beside the other attributes this
/// target does not read.
///
/// The line height is distributed the way CSS distributes it. A line box is
/// `fontSize * lineHeight` tall on both targets, but *where the glyphs sit in
/// it* is a second decision, and the two hosts make it differently: Flutter's
/// default, [TextLeadingDistribution.proportional], spreads the leading above
/// and below the glyphs in proportion to the font's ascent and descent, while
/// CSS adds half of it above and half below — [TextLeadingDistribution.even],
/// which the engine's own documentation calls "the default strategy used by
/// CSS". The two are not close: at 16 logical pixels with a 1.5 line height they
/// put the same line of text about a pixel and a half apart. Both boxes are the
/// same height either way, so nothing about the layout moves — the text moves
/// inside it, which is exactly what a reader sees as a jump when a page is handed
/// from the browser to Flutter. Only one of the two rules can be stated on both
/// targets, so the model uses it.
TextStyle? toTextStyle(core.BoxTextStyle style) {
  if (style.isEmpty) {
    return null;
  }

  final core.FontWeight? weight = style.fontWeight;
  final core.BoxColor? color = style.color;
  final core.TextDecoration? decoration = style.decoration;
  final core.BoxColor? decorationColor = style.decorationColor;

  return TextStyle(
    fontSize: style.fontSize,
    fontWeight: weight == null ? null : toFontWeight(weight),
    color: color == null ? null : toColor(color),
    height: style.lineHeight,
    leadingDistribution: TextLeadingDistribution.even,
    fontFamily: style.fontFamily,
    letterSpacing: style.letterSpacing,
    decoration: decoration == null ? null : toTextDecoration(decoration),
    decorationColor: decorationColor == null ? null : toColor(decorationColor),
  );
}

/// Converts a Unibox [core.BoxShadow] to a Flutter [BoxShadow].
BoxShadow toBoxShadow(core.BoxShadow shadow) {
  return BoxShadow(
    color: toColor(shadow.color),
    offset: Offset(shadow.offsetX, shadow.offsetY),
    blurRadius: shadow.blurRadius,
    spreadRadius: shadow.spreadRadius,
  );
}

/// Converts a Unibox [core.BoxTransform] to a Flutter [Matrix4].
///
/// Translate, then rotate, then scale — the order the model states, which is the
/// order CSS composes `translate(...) rotate(...) scale(...)` in. The rotation is
/// given in degrees because that is how CSS writes it; the matrix wants radians.
Matrix4 toMatrix4(core.BoxTransform transform) {
  return Matrix4.identity()
    ..translateByDouble(transform.offsetX, transform.offsetY, 0, 1)
    ..rotateZ(transform.rotation * math.pi / 180)
    ..scaleByDouble(
      transform.scale * transform.scaleX,
      transform.scale * transform.scaleY,
      1,
      1,
    );
}

/// Converts a Unibox [core.BoxCurve] to a Flutter [Curve].
///
/// The five curves are the ones CSS and Flutter share the control points of, so a
/// transition eases the same way on both targets.
Curve toCurve(core.BoxCurve curve) {
  return switch (curve) {
    core.BoxCurve.linear => Curves.linear,
    core.BoxCurve.ease => Curves.ease,
    core.BoxCurve.easeIn => Curves.easeIn,
    core.BoxCurve.easeOut => Curves.easeOut,
    core.BoxCurve.easeInOut => Curves.easeInOut,
  };
}

/// Converts a Unibox [core.ImageFit] to a Flutter [BoxFit].
///
/// Every value of the model has an exact counterpart, `scaleDown` included: both
/// sides scale the picture down to fit and never enlarge it.
BoxFit toBoxFit(core.ImageFit fit) {
  return switch (fit) {
    core.ImageFit.cover => BoxFit.cover,
    core.ImageFit.contain => BoxFit.contain,
    core.ImageFit.fill => BoxFit.fill,
    core.ImageFit.scaleDown => BoxFit.scaleDown,
  };
}

/// Resolves the [ImageProvider] for an image [src].
///
/// Absolute `http`/`https` URLs are fetched from the network, every other
/// value is treated as an asset path.
ImageProvider<Object> toImageProvider(String src) {
  final String? scheme = Uri.tryParse(src)?.scheme;
  if (scheme == 'http' || scheme == 'https') {
    return NetworkImage(src);
  }
  return AssetImage(src);
}

/// Builds the [BoxDecoration] painted behind a box for [style].
///
/// Returns `null` when the style paints nothing, so that no extra layer is
/// inserted in the widget tree.
BoxDecoration? toDecoration(core.BoxStyle style) {
  final core.BoxBorder? border = style.border;
  final bool hasBorder = border != null && border.isVisible;
  final List<core.BoxShadow>? shadows = style.shadows;
  final double? borderRadius = style.borderRadius;
  final core.BoxBorderRadius? corners = style.corners;
  final core.BoxColor? backgroundColor = style.backgroundColor;

  if (backgroundColor == null &&
      !hasBorder &&
      (shadows == null || shadows.isEmpty) &&
      borderRadius == null &&
      corners == null) {
    return null;
  }

  return BoxDecoration(
    color: backgroundColor == null ? null : toColor(backgroundColor),
    border: hasBorder
        ? Border.all(color: toColor(border.color), width: border.width)
        : null,
    borderRadius: corners != null
        ? toFlutterBorderRadius(corners)
        : borderRadius == null
        ? null
        : BorderRadius.circular(borderRadius),
    boxShadow: shadows == null || shadows.isEmpty
        ? null
        : shadows.map(toBoxShadow).toList(growable: false),
  );
}

/// [alignment] as Flutter's own.
Alignment toAlignment(core.BoxAlignment alignment) => switch (alignment) {
  core.BoxAlignment.topStart => Alignment.topLeft,
  core.BoxAlignment.topCenter => Alignment.topCenter,
  core.BoxAlignment.topEnd => Alignment.topRight,
  core.BoxAlignment.centerStart => Alignment.centerLeft,
  core.BoxAlignment.center => Alignment.center,
  core.BoxAlignment.centerEnd => Alignment.centerRight,
  core.BoxAlignment.bottomStart => Alignment.bottomLeft,
  core.BoxAlignment.bottomCenter => Alignment.bottomCenter,
  core.BoxAlignment.bottomEnd => Alignment.bottomRight,
};

/// The single alignment a box states with a main and a cross one.
///
/// A flex has two axes and a stack's cell has one corner, so the pair reads as one
/// [core.BoxAlignment] once [direction] says which axis is which — the same reading
/// the web renderer gets for free, where a flex aligns its one flow child.
///
/// The three distributing values exist for several children, and a box with one
/// places it as near an edge as it can: `spaceBetween` starts, and `spaceAround` and
/// `spaceEvenly` centre it. A `stretch` cannot be honoured by an alignment at all —
/// a stack does not stretch a child — so the child starts, which is where it would
/// sit without the token.
core.BoxAlignment toBoxAlignment(
  core.MainAlign mainAlign,
  core.CrossAlign crossAlign,
  core.Axis direction,
) {
  final int main = switch (mainAlign) {
    core.MainAlign.start || core.MainAlign.spaceBetween => -1,
    core.MainAlign.center ||
    core.MainAlign.spaceAround ||
    core.MainAlign.spaceEvenly => 0,
    core.MainAlign.end => 1,
  };
  final int cross = switch (crossAlign) {
    // A stack aligns a child in a cell, and a cell has no line of text to sit on: a
    // baseline places the child at the start, which is what Flutter does with one on
    // a vertical axis.
    core.CrossAlign.start ||
    core.CrossAlign.stretch ||
    core.CrossAlign.baseline => -1,
    core.CrossAlign.center => 0,
    core.CrossAlign.end => 1,
  };
  final (int x, int y) = direction == core.Axis.horizontal
      ? (main, cross)
      : (cross, main);

  return switch ((x, y)) {
    (-1, -1) => core.BoxAlignment.topStart,
    (0, -1) => core.BoxAlignment.topCenter,
    (1, -1) => core.BoxAlignment.topEnd,
    (-1, 0) => core.BoxAlignment.centerStart,
    (0, 0) => core.BoxAlignment.center,
    (1, 0) => core.BoxAlignment.centerEnd,
    (-1, 1) => core.BoxAlignment.bottomStart,
    (0, 1) => core.BoxAlignment.bottomCenter,
    _ => core.BoxAlignment.bottomEnd,
  };
}

/// [alignment] as Flutter's own, written so that a start and an end follow the
/// ambient text direction: a `MainAlign.start` is the leading edge on both, which is
/// what a browser's `flex-start` means.
AlignmentDirectional toDirectionalAlignment(core.BoxAlignment alignment) =>
    switch (alignment) {
      core.BoxAlignment.topStart => AlignmentDirectional.topStart,
      core.BoxAlignment.topCenter => AlignmentDirectional.topCenter,
      core.BoxAlignment.topEnd => AlignmentDirectional.topEnd,
      core.BoxAlignment.centerStart => AlignmentDirectional.centerStart,
      core.BoxAlignment.center => AlignmentDirectional.center,
      core.BoxAlignment.centerEnd => AlignmentDirectional.centerEnd,
      core.BoxAlignment.bottomStart => AlignmentDirectional.bottomStart,
      core.BoxAlignment.bottomCenter => AlignmentDirectional.bottomCenter,
      core.BoxAlignment.bottomEnd => AlignmentDirectional.bottomEnd,
    };

/// The four corners of [corners] as Flutter's own radius.
BorderRadius toFlutterBorderRadius(core.BoxBorderRadius corners) =>
    BorderRadius.only(
      topLeft: Radius.circular(corners.topLeft),
      topRight: Radius.circular(corners.topRight),
      bottomRight: Radius.circular(corners.bottomRight),
      bottomLeft: Radius.circular(corners.bottomLeft),
    );

/// Builds the [BoxConstraints] described by the min/max tokens of [style].
///
/// Returns `null` when the style sets no bounds.
BoxConstraints? toConstraints(core.BoxStyle style) {
  if (style.minWidth == null &&
      style.maxWidth == null &&
      style.minHeight == null &&
      style.maxHeight == null) {
    return null;
  }

  return BoxConstraints(
    minWidth: style.minWidth ?? 0,
    maxWidth: style.maxWidth ?? double.infinity,
    minHeight: style.minHeight ?? 0,
    maxHeight: style.maxHeight ?? double.infinity,
  );
}

/// Converts a Flutter [PointerDeviceKind] to the portable kind.
///
/// A trackpad is a mouse as far as the tree is concerned, and a stylus and its
/// inverted end are both a pen; the model names the devices both hosts can, not the
/// ones one engine happens to distinguish.
core.BoxPointerKind toPointerKind(PointerDeviceKind? kind) {
  return switch (kind) {
    PointerDeviceKind.touch => core.BoxPointerKind.touch,
    PointerDeviceKind.mouse || null => core.BoxPointerKind.mouse,
    PointerDeviceKind.trackpad => core.BoxPointerKind.mouse,
    PointerDeviceKind.stylus ||
    PointerDeviceKind.invertedStylus => core.BoxPointerKind.pen,
    _ => core.BoxPointerKind.unknown,
  };
}
