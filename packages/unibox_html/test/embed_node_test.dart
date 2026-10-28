import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('an embed', () {
    test('is written into the page as the markup it carries', () {
      // The door for a web component, a `<video>`, a chart from another package: a piece
      // of the page whose content is the host's and not a node's.
      final String html = toHtml(
        const core.Box(
          children: <core.UINode>[HtmlEmbed('<sl-button>Save</sl-button>')],
        ),
      );

      expect(html, contains('<sl-button>Save</sl-button>'));
    });

    test('is not escaped, which is the point and the risk', () {
      // A `String` this target trusts. Never build one from data a reader supplied.
      expect(toHtml(const HtmlEmbed('<b>bold</b>')), contains('<b>bold</b>'));
    });

    test('carries the name of its node, like anything else', () {
      expect(
        toHtml(const HtmlEmbed('<span>x</span>')),
        contains('data-unibox-node='),
      );
    });

    test('is reported when it carries a payload for another target', () {
      // A page with a piece missing is worse than a failure.
      expect(
        () => toHtml(const _FlutterOnlyEmbed()),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('lets everything around it lay out with boxes', () {
      final String html = toHtml(
        const core.Box(
          padding: core.BoxSpacing.all(8),
          children: <core.UINode>[
            core.TextNode('Before'),
            HtmlEmbed('<hr>'),
            core.TextNode('After'),
          ],
        ),
      );

      expect(html, contains('>Before</span>'));
      expect(html, contains('<hr>'));
      expect(html, contains('>After</span>'));
    });
  });
}

/// An embed that carries no markup this target can draw.
final class _FlutterOnlyEmbed extends core.EmbedNode {
  const _FlutterOnlyEmbed();

  @override
  List<Object> get implementations => <Object>[Object()];
}
