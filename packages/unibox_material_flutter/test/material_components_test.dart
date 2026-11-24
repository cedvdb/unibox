import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart' as material;
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

void main() {
  Future<void> draw(
    WidgetTester tester,
    core.UINode node, {
    bool native = true,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: renderFlutter(
          node,
          scope: core.UniboxScope(theme: material.MaterialPalette.lightTheme),
          substitutions: native
              ? materialComponents(icons: const <IconData>[Icons.search])
              : const UniboxSubstitutions.none(),
        ),
      ),
    ),
  );

  testWidgets('keeps the declared outline on a native card', (tester) async {
    await draw(
      tester,
      material.MaterialCard.outlined(
        children: const <core.UINode>[core.TextNode('Summary')],
      ),
    );
    final Card card = tester.widget<Card>(find.byType(Card));
    final BorderSide side = (card.shape! as RoundedRectangleBorder).side;
    expect(side.width, 1);
    expect(
      side.color,
      Color(material.MaterialPalette.light.outlineVariant.value),
    );
  });

  testWidgets('keeps the declared corner and compact native chip target', (
    tester,
  ) async {
    await draw(
      tester,
      material.MaterialChip(
        label: const core.TextNode('Two rooms'),
        onTap: () {},
      ),
    );
    final FilterChip chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(
      (chip.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(material.MaterialChip.radius),
    );
    expect(chip.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
  });

  testWidgets('hugs a native button label unless a width is declared', (
    tester,
  ) async {
    Future<void> pump(double? width) => draw(
      tester,
      core.Box(
        width: 400,
        crossAlign: core.CrossAlign.stretch,
        children: <core.UINode>[
          material.MaterialButton.filled(
            label: const core.TextNode('Confirm'),
            onTap: () {},
            width: width,
          ),
        ],
      ),
    );
    await pump(null);
    expect(tester.getSize(find.byType(FilledButton)).width, lessThan(400));
    await pump(400);
    expect(tester.getSize(find.byType(FilledButton)).width, 400);
  });

  testWidgets('replays a keyed press through the native button once', (
    tester,
  ) async {
    int calls = 0;
    await draw(
      tester,
      core.Box(
        width: 400,
        crossAlign: core.CrossAlign.stretch,
        children: <core.UINode>[
          material.MaterialButton(
            key: 'save',
            label: const core.TextNode('Save'),
            onTap: () => calls++,
          ),
        ],
      ),
    );
    expect(
      pressRecorded(const <core.BoxPress>[core.BoxPress(key: 'save')]),
      hasLength(1),
    );
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets(
    'native buttons preserve explicit dimensions and long press actions',
    (tester) async {
      int calls = 0;
      await draw(
        tester,
        material.MaterialButton(
          label: const core.TextNode('Save'),
          width: 180,
          height: 48,
          onTap: () {},
          onLongPress: () => calls++,
        ),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, 180);
      await tester.longPress(find.text('Save'));
      expect(calls, 1);
    },
  );

  testWidgets('native controls follow declared destinations through the host', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterLinkScope(
            open: (String url) => opened = url,
            child: renderFlutter(
              material.MaterialButton(
                label: const core.TextNode('Listings'),
                url: '/listings',
              ),
              scope: core.UniboxScope(
                theme: material.MaterialPalette.lightTheme,
              ),
              substitutions: materialComponents(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Listings'));
    expect(opened, '/listings');
  });

  testWidgets(
    'requires the native mapping rather than silently drawing a control',
    (tester) async {
      await draw(
        tester,
        const material.MaterialCard(
          children: <core.UINode>[core.TextNode('Card')],
        ),
        native: false,
      );
      expect(tester.takeException(), isA<StateError>());
    },
  );

  testWidgets('draws a native card with the declared content', (tester) async {
    await draw(
      tester,
      const material.MaterialCard(
        children: <core.UINode>[core.TextNode('Order summary')],
      ),
    );
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Order summary'), findsOneWidget);
  });

  testWidgets('a native button answers once and honours disabled state', (
    tester,
  ) async {
    int calls = 0;
    await draw(
      tester,
      material.MaterialButton(
        label: const core.TextNode('Save'),
        onTap: () => calls++,
      ),
    );
    expect(find.byType(FilledButton), findsOneWidget);
    await tester.tap(find.text('Save'));
    expect(calls, 1);
    await draw(
      tester,
      material.MaterialButton(
        label: const core.TextNode('Save'),
        enabled: false,
        onTap: () => calls++,
      ),
    );
    await tester.tap(find.text('Save'));
    expect(calls, 1);
  });

  testWidgets('a native segmented control reports the chosen destination', (
    tester,
  ) async {
    int selected = 0;
    await draw(
      tester,
      material.MaterialSegmentedButton(
        segments: const <material.MaterialSegment>[
          material.MaterialSegment(label: core.TextNode('Day')),
          material.MaterialSegment(label: core.TextNode('Week')),
        ],
        selected: selected,
        onSelect: (int value) => selected = value,
      ),
    );
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    await tester.tap(find.text('Week'));
    expect(selected, 1);
  });

  testWidgets('native chips preserve selection and removal actions', (
    tester,
  ) async {
    int deleted = 0;
    await draw(
      tester,
      material.MaterialChip(
        label: const core.TextNode('Brussels'),
        selected: true,
        onTap: () {},
        onRemove: () => deleted++,
      ),
    );
    expect(find.byType(InputChip), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    expect(deleted, 1);
  });

  testWidgets('native icons and icon buttons preserve their glyph and label', (
    tester,
  ) async {
    int calls = 0;
    await draw(
      tester,
      material.MaterialIconButton(
        icon: material.MaterialIcon.codePoint(
          Icons.search.codePoint,
          fontFamily: Icons.search.fontFamily ?? 'MaterialIcons',
        ),
        label: 'Search',
        onTap: () => calls++,
      ),
    );
    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byType(Icon), findsWidgets);
    await tester.tap(find.byType(IconButton));
    expect(calls, 1);
  });

  testWidgets('keeps a wrapping row of native buttons on one line', (
    tester,
  ) async {
    // The tree declares a row that wraps; the substitution replaces that row with a widget, and
    // a widget that fills the width a `Wrap` hands its children puts every button on a line of
    // its own — which is what the page held beside it did not do.
    await draw(
      tester,
      core.Box(
        direction: core.Axis.horizontal,
        wrap: true,
        gap: 12,
        children: <core.UINode>[
          material.MaterialButton.filled(
            label: const core.TextNode('Filled'),
            onTap: () {},
          ),
          material.MaterialButton.tonal(
            label: const core.TextNode('Tonal'),
            onTap: () {},
          ),
          material.MaterialButton.outlined(
            label: const core.TextNode('Outlined'),
            onTap: () {},
          ),
          material.MaterialButton.text(
            label: const core.TextNode('Text'),
            onTap: () {},
          ),
        ],
      ),
    );

    final List<Offset> at = <Offset>[
      for (final String label in <String>[
        'Filled',
        'Tonal',
        'Outlined',
        'Text',
      ])
        tester.getTopLeft(find.text(label)),
    ];

    expect(
      at.map((Offset top) => top.dy).toSet(),
      hasLength(1),
      reason: 'the four buttons share one line',
    );
    for (int i = 1; i < at.length; i++) {
      expect(
        at[i].dx,
        greaterThan(at[i - 1].dx),
        reason: 'the buttons keep the order the tree states',
      );
    }
  });

  testWidgets('paints the pill height a native chip is declared at', (
    tester,
  ) async {
    // Material's chip is 32 pixels tall and the node states it; Flutter's own chip paints 38 at
    // the standard density, so the substitution has to tell it which pill the tree asked for.
    for (final double height in <double>[
      material.MaterialChip.controlHeight,
      40,
    ]) {
      await draw(
        tester,
        material.MaterialChip(
          label: const core.TextNode('Two rooms'),
          height: height,
          onTap: () {},
        ),
      );

      expect(tester.getSize(find.byType(FilterChip)).height, height);
    }
  });

  testWidgets('hovers a native button with the palette state layer', (
    tester,
  ) async {
    // Flutter's filled button hovers with `onPrimary`; the page hovers it with `onSurface`.
    // One declaration, one hover: the widget is handed the palette's own layer.
    await draw(
      tester,
      material.MaterialButton.filled(
        label: const core.TextNode('Save'),
        onTap: () {},
      ),
    );

    final FilledButton button = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    final WidgetStateProperty<Color?> overlay = button.style!.overlayColor!;

    expect(
      overlay.resolve(<WidgetState>{WidgetState.hovered}),
      Color(material.MaterialPalette.light.hoverLayer.value),
    );
    expect(
      overlay.resolve(<WidgetState>{WidgetState.pressed}),
      Color(material.MaterialPalette.light.pressedLayer.value),
    );
    expect(overlay.resolve(<WidgetState>{WidgetState.disabled}), isNull);
  });
}
