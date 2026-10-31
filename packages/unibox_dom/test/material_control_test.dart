@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:web/web.dart' as web;

import 'support/document.dart';

/// How big the box that takes a press is next to the pill it paints.
///
/// A tree can state the intent — the floor is the well's, and a pinned size is the well's too —
/// but the numbers a reader meets are layout, and only a browser lays a page out. So the sizes
/// are read back off the elements: the pill, and the box inside it that answers the pointer.
void main() {
  /// The [index]th child element of [parent].
  web.Element child(web.Element parent, [int index = 0]) =>
      parent.children.item(index)!;

  /// A length the browser resolved, in pixels.
  double length(String value) =>
      double.tryParse(value.replaceAll('px', '').trim()) ?? 0;

  /// The room inside a pill's painted frame: what a browser gives its content, and what
  /// Flutter's own box is, because a `BoxDecoration` border paints inside the box there.
  ({double width, double height}) roomInside(web.Element pill) {
    final web.CSSStyleDeclaration style = web.window.getComputedStyle(pill);
    final web.DOMRect box = pill.getBoundingClientRect();

    return (
      width:
          box.width -
          length(style.getPropertyValue('border-left-width')) -
          length(style.getPropertyValue('border-right-width')),
      height:
          box.height -
          length(style.getPropertyValue('border-top-width')) -
          length(style.getPropertyValue('border-bottom-width')),
    );
  }

  test('fills the pill with the press, whatever room the caller leaves', () {
    // Four pixels above and below the label is a 28 pixel control inside a 40 pixel pill until
    // the minimum belongs to the well; a pinned size leaves the ends of the pill dead.
    final MaterialButton roomy = MaterialButton.outlined(
      label: const core.TextNode('Sign in'),
      padding: const core.BoxSpacing.symmetric(horizontal: 16, vertical: 4),
      onTap: () {},
    );
    final MaterialButton pinned = MaterialButton.filled(
      label: const core.TextNode('Sign in'),
      width: 200,
      height: 56,
      onTap: () {},
    );

    final DomView view = DomView.mount(
      core.Box(
        direction: core.Axis.horizontal,
        children: <core.UINode>[roomy, pinned],
      ),
      host(),
      theme: MaterialPalette.lightTheme,
    );

    for (int index = 0; index < 2; index++) {
      final web.Element pill = child(child(view.element, index));
      final web.Element press = child(pill);
      final web.DOMRect pressBox = press.getBoundingClientRect();
      final ({double width, double height}) room = roomInside(pill);

      expect(pressBox.width, closeTo(room.width, 0.01));
      expect(pressBox.height, closeTo(room.height, 0.01));
      expect(pressBox.height, greaterThanOrEqualTo(40));
    }

    final web.DOMRect pinnedBox = child(child(view.element, 1))
        .getBoundingClientRect();

    expect(pinnedBox.width, 200);
    expect(pinnedBox.height, 56);

    view.dispose();
  });
}
