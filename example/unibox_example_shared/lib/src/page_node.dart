import 'package:unibox_core/unibox_core.dart';

import 'apartments.dart';
import 'page.dart';
import 'page_state.dart';
import 'signup_card.dart';
import 'theme.dart';

/// The example as one node: the bar, the listings and the sign-up dialog, drawn
/// from [ExampleState].
///
/// This is the whole application. A host renders it through the stateful renderer
/// of its target (`FlutterStateful` for the app) and supplies only what a
/// node cannot know — the surface and how a link opens — which is why each host of
/// the example is one small file.
final class ExamplePageNode extends StatefulNode<ExampleState, ExampleStore> {
  /// Creates the page, starting with [initialForm] and the dialog closed, and marked
  /// as drawn with [seed].
  ///
  /// [seed] is only what the picker marks as in force: the palette itself is the
  /// theme the host installs, which is why the two must agree and why the host
  /// passes the same value to both.
  factory ExamplePageNode({
    SignupFormState initialForm = const SignupFormState(),
    ExampleSeed seed = ExampleSeed.blue,
    Object? key,
  }) {
    return ExamplePageNode._(
      key: key,
      create: () => ExampleStore(initial: initialForm),
      view: (ExampleState state, ExampleStore store) =>
          exampleView(state: state, store: store, seed: seed),
    );
  }

  ExamplePageNode._({required super.create, required super.view, super.key});
}

/// Draws [state], with [store] for the callbacks the tree hands out.
///
/// The dialog is part of the tree only while it is open: a closed dialog is
/// simply absent, so the renderer sees an ordinary page and no overlay at all.
UINode exampleView({
  required ExampleState state,
  required ExampleStore store,
  ExampleSeed seed = ExampleSeed.blue,
}) {
  return buildExamplePage(
    current: state.current,
    seed: seed,
    onNavigate: store.navigate,
    page: buildApartmentsPage(
      filter: state.filter,
      view: state.view,
      onFilter: store.chooseFilter,
      onView: store.showListings,
    ),
    dialog: state.signupOpen
        ? buildSignupDialog(
            state: state.form,
            onNameChanged: store.setName,
            onEmailChanged: store.setEmail,
            onNewsletterToggled: store.toggleNewsletter,
            onSubmit: store.submit,
            onDismiss: store.closeSignup,
          )
        : null,
  );
}
