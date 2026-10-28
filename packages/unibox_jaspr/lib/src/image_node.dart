import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'labels.dart';
import 'stylesheet.dart';
import 'values.dart';

/// Renders a [core.ImageNode] as an `<img>`.
///
/// `src` and `alt` become the matching HTML attributes, so screen readers and
/// broken image placeholders behave like they do on any other web page. The
/// image keeps the node's size: numbers are logical pixels, `double.infinity`
/// fills the available space, and a missing dimension keeps the natural aspect
/// ratio. `fit` maps to `object-fit` and `borderRadius` to `border-radius`.
///
/// The node's responsive fields are HTML attributes: `srcSet` becomes `srcset`,
/// `sizes` becomes `sizes`, `loading` becomes `loading` and `fetchPriority`
/// becomes `fetchpriority`. A finite width or height is also written as the
/// element's `width` and `height`, which is how a browser learns the picture's
/// aspect ratio before it has fetched it and reserves the right box instead of
/// shifting the page.
///
/// In Flutter an image is a leaf box, so the element is rendered as a block
/// rather than the default inline image: the picture then occupies exactly its
/// bounds instead of adding a line box with a baseline gap around it.
class JasprImage extends StatelessComponent {
  /// Creates a renderer for [node].
  const JasprImage({required this.node, super.key});

  /// The node being rendered.
  final core.ImageNode node;

  @override
  Component build(BuildContext context) {
    final Styles styles = toImageStyles(node);
    final String? className = UniboxStylesheetScope.of(context)?.classFor(
      'image',
      declarationsOf(styles),
      (String name) => <StyleRule>[
        StyleRule(selector: Selector.className(name), styles: styles),
      ],
    );

    return img(
      src: node.src,
      alt: node.alt,
      width: _pixels(node.width),
      height: _pixels(node.height),
      attributes: withNodeAttributes(node, <String, String>{
        'srcset': ?node.resolvedSrcSet,
        'sizes': ?node.sizes,
        'loading': node.loading.name,
        'fetchpriority': node.fetchPriority.name,
      }),
      classes: className,
      styles: className == null ? styles : null,
    );
  }

  /// [value] in whole pixels, or `null` when it is missing or unbounded.
  ///
  /// The attribute is a hint for the browser's layout, so a fraction of a pixel
  /// or an infinite box has nothing to say: the CSS keeps the exact size.
  static int? _pixels(double? value) {
    if (value == null || !value.isFinite) return null;
    return value.round();
  }
}
