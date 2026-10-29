import 'package:test/test.dart';
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('text between two tags', () {
    test('keeps what a reader typed', () {
      expect(escapeText('2 bedrooms · £1,200'), '2 bedrooms · £1,200');
    });

    test('cannot start an element', () {
      // The whole security surface of a string renderer: a title from the database is
      // text, not markup.
      expect(
        escapeText('<script>alert(1)</script>'),
        '&lt;script&gt;alert(1)&lt;/script&gt;',
      );
    });

    test('cannot start a character reference', () {
      expect(escapeText('&amp;'), '&amp;amp;');
      expect(escapeText('&'), '&amp;');
    });

    test('leaves quotes alone, which mean nothing in content', () {
      expect(escapeText('a "quoted" \'word\''), 'a "quoted" \'word\'');
    });
  });

  group('an attribute value', () {
    test('cannot end the attribute it is in', () {
      // An unescaped quote is how a `class` becomes an `onload`.
      expect(
        escapeAttribute('x" onload="alert(1)'),
        'x&quot; onload=&quot;alert(1)',
      );
    });

    test('is escaped before the text specials', () {
      expect(escapeAttribute('a&b<c>d"e'), 'a&amp;b&lt;c&gt;d&quot;e');
    });

    test('escapes an ampersand once', () {
      expect(escapeAttribute('&amp;'), '&amp;amp;');
    });
  });

  group('a URL', () {
    test('is escaped like any other attribute', () {
      expect(safeUrl('/listings?q=a&b=c'), '/listings?q=a&amp;b=c');
    });

    test('cannot run a script', () {
      // It arrives from data, not from the tree: a URL field is user input.
      expect(safeUrl('javascript:alert(1)'), '#');
      expect(safeUrl('JavaScript:alert(1)'), '#');
      expect(safeUrl(' javascript:alert(1)'), '#');
      expect(safeUrl('vbscript:msgbox(1)'), '#');
    });
  });
}
