import 'package:unibox_core/unibox_core.dart';

import 'material_app_bar.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// A Material 3 large top app bar: a band with room above its title, which folds as it leaves.
///
/// ```dart
/// MaterialLargeAppBar(
///   title: const TextNode('Six flats, one tree'),
///   fold: const BoxFold(
///     to: BoxStyle(opacity: 0.1, transform: BoxTransform(scale: 0.62)),
///     curve: BoxCurve.easeOut,
///   ),
/// )
/// ```
///
/// It is the band a results page opens with: a headline with air above it, and a list under it.
/// What the class buys is the combination Material gives a large app bar — 152 logical pixels of
/// height, the title on the baseline at the bottom of the band in `headlineMedium`, 16 pixels of
/// padding, and the same surface the small bar and the list share — plus the [fold] it takes for
/// the journey out of view.
///
/// **It pins, and it states its height, because a bar that shrinks is a bar whose height is
/// rebuilt.** `pin: BoxPin.start` keeps it at the top of the box that scrolls it once it has left —
/// a pinned `SliverAppBar`'s behaviour — and the height is a number the caller states, so a band
/// whose height follows a store is rebuilt with the new number rather than eased into it. That is
/// the one way a *layout* collapse is expressed here: a state and a rebuild, not a fold.
///
/// **The fold is paint, and Material's own collapse is not.** Material shrinks a large app bar
/// into a small one as the content scrolls, which is a *layout* change: the band's height and the
/// room it takes both move, and no renderer here eases a layout — a frame of an eased layout is a
/// picture the two engines cannot be held to. What a [BoxFold] does instead is paint the band out
/// of view — fade it, shrink it about its centre — while the flow keeps its height. A tree that
/// wants the space back states a state and swaps the band for a small one, which is a rebuild and
/// not a fold.
///
/// **What it is not.** It is not a scaffold and it is not a sliver: the band is a child of the
/// tree, the list is the next one, and the box that holds them decides whether it scrolls. And it
/// is not a colour scheme: [surface] is a [MaterialColorRole] the theme resolves.
final class MaterialLargeAppBar extends Box {
  /// Creates a large app bar around [title].
  ///
  /// [fold] is the look the band takes as it leaves the box that scrolls it, and the rest are the
  /// band's own tokens — the surface, the type, the height, the padding — so an application can
  /// theme them without giving up the band.
  factory MaterialLargeAppBar({
    Object? key,
    required UINode title,
    UINode? trailing,
    BoxFold? fold,
    BoxPin? pin,
    double? pinOffset,
    BoxColor color = surface,
    BoxTextStyle titleStyle = MaterialTypography.headlineMedium,
    double height = largeHeight,
    BoxSpacing padding = const BoxSpacing.all(16),
    BoxSpacing? margin,
    BoxTextStyle? textStyle,
    BoxSemantics? semantics,
  }) {
    return MaterialLargeAppBar._(
      key: key,
      box: Box(
        width: double.infinity,
        height: height,
        pin: pin,
        pinOffset: pinOffset,
        padding: padding,
        margin: margin,
        backgroundColor: color,
        fold: fold,
        semantics: semantics ?? const BoxSemantics(element: BoxElement.header),
        // The title sits on the floor of the band, which is where Material puts it: the air the
        // large app bar is for is above the headline, not around it.
        mainAlign: MainAlign.end,
        crossAlign: CrossAlign.start,
        textStyle: textStyle,
        children: <UINode>[
          Box(
            width: double.infinity,
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

  MaterialLargeAppBar._({super.key, required Box box})
    : super(
        width: box.width,
        height: box.height,
        pin: box.pin,
        pinOffset: box.pinOffset,
        padding: box.padding,
        margin: box.margin,
        backgroundColor: box.backgroundColor,
        fold: box.fold,
        semantics: box.semantics,
        mainAlign: box.mainAlign,
        crossAlign: box.crossAlign,
        textStyle: box.textStyle,
        children: box.children,
      );

  /// The height of a large top app bar, in logical pixels.
  static const double largeHeight = 152;

  /// The colour the band paints: Material's `surfaceContainer`, one step above the page.
  ///
  /// The same role the small bar uses, because Material draws all of its top app bars on one
  /// container — a large bar and the small one it becomes share a colour, and the page they sit on
  /// is `MaterialScaffold.surface`, which is a different one.
  static const BoxColor surface = MaterialAppBar.surface;
}
