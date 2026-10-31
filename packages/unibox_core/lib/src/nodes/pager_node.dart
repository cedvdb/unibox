import '../callbacks.dart';
import '../enums.dart';
import '../tokens/box_style.dart';
import 'box.dart';

/// A [Box] that settles on one child at a time: a pager.
///
/// It scrolls along its own `direction` and stops on a child instead of between two, so a
/// row of full-width pages pages sideways and a column of full-height pages pages downwards.
/// The mechanism is each target's own — `scroll-snap-type` with `scroll-snap-align: start` on
/// the children in a browser, a scroll view with page physics in Flutter — which is why the
/// *relation* is what the model states, not either implementation.
///
/// ```dart
/// PagerNode(
///   width: 280,
///   height: 96,
///   direction: Axis.horizontal,
///   index: state.selected,
///   onPageChanged: store.show,
///   children: <UINode>[for (final UINode page in pages) page],
/// )
/// ```
///
/// **Every child is the size of the pager.** A page that is narrower than the box leaves the
/// two targets with different stops — a browser snaps to each child's own edge, and page
/// physics snaps to the viewport's — so `validateTree` reports the child that is not the
/// size the box states, and the box has to state one. That number is also what says how far
/// a page is from the start, which is why a pager with no `height` (or `width`, in a row)
/// is reported: its pages would have no size to be.
///
/// **`index` is where the pager is told to be, and it is a position rather than a controller.**
/// A tree drawn twice with the same index does not move the second time; a tree drawn with
/// another index moves one child. The move is a jump: a browser's programmatic scroll cannot
/// be given a duration or a curve, so an eased move here would be a Flutter animation and a
/// browser guess — a difference no test could hold. Where the movement should be eased, that
/// is a component's business, which is the same line the model draws between a token and a
/// look.
///
/// **[onPageChanged] is the settled answer.** A pager reports the child it came to rest on,
/// whether the reader swiped there or the tree asked for it, so a store that keeps the index
/// hears every way the pager moved and needs nothing to tell the two apart.
///
/// **Why it is a node and not a token.** A box knows its children, its axis, its size and its
/// paint; it does not know what a page is. The three things this node adds — the index, the
/// report, and the invariant that a page is the size of the pager — have no home on a box, and
/// the renderers have to be able to name them: `unibox_flutter` and `unibox_element` may not
/// import a design system, so a pager that lived in one could not be drawn at all.
final class PagerNode extends Box {
  /// Creates a pager over [children].
  ///
  /// `overflow` is not a parameter: a pager scrolls, and the node states it for the tree the
  /// way it states that a page is the size of the box. The rest are the box's own tokens.
  const PagerNode({
    super.key,
    super.children,
    super.direction,
    super.writingDirection,
    super.mainAlign,
    super.crossAlign,
    super.gap,
    super.wrap,
    super.flex,
    super.gridSpan,
    super.pin,
    super.pinOffset,
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
    super.fold,
    super.opacity,
    super.transform,
    super.visibleFrom,
    super.visibleUntil,
    super.styles,
    super.hoverStyle,
    super.stateStyles,
    super.enabled,
    super.capturesPointer,
    super.semantics,
    super.onTap,
    super.onTapDown,
    super.onLongPress,
    super.onHover,
    this.index,
    this.onPageChanged,
  });

  /// The child this pager shows, counted along its own axis, or `null` for wherever it is.
  ///
  /// This is how a pager is told which page to show, and the store that owns the index is
  /// what changes it — a press, a swipe reported by [onPageChanged], anything else. A value
  /// the pager is already on moves nothing, which is what makes it safe to state on every
  /// rebuild.
  final int? index;

  /// Called when this pager comes to rest on a child, with the index of that child.
  ///
  /// It fires for the reader's swipe and for the move the tree asked for, so a store that
  /// keeps [index] can follow both without knowing which it was.
  final PageChangedCallback? onPageChanged;

  /// The box's own style with the scroll it cannot do without.
  ///
  /// A pager that only clipped would have nothing to page, so `overflow` is stated here
  /// rather than left to the caller: it is not a default the caller may override, it is what
  /// the node means. A bag that sets it is overruled for the same reason.
  @override
  BoxStyle get computedStyle => super.computedStyle.merge(_scrolling);

  /// The one token a pager adds to whatever the tree stated.
  static const BoxStyle _scrolling = BoxStyle(overflow: Overflow.scroll);

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'pager';
}
