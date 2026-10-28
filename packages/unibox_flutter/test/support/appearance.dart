import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_testing/unibox_testing.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'harness.dart';

/// The presentation this renderer gave the root box of [pumpNode].
///
/// The facts are read from the widget tree the renderer built — the flex it
/// created, the padding it applied, the decoration it painted — and never from
/// the node tree, so they describe what this target *did* with the node. The
/// Jaspr suite reads the same facts out of the CSS its renderer emitted, and both
/// compare them with the table in `unibox_testing`.
///
/// The rendered root node has to be a [core.Box]; a suite that renders anything
/// else is asking the wrong question.
BoxAppearance appearanceOf(WidgetTester tester) {
  final Element box = inNode(
    find.byWidgetPredicate((Widget widget) => widget is FlutterBox),
  ).evaluate().first;

  final List<Element> parts = _ownParts(box);
  final int flexIndex = parts.indexWhere((Element e) => e.widget is Flex);

  // Every box renders a flex container, so a box without one has lost its
  // layout: reporting the model defaults here would let that pass.
  if (flexIndex < 0) {
    throw StateError('The box was rendered without a flex container.');
  }

  final Flex flex = parts[flexIndex].widget as Flex;
  final int contentIndex = flexIndex;

  final SizedBox? sized = _sizedBoxBefore(parts, contentIndex);
  final BoxDecoration? decoration = _decorationBefore(parts, contentIndex);
  final List<EdgeInsets> paddings = _paddingsBefore(parts, contentIndex);
  final ({Duration duration, core.BoxCurve curve})? transition =
      _transitionBefore(parts, contentIndex);
  final core.BoxTransform? transform = _transformBefore(parts, contentIndex);
  final double? opacity = _opacityBefore(parts, contentIndex);

  final BorderRadius? radius = decoration?.borderRadius as BorderRadius?;
  final Border? border = decoration?.border as Border?;
  final BorderSide? side = border?.top;
  final Color? background = decoration?.color;
  final core.BoxBorderRadius? corners = _cornersOf(radius);

  return BoxAppearance(
    direction: _axisOf(flex.direction),
    mainAlign: _mainAlignOf(flex.mainAxisAlignment),
    crossAlign: _crossAlignOf(flex.crossAxisAlignment),
    gap: _gapOf(parts, flexIndex),
    // A box applies its margin outside its padding, so in a pre-order walk the
    // margin comes first. A box with a single edge inset is reported as padded:
    // without a decoration to cover the inset, a margin and a padding of the same
    // size look identical anyway.
    padding: paddings.isEmpty ? null : _spacingOf(paddings.last),
    margin: paddings.length > 1 ? _spacingOf(paddings.first) : null,
    width: sized?.width,
    height: sized?.height,
    backgroundColor: background == null
        ? null
        : core.BoxColor(background.toARGB32()),
    borderRadius: corners == null || !corners.isUniform || corners.uniform == 0
        ? null
        : corners.uniform,
    corners: corners == null || corners.isUniform ? null : corners,
    borderWidth: side?.width,
    borderColor: side == null ? null : core.BoxColor(side.color.toARGB32()),
    transitionDuration: transition?.duration,
    transitionCurve: transition?.curve,
    opacity: opacity,
    transform: transform,
  );
}

/// The typesetting this renderer gave the text node of [pumpNode].
///
/// The facts are read from the `Text` widget the renderer built — the `TextStyle`
/// it declared, the alignment, the line limit and the truncation it asked for —
/// and never from the node tree. That is what makes the answer comparable with the
/// CSS the Jaspr renderer emitted: only what this target *said* about the node is
/// compared, not what a font engine made of it.
///
/// `Text.style` holds the tokens the renderer declared and nothing else, so a
/// token the node left unset reads back as `null` even though the inherited style
/// fills it in at paint time. [resolvedTextAppearanceOf] is the other half of that
/// pair.
TextAppearance textAppearanceOf(WidgetTester tester) {
  final Text text = _textOf(tester);

  return _textAppearance(
    text.style,
    textAlign: text.textAlign,
    maxLines: text.maxLines,
    overflow: text.overflow,
  );
}

