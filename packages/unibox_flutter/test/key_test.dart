import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// Two keyed inputs whose order the test can flip.
///
/// The widget keeps its `State` across pumps, so the rendered fields are reused
/// exactly like they are when a list is reordered in a real application.
class ReorderHost extends StatefulWidget {
  /// Creates the host with the given child order.
  const ReorderHost({required this.reversed, super.key});

  /// Whether the two inputs are rendered in reverse order.
  final bool reversed;

  @override
  State<ReorderHost> createState() => _ReorderHostState();
}

class _ReorderHostState extends State<ReorderHost> {
  static const List<core.UINode> _inputs = <core.UINode>[
    core.TextInputNode(key: 'email', placeholder: 'Email'),
    core.TextInputNode(key: 'name', placeholder: 'Name'),
  ];

  @override
  Widget build(BuildContext context) {
    final List<core.UINode> children = widget.reversed
        ? _inputs.reversed.toList()
        : _inputs;

    return core.Box(
      direction: core.Axis.vertical,
      gap: 8,
      children: children,
    ).toWidget();
  }
}

/// Pumps the reorder host with its inputs in the requested order.
Future<void> pumpHost(WidgetTester tester, {required bool reversed}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: ReorderHost(reversed: reversed)),
      ),
    ),
  );
}

/// The field rendered for the node with [key].
Finder fieldOf(String key) => find.descendant(
  of: find.byKey(ValueKey<Object>(key)),
  matching: find.byType(TextField),
);

/// The text currently shown by the field of the node with [key].
String textOf(WidgetTester tester, String key) =>
    tester.widget<TextField>(fieldOf(key)).controller!.text;

void main() {
  group('UINode.key', () {
    testWidgets('keeps typed text with its node when the order changes', (
      tester,
    ) async {
      await pumpHost(tester, reversed: false);
      await tester.enterText(fieldOf('email'), 'ada@example.com');
      await tester.enterText(fieldOf('name'), 'Ada');

      await pumpHost(tester, reversed: true);

      expect(textOf(tester, 'email'), 'ada@example.com');
      expect(textOf(tester, 'name'), 'Ada');
    });

    testWidgets('leaves an unkeyed node without a widget key', (tester) async {
      await pumpMaterialNode(tester, const core.TextInputNode());

      expect(tester.widget<TextField>(find.byType(TextField)).key, isNull);
    });

    testWidgets('keys every renderer it renders', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          key: 'root',
          children: <core.UINode>[core.TextNode('Hello', key: 'greeting')],
        ),
      );

      expect(find.byKey(const ValueKey<Object>('root')), findsOneWidget);
      expect(find.byKey(const ValueKey<Object>('greeting')), findsOneWidget);
    });

    testWidgets('keys a positioned stack child', (tester) async {
      await pumpNode(
        tester,
        const core.StackNode(
          width: 100,
          height: 100,
          children: <core.UINode>[
            core.PositionedNode(
              key: 'badge',
              top: 4,
              left: 4,
              child: core.TextNode('1'),
            ),
          ],
        ),
      );

      expect(find.byKey(const ValueKey<Object>('badge')), findsOneWidget);
    });
  });
}
