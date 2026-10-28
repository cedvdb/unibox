import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

void main() {
  group('SignupFormState', () {
    test('starts empty and incomplete', () {
      const SignupFormState state = SignupFormState();

      expect(state.isDirty, isFalse);
      expect(state.isComplete, isFalse);
      expect(state.newsletter, isFalse);
      expect(state.submitted, isFalse);
    });

    test('is complete once a name and an email address are entered', () {
      const SignupFormState state = SignupFormState(
        name: 'Ada',
        email: 'ada@example.com',
      );

      expect(state.isDirty, isTrue);
      expect(state.isComplete, isTrue);
    });

    test('ignores a whitespace only name', () {
      const SignupFormState state = SignupFormState(
        name: '   ',
        email: 'ada@example.com',
      );

      expect(state.isComplete, isFalse);
    });

    test('copyWith replaces only the given fields', () {
      const SignupFormState state = SignupFormState(
        name: 'Ada',
        email: 'ada@example.com',
        newsletter: true,
      );

      final SignupFormState next = state.copyWith(submitted: true);

      expect(next.name, 'Ada');
      expect(next.email, 'ada@example.com');
      expect(next.newsletter, isTrue);
      expect(next.submitted, isTrue);
    });

    test('submits only once the form is complete', () {
      expect(
        submitSignupForm(const SignupFormState(name: 'Ada')).submitted,
        isFalse,
      );
      expect(
        submitSignupForm(
          const SignupFormState(name: 'Ada', email: 'ada@example.com'),
        ).submitted,
        isTrue,
      );
    });
  });

  group('buildSignupCard', () {
    test('renders a controlled field for the name and the email', () {
      final List<TextInputNode> fields = flatten(
        RecordingHost().card(
          const SignupFormState(name: 'Ada', email: 'ada@example.com'),
        ),
      ).whereType<TextInputNode>().toList();

      expect(fields, hasLength(2));
      expect(fields[0].value, 'Ada');
      expect(fields[0].placeholder, 'Ada Lovelace');
      expect(fields[1].value, 'ada@example.com');
      expect(fields[1].placeholder, 'ada@example.com');
    });

    test('reports typed values to the host', () {
      final RecordingHost host = RecordingHost();
      final List<TextInputNode> fields = flatten(host.card())
          .whereType<TextInputNode>()
          .toList();

      fields[0].onChanged!('Ada');
      fields[1].onChanged!('ada@example.com');

      expect(host.names, <String>['Ada']);
      expect(host.emails, <String>['ada@example.com']);
    });

    test('submits when enter is pressed in a field', () {
      final RecordingHost host = RecordingHost();
      final List<TextInputNode> fields = flatten(host.card())
          .whereType<TextInputNode>()
          .toList();

      fields[1].onSubmitted!('ada@example.com');

      expect(host.submissions, 1);
    });

    test('submits when the button is tapped', () {
      final RecordingHost host = RecordingHost();

      boxAround(
        host.card(const SignupFormState(name: 'Ada', email: 'ada@example.com')),
        'Create account',
      ).onTap!();

      expect(host.submissions, 1);
    });

    test('toggles the newsletter opt-in', () {
      final RecordingHost host = RecordingHost();

      boxAround(host.card(), 'Release notes').onTap!();

      expect(host.newsletterToggles, 1);
    });

    test('colors the checkbox and checks it when the opt-in is on', () {
      final Box checkbox = flatten(
        RecordingHost().card(const SignupFormState(newsletter: true)),
      ).whereType<Box>().firstWhere((Box box) => box.width == 24);

      expect(checkbox.backgroundColor, ExamplePalette.accent);
      expect(checkbox.border?.color, ExamplePalette.accent);
      expect(textsIn(checkbox), <String>['✓']);
    });

    test('leaves the checkbox empty while the opt-in is off', () {
      final Box checkbox = flatten(RecordingHost().card())
          .whereType<Box>()
          .firstWhere((Box box) => box.width == 24);

      expect(checkbox.backgroundColor, ExamplePalette.surface);
      expect(checkbox.children, isEmpty);
    });

    test('shows no hint before the form is touched', () {
      expect(
        textsIn(RecordingHost().card()),
        isNot(contains('Add a name and an email address.')),
      );
    });

    test('asks for the missing value while the form is incomplete', () {
      final Box card = RecordingHost().card(const SignupFormState(name: 'Ada'));

      expect(textsIn(card), contains('Add a name and an email address.'));
    });

    test('confirms that a complete form can be submitted', () {
      final Box card = RecordingHost().card(
        const SignupFormState(name: 'Ada', email: 'ada@example.com'),
      );

      expect(textsIn(card), contains('Looks good - press Create account.'));
    });

    test('replaces the hint with a confirmation after submitting', () {
      final Box card = RecordingHost().card(
        const SignupFormState(
          name: 'Ada',
          email: 'ada@example.com',
          submitted: true,
        ),
      );

      final List<String> texts = textsIn(card);

      expect(texts, contains('Thanks, Ada! We will write to ada@example.com.'));
      expect(texts, isNot(contains('Looks good - press Create account.')));
    });

    test('links to the documentation in a new tab', () {
      final LinkNode link = flatten(RecordingHost().card())
          .whereType<LinkNode>()
          .firstWhere((LinkNode node) => node.newTab);

      expect(link.url, 'https://unibox.dev');
      expect(link.newTab, isTrue);
      expect(textsIn(link), <String>['Read the docs']);
    });

    test('offers a way back to the listings', () {
      // A static page cannot dismiss a dialog with a tap, so the way out is a link
      // to the document the dialog covers; the dismissal rides on the same link for
      // a page that has the runtime.
      final LinkNode close = flatten(RecordingHost().card())
          .whereType<LinkNode>()
          .firstWhere((LinkNode node) => !node.newTab);

      expect(close.url, ExampleRoutes.listings);
      expect(textsIn(close), <String>['Close']);
      expect(close.onTap, isNotNull);
    });

    test('layers the avatar chip over the banner', () {
      final StackNode stack = flatten(RecordingHost().card())
          .whereType<StackNode>()
          .single;

      expect(stack.children, hasLength(2));
      expect(stack.children.first, isA<Box>());
      expect((stack.children.last as PositionedNode).child, isA<Box>());
    });
  });

  group('buildSignupDialog', () {
    test('wraps the card in an overlay that can be dismissed', () {
      final OverlayNode dialog = RecordingHost().dialog();

      expect(dialog.children.single, isA<Box>());
      expect(dialog.onDismiss, isNotNull);
      expect(textsIn(dialog), contains('Join Unibox'));
    });

    test('shows the values the host describes', () {
      final OverlayNode dialog = RecordingHost().dialog(
        const SignupFormState(name: 'Ada'),
      );

      expect(flatten(dialog).whereType<TextInputNode>().first.value, 'Ada');
    });
  });
}
