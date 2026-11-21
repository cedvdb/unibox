import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

import 'support/harness.dart';

/// A component an application owns, in the shape `unibox_material`'s card has: a box that
/// states a surface and holds content.
class _Card extends core.Box {
  const _Card({super.children})
    : super(
        borderRadius: 12,
        backgroundColor: core.BoxColor.white,
        padding: const core.BoxSpacing.all(16),
      );
}

/// The same component under a name the map does not list, which is what "keyed by the exact
/// type" means: a subclass is its own node.
class _OtherCard extends _Card {
  const _OtherCard({super.children});
}

Widget _asPlatformCard(
  BuildContext context,
  core.UINode node,
  Widget? content,
) => Card(child: content);

void main() {
  testWidgets('draws the widget the application asked for', (
    WidgetTester tester,
  ) async {
    await pumpNode(
      tester,
      const _Card(children: <core.UINode>[core.TextNode('Hi')]),
      substitutions: UniboxSubstitutions(<Type, NodeSubstitution>{
        _Card: _asPlatformCard,
      }),
    );

    expect(inNode(find.byType(Card)), findsOneWidget);
    // Paint changed, information did not: the label is still the tree's.
    expect(find.text('Hi'), findsOneWidget);
  });

  testWidgets('draws the model values when nothing is substituted', (
    WidgetTester tester,
  ) async {
    await pumpNode(
      tester,
      const _Card(children: <core.UINode>[core.TextNode('Hi')]),
    );

    expect(find.byType(Card), findsNothing);
    expect(decorationOf(tester), isNotNull);
    expect(find.text('Hi'), findsOneWidget);
  });

  testWidgets('leaves a node whose type the map does not name alone', (
    WidgetTester tester,
  ) async {
    await pumpNode(
      tester,
      const core.Box(
        children: <core.UINode>[
          _Card(children: <core.UINode>[core.TextNode('card')]),
          _OtherCard(children: <core.UINode>[core.TextNode('other')]),
        ],
      ),
      substitutions: UniboxSubstitutions(<Type, NodeSubstitution>{
        _Card: _asPlatformCard,
      }),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.text('other'), findsOneWidget);
  });

  testWidgets('hands the substitute the inside, not the surface', (
    WidgetTester tester,
  ) async {
    Widget? inside;

    await pumpNode(
      tester,
      const _Card(children: <core.UINode>[core.TextNode('Hi')]),
      substitutions: UniboxSubstitutions(<Type, NodeSubstitution>{
        _Card: (BuildContext context, core.UINode node, Widget? content) {
          inside = content;

          return content ?? const SizedBox.shrink();
        },
      }),
    );

    // The padding the node states is part of the inside, so the widget wraps the content the
    // box would have drawn; the fill, the border and the radius stay the widget's business.
    expect(
      find.ancestor(of: find.text('Hi'), matching: find.byType(Padding)),
      findsWidgets,
    );
    expect(inside, isNotNull);
  });

  testWidgets('hands a leaf its node and no inside', (
    WidgetTester tester,
  ) async {
    core.UINode? handed;
    Widget? inside = const SizedBox.shrink();

    await pumpNode(
      tester,
      const core.ImageNode('https://example.test/room.png', alt: 'A room'),
      substitutions: UniboxSubstitutions(<Type, NodeSubstitution>{
        core.ImageNode:
            (BuildContext context, core.UINode node, Widget? content) {
              handed = node;
              inside = content;

              return const SizedBox(width: 4, height: 4);
            },
      }),
    );

    expect(handed, isA<core.ImageNode>());
    expect(inside, isNull);
    // The renderer's own image is gone: the substitute is the whole leaf.
    expect(find.byType(Image), findsNothing);
  });

  test('refuses a structural node', () {
    expect(
      () => UniboxSubstitutions(<Type, NodeSubstitution>{
        core.Box: _asPlatformCard,
      }),
      throwsArgumentError,
    );
    expect(
      () => UniboxSubstitutions(<Type, NodeSubstitution>{
        core.TextNode: (
          BuildContext context,
          core.UINode node,
          Widget? content,
        ) => content ?? const SizedBox.shrink(),
      }),
      throwsArgumentError,
    );
  });

  test('is empty when nothing is substituted', () {
    const UniboxSubstitutions none = UniboxSubstitutions.none();

    expect(none.isEmpty, isTrue);
    expect(none.forNode(const core.Box()), isNull);
  });
}
