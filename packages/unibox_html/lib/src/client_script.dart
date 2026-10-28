/// The script a page may carry, and the one piece of behaviour a document has.
///
/// A document is a snapshot of a state: no callback becomes a listener, and nothing in it
/// can change. What a reader can still notice is that a press did nothing at all — so the
/// script does two small things and no more:
///
/// - it paints the **ink** on the element a press landed on, where the renderer marked one
///   with [inkAttribute];
/// - it **records** the press, keyed by [keyAttribute], so the application that takes the
///   page over can replay the intent instead of losing it.
///
/// It is one file and it is optional. `data-unibox-ink` without it is inert markup, which is
/// how a page opts out of ink: it includes no script. The tree says *where* a press may
/// paint; the host says *whether* it does.
///
/// It is not a client renderer. Dismissing an overlay, changing a state, fetching anything:
/// those need a state to change, and that is the application's job or `unibox_dom`'s.
const String uniboxClientScript = '''
(function () {
  'use strict';
  if (window.unibox) { return; }

  var ink = 'data-unibox-ink';
  var key = 'data-unibox-key';
  var pressed = [];

  function nearest(node, name) {
    while (node && node.nodeType === 1) {
      if (node.hasAttribute(name)) { return node; }
      node = node.parentNode;
    }
    return null;
  }

  // The ink: a drop at the point that was pressed, taken away when it has spread.
  function paint(target, event) {
    var box = target.getBoundingClientRect();
    var drop = document.createElement('span');
    drop.className = 'unibox-ink';
    drop.style.left = (event.clientX - box.left) + 'px';
    drop.style.top = (event.clientY - box.top) + 'px';
    target.appendChild(drop);
    drop.addEventListener('animationend', function () {
      drop.parentNode && drop.parentNode.removeChild(drop);
    });
  }

  function record(node, event) {
    var named = nearest(node, key);

    if (!named) { return; }

    var box = named.getBoundingClientRect();

    pressed.push({
      key: named.getAttribute(key),
      dx: event.clientX - box.left,
      dy: event.clientY - box.top
    });

    // The last few presses only: a reader who presses twenty times asked for the last one,
    // and a record nobody reads is memory the page never gets back.
    if (pressed.length > 8) { pressed.shift(); }
  }

  window.unibox = {
    // The presses recorded since the page arrived, oldest first.
    takePressed: function () {
      var taken = pressed;
      pressed = [];
      return taken;
    }
  };

  // One listener for the whole page, in the capture phase: a press is caught whatever it
  // landed on, and a control added later works without being registered.
  document.addEventListener('pointerdown', function (event) {
    var painted = nearest(event.target, ink);

    if (painted) { paint(painted, event); }

    record(event.target, event);
  }, { capture: true, passive: true });
})();
''';

/// The attribute that marks an element a press may paint.
///
/// Written by the renderer where a press is allowed to show feedback — never read back by
/// the tree, and inert when no script is included.
const String inkAttribute = 'data-unibox-ink';

/// The declarations that make the ink a drop that spreads and fades.
///
/// Written into the stylesheet beside the classes, because a page that marks a pressable
/// element has to describe what the mark looks like — and CSS does that without JavaScript
/// deciding anything, so the animation survives a script that has not loaded yet.
const String inkDeclarations = '''
@keyframes unibox-ink{from{opacity:.28;transform:translate(-50%,-50%) scale(0)}
to{opacity:0;transform:translate(-50%,-50%) scale(2.4)}}
.unibox-ink{position:absolute;width:48px;height:48px;border-radius:50%;
background-color:currentColor;pointer-events:none;animation:unibox-ink 500ms ease-out}
''';
