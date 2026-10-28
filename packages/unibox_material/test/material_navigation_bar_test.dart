import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// Records the destination a press asked for.
int? _pressed;

void _select(int index) => _pressed = index;

/// The three destinations a bar of the example is given.
const List<MaterialNavigationDestination> _destinations =
    <MaterialNavigationDestination>[
      MaterialNavigationDestination(label: TextNode('Listings')),
      MaterialNavigationDestination(
        label: TextNode('Map'),
        selectedIcon: TextNode('Map, chosen'),
      ),
      MaterialNavigationDestination(
        label: TextNode('Saved'),
        semanticsLabel: 'Saved listings',
      ),
    ];

MaterialNavigationBar _bar({int selected = 0}) => MaterialNavigationBar(
  destinations: _destinations,
  selected: selected,
  onSelect: _select,
);

/// One share of a bar: the box that holds the destination's ink well.
Box _item(MaterialNavigationBar bar, int index) => bar.children[index] as Box;

/// The ink well of one share of [bar].
MaterialInkWell _well(MaterialNavigationBar bar, int index) =>
    _item(bar, index).children.single as MaterialInkWell;

/// The box an ink well draws.
Box _wellBox(MaterialInkWell well) {
  final MaterialInkStore store = MaterialInkStore();
  final Box box = well.viewFor(store.state, store) as Box;
  store.dispose();

  return box;
}

/// The box a well wraps its content in, which is where the well's padding goes.
Box _paddedBox(Box drawn) => drawn.children
    .whereType<StackNode>()
    .single
    .children
    .whereType<Box>()
    .single;

/// The column inside a destination: the indicator pill above the label.
Box _content(MaterialNavigationBar bar, int index) =>
    _paddedBox(_wellBox(_well(bar, index))).children.single as Box;

/// The pill above the label of one destination.
Box _pill(MaterialNavigationBar bar, int index) =>
    _content(bar, index).children.first as Box;

/// The colour a destination draws its label in.
BoxColor? _labelColour(MaterialNavigationBar bar, int index) =>
    _content(bar, index).textStyle?.color;

void main() {
  group('MaterialNavigationBar', () {
    test('is one row on the navigation surface, announced as a navigation', () {
      final MaterialNavigationBar bar = _bar();

      expect(bar, isA<Box>());
      expect(bar.width, double.infinity);
      expect(bar.height, MaterialNavigationBar.barHeight);
      expect(bar.height, 80);
      expect(bar.direction, Axis.horizontal);
      expect(bar.crossAlign, CrossAlign.stretch);
      expect(
        bar.backgroundColor,
        const BoxColor.role(MaterialColorRole.surfaceContainer),
      );
      expect(bar.semantics?.element, BoxElement.nav);
      expect(bar.children, hasLength(3));
      expect(bar.debugLabel, 'material-navigation-bar');
    });

    test('gives every destination an equal share, filled by its ink', () {
      final MaterialNavigationBar bar = _bar();

      for (int i = 0; i < bar.children.length; i++) {
        expect(_item(bar, i).flex, 1, reason: 'destination $i takes a share');

        final MaterialInkWell well = _well(bar, i);
        final Box drawn = _wellBox(well);
        expect(drawn.width, double.infinity);
        expect(
          drawn.height,
          MaterialNavigationBar.barHeight,
          reason: 'a tint covers the share, not the label in it',
        );
        // The room is the well's own, so the tint reaches the edges of the share.
        expect(
          _paddedBox(drawn).padding,
          const BoxSpacing(top: 12, bottom: 16),
        );
      }
    });

    test('asks for the destination a press landed on', () {
      final MaterialNavigationBar bar = _bar();

      _wellBox(_well(bar, 2)).onTap?.call();

      expect(_pressed, 2);
    });

    test('paints the pill behind the chosen icon and no other', () {
      final MaterialNavigationBar bar = _bar(selected: 1);

      for (int i = 0; i < bar.children.length; i++) {
        final Box pill = _pill(bar, i);

        expect(pill.width, MaterialNavigationBar.indicatorWidth);
        expect(pill.height, MaterialNavigationBar.indicatorHeight);
        expect(pill.borderRadius, MaterialNavigationBar.indicatorHeight / 2);
        expect(
          pill.backgroundColor,
          i == 1
              ? const BoxColor.role(MaterialColorRole.secondaryContainer)
              : null,
          reason: 'only the chosen destination has a filled pill',
        );
      }
    });

    test('draws the chosen icon in place of the resting one', () {
      final MaterialNavigationBar bar = _bar(selected: 1);

      expect((_pill(bar, 1).children.single as TextNode).text, 'Map, chosen');
      expect(
        _pill(bar, 2).children,
        isEmpty,
        reason: 'a destination without a picture keeps an empty pill',
      );
    });

    test('colours the label by state, in the label role', () {
      final MaterialNavigationBar bar = _bar(selected: 2);

      expect(
        _labelColour(bar, 0),
        const BoxColor.role(MaterialColorRole.onSurfaceVariant),
      );
      expect(
        _labelColour(bar, 1),
        const BoxColor.role(MaterialColorRole.onSurfaceVariant),
      );
      expect(
        _labelColour(bar, 2),
        const BoxColor.role(MaterialColorRole.onSurface),
        reason: 'the chosen destination is the one that stands out',
      );

      // The label fits under the pill: labelMedium is a 12 pixel size in a 16
      // pixel line, which is the last row of the bar's 80 pixels.
      final BoxTextStyle style = _content(bar, 0).textStyle!;
      expect(style.fontSize, MaterialTypography.labelMedium.fontSize);
      expect(style.fontWeight, MaterialTypography.labelMedium.fontWeight);
      expect(style.lineHeight, MaterialTypography.labelMedium.lineHeight);
      expect(style.letterSpacing, MaterialTypography.labelMedium.letterSpacing);
    });

    test('makes a button of every destination, and says which is the page', () {
      final MaterialNavigationBar bar = _bar(selected: 0);
      final List<BoxSemantics> semantics = <BoxSemantics>[
        for (int i = 0; i < bar.children.length; i++)
          _wellBox(_well(bar, i)).semantics!,
      ];

      expect(
        semantics.map((BoxSemantics s) => s.role),
        everyElement(BoxRole.button),
      );
      expect(semantics.map((BoxSemantics s) => s.selected ?? false), <bool>[
        true,
        false,
        false,
      ]);
      expect(semantics.map((BoxSemantics s) => s.current), <BoxCurrent?>[
        BoxCurrent.page,
        null,
        null,
      ]);
      expect(
        semantics.last.label,
        'Saved listings',
        reason: 'a label is announced when the destination names one',
      );
    });

    test(
      'leaves the surface and the fill to the caller when it names them',
      () {
        final MaterialNavigationBar bar = MaterialNavigationBar(
          destinations: _destinations,
          selected: 0,
          onSelect: _select,
          color: const BoxColor(0xFFFF0000),
          indicatorColor: const BoxColor(0xFF00FF00),
        );

        expect(bar.backgroundColor, const BoxColor(0xFFFF0000));
        expect(_pill(bar, 0).backgroundColor, const BoxColor(0xFF00FF00));
      },
    );

    test('draws a tree the model can validate', () {
      expect(validateTree(_bar(), theme: MaterialPalette.lightTheme), isEmpty);
    });
  });
}
