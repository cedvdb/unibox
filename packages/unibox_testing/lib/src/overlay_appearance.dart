import 'package:unibox_core/unibox_core.dart' as core;

import 'token_difference.dart';

export 'token_difference.dart';

/// How an overlay is presented once it has been rendered.
///
/// The two renderers produce different output — a widget tree on one side, HTML
/// and CSS on the other — so the only thing that can be compared is what the
/// output *does* with an overlay: the colour of the barrier behind it, where on the
/// screen the content sits, and what happens when the content is taller than the
/// room it has.
///
/// A renderer suite reads those facts back from its own output and compares them
/// with the ones an `OverlayCase` expects. What the overlay is made of — a scrim,
/// a fixed layer, a route barrier — is each target's business and stays out.
final class OverlayAppearance {
  /// Creates a description of the presentation of a rendered overlay.
  ///
  /// The defaults are the model's: the Material barrier colour, a content
  /// centred on the screen, and a layer that bounds its content and scrolls it.
  const OverlayAppearance({
    this.barrierColor = core.OverlayNode.defaultBarrierColor,
    this.alignment = core.OverlayAlignment.center,
    this.scrolls = true,
  });

  /// The colour of the barrier between the page and the content.
  final core.BoxColor barrierColor;

  /// Where the content sits on the screen.
  final core.OverlayAlignment alignment;

  /// Whether the layer bounds its content and scrolls what does not fit.
  ///
  /// An overlay is the size of the window, so content taller than it is the case
  /// this describes: a dialog that grew past the window was as tall as its content
  /// on the web and no taller than the window in Flutter, and the same card came
  /// out two heights. Both targets bound the content now, and a scroll is how each
  /// of them lets a reader reach the rest of it.
  final bool scrolls;

  /// The tokens that differ from [expected], keyed by name.
  Map<String, TokenDifference> differencesFrom(OverlayAppearance expected) {
    final Map<String, TokenDifference> differences =
        <String, TokenDifference>{};

    void compare(String token, Object? actualValue, Object? expectedValue) {
      if (actualValue != expectedValue) {
        differences[token] = (actual: actualValue, expected: expectedValue);
      }
    }

    compare('barrierColor', barrierColor, expected.barrierColor);
    compare('alignment', alignment, expected.alignment);
    compare('scrolls', scrolls, expected.scrolls);

    return differences;
  }

  @override
  bool operator ==(Object other) =>
      other is OverlayAppearance && differencesFrom(other).isEmpty;

  @override
  int get hashCode => Object.hash(barrierColor, alignment, scrolls);

  @override
  String toString() =>
      'OverlayAppearance(barrierColor: $barrierColor, alignment: $alignment, '
      'scrolls: $scrolls)';
}
