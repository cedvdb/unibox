import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
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
/// [core.LinkNode.onTap] is called from a plain `click` listener instead of the
/// component's `onClick`, because `onClick` would call `preventDefault()` and
/// stop the browser from following the link.
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
      attributes: withNodeLabel(node, newTab ? _newTabAttributes : null),

      classes: className,
      styles: className == null ? _anchorStyles : null,
      events: onTap == null
          ? null
          : <String, EventCallback>{'click': (event) => onTap()},
    );
  }
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
