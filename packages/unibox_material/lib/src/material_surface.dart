import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// The easing of a static document's state layers.
const BoxTransition materialSurfaceTransition = BoxTransition(
  duration: Duration(milliseconds: 150),
);

/// Declares a control's server surface without owning interaction state.
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
  const Map<BoxState, BoxStyle> states = <BoxState, BoxStyle>{
    BoxState.hover: BoxStyle(
      backgroundColor: BoxColor.role(MaterialColorRole.hoverLayer),
    ),
    BoxState.focus: BoxStyle(
      backgroundColor: BoxColor.role(MaterialColorRole.focusLayer),
    ),
    BoxState.pressed: BoxStyle(
      backgroundColor: BoxColor.role(MaterialColorRole.pressedLayer),
    ),
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
