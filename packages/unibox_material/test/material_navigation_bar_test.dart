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
        icon: TextNode('Map'),
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

/// One share of a bar: the box that carries the destination's flex factor.
Box _item(MaterialNavigationBar bar, int index) => bar.children[index] as Box;

/// The destination itself: the box a press lands on, and the one a reader hears.
///
/// A destination is stateful, because a hover anywhere in its share lights the pill inside it, so
/// the box a test reads is what its view draws for [hovered].
Box _destination(MaterialNavigationBar bar, int index, {bool hovered = false}) {
  final StatefulNode<Object, Store<Object>> node =
      _item(bar, index).children.single as StatefulNode<Object, Store<Object>>;
  final Store<Object> store = node.createStore();

  return node.viewFor(hovered, store) as Box;
}

/// The layers of one destination: the indicator, then the label above its ink.
StackNode _layers(
  MaterialNavigationBar bar,
  int index, {
  bool hovered = false,
}) => _destination(bar, index, hovered: hovered).children.single as StackNode;

/// The indicator's layer: the colour pill, the ink well and the icon, in that order.
StackNode _indicator(
  MaterialNavigationBar bar,
  int index, {
  bool hovered = false,
}) {
  final PositionedNode layer =
      _layers(bar, index, hovered: hovered).children.first as PositionedNode;

  return (layer.child as Box).children.first as StackNode;
}

/// The pill's colour, which is the layer that fades and stretches.
Box _colour(MaterialNavigationBar bar, int index, {bool hovered = false}) =>
    _indicator(bar, index, hovered: hovered).children.first as Box;

/// The ink well over the colour: the layer that tints and ripples.
MaterialInkWell _well(MaterialNavigationBar bar, int index) =>
    _indicator(bar, index).children[1] as MaterialInkWell;

/// The box the ink well draws, where its tints end up.
Box _pill(MaterialNavigationBar bar, int index) {
  final MaterialInkStore store = MaterialInkStore();
  final Box box = _well(bar, index).viewFor(store.state, store) as Box;
  store.dispose();

  return box;
}

/// The icon of one destination, which sits inside the pill and is always drawn.
///
/// It is the well's content, so a press on the picture reaches the well that owns it.
UINode? _icon(MaterialNavigationBar bar, int index) {
  final StackNode stack = _pill(
    bar,
    index,
  ).children.whereType<StackNode>().single;
  final Box content = stack.children.whereType<Box>().last;
  final Box slot = content.children.single as Box;

  return slot.children.isEmpty ? null : slot.children.single;
}

/// The label of one destination, which is a layer of its own above the ink.
UINode _label(MaterialNavigationBar bar, int index) =>
    ((_layers(bar, index).children.last as PositionedNode).child as Box)
        .children
        .first;

/// The colour a destination draws its label in.
BoxColor? _labelColour(MaterialNavigationBar bar, int index) =>
    _destination(bar, index).textStyle?.color;

