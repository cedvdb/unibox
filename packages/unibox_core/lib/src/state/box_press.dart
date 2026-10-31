import '../nodes/box.dart';
import '../nodes/ui_node.dart';

/// A press a page recorded before the application arrived.
///
/// A document has no state to change, so a press can only be remembered: the client script writes
/// down the key of the element that was pressed and where inside it the press landed, and the
/// application that takes the page over asks for the record once. This is that record.
///
/// [key] is the `key` of the node whose element was pressed — the value a page writes as
/// `data-unibox-key` — and [dx]/[dy] are the position inside that element, in its own pixels.
final class BoxPress {
  /// Creates a recorded press.
  const BoxPress({required this.key, this.dx = 0, this.dy = 0});

  /// Creates a press from the record a page wrote.
  ///
  /// The shape is the one the client script produces: `{key, dx, dy}`, with the key already a
  /// string because that is what an attribute holds. A record with no key is not a press, so it
  /// is refused rather than guessed at.
  factory BoxPress.fromRecord(Map<String, Object?> record) {
    final Object? key = record['key'];

    if (key is! String) {
      throw ArgumentError.value(
        record,
        'record',
        'A recorded press needs the key of the element that was pressed.',
      );
    }

    return BoxPress(
      key: key,
      dx: _number(record['dx']),
      dy: _number(record['dy']),
    );
  }

  /// The `key` of the element that was pressed, as the document wrote it.
  final Object key;

  /// How far inside the element the press landed, from its left edge.
  final double dx;

  /// How far inside the element the press landed, from its top edge.
  final double dy;

  /// This press as the record a page writes.
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
      other is BoxPress && other.key == key && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(key, dx, dy);

  @override
  String toString() => 'BoxPress(key: $key, dx: $dx, dy: $dy)';
}

/// The nodes of [tree] that answer to [key], in paint order.
///
/// A key is unique among the siblings of one node, so a page that has to find one element again
/// gives it a key that is unique in the document. A tree drawn twice on one page therefore
/// answers twice — [replayPresses] refuses that rather than guessing which one was pressed.
List<UINode> nodesKeyed(UINode tree, Object key) {
  final List<UINode> found = <UINode>[];

  void visit(UINode node) {
    if (node.key == key) {
      found.add(node);
    }

    for (final UINode child in node.children) {
      visit(child);
    }
  }

  visit(tree);

  return found;
}

/// Answers [presses] against [tree]: the press a reader made before the application arrived, run
/// now that the node that was pressed exists.
///
/// **A press is answered only where the tree can name the node that took it.** A key that matches
/// nothing is dropped — the page and the application disagree about what is on screen, and firing
/// whatever happens to be nearby is how the wrong control goes off. A key that matches two nodes is
/// dropped for the same reason. So is a node whose callback is gone: a link without an `onTap`
/// belongs to the browser, which has not been asked yet.
///
/// The returned list is what was answered, so a host can log the presses that were not — silence
/// here is the honest kind: a press that cannot be placed is not a press to invent a place for.
List<BoxPress> replayPresses(UINode tree, Iterable<BoxPress> presses) {
  final List<BoxPress> answered = <BoxPress>[];

  for (final BoxPress press in presses) {
    final List<UINode> matches = nodesKeyed(tree, press.key);

    if (matches.length != 1) {
      continue;
    }

    final UINode node = matches.single;
    // A destination with no handler is the browser's: the page is already following it, and
    // firing whatever the tree would have done would be a second answer to one press.
    final void Function()? callback = switch (node) {
      final Box box => box.onTap,
      _ => null,
    };

    if (callback == null) {
      continue;
    }

    callback();
    answered.add(press);
  }

  return answered;
}
