/// The ink a press paints, and the script that paints it.
///
/// A design that wants ink marks where a press may show it; a page that includes this
/// script gets the drop. The two are separate on purpose — the marker is inert markup, so
/// a page opts out of ink by including no script, with no flag anywhere.
library;

/// The attribute that marks an element a press may paint.
///
/// Written by the renderer where a press is allowed to show feedback, never read back by
/// the tree.
const String inkAttribute = 'data-unibox-ink';

/// The declarations that make the ink a drop that spreads and fades.
///
/// Written into the stylesheet beside the classes, because a page that marks a pressable
/// element has to describe what the mark looks like — and CSS does that without JavaScript
/// deciding anything, so the animation is there whether or not the script has loaded.
const String inkDeclarations = '''
@keyframes unibox-ink{from{opacity:.28;transform:translate(-50%,-50%) scale(0)}
to{opacity:0;transform:translate(-50%,-50%) scale(2.4)}}
.unibox-ink{position:absolute;width:48px;height:48px;border-radius:50%;
background-color:currentColor;pointer-events:none;animation:unibox-ink 500ms ease-out}
''';

/// The script that adds a drop to the element a press landed on.
///
/// One listener for the whole page, in the capture phase: a press is caught whatever it
/// landed on, and a control added later works without being registered.
const String inkScript =
    '''
(function () {
  'use strict';
  var marker = '$inkAttribute';
  var unibox = window.unibox = window.unibox || {};

  if (unibox.ink) { return; }

  function nearest(node) {
    while (node && node.nodeType === 1) {
      if (node.hasAttribute(marker)) { return node; }
      node = node.parentNode;
    }
    return null;
  }

  document.addEventListener('pointerdown', function (event) {
    var target = nearest(event.target);

    if (!target) { return; }

    var box = target.getBoundingClientRect();
    var drop = document.createElement('span');
    drop.className = 'unibox-ink';
    drop.style.left = (event.clientX - box.left) + 'px';
    drop.style.top = (event.clientY - box.top) + 'px';
    target.appendChild(drop);
    drop.addEventListener('animationend', function () {
      drop.parentNode && drop.parentNode.removeChild(drop);
    });
  }, { capture: true, passive: true });

  unibox.ink = true;
})();
''';
