import 'package:flutter/material.dart';
import 'package:unibox_core/unibox_core.dart' show BoxPress, BoxScrollOffset;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';

/// The family both hosts ship: `assets/fonts` in this app, the same files in
/// `assets/fonts` of the site.
const String fontFamily = 'UniboxText';

void main() => runApp(
  ExampleApp(
    seed: seedFromUrl(),
    // What the page recorded before the application existed: where a region was scrolled to, and
    // what was pressed. Read once here, where a host does its other reads; every other platform
    // answers with nothing, because there is no page in front of it.
    offsets: scrollOffsetsFromPage(),
    presses: pressesFromPage(),
  ),
);

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
  /// [seed] is the palette it starts in, which the picker then replaces.
  const ExampleApp({
    super.key,
    this.seed = ExampleSeed.blue,
    this.offsets = const <BoxScrollOffset>[],
    this.presses = const <BoxPress>[],
  });

  /// The palette the page is drawn with on the first frame.
  final ExampleSeed seed;

  /// Where each region of the page was scrolled to, before the application arrived.
  final List<BoxScrollOffset> offsets;

  /// What was pressed before the application arrived.
  final List<BoxPress> presses;

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
        // Read once, as the controller's initial position, so a region is where the
        // reader left it at the first layout rather than after a correction.
        body: UniboxScrollScope(
          offsets: widget.offsets,
          child: FlutterLinkScope(
            open: _open,
            // The theme answers the colour roles the page names; the component
            // installs it, so the host states it once and cannot forget a scope. The
            // node is told the same seed, because the picker marks which one is in
            // force — and two places saying it is the only way the mark can lie.
            child: FlutterStateful(
              node: ExamplePageNode(seed: _seed),
              theme: ExamplePalette.themeFor(_seed),
              // The presses are answered by the node that owns the callbacks, once.
              presses: widget.presses,
            ),
          ),
        ),
      ),
    );
  }
}
