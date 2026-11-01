import 'package:flutter/material.dart';
import 'package:unibox_core/unibox_core.dart'
    show BoxColorScheme, UniboxScope, UniboxTheme;

/// The family both hosts ship: `assets/fonts` in this app, the same files in
/// `assets/fonts` of the site.
const String fontFamily = 'UniboxText';

/// The surface a host draws its tree on: the family, the scheme the theme states, no debug
/// banner — and one physics for every scroller in the tree.
///
/// Both trees this build draws — the example and the site page — need the same decisions, and
/// they have to agree: the page is drawn twice, by two renderers, and the whole point of it is
/// that the two renderings look like one page. A host that wrote its own `MaterialApp` would be
/// free to disagree about the font, which is the one token the model leaves to the application.
///
/// **The pull past an end is the second of those decisions.** A renderer drops the overscroll
/// *decoration* — Material's glow or stretch is chrome a node never keeps — and leaves the physics
/// to the host, so a box pulled past its end bounces on iOS and macOS, does nothing at all on
/// Android, and never bounces for a wheel or a trackpad. A browser rubber-bands wherever it runs.
/// So a host that wants the same elastic pull on both targets says so here, once: the two frames
/// of the site's comparison are then the same page in the same state, which is what a reader is
/// being asked to judge.
Widget surface({
  required String title,
  required UniboxScope scope,
  required Widget child,
}) {
  final UniboxTheme? theme = scope.theme;

  return MaterialApp(
    title: title,
    // The scheme is not guessed from the phone: the theme the tree is drawn with has already
    // said which one it is, and `ThemeData` is told the same fact. Without it the parts
    // Material still draws for us — the caret, the selection, a field's scrollbars — would
    // follow the system while the page around them stayed light.
    theme: ThemeData(
      fontFamily: fontFamily,
      brightness: theme?.colorScheme == BoxColorScheme.dark
          ? Brightness.dark
          : Brightness.light,
    ),
    debugShowCheckedModeBanner: false,
    home: ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      child: Scaffold(body: child),
    ),
  );
}
