import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';
import 'package:unibox_element/unibox_element.dart';
import 'package:web/web.dart' as web;

import 'patch.dart';

/// A tree drawn into a page, and the elements it drew.
///
/// Created by [DomView.mount]: it plans the tree with this target's stylesheet, writes the
/// stylesheet into the document, and builds the elements the plan describes. [render] draws another
/// tree over the same elements — a child that is still there is patched where it stands, so a field
/// keeps its focus and a list keeps its elements when it reorders.
final class DomView {
  DomView._(this._plan, this._style, this._element, this._theme);

  /// Draws [tree] into [host], and returns the view that owns what it added.
  ///
  /// [host] is emptied: a view draws a whole tree, not a patch of one. [theme] answers the colour
  /// roles the tree names, exactly as in the string renderer — the same value produces the same
  /// `:root` block, so a class name and a custom property agree across the two renderings.
  static DomView mount(
    core.UINode tree,
    web.Element host, {
    core.UniboxTheme? theme,
  }) {
    final Stylesheet sheet = Stylesheet();
    final ElementPlan plan = planTree(tree, sheet);
    final web.HTMLStyleElement style =
        web.document.createElement('style') as web.HTMLStyleElement
          ..textContent = documentCss(sheet, theme: theme);
    web.document.head!.append(style);

    final web.Element element = buildElement(plan);
    host.replaceChildren(element);

    return DomView._(plan, style, element, theme);
  }

  ElementPlan _plan;
  final web.HTMLStyleElement _style;
  web.Element _element;
  final core.UniboxTheme? _theme;

  /// The element the tree was drawn into, which is what a host measures or scrolls.
  web.Element get element => _element;

  /// The plan this view drew, kept so the next render can compare against it.
  ElementPlan get plan => _plan;

  /// Draws [tree] over the elements this view already has.
  ///
  /// The plans are compared, not the elements: what changed is what is touched, and an element the
  /// new tree still describes is left where it is. That is what keeps a caret, a scroll position, a
  /// focus and a running animation alive across a re-render.
  void render(core.UINode tree) {
    final Stylesheet sheet = Stylesheet();
    final ElementPlan next = planTree(tree, sheet);

    _element = patchElement(_element, _plan, next);
    _plan = next;

    // The stylesheet is one string, so it is rewritten rather than diffed: a class the new tree no
    // longer wears would otherwise be a rule the page keeps paying for.
    _style.textContent = documentCss(sheet, theme: _theme);
  }

  /// Takes the view out of the page: the tree, and the stylesheet it brought with it.
  void dispose() {
    _element.remove();
    _style.remove();
  }
}

/// The plan of [tree] for a browser: every look registered in [sheet].
ElementPlan planTree(core.UINode tree, Stylesheet sheet) {
  return planNode(
    tree,
    sheet,
    options: PlanOptions(
      // A runtime is present, so an overlay in the tree is a dialog the reader can see and close;
      // a document hides it because nothing there can ask for it.
      showOverlays: true,
      embed: (core.EmbedNode embed) => planEmbed(embed, sheet),
    ),
  );
}

/// An embed, written into the page as the markup it carries.
///
/// Only a `String` payload is drawn: an embed carrying something for another target is reported
/// rather than skipped, because a page with a piece missing is worse than a failure. The wrapper
/// takes no part in the layout, for the reason the string renderer gives — an `<iframe>` asking for
/// `height: 100%` needs an ancestor with a height.
ElementPlan planEmbed(core.EmbedNode embed, Stylesheet sheet) {
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
