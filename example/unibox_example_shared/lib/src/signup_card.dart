import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

import 'page.dart';
import 'theme.dart';

/// The values entered in the signup card.
///
/// Plain data, kept by the example's store: the card holds no state, and a host
/// never sees these values except inside `ExampleState`.
final class SignupFormState {
  /// Creates the state of the form.
  const SignupFormState({
    this.name = '',
    this.email = '',
    this.newsletter = false,
    this.submitted = false,
  });

  /// The entered name.
  final String name;

  /// The entered email address.
  final String email;

  /// Whether the newsletter checkbox is on.
  final bool newsletter;

  /// Whether the form has been submitted.
  final bool submitted;

  /// Whether the form has been touched at all.
  bool get isDirty => name.isNotEmpty || email.isNotEmpty;

  /// Whether the entered values can be submitted.
  bool get isComplete => name.trim().isNotEmpty && email.contains('@');

  /// Returns a copy of this state with the given fields replaced.
  SignupFormState copyWith({
    String? name,
    String? email,
    bool? newsletter,
    bool? submitted,
  }) {
    return SignupFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      newsletter: newsletter ?? this.newsletter,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SignupFormState &&
        other.name == name &&
        other.email == email &&
        other.newsletter == newsletter &&
        other.submitted == submitted;
  }

  /// Two states with equal values hash alike.
  ///
  /// The store skips a rebuild when a publish is equal to the current state, so
  /// typing a character and deleting it again costs nothing.
  @override
  int get hashCode => Object.hash(name, email, newsletter, submitted);

  @override
  String toString() {
    return 'SignupFormState(name: $name, email: $email, '
        'newsletter: $newsletter, submitted: $submitted)';
  }
}

/// Applies a submission to [state].
///
/// Both hosts use this so the rule lives next to the card instead of being
/// repeated in the two applications: nothing happens until the entered values
/// are [SignupFormState.isComplete].
SignupFormState submitSignupForm(SignupFormState state) {
  return state.isComplete ? state.copyWith(submitted: true) : state;
}

/// Builds the sign-up card as the dialog the frame shows over the page.
///
/// Presence is the host's: it builds this node while the form is open and leaves
/// it out when the form is closed. The node states the policy — `Escape` and a
/// press on the barrier dismiss — and each renderer presents it: a modal in
/// Flutter, a fixed layer on the web.
OverlayNode buildSignupDialog({
  required SignupFormState state,
  required TextChangedCallback onNameChanged,
  required TextChangedCallback onEmailChanged,
  required TapCallback onNewsletterToggled,
  required TapCallback onSubmit,
  required TapCallback onDismiss,
}) {
  return OverlayNode(
    onDismiss: onDismiss,
    child: buildSignupCard(
      state: state,
      onNameChanged: onNameChanged,
      onEmailChanged: onEmailChanged,
      onNewsletterToggled: onNewsletterToggled,
      onSubmit: onSubmit,
      onDismiss: onDismiss,
    ),
  );
}

/// Builds the interactive signup card.
///
/// The card holds no state of its own and knows nothing about Flutter or the
/// DOM: the host owns a [SignupFormState] and feeds the new values back through
/// the callbacks, which is what keeps the two renderers interchangeable.
Box buildSignupCard({
  required SignupFormState state,
  required TextChangedCallback onNameChanged,
  required TextChangedCallback onEmailChanged,
  required TapCallback onNewsletterToggled,
  required TapCallback onSubmit,
  required TapCallback onDismiss,
}) {
  final UINode? status = _status(state);
  // The two rules the form states, in one place: the field looks wrong and the
  // message under it says why, and both follow a keystroke because both are read
  // from the state the store just replaced.
  final bool noName = state.isDirty && state.name.trim().isEmpty;
  final bool noEmail = state.isDirty && !state.email.contains('@');

  return Box(
    direction: Axis.vertical,
    gap: 16,
    width: 380,
    // The card is a self contained composition, which is what an `<article>` is:
    // it makes sense on its own, next to anything else on the page.
    semantics: const BoxSemantics(element: BoxElement.article),
    textStyle: ExampleType.body,
    padding: const BoxSpacing.all(24),
    backgroundColor: const BoxColor.role(ExampleColor.panel),
    borderRadius: 16,
    border: const BoxBorder(color: ExamplePalette.border),
    // The dialog's own elevation, not a shadow written here: a surface that is raised
    // by hand is the fourth shadow in a page that has three, and the one that drifts.
    shadow: MaterialDialog.elevation,
    children: <UINode>[
      _banner(),
      _closeRow(onDismiss),
      _heading(),
      _field(
        TextInputNode(
          // A key per field, so the input keeps its state when a message row appears
          // above or below it.
          key: 'name',
          value: state.name,
          placeholder: 'Ada Lovelace',
          required: true,
          // The tree does not validate: the host does, and rebuilds with the flag.
          invalid: noName,
          description: 'The name we should greet you by.',
          onChanged: onNameChanged,
          onSubmitted: (_) => onSubmit(),
        ),
        error: noName ? 'A name is required.' : null,
      ),
      _field(
        TextInputNode(
          key: 'email',
          value: state.email,
          placeholder: 'ada@example.com',
          required: true,
          invalid: noEmail,
          description: 'We only use it to send the release notes.',
          onChanged: onEmailChanged,
          onSubmitted: (_) => onSubmit(),
        ),
        error: noEmail ? 'Enter an address with an @.' : null,
      ),
      _newsletterRow(state, onNewsletterToggled),
      _footer(state, onSubmit),
      ?status,
    ],
  );
}

