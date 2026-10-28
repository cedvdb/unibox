import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';

/// A Material 3 circular progress indicator: a [ProgressNode] with Material's
/// size, stroke and colours.
///
/// ```dart
/// const MaterialProgressIndicator();                    // pending
/// const MaterialProgressIndicator(value: 0.4);          // 40% done
/// MaterialProgressIndicator(size: 24, showTrack: true);
/// ```
///
/// It *is* a [ProgressNode], so each renderer draws it with the indicator it has.
/// What the class buys is the combination Material gives a circular indicator: a
/// 48 pixel ring, 4 pixels thick, the arc in `primary`, and a
/// `surfaceContainerHighest` track when [showTrack] asks for one.
///
/// **What it is not.** It is circular only: a linear indicator needs a width as a
/// fraction of its parent, which the model cannot state. The indeterminate motion
/// is each platform's own, so the arc will not grow and shrink identically on both.
final class MaterialProgressIndicator extends ProgressNode {
  /// Creates the indicator, in the `primary` role.
  const MaterialProgressIndicator({
    super.key,
    super.value,
    super.size,
    super.strokeWidth,
    super.semanticsLabel,
    bool showTrack = false,
  }) : super(
         color: const BoxColor.role(MaterialColorRole.primary),
         trackColor: showTrack
             ? const BoxColor.role(MaterialColorRole.surfaceContainerHighest)
             : BoxColor.transparent,
       );
}
