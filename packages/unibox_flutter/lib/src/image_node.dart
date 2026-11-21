import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'substitutions.dart';
import 'values.dart';

/// Renders a [core.ImageNode] as a Flutter [Image].
///
/// An image that fails to load keeps the declared size instead of throwing, so
/// a broken source never breaks the surrounding layout. The [core.ImageNode.alt]
/// text is exposed as the semantic label for screen readers.
///
/// The fit is always passed, even when the node names none: the renderer would
/// otherwise leave the question to `Image`, whose answer is its own, while the
/// web renderer would leave it to the browser's `object-fit: fill`.
///
/// The responsive fields of the node — [core.ImageNode.srcSet],
/// [core.ImageNode.sizes], [core.ImageNode.loading] and
/// [core.ImageNode.fetchPriority] — are not read here. Flutter loads one source,
/// so [core.ImageNode.src] is what a device gets; the web renderer writes the four
/// as `<img>` attributes. This is a deliberate difference between the two
/// renderings, recorded in both READMEs: a candidate list is a web optimisation
/// and a model cannot ask Skia to pick from it.
class FlutterImage extends StatelessWidget {
  /// Creates a renderer for [node].
  const FlutterImage({required this.node, super.key});

  /// The node being rendered.
  final core.ImageNode node;

  @override
  Widget build(BuildContext context) {
    // An image is the leaf an application most often owns: a cache, a placeholder of the
    // same height, a blurhash. The node still says which picture, how big, how it is fitted
    // and what a reader calls it, so a substitution changes how the bytes arrive and never
    // what the page says.
    final Widget? substituted = UniboxSubstitutionsWidget.substitute(
      context,
      node,
      null,
    );

    if (substituted != null) {
      return substituted;
    }

    final double? borderRadius = node.borderRadius;

    final Widget image = Image(
      image: toImageProvider(node.src),
      width: node.width,
      height: node.height,
      fit: toBoxFit(node.resolvedFit),
      semanticLabel: node.alt.isEmpty ? null : node.alt,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) => SizedBox(width: node.width, height: node.height),
    );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}
