import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

/// Holds a recorded press to the widget that wears its key.
///
/// The press is a pointer, not a callback: it goes through the same hit testing a finger does,
/// so a platform button answers it — which is the case that was lost when the press was
/// replayed as a node's `onTap`.
void main() {
  testWidgets('presses a platform button that wears the key', (
    WidgetTester tester,
  ) async {
    int pressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FilledButton(
              key: const ValueKey<String>('checkout'),
              onPressed: () => pressed++,
              child: const Text('Checkout'),
            ),
          ),
        ),
      ),
    );

    final List<core.BoxPress> answered = pressRecorded(const <core.BoxPress>[
      core.BoxPress(key: 'checkout', dx: 0, dy: 0),
    ]);
    await tester.pump();

    expect(answered, hasLength(1));
    expect(pressed, 1);
  });

  testWidgets('leaves a key that matches nothing alone', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('nothing'))),
      ),
    );

    expect(
      pressRecorded(const <core.BoxPress>[
        core.BoxPress(key: 'gone', dx: 0, dy: 0),
      ]),
      isEmpty,
    );
  });

  testWidgets('presses a unibox box that wears the key', (
    WidgetTester tester,
  ) async {
    int tapped = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: renderFlutter(
            core.Box(
              key: 'sign-in',
              width: 80,
              height: 40,
              onTap: () => tapped++,
            ),
          ),
        ),
      ),
    );

    pressRecorded(const <core.BoxPress>[
      core.BoxPress(key: 'sign-in', dx: 0, dy: 0),
    ]);
    await tester.pump();

    expect(tapped, 1);
  });
}