/// The typesetting the text node is actually typeset in.
///
/// The style is resolved the way Flutter resolves it before painting: the
/// inherited style of the closest `DefaultTextStyle` — which `renderFlutter`
/// installs from the model — with the tokens the node declared laid over it. The
/// Jaspr suite resolves the same pair from its `:root` rule and the declarations
/// of the span.
TextAppearance resolvedTextAppearanceOf(WidgetTester tester) {
  final Element element = inNode(find.byType(Text)).evaluate().first;
  final Text text = _textOf(tester);

  return _textAppearance(
    DefaultTextStyle.of(element).style.merge(text.style),
    textAlign: text.textAlign,
    maxLines: text.maxLines,
    overflow: text.overflow,
  );
}

/// The characters the renderer put into the text widget it built.
String renderedTextOf(WidgetTester tester) => _textOf(tester).data ?? '';

/// The `Text` widget the renderer built for the node under test.
Text _textOf(WidgetTester tester) =>
    tester.widget<Text>(inNode(find.byType(Text)).first);

/// The typography a Flutter text style describes.
TextAppearance _textAppearance(
  TextStyle? style, {
  required TextAlign? textAlign,
  required int? maxLines,
  required TextOverflow? overflow,
}) {
  final FontWeight? weight = style?.fontWeight;
  final Color? color = style?.color;

  return TextAppearance(
    fontSize: style?.fontSize,
    fontWeight: weight == null ? null : _fontWeightOf(weight),
    color: color == null ? null : core.BoxColor(color.toARGB32()),
    lineHeight: style?.height,
    fontFamily: style?.fontFamily,
    letterSpacing: style?.letterSpacing,
    textAlign: textAlign == null ? null : _textAlignOf(textAlign),
    maxLines: maxLines,
    overflow: overflow == null ? null : _overflowOf(overflow),
  );
}

/// The core weight of a Flutter font weight.
///
/// The model has four weights, so a renderer that passed a finer one to Flutter
/// described something the other target cannot express.
core.FontWeight _fontWeightOf(FontWeight weight) {
  return switch (weight) {
    FontWeight.w400 => core.FontWeight.normal,
    FontWeight.w500 => core.FontWeight.medium,
    FontWeight.w600 => core.FontWeight.semiBold,
    FontWeight.w700 => core.FontWeight.bold,
    _ => throw StateError('The model has no font weight for $weight.'),
  };
}

/// The core alignment of a Flutter text alignment.
core.TextAlign _textAlignOf(TextAlign align) {
  return switch (align) {
    TextAlign.left => core.TextAlign.left,
    TextAlign.center => core.TextAlign.center,
    TextAlign.right => core.TextAlign.right,
    TextAlign.justify => core.TextAlign.justify,
    _ => throw StateError('The model has no text alignment for $align.'),
  };
}

/// The core truncation of a Flutter text overflow.
core.TextOverflow _overflowOf(TextOverflow overflow) {
  return switch (overflow) {
    TextOverflow.clip => core.TextOverflow.clip,
    TextOverflow.ellipsis => core.TextOverflow.ellipsis,
    _ => throw StateError('The model has no truncation for $overflow.'),
  };
}

/// Every element of the subtree of [box], up to but excluding the widgets of the
/// nodes below it.
///
/// A nested node renders its own facts, so the walk has to stop at its renderer:
/// otherwise a box would report the decoration and the padding of its children.
List<Element> _ownParts(Element box) {
  final List<Element> parts = <Element>[];

  void visit(Element element) {
    parts.add(element);
    element.visitChildElements((Element child) {
      if (_isNodeRenderer(child.widget)) {
        return;
      }
      visit(child);
    });
  }

  visit(box);
  return parts;
}

