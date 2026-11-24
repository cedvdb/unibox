import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// The easing of a static document's state layers.
const BoxTransition materialSurfaceTransition = BoxTransition(
  duration: Duration(milliseconds: 150),
);

/// Declares a control's server surface without owning interaction state.
///
/// [ink] is the colour the control's own content is painted in, and it is what Material
/// tints a state layer with: a hover is the ink at eight percent, a keyboard focus and a
/// press ten. That is the rule a native control follows, so a control whose declaration
/// states it is drawn with no state colour of its own by the renderer that substitutes it —
/// the page and the application paint one tint, from one role.
///
/// A surface with no ink is tinted with `onSurface`, which is where a control whose content
/// is ordinary text lands.
UINode materialSurface({
  required UINode child,
  TapCallback? onTap,
  String? url,
  bool newTab = false,
  LongPressCallback? onLongPress,
  HoverCallback? onHover,
  bool enabled = true,
  double? borderRadius,
  BoxColor? fill,
  BoxColor? ink,
  BoxBorder? border,
  BoxSpacing? padding,
  BoxTransition? transition,
  BoxSemantics? semantics,
  double? width,
  double? height,
  double? minWidth,
  double? minHeight,
  MainAlign? mainAlign,
  CrossAlign? crossAlign,
}) {
  final List<BoxStyle> styles = <BoxStyle>[
    BoxStyle(
      borderRadius: borderRadius,
      border: border,
      padding: padding,
      transition: transition,
      width: width,
      height: height,
      minWidth: minWidth,
      minHeight: minHeight,
      mainAlign: mainAlign,
      crossAlign: crossAlign,
    ),
  ];
  final BoxColor layer =
      ink ?? const BoxColor.role(MaterialColorRole.onSurface);
  final Map<BoxState, BoxStyle> states = <BoxState, BoxStyle>{
    BoxState.hover: BoxStyle(backgroundColor: layer.withOpacity(0.08)),
    BoxState.focus: BoxStyle(backgroundColor: layer.withOpacity(0.10)),
    BoxState.pressed: BoxStyle(backgroundColor: layer.withOpacity(0.10)),
  };
  final Box target = url != null
      ? LinkNode(
          url,
          newTab: newTab,
          onTap: onTap,
          onLongPress: onLongPress,
          onHover: onHover,
          enabled: enabled,
          styles: styles,
          stateStyles: enabled ? states : const <BoxState, BoxStyle>{},
          semantics: semantics,
          children: <UINode>[child],
        )
      : Box(
          onTap: onTap,
          onLongPress: onLongPress,
          onHover: onHover,
          enabled: enabled,
          styles: styles,
          stateStyles: enabled ? states : const <BoxState, BoxStyle>{},
          semantics: semantics,
          children: <UINode>[child],
        );
  if (fill == null) return target;

  // The translucent state layer paints over the resting fill, without fading the label
  // or replacing a selected chip's colour. The target still owns every measurement.
  return Box(
    width: width,
    backgroundColor: fill,
    borderRadius: borderRadius,
    crossAlign: CrossAlign.stretch,
    children: <UINode>[target],
  );
}
