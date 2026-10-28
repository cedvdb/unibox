import 'package:flutter/material.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';

/// The family both hosts ship: `assets/fonts` in this app, the same files in
/// `assets/fonts` of the site.
const String fontFamily = 'UniboxText';

void main() => runApp(ExampleApp(signupOpen: signupOpenFromUrl()));

/// Whether the sign-up dialog starts open, read from the path the page is served at.
///
/// A static host cannot boot a page with a click, so the export writes one document
/// per state — `/flutter/listings/` and `/flutter/signup/` — and the app reads which
/// one it was served as. Any other path, and every build that is not a static
/// export, starts with the dialog closed.
bool signupOpenFromUrl() => Uri.base.pathSegments.contains('signup');

/// The Flutter host of the shared page.
///
/// The page is one node — [ExamplePageNode] — so this file is only what a node
/// cannot know: the surface the tree is drawn on, the theme its colour roles name,
/// and what following a link means. [FlutterStateful] creates the page's store,
/// subscribes to it, disposes it and installs the theme, so the host holds no state
/// and no scope of its own.
class ExampleApp extends StatelessWidget {
  /// Creates the example application.
  ///
  /// [signupOpen] is for the static site, where a document starts in the state the
  /// destination names instead of waiting for a click.
  const ExampleApp({super.key, this.signupOpen = false});

  /// Whether the sign-up dialog is open on the first frame.
  final bool signupOpen;

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
          open: (String url) => debugPrint('Following $url'),
          // The theme answers the colour roles the page names; the component
          // installs it, so the host states it once and cannot forget a scope.
          child: FlutterStateful(
            node: ExamplePageNode(signupOpen: signupOpen),
            theme: ExamplePalette.theme,
          ),
        ),
      ),
    );
  }
}
