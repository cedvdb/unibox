import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

void main() {
  group('a scroll offset', () {
    test('is the key of the region and where it was left', () {
      const BoxScrollOffset offset = BoxScrollOffset(key: 'listings', dy: 1400);

      expect(offset.key, 'listings');
      expect(offset.dy, 1400);
      expect(offset.dx, 0);
    });

    test('reads the record a page wrote', () {
      // The shape the client script produces, so the boundary needs no translation.
      final BoxScrollOffset offset = BoxScrollOffset.fromRecord(
        <String, Object?>{'key': 'listings', 'dx': 0, 'dy': 1400},
      );

      expect(offset, const BoxScrollOffset(key: 'listings', dy: 1400));
    });

    test('writes the record it reads', () {
      const BoxScrollOffset offset = BoxScrollOffset(key: 7, dy: 12.5);

      expect(offset.toRecord(), <String, Object?>{
        'key': 7,
        'dx': 0.0,
        'dy': 12.5,
      });
    });

    test('takes a whole number from the record, which JSON gives freely', () {
      expect(
        BoxScrollOffset.fromRecord(<String, Object?>{'key': 'a', 'dy': 12}).dy,
        12,
      );
    });

    test('is refused when it names no region', () {
      // A record without a key is not an offset, and guessing one would move the wrong box.
      expect(
        () => BoxScrollOffset.fromRecord(<String, Object?>{'dy': 12}),
        throwsArgumentError,
      );
    });

    test('compares by what it says', () {
      expect(
        const BoxScrollOffset(key: 'a', dy: 1),
        const BoxScrollOffset(key: 'a', dy: 1),
      );
      expect(
        const BoxScrollOffset(key: 'a', dy: 1),
        isNot(const BoxScrollOffset(key: 'a', dy: 2)),
      );
    });
  });
}
