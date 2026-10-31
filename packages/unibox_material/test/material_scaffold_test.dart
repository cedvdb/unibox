import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('MaterialScaffold', () {
    test('puts the app bar above the body on the page', () {
      final MaterialScaffold screen = MaterialScaffold(
        appBar: MaterialAppBar(title: const TextNode('Apartments')),
        body: const Box(height: double.infinity, overflow: Overflow.scroll),
      );

      expect(screen, isA<Box>());
      expect(screen.children, hasLength(2));
      expect(screen.children.first, isA<MaterialAppBar>());
      expect(screen.children.last, isA<Box>());
      expect(screen.backgroundColor, MaterialScaffold.surface);
    });

    test('draws the page a step below the container the band paints', () {
      // Material's arrangement, and the one that makes a band read as a band: `surface` behind the
      // screen and `surfaceContainer` for the bar. One colour behind both is a bar that disappears
      // into its list, which is what this test is here to stop happening again.
      expect(
        MaterialScaffold.surface,
        const BoxColor.role(MaterialColorRole.surface),
      );
      expect(
        MaterialScaffold.surface,
        isNot(MaterialAppBar.surface),
        reason: 'the page and the band are two different roles',
      );
    });

    test('stretches the band and the body across the screen', () {
      final MaterialScaffold screen = MaterialScaffold(
        appBar: MaterialAppBar(title: const TextNode('24')),
        body: const Box(height: double.infinity, overflow: Overflow.scroll),
      );

      // A column hugs its children by default, which hands a bar with a short title the width of
      // its words: a band only as wide as the screen if the screen says so.
      expect(screen.crossAlign, CrossAlign.stretch);
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
