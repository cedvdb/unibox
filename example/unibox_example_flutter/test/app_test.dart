import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// Fills both fields with a valid name and email address.
Future<void> fillForm(WidgetTester tester) async {
  await tester.enterText(nameField(), 'Ada');
  await tester.enterText(emailField(), 'ada@example.com');
  await tester.pump();
}

void main() {
  group('ExampleApp', () {
    testWidgets('renders the shared page with the dialog closed', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('Via Bellavista 12'), findsOneWidget);
      expect(find.text('Join Unibox'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens the sign-up dialog from the bar', (tester) async {
      await pumpApp(tester);

      await openPage(tester, 'Sign up');

      expect(find.text('Join Unibox'), findsOneWidget);
      expect(find.text('One description, two renderers.'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Read the docs'), findsOneWidget);
    });

    testWidgets('closes the dialog when the barrier is pressed', (
      tester,
    ) async {
      await pumpApp(tester);
      await openPage(tester, 'Sign up');

      // The top left corner is the barrier: the card is centred in the window.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      expect(find.text('Join Unibox'), findsNothing);
      expect(find.text('Via Bellavista 12'), findsOneWidget);
    });

    testWidgets('fills the surface the window gives it', (tester) async {
      // The page box of the tree fills the viewport on the web, so the Flutter
      // box fills the window instead of shrinking to the card: same tree, same
      // surface, on both targets.
      await pumpApp(tester);

      final Rect page = tester.getRect(find.byType(FlutterBox).first);

      expect(
        page,
        Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio,
      );
    });

    testWidgets('keeps the entered values and reports the form as complete', (
      tester,
    ) async {
      await pumpApp(tester);
      await openPage(tester, 'Sign up');

      await fillForm(tester);

      expect(tester.widget<TextField>(nameField()).controller!.text, 'Ada');
      expect(
        tester.widget<TextField>(emailField()).controller!.text,
        'ada@example.com',
      );
      expect(find.text('Looks good - press Create account.'), findsOneWidget);
    });

    testWidgets('starts on the pricing page when the route says so', (
      tester,
    ) async {
      await pumpApp(tester, page: ExamplePage.pricing);

      // The route is the page: the same document the web export writes, drawn by
      // the app instead of by the server.
      expect(find.text('What it costs'), findsOneWidget);
      expect(find.text('Solo'), findsOneWidget);
      // `Apartments` is also a destination in the bar, so the check is that the
      // listings content is gone rather than that the word is.
      expect(find.textContaining('old town'), findsNothing);
    });

    testWidgets('shows the confirmation after submitting', (tester) async {
      await pumpApp(tester);
      await openPage(tester, 'Sign up');
      await fillForm(tester);

      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(
        find.text('Thanks, Ada! We will write to ada@example.com.'),
        findsOneWidget,
      );
    });

    testWidgets('ignores a submission while the form is incomplete', (
      tester,
    ) async {
      await pumpApp(tester);
      await openPage(tester, 'Sign up');

      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.textContaining('Thanks, '), findsNothing);
      expect(find.text('Add a name and an email address.'), findsNothing);
    });

    testWidgets('submits when enter is pressed in the email field', (
      tester,
    ) async {
      await pumpApp(tester);
      await openPage(tester, 'Sign up');
      await fillForm(tester);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        find.text('Thanks, Ada! We will write to ada@example.com.'),
        findsOneWidget,
      );
    });

    testWidgets('toggles the newsletter opt-in', (tester) async {
      await pumpApp(tester);
      await openPage(tester, 'Sign up');

      expect(find.text('✓'), findsNothing);

      await tester.tap(find.text('Release notes'));
      await tester.pump();

      expect(find.text('✓'), findsOneWidget);

      await tester.tap(find.text('Release notes'));
      await tester.pump();

      expect(find.text('✓'), findsNothing);
    });

    group('navigation', () {
      testWidgets('dismisses the dialog onto the listings', (tester) async {
        await pumpApp(tester);
        await openPage(tester, 'Sign up');

        await closeDialog(tester);

        expect(find.text('Join Unibox'), findsNothing);
        expect(find.text('Via Bellavista 12'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('comes back to the card with the form intact', (
        tester,
      ) async {
        await pumpApp(tester);
        await openPage(tester, 'Sign up');
        await fillForm(tester);

        await closeDialog(tester);
        await openPage(tester, 'Sign up');

        expect(find.text('Join Unibox'), findsOneWidget);
        expect(tester.widget<TextField>(nameField()).controller!.text, 'Ada');
        expect(find.text('Looks good - press Create account.'), findsOneWidget);
      });

      testWidgets('keeps the listings readable on a small surface', (
        tester,
      ) async {
        // The card is a row whose text column takes what is left, so the name, the
        // summary and the rent wrap inside the card instead of widening it.
        await pumpApp(tester, surface: const Size(500, 800));

        expect(tester.takeException(), isNull);
        expect(find.text('Via Bellavista 12'), findsOneWidget);
        expect(find.text('€1850'), findsOneWidget);

        final Rect card = tester.getRect(
          find
              .ancestor(
                of: find.text('Via Bellavista 12'),
                matching: find.byType(FlutterBox),
              )
              .last,
        );
        expect(card.width, lessThanOrEqualTo(500));
      });

      testWidgets('scrolls the listings under the navigation', (tester) async {
        // Short enough that the six listings do not fit, which is the case the
        // scroll view exists for.
        await pumpApp(tester, surface: const Size(900, 700));

        final double bar = tester.getTopLeft(find.text('Unibox')).dy;
        final double before = tester
            .getTopLeft(find.text('Via Bellavista 12'))
            .dy;

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -200),
        );
        await tester.pump();

        expect(
          tester.getTopLeft(find.text('Via Bellavista 12')).dy,
          lessThan(before),
        );
        // The navigation belongs to the frame, not to the page that scrolls.
        expect(tester.getTopLeft(find.text('Unibox')).dy, bar);
      });
    });
  });
}
