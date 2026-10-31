import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

void main() {
  group('Box', () {
    test('defaults to an empty, style-less container', () {
      const box = Box();

      expect(box.children, isEmpty);
      expect(box.computedStyle, const BoxStyle());
      expect(box.hasHoverStyle, isFalse);
      expect(box.computedHoverStyle, const BoxStyle());
      expect(box.isInteractive, isFalse);
    });

    test('reaches the shape from the flat parameter, and that wins', () {
      const BoxShape hexagon = BoxShape(
        viewBoxWidth: 10,
        viewBoxHeight: 10,
        commands: <BoxPathCommand>[BoxPathMoveTo(0, 0), BoxPathClose()],
      );
      const Box box = Box(
        shape: BoxShape.circle,
        styles: <BoxStyle>[BoxStyle(shape: hexagon)],
      );

      expect(box.computedStyle.shape, BoxShape.circle);
      expect(
        const Box(styles: <BoxStyle>[BoxStyle(shape: hexagon)])
            .computedStyle
            .shape,
        hexagon,
        reason: 'a bag still reaches the token when no flat parameter names it',
      );
    });

    test('reaches the ratio from the flat parameter, and that wins', () {
      const Box box = Box(
        aspectRatio: 1.5,
        styles: <BoxStyle>[BoxStyle(aspectRatio: 2)],
      );

      expect(box.computedStyle.aspectRatio, 1.5);
      expect(
        const Box(styles: <BoxStyle>[BoxStyle(aspectRatio: 2)])
            .computedStyle
            .aspectRatio,
        2,
        reason: 'a bag still reaches the token when no flat parameter names it',
      );
    });

    test(
      'reaches the writing direction from the flat parameter, and that wins',
      () {
        const Box box = Box(
          writingDirection: WritingDirection.rtl,
          styles: <BoxStyle>[BoxStyle(writingDirection: WritingDirection.ltr)],
        );

        expect(box.computedStyle.writingDirection, WritingDirection.rtl);
        expect(
          const Box(
            styles: <BoxStyle>[
              BoxStyle(writingDirection: WritingDirection.rtl),
            ],
          ).computedStyle.writingDirection,
          WritingDirection.rtl,
          reason:
              'a bag still reaches the token when no flat parameter names it',
        );
        expect(
          const Box().computedStyle.writingDirection,
          isNull,
          reason:
              'the box says nothing, and neither does the model on its behalf',
        );
      },
    );

    test('exposes children in order', () {
      const box = Box(children: [TextNode('a'), TextNode('b')]);

      expect(box.children, hasLength(2));
      expect((box.children.first as TextNode).text, 'a');
    });

    test('uses the style tokens when no flat parameter is given', () {
      const style = BoxStyle(
        direction: Axis.vertical,
        gap: 8,
        padding: BoxSpacing.all(12),
        backgroundColor: BoxColor.white,
      );
      const box = Box(styles: <BoxStyle>[style]);

      expect(box.computedStyle, style);
    });

    test('flat parameters override matching style tokens', () {
      const style = BoxStyle(
        direction: Axis.vertical,
        gap: 8,
        padding: BoxSpacing.all(12),
        backgroundColor: BoxColor.white,
        width: 100,
      );
      const box = Box(
        styles: <BoxStyle>[style],
        direction: Axis.horizontal,
        gap: 24,
        backgroundColor: BoxColor.black,
      );

      final computed = box.computedStyle;

      expect(computed.direction, Axis.horizontal);
      expect(computed.gap, 24);
      expect(computed.backgroundColor, BoxColor.black);
      // Untouched style tokens survive the merge.
      expect(computed.padding, BoxSpacing.all(12));
      expect(computed.width, 100);
    });

    test('flat parameters are used without a style', () {
      const box = Box(
        direction: Axis.horizontal,
        mainAlign: MainAlign.spaceBetween,
        crossAlign: CrossAlign.stretch,
        gap: 4,
        wrap: true,
        equalShares: true,
        flex: 2,
        gridSpan: 2,
        overflow: Overflow.hidden,
        width: double.infinity,
        height: 40,
        minWidth: 10,
        maxWidth: 200,
        minHeight: 20,
        maxHeight: 300,
        padding: BoxSpacing.all(1),
        margin: BoxSpacing.all(2),
        backgroundColor: BoxColor.black,
        borderRadius: 6,
        border: BoxBorder(width: 2),
        shadows: <BoxShadow>[BoxShadow()],
      );

      final computed = box.computedStyle;

      expect(computed.direction, Axis.horizontal);
      expect(computed.mainAlign, MainAlign.spaceBetween);
      expect(computed.crossAlign, CrossAlign.stretch);
      expect(computed.gap, 4);
      expect(computed.wrap, isTrue);
      expect(computed.equalShares, isTrue);
      expect(computed.flex, 2);
      expect(computed.gridSpan, 2);
      expect(computed.overflow, Overflow.hidden);
      expect(computed.width, double.infinity);
      expect(computed.height, 40);
      expect(computed.minWidth, 10);
      expect(computed.maxWidth, 200);
      expect(computed.minHeight, 20);
      expect(computed.maxHeight, 300);
      expect(computed.padding, BoxSpacing.all(1));
      expect(computed.margin, BoxSpacing.all(2));
      expect(computed.backgroundColor, BoxColor.black);
      expect(computed.borderRadius, 6);
      expect(computed.border, const BoxBorder(width: 2));
      expect(computed.shadows, const <BoxShadow>[BoxShadow()]);
    });

    test('does not mutate the style it resolves', () {
      const style = BoxStyle(gap: 8);
      const box = Box(styles: <BoxStyle>[style], gap: 16);

      box.computedStyle;

      expect(style.gap, 8);
      expect(box.styles.single, same(style));
    });

    test('hover style overlays the resting style', () {
      const style = BoxStyle(backgroundColor: BoxColor.white, borderRadius: 4);
      const hoverStyle = BoxStyle(backgroundColor: BoxColor.black);
      const box = Box(styles: <BoxStyle>[style], hoverStyle: hoverStyle);

      expect(box.hasHoverStyle, isTrue);
      expect(box.computedStyle.backgroundColor, BoxColor.white);
      expect(box.computedHoverStyle.backgroundColor, BoxColor.black);
      expect(box.computedHoverStyle.borderRadius, 4);
    });

    test('hover style wins over flat parameters while hovered', () {
      const box = Box(
        backgroundColor: BoxColor.white,
        hoverStyle: BoxStyle(backgroundColor: BoxColor.black),
      );

      expect(box.computedStyle.backgroundColor, BoxColor.white);
      expect(box.computedHoverStyle.backgroundColor, BoxColor.black);
    });

    test('resolves its typography from the style and the flat tokens', () {
      const box = Box(
        textStyle: BoxTextStyle(color: BoxColor.black),
        styles: <BoxStyle>[
          BoxStyle(
            textStyle: BoxTextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );

      expect(box.computedTextStyle.fontSize, 16);
      expect(box.computedTextStyle.fontWeight, FontWeight.bold);
      expect(box.computedTextStyle.color, BoxColor.black);
    });

    test('resolves an empty typography without a text style', () {
      expect(const Box().computedTextStyle.isEmpty, isTrue);
    });

    test('reports interactivity from its callbacks', () {
      expect(const Box(onTap: _noop).isInteractive, isTrue);
      expect(const Box(onLongPress: _noop).isInteractive, isTrue);
      expect(const Box().isInteractive, isFalse);
    });

    test('carries a scroll callback without becoming a control', () {
      void onScroll(double offset) {}

      final box = Box(overflow: Overflow.scroll, onScroll: onScroll);

      // A scroll callback is a report, not an interaction: a box that only listens to its own
      // scroll is not a button, has no hover state and is not focusable.
      expect(box.onScroll, onScroll);
      expect(box.isInteractive, isFalse);
    });

    test('is enabled by default', () {
      expect(const Box().enabled, isTrue);
    });

    test('styles every interaction state', () {
      const box = Box(
        backgroundColor: BoxColor.white,
        hoverStyle: BoxStyle(backgroundColor: BoxColor.black),
        stateStyles: <BoxState, BoxStyle>{
          BoxState.focus: BoxStyle(borderRadius: 4),
          BoxState.pressed: BoxStyle(borderRadius: 8),
          BoxState.disabled: BoxStyle(backgroundColor: BoxColor.transparent),
        },
      );

      expect(
        box.computedStyleFor(BoxState.hover).backgroundColor,
        BoxColor.black,
      );
      expect(box.computedStyleFor(BoxState.focus).borderRadius, 4);
      expect(
        box.computedStyleFor(BoxState.focus).backgroundColor,
        BoxColor.white,
      );
      expect(box.computedStyleFor(BoxState.pressed).borderRadius, 8);
      expect(
        box.computedStyleFor(BoxState.disabled).backgroundColor,
        BoxColor.transparent,
      );
    });

    test('returns the resting style for a state without tokens', () {
      const box = Box(backgroundColor: BoxColor.white);

      expect(box.computedStyleFor(BoxState.focus), box.computedStyle);
      expect(box.computedStyleFor(BoxState.pressed), box.computedStyle);
      expect(box.stateStyle(BoxState.focus), isNull);
    });

    test('treats hoverStyle as the hover state', () {
      const box = Box(hoverStyle: BoxStyle(backgroundColor: BoxColor.black));

      expect(box.hasHoverStyle, isTrue);
      expect(box.stateStyle(BoxState.hover), box.hoverStyle);
      expect(const Box().hasHoverStyle, isFalse);
      expect(
        const Box(
          stateStyles: <BoxState, BoxStyle>{
            BoxState.focus: BoxStyle(borderRadius: 2),
          },
        ).hasHoverStyle,
        isFalse,
      );
    });

    test('lets a state style win over hoverStyle', () {
      const box = Box(
        hoverStyle: BoxStyle(backgroundColor: BoxColor.black),
        stateStyles: <BoxState, BoxStyle>{
          BoxState.hover: BoxStyle(backgroundColor: BoxColor.white),
        },
      );

      expect(
        box.computedStyleFor(BoxState.hover).backgroundColor,
        BoxColor.white,
      );
    });

    test('lets the disabled state win over every other state', () {
      const box = Box(
        enabled: false,
        backgroundColor: BoxColor.white,
        stateStyles: <BoxState, BoxStyle>{
          BoxState.hover: BoxStyle(backgroundColor: BoxColor.black),
          BoxState.disabled: BoxStyle(backgroundColor: BoxColor.transparent),
        },
      );

      expect(
        box.computedStyleFor(BoxState.hover).backgroundColor,
        BoxColor.transparent,
      );
      expect(
        box.computedStyleFor(BoxState.pressed).backgroundColor,
        BoxColor.transparent,
      );
    });

    test('drops interactions while disabled', () {
      expect(const Box(onTap: _noop, enabled: false).isInteractive, isFalse);
      expect(
        const Box(onLongPress: _noop, enabled: false).isInteractive,
        isFalse,
      );
      expect(const Box(enabled: false).isInteractive, isFalse);
    });
    test('is focusable only with a role the user can act on', () {
      expect(const Box().isFocusable, isFalse);
      expect(
        const Box(semantics: BoxSemantics(role: BoxRole.heading)).isFocusable,
        isFalse,
      );
      expect(
        const Box(
          semantics: BoxSemantics(role: BoxRole.button, label: 'Submit'),
        ).isFocusable,
        isTrue,
      );
    });
  });

  group('style bags', () {
    test('merges the bags in the order they are given', () {
      const BoxStyle base = BoxStyle(
        padding: BoxSpacing.all(16),
        backgroundColor: BoxColor.white,
      );
      const BoxStyle selected = BoxStyle(backgroundColor: BoxColor.black);
      const BoxStyle compact = BoxStyle(padding: BoxSpacing.all(4));

      const Box box = Box(styles: <BoxStyle>[base, selected, compact]);
      final BoxStyle style = box.computedStyle;

      // Later bags win: the last background and the last padding.
      expect(style.backgroundColor, BoxColor.black);
      expect(style.padding, BoxSpacing.all(4));
    });

    test('lets a flat parameter win over every bag', () {
      const Box box = Box(
        styles: <BoxStyle>[
          BoxStyle(backgroundColor: BoxColor.white),
          BoxStyle(backgroundColor: BoxColor.black),
        ],
        backgroundColor: BoxColor.transparent,
      );

      expect(box.computedStyle.backgroundColor, BoxColor.transparent);
    });

    test('reaches the pin from the flat parameter, and that wins', () {
      const Box box = Box(
        pin: BoxPin.start,
        pinOffset: 56,
        styles: <BoxStyle>[BoxStyle(pin: BoxPin.end, pinOffset: 8)],
      );

      expect(box.computedStyle.pin, BoxPin.start);
      expect(box.computedStyle.resolvedPinOffset, 56);
      // A bag still reaches the token when the flat parameter leaves it out.
      expect(
        const Box(styles: <BoxStyle>[BoxStyle(pin: BoxPin.end)])
            .computedStyle
            .pin,
        BoxPin.end,
      );
    });

    test('merges the bags left to right, the last one winning', () {
      const Box box = Box(
        styles: <BoxStyle>[
          BoxStyle(backgroundColor: BoxColor.white),
          BoxStyle(backgroundColor: BoxColor.black),
        ],
      );

      expect(box.styles, hasLength(2));
      expect(box.computedStyle.backgroundColor, BoxColor.black);
    });

    test('finds a threshold in a bag as well as in a flat parameter', () {
      // The renderer asks this of every child of every box, to know which box a container
      // query belongs on, and it asks without resolving a style: a bag may state the
      // threshold that a flat parameter does not.
      expect(const Box().hasThreshold, isFalse);
      expect(const Box(visibleFrom: 600).hasThreshold, isTrue);
      expect(const Box(visibleUntil: 900).hasThreshold, isTrue);
      expect(
        const Box(styles: <BoxStyle>[BoxStyle(visibleFrom: 600)]).hasThreshold,
        isTrue,
      );
    });

    test('takes no look at all from an empty list', () {
      expect(const Box(styles: <BoxStyle>[]).computedStyle.isEmpty, isTrue);
    });
  });
}

/// A callback that does nothing.
void _noop() {}
