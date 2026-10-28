import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_jaspr/unibox_jaspr.dart';

/// Holds the renderer to the half of the naming rule a test can check.
///
/// This file imports Jaspr and `unibox_jaspr` without a prefix and writes out
/// every name the renderer exports, so a new export that Jaspr already declares
/// turns into an ambiguous import here instead of in a component file that
/// imports both.
///
/// Listing a name is the assertion; the expectations only keep the list from
/// being dead code. `unibox_core` cannot be checked the same way — `Axis`,
/// `BoxBorder`, `BoxShadow` and `TextOverflow` clash with Flutter's names and
/// `TextAlign` and `FontWeight` are shadowed silently — which is why every file
/// here imports the tree with `as core`.
void main() {
  test('exports only names a Jaspr import leaves alone', () {
    const core.UINode tree = core.Box(
      children: <core.UINode>[core.TextNode('Hi')],
    );
    final Component component = tree.toComponent();

    const JasprComponentEmbedBuilder? noBuilder = null;

    final List<Object?> exported = <Object?>[
      JasprBox,
      JasprDefaultTypography,
      JasprComponentNode,
      JasprGrid,
      JasprImage,
      JasprLink,
      JasprPositioned,
      JasprScrollRecorder,
      JasprStack,
      JasprStateful,
      JasprText,
      JasprTextInput,
      renderJaspr,
      scrollRecorderScript,
      component,
      noBuilder,
    ];

    expect(exported, hasLength(16));
    expect(component, isA<Component>());
    expect(renderJaspr, isNotNull);
  });
}
