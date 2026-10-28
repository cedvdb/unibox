/// The Unibox example, as one page component.
///
/// [ExamplePageNode] is the whole application: a [StatefulNode] whose store holds
/// the form and whether the sign-up dialog is open, and whose view draws the
/// navigation bar, the listings and the dialog. The tree is plain Dart, so the
/// same node renders as Flutter widgets in `unibox_example_flutter` and as
/// HTML/CSS in `unibox_example_jaspr`.
///
/// The host is what a node cannot be: a surface and the way a link opens. Each
/// host of the example is one small file for exactly that reason.
library;

export 'src/apartments.dart';
export 'src/page_node.dart';
export 'src/page.dart';
export 'src/page_state.dart';
export 'src/signup_card.dart';
export 'src/site/gallery.dart';
export 'src/site/landing.dart';
export 'src/site/showcase.dart';
export 'src/site/site_page.dart';
export 'src/theme.dart';
