import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';
import 'material_typography.dart';

/// A Material 3 small top app bar: a band with a title, and the edge a list scrolls under.
///
/// ```dart
/// MaterialAppBar(
///   title: const TextNode('Results'),
///   trailing: const TextNode('6 of 24'),
///   pin: BoxPin.start,
/// )
/// ```
///
/// It adds no renderer work: it *is* a box, so both targets draw it with the renderer they
/// already have. What the class buys is the combination Material gives a bar — the height, the
/// surface, the 16 logical pixels at each end, `titleLarge` for the title, and the hairline that
/// separates it from the rows once they pass beneath it — and a name that says what it is.
///
/// **The bar is pinned by stating the edge.** `pin: BoxPin.start` is the ordinary case: the bar
/// comes to rest at the top of the box that scrolls it and keeps its slot in the flow. It is the
/// same token a `Box` states, so `pinOffset` stops a second bar under the first, and
/// `BoxPin.end` is a bar that waits at the bottom. A pinned bar has to state its height, which is
/// what [topHeight] is for — and a bar that is not pinned states it too, so the same component
/// can be either.
///
/// **The colour the pull reveals is [surface].** A panel that is pulled past its end reveals its
/// own background, so a list that scrolls under this bar states `backgroundColor: MaterialAppBar.
/// surface` and the pull reads as the bar gaining room rather than as a gap. That is why the
/// colour is a published constant and not only a default.
///
/// **What it is not.** It is not a scaffold: the bar and the list are two children of the tree,
/// in the order they are drawn, and where they sit is the layout's business. Nor is it a colour
/// scheme — every colour is a [MaterialColorRole] the theme resolves.
final class MaterialAppBar extends Box {
  /// Creates an app bar around [title].
  ///
  /// `color`, `titleStyle`, `height`, `padding` and `border` are the bar's own tokens, so an
  /// application can theme them without giving up the bar; [leading] and [trailing] are the
  /// nodes at the two ends, and [pin] is what makes it a band rather than a header.
  factory MaterialAppBar({
    Object? key,
    required UINode title,
    UINode? leading,
    UINode? trailing,
    BoxPin? pin,
    double? pinOffset,
    BoxFold? fold,
    BoxColor color = surface,
    BoxTextStyle titleStyle = MaterialTypography.titleLarge,
    BoxBorder? border = hairline,
    double height = topHeight,
    BoxSpacing padding = const BoxSpacing.symmetric(horizontal: 16),
    BoxSpacing? margin,
    BoxTextStyle? textStyle,
    BoxSemantics? semantics,
  }) {
    return MaterialAppBar._(
      key: key,
      margin: margin,
      box: Box(
        width: double.infinity,
        height: height,
        pin: pin,
        pinOffset: pinOffset,
        fold: fold,
        padding: padding,
        margin: margin,
        backgroundColor: color,
        border: border,
        // The bar is a header of what it sits over, and one row: a title at the start, and the
        // node at the end pushed to the other edge.
        semantics: semantics ?? const BoxSemantics(element: BoxElement.header),
        direction: Axis.horizontal,
        crossAlign: CrossAlign.center,
        mainAlign: MainAlign.spaceBetween,
        textStyle: textStyle,
        children: <UINode>[
          ?leading,
          Box(
            textStyle: titleStyle.merge(
              const BoxTextStyle(
                color: BoxColor.role(MaterialColorRole.onSurface),
              ),
            ),
            children: <UINode>[title],
          ),
          ?trailing,
        ],
      ),
    );
  }

  MaterialAppBar._({super.key, super.margin, required Box box})
    : super(
        width: box.width,
        height: box.height,
        pin: box.pin,
        pinOffset: box.pinOffset,
        fold: box.fold,
        padding: box.padding,
        backgroundColor: box.backgroundColor,
        border: box.border,
        semantics: box.semantics,
        direction: box.direction,
        crossAlign: box.crossAlign,
        mainAlign: box.mainAlign,
        textStyle: box.textStyle,
        children: box.children,
      );

  /// The height of a small top app bar, in logical pixels.
  ///
  /// A band that pins has to state its height — that number is the room its slot keeps in the
  /// flow — and this is the height Material gives one.
  static const double topHeight = 64;

  /// The surface the bar paints, and the surface its list states.
  ///
  /// Material tints the bar against the page so that a list scrolling under it reads as
  /// passing beneath something. A panel that is pulled past its end shows its own background,
  /// so the list states this same colour and the pull is the bar gaining room.
  static const BoxColor surface = BoxColor.role(
    MaterialColorRole.surfaceContainer,
  );

  /// The hairline a bar draws under itself once rows pass beneath it.
  ///
  /// Material 3 has no divider on a top app bar — it tints the bar as the content scrolls
  /// instead, which a description cannot know about. A line is the one edge both targets can
  /// draw for it, and it is a parameter, so a bar that should have none states `border: null`.
  static const BoxBorder hairline = BoxBorder(
    color: BoxColor.role(MaterialColorRole.outlineVariant),
  );
}