/// Whether [widget] renders a node of the tree, and therefore starts a new fact.
bool _isNodeRenderer(Widget widget) {
  return widget is FlutterBox ||
      widget is FlutterText ||
      widget is FlutterTextInput ||
      widget is FlutterLink ||
      widget is FlutterImage ||
      widget is FlutterStack;
}

/// The transition the renderer applied to this node, if it applied one.
///
/// A box that eases its look hands the decoration to a `TweenAnimationBuilder`,
/// which is what makes the duration and the curve readable from the widget tree.
({Duration duration, core.BoxCurve curve})? _transitionBefore(
  List<Element> parts,
  int end,
) {
  for (var index = 0; index < end; index++) {
    final Widget widget = parts[index].widget;
    if (widget is TweenAnimationBuilder<Decoration>) {
      return (duration: widget.duration, curve: _curveOf(widget.curve));
    }
  }
  return null;
}

/// The core curve of a Flutter [Curve].
///
/// The five curves are the ones the model shares with CSS, so a curve outside
/// them is a renderer that invented an easing the other target cannot express.
core.BoxCurve _curveOf(Curve curve) {
  return switch (curve) {
    Curves.linear => core.BoxCurve.linear,
    Curves.ease => core.BoxCurve.ease,
    Curves.easeIn => core.BoxCurve.easeIn,
    Curves.easeOut => core.BoxCurve.easeOut,
    Curves.easeInOut => core.BoxCurve.easeInOut,
    _ => throw StateError('The model has no curve for $curve.'),
  };
}

/// The transform the renderer painted the node with, if it painted one.
///
/// The renderer composes translate, rotate and scale into one matrix about the
/// centre, so the parts can be read back out of it: the translation is the last
/// column, the scale the length of the first basis vector and the rotation the
/// angle between that vector and the x axis. An identity matrix is reported as no
/// transform, because the two paint the same box.
core.BoxTransform? _transformBefore(List<Element> parts, int end) {
  for (var index = 0; index < end; index++) {
    final Widget widget = parts[index].widget;
    if (widget is Transform) {
      // A transform is read as the two axis factors it paints, because a matrix
      // cannot say which of `scale` and `scaleX`/`scaleY` produced it: the model's
      // shorthand and its per-axis stretch are the same pixels.
      final Matrix4 matrix = widget.transform;
      final core.BoxTransform transform = core.BoxTransform(
        scaleX: _rounded(_hypot(matrix.entry(0, 0), matrix.entry(1, 0))),
        scaleY: _rounded(_hypot(matrix.entry(0, 1), matrix.entry(1, 1))),
        rotation: _rounded(
          math.atan2(matrix.entry(1, 0), matrix.entry(0, 0)) * 180 / math.pi,
        ),
        offsetX: _rounded(matrix.entry(0, 3)),
        offsetY: _rounded(matrix.entry(1, 3)),
      );
      return transform.isIdentity ? null : transform;
    }
  }
  return null;
}

/// An opacity of `1` reads as no opacity.
///
/// A box with a transition always carries the wrapper, because the host may
/// change its look; a solid box and one that happens to be at rest paint the
/// same thing.
double? _opacityValue(double value) => value >= 1 ? null : value;

/// The length of the vector ([x], [y]).
///
/// A rotation and a scale are the same two entries of a matrix, so each axis factor
/// is a length: the diagonal would read `0` for a box turned 90 degrees.
double _hypot(double x, double y) => math.sqrt(x * x + y * y);

/// Rounds a number that was read out of a matrix.
///
/// Turning a rotation back into degrees means trigonometry, which answers
/// `14.999999999999998` where the model said `15`. Comparing them exactly
/// would report a difference nobody can see.
double _rounded(double value) => double.parse(value.toStringAsFixed(6));

/// The opacity the renderer painted the node with, if it painted one.
///
/// A box that can change its look uses `AnimatedOpacity`, a static one `Opacity`;
/// both state the same number.

