import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// Holds the renderer to the platform's own feedback for a press.
///
/// A control in an application clicks on Android and taps on iOS, through `Feedback`, and a
/// box that draws its own press used to be silent: every control in a migrated screen lost
/// the sound and the haptic the widget it replaced had. The behaviour is the platform's; the
/// look is still the tree's.
void main() {
  final List<MethodCall> calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          calls.add(call);

          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Draws [node] under a theme that says which platform it is.
  ///
  /// `Feedback` branches on the theme rather than on the machine the test runs on, so the
  /// platform is stated here instead of being left to the host — and a debug variable is not
  /// changed, which the test binding refuses.
  Future<void> pumpOnAndroid(WidgetTester tester, core.UINode node) => pumpNode(
    tester,
    node,
    wrap: (Widget child) => Theme(
      data: ThemeData(platform: TargetPlatform.android),
      child: child,
    ),
  );

  testWidgets('clicks when the tree answers a press', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await pumpOnAndroid(
      tester,
      core.Box(width: 48, height: 48, onTap: () => tapped = true),
    );
    await tester.tap(find.byKey(nodeKey));
    await tester.pump();

    expect(tapped, isTrue);
    expect(
      calls.map((MethodCall call) => call.method),
      contains('SystemSound.play'),
    );
  });

  testWidgets('stays silent when the box is disabled', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await pumpOnAndroid(
      tester,
      core.Box(
        width: 48,
        height: 48,
        enabled: false,
        onTap: () => tapped = true,
      ),
    );
    await tester.tap(find.byKey(nodeKey), warnIfMissed: false);
    await tester.pump();

    expect(tapped, isFalse);
    expect(calls, isEmpty);
  });
}
