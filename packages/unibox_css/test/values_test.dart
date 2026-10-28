import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';

/// A role of a design system, which names the custom property a colour is written
/// as. Any enum does: the model does not own the vocabulary of an application.
enum _Role { primary }

void main() {
  group('a length', () {
    test('is written in pixels, without a needless decimal', () {
      expect(cssPixels(8), '8px');
      expect(cssPixels(8.5), '8.5px');
      expect(cssPixels(0), '0px');
    });

    test('expands an infinite dimension to the space available', () {
      // A box that fills its parent is how the model states "as big as I am given".
      expect(cssLength(double.infinity), '100%');
      expect(cssLength(-double.infinity), '100%');
    });

    test('is left out when the model declares nothing', () {
      expect(cssLength(null), isNull);
    });
  });

  group('a spacing', () {
    test('collapses to one value when every edge is the same', () {
      expect(cssSpacing(const core.BoxSpacing.all(8)), '8px');
    });

    test('is written top, right, bottom, left when the edges differ', () {
      // CSS's order, which is also the order a reader of the output expects.
      expect(
        cssSpacing(
          const core.BoxSpacing(top: 8, right: 12, bottom: 16, left: 4),
        ),
        '8px 12px 16px 4px',
      );
    });

    test('states a zero rather than dropping the declaration', () {
      // A reset that cancels what a user agent applies has to be written down.
      expect(cssSpacing(core.BoxSpacing.zero), '0px');
    });
  });

  group('a colour', () {
    test('is written as six hexadecimal digits when it is opaque', () {
      expect(cssColor(const core.BoxColor(0xFF112233)), '#112233');
    });

    test('is written as rgba when it carries an alpha', () {
      expect(
        cssColor(const core.BoxColor.rgba(17, 34, 51, 128)),
        'rgba(17, 34, 51, 0.502)',
      );
    });

    test('is a custom property when it names a role', () {
      final core.BoxColor? role = core.BoxColor.role(_Role.primary);

      expect(cssRoleReference(role!), startsWith('var(--unibox-color-'));
      expect(cssColorOrRole(role), cssRoleReference(role));
    });

    test('falls back to its channels when it names no role', () {
      expect(cssRoleReference(const core.BoxColor(0xFF112233)), isNull);
      expect(cssColorOrRole(const core.BoxColor(0xFF112233)), '#112233');
    });
  });

  group('an image fit', () {
    test('is the keyword CSS uses for the same crop', () {
      expect(cssObjectFit(core.ImageFit.cover), 'cover');
      expect(cssObjectFit(core.ImageFit.contain), 'contain');
      expect(cssObjectFit(core.ImageFit.fill), 'fill');
      expect(cssObjectFit(core.ImageFit.scaleDown), 'scale-down');
    });
  });
}
