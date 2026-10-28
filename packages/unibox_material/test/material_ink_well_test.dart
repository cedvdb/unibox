import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _tap() {}

void main() {
  group('MaterialInkWell', () {
    test('is a box with the three state layers of a role palette', () {
      final well = MaterialInkWell(onTap: _tap, child: const TextNode('Ada'));

      expect(well, isA<Box>());
      expect(well.onTap, _tap);
      expect(
        well.hoverStyle?.backgroundColor,
        const BoxColor.role(MaterialColorRole.hoverLayer),
      );
      expect(
        well.stateStyle(BoxState.focus)?.backgroundColor,
        const BoxColor.role(MaterialColorRole.focusLayer),
      );
      expect(
        well.stateStyle(BoxState.pressed)?.backgroundColor,
        const BoxColor.role(MaterialColorRole.pressedLayer),
      );
      // No surface of its own: the fill belongs to the box around it.
      expect(well.backgroundColor, isNull);
    });

    test('eases the tint over Material\'s short fade', () {
      final well = MaterialInkWell(onTap: _tap, child: const TextNode('Ada'));

      expect(well.transition, MaterialInkWell.defaultTransition);
      expect(well.transition?.duration, const Duration(milliseconds: 100));
    });

    test('is a button when it can be tapped, and not otherwise', () {
      expect(
        MaterialInkWell(
          onTap: _tap,
          child: const TextNode('Ada'),
        ).semantics?.role,
        BoxRole.button,
      );
      expect(
        MaterialInkWell(child: const TextNode('Ada')).semantics?.role,
        isNull,
      );
    });

    test('takes a radius, padding and a state style of its own', () {
      final well = MaterialInkWell(
        onTap: _tap,
        borderRadius: 20,
        padding: const BoxSpacing.all(8),
        hoverStyle: const BoxStyle(backgroundColor: BoxColor.black),
        child: const TextNode('Ada'),
      );

      expect(well.borderRadius, 20);
      expect(well.padding, const BoxSpacing.all(8));
      expect(well.hoverStyle?.backgroundColor, BoxColor.black);
    });
  });
}
