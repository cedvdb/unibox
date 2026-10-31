import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

/// Holds the renderer to the half of the naming rule a test can check.
///
/// This file imports `flutter/material.dart` and `unibox_flutter` without a
/// prefix and writes out every name the renderer exports. A new export that
/// Flutter already declares — or declares later, under the same name — turns one
/// of the references below into an `ambiguous_import`, so the suite fails here
/// instead of in the first application that imports both.
///
/// Listing a name is the assertion; the expectations only keep the list from
/// being dead code.
///
/// The other half cannot be checked this way, because it is not true:
/// `unibox_core` does declare names Flutter uses — `Axis`, `BoxBorder`,
/// `BoxShadow` and `TextOverflow` are reported as ambiguous, and `TextAlign` and
/// `FontWeight` are not even reported, because Flutter re-exports those two from
/// `dart:ui` and an SDK declaration loses to a package declaration without a
/// diagnostic. That is why every file here imports the tree with `as core`, and
/// why a tree belongs in a library that imports no renderer at all:
/// no file then sees both APIs.
void main() {
  test('exports only names a Flutter import leaves alone', () {
    const core.UINode tree = core.Box(
      children: <core.UINode>[core.TextNode('Hi')],
    );
    final Widget widget = tree.toWidget();

    // The typedefs are written out like the classes are; nothing in this list has
    // to be called.
    const FlutterLinkOpener? noHook = null;
    const FlutterWidgetEmbedBuilder? noBuilder = null;

    final List<Object?> exported = <Object?>[
      FlutterBox,
      FlutterGrid,
      pathOf,
      FlutterImage,
      FlutterLinkScope,
      FlutterOverlay,
      FlutterStack,
      FlutterStateful,
      FlutterText,
      FlutterTextInput,
      FlutterTextStyleScope,
      FlutterWidgetNode,
      renderFlutter,
      widget,
      noHook,
      noBuilder,
    ];

    expect(exported, hasLength(16));
    expect(widget, isNotNull);
    expect(renderFlutter, isNotNull);
  });
}
