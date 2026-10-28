import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// The declarations of a stack cell: the whole grid area, content at the start.
const Map<String, String> _cellStyles = <String, String>{
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

  group('StackNode', () {
    testComponents('renders a relative grid', (tester) async {
      pumpNode(tester, const core.StackNode());

      expect(find.tag('div'), findsOneComponent);
      expect(stylesOf(find.tag('div')), <String, String>{
        'position': 'relative',
        'display': 'grid',
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
