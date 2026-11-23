import 'package:unibox_core/unibox_core.dart';

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
      backgroundColor: fill,
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
    BoxState.hover: BoxStyle(opacity: 0.92),
    BoxState.focus: BoxStyle(opacity: 0.85),
    BoxState.pressed: BoxStyle(opacity: 0.8),
  };
  if (url != null) {
    return LinkNode(
      url,
      newTab: newTab,
      onTap: onTap,
      onLongPress: onLongPress,
      onHover: onHover,
      enabled: enabled,
      styles: styles,
      stateStyles: states,
      semantics: semantics,
      children: <UINode>[child],
    );
  }
  return Box(
    onTap: onTap,
    onLongPress: onLongPress,
    onHover: onHover,
    enabled: enabled,
    styles: styles,
    stateStyles: states,
    semantics: semantics,
    children: <UINode>[child],
  );
}
