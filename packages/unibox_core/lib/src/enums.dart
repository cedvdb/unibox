/// The direction in which the children of a box are laid out.
enum Axis {
  /// Children are laid out from left to right.
  horizontal,

  /// Children are laid out from top to bottom.
  vertical,
}

/// Distribution of children along the main axis of a box.
enum MainAlign {
  /// Pack children at the start of the main axis.
  start,

  /// Pack children at the center of the main axis.
  center,

  /// Pack children at the end of the main axis.
  end,

  /// Evenly distribute children, with no space at the edges.
  spaceBetween,

  /// Evenly distribute children, with half sized space at the edges.
  spaceAround,

  /// Evenly distribute children, with equal space between and around them.
  spaceEvenly,
}

/// Alignment of children along the cross axis of a box.
enum CrossAlign {
  /// Align children at the start of the cross axis.
  start,

  /// Align children at the center of the cross axis.
  center,

  /// Align children at the end of the cross axis.
  end,

  /// Stretch children to fill the cross axis.
  stretch,
}

/// Where a child sits in the cell of a stack, both axes at once.
///
/// [MainAlign] and [CrossAlign] answer for one axis of a flex container; a stack has
/// two axes and no direction of its own, so a child placed in it names both. The nine
/// positions are the corners, the edges and the middle.
///
/// It is what a floating control needs: a button pinned to the bottom centre of the
/// surface it floats over, rather than at offsets that suit one window.
enum BoxAlignment {
  /// The top left corner.
  topStart,

  /// The top edge, centred.
  topCenter,

  /// The top right corner.
  topEnd,

  /// The left edge, centred.
  centerStart,

  /// The middle.
  center,

  /// The right edge, centred.
  centerEnd,

  /// The bottom left corner.
  bottomStart,

  /// The bottom edge, centred.
  bottomCenter,

  /// The bottom right corner.
  bottomEnd,
}

/// The easing of a [BoxTransition].
///
/// These five are the curves CSS and Flutter define with the same control points,
/// so a transition that declares one of them eases identically on both targets:
/// `ease` is `cubic-bezier(0.25, 0.1, 0.25, 1)` in CSS and `Curves.ease` in
/// Flutter, and the other four match the same way.
enum BoxCurve {
  /// Constant speed from start to end.
  linear,

  /// Slow at the ends, faster in the middle: the CSS default.
  ease,

  /// Slow at the start, then accelerate.
  easeIn,

  /// Fast at the start, then decelerate.
  easeOut,

  /// Slow at both ends.
  easeInOut,
}

/// A state a box can be styled for.
///
/// Only states that a pointer, a keyboard and a touch screen all have are part
/// of the model, so every target can express them: `:hover`, `:focus-visible`
/// and `:active` on the web, the same three on Flutter, plus a disabled control
/// on both.
enum BoxState {
  /// The pointer is over the box.
  hover,

  /// The box has keyboard focus.
  focus,

  /// The box is being activated, by a pointer held down or a key held down.
  pressed,

  /// The box does not react to input, see `Box.enabled`.
  disabled,
}

/// The kind of value a single line text input expects.
///
/// The type drives the on-screen keyboard of a touch device and the validation
/// hints of a browser, so typing an address on a phone offers the right keys
/// without any host code.
enum InputType {
  /// Free form text, the default.
  text,

  /// An email address.
  email,

  /// A number.
  number,

  /// A telephone number.
  phone,

  /// A url.
  url,
}

/// How content that exceeds the bounds of a box is treated.
enum Overflow {
  /// Content may paint outside of the box.
  visible,

  /// Content is clipped at the box bounds.
  hidden,

  /// The box becomes scrollable along its main axis.
  scroll,
}

/// Where a scrolling box comes to rest when a gesture ends.
///
enum ScrollSnap {
  /// Wherever the gesture left it, which is what a list does.
  none,

  /// On a child, one child at a time: a pager, a carousel, a wizard step.
  ///
  /// The axis is the box's own ([BoxStyle.resolvedDirection]), so a row of full width
  /// pages pages sideways and a column of full height pages downwards, and the value sits
  /// on the scrolling box rather than inside a new node type: a pager is a scrolling box
  /// that settles.
  page,
}

/// How an image fills its bounds.
enum ImageFit {
  /// Scale the image to cover its bounds, cropping when needed.
  cover,

  /// Scale the image to fit inside its bounds, preserving aspect ratio.
  contain,

  /// Stretch the image to fill its bounds, ignoring aspect ratio.
  fill,

  /// Fit the image inside its bounds without ever enlarging it.
  ///
  /// This is the default, and it is the default for the same reason the typography
  /// has one: the two targets would otherwise answer differently. A Flutter
  /// `Image` without a fit scales the picture down on its own, while a browser
  /// stretches it over its box (`object-fit: fill`), so an undeclared image would
  /// look cropped on one target and squashed on the other. CSS spells this value
  /// `object-fit: scale-down`, which is exactly what `BoxFit.scaleDown` does.
  scaleDown,
}

/// When a browser fetches an image.
///
/// The value is HTML's `loading` attribute. Flutter has no counterpart — an
/// `Image` widget starts loading when it is built — so the default is the answer
/// Flutter already gives, and a lazy image is an optimisation the web alone can
/// honour.
enum ImageLoading {
  /// Fetch the image at once, even while it is off screen.
  eager,

  /// Wait until the image comes near the viewport before fetching it.
  lazy,

  /// Leave the decision to the browser.
  auto,
}

/// How much a browser should prioritise one image against the others on a page.
///
/// The value is HTML's `fetchpriority` attribute, which a browser may use to
/// order fetches it has already started. Flutter has no counterpart, and the
/// value never changes a rendering.
enum ImageFetchPriority {
  /// Raise the image above the default priority, for a hero image.
  high,

  /// Lower it below the default, for decoration far down the page.
  low,

  /// Let the browser decide.
  auto,
}

/// Relative weight of a font.
enum FontWeight {
  /// Regular text weight.
  normal,

  /// Slightly emphasized text weight.
  medium,

  /// Strongly emphasized text weight.
  semiBold,

  /// Heaviest supported text weight.
  bold,
}

/// Horizontal alignment of text inside its bounds.
enum TextAlign {
  /// Align text to the left edge (start for left-to-right text).
  left,

  /// Center text horizontally.
  center,

  /// Align text to the right edge.
  right,

  /// Stretch lines so both edges are aligned.
  justify,
}

/// How text that does not fit its bounds is truncated.
enum TextOverflow {
  /// Clip the overflowing text.
  clip,

  /// Truncate the overflowing text with an ellipsis.
  ellipsis,
}
