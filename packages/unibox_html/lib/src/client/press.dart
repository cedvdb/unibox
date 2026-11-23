/// Recording of one intercepted intent while a document waits for Flutter.
library;

import 'keys.dart';

/// The stable identity shared by the document and the Flutter target.
const String pressKeyAttribute = nodeKeyAttribute;

/// Only the latest pending intent is retained during handover.
const int pressRecordLimit = 1;

/// Intercepts eligible keyed actions while preserving ordinary browser navigation.
const String pressScript =
    '''
(function () {
  'use strict';
  var attribute = '$pressKeyAttribute';
  var unibox = window.unibox = window.unibox || {};
  if (unibox.takePressed) { return; }
  var pressed = [];
  var taken = false;

  function capture(event) {
    var state = document.documentElement.getAttribute('data-unibox-state');
    if (!unibox.takeover || state === 'app' || state === 'failed' || taken) { return; }
    if (event.defaultPrevented || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button > 0) { return; }
    var node = event.target;
    var action = false;
    var named = null;
    while (node && node.nodeType === 1) {
      // Links retain navigation, downloads and new-tab behaviour in the browser.
      if (node.tagName === 'A' && node.hasAttribute('href')) { return; }
      if (node.hasAttribute('disabled') || node.getAttribute('aria-disabled') === 'true') { return; }
      if (node.hasAttribute('data-unibox-action')) { action = true; }
      if (!named && node.hasAttribute(attribute)) { named = node; }
      node = node.parentNode;
    }
    if (!action || !named) { return; }
    var matches = document.querySelectorAll('[' + attribute + ']');
    var key = named.getAttribute(attribute);
    var count = 0;
    for (var i = 0; i < matches.length; i++) {
      if (matches[i].getAttribute(attribute) === key) { count++; }
    }
    if (count !== 1) { return; }
    var box = named.getBoundingClientRect();
    event.preventDefault();
    event.stopImmediatePropagation();
    pressed = [{ key: key, dx: event.clientX - box.left, dy: event.clientY - box.top }];
    unibox.hasPendingPress = true;
  }
  document.addEventListener('click', capture, { capture: true });
  unibox.stopPressRecording = function (discard) {
    document.removeEventListener('click', capture, true);
    if (discard) { pressed = []; taken = true; }
  };
  unibox.takePressed = function () {
    if (taken) { return []; }
    taken = true;
    document.removeEventListener('click', capture, true);
    var result = pressed;
    pressed = [];
    unibox.hasPendingPress = false;
    return result;
  };
})();
''';
