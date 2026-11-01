@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_dom/unibox_dom.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:web/web.dart' as web;

import 'support/document.dart';

/// What a screen looks like when it is measured: the one question a declaration cannot answer.
///
/// A scaffold is three boxes in a column, and the arrangement it documents — two bars at their
/// stated heights and a body between them — is a fact about a layout engine, not about the tree.
/// A browser resolves a `height: 100%` body against the whole column and shrinks all three to fit,
/// so `flex: 1` is the spelling that means "the rest"; this is the test that keeps the two honest.
void main() {
  /// The height [element] is drawn at, in a browser's own pixels.
  double heightOf(web.Element element) =>
      element.getBoundingClientRect().height;

  test(
    'keeps both bars at their stated heights, and hands the body the rest',
    () {
      final DomView view = DomView.mount(
        MaterialScaffold(
          height: 420,
          appBar: MaterialAppBar(title: const TextNode('Apartments')),
          bottomBar: const Box(height: 56),
          body: const Box(flex: 1, overflow: Overflow.scroll),
        ),
        host(),
        scope: UniboxScope(theme: MaterialPalette.lightTheme),
      );

      final web.Element screen = view.element;
      final web.Element appBar = screen.children.item(0)!;
      final web.Element body = screen.children.item(1)!;
      final web.Element bottomBar = screen.children.item(2)!;

      expect(heightOf(screen), 420);
      expect(heightOf(appBar), MaterialAppBar.topHeight);
      expect(heightOf(bottomBar), 56);
      expect(
        heightOf(body),
        420 - MaterialAppBar.topHeight - 56,
        reason: 'the body is what grows; the bars keep the heights they state',
      );
    },
  );
}
