import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('MaterialScaffold', () {
    test('puts the app bar above the body, on one surface', () {
      final MaterialScaffold screen = MaterialScaffold(
        appBar: MaterialAppBar(title: const TextNode('Apartments')),
        body: const Box(height: double.infinity, overflow: Overflow.scroll),
      );

      expect(screen, isA<Box>());
      expect(screen.children, hasLength(2));
      expect(screen.children.first, isA<MaterialAppBar>());
      expect(screen.children.last, isA<Box>());
      // The surface the bar paints is the surface behind the body — which is the colour a pull
      // past either end of the body reveals, so the two cannot disagree.
      expect(screen.backgroundColor, MaterialAppBar.surface);
    });

    test('fills the surface it is drawn on', () {
      final MaterialScaffold screen = MaterialScaffold(
        body: const Box(height: double.infinity, overflow: Overflow.scroll),
      );

      expect(screen.width, double.infinity);
      expect(screen.height, double.infinity);
      // A scaffold without a bar is a body: the bar is the screen's, not the component's.
      expect(screen.children, hasLength(1));
    });

    test('leaves the body its own height, because a flex child cannot hold a scroll view', () {
      // The doc's rule, pinned: a scrolling body states `height: double.infinity` itself — the
      // form a screen takes — and the scaffold does not wrap it in a flex box, which would hand
      // it an unbounded axis.
      const Box body = Box(height: double.infinity, overflow: Overflow.scroll);
      final MaterialScaffold screen = MaterialScaffold(body: body);

      expect(screen.children.single, same(body));
      expect((screen.children.single as Box).flex, isNull);
    });
  });
}
