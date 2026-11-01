import 'client/all.dart';
import 'client/boot.dart';
import 'document_head.dart';

/// A page that an application takes over, in one argument.
///
/// A host that wants a document first and an app afterwards has four things to get right: the
/// bundle is *prefetched* while the reader reads, the recorders travel with the boot so the app
/// can pick the page up mid-read, the boot waits for a signal rather than blocking the first
/// paint, and the policy says which signals count. Written out, that is three arguments in two
/// spellings — and a host that got `prefetch` and `scripts` the wrong way round would ship a page
/// that boots on a cold cache.
///
/// So it is one value, and [toDocument] does the wiring:
///
/// ```dart
/// final String page = toDocument(
///   ListingsPage(listings),
///   takeover: const Takeover(boot: '../../flutter/flutter_bootstrap.js'),
/// );
/// ```
///
/// [policy] is the one choice a host makes, because only it knows which kind of page it
/// published — see [BootPolicy]. [record] decides whether the two recorders travel with the boot:
/// a page whose regions are keyed and whose application replays them wants them, and a page that
/// only has to boot does not.
final class Takeover {
  /// Creates the takeover of a page.
  const Takeover({
    required this.boot,
    this.policy = BootPolicy.onPointer,
    this.reveal = RevealPolicy.onFrame,
    this.readyTimeout = const Duration(seconds: 8),
    this.loadingLabel = 'Opening the application…',
    this.readyLabel = 'The application is ready',
    this.openLabel = 'Open the application',
    this.record = true,
    this.debug = false,
    this.query = true,
    this.nonce,
  });

  /// The url of the loader that boots the application, relative to the document.
  final String boot;

  /// When the boot starts.
  final BootPolicy policy;

  /// When the application is worth showing — see `RevealPolicy`.
  ///
  /// `onFrame` shows the engine's first frame; `onReady` waits for the application to say it has
  /// drawn the state it was given, which is the right answer for a page whose scroll offset and
  /// press are being replayed. A takeover drawn by `unibox_flutter` needs no code of its own for
  /// either: the renderer answers both.
  final RevealPolicy reveal;

  /// How long `RevealPolicy.onReady` waits before revealing anyway, and how long a page waits for
  /// a frame at all before going back to being a document.
  final Duration readyTimeout;

  /// The name of the control while the application loads, for the reader who pressed it.
  final String loadingLabel;

  /// What the document announces when the application has taken the page.
  ///
  /// The reveal swaps what a screen reader can read — a document for a canvas — so it says so
  /// once, in a `role="status"` region, in the language of the document element.
  final String readyLabel;

  /// The name of the control that opens the application, for a reader the pointer signals never
  /// reach — a keyboard reader, or one whose assistive technology drives the focus.
  ///
  /// Only [BootPolicy.onIntent] writes it, because it is the one policy that has no way in
  /// otherwise: a press, a key and a focus move are not signals *by design* (see the policy), so
  /// the document carries a control that says what it does instead. Name it after the application
  /// rather than the technology — `'Open the map'`, not `'Switch to Flutter'` — because that is
  /// what a reader is choosing, and it is written into the content of the page rather than into an
  /// attribute, so it belongs to the document's language.
  final String openLabel;

  /// Whether the recorders travel with the boot.
  ///
  /// They are what lets an application start where the reader left: where a region was scrolled
  /// to, and what was pressed before the application existed.
  final bool record;

  /// Whether the address may ask for a debug report, a profile or a comparison.
  ///
  /// It is a build decision on purpose: `?unibox=debug`, `?unibox=profile` and `?unibox=compare`
  /// all *show* something the host did not publish, so a visitor can only reach one where the
  /// build already allowed it. `?unibox=document` needs no flag — it can only take an application
  /// away.
  final bool debug;

  /// Whether the boot reads the address at all.
  ///
  /// False for a page whose query string is data rather than a choice, and for a host whose
  /// content-security policy refuses nothing but its own parameters.
  final bool query;

  /// The `nonce` a content security policy expects, if it has one.
  final String? nonce;

  /// The scripts this takeover carries, in the order a page should run them.
  List<String> get scripts => <String>[
    if (record) uniboxClientScript,
    bootScript(
      boot,
      policy: policy,
      openLabel: openLabel,
      reveal: reveal,
      readyTimeout: readyTimeout,
      loadingLabel: loadingLabel,
      readyLabel: readyLabel,
      debug: debug,
      query: query,
    ),
  ];

  /// The link that fetches the loader while the reader reads, so a boot that waits for a
  /// signal is never a boot on a cold cache.
  DocumentLink get prefetch => DocumentLink.prefetch(boot, as: 'script');
}
