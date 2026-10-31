import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';

import 'showcase_frame.dart';
import 'surface.dart';

/// The two trees this one build draws, and the address that says which.
enum HostedPage {
  /// The site page, at the root of the Flutter build: `/flutter/`.
  site,

  /// The example, at every other address: the route below the build's root, a takeover
  /// document, a phone.
  example,
}

/// The page the application was loaded at, read from [address].
///
/// One build draws both trees, and the address is what says which. The Flutter build is
/// served one directory below the site, so its *root* is the site page and the route below
/// it — `/flutter/listings/` — is the example on its own. A takeover document
/// (`web/takeover/`, the right frame of the HTML page) boots the same bundle and draws the
/// example, because that is the page its frame framed. Everything else — a phone, a test, a
/// `flutter run` at the server's root — is the example, which is what this application was
/// before the site had a Flutter rendering.
HostedPage hostedPageFor(Uri address) {
  final List<String> segments = address.pathSegments
      .where((String segment) => segment.isNotEmpty)
      .toList(growable: false);

  return segments.isNotEmpty && segments.last == 'flutter'
      ? HostedPage.site
      : HostedPage.example;
}

/// The Flutter host of the site page.
///
/// The page `unibox_html` writes at `/`, drawn by the renderer that draws the application,
/// so the two renderings of one tree can be held side by side. The tree *is* the page; this
/// file is only what a node cannot know — the surface, the theme, what following a link
/// means, and the frames.
class SiteApp extends StatefulWidget {
  /// Creates the site page in [seed]'s palette.
  const SiteApp({super.key, this.seed = ExampleSeed.defaultSeed});

  /// The palette the page is drawn with on the first frame, which the picker replaces.
  final ExampleSeed seed;

  @override
  State<SiteApp> createState() => _SiteAppState();
}

class _SiteAppState extends State<SiteApp> {
  late ExampleSeed _seed = widget.seed;

  /// What following a link means here: a seed is a palette, so it is a rebuild; anything
  /// else is a destination this build does not serve — the site's own pages are the HTML
  /// rendering's business — and it says so rather than doing nothing.
  void _open(String url) {
    final String? name = Uri.tryParse(url)?.queryParameters['seed'];

    if (name == null) {
      debugPrint('Following $url');
      return;
    }

    setState(() => _seed = ExampleSeed.fromName(name));
  }

  @override
  Widget build(BuildContext context) {
    final UniboxTheme theme = ExamplePalette.themeFor(_seed);

    return surface(
      title: 'Unibox — the site, drawn by Flutter',
      theme: theme,
      child: FlutterLinkScope(
        open: _open,
        // A document scrolls; a column of bands taller than the window needs one scroll view
        // around it, which is the whole of what the other renderer gets from the browser.
        child: SingleChildScrollView(
          child: renderFlutter(
            buildSitePage(frame: showcaseFrame, seed: _seed),
            theme: theme,
          ),
        ),
      ),
    );
  }
}
