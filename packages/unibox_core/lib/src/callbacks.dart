import 'events.dart';

/// Called when an interactive node is tapped.
typedef TapCallback = void Function();

/// Called when an interactive node is long pressed.
typedef LongPressCallback = void Function();

/// Called when the pointer enters (`true`) or leaves (`false`) a node.
typedef HoverCallback = void Function(bool isHovered);

/// Called as a scrolling box scrolls, with how far its content has moved.
///
/// [offset] is the distance in logical pixels from the start of the content along
/// the box's main axis: `0` at rest, growing as the content moves up (or left). It is
/// the one number both targets can report exactly — `ScrollMetrics.pixels` in Flutter,
/// `scrollTop`/`scrollLeft` in a browser.
typedef ScrollCallback = void Function(double offset);

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
