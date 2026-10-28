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
    test('is its type in kebab case', () {
      expect(const Box().debugName, 'box');
      expect(const TextNode('Hi').debugName, 'text');
      expect(const GridNode(minItemWidth: 200).debugName, 'grid');
      expect(const ImageNode('a.png', alt: 'A').debugName, 'image');
      expect(const LinkNode('/x', child: TextNode('Go')).debugName, 'link');
      expect(const TextInputNode().debugName, 'text-input');
      expect(const StackNode().debugName, 'stack');
      expect(const OverlayNode(child: Box()).debugName, 'overlay');
    });

    test('is the type of a subclass, so a design system is named', () {
      expect(const PromoCard().debugName, 'promo-card');
    });

    test('drops generics and a leading underscore', () {
      expect(const Wrapper<int>().debugName, 'wrapper');
      expect(const _Hidden().debugName, 'hidden');
    });

    test('is the label a node gives itself', () {
      expect(const SaleBanner().debugName, 'sale-banner');
    });
  });
}
