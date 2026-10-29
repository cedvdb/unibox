import 'dart:async';
import 'dart:js_interop';

import 'package:unibox_core/unibox_core.dart' as core;
import 'package:web/web.dart' as web;

/// How long a press has to be held to be a long press: Material's own threshold, and the one the
/// string renderer writes for the browser.
const Duration longPressThreshold = Duration(milliseconds: 500);

/// What a node asks an element to do, as listeners on it.
///
/// A node states its behaviour as a callback, so this is the one place a callback becomes an event
/// listener — no attribute protocol, no name a host implements in JavaScript. The listeners are
/// returned so a renderer can take them off again: a re-render hands the element a *new* closure,
/// and a listener left behind would call the state the page has already left.
List<void Function()> bindNode(core.UINode node, web.Element element) {
  final List<void Function()> undo = <void Function()>[];

  void on(String type, void Function(web.Event event) handler) {
    final web.EventListener listener = handler.toJS;
    element.addEventListener(type, listener);
    undo.add(() => element.removeEventListener(type, listener));
  }

  switch (node) {
    case final core.Box box when box.enabled:
      if (box.onTap case final core.TapCallback onTap) {
        on('click', (web.Event event) => onTap());
      }

      if (box.onTapDown case final core.TapDownCallback onTapDown) {
        on('pointerdown', (web.Event event) {
          final web.PointerEvent pointer = event as web.PointerEvent;
          onTapDown(
            core.BoxTapEvent(
              // The local coordinate, which is the one both hosts can produce exactly: where the
              // box sits on the page is the host's fact, not the node's.
              position: core.BoxPoint(pointer.offsetX, pointer.offsetY),
              pointer: _kindOf(pointer),
            ),
          );
        });
      }

      if (box.onLongPress case final core.LongPressCallback onLongPress) {
        _bindLongPress(on, onLongPress);
      }

    case final core.LinkNode link when link.onTap != null:
      // The link is a real `href`, so a page without a runtime still follows it. With one, the
      // press is the tree's and the browser does not load the document as well.
      on('click', (web.Event event) {
        final web.MouseEvent mouse = event as web.MouseEvent;

        // A modifier, a middle click and a new tab stay the browser's: a reader asking for
        // another window is not asking this page to handle the press.
        if (mouse.metaKey ||
            mouse.ctrlKey ||
            mouse.shiftKey ||
            mouse.altKey ||
            mouse.button != 0 ||
            link.newTab) {
          return;
        }

        event.preventDefault();
        link.onTap!();
      });

    case final core.TextInputNode field:
      if (field.onChanged case final core.TextChangedCallback onChanged) {
        on('input', (web.Event event) {
          onChanged((event.target! as web.HTMLInputElement).value);
        });
      }

      if (field.onSubmitted case final core.TextSubmittedCallback onSubmitted) {
        on('keydown', (web.Event event) {
          final web.KeyboardEvent key = event as web.KeyboardEvent;

          if (key.key != 'Enter' || key.shiftKey) {
            return;
          }

          event.preventDefault();
          onSubmitted((event.target! as web.HTMLInputElement).value);
        });
      }

    default:
      break;
  }

  return undo;
}

/// A press held long enough is a long press, and the click it would have become is swallowed.
void _bindLongPress(
  void Function(String type, void Function(web.Event event) handler) on,
  core.LongPressCallback onLongPress,
) {
  Timer? timer;
  bool fired = false;

  void cancel() {
    timer?.cancel();
    timer = null;
  }

  on(
    'pointerdown',
    (web.Event event) => timer = Timer(longPressThreshold, () {
      fired = true;
      onLongPress();
    }),
  );
  on('pointerup', (web.Event event) => cancel());
  on('pointerleave', (web.Event event) => cancel());
  on('pointercancel', (web.Event event) => cancel());
  on('click', (web.Event event) {
    if (!fired) {
      return;
    }

    // The release that ends a long press is not also a press.
    fired = false;
    event.preventDefault();
    event.stopPropagation();
  });
}

/// The pointer a press came from, as far as the model names them.
core.BoxPointerKind _kindOf(web.PointerEvent event) =>
    switch (event.pointerType) {
      'mouse' => core.BoxPointerKind.mouse,
      'touch' => core.BoxPointerKind.touch,
      'pen' => core.BoxPointerKind.pen,
      _ => core.BoxPointerKind.unknown,
    };
