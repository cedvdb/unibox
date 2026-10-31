import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// How a host wraps a tree that navigates: one function that decides what opening a url
/// means, and [opened] records the asks so a test can read them.
Widget Function(Widget child) opener(List<String> opened) =>
    (Widget child) =>
        FlutterLinkScope(open: (String url) => opened.add(url), child: child);

/// A box that navigates: the destination is the control, so the press, the cursor and
/// the announcement are the box's own.
///
/// The rules a link states, applied to the node a control already is — which
/// is the point of the token: a box keeps its size, its padding, its pressed state and the
/// ink that starts on tap-down, and only gains a destination.
void main() {
  group('a box with a url', () {
    const core.Box room = core.LinkNode(
      '/?category=meetingRoom',
      padding: core.BoxSpacing.all(12),
      children: <core.UINode>[core.TextNode('Meeting room')],
    );

    testWidgets('opens its destination through the enclosing scope', (
      tester,
    ) async {
      final List<String> opened = <String>[];

      await pumpNode(tester, room, wrap: opener(opened));
      await tester.tap(find.text('Meeting room'));

      expect(opened, <String>['/?category=meetingRoom']);
    });

    testWidgets('lets its own onTap answer the press instead of the opener', (
      tester,
    ) async {
      final List<String> opened = <String>[];
      int taps = 0;

      await pumpNode(
        tester,
        core.LinkNode(
          '/?category=meetingRoom',
          onTap: () => taps++,
          children: <core.UINode>[const core.TextNode('Meeting room')],
        ),
        wrap: opener(opened),
      );
      await tester.tap(find.text('Meeting room'));

      // One press, one answer: the tree answered, so the opener stands down. The url
      // stays on the node, which is what keeps the web's href for a reader without a
      // runtime and for a crawler.
      expect(taps, 1);
      expect(opened, isEmpty);
    });

    testWidgets('shows a click cursor', (tester) async {
      await pumpNode(tester, room, wrap: opener(<String>[]));

      final MouseRegion region = tester.widget<MouseRegion>(
        inNode(find.byType(MouseRegion)),
      );

      // A destination is a hand even with no callback: the pointer is the cue a reader
      // gets before the press, and the web gets the same one from the element.
      expect(region.cursor, SystemMouseCursors.click);
    });

    testWidgets('is exposed as a link, and as nothing else', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        const core.LinkNode(
          '/?category=meetingRoom', // A component written for a button: the tag decides, so the box says "link"
          // and drops the pressed state a link cannot have.
          semantics: core.BoxSemantics(
            role: core.BoxRole.button,
            label: 'Meeting room',
            pressed: true,
          ),
          children: <core.UINode>[core.TextNode('Meeting room')],
        ),
        wrap: opener(<String>[]),
      );

      final SemanticsData data = tester
          .getSemantics(find.byKey(nodeKey))
          .getSemanticsData();

      expect(data.flagsCollection.isLink, isTrue);
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isToggled, Tristate.none);
      expect(data.label, 'Meeting room');

      handle.dispose();
    });

    testWidgets('starts a press on tap-down, so the ink has an origin', (
      tester,
    ) async {
      // A well's ripple starts on `onTapDown`, and a destination that answered only a
      // completed tap would ripple after the page had already changed.
      final List<core.BoxPoint> presses = <core.BoxPoint>[];

      await pumpNode(
        tester,
        core.LinkNode(
          '/?category=meetingRoom',
          onTapDown: (core.BoxTapEvent event) => presses.add(event.position),
          width: 200,
          height: 48,
          children: <core.UINode>[const core.TextNode('Meeting room')],
        ),
        wrap: opener(<String>[]),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(nodeKey)),
      );
      await tester.pump();

      expect(presses, hasLength(1));

      await gesture.up();
      await tester.pump();
    });

    testWidgets('reports a destination it can neither open nor call back', (
      tester,
    ) async {
      await pumpNode(tester, room);

      // Without a scope and without an onTap a press does nothing, which is a host
      // configuration error rather than a control that quietly ignores its reader.
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('opens from the keyboard with Enter, and not with Space', (
      tester,
    ) async {
      final List<String> opened = <String>[];

      await pumpNode(tester, room, wrap: opener(opened));

      // A link is in the tab order on the web, so it is reachable here too. A tree
      // rendered bare has no traversal to walk, so the focus is asked for by hand.
      final Focus focus = tester.widget<Focus>(
        inNode(find.byType(Focus)).first,
      );
      focus.focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(
        opened,
        isEmpty,
        reason: 'a browser does nothing with Space on an anchor',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(opened, <String>['/?category=meetingRoom']);
    });
  });
}
