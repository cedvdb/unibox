import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_flutter/handover.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_core/unibox_core.dart' as core;

void main() {
  testWidgets('a covered replay target cannot activate the surface above it', (
    tester,
  ) async {
    int actions = 0;
    int barriers = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            renderFlutter(
              core.Box(
                key: 'action',
                width: 100,
                height: 40,
                onTap: () => actions++,
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => barriers++,
              ),
            ),
          ],
        ),
      ),
    );
    expect(
      pressRecorded(const <core.BoxPress>[core.BoxPress(key: 'action')]),
      isEmpty,
    );
    expect(actions, 0);
    expect(barriers, 0);
  });

  test('a disposed coordinator cannot start a new transition', () {
    final FlutterHandover handover = FlutterHandover();
    handover.dispose();
    handover.dispose();
    expect(() => handover.complete(), throwsStateError);
  });

  testWidgets(
    'direct Flutter entry needs no document and completes idempotently',
    (tester) async {
      final FlutterHandover handover = FlutterHandover();
      await tester.pumpWidget(const SizedBox());
      final Future<void> first = handover.complete();
      expect(handover.complete(), same(first));
      await first;
      expect(handover.isComplete, isTrue);
      expect(documentScrollFromPage(), Offset.zero);
    },
  );
}
