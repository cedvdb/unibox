/// The offset a page was scrolled to, and the script that records it.
///
/// A page can be static HTML first and the application second, and the application paints
/// into a canvas the size of the viewport — so the browser's own scroll position is not
/// something it can inherit. The document records the offset of every region it drew, and
/// the runtime that boots next starts there instead of at the top.
///
/// The page's own offset is the window's unless the host marks the element it scrolls in
/// ([scrollRootAttribute]): a page that paints the application into the viewport usually
/// keeps the document still, so the window would answer 0 forever.
library;

import 'keys.dart';

/// The mark a host puts on the element its page scrolls in.
///
/// The window is the default, so a page that does not name a scroller keeps the behaviour
/// it had. The mark is a presence, not a selector: the host states which element scrolls,
/// and the library never guesses one.
const String scrollRootAttribute = 'data-unibox-scroll-root';

/// The script that records where each region of a page is scrolled to.
///
/// A `scroll` event does not bubble, but it does run through the capture phase, so one
/// listener on the document sees every region's scroll — including one added later.
///
/// The page's own offset is read from the element marked [scrollRootAttribute], or from the
/// window when none is marked. A marked element is looked up on first read and again if it
/// leaves the document, because a page can replace the box it scrolls in.
///
/// The record is read once, at the moment the runtime asks: `take` reads the page again
/// before answering, so the answer is the position at *that* moment however long the reader
/// has left the page alone.
const String scrollScript =
    '''
(function () {
  'use strict';
  var keyAttribute = '$nodeKeyAttribute';
  var rootAttribute = '$scrollRootAttribute';
  var unibox = window.unibox = window.unibox || {};

  if (unibox.takeScroll) { return; }

  var recorded = [];
  var taken = false;
  var position = { dx: 0, dy: 0 };
  var root = null;

  function scroller() {
    if (root && root.isConnected) { return root; }
    root = document.querySelector('[' + rootAttribute + ']');
    return root;
  }

  unibox.documentScroll = function () {
    if (document.documentElement.getAttribute('data-unibox-state') !== 'app') {
      var element = scroller();
      position = element
        ? { dx: element.scrollLeft || 0, dy: element.scrollTop || 0 }
        : { dx: window.scrollX || 0, dy: window.scrollY || 0 };
    }
    return position;
  };

  function snapshot() {
    unibox.documentScroll();
    var found = [];
    var elements = document.querySelectorAll('[' + keyAttribute + ']');

    for (var i = 0; i < elements.length; i++) {
      found.push({
        key: elements[i].getAttribute(keyAttribute),
        dx: elements[i].scrollLeft || 0,
        dy: elements[i].scrollTop || 0
      });
    }

    recorded = found;
  }

  function onScroll() {
    if (document.documentElement.getAttribute('data-unibox-state') === 'app') { return; }
    snapshot();
  }
  document.addEventListener('scroll', onScroll, { capture: true, passive: true });
  document.addEventListener('visibilitychange', snapshot);
  window.addEventListener('pointerdown', snapshot, { passive: true });
  window.addEventListener('pagehide', snapshot);

  unibox.stopScrollRecording = function () {
    snapshot();
    document.removeEventListener('scroll', onScroll, true);
    document.removeEventListener('visibilitychange', snapshot);
    window.removeEventListener('pointerdown', snapshot);
    window.removeEventListener('pagehide', snapshot);
  };

  // The offsets recorded since the page arrived, taken once so a runtime that replays them
  // twice does not move twice.
  unibox.takeScroll = function () {
    if (taken) { return []; }
    taken = true;
    snapshot();
    var taken = recorded;
    recorded = [];
    return taken;
  };
})();
''';
