import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// The center of the rendered root node.
Offset nodeCenter(WidgetTester tester) => tester.getCenter(find.byKey(nodeKey));

/// A box that shows a black background in [state] over a white resting one.
core.Box statedBox(
  core.BoxState state, {
  core.BoxSemantics? semantics,
  bool enabled = true,
  void Function()? onTap,
}) {
  return core.Box(
    width: 120,
    height: 48,
    enabled: enabled,
    onTap: onTap,
    semantics: semantics,
    backgroundColor: core.BoxColor.white,
    stateStyles: <core.BoxState, core.BoxStyle>{
      state: const core.BoxStyle(backgroundColor: core.BoxColor.black),
    },
  );
}

void main() {
  group('transition parts', () {
    testWidgets('waits for the delay a part asks for', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 60,
          height: 40,
          backgroundColor: core.BoxColor.white,
          transition: core.BoxTransition(
            duration: Duration(milliseconds: 200),
            parts: <core.BoxTransitionPart>[
              core.BoxTransitionPart(
                properties: core.BoxProperty.paint,
                duration: Duration(milliseconds: 100),
              ),
              core.BoxTransitionPart(
                properties: <core.BoxProperty>{core.BoxProperty.transform},
                duration: Duration(milliseconds: 100),
                delay: Duration(milliseconds: 100),
              ),
            ],
          ),
          hoverStyle: core.BoxStyle(
            backgroundColor: core.BoxColor.black,
            transform: core.BoxTransform(scale: 2),
          ),
        ),
      );

      final TestGesture pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: Offset.zero);
      addTearDown(pointer.removePointer);
      await pointer.moveTo(nodeCenter(tester));
      await tester.pump();

      // The paint starts at once…
      await tester.pump(const Duration(milliseconds: 50));
      expect(decorationOf(tester)!.color, isNot(const Color(0xFFFFFFFF)));

      // …while the scale is still waiting for its part of the timeline.
      expect(
        tester
            .widget<Transform>(inNode(find.byType(Transform)).first)
            .transform
            .entry(0, 0),
        closeTo(1, 1e-9),
      );

      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Transform>(inNode(find.byType(Transform)).first)
            .transform
            .entry(0, 0),
        closeTo(2, 1e-9),
      );
    });
  });

  group('transform and opacity', () {
    testWidgets('fades the box without moving it', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 60,
          height: 40,
          opacity: 0.4,
          backgroundColor: core.BoxColor.black,
        ),
      );

      expect(tester.widget<Opacity>(inNode(find.byType(Opacity))).opacity, 0.4);
      // The box keeps its room: a faded box is not a missing box.
      expect(tester.getSize(find.byKey(nodeKey)), const Size(60, 40));
    });

    testWidgets('scales and turns about the centre', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 60,
          height: 40,
          transform: core.BoxTransform(scale: 2, offsetX: 10),
        ),
      );

      final Transform transform = tester.widget<Transform>(
        inNode(find.byType(Transform)).first,
      );
      final Matrix4 matrix = transform.transform;

      expect(transform.alignment, Alignment.center);
      expect(matrix.entry(0, 0), closeTo(2, 1e-9));
      expect(matrix.entry(1, 1), closeTo(2, 1e-9));
      expect(matrix.entry(0, 3), closeTo(10, 1e-9));
    });

    testWidgets('eases a scale that a state introduces', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 60,
          height: 40,
          backgroundColor: core.BoxColor.white,
          transition: core.BoxTransition(duration: Duration(milliseconds: 100)),
          hoverStyle: core.BoxStyle(transform: core.BoxTransform(scale: 1.5)),
        ),
      );

      final TestGesture pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: Offset.zero);
      addTearDown(pointer.removePointer);

      double scale() => tester
          .widget<TweenAnimationBuilder<core.BoxTransform>>(
            inNode(find.byType(TweenAnimationBuilder<core.BoxTransform>)).first,
          )
          .tween
          .end!
          .scale;

      // The resting box is untransformed, and the state asks for 1.5: the value the
      // animation is heading for follows the state, the painted one eases.
      expect(scale(), 1);

      await pointer.moveTo(nodeCenter(tester));
      await tester.pump();

      expect(scale(), 1.5);

      final Transform painted = tester.widget<Transform>(
        inNode(find.byType(Transform)).first,
      );

      expect(painted.transform.entry(0, 0), lessThan(1.5));

      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Transform>(inNode(find.byType(Transform)).first)
            .transform
            .entry(0, 0),
        closeTo(1.5, 1e-9),
      );
    });

    testWidgets('fades a state that introduces an opacity', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 60,
          height: 40,
          transition: core.BoxTransition(duration: Duration(milliseconds: 100)),
          hoverStyle: core.BoxStyle(opacity: 0.5),
        ),
      );

      final TestGesture pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: Offset.zero);
      addTearDown(pointer.removePointer);
      await pointer.moveTo(nodeCenter(tester));
      await tester.pump();

      expect(
        tester
            .widget<AnimatedOpacity>(inNode(find.byType(AnimatedOpacity)))
            .opacity,
        0.5,
      );
    });
  });

  group('transitions', () {
    /// A box that eases from white to black while the pointer is over it.
    core.Box easingBox() {
      return core.Box(
        width: 120,
        height: 48,
        backgroundColor: core.BoxColor.white,
        transition: const core.BoxTransition(
          duration: Duration(milliseconds: 100),
        ),
        hoverStyle: const core.BoxStyle(backgroundColor: core.BoxColor.black),
      );
    }

    testWidgets('eases from one state to the next', (tester) async {
      await pumpNode(tester, easingBox());

      final TestGesture pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: Offset.zero);
      addTearDown(pointer.removePointer);

      expect(decorationOf(tester)?.color, const Color(0xFFFFFFFF));

      await pointer.moveTo(nodeCenter(tester));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final Color middle = decorationOf(tester)!.color!;

      // Halfway through, the box is neither colour: the change is interpolated
      // rather than swapped.
      expect(middle, isNot(const Color(0xFFFFFFFF)));
      expect(middle, isNot(const Color(0xFF000000)));

      await tester.pumpAndSettle();

      expect(decorationOf(tester)?.color, const Color(0xFF000000));
    });

    testWidgets('swaps the look instantly without a transition', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 120,
          height: 48,
          backgroundColor: core.BoxColor.white,
          hoverStyle: core.BoxStyle(backgroundColor: core.BoxColor.black),
        ),
      );

      final TestGesture pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: Offset.zero);
      addTearDown(pointer.removePointer);
      await pointer.moveTo(nodeCenter(tester));
      await tester.pump();

      expect(decorationOf(tester)?.color, const Color(0xFF000000));
    });
  });

  group('BoxState.hover', () {
    testWidgets('applies the hover style while the pointer is over the box', (
      tester,
    ) async {
      await pumpNode(tester, statedBox(core.BoxState.hover));
      expect(decorationOf(tester)?.color, const Color(0xFFFFFFFF));

      final TestGesture pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: Offset.zero);
      addTearDown(pointer.removePointer);
      await pointer.moveTo(nodeCenter(tester));
      await tester.pump();

      expect(decorationOf(tester)?.color, const Color(0xFF000000));

      await pointer.moveTo(const Offset(400, 500));
      await tester.pump();

      expect(decorationOf(tester)?.color, const Color(0xFFFFFFFF));
    });

    testWidgets('serves no hover to a disabled box', (tester) async {
      await pumpNode(tester, statedBox(core.BoxState.hover, enabled: false));

      expect(inNode(find.byType(MouseRegion)), findsNothing);
    });
  });

  group('BoxState.pressed', () {
    testWidgets('applies the pressed style while the box is held', (
      tester,
    ) async {
      await pumpNode(tester, statedBox(core.BoxState.pressed, onTap: _noop));

      final TestGesture gesture = await tester.startGesture(nodeCenter(tester));
      await tester.pump(kPressTimeout);

      expect(decorationOf(tester)?.color, const Color(0xFF000000));

      await gesture.up();
      await tester.pump();

      expect(decorationOf(tester)?.color, const Color(0xFFFFFFFF));
    });

    testWidgets('stacks the hovered and the pressed style', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          width: 120,
          height: 48,
          onTap: _noop,
          backgroundColor: core.BoxColor.white,
          stateStyles: <core.BoxState, core.BoxStyle>{
            core.BoxState.hover: core.BoxStyle(borderRadius: 4),
            core.BoxState.pressed: core.BoxStyle(
              backgroundColor: core.BoxColor.black,
            ),
          },
        ),
      );

      final TestGesture pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: Offset.zero);
      addTearDown(pointer.removePointer);
      await pointer.moveTo(nodeCenter(tester));
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(
        nodeCenter(tester),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(kPressTimeout);

      final BoxDecoration? decoration = decorationOf(tester);
      expect(decoration?.color, const Color(0xFF000000));
      expect(decoration?.borderRadius, BorderRadius.circular(4));

      await gesture.up();
      await pointer.removePointer();
    });
  });

  group('BoxState.focus', () {
    testWidgets('takes focus and applies the focus style', (tester) async {
      await pumpMaterialNode(
        tester,
        statedBox(
          core.BoxState.focus,
          onTap: _noop,
          semantics: const core.BoxSemantics(
            role: core.BoxRole.button,
            label: 'Create account',
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(decorationOf(tester)?.color, const Color(0xFF000000));
    });

    testWidgets('stays out of the tab order without a role', (tester) async {
      await pumpMaterialNode(
        tester,
        statedBox(core.BoxState.focus, onTap: _noop),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(decorationOf(tester)?.color, const Color(0xFFFFFFFF));
    });
  });

  group('keyboard activation', () {
    testWidgets('activates a focused box with enter', (tester) async {
      int taps = 0;

      await pumpMaterialNode(
        tester,
        statedBox(
          core.BoxState.focus,
          onTap: () => taps++,
          semantics: const core.BoxSemantics(role: core.BoxRole.button),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('activates a focused box with space on key up', (tester) async {
      int taps = 0;

      await pumpMaterialNode(
        tester,
        statedBox(
          core.BoxState.pressed,
          onTap: () => taps++,
          semantics: const core.BoxSemantics(role: core.BoxRole.button),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(decorationOf(tester)?.color, const Color(0xFF000000));
      expect(taps, 0);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(taps, 1);
      expect(decorationOf(tester)?.color, const Color(0xFFFFFFFF));
    });
  });

  group('semantics', () {
    testWidgets('describes the role, the label and the checked state', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(
            role: core.BoxRole.checkbox,
            label: 'Release notes',
            checked: true,
          ),
          children: <core.UINode>[core.TextNode('Release notes')],
        ),
      );

      expect(
        tester.getSemantics(find.byKey(nodeKey)),
        isSemantics(
          label: 'Release notes',
          isChecked: true,
          hasCheckedState: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('reports a disabled box and drops its callbacks', (
      tester,
    ) async {
      int taps = 0;
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        core.Box(
          enabled: false,
          onTap: () => taps++,
          semantics: const core.BoxSemantics(
            role: core.BoxRole.button,
            label: 'Create account',
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byKey(nodeKey)),
        isSemantics(
          label: 'Create account',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      expect(
        tester
            .widget<GestureDetector>(inNode(find.byType(GestureDetector)))
            .onTap,
        isNull,
      );
      expect(taps, 0);

      handle.dispose();
    });
  });
}

void _noop() {}
