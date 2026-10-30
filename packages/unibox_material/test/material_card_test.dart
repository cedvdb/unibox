import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _tap() {}

void main() {
  group('MaterialCard', () {
    test('is a box with the defaults Material gives a card', () {
      const card = MaterialCard();

      expect(card, isA<Box>());
      expect(card.padding, const BoxSpacing.all(16));
      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerLow),
      );
      expect(card.borderRadius, 12);
      expect(card.shadow, MaterialCard.elevatedShadow);
      expect(card.border, isNull);
      expect(card.textStyle, MaterialTypography.bodyMedium);
      expect(card.children, isEmpty);
    });

    test('draws the shade of elevation level one', () {
      const shadow = MaterialCard.elevatedShadow;

      // Flutter's `kElevationToShadow[1]`, ambient layer: `0 1px 3px` at 12%.
      expect(shadow.offsetY, 1);
      expect(shadow.blurRadius, 3);
      expect(shadow.color.opacity, closeTo(0.12, 0.01));
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
        shadow: null,
        border: BoxBorder(),
        textStyle: BoxTextStyle(fontSize: 12),
      );

      expect(card.computedStyle.padding, const BoxSpacing.all(8));
      expect(card.computedStyle.backgroundColor, BoxColors.lightGrey);
      expect(card.computedStyle.borderRadius, 0);
      expect(card.computedStyle.shadow, isNull);
      expect(card.computedStyle.border, const BoxBorder());
      expect(card.computedStyle.textStyle, const BoxTextStyle(fontSize: 12));
    });

    test('passes the layout and the interaction it is given to the box', () {
      const card = MaterialCard(
        direction: Axis.horizontal,
        gap: 8,
        width: 320,
        flex: 1,
        onTap: _tap,
      );

      expect(card.direction, Axis.horizontal);
      expect(card.computedStyle.gap, 8);
      expect(card.computedStyle.width, 320);
      expect(card.computedStyle.flex, 1);
      expect(card.onTap, _tap);
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
      expect(card.shadow, MaterialCard.elevatedShadow);
      expect(card.border, isNull);
    });

    test('filled is the highest tone and casts no shadow', () {
      final card = MaterialCard.filled();

      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerHighest),
      );
      expect(card.shadow, isNull);
    });

    test('outlined is the surface with an outline variant border', () {
      final card = MaterialCard.outlined();

      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surface),
      );
      expect(card.shadow, isNull);
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
