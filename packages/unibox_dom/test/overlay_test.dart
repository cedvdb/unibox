@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:web/web.dart' as web;

/// A host for a view, in the document.
web.HTMLDivElement host() {
  final web.HTMLDivElement element =
      web.document.createElement('div') as web.HTMLDivElement;
  web.document.body!.append(element);

  return element;
}

/// The layer, the scrim it holds, and the content it places, in that order.
({web.Element layer, web.Element barrier, web.Element content}) partsOf(
  DomView view,
) {
  final web.Element layer = view.element;

  return (
    layer: layer,
    barrier: layer.children.item(0)!,
    content: layer.children.item(1)!,
  );
}

/// An overlay holding a box of [height]: narrow enough to leave the scrim beside it,
/// and tall enough to be measured.
core.UINode dialog(double height) => core.OverlayNode(
  child: core.Box(
    width: 280,
    height: height,
    backgroundColor: const core.BoxColor(0xFF112233),
  ),
);

void main() {
  group('an overlay larger than the window', () {
    test('is bounded by the layer and scrolled inside it', () {
      // The drift this pins: a flex item centred in a box is allowed to be taller than it,
      // so the example's sign-up card was drawn at the height of its content here and cut
      // off at the window in Flutter — one node, two heights. The layer is the scrollport
      // now, which is what Flutter's scroll view over the same layer draws.
      final DomView view = DomView.mount(dialog(900), host());
      final ({web.Element layer, web.Element barrier, web.Element content})
      parts = partsOf(view);

      expect(
        parts.layer.clientHeight,
        web.window.innerHeight,
        reason:
            'the layer is the window, so the window is the room it bounds to',
      );
      expect(
        parts.layer.scrollHeight,
        greaterThan(parts.layer.clientHeight),
        reason: 'a dialog taller than the window has to be scrollable',
      );
      expect(
        parts.content.getBoundingClientRect().top,
        0,
        reason:
            'the top of the content is reachable: an item centred past the start of '
            'its scrollport loses the edge no scroll can reach',
      );

      view.dispose();
    });

    test('scrolls to the end of the content', () {
      final DomView view = DomView.mount(dialog(900), host());
      final ({web.Element layer, web.Element barrier, web.Element content})
      parts = partsOf(view);

      parts.layer.scrollTop = 1000;

      expect(
        parts.content.getBoundingClientRect().bottom,
        closeTo(web.window.innerHeight.toDouble(), 1),
        reason: 'scrolling to the end puts the last of the content on screen',
      );

      view.dispose();
    });

    test('keeps the scrim on the window as the content scrolls', () {
      // The scrim is pinned to the window rather than laid out in the scroll: otherwise
      // scrolling to the end of a long dialog carries it off the screen and the page
      // behind it is left undimmed.
      final DomView view = DomView.mount(dialog(900), host());
      final ({web.Element layer, web.Element barrier, web.Element content})
      parts = partsOf(view);

      parts.layer.scrollTop = 1000;

      expect(parts.barrier.getBoundingClientRect().top, 0);
      expect(
        parts.barrier.getBoundingClientRect().height,
        web.window.innerHeight,
      );

      view.dispose();
    });
  });

  group('an overlay that fits in the window', () {
    test('centres its content, top to bottom, by a margin', () {
      final DomView view = DomView.mount(dialog(200), host());
      final ({web.Element layer, web.Element barrier, web.Element content})
      parts = partsOf(view);

      final double expected = (web.window.innerHeight - 200) / 2;

      expect(
        parts.content.getBoundingClientRect().top,
        closeTo(expected, 1),
        reason: 'auto margins centre what fits and fall back to zero when it does not',
      );
      expect(
        parts.content.getBoundingClientRect().left,
        closeTo((web.window.innerWidth - 280) / 2, 1),
        reason: 'a dialog is centred across the window as well as down it',
      );
      expect(
        parts.layer.scrollHeight,
        parts.layer.clientHeight,
        reason: 'a dialog that fits leaves nothing to scroll',
      );

      view.dispose();
    });
  });
}
