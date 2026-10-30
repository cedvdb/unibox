import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _close() {}

/// The surface a dialog or a sheet draws, which is the overlay's child.
Box _surfaceOf(OverlayNode overlay) => overlay.child as Box;

void main() {
  group('MaterialDialog', () {
    test('is an overlay, centred over a scrim', () {
      final dialog = MaterialDialog(title: 'Delete listing?');

      expect(dialog, isA<OverlayNode>());
      expect(dialog.alignment, OverlayAlignment.center);
      expect(dialog.barrierColor, const BoxColor.role(MaterialColorRole.scrim));
      expect(dialog.barrierDismissible, isTrue);
    });

    test('passes the dismissal on, and closes only if one is given', () {
      expect(MaterialDialog(title: 'Hi').onDismiss, isNull);
      expect(MaterialDialog(title: 'Hi', onDismiss: _close).onDismiss, _close);
    });

    test('holds a title, the content and the actions, in that order', () {
      final dialog = MaterialDialog(
        title: 'Delete listing?',
        content: const TextNode('The photos go too.'),
        actions: <UINode>[const TextNode('Cancel'), const TextNode('Delete')],
      );
      final children = _surfaceOf(dialog).children;

      expect(children, hasLength(3));
      expect((children[0] as TextNode).text, 'Delete listing?');
      expect(
        ((children[1] as Box).children.single as TextNode).text,
        'The photos go too.',
      );
      expect((children[2] as Box).children, hasLength(2));
    });

    test('packs the actions against the end of a row', () {
      final dialog = MaterialDialog(
        title: 'Hi',
        actions: <UINode>[const TextNode('OK')],
      );
      final row = _surfaceOf(dialog).children.last as Box;

      expect(row.direction, Axis.horizontal);
      expect(row.mainAlign, MainAlign.end);
    });

    test('draws a raised surface in the high tone', () {
      final surface = _surfaceOf(MaterialDialog(title: 'Hi'));

      expect(
        surface.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerHigh),
      );
      expect(surface.borderRadius, 28);
      expect(surface.shadows, MaterialDialog.elevation);
      expect(surface.minWidth, 280);
      expect(surface.maxWidth, 560);
    });

    test('lets a caller set the surface, its room and its action row', () {
      final surface = _surfaceOf(
        MaterialDialog(
          title: 'Hi',
          actions: <UINode>[const TextNode('OK')],
          color: const BoxColor.role(MaterialColorRole.surfaceContainerLowest),
          padding: const BoxSpacing.all(16),
          gap: 8,
          borderRadius: 12,
          actionGap: 4,
          actionMargin: BoxSpacing.zero,
        ),
      );
      final Box actions = surface.children.last as Box;

      expect(
        surface.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerLowest),
      );
      expect(surface.padding, const BoxSpacing.all(16));
      expect(surface.gap, 8);
      expect(surface.borderRadius, 12);
      expect(actions.gap, 4);
      expect(actions.margin, BoxSpacing.zero);
    });

    test('titles the surface with the headline role', () {
      final title =
          _surfaceOf(MaterialDialog(title: 'Hi')).children.first as TextNode;

      expect(title.style?.fontSize, MaterialTypography.headlineSmall.fontSize);
      expect(
        title.style?.color,
        const BoxColor.role(MaterialColorRole.onSurface),
      );
    });
  });

  group('MaterialBottomSheet', () {
    test('is an overlay against the bottom edge', () {
      final sheet = MaterialBottomSheet(title: 'Filters');

      expect(sheet, isA<OverlayNode>());
      expect(sheet.alignment, OverlayAlignment.bottom);
      expect(sheet.barrierColor, const BoxColor.role(MaterialColorRole.scrim));
    });

    test('is a dialog-shaped surface in a lower tone, wider than a dialog', () {
      final surface = _surfaceOf(MaterialBottomSheet(title: 'Filters'));

      expect(
        surface.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerLow),
      );
      expect(surface.maxWidth, 640);
      expect(surface.width, double.infinity);
      expect(
        surface.shadows!.every((BoxShadow shadow) => shadow.offsetY < 0),
        isTrue,
        reason: 'a sheet rises, so every layer of its shadow points up',
      );
    });

    test('holds a title, the content and the actions, in that order', () {
      final sheet = MaterialBottomSheet(
        title: 'Filters',
        content: const TextNode('Two nights'),
        actions: <UINode>[const TextNode('Apply')],
      );
      final children = _surfaceOf(sheet).children;

      // The drag handle comes first, then the title, the content, the actions.
      expect(children, hasLength(4));
      expect((children[1] as TextNode).text, 'Filters');
      expect(
        ((children[2] as Box).children.single as TextNode).text,
        'Two nights',
      );
      expect((children[3] as Box).mainAlign, MainAlign.end);
    });

    test('lets a caller set the surface, its corners and its action row', () {
      final surface = _surfaceOf(
        MaterialBottomSheet(
          title: 'Filters',
          actions: <UINode>[const TextNode('Apply')],
          color: const BoxColor.role(MaterialColorRole.surfaceContainerHighest),
          padding: const BoxSpacing.all(16),
          gap: 8,
          borderRadius: 16,
          actionGap: 4,
          actionMargin: BoxSpacing.zero,
        ),
      );
      final Box actions = surface.children.last as Box;

      expect(
        surface.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainerHighest),
      );
      expect(surface.corners, const BoxBorderRadius(topLeft: 16, topRight: 16));
      expect(surface.padding, const BoxSpacing.all(16));
      expect(surface.gap, 8);
      expect(actions.gap, 4);
      expect(actions.margin, BoxSpacing.zero);
    });
  });
}
