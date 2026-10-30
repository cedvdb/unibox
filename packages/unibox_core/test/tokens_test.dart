import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

/// One role, so the resolve test can watch a theme answer it.
enum _ShapeColor { surface }

void main() {
  group('BoxColor', () {
    test('exposes the channels of a raw ARGB value', () {
      const color = BoxColor(0x8042A5F0);

      expect(color.alpha, 0x80);
      expect(color.red, 0x42);
      expect(color.green, 0xA5);
      expect(color.blue, 0xF0);
      expect(color.opacity, closeTo(0x80 / 0xFF, 1e-9));
      expect(color.isOpaque, isFalse);
      expect(color.isTransparent, isFalse);
    });

    test('builds opaque colors from rgb channels', () {
      const color = BoxColor.rgb(0x2D, 0x6C, 0xF3);

      expect(color.value, 0xFF2D6CF3);
      expect(color.isOpaque, isTrue);
    });

    test('builds colors from rgba channels', () {
      const color = BoxColor.rgba(255, 128, 0, 128);

      expect(color.value, 0x80FF8000);
      expect(color.alpha, 128);
    });

    test('defaults rgba to an opaque color', () {
      expect(const BoxColor.rgba(1, 2, 3).value, 0xFF010203);
    });

    test('provides presets', () {
      expect(BoxColor.black.value, 0xFF000000);
      expect(BoxColor.white.value, 0xFFFFFFFF);
      expect(BoxColor.transparent.value, 0x00000000);
      expect(BoxColor.transparent.isTransparent, isTrue);
    });

    test('names the common colors the way Flutter does', () {
      // A map rather than a list of pairs: it also checks that no two presets
      // name the same colour, because the second one would collapse into the
      // first and the length below would come up short. The values are the ones
      // Flutter's `Colors` gives the same names, which is what makes a preset
      // look like the widgets around it on both targets.
      final Map<BoxColor, int> presets = <BoxColor, int>{
        BoxColors.lightGrey: 0xFFE0E0E0,
        BoxColors.grey: 0xFF9E9E9E,
        BoxColors.darkGrey: 0xFF616161,
        BoxColors.blueGrey: 0xFF607D8B,
        BoxColors.red: 0xFFF44336,
        BoxColors.orange: 0xFFFF9800,
        BoxColors.yellow: 0xFFFFEB3B,
        BoxColors.green: 0xFF4CAF50,
        BoxColors.teal: 0xFF009688,
        BoxColors.blue: 0xFF2196F3,
        BoxColors.indigo: 0xFF3F51B5,
        BoxColors.purple: 0xFF9C27B0,
        BoxColors.pink: 0xFFE91E63,
        BoxColors.brown: 0xFF795548,
      };

      expect(presets, hasLength(14));

      for (final MapEntry<BoxColor, int> preset in presets.entries) {
        expect(preset.key.value, preset.value, reason: preset.key.toString());
        expect(preset.key.isOpaque, isTrue, reason: preset.key.toString());
      }
    });

    test('keeps the three colors BoxColor declares next to its constructors', () {
      // The palette is the one place to look for a name, but these three stay on
      // the value because a colour is usually written next to its constructor.
      expect(BoxColor.white, BoxColors.white);
      expect(BoxColor.black, BoxColors.black);
      expect(BoxColor.transparent, BoxColors.transparent);
    });

    test('withOpacity scales the alpha channel', () {
      const color = BoxColor.rgb(10, 20, 30);

      expect(color.withOpacity(0.5).alpha, 128);
      expect(color.withOpacity(2).alpha, 255);
      expect(color.withOpacity(-1).alpha, 0);
      expect(color.withOpacity(0.5).red, 10);
      expect(color.withOpacity(0.5).blue, 30);
    });

    test('withAlpha replaces only the alpha channel', () {
      const color = BoxColor.rgba(10, 20, 30, 255);

      expect(color.withAlpha(64), const BoxColor.rgba(10, 20, 30, 64));
    });

    test('implements value equality', () {
      expect(const BoxColor(0xFF112233), const BoxColor(0xFF112233));
      expect(
        const BoxColor(0xFF112233).hashCode,
        const BoxColor(0xFF112233).hashCode,
      );
      expect(const BoxColor(0xFF112233), isNot(const BoxColor(0xFF112234)));
      expect(const BoxColor(0xFF112233).toString(), 'BoxColor(0xFF112233)');
    });
  });

  group('BoxSpacing', () {
    test('all applies the same inset on every edge', () {
      const spacing = BoxSpacing.all(12);

      expect(spacing.top, 12);
      expect(spacing.right, 12);
      expect(spacing.bottom, 12);
      expect(spacing.left, 12);
      expect(spacing.horizontal, 24);
      expect(spacing.vertical, 24);
      expect(spacing.isZero, isFalse);
    });

    test('symmetric distributes horizontal and vertical insets', () {
      const spacing = BoxSpacing.symmetric(horizontal: 8, vertical: 4);

      expect(spacing.top, 4);
      expect(spacing.right, 8);
      expect(spacing.bottom, 4);
      expect(spacing.left, 8);
      expect(spacing.hasUniformVertical, isTrue);
      expect(spacing.hasUniformHorizontal, isTrue);
    });

    test('only names individual edges', () {
      const spacing = BoxSpacing.only(top: 1, left: 3);

      expect(spacing.top, 1);
      expect(spacing.right, 0);
      expect(spacing.bottom, 0);
      expect(spacing.left, 3);
      expect(spacing.hasUniformHorizontal, isFalse);
    });

    test('zero has no insets', () {
      expect(BoxSpacing.zero.isZero, isTrue);
      expect(BoxSpacing.zero, const BoxSpacing());
    });

    test('copyWith replaces single edges', () {
      const spacing = BoxSpacing.all(4);

      expect(spacing.copyWith(top: 9).top, 9);
      expect(spacing.copyWith(top: 9).left, 4);
      expect(
        spacing.copyWith(left: 2),
        const BoxSpacing(top: 4, right: 4, bottom: 4, left: 2),
      );
    });

    test('implements value equality', () {
      expect(const BoxSpacing.all(6), const BoxSpacing.all(6));
      expect(
        const BoxSpacing.all(6).hashCode,
        const BoxSpacing.all(6).hashCode,
      );
      expect(const BoxSpacing.all(6), isNot(const BoxSpacing.all(7)));
    });
  });

  group('BoxBorder and BoxShadow', () {
    test('border defaults to a visible black hairline', () {
      const border = BoxBorder();

      expect(border.width, 1);
      expect(border.color, BoxColor.black);
      expect(border.isVisible, isTrue);
      expect(const BoxBorder.none().isVisible, isFalse);
    });

    test('border implements value equality', () {
      expect(
        const BoxBorder(width: 2, color: BoxColor.white),
        const BoxBorder(width: 2, color: BoxColor.white),
      );
      expect(const BoxBorder(width: 2), isNot(const BoxBorder(width: 3)));
      // The cap is part of the value: a style that changed only its cap would
      // otherwise merge away.
      expect(
        const BoxBorder(cap: BoxStrokeCap.round),
        isNot(const BoxBorder(cap: BoxStrokeCap.square)),
      );
    });

    test('a border carries its cap through a theme', () {
      const BoxBorder border = BoxBorder(
        width: 3,
        color: BoxColor.role(_BorderCapRole.primary),
        cap: BoxStrokeCap.round,
      );
      final BoxBorder resolved = border.resolve(
        const UniboxTheme(
          colors: <Enum, BoxColor>{_BorderCapRole.primary: BoxColor.white},
        ),
      );

      expect(resolved.color, BoxColor.white);
      expect(resolved.cap, BoxStrokeCap.round);
      expect(resolved.width, 3);
    });

    test('shadow implements value equality', () {
      const shadow = BoxShadow(color: BoxColor.black, blurRadius: 8);

      expect(shadow.blurRadius, 8);
      expect(shadow, const BoxShadow(blurRadius: 8));
      expect(shadow, isNot(const BoxShadow(blurRadius: 9)));
    });
  });

  group('BoxStyle', () {
    test('starts empty', () {
      expect(const BoxStyle().isEmpty, isTrue);
      expect(const BoxStyle(gap: 8).isEmpty, isFalse);
    });

    test('resolves an unset direction to a column', () {
      expect(const BoxStyle().direction, isNull);
      expect(const BoxStyle().resolvedDirection, Axis.vertical);
      expect(
        const BoxStyle(direction: Axis.horizontal).resolvedDirection,
        Axis.horizontal,
      );
    });

    test('carries where a scrolling box settles', () {
      const style = BoxStyle(overflow: Overflow.scroll, snap: ScrollSnap.page);

      expect(style.snap, ScrollSnap.page);
      expect(style.copyWith().snap, ScrollSnap.page);
      expect(
        style,
        const BoxStyle(overflow: Overflow.scroll, snap: ScrollSnap.page),
      );
      expect(style.toString(), contains('snap: ScrollSnap.page'));
      // An overlay wins, like every other token.
      expect(
        style.merge(const BoxStyle(snap: ScrollSnap.none)).snap,
        ScrollSnap.none,
      );
    });

    test('carries the page a pager shows, and 0 is a page', () {
      // The position of a pager, which is the one way to move one: a tree drawn twice with the same
      // page does not move the second time, and `copyWith` has to treat 0 as a value and not as
      // "unchanged" — the bug every nullable int field invites.
      const style = BoxStyle(
        overflow: Overflow.scroll,
        snap: ScrollSnap.page,
        page: 2,
      );

      expect(style.page, 2);
      expect(style.copyWith().page, 2);
      expect(style.copyWith(page: 0).page, 0);
      expect(
        style,
        const BoxStyle(
          overflow: Overflow.scroll,
          snap: ScrollSnap.page,
          page: 2,
        ),
      );
      expect(style.toString(), contains('page: 2'));
      expect(
        style.merge(const BoxStyle(page: 1)).page,
        1,
        reason: 'an overlay wins, like every other token',
      );
    });

    test('carries the opacity and the transform of a box', () {
      const style = BoxStyle(opacity: 0.5, transform: BoxTransform(scale: 1.1));

      expect(style.opacity, 0.5);
      expect(style.transform, const BoxTransform(scale: 1.1));
      expect(style.copyWith().opacity, 0.5);
      expect(
        style,
        const BoxStyle(opacity: 0.5, transform: BoxTransform(scale: 1.1)),
      );
      expect(style.toString(), contains('opacity: 0.5'));

      // The overlay wins, like every other token.
      expect(style.merge(const BoxStyle(opacity: 1)).opacity, 1);
      expect(const BoxStyle().merge(style).opacity, 0.5);
    });

    test('carries the transition that makes a change ease', () {
      const transition = BoxTransition(duration: Duration(milliseconds: 200));
      const style = BoxStyle(transition: transition);

      expect(style.transition, transition);
      expect(style.copyWith().transition, transition);
      expect(style, const BoxStyle(transition: transition));
      expect(style.toString(), contains('transition'));

      // The overlay wins, like every other token.
      const other = BoxTransition(duration: Duration(milliseconds: 80));
      expect(style.merge(const BoxStyle(transition: other)).transition, other);
      expect(const BoxStyle().merge(style).transition, transition);
    });

    test('merge lets the overlay win', () {
      const base = BoxStyle(
        padding: BoxSpacing.all(16),
        backgroundColor: BoxColor.white,
        gap: 4,
      );
      const overlay = BoxStyle(gap: 12, width: 200);

      final merged = base.merge(overlay);

      expect(merged.padding, BoxSpacing.all(16));
      expect(merged.backgroundColor, BoxColor.white);
      expect(merged.gap, 12);
      expect(merged.width, 200);
    });

    test('merge keeps the base when the overlay is null', () {
      const base = BoxStyle(gap: 4);

      expect(base.merge(null), same(base));
      expect(base.merge(const BoxStyle()), base);
    });

    test('copyWith replaces only the given tokens', () {
      const style = BoxStyle(direction: Axis.horizontal, gap: 4);

      final copy = style.copyWith(gap: 8, flex: 1);

      expect(copy.direction, Axis.horizontal);
      expect(copy.gap, 8);
      expect(copy.flex, 1);
      expect(copy, isNot(style));
    });

    test('merges text styles token by token', () {
      const base = BoxStyle(
        textStyle: BoxTextStyle(fontSize: 16, color: BoxColor.black),
      );
      const overlay = BoxStyle(textStyle: BoxTextStyle(color: BoxColor.white));

      final merged = base.merge(overlay);

      expect(merged.textStyle?.fontSize, 16);
      expect(merged.textStyle?.color, BoxColor.white);
    });

    test('keeps the text style when the overlay has none', () {
      const style = BoxStyle(textStyle: BoxTextStyle(fontSize: 16));

      expect(style.merge(const BoxStyle(gap: 8)).textStyle, style.textStyle);
      expect(const BoxStyle(gap: 8).merge(style).textStyle, style.textStyle);
    });

    test('implements value equality', () {
      const style = BoxStyle(
        direction: Axis.vertical,
        mainAlign: MainAlign.spaceBetween,
        crossAlign: CrossAlign.stretch,
        overflow: Overflow.scroll,
        padding: BoxSpacing.all(8),
        border: BoxBorder(width: 1),
        shadows: <BoxShadow>[BoxShadow()],
        textStyle: BoxTextStyle(fontSize: 16),
      );

      expect(style, style.copyWith());
      expect(style.hashCode, style.copyWith().hashCode);
      expect(style, isNot(style.copyWith(mainAlign: MainAlign.center)));
      expect(
        style,
        isNot(style.copyWith(textStyle: BoxTextStyle(fontSize: 18))),
      );
      expect(style.toString(), contains('direction: Axis.vertical'));
      expect(style.toString(), contains('textStyle'));
    });
  });

  group('UniboxTheme', () {
    test('is light unless its values say otherwise', () {
      // Light is what a theme that makes no claim about its own brightness implies, and no
      // renderer reads the reader's preference on its own.
      expect(const UniboxTheme().colorScheme, BoxColorScheme.light);
      expect(
        const UniboxTheme(colorScheme: BoxColorScheme.dark).colorScheme,
        BoxColorScheme.dark,
      );
    });

    test('keeps its scheme when another theme lends it roles', () {
      const UniboxTheme dark = UniboxTheme(colorScheme: BoxColorScheme.dark);

      expect(dark.merge(const UniboxTheme()).colorScheme, BoxColorScheme.dark);
      // And the other way round: the theme whose roles win states the scheme.
      expect(
        UniboxTheme.none.merge(dark).colorScheme,
        BoxColorScheme.light,
        reason: 'an empty theme has no claim to lend',
      );
    });
  });

  group('BoxTextStyle', () {
    test('starts empty', () {
      expect(const BoxTextStyle().isEmpty, isTrue);
      expect(const BoxTextStyle(fontSize: 16).isEmpty, isFalse);
    });

    test('stores every typography token', () {
      const style = BoxTextStyle(
        fontSize: 18,
        fontWeight: FontWeight.semiBold,
        color: BoxColor.black,
        lineHeight: 1.5,
        fontFamily: 'Inter',
        letterSpacing: 0.2,
      );

      expect(style.fontSize, 18);
      expect(style.fontWeight, FontWeight.semiBold);
      expect(style.color, BoxColor.black);
      expect(style.lineHeight, 1.5);
      expect(style.fontFamily, 'Inter');
      expect(style.letterSpacing, 0.2);
    });

    test('merge lets the overlay win', () {
      const base = BoxTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: BoxColor.black,
      );
      const overlay = BoxTextStyle(color: BoxColor.white, lineHeight: 1.4);

      final merged = base.merge(overlay);

      expect(merged.fontSize, 16);
      expect(merged.fontWeight, FontWeight.normal);
      expect(merged.color, BoxColor.white);
      expect(merged.lineHeight, 1.4);
    });

    test('merge keeps the base when the overlay is null or empty', () {
      const base = BoxTextStyle(fontSize: 16);

      expect(base.merge(null), same(base));
      expect(base.merge(const BoxTextStyle()), base);
    });

    test('copyWith replaces only the given tokens', () {
      const style = BoxTextStyle(fontSize: 16, color: BoxColor.black);

      final copy = style.copyWith(fontWeight: FontWeight.bold);

      expect(copy.fontSize, 16);
      expect(copy.color, BoxColor.black);
      expect(copy.fontWeight, FontWeight.bold);
      expect(copy, isNot(style));
    });

    test('implements value equality', () {
      const style = BoxTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: BoxColor.black,
        lineHeight: 1.5,
        fontFamily: 'Inter',
        letterSpacing: 0.2,
      );

      expect(style, style.copyWith());
      expect(style.hashCode, style.copyWith().hashCode);
      expect(style, isNot(style.copyWith(fontSize: 18)));
      expect(style.toString(), contains('fontSize: 16.0'));
      expect(style.toString(), contains('fontFamily: Inter'));
    });
  });

  group('BoxTransition', () {
    test('eases over a duration', () {
      const transition = BoxTransition(duration: Duration(milliseconds: 150));

      expect(transition.duration, const Duration(milliseconds: 150));
      expect(transition.curve, BoxCurve.ease);
    });

    test('implements value equality and copyWith', () {
      const transition = BoxTransition(
        duration: Duration(milliseconds: 150),
        curve: BoxCurve.linear,
      );

      expect(transition.copyWith(), transition);
      expect(transition.hashCode, transition.copyWith().hashCode);
      expect(transition.copyWith(curve: BoxCurve.easeOut), isNot(transition));
      expect(transition.toString(), contains('0:00:00.150000'));
    });

    test('keeps the duration it is given, negative included', () {
      // A `Duration` cannot be checked in a const constructor, so a meaningless
      // one is reported by `validateTree` rather than thrown here.
      const transition = BoxTransition(duration: Duration(milliseconds: -1));

      expect(transition.duration, const Duration(milliseconds: -1));
    });
  });

  group('BoxTransform', () {
    test('leaves a box alone by default', () {
      const transform = BoxTransform();

      expect(transform.scale, 1);
      expect(transform.rotation, 0);
      expect(transform.offsetX, 0);
      expect(transform.offsetY, 0);
      expect(transform.isIdentity, isTrue);
      expect(const BoxTransform(scale: 1.1).isIdentity, isFalse);
    });

    test('interpolates every part on its own', () {
      const begin = BoxTransform(scale: 1, rotation: 0, offsetY: 0);
      const end = BoxTransform(scale: 2, rotation: 90, offsetY: -20);

      final BoxTransform half = BoxTransform.lerp(begin, end, 0.5);

      // Interpolating the parts is what CSS does with matching transform
      // functions; interpolating the composed matrix would shrink a turning box.
      expect(half.scale, 1.5);
      expect(half.rotation, 45);
      expect(half.offsetY, -10);
      expect(BoxTransform.lerp(begin, end, 0), begin);
      expect(BoxTransform.lerp(begin, end, 1), end);
    });

    test('implements value equality and copyWith', () {
      const transform = BoxTransform(scale: 1.2, offsetX: 8);

      expect(transform.copyWith(), transform);
      expect(transform.hashCode, transform.copyWith().hashCode);
      expect(transform.copyWith(rotation: 15), isNot(transform));
      expect(transform.toString(), contains('scale: 1.2'));
    });
  });

  group('BoxTransition.parts', () {
    test('falls back to the base timing for a look no part names', () {
      const transition = BoxTransition(
        duration: Duration(milliseconds: 200),
        curve: BoxCurve.easeOut,
      );

      final BoxTransitionTiming timing = transition.timingOf(
        BoxProperty.transform,
      );

      expect(timing.duration, const Duration(milliseconds: 200));
      expect(timing.curve, BoxCurve.easeOut);
      expect(timing.delay, Duration.zero);
    });

    test('lets a part ease one look before another', () {
      const transition = BoxTransition(
        duration: Duration(milliseconds: 200),
        parts: <BoxTransitionPart>[
          BoxTransitionPart(
            properties: <BoxProperty>{BoxProperty.backgroundColor},
            duration: Duration(milliseconds: 100),
          ),
          BoxTransitionPart(
            properties: <BoxProperty>{BoxProperty.transform},
            duration: Duration(milliseconds: 150),
            delay: Duration(milliseconds: 100),
            curve: BoxCurve.easeIn,
          ),
        ],
      );

      final BoxTransitionTiming paint = transition.timingOf(
        BoxProperty.backgroundColor,
      );
      final BoxTransitionTiming transform = transition.timingOf(
        BoxProperty.transform,
      );

      expect(paint.duration, const Duration(milliseconds: 100));
      expect(paint.delay, Duration.zero);
      expect(transform.duration, const Duration(milliseconds: 150));
      expect(transform.delay, const Duration(milliseconds: 100));
      expect(transform.curve, BoxCurve.easeIn);

      // The longest `delay + duration` of all the looks.
      expect(transition.totalDuration, const Duration(milliseconds: 250));
    });

    test('implements value equality for parts', () {
      const BoxTransitionPart part = BoxTransitionPart(
        properties: <BoxProperty>{BoxProperty.opacity, BoxProperty.transform},
        duration: Duration(milliseconds: 80),
        delay: Duration(milliseconds: 20),
      );

      expect(part.copyWith(), part);
      expect(part.hashCode, part.copyWith().hashCode);
      // A set of looks does not care about order.
      expect(
        part.copyWith(
          properties: <BoxProperty>{BoxProperty.transform, BoxProperty.opacity},
        ),
        part,
      );
      expect(part.end, const Duration(milliseconds: 100));
      expect(part.toString(), contains('opacity'));

      const BoxTransition transition = BoxTransition(
        duration: Duration(milliseconds: 100),
        parts: <BoxTransitionPart>[part],
      );

      expect(transition.copyWith(), transition);
      expect(transition.hashCode, transition.copyWith().hashCode);
    });
  });

  group('BoxSemantics', () {
    test('describes a plain container by default', () {
      const semantics = BoxSemantics();

      expect(semantics.role, BoxRole.none);
      expect(semantics.label, isNull);
      expect(semantics.checked, isNull);
      expect(semantics.isFocusable, isFalse);
    });

    test('states what a screen reader announces', () {
      const semantics = BoxSemantics(
        role: BoxRole.checkbox,
        label: 'Release notes',
        checked: true,
      );

      expect(semantics.role, BoxRole.checkbox);
      expect(semantics.label, 'Release notes');
      expect(semantics.checked, isTrue);
      expect(semantics.isFocusable, isTrue);
    });

    test('makes only the roles the user can act on focusable', () {
      expect(BoxRole.none.isInteractive, isFalse);
      expect(BoxRole.heading.isInteractive, isFalse);
      expect(BoxRole.button.isInteractive, isTrue);
      expect(BoxRole.checkbox.isInteractive, isTrue);
      expect(BoxRole.switch_.isInteractive, isTrue);
      expect(BoxRole.link.isInteractive, isTrue);
    });

    test('is a plain div unless it says otherwise', () {
      const semantics = BoxSemantics();

      expect(semantics.element, BoxElement.div);
      expect(semantics.element.isLandmark, isFalse);
      expect(semantics.hidden, isFalse);
      expect(semantics.liveRegion, isFalse);
      expect(semantics.expanded, isNull);
      expect(semantics.selected, isNull);
    });

    test('knows which elements are landmarks of a page', () {
      const Set<BoxElement> landmarks = <BoxElement>{
        BoxElement.main,
        BoxElement.nav,
        BoxElement.header,
        BoxElement.footer,
      };

      for (final BoxElement element in BoxElement.values) {
        expect(
          element.isLandmark,
          landmarks.contains(element),
          reason:
              '${element.name} is ${element.isLandmark ? '' : 'not '}a '
              'landmark.',
        );
      }
    });

    test('states the accessibility state both platforms expose', () {
      const semantics = BoxSemantics(
        element: BoxElement.nav,
        expanded: true,
        selected: false,
        hidden: true,
        liveRegion: true,
      );

      expect(semantics.element, BoxElement.nav);
      expect(semantics.expanded, isTrue);
      expect(semantics.selected, isFalse);
      expect(semantics.hidden, isTrue);
      expect(semantics.liveRegion, isTrue);
    });

    test('says which item of a set the box currently is', () {
      const BoxSemantics semantics = BoxSemantics(current: BoxCurrent.page);

      expect(semantics.current, BoxCurrent.page);
      expect(semantics.copyWith().current, BoxCurrent.page);
      expect(semantics, const BoxSemantics(current: BoxCurrent.page));
      expect(semantics, isNot(const BoxSemantics(current: BoxCurrent.step)));
      expect(semantics.toString(), contains('current: BoxCurrent.page'));
      expect(const BoxSemantics().current, isNull);
    });

    test('says whether a toggle button is pressed', () {
      const BoxSemantics semantics = BoxSemantics(
        role: BoxRole.button,
        pressed: true,
      );

      expect(semantics.pressed, isTrue);
      expect(semantics.copyWith().pressed, isTrue);
      expect(semantics.copyWith(pressed: false).pressed, isFalse);
      expect(semantics, isNot(const BoxSemantics(role: BoxRole.button)));
      expect(semantics.toString(), contains('pressed: true'));
      expect(const BoxSemantics().pressed, isNull);
    });

    test('copies the element and the state it is given', () {
      const semantics = BoxSemantics(role: BoxRole.button);

      final copy = semantics.copyWith(
        element: BoxElement.form,
        expanded: false,
        liveRegion: true,
      );

      expect(copy.element, BoxElement.form);
      expect(copy.expanded, isFalse);
      expect(copy.liveRegion, isTrue);
      expect(copy.role, BoxRole.button);
      expect(copy, isNot(semantics));
      expect(copy.toString(), contains('element: BoxElement.form'));
    });

    test('copyWith replaces only the given fields', () {
      const semantics = BoxSemantics(role: BoxRole.button, label: 'Submit');

      final copy = semantics.copyWith(role: BoxRole.link);

      expect(copy.role, BoxRole.link);
      expect(copy.label, 'Submit');
      expect(copy, isNot(semantics));
    });

    test('implements value equality', () {
      const semantics = BoxSemantics(
        role: BoxRole.switch_,
        label: 'Newsletter',
        checked: false,
      );

      expect(semantics, semantics.copyWith());
      expect(semantics.hashCode, semantics.copyWith().hashCode);
      expect(semantics, isNot(semantics.copyWith(checked: true)));
      expect(semantics.toString(), contains('role: BoxRole.switch_'));
      expect(semantics.toString(), contains('checked: false'));
    });
  });

  group('BoxStyle visibility', () {
    test('is visible at every width by default', () {
      const BoxStyle style = BoxStyle();

      expect(style.isVisibleEverywhere, isTrue);
      expect(style.isShownAt(0), isTrue);
      expect(style.isShownAt(5000), isTrue);
    });

    test('draws a wide-only box from its threshold up', () {
      const BoxStyle style = BoxStyle(visibleFrom: 900);

      expect(style.isVisibleEverywhere, isFalse);
      expect(style.isShownAt(899), isFalse);
      expect(style.isShownAt(900), isTrue);
      expect(style.isShownAt(1400), isTrue);
    });

    test('stops drawing a narrow-only box at its threshold', () {
      const BoxStyle style = BoxStyle(visibleUntil: 900);

      expect(style.isShownAt(899), isTrue);
      expect(style.isShownAt(900), isFalse);
    });

    test('reads a range as half open', () {
      const BoxStyle style = BoxStyle(visibleFrom: 600, visibleUntil: 900);

      expect(style.isShownAt(599), isFalse);
      expect(style.isShownAt(600), isTrue);
      expect(style.isShownAt(899), isTrue);
      expect(style.isShownAt(900), isFalse);
    });

    test('merges per field like every other token', () {
      const BoxStyle base = BoxStyle(visibleUntil: 900);
      final BoxStyle merged = base.merge(const BoxStyle(visibleFrom: 600));

      expect(merged.visibleFrom, 600);
      expect(merged.visibleUntil, 900);
    });

    test('compares and prints its thresholds', () {
      expect(
        const BoxStyle(visibleFrom: 900),
        const BoxStyle(visibleFrom: 900),
      );
      expect(
        const BoxStyle(visibleFrom: 900),
        isNot(const BoxStyle(visibleFrom: 600)),
      );
      expect(const BoxStyle(visibleUntil: 900).toString(), contains('900'));
    });

    test('is reachable from the flat parameter, and that wins', () {
      const Box box = Box(visibleFrom: 600, style: BoxStyle(visibleFrom: 2000));

      expect(box.computedStyle.visibleFrom, 600);
    });
  });

  group('BoxStyle shape', () {
    const BoxShape hexagon = BoxShape(
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      commands: <BoxPathCommand>[BoxPathMoveTo(0, 0), BoxPathClose()],
    );

    test('merges like every other token', () {
      const BoxStyle base = BoxStyle();

      expect(base.merge(const BoxStyle(shape: hexagon)).shape, hexagon);
      expect(const BoxStyle(shape: hexagon).merge(base).shape, hexagon);
      expect(
        const BoxStyle(shape: hexagon)
            .merge(const BoxStyle(backgroundColor: BoxColor.white))
            .shape,
        hexagon,
        reason: 'a style that does not name a shape keeps the one under it',
      );
    });

    test('is copied and reported by copyWith and toString', () {
      final BoxStyle style = const BoxStyle().copyWith(shape: hexagon);

      expect(style.shape, hexagon);
      expect(style.toString(), contains('BoxShape'));
      expect(style, isNot(const BoxStyle()));
    });

    test('survives resolve, which only looks colours up', () {
      const BoxStyle style = BoxStyle(
        shape: hexagon,
        corners: BoxBorderRadius(topLeft: 4, topRight: 4),
        visibleFrom: 600,
        backgroundColor: BoxColor.role(_ShapeColor.surface),
      );

      final BoxStyle resolved = style.resolve(
        const UniboxTheme(
          colors: <Enum, BoxColor>{_ShapeColor.surface: BoxColor.white},
        ),
      );

      expect(resolved.backgroundColor, BoxColor.white);
      expect(resolved.shape, hexagon);
      expect(resolved.corners, style.corners);
      expect(resolved.visibleFrom, 600);
    });
  });
}

/// A role of its own, so a cap can be resolved without the Material package.
enum _BorderCapRole { primary }
