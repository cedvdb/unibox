import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

/// The scroll offsets a tree starts with, so a box that scrolls opens where a reader left it.
///
/// A page can be static HTML first and the application second. The application paints into a
/// canvas the size of the viewport, so the browser's own scroll position is not something it
/// can inherit — the document records the offset of each region it drew, and this hands them
/// to the tree before it draws.
///
/// ```dart
/// UniboxScrollScope(
///   offsets: <core.BoxScrollOffset>[
///     core.BoxScrollOffset(key: 'listings', dy: 1400),
///   ],
///   child: page.toWidget(),
/// );
/// ```
///
/// It is read once, when a scrolling box is built, and used as the *initial* offset: the
/// position is right at the first layout, so a reader never sees the top of a list and then a
/// correction. After that the reader owns it — a rebuild does not move them back.
///
/// The offsets come from the page, and a host reads them where it does its other reads: a
/// global written by the client script on web, an empty list elsewhere. `unibox_flutter`
/// itself reads nothing, because it also builds for iOS and Android.
class UniboxScrollScope extends InheritedWidget {
  /// Creates the scope around [child].
  const UniboxScrollScope({
    required this.offsets,
    required super.child,
    super.key,
  });

  /// Every offset of this rendering, in the order they were given.
  final List<core.BoxScrollOffset> offsets;

  /// The offset of the box keyed [key], or `null` when this rendering was given none.
  ///
  /// A box without a key has nothing to be found by, so it always starts at the top: the
  /// alternative is guessing which region a page meant.
  static core.BoxScrollOffset? offsetOf(BuildContext context, Object? key) {
    if (key == null) {
      return null;
    }

    return context
        .dependOnInheritedWidgetOfExactType<UniboxScrollScope>()
        ?.offsetFor(key);
  }

  /// The offset recorded for [key], or `null`.
  ///
  /// A scan rather than a map: a page has a handful of scrolling regions, and a map built
  /// here would have to be rebuilt whenever the widget is, which is the same work twice.
  core.BoxScrollOffset? offsetFor(Object key) {
    for (final core.BoxScrollOffset offset in offsets) {
      if (offset.key == key) {
        return offset;
      }
    }

    return null;
  }

  @override
  bool updateShouldNotify(UniboxScrollScope oldWidget) =>
      !_sameOffsets(oldWidget.offsets, offsets);

  static bool _sameOffsets(
    List<core.BoxScrollOffset> one,
    List<core.BoxScrollOffset> other,
  ) {
    if (one.length != other.length) {
      return false;
    }

    for (int i = 0; i < one.length; i++) {
      if (one[i] != other[i]) {
        return false;
      }
    }

    return true;
  }
}
