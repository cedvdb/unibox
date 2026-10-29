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

    test('accepts a well formed tree', () {
      const Box tree = Box(
        direction: Axis.vertical,
        overflow: Overflow.scroll,
        children: <UINode>[
          TextNode('Hello'),
          LinkNode('https://unibox.dev', child: TextNode('Unibox')),
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
        child: Box(
          children: <UINode>[
            LinkNode('https://b.dev', child: TextNode('inner')),
          ],
        ),
      );

      final TreeIssue issue = validateTree(tree).single;

      expect(issue.node, isA<LinkNode>());
      expect(issue.severity, TreeIssueSeverity.error);
      expect(issue.isError, isTrue);
      expect(issue.message, contains('nested'));
    });

    test('accepts links that are siblings', () {
      const Box tree = Box(
        children: <UINode>[
          LinkNode('https://a.dev', child: TextNode('a')),
          LinkNode('https://b.dev', child: TextNode('b')),
        ],
      );

      expect(validateTree(tree), isEmpty);
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

    test('reads the tokens resolved from the style', () {
      const Box tree = Box(
        style: BoxStyle(
          overflow: Overflow.scroll,
          mainAlign: MainAlign.spaceBetween,
        ),
      );

      expect(validateTree(tree).single.message, contains('spaceBetween'));
    });

    test('collects the issues of every nested subtree', () {
      const Box tree = Box(
        children: <UINode>[
          Box(children: <UINode>[PositionedNode(top: 0, child: TextNode('a'))]),
          LinkNode(
            'https://a.dev',
            child: LinkNode('https://b.dev', child: TextNode('b')),
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
        const Box(shape: hexagon, shadow: BoxShadow()),
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
