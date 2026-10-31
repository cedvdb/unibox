import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';

void main() {
  group('TextNode', () {
    test('stores its text and typography tokens', () {
      const node = TextNode(
        'Hello',
        fontSize: 18,
        fontWeight: FontWeight.semiBold,
        color: BoxColor.black,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

      expect(node.text, 'Hello');
      expect(node.fontSize, 18);
      expect(node.fontWeight, FontWeight.semiBold);
      expect(node.color, BoxColor.black);
      expect(node.textAlign, TextAlign.center);
      expect(node.maxLines, 2);
      expect(node.overflow, TextOverflow.ellipsis);

      expect(node.children, isEmpty);
    });

    test('leaves styling unset by default', () {
      const node = TextNode('Hello');

      expect(node.fontSize, isNull);
      expect(node.fontWeight, isNull);
      expect(node.color, isNull);
      expect(node.textAlign, isNull);
      expect(node.maxLines, isNull);
      expect(node.overflow, isNull);
    });

    test('stores the typography tokens it can inherit', () {
      const node = TextNode(
        'Hello',
        lineHeight: 1.5,
        fontFamily: 'Inter',
        letterSpacing: 0.4,
      );

      expect(node.lineHeight, 1.5);
      expect(node.fontFamily, 'Inter');
      expect(node.letterSpacing, 0.4);
    });

    test('stores the level of the heading it is', () {
      const TextNode heading = TextNode('Title', headingLevel: 1);
      const TextNode body = TextNode('Body');

      expect(heading.headingLevel, 1);
      expect(body.headingLevel, isNull);
    });

    test('rejects a heading level no platform knows', () {
      expect(
        () => TextNode('Title', headingLevel: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => TextNode('Title', headingLevel: 7),
        throwsA(isA<AssertionError>()),
      );
    });

    test('resolves its typography from the style and the flat tokens', () {
      const node = TextNode(
        'Hello',
        fontSize: 20,
        style: BoxTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: BoxColor.black,
        ),
      );

      expect(node.computedStyle.fontSize, 20);
      expect(node.computedStyle.fontWeight, FontWeight.bold);
      expect(node.computedStyle.color, BoxColor.black);
    });

    test('resolves an empty typography without tokens', () {
      expect(const TextNode('Hello').computedStyle.isEmpty, isTrue);
    });
  });

  group('ImageNode', () {
    test('defaults to decorative alt text and natural size', () {
      const node = ImageNode('https://example.com/cat.png');

      expect(node.src, 'https://example.com/cat.png');
      expect(node.alt, '');
      expect(node.width, isNull);
      expect(node.height, isNull);
      expect(node.fit, isNull);
      expect(node.borderRadius, isNull);
      expect(node.children, isEmpty);
      // The responsive fields are opt-in, and the defaults are the answers
      // Flutter can give on its own.
      expect(node.srcSet, isEmpty);
      expect(node.sizes, isNull);
      expect(node.loading, ImageLoading.eager);
      expect(node.fetchPriority, ImageFetchPriority.auto);
      expect(node.resolvedSrcSet, isNull);
    });

    test('writes the candidates narrowest first, whatever the map order', () {
      const node = ImageNode(
        'assets/logo.png',
        srcSet: <int, String>{
          800: 'logo-800.png',
          200: 'logo-200.png',
          400: 'logo-400.png',
        },
      );

      expect(
        node.resolvedSrcSet,
        'logo-200.png 200w, logo-400.png 400w, logo-800.png 800w',
      );
    });

    test('stores media tokens', () {
      const node = ImageNode(
        'assets/logo.png',
        alt: 'Logo',
        width: 64,
        height: 64,
        fit: ImageFit.contain,
        borderRadius: 8,
      );

      expect(node.alt, 'Logo');
      expect(node.width, 64);
      expect(node.height, 64);
      expect(node.fit, ImageFit.contain);
      expect(node.borderRadius, 8);
    });
  });

  group('LinkNode', () {
    test('is a box that names a destination', () {
      const LinkNode link = LinkNode(
        'https://unibox.dev',
        padding: BoxSpacing.all(12),
        children: <UINode>[TextNode('Unibox')],
      );

      // The destination is the box: the look, the children and the layout are its own, which
      // is what lets a link be a control rather than a wrapper around one.
      expect(link, isA<Box>());
      expect(link.url, 'https://unibox.dev');
      expect(link.newTab, isFalse);
      expect(link.computedStyle.padding, const BoxSpacing.all(12));
      expect((link.children.single as TextNode).text, 'Unibox');
    });

    test('is reachable with a keyboard because an anchor is', () {
      // A container is only focusable when a role says so; a link is in the browser's tab
      // order without asking, so it is in Flutter's too. A hidden one is not.
      expect(const Box().isFocusable, isFalse);
      expect(const LinkNode('/x').isFocusable, isTrue);
      expect(
        const LinkNode('/x', semantics: BoxSemantics(hidden: true)).isFocusable,
        isFalse,
      );
      expect(const LinkNode('/x', newTab: true).newTab, isTrue);
    });
  });

  group('StackNode', () {
    test('layers its children in paint order', () {
      const stack = StackNode(
        width: 200,
        height: 100,
        children: [TextNode('back'), TextNode('front')],
      );

      expect(stack.width, 200);
      expect(stack.height, 100);
      expect(stack.children, hasLength(2));
      expect((stack.children.last as TextNode).text, 'front');
    });

    test('defaults to an unsized empty stack', () {
      const stack = StackNode();

      expect(stack.children, isEmpty);
      expect(stack.width, isNull);
      expect(stack.height, isNull);
    });
  });

  group('PositionedNode', () {
    test('stores its offsets and child', () {
      const node = PositionedNode(
        top: 4,
        right: 8,
        bottom: 12,
        left: 16,
        child: TextNode('badge'),
      );

      expect(node.top, 4);
      expect(node.right, 8);
      expect(node.bottom, 12);
      expect(node.left, 16);
      expect(node.isUnpositioned, isFalse);
      expect(node.children, hasLength(1));
      expect((node.children.single as TextNode).text, 'badge');
    });

    test('reports when no offset is set', () {
      const node = PositionedNode(child: TextNode('free'));

      expect(node.isUnpositioned, isTrue);
      expect(node.top, isNull);
      expect(node.left, isNull);
    });
  });

  group('TextInputNode', () {
    test('defaults to a single line, non obscured, uncontrolled input', () {
      const node = TextInputNode();

      expect(node.value, isNull);
      expect(node.placeholder, isNull);
      expect(node.inputType, InputType.text);
      expect(node.obscureText, isFalse);
      expect(node.multiline, isFalse);
      expect(node.maxLines, isNull);
      expect(node.enabled, isTrue);
      expect(node.readOnly, isFalse);
      expect(node.autofocus, isFalse);
      expect(node.semanticsLabel, isNull);
      expect(node.onChanged, isNull);
      expect(node.onSubmitted, isNull);
      expect(node.onFocusChanged, isNull);
      expect(node.children, isEmpty);
    });

    test('states what the form needs from the field', () {
      const node = TextInputNode(
        required: true,
        invalid: true,
        description: 'Use the address we can reach you at.',
      );

      expect(node.required, isTrue);
      expect(node.invalid, isTrue);
      expect(node.description, 'Use the address we can reach you at.');
    });

    test('assumes a field is neither required nor wrong', () {
      const node = TextInputNode();

      expect(node.required, isFalse);
      expect(node.invalid, isFalse);
      expect(node.description, isNull);
    });

    test('stores input configuration and handlers', () {
      final changed = <String>[];
      final submitted = <String>[];
      final focuses = <bool>[];
      final node = TextInputNode(
        value: 'secret',
        placeholder: 'Password',
        inputType: InputType.email,
        obscureText: true,
        multiline: true,
        maxLines: 4,
        enabled: false,
        readOnly: true,
        autofocus: true,
        semanticsLabel: 'Email address',
        onChanged: changed.add,
        onSubmitted: submitted.add,
        onFocusChanged: focuses.add,
      );

      expect(node.value, 'secret');
      expect(node.placeholder, 'Password');
      expect(node.inputType, InputType.email);
      expect(node.obscureText, isTrue);
      expect(node.multiline, isTrue);
      expect(node.maxLines, 4);
      expect(node.enabled, isFalse);
      expect(node.readOnly, isTrue);
      expect(node.autofocus, isTrue);
      expect(node.semanticsLabel, 'Email address');

      node.onChanged?.call('a');
      node.onSubmitted?.call('a');
      node.onFocusChanged?.call(true);

      expect(changed, ['a']);
      expect(submitted, ['a']);
      expect(focuses, [true]);
    });
  });

  group('UINode', () {
    test('is the common supertype of every node', () {
      final nodes = <UINode>[
        const Box(),
        const TextNode('text'),
        const ImageNode('image.png'),
        const LinkNode('https://unibox.dev'),
        const StackNode(),
        const PositionedNode(child: TextNode('positioned')),
        const TextInputNode(),
      ];

      expect(nodes, hasLength(7));
      expect(nodes.map((node) => node.runtimeType).toSet(), hasLength(7));
    });

    test('is unkeyed by default', () {
      expect(const Box().key, isNull);
      expect(const TextNode('text').key, isNull);
      expect(const ImageNode('image.png').key, isNull);
      expect(const LinkNode('https://unibox.dev').key, isNull);
      expect(const StackNode().key, isNull);
      expect(const PositionedNode(child: TextNode('x')).key, isNull);
      expect(const TextInputNode().key, isNull);
    });

    test('carries a key on every node type', () {
      const List<UINode> nodes = <UINode>[
        Box(key: 'box'),
        TextNode('text', key: 'text'),
        ImageNode('image.png', key: 'image'),
        LinkNode('https://unibox.dev', key: 'link'),
        StackNode(key: 'stack'),
        PositionedNode(child: TextNode('x'), key: 'positioned'),
        TextInputNode(key: 'input'),
      ];

      expect(nodes.map((UINode node) => node.key), <String>[
        'box',
        'text',
        'image',
        'link',
        'stack',
        'positioned',
        'input',
      ]);
    });

    test('leaf nodes have no children', () {
      expect(const TextNode('text').children, isEmpty);
      expect(const ImageNode('image.png').children, isEmpty);
      expect(const TextInputNode().children, isEmpty);
    });

    test('parents expose their child nodes', () {
      const child = TextNode('child');

      expect(const PositionedNode(child: child).children, [child]);
      expect(const Box(children: [child]).children, [child]);
      expect(const StackNode(children: [child]).children, [child]);
    });
  });

  group('EmbedNode', () {
    test('carries the implementations of its subclass', () {
      const node = _FakeEmbed(<Object>['widget', 'component'], key: 'embed');

      expect(node.implementations, <Object>['widget', 'component']);
      expect(node.key, 'embed');
      expect(node.children, isEmpty);
      expect(node, isA<UINode>());
    });

    test('exposes a wrapped child as its content', () {
      const child = TextNode('Ripple');
      const node = _FakeEmbed(<Object>['widget'], child: child);

      // The child is what an implementation wraps, so validation and the renderers
      // reach it like the content of any other parent node.
      expect(node.child, child);
      expect(node.children, <UINode>[child]);
    });
  });
}

/// A minimal embed, standing in for a host specific node.
final class _FakeEmbed extends EmbedNode {
  const _FakeEmbed(this.implementations, {super.key, super.child});

  @override
  final List<Object> implementations;
}
