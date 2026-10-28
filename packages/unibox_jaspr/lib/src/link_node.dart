import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;
import 'package:unibox_core/unibox_core.dart' as core;

import 'labels.dart';
import 'render.dart';
import 'stylesheet.dart';

/// Renders a [core.LinkNode] as a semantic `<a>` element.
///
/// The `href` keeps the link working without JavaScript: middle clicks, the
/// context menu, prefetching and search engines all behave like they do on any
/// other website. [core.LinkNode.newTab] sets `target="_blank"` together with
/// `rel="noopener noreferrer"`, so the opened page never gets a handle on the
/// opener or its referrer.
///
/// [core.LinkNode.onTap] is called from a plain `click` listener rather than from
/// the component's `onClick`, because that listener has to decide whether the
/// browser follows the link as well: a link the tree answers does not also load its
/// document — see [_handlePress].
///
/// The anchor declares `color: inherit` and `text-decoration: none`, which turns
/// off the two things the browser adds to a link on its own. An `<a>` is not a
/// text node, so the typography of the enclosing box has to reach it explicitly,
/// and Flutter's link renderer draws its child as it is — no underline, no link
/// colour — so leaving the user agent styles in place would make the same tree
/// look different on the two targets.
class JasprLink extends StatelessComponent {
  /// Creates a renderer for [node].
  const JasprLink({required this.node, super.key});

  /// The node being rendered.
  final core.LinkNode node;

  @override
  Component build(BuildContext context) {
    final core.TapCallback? onTap = node.onTap;
    final bool newTab = node.newTab;

    final String? className = UniboxStylesheetScope.of(context)?.classFor(
      'link',
      declarationsOf(_anchorStyles),
      (String name) => <StyleRule>[
        StyleRule(selector: Selector.className(name), styles: _anchorStyles),
      ],
    );

    return a(
      <Component>[renderNode(node.child)],
      href: node.url,
      target: newTab ? Target.blank : null,
      attributes: withNodeAttributes(node, newTab ? _newTabAttributes : null),

      classes: className,
      styles: className == null ? _anchorStyles : null,
      events: onTap == null
          ? null
          : <String, EventCallback>{
              'click': (web.Event event) => _handlePress(event, node, onTap),
            },
    );
  }
}

/// Answers a press on a link whose node carries a [core.LinkNode.onTap].
///
/// The node named a handler, so the tree owns the press: the browser is told not to
/// follow the `href` and only the handler runs. Without that both happen — the
/// runtime opens the dialog the press asked for *and* the browser loads the document
/// the anchor names, so a visitor sees a flash of a page they never asked for. The
/// `href` stays on the anchor, which is what keeps a page without the runtime a page
/// whose links still work.
///
/// Two presses stay the browser's. A link that opens in a new tab cannot be taken
/// over — the destination is the point and the page the visitor is on stays — so its
/// handler runs and the tab opens. A click with a modifier, or with a button other
/// than the primary one, asks for a tab, a window or a download, which is a question
/// only the browser can answer: it is not a press of the control, so the handler
/// stays quiet.
void _handlePress(web.Event event, core.LinkNode node, core.TapCallback onTap) {
  // A server render has no navigation to cancel and no event fields to read: what it
  // writes is the listener for the client to use.
  if (!kIsWeb || node.newTab) {
    onTap();
    return;
  }

  if (!_isPlainPress(event)) {
    return;
  }

  event.preventDefault();
  onTap();
}

/// Whether [event] is a plain primary click: no modifier and no other button.
bool _isPlainPress(web.Event event) {
  // A `click` is always a mouse event in a browser, and its fields are the only
  // place the modifiers and the button a press came from are stated.
  final web.MouseEvent click = event as web.MouseEvent;

  return click.button == 0 &&
      !click.ctrlKey &&
      !click.metaKey &&
      !click.shiftKey &&
      !click.altKey;
}

/// The declarations that cancel what the browser does to a link by itself.
///
/// `color: inherit` makes the anchor use the typography of its box instead of the
/// user agent link colour, and `text-decoration: none` removes the underline, so
/// a link is drawn exactly like the text the node tree describes.
const Styles _anchorStyles = Styles(
  raw: <String, String>{'color': 'inherit', 'text-decoration': 'none'},
);

/// Attributes that make a `target="_blank"` link safe.
const Map<String, String> _newTabAttributes = <String, String>{
  'rel': 'noopener noreferrer',
};
