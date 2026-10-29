import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart' show TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// The semantics node of the rendered tree root.
SemanticsData dataOf(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

void main() {
  group('headings', () {
    testWidgets('marks a text node as a heading with its level', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(tester, const core.TextNode('Title', headingLevel: 2));

      final SemanticsData data = dataOf(tester, find.text('Title'));

      expect(data.flagsCollection.isHeader, isTrue);
      expect(data.headingLevel, 2);

      handle.dispose();
    });

    testWidgets('leaves a text without a level as body text', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(tester, const core.TextNode('Body'));

      final SemanticsData data = dataOf(tester, find.text('Body'));

      expect(data.flagsCollection.isHeader, isFalse);
      expect(data.headingLevel, 0);

      handle.dispose();
    });

    testWidgets('does not change how the heading looks', (tester) async {
      await pumpNode(
        tester,
        const core.TextNode('Title', headingLevel: 1, fontSize: 24),
      );

      // A heading is structure: the element it renders to on the web brings no
      // typography of its own, and neither does the `Semantics` wrapper here.
      expect(tester.getSize(find.text('Title')).height, 36);
    });
  });

  group('elements', () {
    testWidgets('gives a list, its items and a form their Flutter role', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(element: core.BoxElement.ul),
          children: <core.UINode>[
            core.Box(
              semantics: core.BoxSemantics(element: core.BoxElement.li),
              children: <core.UINode>[core.TextNode('One')],
            ),
          ],
        ),
      );

      expect(dataOf(tester, find.byKey(nodeKey)).role, SemanticsRole.list);

      handle.dispose();
    });

    testWidgets('leaves a landmark as the container it already is', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(element: core.BoxElement.main),
          children: <core.UINode>[core.TextNode('Page')],
        ),
      );

      // Flutter's accessibility tree has no landmarks; the box is still a
      // container, and the web renderer is where `main` means something.
      expect(dataOf(tester, find.byKey(nodeKey)).role, SemanticsRole.none);

      handle.dispose();
    });
  });

  group('form fields', () {
    testWidgets('says a field is required and wrong', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpMaterialNode(
        tester,
        const core.TextInputNode(
          required: true,
          invalid: true,
          description: 'Use the address we can reach you at.',
          semanticsLabel: 'Email',
        ),
      );

      final SemanticsData data = dataOf(tester, find.byType(TextField));

      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.validationResult, SemanticsValidationResult.invalid);
      // The description is the field's hint, which a reader announces after the
      // label; a message that should also be seen stays a text node.
      expect(data.hint, 'Use the address we can reach you at.');

      handle.dispose();
    });

    testWidgets('leaves a plain field alone', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpMaterialNode(tester, const core.TextInputNode());

      // Nothing to announce, so the field keeps its own semantics untouched.
      final SemanticsData data = dataOf(tester, find.byType(TextField));

      expect(data.flagsCollection.isRequired, isNot(Tristate.isTrue));
      expect(data.validationResult, SemanticsValidationResult.none);
      expect(data.hint, isEmpty);

      handle.dispose();
    });
  });

  group('current item', () {
    testWidgets('reports the current item of a set as selected', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(
            role: core.BoxRole.link,
            current: core.BoxCurrent.page,
          ),
          children: <core.UINode>[core.TextNode('Sign up')],
        ),
      );

      // Flutter has no `aria-current`; the selected state of a set is what a phone
      // reader announces for the item that is the current one.
      expect(
        dataOf(tester, find.byKey(nodeKey)).flagsCollection.isSelected,
        Tristate.isTrue,
      );

      handle.dispose();
    });
  });

  group('a button', () {
    testWidgets('is one node: its role, its name and its action', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        core.Box(
          onTap: () {},
          semantics: const core.BoxSemantics(role: core.BoxRole.button),
          children: <core.UINode>[const core.TextNode('Save')],
        ),
      );

      final SemanticsData data = dataOf(tester, find.byKey(nodeKey));

      // One node, not two. The `Focus` widget used to describe itself, which made a
      // node of its own *inside* this one, and the label and the tap action merged
      // into that: a screen reader read "Save" with the action and without the role,
      // while the role sat on an empty parent. A native button is one node, and so is
      // this one now.
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, 'Save');
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.focus), isTrue);

      handle.dispose();
    });

    testWidgets('says when it is disabled, and takes no press', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int presses = 0;

      await pumpNode(
        tester,
        core.Box(
          enabled: false,
          onTap: () => presses++,
          semantics: const core.BoxSemantics(role: core.BoxRole.button),
          children: <core.UINode>[const core.TextNode('Save')],
        ),
      );

      final SemanticsData data = dataOf(tester, find.byKey(nodeKey));

      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        data.hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'a disabled box runs nothing',
      );

      await tester.tap(find.text('Save'), warnIfMissed: false);
      expect(presses, 0);

      handle.dispose();
    });

    testWidgets('announces a long press, which is an action of its own', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        core.Box(
          onLongPress: () {},
          children: <core.UINode>[const core.TextNode('Hold to delete')],
        ),
      );

      final SemanticsData data = dataOf(tester, find.byKey(nodeKey));

      // What a native `InkWell` offers a reader. The box is not a button: nothing here
      // runs on `Enter`, and a keyboard cannot hold a key.
      expect(data.hasAction(SemanticsAction.longPress), isTrue);
      expect(data.flagsCollection.isButton, isFalse);

      handle.dispose();
    });
  });

  group('accessibility state', () {
    testWidgets('reports an expanded, selected and live box', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        const core.Box(
          semantics: core.BoxSemantics(
            expanded: true,
            selected: true,
            liveRegion: true,
          ),
          children: <core.UINode>[core.TextNode('Saved')],
        ),
      );

      final SemanticsData data = dataOf(tester, find.byKey(nodeKey));

      expect(data.flagsCollection.isExpanded != Tristate.none, isTrue);
      expect(data.flagsCollection.isExpanded == Tristate.isTrue, isTrue);
      expect(data.flagsCollection.isSelected != Tristate.none, isTrue);
      expect(data.flagsCollection.isSelected == Tristate.isTrue, isTrue);
      expect(data.flagsCollection.isLiveRegion, isTrue);

      handle.dispose();
    });

    testWidgets('reports a toggle button as toggled, not selected', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        core.Box(
          onTap: () {},
          semantics: const core.BoxSemantics(
            role: core.BoxRole.button,
            pressed: true,
          ),
          children: <core.UINode>[core.TextNode('Two rooms')],
        ),
      );

      final SemanticsData data = dataOf(tester, find.byKey(nodeKey));

      // The state the web writes as `aria-pressed` is Flutter's `toggled`; a button
      // is not an item of a set, so `selected` stays unset.
      expect(data.flagsCollection.isToggled, Tristate.isTrue);
      expect(data.flagsCollection.isSelected, Tristate.none);

      handle.dispose();
    });

    testWidgets('reports a box that is not pressed as off', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        core.Box(
          onTap: () {},
          semantics: const core.BoxSemantics(
            role: core.BoxRole.button,
            pressed: false,
          ),
          children: <core.UINode>[core.TextNode('Studio')],
        ),
      );

      expect(
        dataOf(tester, find.byKey(nodeKey)).flagsCollection.isToggled,
        Tristate.isFalse,
      );

      handle.dispose();
    });

    testWidgets('hides a box from assistive technologies and the tab order', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpNode(
        tester,
        core.Box(
          onTap: () {},
          semantics: const core.BoxSemantics(
            role: core.BoxRole.button,
            label: 'Decorative',
            hidden: true,
          ),
        ),
      );

      final SemanticsData data = dataOf(tester, find.byKey(nodeKey));

      expect(data.flagsCollection.isHidden, isTrue);
      // A control no screen reader can see must not be reachable by keyboard
      // either, which is why a hidden box is never focusable.
      expect(
        const core.BoxSemantics(
          role: core.BoxRole.button,
          hidden: true,
        ).isFocusable,
        isFalse,
      );

      handle.dispose();
    });
  });
}
