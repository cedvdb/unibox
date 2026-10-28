/// The presses a page records, and the script that records them.
///
/// A document has no state to change, so a press can only be remembered: the application
/// that takes the page over reads the record and replays the intent, instead of a reader
/// pressing a control and nothing happening twice.
library;

import 'keys.dart';

/// The attribute a recorded press is keyed by.
///
/// The same one the renderer writes on every element a keyed node drew, so the application
/// finds the element it is being told about.
const String pressKeyAttribute = nodeKeyAttribute;

/// How many presses a page keeps.
///
/// A reader who presses twenty times asked for the last one, and a record nobody reads is
/// memory the page never gets back.
const int pressRecordLimit = 8;

/// The script that records the presses a page receives.
///
/// It reads the key of the nearest ancestor that has one, and the position of the press
/// inside that element, in that element's own pixels — the same coordinates a Flutter
/// renderer reports for the same press.
const String pressScript =
    '''
(function () {
  'use strict';
  var attribute = '$pressKeyAttribute';
  var limit = $pressRecordLimit;
  var unibox = window.unibox = window.unibox || {};

  if (unibox.takePressed) { return; }

  var pressed = [];

  function nearest(node) {
    while (node && node.nodeType === 1) {
      if (node.hasAttribute(attribute)) { return node; }
      node = node.parentNode;
    }
    return null;
  }

  document.addEventListener('pointerdown', function (event) {
    var named = nearest(event.target);

    if (!named) { return; }

    var box = named.getBoundingClientRect();

    pressed.push({
      key: named.getAttribute(attribute),
      dx: event.clientX - box.left,
      dy: event.clientY - box.top
    });

    if (pressed.length > limit) { pressed.shift(); }
  }, { capture: true, passive: true });

  // The presses recorded since the page arrived, oldest first, taken once: a runtime that
  // replays them twice would press twice.
  unibox.takePressed = function () {
    var taken = pressed;
    pressed = [];
    return taken;
  };
})();
''';
