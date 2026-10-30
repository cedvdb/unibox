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
      expect(card.shadows, MaterialCard.elevatedShadows);
      expect(card.border, isNull);
      expect(card.textStyle, MaterialTypography.bodyMedium);
      expect(card.children, isEmpty);
    });

    test('draws the three layers of elevation level one', () {
      const List<BoxShadow> shadows = MaterialCard.elevatedShadows;

      // Flutter's `kElevationToShadow[1]`: an umbra under the edge, its penumbra and
      // the wide ambient layer that reads as height.
      expect(shadows, hasLength(3));
      expect(shadows.first.spreadRadius, -1);
      expect(shadows.last.blurRadius, 3);
      expect(shadows.last.color.opacity, closeTo(0.12, 0.01));
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
      expect(card.shadows, MaterialCard.elevatedShadows);
      expect(card.border, isNull);
    });

    test('filled is the highest tone and casts no shadow', () {
      final card = MaterialCard.filled();

      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerHighest),
      );
      expect(card.shadows, isNull);
    });

    test('outlined is the surface with an outline variant border', () {
      final card = MaterialCard.outlined();

      expect(
        card.backgroundColor,
        const BoxColor.role(MaterialColorRole.surface),
      );
      expect(card.shadows, isNull);
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
