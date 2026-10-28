import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// The declarations of a stack cell: the whole grid area, content at the start.
///
/// The cell is `position: relative` so it is painted in source order: a static box
/// would be painted below every absolutely positioned sibling, and a Flutter `Stack`
/// paints its children in the order they are written.
const Map<String, String> _cellStyles = <String, String>{
  'position': 'relative',
  'display': 'flex',
  'align-items': 'start',
  'justify-content': 'start',
  // A cell is a placement and not a control: it takes no press, so the control it
  // holds — or the cell underneath it — does.
  'pointer-events': 'none',
  'grid-area': '1 / 1',
};

void main() {
  group('an aligned child', () {
    testComponents('fills the cell and is placed by the alignment', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.StackNode(
          width: 300,
          height: 200,
          children: <core.UINode>[
            core.Box(width: double.infinity, height: double.infinity),
            core.PositionedNode(
              alignment: core.BoxAlignment.bottomCenter,
              child: core.TextNode('Open the map'),
            ),
          ],
        ),
      );

      // The last cell is the aligned one: it fills the stack and places its child
      // along the row, at the end of the column — bottom-centred is
      // `justify-content: center` with `align-items: end`.
      final Map<String, String> styles = stylesOf(find.tag('div').last);

      expect(styles['position'], 'absolute');
      // The cell is the whole stack: four edges at zero, which is `inset: 0`
      // written out — Jaspr states the sides rather than the shorthand.
      expect(styles['top'], '0');
      expect(styles['right'], '0');
      expect(styles['bottom'], '0');
      expect(styles['left'], '0');
      expect(styles['justify-content'], 'center');
      expect(styles['align-items'], 'end');
      expect(find.text('Open the map'), findsOneComponent);
    });
  });

  group('a box that holds only a layer', () {
    testComponents('aligns the layer with its own pair, and lets it hug', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.Box(
          width: 200,
          height: 100,
          mainAlign: core.MainAlign.center,
          crossAlign: core.CrossAlign.center,
          children: <core.UINode>[
            core.StackNode(
              children: <core.UINode>[core.Box(width: 30, height: 20)],
            ),
          ],
        ),
      );

      // The box, the layer, and the layer's one cell.
      final Map<String, String> box = stylesOf(find.tag('div').first);
      final Map<String, String> layer = stylesOf(find.tag('div').at(1));

      // The box is the flex that places the layer, and the layer is a flow child
      // that states no height, so it takes the height of its content and the pair
      // centres it. Flutter draws the same place the other way round — a stack that
      // fills the box and aligns its children — which is the same rectangle as long
      // as both read the pair.
      expect(box['display'], 'flex');
      expect(box['justify-content'], 'center');
      expect(box['align-items'], 'center');
      expect(layer['display'], 'grid');
      expect(layer.containsKey('height'), isFalse);
    });
  });

  group('StackNode', () {
    testComponents('renders a relative grid whose cell is the stack', (
      tester,
    ) async {
      pumpNode(tester, const core.StackNode());

      expect(find.tag('div'), findsOneComponent);
      // The one row is `100%` of the stack, not the height of what sits in it: a
      // child that fills the stack is as tall as the stack, which is what a Flutter
      // `Stack` hands a child it does not position. An `auto` row is as tall as its
      // content instead, so a list inside a page would grow the document rather
      // than scroll in the window. With no height stated, `100%` resolves to `auto`
      // and a content-sized stack still sizes to its content.
      expect(stylesOf(find.tag('div')), <String, String>{
        'position': 'relative',
        'display': 'grid',
        'grid-template-rows': '100%',
      });
    });

    testComponents('maps dimensions to css units', (tester) async {
      pumpNode(
        tester,
        const core.StackNode(width: 200, height: double.infinity),
      );

      final Map<String, String> styles = stylesOf(find.tag('div'));

      expect(styles['width'], '200px');
      expect(styles['height'], '100%');
    });

    testComponents('layers unpositioned children in one cell', (tester) async {
      pumpNode(
        tester,
        const core.StackNode(
          width: 100,
          height: 100,
          children: [core.TextNode('Bottom'), core.TextNode('Top')],
        ),
      );

      // One container plus one cell wrapper per child.
      expect(find.tag('div'), findsNComponents(3));
      // The cell wrapper fills the grid area and lays its child out at the top
      // start corner: a Flutter `Stack` gives a child that is not positioned the
      // cell as a constraint and leaves it its own size.
      expect(stylesOf(find.tag('div').at(1)), _cellStyles);
      expect(stylesOf(find.tag('div').at(2)), _cellStyles);
      expect(find.text('Bottom'), findsOneComponent);
      expect(find.text('Top'), findsOneComponent);
    });

    testComponents('paints a positioned layer before what follows it', (
      tester,
    ) async {
      // A web box is static by default, and CSS paints an absolutely positioned
      // sibling *above* every static one whatever the source order — so a layer
      // written first, like an ink drop or a navigation indicator, would sit on top
      // of the content written after it. Flutter's `Stack` paints in order, so the
      // in-flow cell is relative and the two targets agree.
      pumpNode(
        tester,
        const core.StackNode(
          width: 100,
          height: 40,
          children: <core.UINode>[
            core.PositionedNode(left: 0, top: 0, child: core.TextNode('under')),
            core.TextNode('over'),
          ],
        ),
      );

      // The stack itself is the first `div`; its two cells follow it.
      final Map<String, String> under = stylesOf(find.tag('div').at(1));
      final Map<String, String> over = stylesOf(find.tag('div').at(2));

      expect(under['position'], 'absolute');
      expect(
        over['position'],
        'relative',
        reason: 'the cell after it is painted in source order, not below',
      );
    });

    testComponents('positions a child absolutely', (tester) async {
      pumpNode(
        tester,
        const core.StackNode(
          width: 100,
          height: 100,
          children: [
            core.PositionedNode(
              top: 10,
              left: 4,
              child: core.Box(width: 20, height: 20),
            ),
          ],
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div').at(1));

      expect(styles['position'], 'absolute');
      expect(styles['top'], '10px');
      expect(styles['left'], '4px');
      expect(styles.containsKey('grid-area'), isFalse);
    });

    testComponents('positions a child from the opposite edges', (tester) async {
      pumpNode(
        tester,
        const core.StackNode(
          width: 100,
          height: 100,
          children: [
            core.PositionedNode(
              right: 8,
              bottom: 12,
              child: core.TextNode('Badge'),
            ),
          ],
        ),
      );

      final Map<String, String> styles = stylesOf(find.tag('div').at(1));

      expect(styles['position'], 'absolute');
      expect(styles['right'], '8px');
      expect(styles['bottom'], '12px');
      expect(styles.containsKey('top'), isFalse);
    });

    testComponents('keeps a positioned node without offsets in the cell', (
      tester,
    ) async {
      pumpNode(
        tester,
        const core.StackNode(
          children: [core.PositionedNode(child: core.TextNode('Centered'))],
        ),
      );

      expect(stylesOf(find.tag('div').at(1)), _cellStyles);
    });

    testComponents('nests further nodes', (tester) async {
      pumpNode(
        tester,
        const core.StackNode(
          width: 120,
          height: 120,
          children: [
            core.ImageNode('assets/cover.png', width: 120, height: 120),
            core.PositionedNode(
              left: 8,
              bottom: 8,
              child: core.TextNode('Caption'),
            ),
          ],
        ),
      );

      expect(find.tag('img'), findsOneComponent);
      expect(find.tag('span'), findsOneComponent);
      expect(find.text('Caption'), findsOneComponent);
    });
  });

  group('PositionedNode', () {
    testComponents('renders only its child without a stack', (tester) async {
      pumpNode(
        tester,
        const core.PositionedNode(top: 4, child: core.TextNode('Loose')),
      );

      expect(find.tag('div'), findsNothing);
      expect(find.tag('span'), findsOneComponent);
      expect(find.text('Loose'), findsOneComponent);
    });
  });
}
