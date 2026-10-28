import 'package:unibox_core/unibox_core.dart';

import 'apartments.dart';
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
    this.page = ExamplePage.apartments,
    this.filter = defaultFilter,
    this.view = ListingsView.grid,
  });

  /// The filter the listings start with, and the one a cleared row goes back to.
  static const String defaultFilter = defaultListingFilter;

  /// The values of the sign-up form.
  final SignupFormState form;

  /// Whether the sign-up dialog is open.
  final bool signupOpen;

  /// The filter the listing chips have chosen, or `null` for no filter.
  final String? filter;

  /// How the listings are drawn: one column, or a grid.
  final ListingsView view;

  /// Whether the map is open as a view of its own.
  ///
  /// It only matters on a narrow surface: from 900 logical pixels the map is drawn
  /// beside the listings, and the toggle that opens it is not drawn at all.
  final bool mapOpen;

  /// The page below the bar, which is the destination the bar highlights.
  ///
  /// The sign-up form is not a page: it is a dialog over whichever page this is, so it
  /// is never the value here — opening it changes [signupOpen] and leaves the page
  /// underneath highlighted, which is what the reader is still looking at.
  final ExamplePage page;

  /// Returns a copy of this state with the given fields replaced.
  ExampleState copyWith({
    SignupFormState? form,
    bool? signupOpen,
    bool? mapOpen,
    ExamplePage? page,
    Object? filter = _unchanged,
    ListingsView? view,
  }) {
    return ExampleState(
      form: form ?? this.form,
      signupOpen: signupOpen ?? this.signupOpen,
      mapOpen: mapOpen ?? this.mapOpen,
      page: page ?? this.page,
      // A filter is cleared by passing `null`, which is a value and not "unchanged".
      filter: identical(filter, _unchanged) ? this.filter : filter as String?,
      view: view ?? this.view,
    );
  }

  /// The marker that tells [copyWith] "leave this token alone".
  static const Object _unchanged = Object();

  @override
  bool operator ==(Object other) {
    // Every field, because the store skips a publish whose state equals the last
    // one: a field left out of this comparison is a change that draws nothing.
    return other is ExampleState &&
        other.form == form &&
        other.signupOpen == signupOpen &&
        other.mapOpen == mapOpen &&
        other.page == page &&
        other.filter == filter &&
        other.view == view;
  }

  /// Two states with equal values hash alike, which is what lets the store skip
  /// a rebuild that would draw the same tree again.
  @override
  int get hashCode =>
      Object.hash(form, signupOpen, mapOpen, page, filter, view);

  @override
  String toString() =>
      'ExampleState(form: $form, signupOpen: $signupOpen, mapOpen: $mapOpen, '
      'page: $page, filter: $filter, view: $view)';
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
    ExamplePage page = ExamplePage.apartments,
  }) : super(ExampleState(form: initial, signupOpen: openSignup, page: page));

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

  /// Opens the sign-up dialog over the page it is on, which is what a call to
  /// action on the pricing page does.
  void openSignup() => state = state.copyWith(signupOpen: true);

  /// Closes the sign-up dialog.
  void closeSignup() => state = state.copyWith(signupOpen: false);

  /// Chooses the filter of the listing chips, or clears it with `null`.
  void chooseFilter(String? filter) => state = state.copyWith(filter: filter);

  /// Draws the listings in the layout [view] names.
  void showListings(ListingsView view) => state = state.copyWith(view: view);

  /// Opens the map as a view of its own, which is what a narrow surface offers.
  void openMap() => state = state.copyWith(mapOpen: true);

  /// Closes the map view.
  void closeMap() => state = state.copyWith(mapOpen: false);

  /// Follows a destination of the bar.
  ///
  /// The sign-up form is a dialog rather than a page, so choosing it opens the
  /// dialog over whatever page is drawn; every other destination is a page, and
  /// choosing one closes the dialog first.
  void navigate(ExamplePage destination) {
    state = destination == ExamplePage.signup
        ? state.copyWith(signupOpen: true)
        : state.copyWith(page: destination, signupOpen: false);
  }

  void _setForm(SignupFormState form) => state = state.copyWith(form: form);
}
