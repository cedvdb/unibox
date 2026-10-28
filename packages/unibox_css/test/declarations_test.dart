import 'package:test/test.dart';
import 'package:unibox_css/unibox_css.dart';

void main() {
  group('a list of declarations', () {
    test('is empty until something is declared', () {
      final CssDeclarations declarations = CssDeclarations();

      expect(declarations.isEmpty, isTrue);
      expect(declarations.text, '');
    });

    test('is written in property order, whatever order it was built in', () {
      // The class name of a look is a hash of this text, so two renderers that fill
      // the same declarations in different orders have to agree on the spelling.
      final CssDeclarations one = CssDeclarations()
        ..add('width', '8px')
        ..add('display', 'flex');
      final CssDeclarations other = CssDeclarations()
        ..add('display', 'flex')
        ..add('width', '8px');

      expect(one.text, 'display:flex;width:8px');
      expect(other.text, one.text);
    });

    test(
      'keeps a property that is written twice, in the order it was written',
      () {
        // A second write is a fallback, not a mistake, and CSS applies the last one.
        final CssDeclarations declarations = CssDeclarations()
          ..add('color', 'red')
          ..add('color', 'var(--unibox-color-text)');

        expect(declarations.text, 'color:red;color:var(--unibox-color-text)');
        expect(declarations['color'], 'var(--unibox-color-text)');
        expect(declarations.length, 2);
      },
    );

    test('answers whether a property is declared at all', () {
      final CssDeclarations declarations = CssDeclarations()
        ..addAll(<String, String>{'border-radius': '8px'});

      expect(declarations.has('border-radius'), isTrue);
      expect(declarations.has('border'), isFalse);
      expect(declarations['border'], isNull);
      expect(declarations.isNotEmpty, isTrue);
    });
  });

  group('the class a look wears', () {
    test('is the same for the same declarations, whatever built them', () {
      // Which is what lets a server render, a browser and a second renderer agree on
      // one rule instead of three that look alike.
      final CssDeclarations one = CssDeclarations()
        ..add('display', 'flex')
        ..add('width', '8px');
      final CssDeclarations other = CssDeclarations()
        ..add('width', '8px')
        ..add('display', 'flex');

      expect(classNameFor('box', one.text), classNameFor('box', other.text));
    });

    test('names the kind, and differs between two kinds with one look', () {
      expect(classNameFor('box', 'display:flex'), startsWith('unibox-box-'));
      expect(classNameFor('text', 'display:flex'), startsWith('unibox-text-'));
      expect(
        classNameFor('box', 'display:flex'),
        isNot(classNameFor('text', 'display:flex')),
      );
    });

    test('hashes to eight lowercase hexadecimal characters', () {
      expect(fnv1a('x'), matches(RegExp(r'^[0-9a-f]{8}$')));
      expect(fnv1a('x'), fnv1a('x'));
      expect(fnv1a('x'), isNot(fnv1a('y')));
    });
  });
}
