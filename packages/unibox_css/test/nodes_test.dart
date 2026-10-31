import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';

void main() {
  group('a box that wraps', () {
    test('is a flex container whose lines break inside it', () {
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(direction: core.Axis.horizontal, wrap: true),
      );

      expect(declarations.text, contains('flex-wrap:wrap'));
      expect(
        declarations.text,
        contains('align-content:flex-start'),
        reason:
            'a browser stretches the lines over the box by default, and a '
            'Flutter Wrap packs them from the start',
      );
    });

    test('states the direction the words flow in, and claims none when it has none', () {
      final CssDeclarations rtl = boxDeclarations(
        const core.BoxStyle(writingDirection: core.WritingDirection.rtl),
      );

      expect(rtl['direction'], 'rtl');
      expect(
        boxDeclarations(const core.BoxStyle()).has('direction'),
        isFalse,
        reason:
            'a box that states none inherits the page, and stating `ltr` here '
            'would overrule a page written right to left',
      );
    });

    test('says nothing about a wrap a box does not state', () {
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(direction: core.Axis.horizontal),
      );

      expect(declarations.text, isNot(contains('flex-wrap')));
      expect(declarations.text, isNot(contains('align-content')));
    });

    test('leaves the wrap out of a state rule', () {
      // A state rule restates only the tokens the state changes: a `:hover` that repeated
      // the wrap would reset the resting layout, which is why the declarations of a state
      // are written with `declaredOnly`.
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(wrap: true),
        declaredOnly: true,
      );

      expect(declarations.text, isNot(contains('flex-wrap')));
    });
  });

  group('a grid that states its columns', () {
    test('is one explicit track per column, as 1fr 2fr 1fr states them', () {
      final CssDeclarations declarations = gridDeclarations(
        const core.GridNode.columns(
          <int>[1, 2, 1],
          gap: 12,
          children: <core.UINode>[core.Box(), core.Box(), core.Box()],
        ),
      );

      expect(declarations['display'], 'grid');
      expect(
        declarations['grid-template-columns'],
        'minmax(0, 1fr) minmax(0, 2fr) minmax(0, 1fr)',
        reason:
            'a floor of zero is what lets a column shrink into a parent too narrow '
            'for the widest one, which is what Flutter does with the width it clamps',
      );
      expect(declarations['gap'], '12px');

      // One width rule for both forms: the percentage is the box the grid is in, and
      // `auto` where that box has no width yet.
      expect(declarations['width'], '100%');
    });

    test('starts its columns unless the node stretches them', () {
      // A grid stretches its items by default and the column's height is the model's to
      // place: an unset alignment is `start`, which is written rather than left to the
      // browser.
      expect(
        gridDeclarations(const core.GridNode.columns(<int>[1]))['align-items'],
        'start',
      );
      expect(
        gridDeclarations(
          const core.GridNode.columns(<int>[
            1,
          ], crossAlign: core.CrossAlign.stretch),
        )['align-items'],
        'stretch',
      );
    });

    test('keeps the reflowing grid as it was', () {
      final CssDeclarations declarations = gridDeclarations(
        const core.GridNode(minItemWidth: 200, gap: 16, maxColumns: 3),
      );

      expect(
        declarations['grid-template-columns'],
        contains('repeat(auto-fill'),
      );
      expect(declarations['align-items'], 'start');
    });
  });

  group('a box that pins', () {
    test(
      'sticks to the edge it names, above the content that scrolls under it',
      () {
        final CssDeclarations declarations = boxDeclarations(
          const core.BoxStyle(pin: core.BoxPin.start),
        );

        expect(declarations.text, contains('position:sticky'));
        expect(declarations.text, contains('top:0'));
        expect(
          declarations.text,
          contains('z-index:1'),
          reason:
              'a sticky box is painted in the flow order it was written in, so '
              'content that follows it would paint over it',
        );
      },
    );

    test('keeps the inset it is given, at the end edge', () {
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(pin: core.BoxPin.end, pinOffset: 64),
      );

      expect(declarations.text, contains('position:sticky'));
      expect(declarations.text, contains('bottom:64px'));
      expect(declarations.text, isNot(contains('top:')));
    });

    test('leaves the pin out of a state rule', () {
      // A state rule restates only the tokens the state changes: a `:hover` that repeated
      // the pin would reset the stacking the resting rule set up.
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(pin: core.BoxPin.start),
        declaredOnly: true,
      );

      expect(declarations.text, isNot(contains('sticky')));
      expect(declarations.text, isNot(contains('z-index')));
    });

    test('says nothing for a box that does not pin', () {
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(),
      );

      expect(declarations.text, isNot(contains('sticky')));
      expect(declarations.text, isNot(contains('z-index')));
    });
  });

  group('a box that scrolls', () {
    test(
      'keeps its overscroll to itself, and shows its own surface for it',
      () {
        // A browser hands the rest of a scroll to the page once the box reaches its end; Flutter's
        // viewport keeps it. `contain` is what makes the two agree, and it leaves the host the
        // pull that says "this is the end" — a pull whose gap is the box's own background, so a
        // panel that states its surface never shows the page through it.
        expect(
          boxDeclarations(const core.BoxStyle(overflow: core.Overflow.scroll))
              .text,
          contains('overscroll-behavior:contain'),
        );
      },
    );

    test('says nothing about overscroll for a box that does not scroll', () {
      expect(
        boxDeclarations(const core.BoxStyle(overflow: core.Overflow.hidden))
            .text,
        isNot(contains('overscroll-behavior')),
      );
      expect(
        boxDeclarations(const core.BoxStyle()).text,
        isNot(contains('overscroll-behavior')),
      );
    });
  });

  group('a box that folds', () {
    test('runs an animation on the exit of the box itself', () {
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(fold: core.BoxFold(to: core.BoxStyle(opacity: 0))),
      );

      // `view()` is the box's own visibility in the box that scrolls it, so nothing here names
      // a scroll container, a document or a number of pixels.
      expect(declarations.text, contains('animation-name:unibox-fold-'));
      expect(declarations.text, contains('animation-duration:auto'));
      expect(declarations.text, contains('animation-timeline:view()'));
      expect(declarations.text, contains('animation-fill-mode:both'));
      expect(declarations.text, contains('animation-timing-function:linear'));
      expect(declarations.text, isNot(contains('animation-range')));
    });

    test(
      'writes the two frames, from the look it starts in to the one it ends in',
      () {
        final CssKeyframes frames = foldKeyframes(
          const core.BoxStyle(
            backgroundColor: core.BoxColor.white,
            fold: core.BoxFold(
              to: core.BoxStyle(
                backgroundColor: core.BoxColor.black,
                opacity: 0,
              ),
            ),
          ),
        );

        // Only the looks the fold moves, and both ends of each: the white hero fades to black and
        // to nothing, and the padding it keeps is not in either frame.
        expect(frames.from.text, 'background-color:#ffffff;opacity:1');
        expect(frames.to.text, 'background-color:#000000;opacity:0');
        expect(frames.name, startsWith('unibox-fold-'));
        expect(frames.toString(), '@keyframes ${frames.name}{${frames.body}}');
      },
    );

    test('names one block for one fold, however many boxes wear it', () {
      const core.BoxStyle style = core.BoxStyle(
        fold: core.BoxFold(to: core.BoxStyle(opacity: 0)),
      );

      expect(foldKeyframes(style).name, foldKeyframes(style).name);
      expect(
        foldKeyframes(style).name,
        isNot(
          foldKeyframes(
            const core.BoxStyle(
              fold: core.BoxFold(to: core.BoxStyle(opacity: 0.2)),
            ),
          ).name,
        ),
      );
    });

    test('finishes early when the fold takes part of the exit', () {
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(
          fold: core.BoxFold(to: core.BoxStyle(opacity: 0), over: 0.5),
        ),
      );

      expect(declarations.text, contains('animation-range:exit 0% exit 50%'));
    });

    test('leaves the fold out of a state rule', () {
      // Restating the animation in a `:hover` rule would start it again from wherever the
      // reader is, which is the same reason the pin is left out.
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(fold: core.BoxFold(to: core.BoxStyle(opacity: 0))),
        declaredOnly: true,
      );

      expect(declarations.text, isNot(contains('animation')));
    });
  });

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

    test('states a child span as the tracks it covers', () {
      // The declaration lives on the child, not on the grid: `span 2` says the card
      // takes two of whatever tracks the grid laid out, and a browser clamps it to
      // the count the width gives.
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(gridSpan: 2),
      );

      expect(declarations.text, contains('grid-column:span 2'));
    });

    test('says nothing about a span a box does not state', () {
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(),
      );

      expect(declarations.text, isNot(contains('grid-column')));
    });

    test('keeps a shape with a ratio, written as the number', () {
      // `1.5` and not `3 / 2`: a browser divides the number, and both renderers have to
      // spell the same statement for the class names to agree.
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(aspectRatio: 1.5),
      );

      expect(declarations.text, contains('aspect-ratio:1.5'));
    });

    test('says nothing about a ratio a box does not state', () {
      final CssDeclarations declarations = boxDeclarations(
        const core.BoxStyle(),
      );

      expect(declarations.text, isNot(contains('aspect-ratio')));
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

  group('an overlay', () {
    test('bounds its content to the window and scrolls what does not fit', () {
      // A flex item that is taller than the box it is centred in simply grows past it, so
      // a dialog holding more than the window was as tall as its content here and no taller
      // than the window in Flutter — one node, two heights. The layer is the scrollport,
      // which is what the Flutter renderer draws with a scroll view over the same layer.
      final CssDeclarations layer = overlayDeclarations();

      expect(layer['position'], 'fixed');
      expect(layer['inset'], '0');
      expect(layer['display'], 'flex');
      expect(layer['overflow'], 'auto');
    });

    test(
      'places its content by a margin, so a tall one keeps its start edge',
      () {
        // An alignment keyword centres an item that is bigger than its box *outside* the box,
        // and the top of a dialog put there is above the scrollport where no scroll reaches.
        // Auto margins centre what fits and fall back to zero when it does not.
        expect(
          overlayContentDeclarations(core.OverlayAlignment.center).text,
          'margin-block-end:auto;margin-block-start:auto;margin-inline:auto;'
          'position:relative',
        );
        expect(
          overlayContentDeclarations(core.OverlayAlignment.top).text,
          contains('margin-block-end:auto;margin-block-start:0'),
        );
        expect(
          overlayContentDeclarations(core.OverlayAlignment.bottom).text,
          contains('margin-block-end:0;margin-block-start:auto'),
        );
      },
    );

    test('scrims the page from the window, so scrolling cannot carry it away', () {
      // An absolutely positioned scrim belongs to the layer's scrollable content: at the end
      // of a long dialog it would have scrolled off and left the page undimmed.
      expect(
        overlayBarrierDeclarations(const core.BoxColor(0x52000000))['position'],
        'fixed',
      );
    });
  });
}
