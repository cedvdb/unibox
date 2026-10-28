/// Where one scrolling box was scrolled to, before the tree drew it.
///
/// A page can be static HTML first and an application second, and the application paints into
/// a canvas the size of the viewport — so the browser's own scroll position is not something
/// it can inherit. The document records the offset of each region it drew, keyed by the key
/// that region's node carried, and this is what crosses the boundary.
///
/// ```dart
/// UniboxScrollScope(
///   offsets: const <BoxScrollOffset>[
///     BoxScrollOffset(key: 'listings', dy: 1400),
///   ],
///   child: renderFlutter(page),
/// );
/// ```
///
/// The value holds no renderer and no host: it is data, which is why it lives in the model
/// and both sides can speak it.
final class BoxScrollOffset {
  /// Creates an offset of a region.
  ///
  /// [key] is the `key` of the scrolling box — the value written as `data-unibox-key` in a
  /// document — and [dx]/[dy] are where that region was scrolled to, in its own pixels.
  const BoxScrollOffset({required this.key, this.dx = 0, this.dy = 0});

  /// Creates an offset from the record a page wrote.
  ///
  /// The shape is the one the client script produces: `{key, dx, dy}`, with the key already
  /// a string because that is what an attribute holds. A record with no key is not an
  /// offset, so it is refused rather than guessed at.
  factory BoxScrollOffset.fromRecord(Map<String, Object?> record) {
    final Object? key = record['key'];

    if (key is! String) {
      throw ArgumentError.value(
        record,
        'record',
        'A recorded offset needs the key of the region it belongs to.',
      );
    }

    return BoxScrollOffset(
      key: key,
      dx: _number(record['dx']),
      dy: _number(record['dy']),
    );
  }

  /// The `key` of the scrolling box, as the document wrote it.
  final Object key;

  /// How far the region was scrolled across, in its own pixels.
  final double dx;

  /// How far the region was scrolled down, in its own pixels.
  final double dy;

  /// This offset as the record a page writes.
  Map<String, Object?> toRecord() => <String, Object?>{
    'key': key,
    'dx': dx,
    'dy': dy,
  };

  static double _number(Object? value) => switch (value) {
    final num number => number.toDouble(),
    _ => 0,
  };

  @override
  bool operator ==(Object other) =>
      other is BoxScrollOffset &&
      other.key == key &&
      other.dx == dx &&
      other.dy == dy;

  @override
  int get hashCode => Object.hash(key, dx, dy);

  @override
  String toString() => 'BoxScrollOffset(key: $key, dx: $dx, dy: $dy)';
}
