@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:web/web.dart' as web;

import 'support/document.dart';

/// What a pointer aimed at a count finds, measured where the count is drawn.
///
/// It is a question only a browser answers: the badge is decoration, and the corner it covers
/// has to be the control's — the same hover, the same hand, the same press — which is hit
/// testing, not a declaration. `elementFromPoint` is what a reader's thumb does, so the test
/// asks it rather than reading the class back.
void main() {
  /// The [index]th child element of [parent].
  web.Element child(web.Element parent, [int index = 0]) =>
      parent.children.item(index)!;

  test('gives the pointer at the count to the control under it', () {
    int pressed = 0;
    final DomView view = DomView.mount(
      MaterialIconButton(
        icon: MaterialIcon.codePoint(0xe9b2),
        label: 'Filters',
        badgeCount: 3,
        onTap: () => pressed++,
      ),
      host(),
      theme: MaterialPalette.lightTheme,
    );

    final web.Element stack = child(view.element);
    final web.Element well = child(child(stack, 0));
    final web.Element badge = child(child(stack, 1));
    final web.DOMRect box = badge.getBoundingClientRect();
    final web.Element? at = web.document.elementFromPoint(
      box.left + box.width / 2,
      box.top + box.height / 2,
    );

    expect(at, isNotNull);

    final web.Element found = at!;

    expect(
      well.contains(found),
      isTrue,
      reason: 'the pointer belongs to the control, not to the picture over it',
    );
    expect(web.window.getComputedStyle(found).cursor, 'pointer');

    found.dispatchEvent(
      web.MouseEvent(
        'click',
        web.MouseEventInit(bubbles: true, cancelable: true),
      ),
    );

    expect(pressed, 1);

    view.dispose();
  });
}
