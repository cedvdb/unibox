import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'render.dart';
import 'theme_scope.dart';
import 'values.dart';

/// Presents a [core.OverlayNode] above the page.
///
/// The node is inserted into the root [Overlay] through an [OverlayPortal], so it
/// escapes the clipping and scrolling of the boxes around it. The barrier covers
/// the page, `Escape` and a press on the barrier call the node's `onDismiss`,
/// focus stays inside the content while it is shown and goes back where it was
/// when the node leaves, and the whole thing is announced as a route.
///
/// The content is bounded by the room the window gives it: it is drawn in a scroll
/// view whose content is at least that room, so a dialog holding more than the
/// window scrolls rather than growing past it — the height the web renderer gives
/// the same node, where the layer is a flex container with `overflow: auto`.
///
/// An overlay never occupies room in its parent: the portal's own child is
/// empty, and everything it draws lives in the overlay above.
///
/// A widget tree that contains one needs an [Overlay] above it — every
/// `MaterialApp` or `WidgetsApp` provides one.
class FlutterOverlay extends StatefulWidget {
  /// Creates the presentation of [node].
  const FlutterOverlay({required this.node, super.key});

  /// The overlay being presented.
  final core.OverlayNode node;

  @override
  State<FlutterOverlay> createState() => FlutterOverlayState();
}

class FlutterOverlayState extends State<FlutterOverlay> {
  final OverlayPortalController _portal = OverlayPortalController(
    debugLabel: 'FlutterOverlay',
  );

  // A closed loop keeps Tab inside the content instead of walking the page.
  final FocusScopeNode _scope = FocusScopeNode(
    debugLabel: 'FlutterOverlay',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  FocusNode? _previousFocus;

  @override
  void initState() {
    super.initState();

    // The page has settled by the time this runs, so the focus it holds is the
    // one to give back when the overlay leaves. The portal is then shown, and
    // the focus scope it builds asks for focus on the frame after — it does not
    // exist before that.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _previousFocus = FocusManager.instance.primaryFocus;
      _portal.show();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scope.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    final FocusNode? previous = _previousFocus;
    _scope.dispose();
    if (previous != null && previous.context != null) {
      previous.requestFocus();
    }
    super.dispose();
  }

  Alignment get _alignment => switch (widget.node.alignment) {
    core.OverlayAlignment.center => Alignment.center,
    core.OverlayAlignment.top => Alignment.topCenter,
    core.OverlayAlignment.bottom => Alignment.bottomCenter,
  };

  @override
  Widget build(BuildContext context) {
    final core.OverlayNode node = widget.node;
    final void Function()? dismiss = node.onDismiss;
    // The portal puts its content on the root overlay, which is *outside* the tree
    // the page was rendered in — so the theme of that tree is read here, while the
    // widget is still in it, and handed to the content explicitly.
    final core.UniboxTheme? theme = UniboxThemeScope.of(context);

    return OverlayPortal(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (BuildContext context) => Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): ?dismiss,
          },
          child: FocusScope(
            node: _scope,
            // The layer is the window, and the content is bounded by it. A dialog holding
            // more than the window scrolls here, exactly as it does on the web, where the
            // layer is a flex container with `overflow: auto`: without the scroll the same
            // card came out as tall as its content in one rendering and no taller than the
            // window in the other, which is the drift these two files exist to prevent.
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  SingleChildScrollView(
                    child: Stack(
                      children: <Widget>[
                        // Inside the scroll view and not beside it: a scroll view that covered
                        // the layer would take the press itself and the scrim would stop
                        // dismissing, and a scrim pinned under the content's room covers every
                        // part of the window whatever the content is.
                        Positioned.fill(
                          child: ModalBarrier(
                            color: toColor(
                              theme == null
                                  ? node.barrierColor
                                  : theme.resolve(node.barrierColor),
                            ),
                            dismissible:
                                node.barrierDismissible && dismiss != null,
                            onDismiss: dismiss,
                          ),
                        ),
                        // What the alignment places is at least the layer: shorter than it, the
                        // content is centred in the window; taller, it is placed from the edge
                        // the alignment names and the scroll reaches the rest.
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Align(
                            alignment: _alignment,
                            child: renderFlutter(node.child, theme: theme),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}
