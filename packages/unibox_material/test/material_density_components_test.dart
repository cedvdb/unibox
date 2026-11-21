import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// Holds the components to the height Flutter draws at each density.
///
/// A control is 40 high at [MaterialDensity.standard] and 32 at
/// [MaterialDensity.compact] — the same eight pixels Flutter's
/// `VisualDensity.adaptivePlatformDensity` takes off it — and the tree states the answer once,
/// so the page and the application draw the same control.
void main() {
  group('at the standard density', () {
    test('a chip sits in a forty-eight pixel target', () {
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Two rooms'),
      );

      expect(chip.minHeight, 48);
    });
  });

  group('at the compact density', () {
    test('a chip sits in a forty pixel target', () {
      final MaterialChip chip = MaterialChip(
        label: const TextNode('Two rooms'),
        density: MaterialDensity.compact,
      );

      expect(chip.minHeight, 40);
    });

    test('a list tile is eight pixels shorter', () {
      final MaterialListTile tile = MaterialListTile(
        title: const TextNode('Ada'),
        density: MaterialDensity.compact,
      );
      final MaterialListTile resting = MaterialListTile(
        title: const TextNode('Ada'),
      );

      expect(resting.row.minHeight, 56);
      expect(tile.row.minHeight, 48);
    });
  });
}
