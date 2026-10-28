import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;
import 'package:unibox_core/unibox_core.dart' as core;

import 'labels.dart';
import 'render.dart';
import 'stylesheet.dart';
import 'values.dart';

/// Draws a [core.OverlayNode] as a fixed layer over the page.
///
/// A server render has no `Escape`, no pointer handling and no focus to move, so
/// this is the overlay's *look* plus the listeners a client would use: a fixed
/// layer, the barrier, the content and where it sits. It is never drawn in the
/// flow of its parent — an overlay on the web is a layer or nothing.
///
/// The barrier carries the `click` that dismisses when the node says the barrier
/// is dismissible; `Escape` dismisses too, but the key is heard on the document
/// while the overlay is up, because nothing inside a freshly opened overlay holds
/// focus and a listener on the layer only sees a keystroke that starts inside it.
/// A static document can run neither, so both take effect once the page is
/// hydrated by the client build. Until then the export is the snapshot the
/// `signup` document exists for.
class JasprOverlay extends StatefulComponent {
  /// Creates a renderer for [node].
  const JasprOverlay({required this.node, super.key});

  /// The node being rendered.
  final core.OverlayNode node;

  @override
  State<JasprOverlay> createState() => _JasprOverlayState();
}

/// The overlay's browser half: the `Escape` listener it holds while it is up.
class _JasprOverlayState extends State<JasprOverlay> {
  /// The `keydown` subscription of a browser, or `null` on a server.
  StreamSubscription<web.KeyboardEvent>? _keyDown;

  @override
  void initState() {
    super.initState();

    final core.TapCallback? onDismiss = component.node.onDismiss;

    if (!kIsWeb || onDismiss == null) {
      return;
    }

    _keyDown = web.EventStreamProviders.keyDownEvent
        .forTarget(web.document)
        .listen((web.KeyboardEvent event) {
          if (event.key != 'Escape') {
            return;
          }

          event.preventDefault();
          onDismiss();
        });
  }

  @override
  void dispose() {
    final StreamSubscription<web.KeyboardEvent>? keyDown = _keyDown;

    if (keyDown != null) {
      unawaited(keyDown.cancel());
    }

    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final String alignment = switch (component.node.alignment) {
      core.OverlayAlignment.center => 'center',
      core.OverlayAlignment.top => 'flex-start',
      core.OverlayAlignment.bottom => 'flex-end',
    };

    final Styles layer = Styles(
      raw: <String, String>{
        'position': 'fixed',
        'inset': '0',
        'display': 'flex',
        'align-items': alignment,
        'justify-content': 'center',
      },
    );
    final Styles barrier = Styles(
      raw: <String, String>{
        'position': 'absolute',
        'inset': '0',
        'background-color':
            cssRoleReference(component.node.barrierColor) ??
            toCssColor(component.node.barrierColor).value,
      },
    );
    // Positioned boxes paint above in-flow ones, in that order whichever comes
    // first in the document — so the content is positioned too, and the later
    // sibling wins. Left static it would sit *under* the scrim and be dimmed with
    // the page behind it, which is not what a modal looks like.
    final Styles content = Styles(
      raw: <String, String>{'position': 'relative'},
    );
    final UniboxStylesheet? sheet = UniboxStylesheetScope.of(context);

    return div(
      <Component>[
        div(
          const <Component>[],
          classes: _className(sheet, 'overlay-barrier', barrier),
          styles: sheet == null ? barrier : null,
          events: _barrierEvents(),
        ),
        div(
          <Component>[renderNode(component.node.child)],
          classes: _className(sheet, 'overlay-content', content),
          styles: sheet == null ? content : null,
        ),
      ],
      attributes: withNodeLabel(component.node, const <String, String>{
        'role': 'dialog',
        'aria-modal': 'true',
      }),
      classes: _className(sheet, 'overlay', layer),
      styles: sheet == null ? layer : null,
    );
  }

  /// The press that dismisses the overlay, when the node says a press may.
  ///
  /// Nothing is stopped: the barrier covers the page and is a sibling of the
  /// content, so the press never reaches a handler behind it.
  Map<String, EventCallback>? _barrierEvents() {
    final core.TapCallback? onDismiss = component.node.onDismiss;

    if (!component.node.barrierDismissible || onDismiss == null) {
      return null;
    }

    return <String, EventCallback>{'click': (web.Event event) => onDismiss()};
  }

  /// The class of [styles] in [sheet], or `null` when there is no sheet to put it
  /// in.
  static String? _className(
    UniboxStylesheet? sheet,
    String kind,
    Styles styles,
  ) => sheet?.classFor(
    kind,
    declarationsOf(styles),
    (String name) => <StyleRule>[
      StyleRule(selector: Selector.className(name), styles: styles),
    ],
  );
}
