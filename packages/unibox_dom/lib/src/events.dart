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
      // A link is the node that names a destination, and a destination is pressed once: the
      // rule below depends on knowing which of the two this box is.
      final core.LinkNode? link = box is core.LinkNode ? box : null;

      // The long press is bound first because it may have to swallow the click that ends it, and a
      // listener only runs before the ones added after it.
      if (box.onLongPress case final core.LongPressCallback onLongPress) {
        _bindLongPress(on, onLongPress);
      }

      if (box.onTap case final core.TapCallback onTap) {
        if (link != null) {
          _bindLinkClick(on, onTap: onTap, newTab: link.newTab);
        } else {
          on('click', (web.Event event) => onTap());
        }
      }

      if (box.onTapDown case final core.TapDownCallback onTapDown) {
        on('pointerdown', (web.Event event) {
          final web.PointerEvent pointer = event as web.PointerEvent;
          onTapDown(
            core.BoxTapEvent(
              position: _positionIn(element, pointer),
              pointer: _kindOf(pointer),
            ),
          );
        });
      }

      // A link activates with `Enter` on its own and the browser turns that into a click,
      // which the listener above answers, so binding the key as well would press twice. A
      // `Space` on a link does nothing anywhere, and nothing here is where it belongs.
      if (box.isInteractive && box.onTap != null && link == null) {
        _bindActivationKey(on, box.onTap!);
      }

      if (box.onScroll case final core.ScrollCallback onScroll) {
        // `scroll` does not bubble, so a scrollable nested in this element never reaches this
        // listener: the nested box reports its own offset to its own callback, exactly as
        // Flutter's notification depth does.
        final bool horizontal =
            box.computedStyle.resolvedDirection == core.Axis.horizontal;

        on('scroll', (web.Event event) {
          onScroll(
            (horizontal ? element.scrollLeft : element.scrollTop).toDouble(),
          );
        });
      }

      if (box.onHover case final core.HoverCallback onHover) {
        // `enter` and `leave` rather than `over` and `out`: those two fire for every child the
        // pointer crosses, so a control made of several boxes would report a hover dozens of times
        // and end it while the pointer is still inside.
        on('pointerenter', (web.Event event) => onHover(true));
        on('pointerleave', (web.Event event) => onHover(false));
      }

    case final core.OverlayNode overlay
        when overlay.onDismiss != null &&
            element.getAttribute('data-unibox-barrier') != null:
      // The barrier, not the layer: a press inside the dialog is the dialog's, and a press on the
      // shade behind it is the reader asking to be let out.
      on('click', (web.Event event) => overlay.onDismiss!());

    case final core.TextInputNode field:
      if (field.onChanged case final core.TextChangedCallback onChanged) {
        on('input', (web.Event event) {
          onChanged((event.target! as web.HTMLInputElement).value);
        });
      }

      if (field.onFocusChanged
          case final core.FocusChangedCallback onFocusChanged) {
        // `focus` and `blur` rather than their bubbling twins: an input is one element, so the pair
        // that fires on it is the whole story.
        on('focus', (web.Event event) => onFocusChanged(true));
        on('blur', (web.Event event) => onFocusChanged(false));
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

/// A press on a real link, which the browser keeps unless the tree answers it.
///
/// The element is a real `href`, so a page without a runtime still follows it. With one,
/// the press is the tree's and the browser does not load the document as well — except
/// when the reader asked for something else: a modifier, a middle click and a new tab are
/// the browser's, and a page that swallowed them would take away the whole of what a link
/// is for.
void _bindLinkClick(
  void Function(String type, void Function(web.Event event) handler) on, {
  required core.TapCallback onTap,
  required bool newTab,
}) {
  on('click', (web.Event event) {
    final web.MouseEvent mouse = event as web.MouseEvent;

    if (mouse.metaKey ||
        mouse.ctrlKey ||
        mouse.shiftKey ||
        mouse.altKey ||
        mouse.button != 0 ||
        newTab) {
      return;
    }

    event.preventDefault();
    onTap();
  });
}

/// Activates a box from the keyboard, the way Flutter does it.
///
/// `Enter` fires on the way down and `Space` on the way up, which is what a button does everywhere.
/// `Space` has to be cancelled on the way down as well, or the page scrolls under the reader while
/// they are pressing a control.
void _bindActivationKey(
  void Function(String type, void Function(web.Event event) handler) on,
  core.TapCallback onTap,
) {
  bool held = false;

  on('keydown', (web.Event event) {
    final web.KeyboardEvent key = event as web.KeyboardEvent;

    if (key.key == 'Enter') {
      event.preventDefault();
      onTap();

      return;
    }

    if (key.key == ' ') {
      // The default of Space on a focused element is a page of scrolling.
      event.preventDefault();
      held = true;
    }
  });

  on('keyup', (web.Event event) {
    final web.KeyboardEvent key = event as web.KeyboardEvent;

    if (key.key == ' ' && held) {
      held = false;
      onTap();
    }
  });
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

    // The release that ends a long press is not also a press: every other listener on this element
    // is skipped, not merely the bubbling.
    fired = false;
    event.preventDefault();
    event.stopImmediatePropagation();
  });
}

/// Where [event] landed, in the coordinates of [element] — the box the listener is on.
///
/// Not `offsetX`/`offsetY`: those are measured from the edge of the *event target*, and a press on a
/// label inside a button reports a point near that label, not near the button. A ripple would start
/// at the top of the control instead of under the finger. `clientX`/`clientY` are viewport
/// coordinates, so subtracting the element's own rectangle gives the box-local point both targets can
/// produce exactly — where the box sits on the page is the host's fact, not the node's.
core.BoxPoint _positionIn(web.Element element, web.PointerEvent event) {
  final web.DOMRect rect = element.getBoundingClientRect();

  return core.BoxPoint(event.clientX - rect.left, event.clientY - rect.top);
}

/// The pointer a press came from, as far as the model names them.
core.BoxPointerKind _kindOf(web.PointerEvent event) =>
    switch (event.pointerType) {
      'mouse' => core.BoxPointerKind.mouse,
      'touch' => core.BoxPointerKind.touch,
      'pen' => core.BoxPointerKind.pen,
      _ => core.BoxPointerKind.unknown,
    };
