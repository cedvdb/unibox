import 'package:unibox_core/unibox_core.dart' as core;

import 'escape.dart';
import 'plan.dart';
import 'render.dart';

/// A script a page carries, in the head, in the order it is listed.
///
/// Written as a value rather than as a string of markup so the page cannot be assembled
/// wrong: a `src` is escaped, and an inline body is written raw for the same reason a
/// `<script>` needs it — nothing inside a raw text element is escaped, so escaping it
/// would ship `&amp;&amp;` and the file would not run.
final class DocumentScript {
  /// A script fetched from [src], deferred by default.
  const DocumentScript({
    required String this.src,
    this.defer = true,
    this.nonce,
  }) : body = null;

  /// A script written into the page.
  ///
  /// A host with a content security policy that refuses inline script should serve the
  /// same text as a file instead, or pass a [nonce].
  const DocumentScript.inline({required String this.body, this.nonce})
    : src = null,
      defer = false;

  /// The url the browser fetches, or `null` for a script written into the page.
  final String? src;

  /// The script itself, or `null` for one the browser fetches.
  final String? body;

  /// Whether the browser runs the script after the document is parsed.
  final bool defer;

  /// The `nonce` a policy that refuses inline script expects, if it has one.
  final String? nonce;

  /// This script as HTML.
  String write() {
    final String? source = src;

    if (source != null) {
      return '<script src="${safeUrl(source)}"${defer ? ' defer' : ''}'
          '${_nonceAttribute()}'
          '></script>';
    }

    return '<script${_nonceAttribute()}>${body ?? ''}</script>';
  }

  String _nonceAttribute() {
    final String? value = nonce;

    return value == null ? '' : ' nonce="${escapeAttribute(value)}"';
  }
}

/// The tree as a page: the head a crawler reads, then the tree in the body.
///
/// A document is what a search engine, a link preview and a reader without JavaScript
/// see, and every element of it is stated: `title`, `lang`, a description, a canonical
/// url, the Open Graph pair a preview uses, and the scripts the host needs.
///
/// ```dart
/// final String page = toDocument(
///   ListingsPage(listings),
///   title: 'Apartments in Amsterdam',
///   description: 'Six flats, from the same tree Flutter draws.',
///   canonical: 'https://example.com/apartments/',
/// );
/// ```
///
/// The stylesheet goes into the head rather than in front of the tree: a page whose look
/// arrives with the first paint does not flash an unstyled version of itself, and the LCP
/// candidate is painted once.
///
/// [scripts] are for the host's own: Flutter's bootstrap, the scroll recorder, an
/// analytics file. Each is deferred by default, so nothing blocks the first paint.
String toDocument(
  core.UINode node, {
  String? title,
  String lang = 'en',
  String? description,
  String? canonical,
  Map<String, String> meta = const <String, String>{},
  List<DocumentScript> scripts = const <DocumentScript>[],
  core.UniboxTheme? theme,
  bool showOverlays = false,
}) {
  final ({ElementPlan plan, String css}) rendered = renderFragment(
    node,
    theme: theme,
    showOverlays: showOverlays,
  );
  final StringBuffer head = StringBuffer();

  // First, always: a browser that has to guess the encoding may reparse the document.
  head.write('<meta charset="utf-8">');
  head.write(
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
  );

  if (title != null) {
    head.write('<title>${escapeText(title)}</title>');
  }

  if (description != null) {
    head.write(
      '<meta name="description" content="${escapeAttribute(description)}">',
    );
  }

  if (canonical != null) {
    head.write('<link rel="canonical" href="${safeUrl(canonical)}">');
  }

  // What a link preview shows, which is the other half of being found.
  if (title != null) {
    head.write(
      '<meta property="og:title" content="${escapeAttribute(title)}">',
    );
  }

  if (description != null) {
    head.write(
      '<meta property="og:description" '
      'content="${escapeAttribute(description)}">',
    );
  }

  for (final MapEntry<String, String> entry in meta.entries) {
    head.write(
      '<meta name="${escapeAttribute(entry.key)}" '
      'content="${escapeAttribute(entry.value)}">',
    );
  }

  head.write('<style>${rendered.css}</style>');

  for (final DocumentScript script in scripts) {
    head.write(script.write());
  }

  return '<!DOCTYPE html>'
      '<html lang="${escapeAttribute(lang)}">'
      '<head>${head.toString()}</head>'
      '<body>${rendered.plan.write()}</body>'
      '</html>';
}
