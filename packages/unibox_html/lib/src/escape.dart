/// Escaping, for the one place this package can be unsafe.
///
/// A string renderer's only security surface is the text it writes: everything a node
/// carries is a `String` from the application, and the moment one of them contains a
/// `<`, an attribute ends and markup begins. So every value passes through one of these
/// before it reaches the output, and the tests that come with them are adversarial
/// rather than illustrative.
library;

import 'package:unibox_element/unibox_element.dart';

/// [value] escaped for HTML content between two tags.
///
/// `&`, `<` and `>` are the three characters that can end text and start an element or a
/// character reference. `"` and `'` are left alone: neither has a meaning in element
/// content, and escaping them makes a page's source harder to read than it needs to be.
String escapeText(String value) {
  if (!value.contains(_textSpecials)) {
    return value;
  }

  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

/// [value] escaped for a double-quoted HTML attribute.
///
/// The quote is escaped as well as the three content specials, because an attribute ends
/// at the quote that opened it: an unescaped `"` in a value is how a `class` becomes an
/// `onload`.
String escapeAttribute(String value) {
  if (!value.contains(_attributeSpecials)) {
    return value;
  }

  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

/// [value] as a URL an element may point at, escaped for an attribute.
///
/// A `javascript:` or `vbscript:` URL in an `href` is a script that runs when a reader
/// clicks, which no tree states on purpose — it arrives because a URL came from data. It
/// is replaced with `#`, which keeps the element a link with a destination that does
/// nothing, rather than dropping the attribute and quietly changing the markup. [isRiskyUrl]
/// is what a validator should ask, so that the tree is reported rather than only patched.
String safeUrl(String value) =>
    escapeAttribute(isRiskyUrl(value) ? '#' : value);

/// The characters that end text or start a reference.
final RegExp _textSpecials = RegExp('[&<>]');

/// The characters that end an attribute, plus the ones that end text.
final RegExp _attributeSpecials = RegExp('[&<>"]');
