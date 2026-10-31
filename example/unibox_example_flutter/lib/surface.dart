import 'package:flutter/material.dart';
import 'package:unibox_core/unibox_core.dart' show BoxColorScheme, UniboxTheme;

/// The family both hosts ship: `assets/fonts` in this app, the same files in
/// `assets/fonts` of the site.
const String fontFamily = 'UniboxText';

/// The surface a host draws its tree on: the family, the scheme the theme states, and no
/// debug banner.
///
/// Both trees this build draws — the example and the site page — need the same four
/// decisions, and they have to agree: the page is drawn twice, by two renderers, and the
/// whole point of it is that the two renderings look like one page. A host that wrote its
/// own `MaterialApp` would be free to disagree about the font, which is the one token the
/// model leaves to the application.
Widget surface({
  required String title,
  required UniboxTheme theme,
  required Widget child,
}) {
  return MaterialApp(
    title: title,
    // The scheme is not guessed from the phone: the theme the tree is drawn with has already
    // said which one it is, and `ThemeData` is told the same fact. Without it the parts
    // Material still draws for us — the caret, the selection, a field's scrollbars — would
    // follow the system while the page around them stayed light.
    theme: ThemeData(
      fontFamily: fontFamily,
      brightness: theme.colorScheme == BoxColorScheme.dark
          ? Brightness.dark
          : Brightness.light,
    ),
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: child),
  );
}
