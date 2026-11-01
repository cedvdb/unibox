import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

/// A role of the test's own, so a theme can answer one.
enum _Ink { primary }

void main() {
  const UniboxTheme theme = UniboxTheme(
    colors: <Enum, BoxColor>{_Ink.primary: BoxColor.white},
    colorScheme: BoxColorScheme.dark,
  );

  group('UniboxScope', () {
    test('states nothing until it is given something', () {
      expect(UniboxScope.none.theme, isNull);
      expect(UniboxScope.none.lang, 'en');
      expect(UniboxScope.none.writingDirection, isNull);
    });

    test('is equal to another scope that states the same nothing', () {
      // A renderer compares the scope it is given with [UniboxScope.none] to decide whether
      // to install one at all, so the empty value has to compare equal to the constant.
      expect(const UniboxScope(), UniboxScope.none);
      expect(const UniboxScope().hashCode, UniboxScope.none.hashCode);
    });

    test(
      'carries the theme, the language and the direction of a rendering',
      () {
        const UniboxScope scope = UniboxScope(
          theme: theme,
          lang: 'ar',
          writingDirection: WritingDirection.rtl,
        );

        expect(scope.theme, theme);
        expect(scope.lang, 'ar');
        expect(scope.writingDirection, WritingDirection.rtl);
        expect(scope, isNot(UniboxScope.none));
      },
    );

    test('differs when only the language differs', () {
      // The language reaches a page as an attribute, so two renderings that differ only in it
      // are two renderings: a scope that compared equal would keep the wrong one on screen.
      expect(
        const UniboxScope(lang: 'nl'),
        isNot(const UniboxScope(lang: 'de')),
      );
      expect(
        const UniboxScope(lang: 'nl').hashCode,
        isNot(const UniboxScope(lang: 'de').hashCode),
      );
    });

    test('names the facts it holds when it is printed', () {
      expect(
        const UniboxScope(
          lang: 'nl',
          writingDirection: WritingDirection.rtl,
        ).toString(),
        contains('nl'),
      );
      expect(UniboxScope.none.toString(), contains('UniboxScope'));
    });
  });
}
