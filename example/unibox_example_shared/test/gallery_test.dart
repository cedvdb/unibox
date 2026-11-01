import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('the Material gallery', () {
    test('gives a segmented button the width its segments divide', () {
      // Measured at 375 and at 1440: the gallery's grid hands each of these buttons a
      // cell, so a button without a width is a 40 pixel pill hugging three shares at the
      // start of it — a control that occupies a third of the cell it was given. With a
      // width the shares divide the cell: 102, 102, 102 at 375 and 144, 144, 144 at 1440.
      final List<MaterialSegmentedButton> buttons = _nodesOf(
        buildMaterialSection(),
      ).whereType<MaterialSegmentedButton>().toList();

      expect(buttons, hasLength(2));
      for (final MaterialSegmentedButton button in buttons) {
        expect(button.width, double.infinity);
        final GridNode grid = button.children.single as GridNode;

        expect(
          grid.columns,
          <int>[1, 1, 1],
          reason: 'the three segments are columns of the pill, and equal ones',
        );
        expect(
          grid.children.whereType<Box>().where((Box box) => box.flex != null),
          isEmpty,
          reason: 'a column is the grid\'s answer, so no segment states a flex',
        );
      }
    });

    test('gives a layer that places every child a rectangle', () {
      // A layer has no size of its own: the catalogue's two phones place a whole screen and
      // nothing in their flow, so without a stated rectangle they were empty in the document
      // and drawn in the app — Flutter's stack takes the room it is handed, a browser's grid
      // collapses. The map, which places labels and pins, states one for the same reason.
      final List<StackNode> stacks = _nodesOf(buildMaterialSection())
          .whereType<StackNode>()
          .toList();

      expect(stacks, isNotEmpty);
      for (final StackNode stack in stacks) {
        if (stack.children.any((UINode child) => child is! PositionedNode)) {
          continue;
        }

        expect(
          stack.width,
          isNotNull,
          reason: 'the layer states its rectangle',
        );
        expect(
          stack.height,
          isNotNull,
          reason: 'the layer states its rectangle',
        );
      }
    });

    test('lets the rows of chips scroll rather than widen the page', () {
      // Four chips need 368 pixels and a phone's cell gives 311, so a row that neither
      // shrinks nor scrolls pushes the page sideways: the gallery measured a 400 pixel
      // document in a 375 pixel window before these rows scrolled.
      final List<Box> scrollers = _nodesOf(buildMaterialSection())
          .whereType<Box>()
          // The resolved overflow rather than the flat one: a pager is a scroller because of what
          // the node *is*, so it states no `overflow` of its own and still belongs in the count.
          .where((Box box) => box.computedStyle.overflow == Overflow.scroll)
          .toList();

      // Two rows of chips that overflow, two pagers, and the scrolling body of each of the two
      // screens. A pager scrolls for a different reason — it settles on a child — so it is
      // counted here and told apart below.
      expect(scrollers, hasLength(6));
      expect(_textsIn(scrollers.first), contains('Two rooms'));
      expect(_textsIn(scrollers[1]), contains('Garden'));

      final List<PagerNode> paged = scrollers.whereType<PagerNode>().toList();

      expect(paged, hasLength(2));
      // One is told which page it shows, and that is the one a press can move; the other is left to
      // the reader, which is what a pager is in a document.
      expect(
        paged.where((PagerNode pager) => pager.index != null),
        hasLength(1),
      );
      // The tabs come first in the catalogue, and theirs is the pager a press can move; the `Pages`
      // block is left to the reader, which is what a pager is in a document.
      expect(paged.first.index, 0);
      expect(paged.last.index, isNull);
      expect(_textsIn(paged.last), contains('Three'));
    });

    test('dresses its bars as app bars rather than hand-built boxes', () {
      final List<Box> nodes = _nodesOf(buildMaterialSection())
          .whereType<Box>()
          .toList();

      // Every bar in the catalogue is the component that draws one — the two screens' bars and
      // the ones the static specimens show — so nothing here teaches a reader to write the same
      // thing out of a `Box`. What makes a bar a bar here is the landmark it states.
      for (final Box bar in nodes.where(
        (Box box) => box.semantics?.element == BoxElement.header,
      )) {
        expect(bar, anyOf(isA<MaterialAppBar>(), isA<MaterialLargeAppBar>()));
      }

      // And the bars have specimens of their own, not only a part in a screen: two small bars, the
      // small one a screen holds, and two large ones — a specimen and the bar that collapses.
      expect(
        nodes.where((Box box) => box is MaterialAppBar && box.pin == null),
        hasLength(3),
      );
      expect(
        nodes.where((Box box) => box is MaterialLargeAppBar && box.pin == null),
        hasLength(2),
      );
    });

    test('frames its screens and its bars with a line and no shape', () {
      // A rounded frame that also clips cut the corners off what it held: the tab view lost
      // the page's hairline, and each screen lost the corners of the bar it opens with. The
      // line is the outline that says where a panel begins; a corner missing from it reads
      // as a cropped panel rather than as a shape.
      final List<Box> nodes = _nodesOf(buildMaterialSection())
          .whereType<Box>()
          .toList();

      // A bar's frame holds the bar. A screen's holds the plate that places the whole
      // screen, so the frame is the outlined box a scaffold is drawn in.
      final List<Box> bars = nodes
          .where(
            (Box box) =>
                box.children.length == 1 &&
                (box.children.single is MaterialAppBar ||
                    box.children.single is MaterialLargeAppBar),
          )
          .toList();
      final List<Box> screens = nodes
          .where((Box box) => box.border != null)
          .where(
            (Box box) =>
                _nodesOf(box).any((UINode node) => node is MaterialScaffold),
          )
          .toList();

      expect(bars, hasLength(3), reason: 'one frame per bar specimen');
      expect(screens, hasLength(2), reason: 'one frame per screen');

      for (final Box frame in <Box>[...bars, ...screens]) {
        expect(
          frame.borderRadius,
          isNull,
          reason: 'a rounded frame cuts the corners of what it holds',
        );
        expect(
          frame.overflow,
          isNot(Overflow.hidden),
          reason: 'a frame with nothing to round has nothing to clip',
        );
      }
    });

    test('keeps both screens’ bars outside the scroll', () {
      final List<UINode> nodes = _nodesOf(buildMaterialSection());
      final List<MaterialScaffold> screens = nodes
          .whereType<MaterialScaffold>()
          .toList();

      expect(screens, hasLength(2));

      // Both screens are the arrangement a Material app has: the bars are the scaffold's, and the
      // body is the only thing that scrolls. A pull past the list therefore opens *inside* the
      // body, where the page shows — never at an edge a bar has come away from.
      for (final MaterialScaffold screen in screens) {
        final Box body = screen.children[1] as Box;

        expect(screen.children.first, isA<Box>());
        expect(
          screen.children.first,
          anyOf(isA<MaterialAppBar>(), isA<MaterialLargeAppBar>()),
        );
        expect(body.overflow, Overflow.scroll);
        expect(body.flex, 1, reason: 'the body takes the room the bars leave');
        expect(
          screen.children.whereType<Box>().where((Box box) => box.pin != null),
          isEmpty,
          reason: 'a bar outside the scroll has no edge to come to rest at',
        );
      }

      // The first screen has the bottom bar too, which is the second slot and the reason a footer
      // is furniture rather than the last child of a list.
      expect(screens.first.children, hasLength(3));
      expect(screens.first.children.last, isA<NavigationDemo>());

      // And the bar of that screen draws no hairline: a line separates a bar from the content
      // scrolling under it, and nothing scrolls under a bar that is outside the scroll.
      expect(
        (screens.first.children.first as MaterialAppBar).border,
        isNull,
        reason: 'the container is what separates a bar a scaffold holds',
      );

      // Nothing in the catalogue pins: a pin is a bar that is content, and the screens are
      // furniture. The pinned bar is documented in `docs/nodes/box.md` and pinned by the renderer
      // suites, which scroll it.
      expect(
        nodes.whereType<Box>().where((Box box) => box.pin != null),
        isEmpty,
      );
    });

    test(
      'gives the app bar its height back a hundredth of a scroll at a time',
      () {
        // The screen opens with the bar at its full height, and the store turns any offset past the
        // range into the collapsed one — a layout change a rebuild states, which is the only way a
        // height moves here.
        final MaterialScaffold screen = _nodesOf(buildMaterialSection())
            .whereType<MaterialScaffold>()
            .singleWhere(
              (MaterialScaffold screen) =>
                  screen.children.first is MaterialLargeAppBar,
            );
        final MaterialLargeAppBar bar =
            screen.children.first as MaterialLargeAppBar;
        final Box body = screen.children[1] as Box;

        expect(bar.height, MaterialLargeAppBar.largeHeight);
        expect(
          body.onScroll,
          isNotNull,
          reason: 'the bar can only follow a scroll the body reports',
        );

        final CollapsingAppBarStore store = CollapsingAppBarStore();

        expect(store.state.progress, 0);
        store.scrolledTo(-40);
        expect(
          store.state.progress,
          0,
          reason: 'a pull past the top collapses nothing',
        );
        store.scrolledTo(CollapsingAppBarStore.range / 2);
        expect(store.state.progress, 0.5);
        store.scrolledTo(CollapsingAppBarStore.range * 3);
        expect(
          store.state.progress,
          1,
          reason: 'past the range the bar is as small as it goes',
        );

        // A hundredth is the resolution, so a fling does not redraw the screen for every pixel it
        // passes: the store publishes a state a reader could see, not a state a device produced.
        store.scrolledTo(0);
        store.scrolledTo(CollapsingAppBarStore.range / 3);
        expect(store.state.progress, 0.33);
      },
    );

    test(
      'draws the chosen segment with Material’s check, in place of its icon',
      () {
        final List<UINode> nodes = _nodesOf(buildMaterialSection());

        // The chosen chip and the chosen segment of each of the two buttons: three
        // marks, and no text glyph standing in for one.
        expect(nodes.whereType<MaterialCheckMark>(), hasLength(3));
        // A segment that is not chosen still draws its own icon.
        expect(
          _textsIn(buildMaterialSection()),
          containsAll(<String>['Grid', 'Map']),
        );
      },
    );

    test('draws its specimens in the seed the header chose', () {
      // The picker is in the page's header, because a palette is the whole page; what the
      // catalogue owes is that everything it shows is read out of that seed.
      final UINode section = buildMaterialSection(seed: ExampleSeed.rose);

      expect(_nodesOf(section).whereType<MaterialCard>().isEmpty, isFalse);
      expect(
        _nodesOf(section)
            .whereType<LinkNode>()
            .where((LinkNode link) => link.url.startsWith('?seed=')),
        isEmpty,
      );
    });

    test('raises one card at each of the six heights, on the tone it is tinted with', () {
      // Elevation is two values in Material, not one: the shadow a surface casts and
      // the tone it is tinted with. A card that took the shadow alone would be six cards
      // that look alike once a browser has blurred 12% black over the page's own tone, so
      // the catalogue pairs them — and this is the ladder, written down. The palette has
      // five container tones for six heights, so the top two share the highest one, and
      // the shadow is the only half that still tells them apart.
      final MaterialPalette palette = ExamplePalette.materialFor(
        ExampleSeed.defaultSeed,
      );
      final List<MaterialCard> cards = _nodesOf(buildMaterialSection())
          .whereType<MaterialCard>()
          .toList();

      MaterialCard titled(String title) => cards.singleWhere(
        (MaterialCard card) => _textsIn(card).contains(title),
      );

      final List<(String, List<BoxShadow>, BoxColor)>
      ladder = <(String, List<BoxShadow>, BoxColor)>[
        ('Level 0', MaterialElevation.level0, palette.surfaceContainerLowest),
        ('Level 1', MaterialElevation.level1, palette.surfaceContainerLow),
        ('Level 2', MaterialElevation.level2, palette.surfaceContainer),
        ('Level 3', MaterialElevation.level3, palette.surfaceContainerHigh),
        ('Level 4', MaterialElevation.level4, palette.surfaceContainerHighest),
        ('Level 5', MaterialElevation.level5, palette.surfaceContainerHighest),
      ];

      for (final (String title, List<BoxShadow> shadows, BoxColor tone)
          in ladder) {
        final MaterialCard card = titled(title);

        expect(
          card.backgroundColor,
          tone,
          reason: '$title sits on the tone Material pairs with it',
        );
        expect(
          card.shadows ?? const <BoxShadow>[],
          shadows,
          reason: '$title casts that level\'s shadow',
        );
      }

      // The two shapes beside the raised ones: one draws a line where the others draw a
      // tone, and neither casts anything — an empty list of shadows is that statement.
      final MaterialCard outlined = titled('Outlined');
      final MaterialCard filled = titled('Filled');

      expect(outlined.shadows, isEmpty);
      expect(
        outlined.border?.color,
        const BoxColor.role(MaterialColorRole.outlineVariant),
        reason: 'the outlined card is the one that draws a line instead of a shadow',
      );
      expect(filled.shadows, isEmpty);
      expect(
        filled.border,
        isNull,
        reason: 'the filled card is the one with neither a line nor a shadow',
      );
    });
  });
}

/// Every node of [root], depth first, with every stateful node's first frame drawn.
///
/// A [StatefulNode] has no children until a renderer mounts it — the labels of the
/// chips and of the segments live inside their ink wells — so a plain walk of the
/// tree stops at the control and sees nothing inside it.
List<UINode> _nodesOf(UINode root) {
  final List<UINode> nodes = <UINode>[root];

  if (root is StatefulNode<Object, Store<Object>>) {
    final Store<Object> store = root.createStore();
    nodes.addAll(_nodesOf(root.viewFor(store.state, store)));
    store.dispose();
  }
  for (final UINode child in root.children) {
    nodes.addAll(_nodesOf(child));
  }

  return nodes;
}

/// The text of every [TextNode] in [root], depth first, with stateful nodes mounted.
List<String> _textsIn(UINode root) =>
    _nodesOf(root)
        .whereType<TextNode>()
        .map((TextNode node) => node.text)
        .toList();
