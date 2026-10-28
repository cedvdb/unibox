import '../enums.dart';
import 'ui_node.dart';

/// A network or bundled image.
class ImageNode extends UINode {
  /// Creates an image node.
  const ImageNode(
    this.src, {
    super.key,
    this.alt = '',
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.srcSet = const <int, String>{},
    this.sizes,
    this.loading = ImageLoading.eager,
    this.fetchPriority = ImageFetchPriority.auto,
  });

  /// The location of the image.
  ///
  /// Absolute URLs are loaded from the network, relative paths refer to assets
  /// bundled with the Flutter application or served by the website.
  final String src;

  /// Alternative text used by screen readers and when loading fails.
  final String alt;

  /// The width in logical pixels, or `double.infinity` to expand.
  final double? width;

  /// The height in logical pixels, or `double.infinity` to expand.
  final double? height;

  /// How the image fills its bounds.
  ///
  /// `null` means [resolvedFit].
  final ImageFit? fit;

  /// The fit both renderers apply; [ImageFit.scaleDown] when the node names none.
  ///
  /// The default belongs to the model, because a renderer would otherwise fall
  /// back to its own platform: Flutter's `Image` scales a picture down and never
  /// enlarges it, while a browser stretches it over its box. An image that
  /// declares no fit therefore used to be squashed on the web and letterboxed in
  /// Flutter, which is a difference the tree never asked for.
  ImageFit get resolvedFit => fit ?? ImageFit.scaleDown;

  /// The corner radius in logical pixels.
  final double? borderRadius;

  /// The candidates a browser may pick from, by width in logical pixels.
  ///
  /// `{200: 'logo-200.png', 400: 'logo-400.png'}` asks the browser to pick the
  /// narrowest candidate that covers the slot the image is laid out in, at the
  /// screen's pixel ratio. The web renderer writes it as the `srcset` attribute.
  ///
  /// Flutter has no counterpart: an `Image` loads exactly one source, so the
  /// Flutter rendering uses [src] and the candidates are a web optimisation. Ship
  /// [src] at the size a phone needs, and the denser candidates are free.
  final Map<int, String> srcSet;

  /// How wide the image is laid out, in CSS's `sizes` syntax.
  ///
  /// `'(min-width: 800px) 640px, 100vw'` says the image is 640 wide on a wide
  /// screen and the whole viewport otherwise, which is what a browser needs to
  /// choose from [srcSet] *before* it has laid the page out. Read only with
  /// [srcSet]; on its own it names nothing. Flutter ignores it.
  final String? sizes;

  /// When a browser should fetch the image.
  ///
  /// [ImageLoading.eager] is the default because it is what Flutter does, and a
  /// model default has to be the answer both targets can give.
  final ImageLoading loading;

  /// How much a browser should prioritise the image against the others.
  final ImageFetchPriority fetchPriority;

  /// The `srcset` attribute value: one `url width` candidate per entry, narrowest
  /// first.
  ///
  /// The order is the model's, not the renderer's, so the attribute does not
  /// depend on the order a map happened to be built in: two trees with the same
  /// candidates produce the same HTML.
  String? get resolvedSrcSet {
    if (srcSet.isEmpty) return null;

    final List<int> widths = srcSet.keys.toList()..sort();
    return <String>[
      for (final int width in widths) '${srcSet[width]} ${width}w',
    ].join(', ');
  }

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'image';
}
