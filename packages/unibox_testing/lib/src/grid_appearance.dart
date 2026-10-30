import 'token_difference.dart';

/// How a grid gave out the tracks it has.
///
/// A grid's placement is not a look, so it is not part of `BoxAppearance`: what
/// the box states is a `gridSpan`, and what decides whether it is honoured is the
/// grid it sits in. The two renderers describe the answer in vocabularies that do
/// not resemble each other — `grid-column: span 2` in CSS, a `SizedBox` as wide as
/// two tracks in Flutter — so what they are held to is the one number both can be
/// read for: how many tracks each child occupies.
///
/// A span wider than the grid is clamped to its column count on both targets, so
/// the tracks here are the used ones and not the declared ones.
final class GridAppearance {
  /// Describes a placement with the tracks each child occupies.
  const GridAppearance({required this.spans});

  /// The tracks each child occupies, in reading order.
  ///
  /// A child that states no span takes one, so this is never zero and never
  /// longer than the number of children.
  final List<int> spans;

  /// The placement a rendering differs in from [expected].
  ///
  /// A drifting child is named by its index, so a banner that lost its span is a
  /// message about child 1 rather than two lists side by side.
  Map<String, TokenDifference> differencesFrom(GridAppearance expected) {
    final Map<String, TokenDifference> differences =
        <String, TokenDifference>{};

    if (spans.length != expected.spans.length) {
      differences['spans'] = (actual: spans, expected: expected.spans);

      return differences;
    }

    for (var index = 0; index < spans.length; index++) {
      if (spans[index] != expected.spans[index]) {
        differences['span $index'] = (
          actual: spans[index],
          expected: expected.spans[index],
        );
      }
    }

    return differences;
  }

  @override
  bool operator ==(Object other) =>
      other is GridAppearance && differencesFrom(other).isEmpty;

  @override
  int get hashCode => Object.hashAll(spans);

  @override
  String toString() => 'GridAppearance(spans: $spans)';
}
