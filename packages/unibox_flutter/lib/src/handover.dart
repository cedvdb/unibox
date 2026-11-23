import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';

import 'document_scroll.dart';
import 'page_press.dart';
import 'press_replay.dart';
import 'unibox_ready.dart';

/// Coordinates a host-ready document-to-Flutter transition.
///
/// The host owns routing, data and layout. Call [complete] once those have produced
/// the destination surface, and supply the scroll controller representing the page.
final class FlutterHandover {
  bool _completed = false;
  bool _disposed = false;
  SemanticsHandle? _semantics;
  Future<void>? _completion;

  /// Whether restoration and the readiness signal have completed.
  bool get isComplete => _completed;

  /// Restores the latest document position, reveals Flutter and replays one intent.
  ///
  /// A missing or unattached controller is a configuration error, not a reason to
  /// reveal an incorrectly positioned page. [restore] supports custom page layouts
  /// and takes precedence over [controller]. Repeated calls share the same operation.
  Future<void> complete({
    ScrollController? controller,
    Future<void> Function(Offset position)? restore,
    BuildContext? root,
  }) {
    if (_disposed) {
      throw StateError('The handover coordinator has been disposed.');
    }
    return _completion ??= _complete(controller, restore, root);
  }

  /// Releases accessibility resources and cancels a transition still awaiting reveal.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (!_completed) cancelPendingHandover();
    _semantics?.dispose();
    _semantics = null;
  }

  Future<void> _complete(
    ScrollController? controller,
    Future<void> Function(Offset position)? restore,
    BuildContext? root,
  ) async {
    if (!wasTakenOver) {
      _completed = true;
      return;
    }
    _semantics ??= SemanticsBinding.instance.ensureSemantics();
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    if (_disposed) return;
    if (root != null && !root.mounted) {
      throw StateError('The handover surface was unmounted before readiness.');
    }
    final Offset position = documentScrollFromPage();
    if (restore != null) {
      await restore(position);
    } else if (controller != null) {
      if (!controller.hasClients ||
          controller.positions.length != 1 ||
          !controller.position.hasContentDimensions) {
        throw StateError('Handover needs one laid-out scroll position.');
      }
      final ScrollPosition destination = controller.position;
      final double offset =
          axisDirectionToAxis(destination.axisDirection) == Axis.horizontal
          ? position.dx
          : position.dy;
      controller.jumpTo(
        offset.clamp(destination.minScrollExtent, destination.maxScrollExtent),
      );
    } else if (position != Offset.zero) {
      throw StateError(
        'Supply the page scroll controller or a restoration callback.',
      );
    }
    if (_disposed) return;
    if (root != null && !root.mounted) {
      throw StateError(
        'The handover surface was unmounted during restoration.',
      );
    }
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    if (_disposed) return;
    uniboxReady();
    if (!await handoverRevealed()) return;
    if (_disposed || (root != null && !root.mounted)) return;
    pressRecorded(pressesFromPage().take(1), root: root);
    _completed = true;
  }
}
