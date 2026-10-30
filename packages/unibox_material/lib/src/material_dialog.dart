import 'package:unibox_core/unibox_core.dart';

import 'material_elevation.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// A Material 3 dialog: an [OverlayNode] whose content is a surface with a title,
/// a body and a row of actions.
///
/// ```dart
/// MaterialDialog(
///   title: 'Delete listing?',
///   content: const TextNode('The listing and its photos are removed.'),
///   actions: <UINode>[
///     TextButtonNode(label: 'Cancel', onTap: store.close),
///     TextButtonNode(label: 'Delete', onTap: store.delete),
///   ],
///   onDismiss: store.close,
/// )
/// ```
///
/// It carries its own policy — the scrim, `barrierDismissible`, the centred
/// alignment and [onDismiss] — because an overlay belongs in the tree, not in a
/// slot on the view. No renderer knows this class: Flutter presents it through an
/// `OverlayPortal`, the web draws a fixed layer.
///
/// **What it is not.** Material's entrance and exit transitions (a scale and a fade
/// on the way in) are not here: the model animates a box's look, not a node's
/// appearance, so the surface appears and disappears. The width is bounded rather
/// than measured, and the actions row does not wrap.
final class MaterialDialog extends OverlayNode {
  /// Creates the dialog.
  ///
  /// The surface is the caller's to state: [color], [padding], [gap],
  /// [borderRadius] and the bounds, and the action row's [actionGap] and
  /// [actionMargin] with them, so a dialog can be tightened for a small screen
  /// without a second component.
  MaterialDialog({
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
    double minWidth = 280,
    double maxWidth = 560,
    double actionGap = 8,
    BoxSpacing actionMargin = const BoxSpacing.only(top: 8),
  }) : super(
         barrierColor: const BoxColor.role(MaterialColorRole.scrim),
         alignment: OverlayAlignment.center,
         child: Box(
           backgroundColor: color,
           borderRadius: borderRadius,
           padding: padding,
           gap: gap,
           minWidth: minWidth,
           maxWidth: maxWidth,
           shadows: elevation,
           children: <UINode>[
             TextNode(title, style: _titleStyle()),
             if (content != null)
               Box(textStyle: _contentStyle(), children: <UINode>[content]),
             if (actions.isNotEmpty)
               _ActionRow(
                 actions: actions,
                 gap: actionGap,
                 margin: actionMargin,
               ),
           ],
         ),
       );

  /// The surface Material raises a dialog on.
  static const BoxColor _surface = BoxColor.role(
    MaterialColorRole.surfaceContainerHigh,
  );

  /// Material's level-three elevation: the shadow a dialog is raised by.
  static const List<BoxShadow> elevation = MaterialElevation.level3;

  /// The title: the headline role, in the on-surface colour.
  static BoxTextStyle _contentStyle() => MaterialTypography.bodyMedium.merge(
    BoxTextStyle(
      color: const BoxColor.role(MaterialColorRole.onSurfaceVariant),
    ),
  );

  static BoxTextStyle _titleStyle() => MaterialTypography.headlineSmall.merge(
    BoxTextStyle(color: const BoxColor.role(MaterialColorRole.onSurface)),
  );

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'material-dialog';
}

/// The actions of a dialog or a sheet: a row packed against its end.
final class _ActionRow extends Box {
  _ActionRow({
    required List<UINode> actions,
    required double gap,
    required BoxSpacing margin,
  }) : super(
         direction: Axis.horizontal,
         mainAlign: MainAlign.end,
         gap: gap,
         margin: margin,
         textStyle: MaterialTypography.labelLarge.merge(
           BoxTextStyle(color: const BoxColor.role(MaterialColorRole.primary)),
         ),
         children: actions,
       );
}
