import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_example_jaspr/main.dart';

import 'support/harness.dart';

/// The app as `build/signup.html` renders it: the dialog over the listings.
ExampleApp signupApp({SignupFormState state = const SignupFormState()}) {
  return ExampleApp(initialForm: state, openSignup: true);
}

void main() {
  group('ExampleApp', () {
    testComponents('renders the shared node tree', (tester) async {
      tester.pumpComponent(signupApp());

      expect(find.text('Join Unibox'), findsOneComponent);
      expect(find.text('One description, two renderers.'), findsOneComponent);
      expect(find.tag('input'), findsNComponents(2));
      expect(find.text('Create account'), findsOneComponent);
      expect(find.text('Read the docs'), findsOneComponent);

      final TestRenderElement docs = elementsOf(find.tag('a')).firstWhere(
        (TestRenderElement element) =>
            element.attributes?['target'] == '_blank',
      );

      expect(docs.attributes?['href'], 'https://unibox.dev');
      expect(docs.attributes?['target'], '_blank');
    });

    testComponents('links each destination to its document', (tester) async {
      tester.pumpComponent(signupApp());

      final List<String?> hrefs = elementsOf(find.tag('a'))
          .map((TestRenderElement element) => element.attributes?['href'])
          .toList();

      // A destination is a real anchor, so a page without the client runtime still goes
      // somewhere: the two items of the bar name the document that draws them, the
      // dialog's close control goes back to the listings, and the docs link is external.
      // Nothing links to `../signup/`: an account is a button over the page, not a
      // place to go.
      expect(hrefs, <String?>[
        '../listings/',
        '../pricing/',
        '../listings/',
        'https://unibox.dev',
      ]);
      expect(hrefs, isNot(contains('../signup/')));
    });

    testComponents('fills the viewport', (tester) async {
      tester.pumpComponent(signupApp());

      final Map<String, String> page = stylesOf(find.tag('div').first);

      expect(page['width'], '100%');
      expect(page['height'], '100%');
    });

    testComponents('wires both fields to the host', (tester) async {
      tester.pumpComponent(signupApp());

      final List<TestRenderElement> fields = elementsOf(find.tag('input'));

      expect(fields, hasLength(2));
      for (final TestRenderElement field in fields) {
        expect(field.events?.keys, contains('input'));
      }
      expect(
        attributesOf(find.tag('input').first)['placeholder'],
        'Ada Lovelace',
      );
      expect(
        attributesOf(find.tag('input').last)['placeholder'],
        'ada@example.com',
      );
    });

    testComponents('registers a click listener on the controls of the page', (
      tester,
    ) async {
      tester.pumpComponent(signupApp());

      final List<TestRenderElement> clickable = elementsOf(find.tag('div'))
          .where(
            (TestRenderElement element) =>
                element.events?.containsKey('click') ?? false,
          )
          .toList();

      // The three filters and the cross of the removable one, the two segments of the
      // layout switch, the floating pill at the bottom of the listings, the opt-in row,
      // the dialog's barrier and the sign-up button of the bar; the submit button is
      // disabled until the form is complete, and a disabled box listens to nothing. The
      // destinations of the bar are anchors and the close control is one too, so they are
      // not counted here.
      expect(clickable, hasLength(10));

      // A destination is an anchor instead, because the `href` is what a page
      // without the client runtime follows: the two items of the bar and the way out
      // of the dialog carry the press, and the docs link opens a new tab and needs no
      // listener of its own. The sign-up control is a button of the bar, counted with
      // the boxes above.
      final List<TestRenderElement> links = elementsOf(find.tag('a'))
          .where(
            (TestRenderElement element) =>
                element.events?.containsKey('click') ?? false,
          )
          .toList();

      expect(links, hasLength(3));
      expect(
        links.map((TestRenderElement link) => link.attributes?['href']),
        <String?>['../listings/', '../pricing/', '../listings/'],
      );

      // The bar's sign-up trigger is a button too, and it comes first; the
      // submit button is the last one in the tree.
      final TestRenderElement button = elementsOf(find.tag('div')).lastWhere(
        (TestRenderElement element) => element.attributes?['role'] == 'button',
      );
      expect(button.attributes?['aria-disabled'], 'true');
      expect(button.attributes?.containsKey('tabindex'), isFalse);
    });

    testComponents('enables the button once the form is complete', (
      tester,
    ) async {
      tester.pumpComponent(
        signupApp(
          state: const SignupFormState(name: 'Ada', email: 'ada@example.com'),
        ),
      );

      final List<TestRenderElement> clickable = elementsOf(find.tag('div'))
          .where(
            (TestRenderElement element) =>
                element.events?.containsKey('click') ?? false,
          )
          .toList();

      // The same set, and now the submit button as well.
      expect(clickable, hasLength(11));

      final TestRenderElement button = elementsOf(find.tag('div')).lastWhere(
        (TestRenderElement element) => element.attributes?['role'] == 'button',
      );
      expect(button.attributes?['aria-disabled'], isNull);
      expect(button.attributes?['tabindex'], '0');
      expect(button.events?.keys, contains('keydown'));
    });

    testComponents('checks the opt-in when the newsletter is on', (
      tester,
    ) async {
      tester.pumpComponent(
        signupApp(state: const SignupFormState(newsletter: true)),
      );

      expect(find.text('✓'), findsOneComponent);
    });

    testComponents('renders the confirmation of a submitted form', (
      tester,
    ) async {
      tester.pumpComponent(
        signupApp(
          state: const SignupFormState(
            name: 'Ada',
            email: 'ada@example.com',
            submitted: true,
          ),
        ),
      );

      expect(
        find.text('Thanks, Ada! We will write to ada@example.com.'),
        findsOneComponent,
      );
      expect(find.text('Looks good - press Create account.'), findsNothing);
    });

    testComponents('offers the pages as navigation and the form as a button', (
      tester,
    ) async {
      tester.pumpComponent(signupApp());

      expect(find.text('Sign up'), findsOneComponent);
      // The item and the heading of the page behind the dialog.
      expect(find.text('Apartments'), findsNComponents(2));

      // A destination is a box with the link role and a tab stop, wrapped in the
      // anchor that carries the href and answers the press.
      final TestRenderElement item = elementsOf(find.tag('div')).firstWhere(
        (TestRenderElement element) => element.attributes?['role'] == 'link',
      );

      expect(item.attributes?['tabindex'], '0');

      final TestRenderElement link = elementsOf(find.tag('a')).firstWhere(
        (TestRenderElement element) =>
            element.events?.containsKey('click') ?? false,
      );

      expect(link.attributes?['href'], '../listings/');

      // The sign-up control is a button in the bar rather than a page in it, so it is
      // a box that answers a press and carries no `href` for a crawler to follow.
      final TestRenderElement signup = elementsOf(find.tag('div')).firstWhere(
        (TestRenderElement element) =>
            element.attributes?['role'] == 'button' &&
            (element.events?.containsKey('click') ?? false),
      );

      expect(signup.attributes?['href'], isNull);
    });
  });

  group('apartments page', () {
    testComponents('renders the listings of the shared page', (tester) async {
      tester.pumpComponent(const ExampleApp());

      // The heading and the navigation item carry the same label.
      expect(find.text('Apartments'), findsNComponents(2));
      expect(find.text('Via Bellavista 12'), findsOneComponent);
      expect(find.text('3 rooms · 84 m²'), findsOneComponent);
      expect(find.text('€1850'), findsComponents);
      expect(find.text('Join Unibox'), findsNothing);
    });

    testComponents('scrolls the listings inside the page', (tester) async {
      tester.pumpComponent(const ExampleApp());

      // The page is the `<main>` landmark and takes the room the navigation
      // leaves; the list inside it is what scrolls, under the floating button.
      final Map<String, String> page = stylesOf(find.tag('main'));

      expect(page['flex-grow'], '1');
      expect(
        page['overflow'],
        isNull,
        reason: 'the page itself no longer scrolls: the list inside it does',
      );

      // A look is written once as a class, so the declarations are read through
      // the class each div wears rather than from its inline styles.
      final List<Map<String, String>> scrollable = <Map<String, String>>[];
      final int divs = elementsOf(find.tag('div')).length;

      for (int i = 0; i < divs; i++) {
        final Map<String, String> styles = stylesOf(find.tag('div').at(i));

        if (styles['overflow'] == 'auto') {
          scrollable.add(styles);
        }
      }

      expect(scrollable, hasLength(1));
      expect(scrollable.single['height'], '100%');
    });

    testComponents('shows the listings behind the sign-up dialog', (
      tester,
    ) async {
      // The form is a layer over the page, not a page of its own: the static
      // export of the sign-up document still carries the listings.
      tester.pumpComponent(signupApp());

      expect(find.text('Join Unibox'), findsOneComponent);
      expect(find.text('Via Bellavista 12'), findsOneComponent);
    });
  });
}
