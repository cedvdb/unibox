import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

/// A node a package would ship: the name a developer reads is the type's.
final class PromoCard extends Box {
  const PromoCard();
}

/// A node that names itself.
final class SaleBanner extends Box {
  const SaleBanner();

  @override
  String? get debugLabel => 'sale-banner';
}

/// A generic node, whose name is the type without its arguments.
final class Wrapper<T> extends Box {
  const Wrapper();
}

/// A private node, whose name loses its underscore.
final class _Hidden extends Box {
  const _Hidden();
}

void main() {
  group('the name of a node', () {
    test('is the literal the node states', () {
      expect(const Box().debugName, 'box');
      expect(const TextNode('Hi').debugName, 'text');
      expect(const GridNode(minItemWidth: 200).debugName, 'grid');
      expect(const ImageNode('a.png', alt: 'A').debugName, 'image');
      expect(const LinkNode('/x').debugName, 'link');
      expect(const TextInputNode().debugName, 'text-input');
      expect(const StackNode().debugName, 'stack');
      expect(const OverlayNode(child: Box()).debugName, 'overlay');
    });

    test('is inherited by a subclass that names nothing', () {
      // The type is deliberately not consulted: a compiled build mangles it, and a
      // name that reads `minified:-s` in production is worse than none. So a
      // subclass reads the name of the node it extends until it states its own —
      // one override, and the only spelling that survives every build.
      expect(const PromoCard().debugName, 'box');
      expect(const Wrapper<int>().debugName, 'box');
      expect(const _Hidden().debugName, 'box');
    });

    test('never depends on a runtime type', () {
      // Whatever a build does to class names, a name is either the literal a node
      // states or `node` — which is what keeps `minified:…` out of a page.
      for (final UINode node in <UINode>[
        const Box(),
        const PromoCard(),
        const SaleBanner(),
      ]) {
        expect(node.debugName, isNot(contains('minified')));
      }
    });

    test('is the label a node gives itself', () {
      expect(const SaleBanner().debugName, 'sale-banner');
    });
  });
}
