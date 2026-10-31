import 'events.dart';

/// Called when an interactive node is tapped.
typedef TapCallback = void Function();

/// Called when an interactive node is long pressed.
typedef LongPressCallback = void Function();

/// Called when the pointer enters (`true`) or leaves (`false`) a node.
typedef HoverCallback = void Function(bool isHovered);

/// Called as a scrolling box scrolls, with how far its content has moved.
///
/// [offset] is the distance in logical pixels from the start of the content along the box's
/// main axis: `0` at rest, growing as the content moves up (or left). It is the one number
/// both hosts report — `ScrollMetrics.pixels` in Flutter, `scrollTop`/`scrollLeft` in a
/// browser — which is why the value is a plain double and not a position in two axes.
///
/// A callback fires on the frames a box actually scrolls, so a store that publishes on every
/// call re-renders the subtree on every frame of a drag: throttle in the store, not here.
typedef ScrollCallback = void Function(double offset);

/// Called when a pager comes to rest on a child, with which child it is.
///
/// [index] counts along the pager's own axis, from `0`. It is the settled answer and not
/// the offset, because a pager snaps: every offset between two pages is a number the
/// reader is passing through, and a bar that named one of them would show a tab nobody
/// chose. A pager also reports its own move — the one the tree asked for — when that move
/// arrives, so a store that keeps the index hears about every way the pager got where it is
/// and needs no marker to tell them apart.
///
/// It fires once per resting place, so a store may publish on it directly.
typedef PageChangedCallback = void Function(int index);

/// Called whenever the text of an input node changes.
typedef TextChangedCallback = void Function(String text);

/// Called when the text of an input node is submitted.
typedef TextSubmittedCallback = void Function(String text);

/// Called when a focusable node gains (`true`) or loses (`false`) focus.
typedef FocusChangedCallback = void Function(bool isFocused);

/// Called when a press lands on a node, before it is released.
///
/// The event says where the press landed inside the box and what pressed it — the
/// two facts both targets can produce exactly. [TapCallback] stays for the common
/// case, where only the activation matters.
typedef TapDownCallback = void Function(BoxTapEvent event);
