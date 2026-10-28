/// The Unibox example.
///
/// [ExamplePageNode] is the application the site compares: a [StatefulNode] whose
/// store holds the form and whether the sign-up dialog is open, and whose view draws
/// the navigation bar, the listings and the dialog. The tree is plain Dart, so the
/// same node renders as Flutter widgets in `unibox_example_flutter` and as HTML/CSS
/// in `unibox_example_jaspr`.
///
/// The site itself is one page — [buildSitePage] — of three bands: the claim, the
/// comparison, and the Material catalogue. Its sections are node trees too, so the
/// site is drawn with the library it documents.
///
/// The host is what a node cannot be: a surface and the way a link opens. Each host
/// of the example is one small file for exactly that reason.
library;

export 'src/apartments.dart';
export 'src/icons.dart';
export 'src/page_node.dart';
export 'src/page.dart';
export 'src/page_state.dart';
export 'src/signup_card.dart';
export 'src/site/gallery.dart';
export 'src/site/hero.dart';
export 'src/site/section.dart';
export 'src/site/showcase.dart';
export 'src/site/site.dart';
export 'src/theme.dart';
