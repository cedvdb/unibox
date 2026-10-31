import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';

import 'document_head.dart';
import 'escape.dart';

import 'package:unibox_element/unibox_element.dart';

import 'render.dart';
import 'takeover.dart';
import 'write.dart';

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

/// A page as a value: the tree, the language it is written in, the head that names it, and the
/// host's choices for how it is written.
///
/// [toDocument] is the whole of this in one call, and stays the shorter path for a host that
/// writes one page. This is for the host that writes several: a build holds a list of documents
/// beside the addresses they are served at, writes them all the same way, and can hand the same
/// list to anything else that has to know what the site contains — a sitemap, a router, a test
/// that every page states its own address.
///
/// ```dart
/// final Document listings = Document(
///   node: ListingsPage(flats),
///   head: const DocumentHead(title: 'Apartments in Amsterdam'),
/// );
///
/// File('site/listings/index.html').writeAsStringSync(listings.write());
/// ```
final class Document {
  /// Creates a page.
  const Document({
    required this.node,
    this.lang = 'en',
    this.writingDirection,
    this.head = const DocumentHead(),
    this.scripts = const <DocumentScript>[],
    this.theme,
    this.showOverlays = false,
    this.takeover,
  });

  /// The tree, drawn into the body.
  final core.UINode node;

  /// The language the page is written in: an attribute of the root element rather than a head
  /// element, which is why it sits beside [head] and not in it.
  final String lang;

  /// The direction the page is written in, or `null` to write no `dir` at all.
  ///
  /// It is the `dir` attribute of the same root element as [lang], and the two are
  /// deliberately separate: a language is not a direction. Azerbaijani, Kurdish and
  /// Punjabi are written in both scripts, and a page in Arabic can hold a region — a
  /// quotation, a code block, a price — that reads left to right. Everything inside
  /// inherits this, so a page written right to left states it once here and a box only
  /// states its own where a region differs.
  final core.WritingDirection? writingDirection;

  /// What the page says about itself: a title, an address, its translations, the resources it
  /// needs in the head.
  final DocumentHead head;

  /// The scripts the host needs, deferred, in the order they should run.
  final List<DocumentScript> scripts;

  /// The values a tree that names colour roles is drawn with.
  final core.UniboxTheme? theme;

  /// Whether an overlay is written open, for a page whose published state *is* a dialog.
  final bool showOverlays;

  /// What turns the page into an application, when it is one.
  final Takeover? takeover;

  /// This page as HTML: [toDocument] with every field of this value.
  String write() => toDocument(
    node,
    lang: lang,
    writingDirection: writingDirection,
    head: head,
    scripts: scripts,
    theme: theme,
    showOverlays: showOverlays,
    takeover: takeover,
  );

  /// This page as it is served at [address], which is the one thing a build knows and a page
  /// does not.
  ///
  /// The address becomes the canonical url: the address a search engine attributes the page to
  /// when two of them serve the same content, which is why it can only be stated once the build
  /// has decided where the page goes. Every other field is kept, so a build can take the pages
  /// it was handed and give each one its address without knowing how it was built.
  Document at(String address) => Document(
    node: node,
    lang: lang,
    writingDirection: writingDirection,
    head: DocumentHead(
      title: head.title,
      description: head.description,
      image: head.image,
      canonical: address,
      alternates: head.alternates,
      meta: head.meta,
      links: head.links,
      raw: head.raw,
    ),
    scripts: scripts,
    theme: theme,
    showOverlays: showOverlays,
    takeover: takeover,
  );
}

