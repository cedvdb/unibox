import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

void _tap() {}

/// The palette the well's roles are read from, so `validateTree` can resolve
/// them.
final UniboxTheme _theme = MaterialPalette.lightTheme;

/// The box the well draws: the stateful node's view, where every token of the
/// well ends up.
Box _view(MaterialInkWell well, MaterialInkStore store) =>
    well.viewFor(store.state, store) as Box;

/// The stack the well holds: the ink, then the content.
StackNode _stack(Box well) => well.children.single as StackNode;

/// The drops in flight, as they are drawn.
List<PositionedNode> _ink(Box well) =>
    _stack(well).children.whereType<PositionedNode>().toList();

/// The box that carries the label, which is what sizes the well.
Box _content(Box well) => _stack(well).children.last as Box;

void main() {
  group('MaterialInkStore', () {
    test('starts a drop where the press landed', () {
      final MaterialInkStore store = MaterialInkStore()
        ..press(const BoxPoint(30, 12));

      expect(store.state.drops, hasLength(1));
      expect(store.state.drops.single.position, const BoxPoint(30, 12));
      expect(store.state.drops.single.progress, 0);

      store.onUnmount();
    });

    test('keeps a second press apart from the first', () {
      final MaterialInkStore store = MaterialInkStore()
        ..press(const BoxPoint(10, 10))
        ..press(const BoxPoint(90, 4));

      expect(
        <BoxPoint>[
          for (final MaterialInkDrop drop in store.state.drops) drop.position,
        ],
        <BoxPoint>[const BoxPoint(10, 10), const BoxPoint(90, 4)],
      );

      store.onUnmount();
    });

    test('advances a drop and forgets it when it has spread', () {
      final MaterialInkStore store = MaterialInkStore()
        ..press(const BoxPoint(0, 0));

      store.advance(materialInkDuration ~/ 2);
      expect(store.state.drops.single.progress, closeTo(0.5, 0.01));

      store.advance(materialInkDuration ~/ 2);
      expect(store.state.drops, isEmpty);

      store.onUnmount();
    });

    test('publishes a change, and not a frame that changes nothing', () {
      final MaterialInkStore store = MaterialInkStore();
      var notified = 0;
      store.addListener(() => notified++);

      store.press(const BoxPoint(1, 2));
      expect(notified, 1);

      store.advance(materialInkDuration ~/ 2);
      expect(notified, 2);

      // The drop finishes and takes itself away.
      store.advance(materialInkDuration ~/ 2);
      expect(notified, 3);

      // Nothing is in flight, so a further frame is not a change.
      store.advance(materialInkDuration);
      expect(notified, 3);

      store.onUnmount();
    });

    test('ignores ink that would arrive after the well is gone', () {
      final MaterialInkStore store = MaterialInkStore()
        ..press(const BoxPoint(0, 0))
        ..dispose();

      store.advance(materialInkDuration);

      expect(store.state.drops, hasLength(1));
    });
  });

  group('MaterialInkWell', () {
    test('paints the three state layers of the palette, and no surface', () {
      final Box well = _view(
        MaterialInkWell(onTap: _tap, child: const TextNode('Ada')),
        MaterialInkStore(),
      );

      expect(well.onTap, _tap);
      expect(
        well.hoverStyle?.backgroundColor,
        const BoxColor.role(MaterialColorRole.hoverLayer),
      );
      expect(
        well.stateStyle(BoxState.focus)?.backgroundColor,
        const BoxColor.role(MaterialColorRole.focusLayer),
      );
      expect(
        well.stateStyle(BoxState.pressed)?.backgroundColor,
        const BoxColor.role(MaterialColorRole.pressedLayer),
      );
      // No surface of its own: the fill belongs to the box around it.
      expect(well.backgroundColor, isNull);
    });

    test('fills a full-width well with its content, so a flexible part reaches the edge', () {
      final Box well = _view(
        MaterialInkWell(
          onTap: _tap,
          width: double.infinity,
          child: const TextNode('Ada'),
        ),
        MaterialInkStore(),
      );

      // A web flex column and a flex cell both shrink a start-aligned child to its
      // content, so each level has to stretch.
      expect(well.crossAlign, CrossAlign.stretch);
      expect(_content(well).width, double.infinity);
      expect(_content(well).crossAlign, CrossAlign.stretch);
    });

    test('keeps a well that has no width sized to its content', () {
      final Box well = _view(
        MaterialInkWell(onTap: _tap, child: const TextNode('Ada')),
        MaterialInkStore(),
      );

      // Stretching a well in an unbounded row would ask for an infinite width.
      expect(well.crossAlign, isNot(CrossAlign.stretch));
      expect(_content(well).crossAlign, isNot(CrossAlign.stretch));
    });

    test('eases the tint over Material\'s short fade', () {
      final Box well = _view(
        MaterialInkWell(onTap: _tap, child: const TextNode('Ada')),
        MaterialInkStore(),
      );

      expect(well.transition, MaterialInkWell.defaultTransition);
      expect(well.transition?.duration, const Duration(milliseconds: 100));
    });

    test('is a button when it can be tapped, and not otherwise', () {
      expect(
        _view(
          MaterialInkWell(onTap: _tap, child: const TextNode('Ada')),
          MaterialInkStore(),
        ).semantics?.role,
        BoxRole.button,
      );
      expect(
        _view(
          MaterialInkWell(child: const TextNode('Ada')),
          MaterialInkStore(),
        ).semantics,
        isNull,
      );
    });

    test('keeps the room for its label inside the ink', () {
      final Box content = _content(
        _view(
          MaterialInkWell(
            onTap: _tap,
            padding: const BoxSpacing.all(12),
            child: const TextNode('Ada'),
          ),
          MaterialInkStore(),
        ),
      );

      expect(content.padding, const BoxSpacing.all(12));
      expect(content.children.single, isA<TextNode>());
    });

    test('clips its content to its radius, so a drop stays inside', () {
      final Box well = _view(
        MaterialInkWell(
          onTap: _tap,
          borderRadius: 20,
          child: const TextNode('Ada'),
        ),
        MaterialInkStore(),
      );

      expect(well.borderRadius, 20);
      expect(
        well.overflow,
        Overflow.hidden,
        reason: 'the drop is clipped by the well, not by a layer that fills it',
      );
    });
    test('leaves a drop where the press landed, and takes it away', () {
      final MaterialInkStore store = MaterialInkStore();
      final MaterialInkWell well = MaterialInkWell(
        onTap: _tap,
        child: const TextNode('Ada'),
      );

      expect(_ink(_view(well, store)), isEmpty);

      // The press a renderer reports, in the well's own coordinates.
      _view(well, store).onTapDown!(
        const BoxTapEvent(position: BoxPoint(40, 12)),
      );

      final PositionedNode drop = _ink(_view(well, store)).single;
      final Box ink = drop.child as Box;

      // A circle as wide as the spread, its centre on the press: the box is placed by its
      // corner, and the drop grows by scaling out of nothing rather than by being given a
      // new size each frame — see `_dropView` for why that is what keeps a ripple cheap.
      expect(drop.left, 40 - materialInkSpread / 2);
      expect(drop.top, 12 - materialInkSpread / 2);
      expect(ink.backgroundColor, MaterialInkWell.defaultInk);
      expect(ink.width, materialInkSpread);
      expect(ink.height, materialInkSpread);
      expect(ink.borderRadius, materialInkSpread / 2);
      expect(ink.transform?.scale, 0);
      expect(ink.opacity, materialInkOpacity);

      store.advance(materialInkDuration ~/ 2);

      final Box half = _ink(_view(well, store)).single.child as Box;
      expect(half.transform?.scale, closeTo(0.5, 0.01));
      expect(half.opacity, closeTo(materialInkOpacity / 2, 0.001));

      store.advance(materialInkDuration ~/ 2);
      expect(_ink(_view(well, store)), isEmpty);

      store.dispose();
    });

    test('puts the middle of a drop on a whole pixel', () {
      // A tap carries a fraction of a pixel. Two of them on one button are the same ripple to
      // the eye, and on the web a fraction would be a look of its own: forty taps an afternoon
      // would be forty rules the sheet keeps. So the centre snaps, and the press point lives in
      // the one rule per pixel rather than in the animation.
      final MaterialInkStore store = MaterialInkStore();
      final MaterialInkWell well = MaterialInkWell(
        onTap: _tap,
        child: const TextNode('Ada'),
      );

      _view(well, store).onTapDown!(
        const BoxTapEvent(position: BoxPoint(40.4, 12.7)),
      );

      final PositionedNode drop = _ink(_view(well, store)).single;
      expect(drop.left, 40 - materialInkSpread / 2);
      expect(drop.top, 13 - materialInkSpread / 2);

      store.dispose();
    });

    test('listens to no pointer when it cannot be pressed', () {
      expect(
        _view(
          MaterialInkWell(child: const TextNode('Ada')),
          MaterialInkStore(),
        ).onTapDown,
        isNull,
        reason: 'a well that only tints renders without a client runtime',
      );
      expect(
        _view(
          MaterialInkWell(
            onTap: _tap,
            enabled: false,
            child: const TextNode('Ada'),
          ),
          MaterialInkStore(),
        ).onTapDown,
        isNull,
      );
    });

    test('paints the surface it is given under its tints', () {
      // A fill and a tint are two boxes, because a box paints one background: the
      // well's own box carries the surface and clips it, and the box inside it carries
      // the three state layers.
      final Box well = _view(
        MaterialInkWell(
          onTap: _tap,
          fill: const BoxColor(0xFF00FF00),
          border: const BoxBorder(color: BoxColor(0xFF0000FF)),
          child: const TextNode('Two rooms'),
        ),
        MaterialInkStore(),
      );

      expect(well.backgroundColor, const BoxColor(0xFF00FF00));
      expect(well.border, const BoxBorder(color: BoxColor(0xFF0000FF)));
      expect(well.hoverStyle, isNull, reason: 'the tints are not the surface');
      expect(
        (well.children.single as Box).hoverStyle?.backgroundColor,
        const BoxColor.role(MaterialColorRole.hoverLayer),
      );
    });

    test('takes a press on a target taller than the shape it paints', () {
      // Material states 48 for a touch target over a 32 pixel chip: the shape is
      // centred in the target, so the room above it is target and not paint — and a
      // press there still starts its drop where the pill would see it.
      final MaterialInkStore store = MaterialInkStore();
      final Box well = _view(
        MaterialInkWell(
          onTap: _tap,
          height: 32,
          tapTargetHeight: 48,
          child: const TextNode('Studio'),
        ),
        store,
      );

      expect(well.height, 48);
      expect(well.mainAlign, MainAlign.center);
      expect((well.children.single as Box).height, 32);

      well.onTapDown!(const BoxTapEvent(position: BoxPoint(10, 40)));

      // 40 is 4 pixels inside the pill, whose top edge is at 8.
      expect(store.state.drops.single.position, const BoxPoint(10, 32));
      store.onUnmount();
    });

    test('draws a tree the model can validate, at rest and under a press', () {
      final MaterialInkStore store = MaterialInkStore();
      final MaterialInkWell well = MaterialInkWell(
        onTap: _tap,
        borderRadius: 12,
        child: const TextNode('Ada'),
      );

      expect(validateTree(_view(well, store), theme: _theme), isEmpty);

      store.press(const BoxPoint(4, 4));
      expect(validateTree(_view(well, store), theme: _theme), isEmpty);

      store.dispose();
    });
  });

  group('a well that navigates', () {
    /// The box the well draws, with no drop in flight.
    Box view(MaterialInkWell well) {
      final MaterialInkStore store = MaterialInkStore();
      final Box box = _view(well, store);
      store.dispose();

      return box;
    }

    test(
      'puts the destination where it puts the press, and ripples for it',
      () {
        final Box shape = view(
          MaterialInkWell(url: '/sign-in', child: const TextNode('Sign in')),
        );

        // A link is a box, so the region a reader presses is the node that navigates.
        expect(shape, isA<LinkNode>());
        expect((shape as LinkNode).url, '/sign-in');
        expect(shape.onTap, isNull);
        // A destination is pressable: the ink starts on tap-down even though nothing in the
        // tree answers the tap, because the press is what opens it.
        expect(shape.onTapDown, isNotNull);
      },
    );

    test('keeps the destination on the surface when the well paints one', () {
      final Box shape = view(
        MaterialInkWell(
          url: '/sign-in',
          fill: const BoxColor.role(MaterialColorRole.primary),
          child: const TextNode('Sign in'),
        ),
      );
      // The layered case: the outer box is the surface and the anchor, and the tints are
      // one box inside it — an `<a>` inside an `<a>` would be no link at all.
      final Box tints = shape.children.single as Box;

      expect(shape, isA<LinkNode>());
      expect((shape as LinkNode).url, '/sign-in');
      // The tints are a box inside the anchor, not a second one.
      expect(tints, isNot(isA<LinkNode>()));
      // The fill survived the conversion, read the way a renderer reads it: a link built from
      // a box states the look as one bag, so the flat accessors of the copy answer null.
      expect(shape.computedStyle.backgroundColor, isNotNull);
    });

    test(
      'puts the destination on the target when a target carries the press',
      () {
        final Box target = view(
          MaterialInkWell(
            url: '/sign-in',
            height: 32,
            tapTargetHeight: 48,
            newTab: true,
            child: const TextNode('Sign in'),
          ),
        );
        final Box shape = target.children.single as Box;

        // The room a finger gets is the region that navigates, and the pill inside it is not
        // a second link — an `<a>` inside an `<a>` is no link at all.
        expect(target, isA<LinkNode>());
        expect((target as LinkNode).url, '/sign-in');
        expect(target.newTab, isTrue);
        expect(shape, isNot(isA<LinkNode>()));
      },
    );
  });
}
