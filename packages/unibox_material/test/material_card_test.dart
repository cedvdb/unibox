import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('MaterialCard', () {
    test('is a box with the defaults Material gives a card', () {
      const card = MaterialCard();

      expect(card, isA<Box>());
      // No padding: Flutter's `Card` has none either, and a card that padded would have a
      // ring no press inside it can reach. Null rather than a zero, so the rule declares
      // nothing at all.
      expect(card.padding, isNull);
      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerLow),
      );
      expect(card.borderRadius, 12);
      expect(card.shadows, MaterialCard.elevatedShadows);
      expect(card.border, isNull);
      expect(card.textStyle, MaterialTypography.bodyMedium);
      expect(card.children, isEmpty);
    });

    test('draws the ladder\'s level one, not a stack of layers', () {
      const List<BoxShadow> shadows = MaterialCard.elevatedShadows;

      // The table in `material_elevation.dart`: one shade at 34% black, one height. A card
      // that stacked three layers read a level higher than the card in the design file,
      // which is what the ladder replaced.
      expect(shadows, hasLength(1));
      expect(shadows.single.offsetY, 0.55);
      expect(shadows.single.blurRadius, 0.61);
      expect(shadows.single.spreadRadius, 0);
      expect(shadows.single.color.opacity, closeTo(0.34, 0.01));
    });

    test('keeps the children it is given, in order', () {
      const card = MaterialCard(
        children: <UINode>[TextNode('Order summary'), TextNode('Total')],
      );

      expect(card.children, hasLength(2));
      expect((card.children.first as TextNode).text, 'Order summary');
      expect((card.children.last as TextNode).text, 'Total');
    });

    test('lets a caller replace every card token', () {
      const card = MaterialCard(
        padding: BoxSpacing.all(8),
        color: BoxColors.lightGrey,
        borderRadius: 0,
        shadows: null,
        border: BoxBorder(),
        textStyle: BoxTextStyle(fontSize: 12),
      );

      expect(card.computedStyle.padding, const BoxSpacing.all(8));
      expect(card.computedStyle.backgroundColor, BoxColors.lightGrey);
      expect(card.computedStyle.borderRadius, 0);
      expect(card.computedStyle.shadows, isNull);
      expect(card.computedStyle.border, const BoxBorder());
      expect(card.computedStyle.textStyle, const BoxTextStyle(fontSize: 12));
    });

    test('passes the layout it is given to the box, and takes no press', () {
      const card = MaterialCard(
        direction: Axis.horizontal,
        gap: 8,
        width: 320,
        flex: 1,
      );

      expect(card.direction, Axis.horizontal);
      expect(card.computedStyle.gap, 8);
      expect(card.computedStyle.width, 320);
      expect(card.computedStyle.flex, 1);
      // A surface is not a control: the press belongs to the ink well inside the card, so
      // the card has no tap, no hand cursor and no tab stop of its own.
      expect(card.onTap, isNull);
      expect(card.isInteractive, isFalse);
      expect(card.isFocusable, isFalse);
    });

    test('typesets the texts inside it without a style of their own', () {
      const card = MaterialCard(children: <UINode>[TextNode('Two nights')]);
      final UINode text = card.children.single;

      expect((text as TextNode).computedStyle, const BoxTextStyle());
      expect(validateTree(card, theme: MaterialPalette.lightTheme), isEmpty);
    });

    test('is validated like any other box', () {
      const card = MaterialCard(
        children: <UINode>[PositionedNode(child: TextNode('Outside a stack'))],
      );

      final issues = validateTree(card, theme: MaterialPalette.lightTheme);

      expect(issues, hasLength(1));
      expect(issues.single.node, isA<PositionedNode>());
      expect(issues.single.severity, TreeIssueSeverity.warning);
    });
  });

  group('MaterialCard variants', () {
    test('elevated is the tonal surface with the level one shadow', () {
      final card = MaterialCard.elevated();

      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerLow),
      );
      expect(card.shadows, MaterialCard.elevatedShadows);
      expect(card.border, isNull);
    });

    test('filled is the highest tone and casts no shadow', () {
      final card = MaterialCard.filled();

      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerHighest),
      );
      // An empty list and not `null`: the variant states that it casts nothing, rather
      // than dropping the default the primary constructor would have given it.
      expect(card.shadows, isEmpty);
    });

    test('outlined is the surface with an outline variant border', () {
      final card = MaterialCard.outlined();

      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surface),
      );
      expect(card.shadows, isEmpty);
      expect(
        card.border?.color,
        const BoxColor.role(MaterialColorRole.outlineVariant),
      );
      expect(card.borderRadius, 12);
    });

    test('types the text in the on-surface role', () {
      final card = MaterialCard.filled();

      expect(
        card.textStyle?.color,
        const BoxColor.role(MaterialColorRole.onSurface),
      );
    });
  });
}
