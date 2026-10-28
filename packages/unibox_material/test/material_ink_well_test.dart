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

      final Box drop = _ink(_view(well, store)).single.child as Box;
      expect(drop.backgroundColor, MaterialInkWell.defaultInk);
      // At the instant of the press the drop has no width, so its centre is the
      // point that was pressed.
      expect(drop.transform?.offsetX, 40);
      expect(drop.transform?.offsetY, 12);
      expect(drop.width, 0);

      store.advance(materialInkDuration);
      expect(_ink(_view(well, store)), isEmpty);

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
}
