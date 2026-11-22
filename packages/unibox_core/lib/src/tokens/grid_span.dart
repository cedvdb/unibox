/// How much of a grid a child occupies.
///
/// A grid that has to be interrupted — a banner across the row between the first two cards — states
/// the span on the box that spans, which is what CSS does too (`grid-column: span 2`).
///
/// The two cases exist because they need different words on the two targets, and only one of them can
/// be said with a count:
///
/// * [GridSpan.tracks] is a number of columns. A count the grid does not have is clamped, and CSS
///   states it as `grid-column: span 2`.
/// * [GridSpan.row] is "all of them". CSS cannot state that as a count — a `span` wider than the
///   grid makes a browser invent a column and overflow — so it states the row's own edges instead,
///   `grid-column: 1 / -1`, which is the whole row however many columns there are. Flutter clamps to
///   the count it worked out, which is the same thing.
///
/// A count clamped in a narrow layout is why this type exists: "span 2" in a one-column grid is a
/// grid wider than its container, while "the row" is right at every width.
final class GridSpan {
  /// The child takes [tracks] columns, or the whole row when the grid is narrower.
  const GridSpan.tracks(int this.tracks) : fillRow = false;

  /// The child takes the whole row, however many columns the grid has.
  const GridSpan.row() : tracks = null, fillRow = true;

  /// The number of columns asked for, or `null` for the whole row.
  final int? tracks;

  /// Whether the child takes the whole row.
  final bool fillRow;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridSpan && other.tracks == tracks && other.fillRow == fillRow;

  @override
  int get hashCode => Object.hash(tracks, fillRow);

  @override
  String toString() => fillRow ? 'GridSpan.row()' : 'GridSpan.tracks($tracks)';
}
