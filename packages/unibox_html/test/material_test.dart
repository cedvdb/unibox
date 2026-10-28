import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
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
}
