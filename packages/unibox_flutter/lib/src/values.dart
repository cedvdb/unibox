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
CrossAxisAlignment toCrossAxisAlignment(core.CrossAlign align) {
  return switch (align) {
    core.CrossAlign.start => CrossAxisAlignment.start,
    core.CrossAlign.center => CrossAxisAlignment.center,
    core.CrossAlign.end => CrossAxisAlignment.end,
    core.CrossAlign.stretch => CrossAxisAlignment.stretch,
  };
}

/// Converts a Unibox [core.FontWeight] to a Flutter [FontWeight].
FontWeight toFontWeight(core.FontWeight weight) {
  return switch (weight) {
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

/// Converts the typography of a box or a text node into a Flutter [TextStyle].
///
/// Only the tokens that are set end up in the result, so Flutter keeps
/// inheriting every other token from the enclosing `DefaultTextStyle` — which is
/// exactly how the web renderer lets CSS inherit. Returns `null` when [style]
/// sets no token.
TextStyle? toTextStyle(core.BoxTextStyle style) {
  if (style.isEmpty) {
    return null;
  }

  final core.FontWeight? weight = style.fontWeight;
  final core.BoxColor? color = style.color;

  return TextStyle(
    fontSize: style.fontSize,
    fontWeight: weight == null ? null : toFontWeight(weight),
    color: color == null ? null : toColor(color),
    height: style.lineHeight,
    fontFamily: style.fontFamily,
    letterSpacing: style.letterSpacing,
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
    ..scaleByDouble(transform.scale, transform.scale, 1, 1);
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
  final core.BoxShadow? shadow = style.shadow;
  final double? borderRadius = style.borderRadius;
  final core.BoxCorners? corners = style.corners;
  final core.BoxColor? backgroundColor = style.backgroundColor;

  if (backgroundColor == null &&
      !hasBorder &&
      shadow == null &&
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
    boxShadow: shadow == null ? null : <BoxShadow>[toBoxShadow(shadow)],
  );
}

/// The four corners of [corners] as Flutter's own radius.
BorderRadius toFlutterBorderRadius(core.BoxCorners corners) =>
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
