import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';
import 'package:unibox_element/unibox_element.dart';

import 'embed_node.dart';
import 'write.dart';

/// The tree as an HTML fragment, with one `<style>` element in front of it.
///
/// A fragment is what an island inside someone else's page needs; `toDocument` is what a
/// crawler needs. Both come from the same plan, so a page and a fragment never disagree about
/// what an element is.
///
/// Interactivity is not part of it: a `StatefulNode` draws the state its store starts in, an
/// `OverlayNode` draws its overlay open, and no callback becomes a listener. A document is a
/// snapshot of a state, and the application is what makes it move.
String toHtml(
  core.UINode node, {
  core.UniboxTheme? theme,
  bool showOverlays = false,
}) {
  final Stylesheet sheet = Stylesheet();
  final ElementPlan plan = planNode(
    node,
    sheet,
    options: _options(showOverlays, sheet),
  );

  return '<style>${sheetWithRoot(sheet, theme: theme)}</style>'
      '${writeElement(plan)}';
}

/// The plan of [node] and the CSS it needs, for a caller that wants the two separately — a page
/// puts the stylesheet in the head and the tree in the body.
({ElementPlan plan, String css}) renderFragment(
  core.UINode node, {
  core.UniboxTheme? theme,
  bool showOverlays = false,
}) {
  final Stylesheet sheet = Stylesheet();
  final ElementPlan plan = planNode(
    node,
    sheet,
    options: _options(showOverlays, sheet),
  );

  return (plan: plan, css: sheetWithRoot(sheet, theme: theme));
}

/// The options of a rendering, with this target's way of drawing an embed.
PlanOptions _options(bool showOverlays, Stylesheet sheet) => PlanOptions(
  showOverlays: showOverlays,
  embed: (core.EmbedNode embed) => _planEmbed(embed, sheet),
);

/// The CSS a document needs before the tree: the typography of the model, the colours of the
/// theme, then every class the tree wears.
///
/// The `:root` block first, because it is what a text with no declarations of its own inherits;
/// the classes after it, so a look always outranks the default it started from.
String sheetWithRoot(Stylesheet sheet, {core.UniboxTheme? theme}) {
  final CssDeclarations root = defaultTypographyDeclarations();

  if (theme != null) {
    root.addAllIn(themeDeclarations(theme));
  }

  return ':root{${root.text}}${sheet.css}';
}

/// An embed, written into the page as the markup it carries.
///
/// Only an [HtmlEmbed] is drawn: a node carrying a payload for another target is reported rather
/// than skipped, because a page with a piece missing is worse than a failure.
///
/// The element it is written in takes no part in the layout (`display: contents`), so the payload
/// is laid out by the box around the embed rather than by a box this renderer invented. Without
/// that, the wrapper is a block of unknown height: an `<iframe>` asking for `height: 100%` gets
/// nothing to resolve against and falls back to the browser's 150 pixels, which is how the two
/// frames of the example's comparison came out a quarter of the height they were given.
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
    'No HTML renderer for ${embed.runtimeType}: this target draws an HtmlEmbed, and the node '
    'carries ${embed.implementations.map((Object it) => it.runtimeType).join(', ')}.',
  );
}
