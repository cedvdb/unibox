import 'package:unibox_core/unibox_core.dart';

import 'page.dart';
import 'signup_card.dart';

/// The state of the example page: the form and whether its dialog is open.
///
/// One value, because one node draws both: the bar, the listings and the dialog
/// are the same tree, and this object is the only thing that changes between two
/// renderings of it.
final class ExampleState {
  /// Creates a state with [form] and the dialog closed unless [signupOpen].
  const ExampleState({
    this.form = const SignupFormState(),
    this.signupOpen = false,
    this.mapOpen = false,
  });

  /// The values of the sign-up form.
  final SignupFormState form;

  /// Whether the sign-up dialog is open.
  final bool signupOpen;

  /// Whether the map is open as a view of its own.
  ///
  /// It only matters on a narrow surface: from 900 logical pixels the map is drawn
  /// beside the listings, and the toggle that opens it is not drawn at all.
  final bool mapOpen;

  /// The destination the bar highlights.
  ///
  /// The sign-up form is not a page, so it is the current destination while its
  /// dialog is open, and the listings are current otherwise.
  ExamplePage get current =>
      signupOpen ? ExamplePage.signup : ExamplePage.apartments;

  /// Returns a copy of this state with the given fields replaced.
  ExampleState copyWith({
    SignupFormState? form,
    bool? signupOpen,
    bool? mapOpen,
  }) {
    return ExampleState(
      form: form ?? this.form,
      signupOpen: signupOpen ?? this.signupOpen,
      mapOpen: mapOpen ?? this.mapOpen,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExampleState &&
        other.form == form &&
        other.signupOpen == signupOpen;
  }

  /// Two states with equal values hash alike, which is what lets the store skip
  /// a rebuild that would draw the same tree again.
  @override
  int get hashCode => Object.hash(form, signupOpen, mapOpen);

  @override
  String toString() =>
      'ExampleState(form: $form, signupOpen: $signupOpen, mapOpen: $mapOpen)';
}

/// The store of `ExamplePageNode`: every interaction of the page as one
/// assignment.
///
/// The page owns its own state, so a host has nothing to wire: the bar reports a
/// destination, the fields report a value and the dialog reports a dismissal, and
/// all of them publish [ExampleState]. A renderer subscribes to the store and
/// draws the view again.
final class ExampleStore extends StateStore<ExampleState> {
  /// Creates a store starting with [initial] and the dialog open when
  /// [openSignup] is set.
  ///
  /// [openSignup] exists for a static export: a document has no click to open the
  /// dialog, so it is rendered in the state it should start in.
  ExampleStore({
    SignupFormState initial = const SignupFormState(),
    bool openSignup = false,
  }) : super(ExampleState(form: initial, signupOpen: openSignup));

  /// Replaces the name and clears a previous confirmation.
  void setName(String name) =>
      _setForm(state.form.copyWith(name: name, submitted: false));

  /// Replaces the email address and clears a previous confirmation.
  void setEmail(String email) =>
      _setForm(state.form.copyWith(email: email, submitted: false));

  /// Turns the newsletter opt-in on or off.
  void toggleNewsletter() =>
      _setForm(state.form.copyWith(newsletter: !state.form.newsletter));

  /// Confirms the form, when the entered values allow it.
  void submit() => _setForm(submitSignupForm(state.form));

  /// Closes the sign-up dialog.
  void closeSignup() => state = state.copyWith(signupOpen: false);

  /// Opens the map as a view of its own, which is what a narrow surface offers.
  void openMap() => state = state.copyWith(mapOpen: true);

  /// Closes the map view.
  void closeMap() => state = state.copyWith(mapOpen: false);

  /// Follows a destination of the bar.
  ///
  /// The sign-up form is a dialog and the listings are the page, so a destination
  /// decides what is open rather than which page is drawn.
  void navigate(ExamplePage page) =>
      state = state.copyWith(signupOpen: page == ExamplePage.signup);

  void _setForm(SignupFormState form) => state = state.copyWith(form: form);
}
