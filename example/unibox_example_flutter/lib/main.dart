import 'package:flutter/material.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';

/// The family both hosts ship: `assets/fonts` in this app, the same files in
/// `assets/fonts` of the site.
const String fontFamily = 'UniboxText';

void main() =>
    runApp(ExampleApp(signupOpen: signupOpenFromUrl(), seed: seedFromUrl()));

/// Whether the sign-up dialog starts open, read from the path the page is served at.
///
/// A static host cannot boot a page with a click, so the export writes one document
/// per state — `/flutter/listings/` and `/flutter/signup/` — and the app reads which
/// one it was served as. Any other path, and every build that is not a static
/// export, starts with the dialog closed.
bool signupOpenFromUrl() => Uri.base.pathSegments.contains('signup');

/// The palette the page starts in, read from `?seed=<name>` the way the site reads it.
///
/// The picker is a row of links, so the choice travels as an address on both targets:
/// the browser loads the page with it, and this host reads it here once and then
/// answers the same addresses in [ExampleApp] without loading anything.
ExampleSeed seedFromUrl() =>
    ExampleSeed.fromName(Uri.base.queryParameters['seed']);

/// The Flutter host of the shared page.
///
/// The page is one node — [ExamplePageNode] — so this file is only what a node
/// cannot know: the surface the tree is drawn on, the theme its colour roles name,
/// and what following a link means. [FlutterStateful] creates the page's store,
/// subscribes to it, disposes it and installs the theme.
///
/// The seed is the one piece of state this host keeps. A palette is a theme, a theme
/// is installed by the host, and the tree only names roles — so choosing a seed is a
/// rebuild of this widget with another theme, and the page's own store (the dialog,
/// the filter, the fields) stays where it was.
class ExampleApp extends StatefulWidget {
  /// Creates the example application.
  ///
  /// [signupOpen] is for the static site, where a document starts in the state the
  /// destination names instead of waiting for a click. [seed] is the palette it
  /// starts in, which the picker then replaces.
  const ExampleApp({
    super.key,
    this.signupOpen = false,
    this.seed = ExampleSeed.blue,
  });

  /// Whether the sign-up dialog is open on the first frame.
  final bool signupOpen;

  /// The palette the page is drawn with on the first frame.
  final ExampleSeed seed;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late ExampleSeed _seed = widget.seed;

  /// What following a link means here: a seed is a palette, so it is a rebuild;
  /// anything else is a destination this host does not serve, and it says so.
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
    return MaterialApp(
      title: 'Unibox example',
      // The family the pubspec bundles, so the tree is drawn with the same four
      // files the site ships: a weight means the same thing on both renderings.
      theme: ThemeData(fontFamily: fontFamily),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: FlutterLinkScope(
          open: _open,
          // The theme answers the colour roles the page names; the component
          // installs it, so the host states it once and cannot forget a scope. The
          // node is told the same seed, because the picker marks which one is in
          // force — and two places saying it is the only way the mark can lie.
          child: FlutterStateful(
            node: ExamplePageNode(signupOpen: widget.signupOpen, seed: _seed),
            theme: ExamplePalette.themeFor(_seed),
          ),
        ),
      ),
    );
  }
}