void main() {
  group('MaterialNavigationBar', () {
    test('is one row on the navigation surface, announced as a navigation', () {
      final MaterialNavigationBar bar = _bar();

      expect(bar, isA<Box>());
      expect(bar.width, double.infinity);
      expect(bar.height, MaterialNavigationBar.barHeight);
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

    test('makes one control of every destination, a share wide', () {
      final MaterialNavigationBar bar = _bar();

      for (int i = 0; i < bar.children.length; i++) {
        expect(_item(bar, i).flex, 1, reason: 'destination $i takes a share');

        final Box destination = _destination(bar, i);
        expect(destination.width, double.infinity);
        expect(
          destination.height,
          MaterialNavigationBar.barHeight,
          reason: 'the whole share is the target, not the pill',
        );
        expect(destination.onTap, isNotNull);
        expect(destination.semantics?.role, BoxRole.button);
      }
    });

    test('asks for the destination a press landed on', () {
      final MaterialNavigationBar bar = _bar();

      // The pill answers a press itself, and the destination answers one that lands
      // anywhere else on the share.
      _destination(bar, 2).onTap!();
      expect(_pressed, 2);

      _pill(bar, 1).onTap?.call();
      expect(_pressed, 1);
    });

    test('paints the pill behind the chosen icon and no other', () {
      final MaterialNavigationBar bar = _bar(selected: 1);

      for (int i = 0; i < bar.children.length; i++) {
        final Box pill = _colour(bar, i);

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

    test('tints and inks the pill, not the share around it', () {
      final MaterialNavigationBar bar = _bar(selected: 0);
      final Box destination = _destination(bar, 0);

      // The share paints nothing of its own — what a hover lights is the pill — and the
      // well stops tinting, so a hover is one layer rather than two over one shape.
      expect(destination.backgroundColor, isNull);
      expect(destination.stateStyle(BoxState.hover), isNull);
      expect(destination.onHover, isNotNull);
      expect(_pill(bar, 0).hoverStyle?.backgroundColor, BoxColor.transparent);
      expect(_pill(bar, 0).onTap, isNotNull);
      expect(
        _pill(bar, 0).semantics?.hidden,
        isTrue,
        reason: 'the pill is not a second control for a reader',
      );
    });

    test('lights the pill when the pointer is anywhere in the share', () {
      // Material lights the indicator when the pointer is over the destination, and the
      // destination is the whole share, not the pill inside it. The pill is a layer the
      // pointer is not over, which is why the destination keeps the hover in a store.
      final MaterialNavigationBar bar = _bar(selected: 0);

      final Box hovered = _colour(bar, 2, hovered: true);
      final Box resting = _colour(bar, 2);

      expect(
        hovered.backgroundColor,
        const BoxColor.role(MaterialColorRole.hoverLayer),
      );
      expect(hovered.opacity, 1);
      // At full width: nothing is stretching, the layer simply appears.
      expect(hovered.transform?.scaleX, 1);
      expect(resting.opacity, 0);
      expect(resting.backgroundColor, isNull);
      expect(resting.transform?.scaleX, lessThan(1));
    });

    test('keeps the indicator of the chosen destination under a hover', () {
      final MaterialNavigationBar bar = _bar(selected: 0);

      // The chosen destination shows its indicator colour either way: a hover adds a layer
      // over a surface in Material, and one colour is all a box paints.
      expect(
        _colour(bar, 0, hovered: true).backgroundColor,
        const BoxColor.role(MaterialColorRole.secondaryContainer),
      );
    });

    test('draws the icon in every state, and the chosen one in its place', () {
      final MaterialNavigationBar chosen = _bar(selected: 1);

      expect((_icon(chosen, 1) as TextNode).text, 'Map, chosen');
      expect(
        _icon(chosen, 0),
        isNull,
        reason: 'a destination without a picture draws no icon layer',
      );

      // The regression that mattered: the icon is a layer of its own, so fading the
      // pill's colour cannot fade the picture with it.
      final MaterialNavigationBar resting = _bar(selected: 2);
      expect((_icon(resting, 1) as TextNode).text, 'Map');
      expect(_colour(resting, 1).opacity, 0);
    });

    test('fades and stretches the pill instead of popping it in', () {
      final MaterialNavigationBar bar = _bar(selected: 1);

      for (int i = 0; i < bar.children.length; i++) {
        final Box indicator = _colour(bar, i);
        expect(indicator.opacity, i == 1 ? 1 : 0);
        expect(indicator.transform?.scaleX, i == 1 ? 1 : lessThan(1));
        expect(
          indicator.transform?.scaleY,
          1,
          reason: 'Material stretches the pill sideways and not vertically',
        );
        expect(indicator.transition, MaterialNavigationBar.indicatorTransition);
      }

      // Flutter's two speeds: the fade is quick, the stretch is slow.
      expect(
        MaterialNavigationBar.indicatorTransition.duration,
        const Duration(milliseconds: 100),
      );
      expect(
        MaterialNavigationBar.indicatorTransition
            .timingOf(BoxProperty.transform)
            .duration,
        const Duration(milliseconds: 500),
      );
    });

    test('colours the label by state, in the label role', () {
      final MaterialNavigationBar bar = _bar(selected: 2);

      expect(
        _labelColour(bar, 0),
        const BoxColor.role(MaterialColorRole.onSurfaceVariant),
      );
      expect(
        _labelColour(bar, 2),
        const BoxColor.role(MaterialColorRole.onSurface),
        reason: 'the chosen destination is the one that stands out',
      );
      expect((_label(bar, 0) as TextNode).text, 'Listings');

      final BoxTextStyle style = _destination(bar, 0).textStyle!;
      expect(style.fontSize, MaterialTypography.labelMedium.fontSize);
      expect(style.fontWeight, MaterialTypography.labelMedium.fontWeight);
      expect(style.lineHeight, MaterialTypography.labelMedium.lineHeight);
    });

    test('says which destination is the page, and no more', () {
      final MaterialNavigationBar bar = _bar(selected: 0);
      final List<BoxSemantics> semantics = <BoxSemantics>[
        for (int i = 0; i < bar.children.length; i++)
          _destination(bar, i).semantics!,
      ];

      expect(
        semantics.map((BoxSemantics s) => s.role),
        everyElement(BoxRole.button),
      );
      // `current` and not `selected`: `aria-selected` is not valid on a button, and
      // Flutter reads `current` as the selected state itself.
      expect(semantics.map((BoxSemantics s) => s.selected), <bool?>[
        null,
        null,
        null,
      ]);
      expect(semantics.map((BoxSemantics s) => s.current), <BoxCurrent?>[
        BoxCurrent.page,
        null,
        null,
      ]);
      expect(semantics.last.label, 'Saved listings');
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
        expect(_colour(bar, 0).backgroundColor, const BoxColor(0xFF00FF00));
      },
    );

    test('draws a tree the model can validate', () {
      expect(validateTree(_bar(), theme: MaterialPalette.lightTheme), isEmpty);
    });
  });
}
