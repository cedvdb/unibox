import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void main() {
  group('MaterialIcon', () {
    test('takes the glyph of a codepoint', () {
      final MaterialIcon icon = MaterialIcon.codePoint(0xe9b2);

      expect(
        (icon.children.single as TextNode).text,
        String.fromCharCode(0xe9b2),
      );
    });

    test('scales its glyph with its size and takes a colour', () {
      final MaterialIcon icon = MaterialIcon.codePoint(
        0xe9b2,
        size: 40,
        color: BoxColors.red,
      );

      expect(icon.width, 40);
      expect(icon.height, 40);
      expect(icon.textStyle?.fontSize, 40);
      expect(icon.textStyle?.color, BoxColors.red);
    });

    test('names the family the host declares', () {
      final MaterialIcon icon = MaterialIcon.codePoint(
        0xe88a,
        fontFamily: 'MaterialIcons',
      );

      expect(icon.textStyle?.fontFamily, 'MaterialIcons');
    });

    test('hides a decorative icon and announces a labelled one', () {
      final MaterialIcon decorative = MaterialIcon.codePoint(0xe9b2);

      expect(decorative.semantics?.hidden, isTrue);
      expect(decorative.semantics?.label, isNull);

      final MaterialIcon labelled = MaterialIcon.codePoint(
        0xe9b2,
        label: 'Home',
      );

      expect(labelled.semantics?.hidden, isFalse);
      expect(labelled.semantics?.label, 'Home');
    });
  });
}
