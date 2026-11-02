@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:web/web.dart' as web;

import 'support/document.dart';

/// Which of two overlapping layers of a stack a reader's thumb reaches.
///
/// A browser paints a positioned box after the in-flow ones, so a stack holding a positioned
/// child and a plain one would hand the press to the positioned one *whatever order the tree
/// wrote them in* — while a Flutter `Stack` paints its children in order and hit-tests them in
/// reverse. A press in the middle of two full-size layers is the one question a browser answers
/// about paint order, so the test asks it rather than comparing stylesheets.
void main() {
  /// A full-size layer that takes a press, so that a pointer has something to land on.
  core.Box layer(String key, void Function() onTap) => core.Box(
    key: key,
    width: 100,
    height: 100,
    backgroundColor: core.BoxColor.rgb(0x2D, 0x6C, 0xF3),
    onTap: onTap,
  );

  /// The key of the box a press in the middle of [children] reaches.
  String? reached(List<core.UINode> children) {
    final DomView view = DomView.mount(
      core.StackNode(width: 100, height: 100, children: children),
      host(),
    );

    // Where this stack was drawn: the page holds the ones earlier tests drew too, and a point
    // from the top of the window would be aimed at whichever stack is up there.
    final web.DOMRect box = view.element.getBoundingClientRect();
    final web.Element? at = web.document.elementFromPoint(
      box.left + box.width / 2,
      box.top + box.height / 2,
    );

    expect(
      at,
      isNotNull,
      reason: 'a layer that paints is a layer a pointer can meet',
    );

    return at!.closest('[data-unibox-key]')?.getAttribute('data-unibox-key');
  }

  test('gives the press to the layer the tree lists last', () {
    expect(
      reached(<core.UINode>[layer('first', () {}), layer('second', () {})]),
      'second',
    );
  });

  test(
    'does not lift a positioned child above the siblings written after it',
    () {
      // The bug this pins: `position: absolute` is painted after the in-flow content of a
      // stacking context, so a positioned child covered the plain one written after it — the
      // reverse of what Flutter's `Stack` draws.
      expect(
        reached(<core.UINode>[
          core.PositionedNode(
            top: 0,
            left: 0,
            child: layer('positioned', () {}),
          ),
          layer('plain', () {}),
        ]),
        'plain',
      );
    },
  );

  test('does not lower the siblings written before a positioned child', () {
    expect(
      reached(<core.UINode>[
        layer('plain', () {}),
        core.PositionedNode(top: 0, left: 0, child: layer('positioned', () {})),
      ]),
      'positioned',
    );
  });
}