/// The way out for a reader on a static page: a link back to the listings.
///
/// The link goes to the document the dialog covers, so a page without a runtime still
/// has a way out; with one, the same press dismisses the dialog in place and the
/// document is not loaded as well.
UINode _closeRow(TapCallback onDismiss) {
  return Box(
    direction: Axis.horizontal,
    mainAlign: MainAlign.end,
    children: <UINode>[
      LinkNode(
        ExampleRoutes.listings,
        onTap: onDismiss,
        child: Box(
          padding: const BoxSpacing.symmetric(horizontal: 12, vertical: 6),
          borderRadius: 8,
          semantics: const BoxSemantics(role: BoxRole.button, label: 'Close'),
          stateStyles: const <BoxState, BoxStyle>{
            BoxState.hover: BoxStyle(
              backgroundColor: ExamplePalette.accentSurface,
            ),
          },
          children: const <UINode>[TextNode('Close', style: ExampleType.nav)],
        ),
      ),
    ],
  );
}

/// A text field of the form, with the message under it when it is wrong.
///
/// The node only says what the field is for, so the box around it says what the
/// field looks like: both renderers keep the platform field free of its own
/// chrome — no Material underline, no browser border and padding — which makes
/// this box the only thing that draws a field, on either target.
///
/// [error] is the host's answer about the value, and drawing it here is what makes
/// an invalid field *look* invalid: the border and the message turn to
/// [ExamplePalette.danger] the moment the state says so, and the row appears and
/// disappears with it, so a keystroke that fixes the address takes the message away.
UINode _field(TextInputNode node, {String? error}) {
  // The wrapper is always there, with the message row as its second child or not
  // at all: a tree whose shape changed when an error appeared would replace the
  // input and lose the caret with it.
  return Box(
    width: double.infinity,
    gap: 4,
    children: <UINode>[
      Box(
        width: double.infinity,
        padding: const BoxSpacing.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: ExamplePalette.panel,
        borderRadius: 10,
        border: BoxBorder(
          color: error == null ? ExamplePalette.border : ExamplePalette.danger,
        ),
        children: <UINode>[node],
      ),
      if (error != null)
        Box(
          padding: const BoxSpacing.only(left: 2),
          children: <UINode>[
            TextNode(
              error,
              style: const BoxTextStyle(
                fontSize: 12,
                color: ExamplePalette.danger,
              ),
            ),
          ],
        ),
    ],
  );
}

/// The header: a colored banner with the avatar chip sitting on its lower edge.
///
/// The stack is what layers the two: the banner is a regular child, the avatar
/// is positioned inside the same area.
UINode _banner() {
  return StackNode(
    width: double.infinity,
    height: 88,
    children: <UINode>[
      Box(
        width: double.infinity,
        height: 88,
        backgroundColor: ExamplePalette.accent,
        borderRadius: 12,
      ),
      PositionedNode(left: 16, bottom: 8, child: _avatarChip()),
    ],
  );
}

/// The initials of the member, layered over the banner.
UINode _avatarChip() {
  return Box(
    direction: Axis.horizontal,
    mainAlign: MainAlign.center,
    crossAlign: CrossAlign.center,
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: ExamplePalette.panel,
    border: const BoxBorder(width: 4, color: ExamplePalette.accent),
    textStyle: const BoxTextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: ExamplePalette.accent,
    ),
    children: <UINode>[const TextNode('AL')],
  );
}

/// The title above the fields.
///
/// The heading sets the title typography and the subtitle overrides the one
/// token it changes, which is the whole point of inheritance: no node has to
/// repeat what its box already says.
///
/// The title is a level one heading: the web renders an `<h1>` and Flutter marks
/// the text as a header, which is the outline a crawler and a screen reader build
/// the page from. The line under it stays plain text.
UINode _heading() {
  return const Box(
    direction: Axis.vertical,
    gap: 4,
    textStyle: ExampleType.title,
    children: <UINode>[
      // A level two: the card is a dialog over a page that already has its h1, and
      // one document with two of them has no outline a crawler can follow.
      TextNode('Join Unibox', headingLevel: 2),
      TextNode('One description, two renderers.', style: ExampleType.muted),
    ],
  );
}

