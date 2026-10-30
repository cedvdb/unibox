import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _tap() {}

/// The ink well a tile is wrapped in.
MaterialInkWell _well(MaterialListTile tile) =>
    tile.children.single as MaterialInkWell;

/// The surface the well draws for its resting state: the tints, the ink and the
/// row. A stateful node's view is a function, so this is how a test reads it.
Box _surface(MaterialListTile tile) {
  final MaterialInkWell well = _well(tile);
  final Store<Object> store = well.createStore() as Store<Object>;

  return well.viewFor(store.state, store) as Box;
}

/// The column of text inside a tile, whether or not it has a leading node.
Box _textColumn(MaterialListTile tile) =>
    tile.row.children.firstWhere((UINode node) => node is Box) as Box;

void main() {
  group('MaterialListTile', () {
    test('is a row with the arrangement Material gives a tile', () {
      final tile = MaterialListTile(title: const TextNode('Ada'));

      expect(tile, isA<Box>());
      expect(tile.width, double.infinity);
      expect(tile.row.direction, Axis.horizontal);
      expect(tile.row.crossAlign, CrossAlign.center);
      expect(tile.row.gap, 16);
      expect(
        tile.row.padding,
        const BoxSpacing.symmetric(horizontal: 16, vertical: 8),
      );
      expect(tile.backgroundColor, isNull);
      expect(tile.row.children, hasLength(1));
    });

    test('takes the width it is given, and puts the trailing node at the end', () {
      final tile = MaterialListTile(
        leading: const TextNode('AL'),
        title: const TextNode('Ada Lovelace'),
        subtitle: const TextNode('ada@example.com'),
        trailing: const TextNode('2m'),
        onTap: _tap,
      );

      // The tile fills, the well fills the tile, and the row fills the well: a row
      // that sized itself to its content left the trailing node against the subtitle
      // instead of at the far edge of the surface it belongs to.
      expect(tile.width, double.infinity);
      expect(_surface(tile).width, double.infinity);
      expect(tile.row.width, double.infinity);
      // And the text column takes what the leading and trailing nodes leave, so
      // there is a gap for the trailing node to be pushed across.
      expect(
        tile.row.children
            .whereType<Box>()
            .map((Box box) => box.flex)
            .whereType<int>(),
        contains(1),
      );
    });

    test('sizes itself to the one line and two line heights of Material', () {
      final oneLine = MaterialListTile(title: const TextNode('Ada'));
      final twoLine = MaterialListTile(
        title: const TextNode('Ada'),
        subtitle: const TextNode('ada@example.com'),
      );
      final denseOneLine = MaterialListTile(
        title: const TextNode('Ada'),
        dense: true,
      );
      final denseTwoLine = MaterialListTile(
        title: const TextNode('Ada'),
        subtitle: const TextNode('ada@example.com'),
        dense: true,
      );

      expect(oneLine.row.minHeight, 56);
      expect(twoLine.row.minHeight, 72);
      expect(denseOneLine.row.minHeight, 48);
      expect(denseTwoLine.row.minHeight, 64);
    });

    test('lays the leading node, the text and the trailing node in a row', () {
      final tile = MaterialListTile(
        leading: const TextNode('AL'),
        title: const TextNode('Ada'),
        subtitle: const TextNode('ada@example.com'),
        trailing: const TextNode('2m'),
      );

      expect(tile.row.children, hasLength(3));
      expect((tile.row.children.first as TextNode).text, 'AL');
      expect(_textColumn(tile).children, hasLength(2));
      expect((tile.row.children.last as TextNode).text, '2m');
    });

    test('is wrapped in the ink well, so it ripples where it is pressed', () {
      final tile = MaterialListTile(title: const TextNode('Ada'), onTap: _tap);
      final Box surface = _surface(tile);

      expect(_well(tile), isA<MaterialInkWell>());
      // The ink needs the press, not just the tap: this is what turns a press into
      // a drop at the pointer.
      expect(surface.onTapDown, isNotNull);
      expect(surface.overflow, Overflow.hidden);
    });

    test('clips its tint to the radius it is given', () {
      final tile = MaterialListTile(
        title: const TextNode('Ada'),
        onTap: _tap,
        borderRadius: 12,
      );

      expect(_surface(tile).borderRadius, 12);
    });

    test('is a button only when it can be tapped', () {
      final resting = MaterialListTile(title: const TextNode('Ada'));
      final tappable = MaterialListTile(
        title: const TextNode('Ada'),
        onTap: _tap,
      );

      expect(_surface(resting).semantics, isNull);
      expect(_surface(resting).isFocusable, isFalse);
      expect(_surface(tappable).semantics?.role, BoxRole.button);
      expect(_surface(tappable).isFocusable, isTrue);
    });

    test('keeps the semantics it is given', () {
      final tile = MaterialListTile(
        title: const TextNode('Ada'),
        onTap: _tap,
        semantics: const BoxSemantics(role: BoxRole.link, label: 'Contact'),
      );
      final Box surface = _surface(tile);

      expect(surface.semantics?.role, BoxRole.link);
      expect(surface.semantics?.label, 'Contact');
    });

    test('tints itself on hover and press, and lets a caller replace it', () {
      final tile = MaterialListTile(title: const TextNode('Ada'));
      final themed = MaterialListTile(
        title: const TextNode('Ada'),
        hoverStyle: const BoxStyle(backgroundColor: BoxColors.blue),
      );

      expect(
        _surface(tile).stateStyle(BoxState.hover)?.backgroundColor,
        const BoxColor.role(MaterialColorRole.hoverLayer),
      );
      expect(
        _surface(tile).stateStyle(BoxState.pressed)?.backgroundColor,
        const BoxColor.role(MaterialColorRole.pressedLayer),
      );
      expect(
        _surface(themed).stateStyle(BoxState.hover)?.backgroundColor,
        BoxColors.blue,
      );
    });

    test('lets a caller replace every tile token', () {
      final tile = MaterialListTile(
        title: const TextNode('Ada'),
        subtitle: const TextNode('ada@example.com'),
        color: BoxColors.darkGrey,
        width: 320,
        padding: const BoxSpacing.all(8),
        gap: 8,
        minHeight: 40,
        titleStyle: const BoxTextStyle(fontSize: 18),
        subtitleStyle: const BoxTextStyle(fontSize: 12),
      );

      expect(tile.computedStyle.backgroundColor, BoxColors.darkGrey);
      expect(tile.computedStyle.width, 320);
      expect(tile.row.minHeight, 40);
      expect(tile.row.padding, const BoxSpacing.all(8));
      expect(tile.row.gap, 8);
      expect(_textColumn(tile).textStyle?.fontSize, 18);
      expect((_textColumn(tile).children.last as Box).textStyle?.fontSize, 12);
    });

    test(
      'keeps the title and the subtitle two pixels apart, or as close as asked',
      () {
        final MaterialListTile natural = MaterialListTile(
          title: const TextNode('Ada Lovelace'),
          subtitle: const TextNode('ada@example.com'),
        );
        final MaterialListTile tight = MaterialListTile(
          title: const TextNode('Ada Lovelace'),
          subtitle: const TextNode('ada@example.com'),
          textGap: 0,
        );

        expect(_textColumn(natural).gap, 2);
        expect(_textColumn(tight).gap, 0);
      },
    );

    test('is named for an inspector', () {
      expect(
        MaterialListTile(title: const TextNode('Ada')).debugName,
        'material-list-tile',
      );
    });
  });
}
