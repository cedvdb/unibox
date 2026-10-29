import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

/// Every node of [root], depth first.
List<UINode> flatten(UINode root) => <UINode>[
  root,
  for (final UINode child in root.children) ...flatten(child),
];

/// The text of every [TextNode] in [root], depth first.
List<String> textsIn(UINode root) =>
    flatten(root)
        .whereType<TextNode>()
        .map((TextNode node) => node.text)
        .toList();

/// The innermost box that contains a [TextNode] with [label].
Box boxAround(UINode root, String label) =>
    flatten(root)
        .whereType<Box>()
        .lastWhere((Box box) => textsIn(box).contains(label));

/// Stands in for a host application: records what the tree reports.
///
/// The pages of the example know nothing about state containers, so a recording
/// host is all a test needs: it builds the tree with callbacks that write down
/// what happened.
final class RecordingHost {
  /// The names reported through `onNameChanged`.
  final List<String> names = <String>[];

  /// The emails reported through `onEmailChanged`.
  final List<String> emails = <String>[];

  /// How often the newsletter opt-in was toggled.
  int newsletterToggles = 0;

  /// How often the form was submitted.
  int submissions = 0;

  /// The pages reported through the navigation.
  final List<ExamplePage> navigations = <ExamplePage>[];

  /// Builds the card for [state] with recording callbacks.
  Box card([SignupFormState state = const SignupFormState()]) {
    return buildSignupCard(
      state: state,
      onNameChanged: names.add,
      onEmailChanged: emails.add,
      onNewsletterToggled: () => newsletterToggles++,
      onSubmit: () => submissions++,
      onDismiss: () => dismissals++,
    );
  }

  /// How often the dialog asked to be dismissed.
  int dismissals = 0;

  /// Builds the sign-up dialog for [state] with recording callbacks.
  OverlayNode dialog([SignupFormState state = const SignupFormState()]) {
    return buildSignupDialog(
      state: state,
      onNameChanged: names.add,
      onEmailChanged: emails.add,
      onNewsletterToggled: () => newsletterToggles++,
      onSubmit: () => submissions++,
      onDismiss: () => dismissals++,
    );
  }

  /// Wraps [page] in the example frame with a recording navigation.
  Box frame({
    ExamplePage current = ExamplePage.apartments,
    UINode? page,
    OverlayNode? dialog,
    ExampleSeed seed = ExampleSeed.blue,
  }) {
    return buildExamplePage(
      current: current,
      seed: seed,
      onNavigate: navigations.add,
      page: page ?? buildApartmentsPage(),
      dialog: dialog,
    );
  }
}

/// The tree [node] draws for the state its store starts with.
///
/// Creating the store is what a renderer does when it mounts the node, so this is
/// the first frame of the page without a host or a widget in the way.
UINode viewOf(ExamplePageNode node) {
  final ExampleStore store = node.create();
  return node.viewFor(store.state, store);
}