double? _opacityBefore(List<Element> parts, int end) {
  for (var index = 0; index < end; index++) {
    final Widget widget = parts[index].widget;
    if (widget is AnimatedOpacity) {
      return _opacityValue(widget.opacity);
    }
    if (widget is Opacity) {
      return _opacityValue(widget.opacity);
    }
  }
  return null;
}

/// The box the renderer sized this node with, if the node declares a size.
SizedBox? _sizedBoxBefore(List<Element> parts, int end) {
  for (var index = 0; index < end; index++) {
    final Widget widget = parts[index].widget;
    if (widget is SizedBox && (widget.width != null || widget.height != null)) {
      return widget;
    }
  }
  return null;
}

/// The decoration the renderer painted behind this node.
BoxDecoration? _decorationBefore(List<Element> parts, int end) {
  for (var index = 0; index < end; index++) {
    final Widget widget = parts[index].widget;
    if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
      return widget.decoration as BoxDecoration;
    }
  }
  return null;
}

/// The edge insets the renderer applied to this node, outermost first.
List<EdgeInsets> _paddingsBefore(List<Element> parts, int end) {
  final List<EdgeInsets> paddings = <EdgeInsets>[];

  for (var index = 0; index < end; index++) {
    final Widget widget = parts[index].widget;
    if (widget is! Padding) {
      continue;
    }

    final EdgeInsetsGeometry padding = widget.padding;
    if (padding is EdgeInsets) {
      paddings.add(padding);
    }
  }

  return paddings;
}

/// The space the renderer put between two children of the flex at [flexIndex].
double? _gapOf(List<Element> parts, int flexIndex) {
  if (flexIndex < 0) {
    return null;
  }

  for (var index = flexIndex + 1; index < parts.length; index++) {
    final Widget widget = parts[index].widget;
    if (widget is SizedBox && widget.child == null) {
      return widget.width ?? widget.height;
    }
  }

  return null;
}

/// The core spacing of a Flutter edge inset.
core.BoxSpacing _spacingOf(EdgeInsets insets) {
  return core.BoxSpacing(
    top: insets.top,
    right: insets.right,
    bottom: insets.bottom,
    left: insets.left,
  );
}

/// The core axis of a Flutter axis.
core.Axis _axisOf(Axis axis) {
  return axis == Axis.horizontal ? core.Axis.horizontal : core.Axis.vertical;
}

/// The core alignment of a Flutter main axis alignment.
core.MainAlign _mainAlignOf(MainAxisAlignment align) {
  return switch (align) {
    MainAxisAlignment.start => core.MainAlign.start,
    MainAxisAlignment.end => core.MainAlign.end,
    MainAxisAlignment.center => core.MainAlign.center,
    MainAxisAlignment.spaceBetween => core.MainAlign.spaceBetween,
    MainAxisAlignment.spaceAround => core.MainAlign.spaceAround,
    MainAxisAlignment.spaceEvenly => core.MainAlign.spaceEvenly,
  };
}

/// The core alignment of a Flutter cross axis alignment.
core.CrossAlign _crossAlignOf(CrossAxisAlignment align) {
  return switch (align) {
    CrossAxisAlignment.start => core.CrossAlign.start,
    CrossAxisAlignment.end => core.CrossAlign.end,
    CrossAxisAlignment.center => core.CrossAlign.center,
    CrossAxisAlignment.stretch => core.CrossAlign.stretch,
    // A baseline has no counterpart on the cross axis of a box, so a renderer
    // that aligned on it would be laying the box out differently.
    CrossAxisAlignment.baseline => throw StateError(
      'A box cannot align its children on a baseline.',
    ),
  };
}

/// The four corners Flutter drew, or `null` when it drew no decoration.
core.BoxBorderRadius? _cornersOf(BorderRadius? radius) => radius == null
    ? null
    : core.BoxBorderRadius(
        topLeft: radius.topLeft.x,
        topRight: radius.topRight.x,
        bottomRight: radius.bottomRight.x,
        bottomLeft: radius.bottomLeft.x,
      );
