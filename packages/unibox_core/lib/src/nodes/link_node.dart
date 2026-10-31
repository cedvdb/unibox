import '../tokens/box_style.dart';
import 'box.dart';

/// A [Box] that names a destination: a link.
///
/// It *is* the box — the same element, the same look, the same children, the same press —
/// with a `url` on it, so the whole of it is the thing a reader presses and, on the web, a
/// real `<a href>` that a crawler can follow and a page without a runtime can use. That is
/// why a link is a node and not a wrapper around one: a wrapper states no layout, so a
/// control inside it keeps the flex share, the height and the padding that the anchor
/// should have had — and a press on the control inside it is a press the link never sees.
///
/// ```dart
/// LinkNode('/rooms/1', padding: BoxSpacing.all(16), children: <UINode>[TextNode('One')])
/// ```
///
/// The destination is the element: the web writes `<a href>` with this box's class, and a
/// role, a tab stop and the states of a control are not written on it, because the tag is
/// the role. A disabled link writes no `href`, so nothing navigates and no tab stop is
/// added. `newTab` is the web's: Flutter has no tab, and following a destination there is
/// the host's decision, taken once in the link scope.
///
/// `validateTree` reports a link inside another link, which HTML forbids and which would
/// navigate twice, and a control inside a link, which it also forbids: compose those as
/// siblings, or make the control the destination.
final class LinkNode extends Box {
  /// Creates a link to [url], with every parameter a box takes.
  const LinkNode(
    this.url, {
    super.key,
    super.children,
    super.direction,
    super.mainAlign,
    super.crossAlign,
    super.gap,
    super.wrap,
    super.flex,
    super.gridSpan,
    super.overflow,
    super.snap,
    super.page,
    super.width,
    super.height,
    super.aspectRatio,
    super.widthFraction,
    super.heightFraction,
    super.minWidth,
    super.maxWidth,
    super.minHeight,
    super.maxHeight,
    super.padding,
    super.margin,
    super.backgroundColor,
    super.borderRadius,
    super.corners,
    super.border,
    super.shadows,
    super.shape,
    super.textStyle,
    super.transition,
    super.opacity,
    super.transform,
    super.visibleFrom,
    super.visibleUntil,
    super.styles,
    super.hoverStyle,
    super.stateStyles,
    super.enabled,
    super.semantics,
    this.newTab = false,
    super.onTap,
    super.onTapDown,
    super.onLongPress,
    super.onHover,
    super.onScroll,
  });

  /// A link to [url] that is [box] in every other respect.
  ///
  /// A box and a link differ by a destination, so this copies what a box *is*: its children,
  /// its behaviour and its resolved look. The look travels as one [BoxStyle]
  /// ([Box.computedStyle]), which is why a token `Box` gains never has to be added here — it
  /// is already in the bag. The facets that are not style are the ones a reader keeps in
  /// step: the children, `enabled`, `semantics`, the two state bags and the callbacks.
  ///
  /// The copy therefore states its look as a bag, and its flat accessors — `padding`,
  /// `backgroundColor` and the rest — answer `null`. Nothing renders differently, because a
  /// renderer reads `computedStyle`; a caller inspecting the result should read it there too.
  factory LinkNode.of(Box box, String url, {bool newTab = false}) {
    return LinkNode(
      url,
      newTab: newTab,
      key: box.key,
      children: box.children,
      styles: <BoxStyle>[box.computedStyle],
      hoverStyle: box.hoverStyle,
      stateStyles: box.stateStyles,
      enabled: box.enabled,
      semantics: box.semantics,
      onTap: box.onTap,
      onTapDown: box.onTapDown,
      onLongPress: box.onLongPress,
      onHover: box.onHover,
      onScroll: box.onScroll,
    );
  }

  /// The destination.
  final String url;

  /// Whether the destination opens in a new tab, on the web.
  final bool newTab;

  /// Whether a reader can reach the link with the keyboard.
  ///
  /// Yes, and without asking: an `<a href>` is in the browser's tab order, so a link is in
  /// Flutter's too, and a destination that a keyboard could reach in a browser and not in
  /// Flutter is the drift this model exists to prevent. A hidden link is not reachable, the
  /// same rule the role follows.
  @override
  bool get isFocusable => !(semantics?.hidden ?? false);

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'link';
}
