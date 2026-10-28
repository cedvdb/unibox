import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';

void main() {
  group('a text', () {
    test('writes only the typography it states', () {
      expect(textDeclarations(const core.TextNode('Hi')).text, '');
      expect(
        textDeclarations(const core.TextNode('Hi', fontSize: 20)).text,
        'font-size:20px',
      );
    });

    test('clamps to a number of lines with the prefixed box layout', () {
      // The only way CSS truncates after N lines, and it is not a typed property.
      expect(
        textDeclarations(const core.TextNode('Hi', maxLines: 2)).text,
        '-webkit-box-orient:vertical;-webkit-line-clamp:2;display:-webkit-box;'
        'overflow:hidden',
      );
    });

    test('truncates one line without a clamp', () {
      expect(
        textDeclarations(
          const core.TextNode('Hi', overflow: core.TextOverflow.ellipsis),
        ).text,
        'overflow:hidden;text-overflow:ellipsis;white-space:nowrap',
      );
    });

    test('resets what a heading brings from the user agent', () {
      // A heading is structure, not a look: the reset states only the tokens the node
      // does not, so the tree's typography stays in charge.
      expect(
        textDeclarations(const core.TextNode('Hi', headingLevel: 2)).text,
        'font-size:inherit;font-weight:inherit;margin:0',
      );
      expect(
        textDeclarations(
          const core.TextNode('Hi', headingLevel: 2, fontSize: 32),
        ).text,
        'font-size:32px;font-weight:inherit;margin:0',
      );
    });

    test('aligns when it says where', () {
      expect(
        textDeclarations(
          const core.TextNode('Hi', textAlign: core.TextAlign.center),
        ).text,
        'text-align:center',
      );
    });
  });

  group('an image', () {
    test('is a block, so it contributes no line box', () {
      expect(
        imageDeclarations(const core.ImageNode('a.png', alt: 'A')).text,
        'display:block;object-fit:scale-down',
      );
    });

    test('states the box it was given', () {
      expect(
        imageDeclarations(
          const core.ImageNode(
            'a.png',
            width: 200,
            height: 100,
            borderRadius: 8,
            fit: core.ImageFit.cover,
          ),
        ).text,
        'border-radius:8px;display:block;height:100px;object-fit:cover;'
        'width:200px',
      );
    });
  });

  group('a grid', () {
    test('counts its tracks from the width it is given', () {
      expect(
        gridDeclarations(const core.GridNode(minItemWidth: 200)).text,
        'align-items:start;display:grid;grid-template-columns:'
        'repeat(auto-fill, minmax(min(100%, 200px), 1fr));min-width:0;width:100%',
      );
    });

    test('leaves room for the gutters when it caps the columns', () {
      expect(
        gridDeclarations(
          const core.GridNode(minItemWidth: 200, gap: 16, maxColumns: 3),
        ).text,
        'align-items:start;display:grid;gap:16px;grid-template-columns:'
        'repeat(auto-fill, minmax(min(100%, max(200px, (100% - 32px) / 3)), 1fr));'
        'min-width:0;width:100%',
      );
    });
  });

  group('a stack', () {
    test('is a relative grid with a row the height of the stack', () {
      // The row is the stack, not its content: a list inside it scrolls instead of
      // growing the document.
      expect(
        stackDeclarations(const core.StackNode()).text,
        'display:grid;grid-template-rows:100%;position:relative',
      );
    });

    test('gives each child a cell it cannot escape', () {
      expect(
        stackCellDeclarations().text,
        'align-items:start;display:flex;grid-area:1 / 1;justify-content:start;'
        'pointer-events:none',
      );
    });
  });

  group('a positioned child', () {
    test('collapses four equal offsets into one inset', () {
      expect(
        positionedDeclarations(
          const core.PositionedNode(
            top: 5,
            right: 5,
            bottom: 5,
            left: 5,
            child: core.TextNode('Hi'),
          ),
        ).text,
        'inset:5px;pointer-events:none;position:absolute',
      );
    });

    test('states the edges it has when they differ', () {
      expect(
        positionedDeclarations(
          const core.PositionedNode(
            top: 8,
            left: 16,
            child: core.TextNode('Hi'),
          ),
        ).text,
        'left:16px;pointer-events:none;position:absolute;top:8px',
      );
    });

    test('takes no pointer of its own', () {
      // A wrapper is a placement, not a control: the child inside takes the press.
      expect(
        positionedDeclarations(
          const core.PositionedNode(child: core.TextNode('Hi')),
        ).text,
        'pointer-events:none;position:absolute',
      );
    });
  });

  group('an aligned child', () {
    test('fills the stack and aligns inside it', () {
      expect(
        alignedDeclarations(core.BoxAlignment.bottomCenter).text,
        'align-items:end;display:flex;flex-direction:row;inset:0;'
        'justify-content:center;pointer-events:none;position:absolute',
      );
    });

    test('names the two axes of every corner', () {
      expect(
        alignedDeclarations(core.BoxAlignment.topStart).text,
        contains('align-items:start;display:flex'),
      );
      expect(
        alignedDeclarations(core.BoxAlignment.topEnd).text,
        contains('justify-content:end'),
      );
      expect(
        alignedDeclarations(core.BoxAlignment.center).text,
        contains('align-items:center'),
      );
    });
  });
}
