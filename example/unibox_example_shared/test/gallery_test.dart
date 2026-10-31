import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('the Material gallery', () {
    test('gives a segmented button the width its segments divide', () {
      // Measured at 375 and at 1440: the gallery's grid hands each of these buttons a
      // cell, so a button without a width is a 40 pixel pill stretched across it with
      // its segments hugging the left — two thirds of a control that is not there.
      // With a width, each segment takes an equal share: 102, 102, 102 at 375 and
      // 144, 144, 144 at 1440.
      final List<MaterialSegmentedButton> buttons = _nodesOf(
        buildMaterialSection(),
      ).whereType<MaterialSegmentedButton>().toList();

      expect(buttons, hasLength(2));
      for (final MaterialSegmentedButton button in buttons) {
        expect(button.width, double.infinity);
        expect(
          button.children.whereType<Box>().where((Box box) => box.flex == 1),
          hasLength(3),
          reason: 'three segments share the width, so the dividers take none',
        );
      }
    });

    test('lets the rows of chips scroll rather than widen the page', () {
      // Four chips need 368 pixels and a phone's cell gives 311, so a row that neither
      // shrinks nor scrolls pushes the page sideways: the gallery measured a 400 pixel
      // document in a 375 pixel window before these rows scrolled.
      final List<Box> scrollers = _nodesOf(buildMaterialSection())
          .whereType<Box>()
          .where((Box box) => box.overflow == Overflow.scroll)
          .toList();

      // Two rows of chips that overflow, two pagers, three pinned panels and three folding
      // ones. A pager scrolls for a different reason — it settles on a child — so it is
      // counted here and told apart below.
      expect(scrollers, hasLength(10));
      expect(_textsIn(scrollers.first), contains('Two rooms'));
      expect(_textsIn(scrollers[1]), contains('Garden'));

      final List<Box> paged = scrollers
          .where((Box box) => box.snap == ScrollSnap.page)
          .toList();

      expect(paged, hasLength(2));
      // One is told which page it shows, and that is the one a press can move; the other is left to
      // the reader, which is what a pager is in a document.
      expect(paged.where((Box box) => box.page != null), hasLength(1));
      // The tabs come first in the catalogue, and theirs is the pager a press can move; the `Pages`
      // block is left to the reader, which is what a pager is in a document.
      expect(paged.first.page, 0);
      expect(paged.last.page, isNull);
      expect(_textsIn(paged.last), contains('Three'));
    });

    test('dresses its bands as app bars rather than hand-built boxes', () {
      final List<Box> nodes = _nodesOf(buildMaterialSection())
          .whereType<Box>()
          .toList();

      // Every band in the catalogue is the component that draws one — a pinned bar, the bar a
      // fold leaves behind, the ones the static specimens show — so nothing here teaches a
      // reader to write the same thing out of a `Box`.
      for (final Box band in nodes.where((Box box) => box.pin != null)) {
        expect(band, isA<MaterialAppBar>());
      }
      for (final Box band in nodes.where((Box box) => box.fold != null)) {
        expect(band, anyOf(isA<MaterialAppBar>(), isA<MaterialLargeAppBar>()));
      }

      // And the bars have a specimen of their own, not only a part in the panels.
      expect(
        nodes.where(
          (Box box) =>
              box is MaterialAppBar && box.pin == null && box.fold == null,
        ),
        hasLength(2),
      );
      // Two large ones: the specimen, and the band the first pinned panel opens with.
      expect(
        nodes.where(
          (Box box) =>
              box is MaterialLargeAppBar && box.fold == null && box.pin == null,
        ),
        hasLength(2),
      );
    });

    test('shows a band at each edge, and one that stops under another', () {
      final List<UINode> nodes = _nodesOf(buildMaterialSection());
      final List<Box> pinned = nodes
          .whereType<Box>()
          .where((Box box) => box.pin != null)
          .toList();

      // Four bands across three panels: the toolbar under the hero, the pair that sits one
      // under the other, and the action bar at the end.
      expect(pinned, hasLength(4));
      expect(pinned.where((Box box) => box.pin == BoxPin.start), hasLength(3));
      expect(pinned.where((Box box) => box.pin == BoxPin.end), hasLength(1));
      expect(
        pinned.where((Box box) => (box.pinOffset ?? 0) == 0),
        hasLength(3),
        reason:
            'the toolbar, the filters and the action bar keep none of the edge',
      );
      expect(
        pinned.where((Box box) => (box.pinOffset ?? 0) > 0),
        hasLength(1),
        reason: 'one band stops under the band above it',
      );

      for (final Box band in pinned) {
        // The contract a band keeps: a stated height for its slot, a surface of its own,
        // and a parent that scrolls it.
        expect(band.height, isNotNull);
        expect(band.height!.isFinite, isTrue);
        expect(band.backgroundColor, isNotNull);

        final Box viewport = nodes.whereType<Box>().singleWhere(
          (Box box) => box.children.contains(band),
        );

        expect(viewport.overflow, Overflow.scroll);
        expect(viewport.height, isNotNull);
      }
    });

    test('uses a different paint and a different range for each fold', () {
      final List<Box> folded = _nodesOf(buildMaterialSection())
          .whereType<Box>()
          .where((Box box) => box.fold != null)
          .toList();

      expect(folded, hasLength(3));

      // Two bands fade and shrink over different shares of the same exit, so the range is
      // what a reader compares…
      final List<Box> fading = folded
          .where((Box box) => box.fold!.looks.contains(BoxProperty.transform))
          .toList();

      expect(fading, hasLength(2));
      expect(fading.map((Box box) => box.fold!.over).toSet(), <double>{
        1,
        0.4,
      }, reason: 'one fold runs the whole exit, the other finishes early');
      for (final Box box in fading) {
        expect(box.fold!.looks, contains(BoxProperty.opacity));
      }

      // …and the third moves a colour and nothing else, which is a paint neither of the others
      // touches: a tinted bar that arrives as the plain one.
      final Box tinted = folded.singleWhere(
        (Box box) =>
            !box.fold!.looks.contains(BoxProperty.opacity) &&
            box.fold!.looks.contains(BoxProperty.backgroundColor),
      );

      expect(tinted.fold!.to.backgroundColor, isNotNull);
      expect(tinted.backgroundColor, isNotNull);

      // A fold is for the box that leaves, so no band that stays carries one.
      for (final Box box in folded) {
        expect(box.pin, isNull);
      }
    });

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

    test('raises one card per level, on the surface Material tints with it', () {
      // Elevation is two values in Material, not one: the shadow a surface casts and
      // the tone it is tinted with. A card that took the shadow alone would be three
      // cards that look alike once a browser has blurred 12% black over the page's own
      // tone, so the catalogue pairs them — and this is the pair, written down.
      final MaterialPalette palette = ExamplePalette.materialFor(
        ExampleSeed.defaultSeed,
      );
      final List<MaterialCard> cards = _nodesOf(buildMaterialSection())
          .whereType<MaterialCard>()
          .toList();

      MaterialCard raised(List<BoxShadow> shadows) => cards.singleWhere(
        // The ambient layer names the level, and a `BoxShadow` compares by value.
        (MaterialCard card) => card.shadows?.lastOrNull == shadows.last,
      );

      expect(
        raised(MaterialElevation.level1).backgroundColor,
        palette.surfaceContainerLow,
      );
      expect(
        raised(MaterialElevation.level2).backgroundColor,
        palette.surfaceContainer,
      );
      expect(
        raised(MaterialElevation.level3).backgroundColor,
        palette.surfaceContainerHigh,
      );

      // The two shapes beside the raised one: one draws a line where the other draws a
      // tone, and neither casts anything — an empty list of shadows is that statement.
      bool castsNothing(MaterialCard card) => card.shadows?.isEmpty ?? true;

      expect(
        cards.where(
          (MaterialCard card) => castsNothing(card) && card.border != null,
        ),
        hasLength(1),
        reason: 'the outlined card is the one that draws a line instead of a shadow',
      );
      expect(
        cards.where(
          (MaterialCard card) => castsNothing(card) && card.border == null,
        ),
        hasLength(1),
        reason: 'the filled card is the one with neither',
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
