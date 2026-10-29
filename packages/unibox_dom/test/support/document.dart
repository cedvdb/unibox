import 'dart:js_interop';

import 'package:unibox_dom/unibox_dom.dart';
import 'package:web/web.dart' as web;

/// A host for a view, in the document — a view draws into a page, so a test draws into one too.
web.HTMLDivElement host() {
  final web.HTMLDivElement element =
      web.document.createElement('div') as web.HTMLDivElement;
  web.document.body!.append(element);

  return element;
}

/// The view's output as the string a reader of the appearance table can read.
///
/// The stylesheet the view wrote and the markup it built, put together the way a document puts
/// them: the same reader in `unibox_testing` then describes what this renderer *did* with the node,
/// exactly as it describes what the string renderer did. That is the point of reading the output
/// rather than the plan — a class with no rule, or a rule the browser never receives, fails here.
String documentOf(DomView view) {
  final web.Element? style = web.document.head!.querySelector(
    'style[data-unibox-css]',
  );
  final String css = style?.textContent ?? '';
  final String markup = (view.element.outerHTML as JSString).toDart;

  return '<style>$css</style>$markup';
}
