import 'package:test/test.dart';
import 'package:unibox_element/unibox_element.dart';

/// What a destination may be, which is the plan's decision rather than a renderer's.
void main() {
  group('a risky url', () {
    test('is one that runs a script when a reader clicks', () {
      expect(isRiskyUrl('javascript:alert(1)'), isTrue);
      expect(isRiskyUrl('JavaScript:alert(1)'), isTrue);
      expect(isRiskyUrl(' javascript:alert(1)'), isTrue);
      expect(isRiskyUrl('vbscript:msgbox(1)'), isTrue);
    });

    test('is not a destination a reader can go to', () {
      expect(isRiskyUrl('https://example.com'), isFalse);
      expect(isRiskyUrl('/listings'), isFalse);
      expect(isRiskyUrl('mailto:hi@example.com'), isFalse);
    });

    test('is replaced with a destination that does nothing', () {
      // The element stays a link rather than losing its attribute, so the markup a reader and a
      // crawler read is the one the tree described.
      expect(safeUrlValue('javascript:alert(1)'), '#');
      expect(safeUrlValue('/listings'), '/listings');
    });
  });
}
