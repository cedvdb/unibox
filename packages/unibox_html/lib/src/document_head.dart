import 'escape.dart';

/// The head of a document: what a crawler reads, a link preview shows and the first paint
/// needs.
///
/// A node describes a region of a page, so the page's own title, address and translations
/// belong to the host. They arrive here as one value rather than as a handful of arguments of
/// [toDocument] that have to agree with each other — a page in one language whose canonical
/// address points at another is the bug a localised site actually has, and one value is what
/// lets a host build the whole head once per language.
///
/// Everything but [raw] is escaped on the way out, so a title that came from data cannot end
/// the element it is written into. [raw] is the opposite by design: markup this package does
/// not describe, written verbatim, so it is the host's own text and never a string assembled
/// from something a reader supplied.
///
/// The language the page is written in is not here: `lang` is an attribute of the root
/// element and not a head element, which is why [toDocument] takes it beside this value.
///
/// ```dart
/// final String page = toDocument(
///   ListingsPage(listings),
///   lang: 'de',
///   head: const DocumentHead(
///     title: 'Wohnungen in Amsterdam',
///     canonical: 'https://example.com/de/apartments/',
///     alternates: <String, String>{'de': …, 'en': …, 'x-default': …},
///   ),
/// );
/// ```
final class DocumentHead {
  /// Creates the head of a document.
  const DocumentHead({
    this.title,
    this.description,
    this.image,
    this.canonical,
    this.alternates = const <String, String>{},
    this.meta = const <String, String>{},
    this.links = const <DocumentLink>[],
    this.raw = const <String>[],
  });

  /// A head that is only markup this package does not describe.
  ///
  /// The shorthand for a host whose page states nothing else, and for a test that wants one
  /// element in the head:
  ///
  /// ```dart
  /// final String page = toDocument(
  ///   card,
  ///   head: DocumentHead.raw(<String>['<style>@font-face{…}</style>']),
  /// );
  /// ```
  const DocumentHead.raw(List<String> raw) : this(raw: raw);

  /// The title a result links and a tab shows.
  ///
  /// Written as `<title>`, and again as `og:title` for a preview. It is also the text a
  /// reader sees in a bookmark, so it names the page and not only the site.
  final String? title;

  /// The sentence a result shows under the title.
  ///
  /// Written as `<meta name="description">` and again as `og:description`. A search engine
  /// treats it as a suggestion rather than an instruction, which is why the page still has to
  /// say what it is in its own text.
  final String? description;

  /// The image a link preview shows.
  ///
  /// Written as `og:image`. A preview without one is a line of text in a feed, so this is the
  /// other half of being found — and the url goes through `safeUrl`, because an image address
  /// comes from data as often as from code.
  final String? image;

  /// The address of this page.
  ///
  /// Written as `<link rel="canonical">`, and it is what stops two addresses that serve the
  /// same page — with and without a trailing slash, with a query string, with a `www` — from
  /// competing as duplicates of each other.
  final String? canonical;

  /// The same page in its other languages, keyed by the `hreflang` value a search engine
  /// matches on.
  ///
  /// `'de'`, `'de-AT'`, and `'x-default'` for the address that answers a language the site
  /// does not have. Every page of a translation set names the whole set, itself included: a
  /// crawler told nothing sees three pages of translated text and treats two of them as
  /// duplicates of the third. Each url goes through `safeUrl`, because a locale is assembled
  /// from an address rather than typed by hand.
  final Map<String, String> alternates;

  /// Metadata a host needs and this package does not know, as `name`/`content` pairs.
  ///
  /// Written as `<meta name="…" content="…">`. A tag whose attribute is `property` rather
  /// than `name`, and that the fields above do not cover, belongs in [raw].
  final Map<String, String> meta;

  /// Resources to fetch before anything asks for them: the font a host ships, the image the
  /// first paint needs, the bundle the page is likely to load.
  ///
  /// Written in the order given and before the stylesheet, so a fetch starts with the
  /// document instead of after it — which is the difference between a font that arrives with
  /// the text and one that arrives a round trip behind it.
  final List<DocumentLink> links;

  /// Markup written verbatim, after the stylesheet and before the tree.
  ///
  /// This is where a host's own `<style>` goes, and the position is the point: an equally
  /// specific rule written after the renderer's stylesheet outranks it, so a host can restate
  /// a colour role for one page — and the `@font-face` rules of the font it ships still
  /// arrive before the text that uses them. Structured data belongs here too, because
  /// `application/ld+json` is a script element rather than a tag this value could describe.
  final List<String> raw;
}

/// A `<link>` a document names before anything uses it.
///
/// Written as a value rather than as markup for the reason `DocumentScript` is: the attributes
/// a browser needs are easy to leave out in exactly the case that matters, and nothing about a
/// string of markup says so. A font preload without `crossorigin` is fetched twice — once for
/// the preload and once for the `@font-face` that names it — which is worse than no preload at
/// all, and it is the mistake this type exists to make impossible.
///
/// ```dart
/// const DocumentHead(
///   links: <DocumentLink>[
///     DocumentLink.preload(
///       'assets/fonts/roboto-400.woff2',
///       as: 'font',
///       type: 'font/woff2',
///       crossorigin: true,
///     ),
///   ],
/// );
/// ```
final class DocumentLink {
  /// Creates a link.
  const DocumentLink({
    required this.rel,
    required this.href,
    this.as,
    this.type,
    this.crossorigin = false,
  });

  /// A resource fetched ahead of the document asking for it.
  ///
  /// [as] is what the browser sets the request's priority and headers from, and the
  /// specification requires it for a preload; [type] lets it skip a fetch it cannot use.
  const DocumentLink.preload(
    String href, {
    required String as,
    String? type,
    bool crossorigin = false,
  }) : this(
         rel: 'preload',
         href: href,
         as: as,
         type: type,
         crossorigin: crossorigin,
       );

  /// A resource fetched at a low priority, for a page likely to ask for it later.
  ///
  /// A boot that waits for a signal is never a boot on a cold cache because of one of these.
  const DocumentLink.prefetch(String href, {String? as, String? type})
    : this(rel: 'prefetch', href: href, as: as, type: type);

  /// How the document relates to what it names: `'preload'`, `'prefetch'`, `'preconnect'`,
  /// `'manifest'`, `'icon'`.
  final String rel;

  /// The url, relative to the document unless it is absolute.
  final String href;

  /// What the browser will use the resource as: `'script'`, `'font'`, `'image'`, `'style'`.
  final String? as;

  /// The MIME type, which a browser may use to skip a fetch it cannot use.
  final String? type;

  /// Whether the request is a CORS one.
  ///
  /// A bare `crossorigin` attribute means `anonymous`, which is what a font needs even when it
  /// is served from the same origin: without it the browser fetches the file twice.
  final bool crossorigin;

  /// This link as HTML.
  String write() {
    final StringBuffer buffer = StringBuffer('<link rel="')
      ..write(escapeAttribute(rel))
      ..write('" href="')
      ..write(safeUrl(href))
      ..write('"');

    final String? asValue = as;

    if (asValue != null) {
      buffer.write(' as="${escapeAttribute(asValue)}"');
    }

    final String? typeValue = type;

    if (typeValue != null) {
      buffer.write(' type="${escapeAttribute(typeValue)}"');
    }

    if (crossorigin) {
      buffer.write(' crossorigin');
    }

    buffer.write('>');

    return buffer.toString();
  }
}
