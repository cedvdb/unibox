import 'package:unibox_core/unibox_core.dart';

import 'apartments.dart';
import 'page.dart';
import 'page_state.dart';
import 'pricing.dart';
import 'signup_card.dart';

/// The example as one node: the bar, the listings and the sign-up dialog, drawn
/// from [ExampleState].
///
/// This is the whole application. A host renders it through the stateful renderer
/// of its target (`FlutterStateful` and `JasprStateful`) and supplies only what a
/// node cannot know — the surface and how a link opens — which is why each host of
/// the example is one small file.
final class ExamplePageNode extends StatefulNode<ExampleState, ExampleStore> {
  /// Creates the page, starting with [initialForm] and with the dialog open when
  /// [signupOpen] is set.
  ///
  /// [signupOpen] is for a static export: a document has no click to open the
  /// dialog, so it is rendered in the state it should start in.
  ///
  factory ExamplePageNode({
    SignupFormState initialForm = const SignupFormState(),
    bool signupOpen = false,
    ExamplePage initialPage = ExamplePage.apartments,
    Object? key,
  }) {
    return ExamplePageNode._(
      key: key,
      create: () => ExampleStore(
        initial: initialForm,
        openSignup: signupOpen,
        page: initialPage,
      ),
      view: (ExampleState state, ExampleStore store) =>
          exampleView(state: state, store: store),
    );
  }

  ExamplePageNode._({required super.create, required super.view, super.key});
}

/// Draws [state], with [store] for the callbacks the tree hands out.
///
/// The dialog is part of the tree only while it is open: a closed dialog is
/// simply absent, so the renderer sees an ordinary page and no overlay at all.
UINode exampleView({required ExampleState state, required ExampleStore store}) {
  return buildExamplePage(
    current: state.page,
    onNavigate: store.navigate,
    page: switch (state.page) {
      // The pricing page is the marketing shape this library exists for: written
      // once, exported as HTML and CSS, and the same tree in the app.
      ExamplePage.pricing => buildPricingPage(
        onStart: store.openSignup,
        onNavigate: store.navigate,
      ),
      ExamplePage.apartments || ExamplePage.signup => buildApartmentsPage(
        filter: state.filter,
        view: state.view,
        onFilter: store.chooseFilter,
        onView: store.showListings,
      ),
    },
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
