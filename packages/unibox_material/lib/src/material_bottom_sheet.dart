import 'package:unibox_core/unibox_core.dart';

import 'material_elevation.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// A Material 3 bottom sheet: an [OverlayNode] against the bottom edge, holding a
/// title, a body and the sheet's own actions.
///
/// ```dart
/// MaterialBottomSheet(
///   title: 'Filter listings',
///   content: FilterForm(state: state, store: store),
///   actions: <UINode>[ApplyButton(onTap: store.applyFilters)],
///   onDismiss: store.closeFilters,
/// )
/// ```
///
/// It is a [MaterialDialog] that sits at the bottom and reads as a sheet rather
/// than a card: the same scrim, the same dismissal policy, the same title and
/// action treatment, a lower surface tone and a wider bound.
///
/// **Round at the top, square where it meets the screen.** Material rounds the two
/// corners the sheet rises from and squares the two that meet the edge, which is
/// what [BoxBorderRadius] states.
final class MaterialBottomSheet extends OverlayNode {
  /// Creates the sheet.
  ///
  /// The surface is the caller's to state, exactly as in [MaterialDialog]: [color],
  /// [padding], [gap], [borderRadius] of the two upper corners, [maxWidth], and the
  /// action row's [actionGap] and [actionMargin].
  MaterialBottomSheet({
    super.key,
    required String title,
    UINode? content,
    List<UINode> actions = const <UINode>[],
    super.onDismiss,
    super.barrierDismissible,
    BoxColor color = _surface,
    BoxSpacing padding = const BoxSpacing.all(24),
    double gap = 16,
    double borderRadius = 28,
    double maxWidth = 640,
    double actionGap = 8,
    BoxSpacing actionMargin = const BoxSpacing.only(top: 8),
  }) : super(
         barrierColor: const BoxColor.role(MaterialColorRole.scrim),
         alignment: OverlayAlignment.bottom,
         child: Box(
           backgroundColor: color,
           corners: BoxBorderRadius(
             topLeft: borderRadius,
             topRight: borderRadius,
           ),
           padding: padding,
           gap: gap,
           width: double.infinity,
           maxWidth: maxWidth,
           shadows: _elevation,
           children: <UINode>[
             Box(
               mainAlign: MainAlign.center,
               children: <UINode>[
                 Box(
                   width: 32,
                   height: 4,
                   borderRadius: 2,
                   backgroundColor: const BoxColor.role(
                     MaterialColorRole.outlineVariant,
                   ),
                 ),
               ],
             ),
             TextNode(
               title,
               style: MaterialTypography.headlineSmall.merge(
                 BoxTextStyle(
                   color: const BoxColor.role(MaterialColorRole.onSurface),
                 ),
               ),
             ),
             if (content != null)
               Box(
                 textStyle: MaterialTypography.bodyMedium.merge(
                   BoxTextStyle(
                     color: const BoxColor.role(
                       MaterialColorRole.onSurfaceVariant,
                     ),
                   ),
                 ),
                 children: <UINode>[content],
               ),
             if (actions.isNotEmpty)
               Box(
                 direction: Axis.horizontal,
                 mainAlign: MainAlign.end,
                 gap: actionGap,
                 margin: actionMargin,
                 textStyle: MaterialTypography.labelLarge.merge(
                   BoxTextStyle(
                     color: const BoxColor.role(MaterialColorRole.primary),
                   ),
                 ),
                 children: actions,
               ),
           ],
         ),
       );

  /// The surface a sheet rises from: the low container tone, one step below a dialog.
  static const BoxColor _surface = BoxColor.role(
    MaterialColorRole.surfaceContainerLow,
  );

  /// Elevation level one, cast upward: the sheet rises from the bottom edge.
  static const List<BoxShadow> _elevation = MaterialElevation.sheet;

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'material-bottom-sheet';
}
