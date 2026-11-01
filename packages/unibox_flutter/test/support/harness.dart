import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

/// Key wrapping the rendered root node so tests can measure it.
const Key nodeKey = ValueKey<String>('unibox-node');

/// Renders [node] centered on the default 800x600 test surface.
///
/// The [Center] hands loose constraints to the node, which mirrors how a node
/// is usually embedded and keeps fixed sizes measurable. [wrap] injects
/// inherited configuration, such as a [FlutterLinkScope], around the node.
///
/// [theme] is the scope the suite usually needs — a theme and nothing else: it is wrapped into an
/// `UniboxScope` here, so a test never spells the same three fields out.
Future<void> pumpNode(
  WidgetTester tester,
  core.UINode node, {
  Widget Function(Widget child)? wrap,
  core.UniboxTheme? theme,
}) async {
  final Widget rendered = KeyedSubtree(
    key: nodeKey,
    child: renderFlutter(node, scope: core.UniboxScope(theme: theme)),
  );

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: wrap == null ? rendered : wrap(rendered)),
    ),
  );
}

/// Renders [node] inside a minimal Material app, for widgets that need a
/// [Material] ancestor, such as text fields.
Future<void> pumpMaterialNode(WidgetTester tester, core.UINode node) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: KeyedSubtree(key: nodeKey, child: renderFlutter(node)),
        ),
      ),
    ),
  );
}

/// Restricts [matching] to the subtree of the rendered root node.
Finder inNode(Finder matching) =>
    find.descendant(of: find.byKey(nodeKey), matching: matching);

/// The flex container the rendered root box built for its own children.
///
/// Every box is a flex container, empty ones included, so a tree of boxes holds
/// one flex per box. The first one below the node key is the one the root box
/// created, which is the layout a test about `direction`, `gap` or alignment
/// means.
Flex rootFlex(WidgetTester tester) {
  return tester.widget<Flex>(
    inNode(find.byWidgetPredicate((Widget widget) => widget is Flex)).first,
  );
}

/// The decoration painted by the rendered root node, if any.
BoxDecoration? decorationOf(WidgetTester tester) {
  final Finder finder = inNode(find.byType(DecoratedBox));
  if (finder.evaluate().isEmpty) {
    return null;
  }
  return tester.widget<DecoratedBox>(finder.first).decoration as BoxDecoration;
}
