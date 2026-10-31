import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// A hero of [height] that folds towards [to], with a list under it to scroll.
core.Box _viewport({required core.BoxFold fold, double height = 100}) {
  return core.Box(
    key: 'viewport',
    width: 300,
    height: 400,
    overflow: core.Overflow.scroll,
    children: <core.UINode>[
      core.Box(
        key: 'hero',
        width: 300,
        height: height,
        backgroundColor: core.BoxColor.white,
        fold: fold,
      ),
      core.Box(key: 'list', width: 300, height: 600),
    ],
  );
}

/// The distance from the top of the viewport to the top of [key].
double _topOf(WidgetTester tester, String key) =>
    tester.getTopLeft(find.byKey(ValueKey<Object>(key))).dy -
    tester.getTopLeft(find.byKey(const ValueKey<Object>('viewport'))).dy;

/// Scrolls the viewport by [dy] and lets it settle.
Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(
    find.byKey(const ValueKey<Object>('viewport')),
    Offset(0, -dy),
  );
  await tester.pumpAndSettle();
}

Finder _hero() => find.byKey(const ValueKey<Object>('hero'));

void main() {
  group('a folded box', () {
    testWidgets('paints its own look where it has not started to leave', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(
          fold: const core.BoxFold(
            to: core.BoxStyle(backgroundColor: core.BoxColor.black),
          ),
        ),
      );

      expect(_hero(), paints..rect(color: const Color(0xFFFFFFFF)));
    });

    testWidgets('paints the look in between as it leaves', (tester) async {
      await pumpNode(
        tester,
        _viewport(
          fold: const core.BoxFold(
            to: core.BoxStyle(backgroundColor: core.BoxColor.black),
          ),
        ),
      );

      // The hero is a hundred pixels tall, so fifty pixels of scroll is half way out.
      await _scroll(tester, 50);

      expect(
        _hero(),
        paints..rect(
          color: Color.lerp(
            const Color(0xFFFFFFFF),
            const Color(0xFF000000),
            0.5,
          )!,
        ),
      );
    });

    testWidgets('finishes early when the fold takes part of the exit', (
      tester,
    ) async {
      await pumpNode(
        tester,
        _viewport(
          fold: const core.BoxFold(
            to: core.BoxStyle(backgroundColor: core.BoxColor.black),
            over: 0.5,
          ),
        ),
      );

      // Half of the exit is half the hero: by then the folded look has arrived.
      await _scroll(tester, 50);

      expect(_hero(), paints..rect(color: const Color(0xFF000000)));
    });

    testWidgets('never moves what is around it', (tester) async {
      await pumpNode(
        tester,
        _viewport(fold: const core.BoxFold(to: core.BoxStyle(opacity: 0))),
      );

      expect(_topOf(tester, 'list'), 100);

      await _scroll(tester, 60);

      // The list moved because the reader scrolled, and the hero kept its slot: a fold is a
      // look, so nothing is laid out again as it runs.
      expect(_topOf(tester, 'list'), 40);
      expect(tester.getSize(_hero()).height, 100);
    });

    testWidgets('keeps its resting look where nothing scrolls', (tester) async {
      // The surface an application is drawn on does not scroll, so a box with no scrollable
      // above it never leaves — and it shows the look it states rather than a folded one.
      await pumpNode(
        tester,
        core.Box(
          key: 'viewport',
          width: 300,
          height: 100,
          backgroundColor: core.BoxColor.white,
          fold: const core.BoxFold(
            to: core.BoxStyle(backgroundColor: core.BoxColor.black),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<Object>('viewport')),
        paints..rect(color: const Color(0xFFFFFFFF)),
      );
    });
  });
}
