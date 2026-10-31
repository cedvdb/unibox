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
    this.prefetch = const <String>[],
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

  /// Urls to fetch at a low priority while the reader reads.
  ///
  /// Written as `<link rel="prefetch" as="script">`, so it is a script prefetch: for a bundle
  /// the page is likely to ask for. It is placed before the stylesheet, so the download
  /// starts with the document instead of after it.
  final List<String> prefetch;

  /// Markup written verbatim, after the stylesheet and before the tree.
  ///
  /// This is where a host's own `<style>` goes, and the position is the point: an equally
  /// specific rule written after the renderer's stylesheet outranks it, so a host can restate
  /// a colour role for one page — and the `@font-face` rules of the font it ships still
  /// arrive before the text that uses them. Structured data belongs here too, because
  /// `application/ld+json` is a script element rather than a tag this value could describe.
  final List<String> raw;
}
