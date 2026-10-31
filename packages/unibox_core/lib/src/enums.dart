/// The direction in which the children of a box are laid out.
enum Axis {
  /// Children are laid out from left to right.
  horizontal,

  /// Children are laid out from top to bottom.
  vertical,
}

/// The direction writing flows in, which is what "start" and "end" mean.
///
/// It is not [Axis]. A row lays its children along one axis whichever way the words
/// in it read, and the two are separate facts about one box: Arabic in a row is the
/// same rectangle with the children packed from the other side.
///
/// A direction is inherited, the way typography is — CSS inherits `direction` and
/// Flutter's `Directionality` is ambient — so a box states it once and everything
/// inside it reads that way, unless something inside states its own. That is what
/// makes it a property of a region rather than of the document: a quotation, a code
/// block or a price written in the other script states the direction it is written in
/// and the rest of the page keeps its own.
///
/// There is no `auto`, which is CSS's `dir="auto"`: it reads the first strong
/// character of the text, and Flutter has no counterpart — a value only one target
/// can honour is a bug here. A box that says nothing inherits, so "let the text
/// decide" is the page's direction and not a third value.
enum WritingDirection {
  /// Writing flows from left to right: English, Dutch, Greek.
  ltr,

  /// Writing flows from right to left: Arabic, Hebrew, Persian, Urdu.
  rtl,
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

  /// Align children so that their first lines of text sit on one baseline.
  ///
  /// The one cross alignment that knows where the glyphs are: a row of a 14px
  /// label and a 24px price aligned any other way lines their boxes up, and the
  /// two texts then sit at different heights. `CrossAxisAlignment.baseline` and
  /// `align-items: baseline` both say it, so the two targets agree on it.
  ///
  /// The baseline is the alphabetic one, which is what both engines default to
  /// and the only one CSS can name. A child with no text in it reports no
  /// baseline: Flutter tops it out and CSS falls back to the bottom edge of the
  /// child, so a row that aligns on the baseline is a row of text.
  ///
  /// Only a horizontal box has one. A vertical box aligns its children across a
  /// horizontal axis, where a horizontal line describes nothing: Flutter treats
  /// the value as [start] and a browser shifts the children sideways to line the
  /// baselines up. The two then lay the same tree out differently, so
  /// `validateTree` reports it.
  baseline,
}

/// Where a child sits in the cell of a stack, both axes at once.
///
/// [MainAlign] and [CrossAlign] answer for one axis of a flex container; a stack has
/// two axes and no direction of its own, so a child placed in it names both. The nine
/// positions are the corners, the edges and the middle.
///
/// The names are the reading ones and not the screen's: `topStart` is the corner the
/// words begin at — the left one in Dutch and the right one in Arabic — and every
/// `Start` and `End` follows the writing direction of the box the child sits in. That is
/// what CSS's `justify-content: start` means, and naming a physical corner would need a
/// second tree per language, which is the drift the model exists to prevent.
///
/// It is what a floating control needs: a button pinned to the bottom centre of the
/// surface it floats over, rather than at offsets that suit one window.
enum BoxAlignment {
  /// The corner at the start of the top edge.
  topStart,

  /// The middle of the top edge.
  topCenter,

  /// The corner at the end of the top edge.
  topEnd,

  /// The middle of the start edge.
  centerStart,

  /// The middle.
  center,

  /// The middle of the end edge.
  centerEnd,

  /// The corner at the start of the bottom edge.
  bottomStart,

  /// The middle of the bottom edge.
  bottomCenter,

  /// The corner at the end of the bottom edge.
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

/// The edge of a scrolling box a box stays at while the content scrolls past it.
///
/// A pinned box keeps its slot in the flow — nothing below it moves — and is painted at
/// the named edge of the box that scrolls it once it would have scrolled past. It is the
/// relation, not the mechanism: a browser writes it as `position: sticky` with an inset,
/// and this package's Flutter renderer paints the band over the viewport it pins to, so
/// both resolve the edge the same way.
///
/// The two edges are the vertical ones, in the direction a page scrolls, so only a box
/// that scrolls vertically holds one: a pin inside a row that scrolls sideways would
/// name an edge nothing moves along, and `validateTree` reports it. So does a pin that is
/// not a child of the box that scrolls it, because a band is drawn by that box.
enum BoxPin {
  /// The leading edge of the scrolling box: the top of a vertical viewport.
  start,

  /// The trailing edge of the scrolling box: the bottom of a vertical viewport.
  end,
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
///
/// The five weights every target can name without a variable font: CSS writes
/// them as `100`–`900` in steps of a hundred, and Flutter as `FontWeight.w300`
/// to `w700`. The ones below 300 and above 700 are left out because the two
/// engines disagree about what they mean — a browser synthesises a `100` from a
/// family that has no such cut, while Flutter picks the closest face and warns
/// in debug — so a token either target would draw differently is not a token.
enum FontWeight {
  /// A light weight, for a label that has to recede: `300`.
  light,

  /// Regular text weight: `400`.
  normal,

  /// Slightly emphasized text weight: `500`.
  medium,

  /// Strongly emphasized text weight: `600`.
  semiBold,

  /// Heaviest supported text weight: `700`.
  bold,
}

/// A line drawn across a run of text.
///
/// Three of CSS's five values are here, and the two that are missing are missing
/// for one reason: both targets have to draw the same line. `overline` has no
/// counterpart in Flutter's `TextDecoration`, and `double` and `wavy` are style
/// values CSS draws itself — Flutter paints one solid line and would silently
/// draw something else. `none` is a value rather than an absence because it is
/// how a run of text takes back a decoration: a link's underline, a struck
/// through price in a card that strikes nothing else.
enum TextDecoration {
  /// No line at all.
  none,

  /// A line through the middle of the text, the way the price that is no longer
  /// paid is struck through.
  lineThrough,

  /// A line under the text.
  underline,
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
