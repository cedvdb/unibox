import 'package:unibox_core/unibox_core.dart';

/// An `<iframe>` as a node.
///
/// A frame is content only the web can draw, which is what an embed is for. The showcase page
/// uses two of them to put the two renderings side by side.
final class IframeNode extends EmbedNode {
  /// Creates a frame showing [src], named [title] for a screen reader.
  ///
  /// [resizable] lets a reader drag the frame's corner to a narrower width, which is the whole
  /// point of the showcase: the page inside reflows to its own width, so the responsive
  /// behaviour is one gesture away instead of one window resize. It is host chrome — CSS
  /// `resize` on the frame — and not a token the model carries, because no node draws it.
  const IframeNode({
    required this.src,
    required this.title,
    this.resizable = false,
    super.key,
  });

  /// The page the frame shows, relative to the document that holds it.
  final String src;

  /// The accessible name of the frame.
  final String title;

  /// Whether a reader can drag the frame narrower.
  final bool resizable;

  @override
  List<Object> get implementations => <Object>[markup];

  /// The frame, with the chrome a node does not describe.
  String get markup =>
      '<iframe src="$src" title="$title" style="border:0;width:100%;'
      'height:100%;display:block${resizable ? ';resize:horizontal;overflow:auto;'
                'min-width:280px;max-width:100%' : ''}"></iframe>';
}
