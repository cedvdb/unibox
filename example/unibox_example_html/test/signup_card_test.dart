import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_html/unibox_html.dart';

/// What the sign-up card owes the page it is drawn on.
///
/// The card is the one part of the example that is drawn over everything else, and the one
/// the comparison frames show side by side, so a difference between the two renderings of it
/// is the most visible one the example can have.
void main() {
  /// The card as the browser receives it, planned after a plain text — the order the page
  /// plans its own copy in before it reaches the dialog.
  String cardHtml() => toHtml(
    core.Box(
      children: <core.UINode>[
        const core.TextNode('Apartments'),
        buildSignupCard(
          state: const SignupFormState(name: 'Ada', email: 'ada@example.com'),
          onNameChanged: (_) {},
          onEmailChanged: (_) {},
          onNewsletterToggled: () {},
          onSubmit: () {},
          onDismiss: () {},
        ),
      ],
    ),
  );

  group('the sign-up card in a document', () {
    test(
      'sets its heading the way the tree asks, not the way a browser does',
      () {
        // A user agent gives `h1`-`h6` a `1.5em` size and `0.83em` margins of its own, and the
        // model has no place for either: the tree's typography is the whole of the heading's
        // look. The card's title is a heading and the text beside it is not, so the two must not
        // share a class — they wear the same typography, and sharing one let the plain text's
        // rule answer for the `<h2>`, which then drew at 33 pixels where Flutter drew 22 and
        // made the card taller than the frame its Flutter twin fits in.
        final String html = cardHtml();
        final RegExpMatch heading = RegExp(r'<h(\d) class="([^"]+)"')
            .firstMatch(html)!;
        final String rule = RegExp(
          '\\.${RegExp.escape(heading.group(2)!)}\\{([^}]*)\\}',
        ).firstMatch(html)!.group(1)!;

        expect(rule, contains('margin:0'));
        expect(rule, contains('font-size:inherit'));
      },
    );

    test('holds no heading on the user agent\'s margins', () {
      final String html = cardHtml();

      for (final RegExpMatch heading in RegExp(
        r'<h[1-6] class="([^"]+)"',
      ).allMatches(html)) {
        final String rule = RegExp(
          '\\.${RegExp.escape(heading.group(1)!)}\\{([^}]*)\\}',
        ).firstMatch(html)!.group(1)!;

        expect(rule, contains('margin:0'));
      }
    });
  });
}
