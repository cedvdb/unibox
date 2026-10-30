import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_element/unibox_element.dart';
import 'package:unibox_html/unibox_html.dart';
import 'package:unibox_material/unibox_material.dart';

/// What a design-system component looks like in a document.
///
/// `unibox_html` does not depend on `unibox_material` — a renderer knows nothing of a
/// design system — but a renderer that cannot draw one is not finished, so the test that
/// proves it lives here and the dependency is a dev one.
void main() {
  group('an ink well in a document', () {
    String renderWell() => toHtml(
      MaterialInkWell(
        onTap: () {},
        borderRadius: 12,
        child: const core.TextNode('Ada Lovelace'),
      ),
      theme: MaterialPalette.light.theme,
    );

    test('draws its resting well, with the content in it', () {
      // A server render reads the state the store starts in: no drop is in flight, so the
      // well is the shape it rests as.
      final String html = renderWell();

      expect(html, contains('>Ada Lovelace</span>'));
      expect(html, contains('border-radius:12px'));
    });

    test('draws its tints as CSS, so hovering and pressing work without JavaScript', () {
      // The tints are state styles, not store state — which is what makes them three
      // rules a document already writes, instead of something only a runtime can do.
      final String html = renderWell();

      expect(html, contains('@media (hover: hover)'));
      expect(html, contains(':hover'));
      expect(html, contains(':active'));
    });

    test('draws no ink, because ink is a state a document cannot reach', () {
      // The ripple is a drop in the store, advanced by a timer and drawn as a layer of
      // boxes. A page without a runtime shows the resting well and no drop — which is the
      // behaviour the ink well's own documentation asks for.
      expect(renderWell(), isNot(contains('unibox-ink')));
    });

    test('resolves its colours through the theme it was given', () {
      // Every colour is a role, so a dark scheme is the host's theme and not a parameter:
      // the document writes the custom property and the `:root` block answers it.
      final String html = renderWell();

      expect(html, contains('var(--unibox-color-'));
      expect(html, contains('--unibox-color-primary:'));
    });

    test('is a region a crawler can read, not a canvas', () {
      final String html = renderWell();

      expect(html, contains('<span class="unibox-text-'));
      expect(html, isNot(contains('<canvas')));
    });
  });

  group('a ripple in the stylesheet', () {
    test('writes the looks a press needs once, so pressing again costs no rule', () {
      // The bug this exists for: a drop used to be given a new size every frame, and on the
      // web a size is a class — one rule a frame, kept for the life of the page. A button
      // pressed all afternoon left thousands of rules behind, and every frame of every press
      // rewrote the whole sheet into the document, so each press was slower than the one
      // before it. A ripple is a fixed set of looks now, and the press point snaps to a pixel.
      final MaterialInkStore store = MaterialInkStore();
      final MaterialInkWell well = MaterialInkWell(
        onTap: () {},
        borderRadius: 12,
        child: const core.TextNode('Ada Lovelace'),
      );
      final Stylesheet sheet = Stylesheet();

      /// One press, planned frame by frame the way a publish plans it.
      void ripple(core.BoxPoint at) {
        store.press(at);

        while (store.state.drops.isNotEmpty) {
          planNode(well.viewFor(store.state, store), sheet);
          store.advance(const Duration(milliseconds: 16));
        }
      }

      ripple(const core.BoxPoint(30.4, 16.7));
      final int first = sheet.length;
      expect(first, greaterThan(0));

      // The same button, tapped again a fraction of a pixel away.
      ripple(const core.BoxPoint(30.2, 16.6));
      expect(
        sheet.length,
        first,
        reason:
            'a ripple draws a fixed set of looks, and a press lands on a pixel',
      );

      // A tap a few pixels along is one look more: where it landed, not when it landed.
      ripple(const core.BoxPoint(34.4, 16.7));
      expect(sheet.length, first + 1);

      store.dispose();
    });
  });
}
