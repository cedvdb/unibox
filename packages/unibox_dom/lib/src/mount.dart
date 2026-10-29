import 'dart:js_interop';

import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';
import 'package:unibox_element/unibox_element.dart';
import 'package:web/web.dart' as web;

/// A tree drawn into a page, and the elements it drew.
///
/// Created by [mount]: it plans the tree once with this target's stylesheet, writes the stylesheet
/// into the document, and builds the elements the plan describes. Adopting a page a server wrote —
/// reusing its elements instead of building new ones — is the next step, and it is why this class
/// keeps the plan beside the element rather than throwing it away.
final class DomView {
  DomView._(this._plan, this._style, this._elements);

  /// Draws [tree] into [host], and returns the view that owns what it added.
  ///
  /// [host] is emptied: a view draws a whole tree, not a patch of one. [theme] answers the colour
  /// roles the tree names, exactly as it does in the string renderer — the same value produces the
  /// same `:root` block, so a class name and a custom property agree across the two.
  static DomView mount(
    core.UINode tree,
    web.Element host, {
    core.UniboxTheme? theme,
  }) {
    final Stylesheet sheet = Stylesheet();
    final Map<ElementPlan, core.UINode> nodes =
        Map<ElementPlan, core.UINode>.identity();

    final ElementPlan plan = planNode(
      tree,
      sheet,
      options: PlanOptions(
        // A runtime is present, so an overlay in the tree is a dialog the reader can see and
        // close; a document hides it because nothing there can ask for it.
        showOverlays: true,
        embed: (core.EmbedNode embed) => _planEmbed(embed, sheet),
        onPlanned: (ElementPlan plan, core.UINode node) => nodes[plan] = node,
      ),
    );

    final web.HTMLStyleElement style =
        web.document.createElement('style') as web.HTMLStyleElement
          ..textContent = documentCss(sheet, theme: theme);
    web.document.head!.append(style);

    final web.Element element = _build(plan);
    host.replaceChildren(element);

    return DomView._(plan, style, <web.Element>[element]);
  }

  final ElementPlan _plan;
  final web.HTMLStyleElement _style;
  final List<web.Element> _elements;

  /// The element the tree was drawn into, which is what a host measures or scrolls.
  web.Element get element => _elements.first;

  /// The plan this view drew, kept for the adoption step.
  ElementPlan get plan => _plan;

  /// Takes the view out of the page: the tree, and the stylesheet it brought with it.
  void dispose() {
    for (final web.Element element in _elements) {
      element.remove();
    }

    _style.remove();
  }
}

/// An embed, written into the page as the markup it carries.
///
/// Only a `String` payload is drawn: an embed carrying something for another target is reported
/// rather than skipped, because a page with a piece missing is worse than a failure. The wrapper
/// takes no part in the layout, for the reason the string renderer gives — an `<iframe>` asking for
/// `height: 100%` needs an ancestor with a height.
ElementPlan _planEmbed(core.EmbedNode embed, Stylesheet sheet) {
  for (final Object implementation in embed.implementations) {
    if (implementation is String) {
      return ElementPlan.raw(
        tag: 'div',
        raw: implementation,
        className: sheet.classFor(
          'embed',
          CssDeclarations()..add('display', 'contents'),
        ),
        attributes: nodeAttributes(embed),
      );
    }
  }

  throw UnsupportedError(
    'No DOM renderer for ${embed.runtimeType}: this target draws an HtmlEmbed, and the node '
    'carries ${embed.implementations.map((Object it) => it.runtimeType).join(', ')}.',
  );
}

/// [plan] as DOM nodes.
web.Element _build(ElementPlan plan) {
  final web.Element element = web.document.createElement(plan.tag);

  if (plan.className != null) {
    element.className = plan.className!;
  }

  plan.attributes.forEach((String name, String value) {
    element.setAttribute(name, value);
  });

  // The host's own markup, trusted as it is: an embed is the one place a page carries content the
  // model does not describe, and `innerHTML` is where that content belongs.
  if (plan.raw != null) {
    element.innerHTML = plan.raw!.toJS;
  }

  if (plan.text != null) {
    element.textContent = plan.text;
  }

  for (final ElementPlan child in plan.children) {
    element.append(_build(child));
  }

  return element;
}
