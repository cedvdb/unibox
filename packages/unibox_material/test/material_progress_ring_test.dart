import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// The track and the value of [ring], in paint order.
List<Box> _rings(MaterialProgressRing ring) {
  final StackNode stack = ring.children.single as StackNode;

  return stack.children.cast<Box>().toList(growable: false);
}

/// The theme the ring's roles are read from, so `validateTree` can resolve them.
final UniboxTheme _theme = MaterialPalette.lightTheme;

void main() {
  group('MaterialProgressRing', () {
    test('draws a track and the part that is done, as two rings', () {
      final List<Box> rings = _rings(MaterialProgressRing(value: 0.42));

      expect(rings, hasLength(2));
      expect(
        rings.first.backgroundColor,
        MaterialProgressRing.defaultTrack,
        reason: 'the track is painted first, so the value sits over it',
      );
      expect(rings.last.backgroundColor, MaterialProgressRing.defaultIndicator);
      expect((rings.last.shape?.commands.first as BoxPathMoveTo).x, 24);
    });

    test('states the band in pixels, by writing the shape in the box grid', () {
      final List<Box> rings = _rings(
        MaterialProgressRing(value: 0.5, size: 64, thickness: 6),
      );

      // One unit is one pixel, because the view box is as wide as the box.
      expect(rings.first.shape?.viewBoxWidth, 64);
      expect(rings.last.shape?.viewBoxWidth, 64);
      expect(
        rings.first.shape?.fillRule,
        BoxFillRule.evenOdd,
        reason: 'a closed track is two circles, the inner one being the hole',
      );
      // The inner circle starts six units below the top of the box.
      expect((rings.first.shape?.commands[3] as BoxPathMoveTo).y, 6);
    });

    test('draws the value a fraction of a turn round', () {
      final Box value = _rings(MaterialProgressRing(value: 0.25)).last;
      final BoxShape shape = value.shape!;

      expect(
        shape.fillRule,
        BoxFillRule.nonZero,
        reason: 'a sector is open, so its subpaths do not cancel',
      );
      // A quarter turn from twelve o\'clock ends at three o\'clock on the rim.
      final BoxPathArcTo outer = shape.commands[1] as BoxPathArcTo;
      expect(outer.x, closeTo(48, 0.01));
      expect(outer.y, closeTo(24, 0.01));
    });

    test('clamps the value rather than reporting one', () {
      expect(_rings(MaterialProgressRing(value: -0.2)), hasLength(1));
      expect(_rings(MaterialProgressRing(value: 0)), hasLength(1));

      final List<Box> full = _rings(MaterialProgressRing(value: 1.4));
      expect(full, hasLength(2));
      expect(
        full.last.shape?.fillRule,
        BoxFillRule.evenOdd,
        reason: 'more than a turn is a closed ring, not a longer sector',
      );
    });

    test('is a sized box with a label a reader can hear', () {
      final MaterialProgressRing ring = MaterialProgressRing(
        value: 0.42,
        size: 64,
        label: '42% complete',
      );

      expect(ring.width, 64);
      expect(ring.height, 64);
      expect(ring.semantics?.label, '42% complete');
      expect(MaterialProgressRing(value: 0.42).semantics, isNull);
    });

    test('draws a tree the model can validate', () {
      final MaterialProgressRing ring = MaterialProgressRing(value: 0.42);

      expect(validateTree(ring, theme: _theme), isEmpty);
    });
  });

  group('MaterialSpinner', () {
    test('turns one step at a time and wraps after a whole turn', () {
      final MaterialSpinStore store = MaterialSpinStore(steps: 60);

      expect(store.degrees, 0);
      store.advance();
      expect(store.state, 1);
      expect(store.degrees, closeTo(6, 1e-9));

      for (int i = 0; i < 59; i++) {
        store.advance();
      }

      expect(store.state, 0, reason: 'a turn is sixty steps, then the start');
      store.onUnmount();
    });

    test('rotates the ring it draws, keeping the sweep it was given', () {
      final MaterialSpinner spinner = MaterialSpinner(sweep: 0.75, steps: 12);
      final MaterialSpinStore store = spinner.create();
      final MaterialProgressRing first =
          spinner.viewFor(store.state, store) as MaterialProgressRing;

      store.advance();
      final MaterialProgressRing second =
          spinner.viewFor(store.state, store) as MaterialProgressRing;

      expect(first.transform?.rotation, 0);
      expect(second.transform?.rotation, 30);
      expect(
        _rings(second).last.shape,
        _rings(first).last.shape,
        reason: 'the turn moves the shape, it does not redraw it',
      );

      store.dispose();
    });

    test(
      'starts its clock when a renderer mounts it, and stops on unmount',
      () {
        final MaterialSpinStore store = MaterialSpinStore(steps: 4);
        var notified = 0;
        store.addListener(() => notified++);

        expect(notified, 0, reason: 'nothing runs until a renderer mounts');
        store.onMount();
        store.onUnmount();
        store.advance();
        store.dispose();
      },
    );

    test('draws a tree the model can validate', () {
      final MaterialSpinner spinner = MaterialSpinner();
      final MaterialSpinStore store = spinner.create();

      expect(
        validateTree(spinner.viewFor(store.state, store), theme: _theme),
        isEmpty,
      );

      store.dispose();
    });
  });
}