/// The newsletter opt-in, a tappable row with a hand drawn checkbox.
///
/// The checkbox is drawn out of boxes, so before `semantics` a screen reader
/// only found a label. The role and the checked state make it a checkbox for
/// assistive technologies, and the role also puts it in the tab order.
UINode _newsletterRow(SignupFormState state, TapCallback onToggle) {
  return Box(
    direction: Axis.horizontal,
    gap: 12,
    crossAlign: CrossAlign.center,
    onTap: onToggle,
    semantics: BoxSemantics(
      role: BoxRole.checkbox,
      label: 'Release notes',
      checked: state.newsletter,
    ),
    children: <UINode>[
      Box(
        direction: Axis.horizontal,
        mainAlign: MainAlign.center,
        crossAlign: CrossAlign.center,
        width: 24,
        height: 24,
        borderRadius: 6,
        backgroundColor: state.newsletter
            ? ExamplePalette.accent
            : ExamplePalette.panel,
        border: BoxBorder(
          width: 2,
          color: state.newsletter
              ? ExamplePalette.accent
              : ExamplePalette.border,
        ),
        children: <UINode>[
          if (state.newsletter)
            const TextNode(
              '✓',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ExamplePalette.panel,
            ),
        ],
      ),
      const TextNode('Release notes'),
    ],
  );
}

/// The action area: a full width submit button and the docs link below it.
///
/// The button is a hand drawn control, so its state lives in the node: `enabled`
/// decides whether it reacts, `stateStyles` describes how it looks in every
/// state and `semantics` makes it a real button for a keyboard and a screen
/// reader. Nothing here needs a second code path per target.
UINode _footer(SignupFormState state, TapCallback onSubmit) {
  return Box(
    direction: Axis.vertical,
    width: double.infinity,
    gap: 12,
    children: <UINode>[
      Box(
        onTap: onSubmit,
        enabled: state.isComplete,
        direction: Axis.horizontal,
        mainAlign: MainAlign.center,
        width: double.infinity,
        padding: const BoxSpacing.symmetric(horizontal: 18, vertical: 12),
        borderRadius: 10,
        backgroundColor: ExamplePalette.accent,
        textStyle: ExampleType.button,
        transition: ExampleType.transition,
        stateStyles: const <BoxState, BoxStyle>{
          BoxState.hover: BoxStyle(backgroundColor: ExamplePalette.accentHover),
          // Pressed, the button gives a little: the scale is painted, so nothing
          // around it moves and the label does not reflow.
          BoxState.pressed: BoxStyle(
            backgroundColor: ExamplePalette.accentPressed,
            transform: BoxTransform(scale: 0.98),
          ),
          BoxState.focus: BoxStyle(
            border: BoxBorder(color: ExamplePalette.text),
          ),
          BoxState.disabled: BoxStyle(
            backgroundColor: ExamplePalette.border,
            textStyle: BoxTextStyle(color: ExamplePalette.muted),
          ),
        },
        semantics: BoxSemantics(role: BoxRole.button, label: 'Create account'),
        children: <UINode>[const TextNode('Create account')],
      ),
      const Box(
        direction: Axis.horizontal,
        mainAlign: MainAlign.center,
        textStyle: ExampleType.link,
        children: <UINode>[
          LinkNode(
            'https://unibox.dev',
            newTab: true,
            child: TextNode('Read the docs'),
          ),
        ],
      ),
    ],
  );
}

/// The line under the button: either a hint or the confirmation.
UINode? _status(SignupFormState state) {
  if (state.submitted) {
    return Box(
      padding: const BoxSpacing.all(12),
      backgroundColor: ExamplePalette.successSurface,
      borderRadius: 10,
      // A live region, so a screen reader announces the confirmation when it
      // appears instead of leaving the reader to go looking for it.
      semantics: const BoxSemantics(liveRegion: true),
      textStyle: const BoxTextStyle(
        fontSize: 13,
        color: ExamplePalette.success,
      ),
      children: <UINode>[
        TextNode(
          'Thanks, ${state.name.trim()}! '
          'We will write to ${state.email.trim()}.',
        ),
      ],
    );
  }
  if (!state.isDirty) {
    return null;
  }
  return TextNode(
    state.isComplete
        ? 'Looks good - press Create account.'
        : 'Add a name and an email address.',
    style: ExampleType.muted,
  );
}
