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
///   takeover: const Takeover(boot: '../../flutter/app.js'),
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
    this.record = true,
    this.nonce,
  });

  /// The url of the loader that boots the application, relative to the document.
  final String boot;

  /// When the boot starts.
  final BootPolicy policy;

  /// Whether the recorders travel with the boot.
  ///
  /// They are what lets an application start where the reader left: where a region was scrolled
  /// to, and what was pressed before the application existed.
  final bool record;

  /// The `nonce` a content security policy expects, if it has one.
  final String? nonce;

  /// The scripts this takeover carries, in the order a page should run them.
  List<String> get scripts => <String>[
    if (record) uniboxClientScript,
    bootScript(boot, policy: policy),
  ];

  /// The link that fetches the loader while the reader reads, so a boot that waits for a
  /// signal is never a boot on a cold cache.
  DocumentLink get prefetch => DocumentLink.prefetch(boot, as: 'script');
}