/// The tree as a page: the head a crawler reads, then the tree in the body.
///
/// A document is what a search engine, a link preview and a reader without JavaScript
/// see. [head] states everything a host can say about it — a title, a description, the image
/// a preview shows, its address, the languages it is translated into, and the markup the page
/// needs — and the tree goes into the body exactly as `toHtml` renders it.
///
/// ```dart
/// final String page = toDocument(
///   ListingsPage(listings),
///   head: const DocumentHead(
///     title: 'Apartments in Amsterdam',
///     description: 'Six flats, from the same tree Flutter draws.',
///     canonical: 'https://example.com/apartments/',
///   ),
/// );
/// ```
///
/// The order is the renderer's rather than the host's, because two of the positions matter and
/// neither is visible in a value: the stylesheet is written after the metadata and the
/// prefetches, so those fetches start with the document, and before the head's own markup, so
/// a host rule of equal specificity can outrank the `:root` block. The encoding is first of
/// all, because a browser that has to guess it may reparse the document.
///
/// The stylesheet goes into the head rather than in front of the tree: a page whose look
/// arrives with the first paint does not flash an unstyled version of itself, and the LCP
/// candidate is painted once.
///
/// [scripts] are for the host's own: Flutter's bootstrap, the scroll recorder, an
/// analytics file. Each is deferred by default, so nothing blocks the first paint, and a
/// [takeover] adds its own before they run.
///
/// [lang] is the language the page is written in — an attribute of the root element rather
/// than a head element, which is why it sits beside [head] and not in it. Which language a
/// reader is given is the host's decision, and the address is the only place a crawler can
/// read it from — so `/de/apartments/` is the German page, and a header or a cookie would be a
/// page no crawler ever sees.
///
/// A host that writes several pages holds them as [Document] values instead, one per address,
/// and writes each with the same call.
///
/// [writingDirection] is the `dir` attribute of the same root element as [lang], and it is
/// what everything on the page that states no direction of its own inherits. Unset writes
/// no attribute at all, so the page reads in the browser's direction and nothing is
/// claimed on its behalf; a page translated into Arabic states [core.WritingDirection.rtl]
/// once here, and a region inside it that is not in Arabic states its own on the box.
/// Language and direction are two attributes and not one because a language is not a
/// direction: a page can be Dutch and hold an Arabic quotation, and a language can be
/// written in either script.
String toDocument(
  core.UINode node, {
  String lang = 'en',
  core.WritingDirection? writingDirection,
  DocumentHead head = const DocumentHead(),
  List<DocumentScript> scripts = const <DocumentScript>[],
  core.UniboxTheme? theme,
  bool showOverlays = false,
  Takeover? takeover,
}) {
  final ({ElementPlan plan, String css}) rendered = renderFragment(
    node,
    theme: theme,
    showOverlays: showOverlays,
  );
  final StringBuffer buffer = StringBuffer();

  // First, always: a browser that has to guess the encoding may reparse the document.
  buffer.write('<meta charset="utf-8">');
  buffer.write(
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
  );

  final String? title = head.title;

  if (title != null) {
    buffer.write('<title>${escapeText(title)}</title>');
  }

  final String? description = head.description;

  if (description != null) {
    buffer.write(
      '<meta name="description" content="${escapeAttribute(description)}">',
    );
  }

  final String? canonical = head.canonical;

  if (canonical != null) {
    buffer.write('<link rel="canonical" href="${safeUrl(canonical)}">');
  }

  // The same page in its other languages. Without these a search engine compares translated
  // copies of one page and keeps one of them, so the translations compete as duplicates of
  // each other. A locale arrives from an address a reader typed, so the url goes through the
  // same gate the canonical does and the tag is escaped like any other string.
  for (final MapEntry<String, String> entry in head.alternates.entries) {
    buffer.write(
      '<link rel="alternate" hreflang="${escapeAttribute(entry.key)}" '
      'href="${safeUrl(entry.value)}">',
    );
  }

  // What a link preview shows, which is the other half of being found: the title and the
  // sentence of the card, then the image it is drawn around.
  if (title != null) {
    buffer.write(
      '<meta property="og:title" content="${escapeAttribute(title)}">',
    );
  }

  if (description != null) {
    buffer.write(
      '<meta property="og:description" '
      'content="${escapeAttribute(description)}">',
    );
  }

  final String? image = head.image;

  if (image != null) {
    buffer.write('<meta property="og:image" content="${safeUrl(image)}">');
  }

  for (final MapEntry<String, String> entry in head.meta.entries) {
    buffer.write(
      '<meta name="${escapeAttribute(entry.key)}" '
      'content="${escapeAttribute(entry.value)}">',
    );
  }

  // A resource named before anything asks for it starts its fetch with the document instead
  // of after it: the download is not what a reader pays for, the execution is. Written before
  // the stylesheet for the same reason.
  for (final DocumentLink link in head.links) {
    buffer.write(link.write());
  }

  buffer.write('<style data-unibox-css>${rendered.css}</style>');

  // Markup the host owns and the model does not describe: the `@font-face` rules of the
  // asset it ships, a dark-mode block, a structured-data script. Written verbatim, so it is
  // the host's own text and never assembled from data a reader supplied — and written after
  // the stylesheet, so a host rule of equal specificity can restate what the page starts
  // with.
  for (final String markup in head.raw) {
    buffer.write(markup);
  }

  // A takeover says the same three things in one value: what to prefetch, which scripts to run,
  // and when the boot may start. Added before the host's own scripts, because the recorders
  // have to exist before the application asks what the reader did.
  if (takeover != null) {
    buffer.write(takeover.prefetch.write());

    for (final String script in takeover.scripts) {
      buffer.write(
        DocumentScript.inline(body: script, nonce: takeover.nonce).write(),
      );
    }
  }

  for (final DocumentScript script in scripts) {
    buffer.write(script.write());
  }

  // The direction of the whole page, stated on the root element so that every box that
  // names none inherits it: the same one attribute `dir="auto"` would occupy, with the
  // answer given rather than guessed from the first character of the text.
  final String direction = writingDirection == null
      ? ''
      : ' dir="${cssWritingDirection(writingDirection)}"';

  return '<!DOCTYPE html>'
      '<html lang="${escapeAttribute(lang)}"$direction>'
      '<head>${buffer.toString()}</head>'
      '<body>${writeElement(rendered.plan)}</body>'
      '</html>';
}
