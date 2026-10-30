import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

/// The roles an application defines. Two enums keep the tests honest about a
/// theme that mixes vocabularies.
enum AppColor { primary, onPrimary, surfaceContainerHigh, error }

enum BrandColor { primary, accent }

const UniboxTheme theme = UniboxTheme(
  colors: <AppColor, BoxColor>{
    AppColor.primary: BoxColor(0xFF6750A4),
    AppColor.onPrimary: BoxColor(0xFFFFFFFF),
    AppColor.surfaceContainerHigh: BoxColor(0xFFECE6F0),
    AppColor.error: BoxColor(0xFFB3261E),
  },
);

void main() {
  group('BoxColor.role', () {
    test('names a role instead of carrying channels', () {
      const BoxColor color = BoxColor.role(AppColor.primary);

      expect(color.isRole, isTrue);
      expect(color.role, AppColor.primary);
      expect(color.toString(), 'BoxColor.role(AppColor.primary)');
    });

    test('throws when read as a value, because no theme answered it', () {
      expect(
        () => const BoxColor.role(AppColor.primary).value,
        throwsA(isA<StateError>()),
      );
    });

    test('equals another colour of the same role, and no literal', () {
      expect(
        const BoxColor.role(AppColor.primary),
        const BoxColor.role(AppColor.primary),
      );
      expect(
        const BoxColor.role(AppColor.primary),
        isNot(const BoxColor.role(AppColor.error)),
      );
      expect(const BoxColor.role(AppColor.primary), isNot(BoxColor.black));
    });
  });

  group('UniboxTheme', () {
    test('resolves a role and leaves a value alone', () {
      expect(
        theme.resolve(const BoxColor.role(AppColor.primary)).value,
        0xFF6750A4,
      );
      expect(theme.resolve(BoxColor.black), BoxColor.black);
    });

    test('throws for a role it does not define, naming it', () {
      expect(
        () => theme.resolve(const BoxColor.role(BrandColor.accent)),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('BrandColor.accent'),
          ),
        ),
      );
    });

    test('spells a role as a kebab case custom property', () {
      expect(UniboxTheme.cssNameOf(AppColor.primary), '--unibox-color-primary');
      expect(
        UniboxTheme.cssNameOf(AppColor.surfaceContainerHigh),
        '--unibox-color-surface-container-high',
      );
      expect(
        UniboxTheme.cssNameOf(AppColor.onPrimary),
        '--unibox-color-on-primary',
      );
    });

    test('lists its variables in declaration order', () {
      expect(theme.variables.keys, <String>[
        '--unibox-color-primary',
        '--unibox-color-on-primary',
        '--unibox-color-surface-container-high',
        '--unibox-color-error',
      ]);
    });

    test('reports two roles that would claim one property', () {
      const UniboxTheme mixed = UniboxTheme(
        colors: <Enum, BoxColor>{
          AppColor.primary: BoxColor(0xFF6750A4),
          BrandColor.primary: BoxColor(0xFF00FF00),
        },
      );

      expect(mixed.clashes, <String>['--unibox-color-primary']);
      expect(theme.clashes, isEmpty);
    });

    test('is empty by default', () {
      expect(UniboxTheme.none.isEmpty, isTrue);
      expect(theme.isEmpty, isFalse);
    });
  });

  group('merging themes', () {
    test('keeps the value of a role both define', () {
      const UniboxTheme base = UniboxTheme(
        colors: <Enum, BoxColor>{AppColor.primary: BoxColor(0xFF000001)},
      );
      final UniboxTheme merged = base.merge(theme);

      expect(
        merged.resolve(const BoxColor.role(AppColor.primary)).value,
        0xFF000001,
      );
    });

    test('adds the roles it does not define', () {
      const UniboxTheme base = UniboxTheme(
        colors: <Enum, BoxColor>{BrandColor.accent: BoxColor(0xFF00FF00)},
      );
      final UniboxTheme merged = base.merge(theme);

      expect(
        merged.resolve(const BoxColor.role(AppColor.error)).value,
        0xFFB3261E,
      );
      expect(
        merged.resolve(const BoxColor.role(BrandColor.accent)).value,
        0xFF00FF00,
      );
    });

    test('is the same theme when the other defines nothing', () {
      expect(identical(theme.merge(UniboxTheme.none), theme), isTrue);
    });
  });

  group('resolving a style', () {
    const UniboxTheme theme = UniboxTheme(
      colors: <AppColor, BoxColor>{
        AppColor.primary: BoxColor(0xFF6750A4),
        AppColor.error: BoxColor(0xFFB3261E),
      },
    );

    test('reports whether it holds a role', () {
      expect(const BoxStyle().hasRoleColors, isFalse);
      expect(
        const BoxStyle(backgroundColor: BoxColor.role(AppColor.primary))
            .hasRoleColors,
        isTrue,
      );
      expect(
        const BoxStyle(
          textStyle: BoxTextStyle(color: BoxColor.role(AppColor.error)),
        ).hasRoleColors,
        isTrue,
      );
    });

    test('gives back the same style when it holds no role', () {
      const BoxStyle style = BoxStyle(backgroundColor: BoxColor.white);

      expect(identical(style.resolve(theme), style), isTrue);
    });

    test('resolves every colour a style can carry', () {
      const BoxStyle style = BoxStyle(
        backgroundColor: BoxColor.role(AppColor.primary),
        border: BoxBorder(color: BoxColor.role(AppColor.error)),
        shadows: <BoxShadow>[BoxShadow(color: BoxColor.role(AppColor.error))],
        textStyle: BoxTextStyle(color: BoxColor.role(AppColor.primary)),
        padding: BoxSpacing.all(8),
        borderRadius: 12,
      );
      final BoxStyle resolved = style.resolve(theme);

      expect(resolved.backgroundColor?.value, 0xFF6750A4);
      expect(resolved.border?.color.value, 0xFFB3261E);
      expect(resolved.shadows?.single.color.value, 0xFFB3261E);
      expect(resolved.textStyle?.color?.value, 0xFF6750A4);
      // Everything that is not a colour travels untouched.
      expect(resolved.padding, style.padding);
      expect(resolved.borderRadius, 12);
    });
  });

  group('validateTree with a theme', () {
    const Box box = Box(
      backgroundColor: BoxColor.role(AppColor.primary),
      children: <UINode>[
        TextNode('Unibox', color: BoxColor.role(AppColor.error)),
      ],
    );

    test('accepts roles the theme defines', () {
      expect(validateTree(box, theme: theme), isEmpty);
    });

    test('reports a role with no theme at all', () {
      final List<TreeIssue> issues = validateTree(box);

      expect(issues, hasLength(2));
      expect(issues.every((TreeIssue issue) => issue.isError), isTrue);
      expect(issues.first.message, contains('no theme was given'));
    });

    test('reports a role the theme does not define', () {
      final List<TreeIssue> issues = validateTree(
        const Box(backgroundColor: BoxColor.role(BrandColor.accent)),
        theme: theme,
      );

      expect(issues.single.isError, isTrue);
      expect(issues.single.message, contains('BrandColor.accent'));
    });

    test('reports a role in a state style too', () {
      final List<TreeIssue> issues = validateTree(
        const Box(
          stateStyles: <BoxState, BoxStyle>{
            BoxState.hover: BoxStyle(
              backgroundColor: BoxColor.role(BrandColor.primary),
            ),
          },
        ),
        theme: theme,
      );

      expect(issues.single.message, contains('BrandColor.primary'));
    });
  });
}
