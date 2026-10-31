import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

void main() {
  group('validateTree', () {
    test('accepts a responsive image', () {
      const ImageNode image = ImageNode(
        'assets/logo.png',
        srcSet: <int, String>{200: 'logo-200.png', 400: 'logo-400.png'},
        sizes: '(min-width: 800px) 640px, 100vw',
        loading: ImageLoading.lazy,
        fetchPriority: ImageFetchPriority.high,
      );

      expect(validateTree(image), isEmpty);
    });

    test('reports an image candidate without a positive width', () {
      final List<TreeIssue> issues = validateTree(
        const ImageNode('assets/logo.png', srcSet: <int, String>{0: 'z.png'}),
      );

      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('positive'));
    });

    test('reports sizes that name no candidate', () {
      final List<TreeIssue> issues = validateTree(
        const ImageNode('assets/logo.png', sizes: '100vw'),
      );

      expect(issues.single.message, contains('without a srcSet'));
    });

    test('accepts a struck through price', () {
      expect(
        validateTree(
          const TextNode(
            '€1 200',
            decoration: TextDecoration.lineThrough,
            decorationColor: BoxColor.black,
            decorationThickness: 1,
          ),
        ),
        isEmpty,
      );
    });

    test('reports a decoration colour without a line to paint', () {
      // A colour and a thickness describe a line; with no decoration stated there
      // is none, and both renderers would write nothing at all.
      final List<TreeIssue> issues = validateTree(
        const TextNode('Terms', decorationColor: BoxColor.black),
      );

      expect(issues.single.message, contains('without a decoration'));
      expect(issues.single.isError, isFalse);
    });

    test('reports a decoration thickness without a line to draw', () {
      final List<TreeIssue> issues = validateTree(
        const TextNode('Terms', decorationThickness: 2),
      );

      expect(issues.single.message, contains('without a decoration'));
    });

    test('reports a decoration no line can be drawn with', () {
      final List<TreeIssue> issues = validateTree(
        const TextNode(
          'Terms',
          decoration: TextDecoration.underline,
          decorationThickness: 0,
        ),
      );

      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('more than zero'));
    });

    test('accepts a line a box states for the texts inside it', () {
      expect(
        validateTree(
          const Box(
            textStyle: BoxTextStyle(decoration: TextDecoration.underline),
            children: <UINode>[
              TextNode('Inside'),
              Box(children: <UINode>[TextNode('Deeper')]),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('reports a line stated by a box and again by a text inside it', () {
      // The two targets cannot agree: CSS propagates the box's line and lets the
      // text add another, while Flutter lets the text's style replace it.
      final List<TreeIssue> issues = validateTree(
        const Box(
          textStyle: BoxTextStyle(decoration: TextDecoration.underline),
          children: <UINode>[
            TextNode('Inside', decoration: TextDecoration.lineThrough),
          ],
        ),
      );

      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('State the line once'));
    });

    test('reports a decoration a box states with no line to draw', () {
      // The typography of a box is inherited by every text inside it, so a
      // thickness there is a token that does nothing just as much as one on a
      // text.
      final List<TreeIssue> issues = validateTree(
        const Box(
          textStyle: BoxTextStyle(decorationThickness: 2),
          children: <UINode>[TextNode('Inside')],
        ),
      );

      expect(issues.single.message, contains('without a decoration'));
    });

    test('accepts a pager', () {
      expect(
        validateTree(
          const Box(
            overflow: Overflow.scroll,
            snap: ScrollSnap.page,
            children: <UINode>[Box(width: 100), Box(width: 100)],
          ),
        ),
        isEmpty,
      );
    });

    test('reports a snap on a box that cannot scroll', () {
      // Nothing scrolls, so nothing settles: the token would be written and never read.
      final List<TreeIssue> issues = validateTree(
        const Box(snap: ScrollSnap.page),
      );

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('snap: ScrollSnap.page'));
    });

    test('reports a page on a box that does not snap', () {
      // A page is a position in a pager, so a box that settles nowhere has no pages to be on.
      final List<TreeIssue> issues = validateTree(
        const Box(overflow: Overflow.scroll, page: 1),
      );

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('page: 1'));
      expect(issues.single.message, contains('ScrollSnap.page'));
    });

    test('accepts a page on a pager', () {
      expect(
        validateTree(
          const Box(overflow: Overflow.scroll, snap: ScrollSnap.page, page: 1),
        ),
        isEmpty,
      );
    });

    test('accepts a pin inside a box that scrolls down', () {
      expect(
        validateTree(
          const Box(
            height: 400,
            overflow: Overflow.scroll,
            children: <UINode>[
              Box(height: 100),
              Box(height: 60, pin: BoxPin.start, pinOffset: 48),
              Box(height: 60, pin: BoxPin.end),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('accepts a pin at the top of a page, where the surface scrolls', () {
      // A server-rendered page scrolls the document, not a box, and the document is the
      // viewport a band at the top of the tree pins to. Nothing above it in the tree is a
      // reason to report it.
      expect(
        validateTree(
          const Box(
            height: 200,
            children: <UINode>[Box(height: 56, pin: BoxPin.start)],
          ),
        ),
        isEmpty,
      );
    });

    test('reports a pin inside a box that scrolls sideways', () {
      final List<TreeIssue> issues = validateTree(
        const Box(
          direction: Axis.horizontal,
          overflow: Overflow.scroll,
          children: <UINode>[Box(width: 60, height: 20, pin: BoxPin.start)],
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('scrolls sideways'));
      expect(issues.single.isError, isTrue);
    });

    test('reports a pin inside a box that only clips', () {
      // A browser makes a scroll container of any overflow but `visible`, so the band would
      // pin to a viewport that never moves; Flutter has no viewport there at all.
      final List<TreeIssue> issues = validateTree(
        const Box(
          overflow: Overflow.hidden,
          children: <UINode>[Box(height: 60, pin: BoxPin.start)],
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('Overflow.hidden'));
      expect(issues.single.isError, isTrue);
    });

    test('reports a pinned box with no height to keep its slot', () {
      // The band is drawn over its viewport and the flow keeps its room, so the height is
      // what holds the children below it still.
      final List<TreeIssue> issues = validateTree(
        const Box(
          height: 400,
          overflow: Overflow.scroll,
          children: <UINode>[Box(pin: BoxPin.end)],
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('without a finite height'));
      expect(issues.single.isError, isTrue);
    });

    test('reports a pin that is not a child of the box that scrolls it', () {
      // A band is drawn by the box that scrolls it, over that box's own viewport: from one
      // level down the flow already has a parent, and a browser would pin the band inside
      // that parent rather than to the edge of the viewport.
      final List<TreeIssue> issues = validateTree(
        const Box(
          height: 400,
          overflow: Overflow.scroll,
          children: <UINode>[
            Box(
              padding: BoxSpacing.all(8),
              children: <UINode>[Box(height: 60, pin: BoxPin.start)],
            ),
          ],
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.isError, isTrue);
      expect(
        issues.single.message,
        contains('child of the box that scrolls it'),
      );
    });

    test('reports a pinned box that asks for a share of the box', () {
      // A band keeps the height it states — that is the slot the flow holds open — while a
      // browser would grow it with the free space it has.
      final List<TreeIssue> issues = validateTree(
        const Box(
          height: 400,
          overflow: Overflow.scroll,
          children: <UINode>[Box(height: 60, pin: BoxPin.start, flex: 1)],
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('flex: 1'));
    });

    test('reports a negative inset', () {
      final List<TreeIssue> issues = validateTree(
        const Box(
          height: 400,
          overflow: Overflow.scroll,
          children: <UINode>[Box(height: 60, pin: BoxPin.start, pinOffset: -8)],
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('pinOffset of -8.0'));
    });

    test('reports an inset with no pin to hold it', () {
      final List<TreeIssue> issues = validateTree(const Box(pinOffset: 8));

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('without a pin'));
      expect(issues.single.isError, isFalse);
    });

    test('accepts a hero that folds as it leaves', () {
      expect(
        validateTree(
          const Box(
            height: 400,
            overflow: Overflow.scroll,
            children: <UINode>[
              Box(
                height: 132,
                fold: BoxFold(
                  to: BoxStyle(
                    opacity: 0,
                    transform: BoxTransform(scale: 0.75),
                  ),
                  curve: BoxCurve.easeOut,
                  over: 0.75,
                ),
              ),
              Box(height: 60, pin: BoxPin.start),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('reports a fold that names a layout token', () {
      // A layout that eases moves everything around the box on every frame, and the two engines
      // would draw a different picture in between: a fold is paint only.
      final List<TreeIssue> issues = validateTree(
        const Box(
          height: 132,
          fold: BoxFold(to: BoxStyle(height: 56, padding: BoxSpacing.all(8))),
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('height, padding'));
      expect(issues.single.message, contains('paint only'));
    });

    test('reports a fold that names no look', () {
      final List<TreeIssue> issues = validateTree(
        const Box(height: 132, fold: BoxFold(to: BoxStyle())),
      );

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('names no look'));
    });

    test('reports a fold that takes more than the whole exit', () {
      final List<TreeIssue> issues = validateTree(
        const Box(
          height: 132,
          fold: BoxFold(to: BoxStyle(opacity: 0), over: 2),
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('over 2.0'));
    });

    test('reports a box that both pins and folds', () {
      // A pinned band stays at the edge of its viewport, so its own exit never begins.
      final List<TreeIssue> issues = validateTree(
        const Box(
          height: 400,
          overflow: Overflow.scroll,
          children: <UINode>[
            Box(
              height: 60,
              pin: BoxPin.start,
              fold: BoxFold(to: BoxStyle(opacity: 0)),
            ),
          ],
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('opposite journeys'));
    });

    test('reports a fold that changes a border width', () {
      // A border width is layout in a browser and paint in Flutter, which is the one property
      // no animation here may touch.
      final List<TreeIssue> issues = validateTree(
        const Box(
          height: 132,
          border: BoxBorder(color: BoxColor.white),
          fold: BoxFold(to: BoxStyle(border: BoxBorder(width: 2))),
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('only its colour eases'));
    });

    test('reports a fold and a transition over the same look', () {
      final List<TreeIssue> issues = validateTree(
        const Box(
          height: 132,
          transition: BoxTransition(
            duration: Duration(milliseconds: 150),
            parts: <BoxTransitionPart>[
              BoxTransitionPart(
                properties: <BoxProperty>{BoxProperty.opacity},
                duration: Duration(milliseconds: 120),
              ),
            ],
          ),
          fold: BoxFold(to: BoxStyle(opacity: 0)),
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('opacity'));
    });

    test('accepts a well formed tree', () {
      const Box tree = Box(
        direction: Axis.vertical,
        overflow: Overflow.scroll,
        children: <UINode>[
          TextNode('Hello'),
          LinkNode(
            'https://unibox.dev',
            children: <UINode>[TextNode('Unibox')],
          ),
          StackNode(
            children: <UINode>[
              PositionedNode(top: 0, left: 0, child: TextNode('badge')),
            ],
          ),
          Box(children: <UINode>[TextInputNode(placeholder: 'Email')]),
        ],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('accepts a list item inside a list', () {
      const Box tree = Box(
        semantics: BoxSemantics(element: BoxElement.ul),
        children: <UINode>[
          Box(
            semantics: BoxSemantics(element: BoxElement.li),
            children: <UINode>[TextNode('One')],
          ),
        ],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('reports a list item outside a list', () {
      const Box tree = Box(
        children: <UINode>[
          Box(
            semantics: BoxSemantics(element: BoxElement.li),
            children: <UINode>[TextNode('One')],
          ),
        ],
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.severity, TreeIssueSeverity.error);
      expect(issue.message, contains('BoxElement.ul'));
      expect(issue.message, contains('invalid HTML'));
    });

    test('reports a transition declared in a state style', () {
      const Box tree = Box(
        stateStyles: <BoxState, BoxStyle>{
          BoxState.hover: BoxStyle(
            backgroundColor: BoxColor.black,
            transition: BoxTransition(duration: Duration(milliseconds: 150)),
          ),
        },
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.severity, TreeIssueSeverity.warning);
      expect(issue.message, contains('hover'));
      expect(issue.message, contains('transition'));
    });

    test('reports a transition that changes nothing', () {
      const Box tree = Box(transition: BoxTransition(duration: Duration.zero));

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.message, contains('positive duration'));
    });

    test('reports an opacity outside the visible range', () {
      const Box tree = Box(opacity: 1.5);

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.message, contains('opacity of 1.5'));
      expect(issue.message, contains('0 to 1'));
    });

    test('accepts a transition that eases one part before another', () {
      const Box tree = Box(
        transition: BoxTransition(
          duration: Duration(milliseconds: 200),
          parts: <BoxTransitionPart>[
            BoxTransitionPart(
              properties: BoxProperty.paint,
              duration: Duration(milliseconds: 100),
            ),
            BoxTransitionPart(
              properties: <BoxProperty>{BoxProperty.transform},
              duration: Duration(milliseconds: 150),
              delay: Duration(milliseconds: 100),
            ),
          ],
        ),
      );

      expect(validateTree(tree), isEmpty);
    });

    test('reports a part that names no look', () {
      const Box tree = Box(
        transition: BoxTransition(
          duration: Duration(milliseconds: 100),
          parts: <BoxTransitionPart>[
            BoxTransitionPart(
              properties: <BoxProperty>{},
              duration: Duration(milliseconds: 100),
            ),
          ],
        ),
      );

      expect(validateTree(tree).single.message, contains('names no look'));
    });

    test('reports a look eased by two parts', () {
      const Box tree = Box(
        transition: BoxTransition(
          duration: Duration(milliseconds: 100),
          parts: <BoxTransitionPart>[
            BoxTransitionPart(
              properties: <BoxProperty>{BoxProperty.opacity},
              duration: Duration(milliseconds: 100),
            ),
            BoxTransitionPart(
              properties: <BoxProperty>{BoxProperty.opacity},
              duration: Duration(milliseconds: 50),
            ),
          ],
        ),
      );

      expect(validateTree(tree).single.message, contains('ambiguous'));
    });

    test('reports paint that eases at two speeds', () {
      // A single decoration interpolates as a unit on Flutter, so the paint has to
      // share one timing; the fix is to nest a box, not to approximate.
      const Box tree = Box(
        transition: BoxTransition(
          duration: Duration(milliseconds: 200),
          parts: <BoxTransitionPart>[
            BoxTransitionPart(
              properties: <BoxProperty>{BoxProperty.backgroundColor},
              duration: Duration(milliseconds: 100),
            ),
            BoxTransitionPart(
              properties: <BoxProperty>{BoxProperty.borderColor},
              duration: Duration(milliseconds: 200),
            ),
          ],
        ),
      );

      expect(validateTree(tree).single.message, contains('eases as one'));
    });

    test('accepts a caption inside a figure', () {
      const Box tree = Box(
        semantics: BoxSemantics(element: BoxElement.figure),
        children: <UINode>[
          Box(
            semantics: BoxSemantics(element: BoxElement.figcaption),
            children: <UINode>[TextNode('The old town')],
          ),
        ],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('reports a caption outside a figure', () {
      const Box tree = Box(
        children: <UINode>[
          Box(
            semantics: BoxSemantics(element: BoxElement.figcaption),
            children: <UINode>[TextNode('The old town')],
          ),
        ],
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.severity, TreeIssueSeverity.error);
      expect(issue.message, contains('BoxElement.figure'));
      expect(issue.message, contains('invalid HTML'));
    });

    test('reports an embed without an implementation', () {
      const Box tree = Box(children: <UINode>[_EmptyEmbed()]);

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.severity, TreeIssueSeverity.error);
      expect(issue.message, contains('carries no implementation'));
    });

    test('reaches the child an embed wraps', () {
      const Box tree = Box(
        children: <UINode>[
          _WrappingEmbed(child: PositionedNode(top: 0, child: TextNode('x'))),
        ],
      );

      // The child of an embed is content like any other, so a node validation
      // rejects is reported even when an embed holds it.
      expect(validateTree(tree).single.message, contains('StackNode'));
    });

    test('warns about a positioned node outside a stack', () {
      const Box tree = Box(
        children: <UINode>[PositionedNode(top: 8, child: TextNode('badge'))],
      );

      final List<TreeIssue> issues = validateTree(tree);

      expect(issues, hasLength(1));
      final TreeIssue issue = issues.single;
      expect(issue.node, isA<PositionedNode>());
      expect(issue.severity, TreeIssueSeverity.warning);
      expect(issue.isError, isFalse);
      expect(issue.message, contains('StackNode'));
      expect(issue.message, contains('Box'));
    });

    test('names the root as the parent of a lone positioned node', () {
      const PositionedNode tree = PositionedNode(
        top: 8,
        child: TextNode('badge'),
      );

      expect(validateTree(tree).single.message, contains('the root'));
    });

    test('errors on a link nested in a link', () {
      const LinkNode tree = LinkNode(
        'https://a.dev',
        children: <UINode>[
          LinkNode('https://b.dev', children: <UINode>[TextNode('inner')]),
        ],
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.node, isA<Box>());
      expect(issue.severity, TreeIssueSeverity.error);
      expect(issue.isError, isTrue);
      expect(issue.message, contains('nested'));
    });

    test('accepts links that are siblings', () {
      const Box tree = Box(
        children: <UINode>[
          LinkNode('https://a.dev', children: <UINode>[TextNode('a')]),
          LinkNode('https://b.dev', children: <UINode>[TextNode('b')]),
        ],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('errors on a link inside another one', () {
      const LinkNode tree = LinkNode(
        '/rooms',
        children: <UINode>[
          LinkNode('/rooms/1', children: <UINode>[TextNode('One')]),
        ],
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.node, isA<Box>());
      expect(issue.isError, isTrue);
      expect(issue.message, contains('nested'));
    });

    test('errors on a control inside a link', () {
      const LinkNode tree = LinkNode(
        '/rooms',
        children: <UINode>[
          Box(onTap: _noop, children: <UINode>[TextNode('Remove')]),
        ],
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.isError, isTrue);
      expect(issue.message, contains('interactive content'));
    });

    test('accepts a link around plain content', () {
      const LinkNode tree = LinkNode(
        '/rooms',
        children: <UINode>[TextNode('Meeting room'), ImageNode('room.png')],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('accepts a link that names the anchor it already is', () {
      const LinkNode tree = LinkNode(
        '/rooms',
        semantics: BoxSemantics(element: BoxElement.a),
      );

      expect(validateTree(tree), isEmpty);
    });

    test('errors on a link that is a landmark as well', () {
      const LinkNode tree = LinkNode(
        '/rooms',
        semantics: BoxSemantics(element: BoxElement.article),
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.isError, isTrue);
      expect(issue.message, contains('article'));
    });

    test('warns about mainAlign on a box that scrolls', () {
      const Box tree = Box(
        overflow: Overflow.scroll,
        mainAlign: MainAlign.center,
        children: <UINode>[TextNode('Hello')],
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.node, same(tree));
      expect(issue.message, contains('mainAlign: center'));
    });

    test('accepts mainAlign start on a box that scrolls', () {
      const Box tree = Box(
        overflow: Overflow.scroll,
        mainAlign: MainAlign.start,
      );

      expect(validateTree(tree), isEmpty);
    });

    test('accepts a wrap that starts, centres or ends its children', () {
      for (final CrossAlign align in <CrossAlign>[
        CrossAlign.start,
        CrossAlign.center,
        CrossAlign.end,
      ]) {
        final Box tree = Box(
          direction: Axis.horizontal,
          wrap: true,
          gap: 8,
          crossAlign: align,
          children: const <UINode>[TextNode('Garden'), TextNode('Balcony')],
        );

        expect(
          validateTree(tree),
          isEmpty,
          reason: 'crossAlign: ${align.name}',
        );
      }
    });

    test('reports a wrap that stretches or baselines its children', () {
      // A browser states both for the children of one line; a Flutter `Wrap` starts,
      // centres or ends them and nothing else. One tree, two layouts.
      for (final CrossAlign align in <CrossAlign>[
        CrossAlign.stretch,
        CrossAlign.baseline,
      ]) {
        final Box tree = Box(
          direction: Axis.horizontal,
          wrap: true,
          crossAlign: align,
          children: const <UINode>[TextNode('a')],
        );
        final List<TreeIssue> issues = validateTree(tree);

        expect(
          issues.map((TreeIssue issue) => issue.message).join(),
          contains('CrossAlign.${align.name}'),
          reason: 'a wrap cannot say ${align.name} on both targets',
        );
      }
    });

    test('reports a box that both wraps and scrolls', () {
      const Box tree = Box(
        direction: Axis.horizontal,
        wrap: true,
        overflow: Overflow.scroll,
        children: <UINode>[TextNode('Garden')],
      );
      final TreeIssue issue = validateTree(tree).single;

      expect(issue.isError, isTrue);
      expect(issue.message, contains('wraps its children and scrolls'));
    });

    test('reports a flexible child of a wrapping box', () {
      const Box tree = Box(
        direction: Axis.horizontal,
        wrap: true,
        children: <UINode>[Box(flex: 1, height: 20)],
      );
      final TreeIssue issue = validateTree(tree).single;

      expect(issue.node, same(tree.children.single));
      expect(issue.isError, isTrue);
      expect(issue.message, contains('flex: 1'));
    });

    test('accepts a row whose children are equal shares', () {
      // The tree a segmented button is: one row, every child a share of it, and nothing on
      // a child that would answer the question the row has already answered.
      expect(
        validateTree(
          const Box(
            direction: Axis.horizontal,
            equalShares: true,
            children: <UINode>[
              Box(backgroundColor: BoxColor.white),
              Box(backgroundColor: BoxColor.black),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('reports shares in a column', () {
      // A share is a width divided between the children, and a column divides a height:
      // the browser would build the grid anyway and the app would measure the other axis.
      const Box tree = Box(equalShares: true, children: <UINode>[Box(), Box()]);
      final TreeIssue issue = validateTree(tree).single;

      expect(issue.isError, isTrue);
      expect(issue.message, contains('equalShares without direction'));
    });

    test('reports a box that both shares and wraps its children', () {
      const Box tree = Box(
        direction: Axis.horizontal,
        equalShares: true,
        wrap: true,
        children: <UINode>[Box(), Box()],
      );
      final TreeIssue issue = validateTree(tree).single;

      expect(issue.isError, isTrue);
      expect(issue.message, contains('wraps its children'));
    });

    test('reports a child of equal shares that states a flex or a width', () {
      // Both are a second answer to the share the row measured: a browser ignores the flex
      // on a grid item and honours a width inside a track, where Flutter expands every
      // share to the same tight width, so the two targets would draw two layouts.
      for (final Box child in <Box>[
        const Box(flex: 2),
        const Box(width: 40),
        const Box(widthFraction: 0.5),
      ]) {
        final Box tree = Box(
          direction: Axis.horizontal,
          equalShares: true,
          children: <UINode>[child, const Box()],
        );
        final TreeIssue issue = validateTree(tree).single;

        expect(issue.node, same(child));
        expect(issue.isError, isTrue);
      }
    });

    test('reports a full-width box inside a row that scrolls', () {
      // The consumer's crash: a box that fills its width in a row that scrolls along it.
      // Flutter throws `BoxConstraints forces an infinite width` during layout, and the
      // browser resolves the same `100%` against the scrollport's content.
      const Box tree = Box(
        direction: Axis.horizontal,
        overflow: Overflow.scroll,
        children: <UINode>[Box(width: double.infinity, height: 40)],
      );
      final TreeIssue issue = validateTree(tree).single;

      expect(issue.node, same(tree.children.single));
      expect(issue.isError, isTrue);
      expect(issue.message, contains('width: double.infinity'));
      expect(issue.message, contains('Box'));
      expect(issue.message, contains('scrolls along that axis'));
    });

    test('reports a full-height box inside a column that scrolls', () {
      const Box tree = Box(
        overflow: Overflow.scroll,
        children: <UINode>[Box(height: double.infinity)],
      );
      final TreeIssue issue = validateTree(tree).single;

      expect(issue.message, contains('height: double.infinity'));
      expect(issue.message, contains('scrolls along that axis'));
    });

    test('reports a full-height box used as an overlay content', () {
      // An overlay's content is laid out in a scrollport the size of the window on both
      // targets — the web's layer bounds it and Flutter draws it in a scroll view — so a
      // dialog that fills its height has nothing to fill and asks for infinite room.
      const OverlayNode tree = OverlayNode(
        onDismiss: _noop,
        child: Box(height: double.infinity),
      );
      final TreeIssue issue = validateTree(tree).single;

      expect(issue.node, same(tree.child));
      expect(issue.isError, isTrue);
      expect(issue.message, contains('height: double.infinity'));
    });

    test('accepts a dialog taller than the window as an overlay content', () {
      // The height a dialog states is its own; the room it is drawn in is what bounds it.
      const OverlayNode tree = OverlayNode(
        onDismiss: _noop,
        child: Box(width: 280, height: 900),
      );

      expect(validateTree(tree), isEmpty);
    });

    test('reports a full-width box a flex parent passes no width to', () {
      // The row is not scrolling itself; it was handed no end by the row above it, and a
      // flex hands its children what it was handed.
      const Box tree = Box(
        direction: Axis.horizontal,
        overflow: Overflow.scroll,
        children: <UINode>[
          Box(
            direction: Axis.vertical,
            children: <UINode>[Box(width: double.infinity)],
          ),
        ],
      );
      final TreeIssue issue = validateTree(tree)
          .where((TreeIssue issue) => issue.message.contains('double.infinity'))
          .single;

      expect(issue.message, contains('no end on that axis'));
    });

    test('accepts a full-width box in a bounded parent', () {
      const Box tree = Box(
        direction: Axis.horizontal,
        children: <UINode>[
          Box(width: double.infinity),
          Box(height: 20),
        ],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('accepts a finite box inside a row that scrolls', () {
      const Box tree = Box(
        direction: Axis.horizontal,
        overflow: Overflow.scroll,
        children: <UINode>[Box(width: 200, height: 40)],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('accepts a full-height box in a row that scrolls across it', () {
      // The axis is the whole rule: a row that scrolls gives its children no *width*, and
      // the height is the row's own, which has an end.
      const Box tree = Box(
        direction: Axis.horizontal,
        height: 40,
        overflow: Overflow.scroll,
        children: <UINode>[Box(width: 200, height: double.infinity)],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('accepts a full-width box in a grid that has no width of its own', () {
      // A grid gives every child a measured track whatever it was handed: the count comes
      // from `minItemWidth` and the width from the tracks, so a card may fill its cell.
      const GridNode tree = GridNode(
        minItemWidth: 200,
        children: <UINode>[Box(width: double.infinity, height: 40)],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('reports a baseline alignment on a column', () {
      // A baseline is a horizontal line: Flutter lays a column out as if the value
      // were start, and a browser shifts the children sideways. Nothing can draw both.
      const Box tree = Box(
        crossAlign: CrossAlign.baseline,
        children: <UINode>[TextNode('a'), TextNode('b')],
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.node, same(tree));
      expect(issue.isError, isTrue);
      expect(issue.message, contains('CrossAlign.baseline'));
    });

    test('accepts a baseline alignment on a row of text', () {
      const Box tree = Box(
        direction: Axis.horizontal,
        crossAlign: CrossAlign.baseline,
        children: <UINode>[TextNode('label'), TextNode('price')],
      );

      expect(validateTree(tree), isEmpty);
    });

    test('warns about a ratio next to a width and a height', () {
      // Both sides are stated, so the ratio has nothing left to divide: the two
      // renderers keep the sizes and drop it, and the tree says something no reader
      // of the screen can see.
      const Box tree = Box(width: 320, height: 200, aspectRatio: 1.5);

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.node, same(tree));
      expect(issue.message, contains('aspectRatio: 1.5'));
    });

    test('accepts a ratio beside one side', () {
      // The ratio divides the width it is given, which is what it is for.
      const Box tree = Box(width: 320, aspectRatio: 1.5);

      expect(validateTree(tree), isEmpty);
    });

    test('reports a ratio that is not positive', () {
      const Box tree = Box(aspectRatio: 0);

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.isError, isTrue);
      expect(issue.message, contains('aspectRatio: 0'));
    });

    test('reads the tokens resolved from the style', () {
      const Box tree = Box(
        styles: <BoxStyle>[
          BoxStyle(
            overflow: Overflow.scroll,
            mainAlign: MainAlign.spaceBetween,
          ),
        ],
      );

      expect(validateTree(tree).single.message, contains('spaceBetween'));
    });

    test('collects the issues of every nested subtree', () {
      const Box tree = Box(
        children: <UINode>[
          Box(children: <UINode>[PositionedNode(top: 0, child: TextNode('a'))]),
          LinkNode(
            'https://a.dev',
            children: <UINode>[
              LinkNode('https://b.dev', children: <UINode>[TextNode('b')]),
            ],
          ),
        ],
      );

      expect(
        validateTree(tree).map((TreeIssue issue) => issue.severity),
        <TreeIssueSeverity>[TreeIssueSeverity.warning, TreeIssueSeverity.error],
      );
    });

    test('describes the issue as its message', () {
      const Box tree = Box(overflow: Overflow.scroll, mainAlign: MainAlign.end);

      expect(
        validateTree(tree).single.toString(),
        validateTree(tree).single.message,
      );
    });
  });

  group('aligned placement', () {
    test('accepts a child placed by an alignment', () {
      const UINode stack = StackNode(
        children: <UINode>[
          Box(width: double.infinity, height: 200),
          PositionedNode(
            alignment: BoxAlignment.bottomCenter,
            child: TextNode('Open the map'),
          ),
        ],
      );

      expect(validateTree(stack), isEmpty);
    });

    test('reports an alignment and an offset on one node', () {
      final List<TreeIssue> issues = validateTree(
        const StackNode(
          children: <UINode>[
            PositionedNode(
              bottom: 24,
              alignment: BoxAlignment.bottomCenter,
              child: TextNode('Open the map'),
            ),
          ],
        ),
      );

      expect(issues.single.message, contains('not by both'));
    });
  });

  group('shapes', () {
    const BoxShape hexagon = BoxShape(
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      commands: <BoxPathCommand>[BoxPathMoveTo(0, 0), BoxPathClose()],
    );

    test('accepts a shaped box that names no rectangle', () {
      expect(validateTree(const Box(shape: hexagon)), isEmpty);
    });

    test('reports a shape and a corner radius together', () {
      final List<TreeIssue> issues = validateTree(
        const Box(shape: hexagon, borderRadius: 8),
      );

      expect(issues.single.message, contains('one outline'));
    });

    test('reports a shape and a shadow, which the model cannot draw', () {
      final List<TreeIssue> issues = validateTree(
        const Box(shape: hexagon, shadows: <BoxShadow>[BoxShadow()]),
      );

      expect(issues.single.message, contains('shadow'));
    });

    test('reports a shape with no command', () {
      final List<TreeIssue> issues = validateTree(
        const Box(
          shape: BoxShape(
            viewBoxWidth: 10,
            viewBoxHeight: 10,
            commands: <BoxPathCommand>[],
          ),
        ),
      );

      expect(issues.single.message, contains('no command'));
    });

    test('accepts a capped border on a shaped box', () {
      expect(
        validateTree(
          const Box(
            shape: BoxShape.circle,
            border: BoxBorder(cap: BoxStrokeCap.round),
          ),
        ),
        isEmpty,
      );
    });

    test('reports a cap on a rectangle, which has no ends to cap', () {
      final List<TreeIssue> issues = validateTree(
        const Box(border: BoxBorder(cap: BoxStrokeCap.round)),
      );

      expect(issues.single.message, contains('cap'));
    });

    test('reports a view box with no size', () {
      final List<TreeIssue> issues = validateTree(
        const Box(
          shape: BoxShape(
            viewBoxWidth: 0,
            viewBoxHeight: 100,
            commands: <BoxPathCommand>[BoxPathMoveTo(0, 0), BoxPathClose()],
          ),
        ),
      );

      expect(issues.single.message, contains('view box'));
    });
  });

  group('visibility', () {
    test('accepts a threshold inside a box', () {
      expect(
        validateTree(
          const Box(width: 800, children: <UINode>[Box(visibleFrom: 900)]),
        ),
        isEmpty,
      );
    });

    test('reports a range no width can show', () {
      final List<TreeIssue> issues = validateTree(
        const Box(children: <UINode>[Box(visibleFrom: 900, visibleUntil: 900)]),
      );

      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('empty'));
    });

    test('reports a threshold below zero', () {
      final List<TreeIssue> issues = validateTree(
        const Box(children: <UINode>[Box(visibleUntil: -1)]),
      );

      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('below zero'));
    });

    test('reports a threshold with no box to measure', () {
      final List<TreeIssue> issues = validateTree(const Box(visibleFrom: 900));

      expect(issues.single.message, contains('not inside another box'));
    });
  });
}

/// A press that does nothing: a control inside a link is the construct under test, and
/// what it does is not.
void _noop() {}

/// An embed that carries nothing, which no renderer can draw.
final class _EmptyEmbed extends EmbedNode {
  const _EmptyEmbed();

  @override
  List<Object> get implementations => const <Object>[];
}

/// An embed that wraps a child it does not draw itself.
final class _WrappingEmbed extends EmbedNode {
  const _WrappingEmbed({required super.child});

  @override
  List<Object> get implementations => const <Object>['widget'];
}
