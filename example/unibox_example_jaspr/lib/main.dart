import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_jaspr/unibox_jaspr.dart';

/// The Jaspr host of the shared page.
///
/// The page is one node — [ExamplePageNode] — so this file is only what a server
/// needs to know about it: which state the document starts in. [JasprStateful]
/// draws the store's first state and, once the client build exists, subscribes to
/// the same store in a browser.
///
/// [initialForm] and [openSignup] are for the static export: a document has no
/// click to open the dialog, so `bin/build_site.dart` renders the state the document
/// should start in.
class ExampleApp extends JasprStateful {
  /// Creates the example application.
  const ExampleApp({
    this.initialForm = const SignupFormState(),
    this.openSignup = false,
    super.key,
  });

  /// The values the form starts with.
  final SignupFormState initialForm;

  /// Whether the first render has the sign-up dialog open.
  final bool openSignup;

  @override
  core.StatefulNode<Object, core.Store<Object>> createNode() {
    return ExamplePageNode(initialForm: initialForm, signupOpen: openSignup);
  }
}

/// The body of an example document, and the root the browser renders.
///
/// The two sides build the *same* root on purpose. A server draws it into the HTML
/// and the client runtime draws it into the browser, so the markup the page arrives
/// with and the markup it keeps are the same tree. The theme has to be part of it:
/// the page names colour roles, and a root without the scope would render them
/// unanswered the moment the runtime took over.
Component buildExampleRoot({bool openSignup = false}) {
  return JasprThemeScope(
    theme: ExamplePalette.theme,
    child: ExampleApp(openSignup: openSignup),
  );
}
