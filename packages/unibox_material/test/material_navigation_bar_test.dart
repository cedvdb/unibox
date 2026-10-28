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

/// One share of a bar: the box that carries the destination's flex factor.
Box _item(MaterialNavigationBar bar, int index) => bar.children[index] as Box;

/// The destination itself: the box a press lands on, and the one a reader hears.
Box _destination(MaterialNavigationBar bar, int index) =>
    _item(bar, index).children.single as Box;

/// The layers of one destination: the indicator, then the label above its ink.
StackNode _layers(MaterialNavigationBar bar, int index) =>
    _destination(bar, index).children.single as StackNode;

/// The indicator's animated box: the pill fades and stretches here.
Box _indicator(MaterialNavigationBar bar, int index) {
  final PositionedNode layer =
      _layers(bar, index).children.first as PositionedNode;

  return (layer.child as Box).children.first as Box;
}

/// The pill the indicator draws: its fill, its line and its clip.
MaterialInkWell _well(MaterialNavigationBar bar, int index) =>
    _indicator(bar, index).children.single as MaterialInkWell;

/// The box the pill's well draws.
Box _pill(MaterialNavigationBar bar, int index) {
  final MaterialInkStore store = MaterialInkStore();
  final Box box = _well(bar, index).viewFor(store.state, store) as Box;
  store.dispose();

  return box;
}

/// The 64 by 32 slot the icon is centred in, inside the pill.
Box _iconSlot(MaterialNavigationBar bar, int index) =>
    _content(bar, index).children.single as Box;

/// The padded content box inside the pill's ink.
///
/// A filled pill is layered — the surface, then the tints over it — and an empty one is
/// the single box it has always been, so both shapes are read here.
Box _content(MaterialNavigationBar bar, int index) {
  final UINode child = _pill(bar, index).children.single;
  final StackNode stack = child is StackNode
      ? child
      : (child as Box).children.whereType<StackNode>().single;

  return stack.children.whereType<Box>().last;
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

    test('tints and inks the pill, not the share around it', () {
      final MaterialNavigationBar bar = _bar(selected: 0);
      final Box destination = _destination(bar, 0);

      // The tints belong to the pill's well — a box inside it — and the share paints
      // nothing of its own, which is the arrangement Material draws.
      expect(destination.backgroundColor, isNull);
      expect(destination.stateStyle(BoxState.hover), isNull);
      expect(
        (_pill(bar, 0).children.single as Box).hoverStyle?.backgroundColor,
        const BoxColor.role(MaterialColorRole.hoverLayer),
      );
      expect(_pill(bar, 0).onTap, isNotNull);
      expect(
        _pill(bar, 0).semantics?.hidden,
        isTrue,
        reason: 'the pill is not a second control for a reader',
      );
    });

    test('draws the chosen icon in place of the resting one', () {
      final MaterialNavigationBar bar = _bar(selected: 1);

      expect(
        (_iconSlot(bar, 1).children.single as TextNode).text,
        'Map, chosen',
      );
      expect(
        _iconSlot(bar, 2).children,
        isEmpty,
        reason: 'a destination without a picture keeps an empty slot',
      );
    });

    test('fades and stretches the pill instead of popping it in', () {
      final MaterialNavigationBar bar = _bar(selected: 1);

      for (int i = 0; i < bar.children.length; i++) {
        final Box indicator = _indicator(bar, i);
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
        expect(_pill(bar, 0).backgroundColor, const BoxColor(0xFF00FF00));
      },
    );

    test('draws a tree the model can validate', () {
      expect(validateTree(_bar(), theme: MaterialPalette.lightTheme), isEmpty);
    });
  });
}
