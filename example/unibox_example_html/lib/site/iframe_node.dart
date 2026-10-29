import 'package:unibox_core/unibox_core.dart';

/// An `<iframe>` as a node.
///
/// A frame is content only the web can draw, which is what an embed is for. The showcase page
/// uses two of them to put the two renderings side by side.
final class IframeNode extends EmbedNode {
  /// Creates a frame showing [src], named [title] for a screen reader.
  const IframeNode({required this.src, required this.title, super.key});

  /// The page the frame shows, relative to the document that holds it.
  final String src;

  /// The accessible name of the frame.
  final String title;

  @override
  List<Object> get implementations => <Object>[markup];

  /// The frame, filling the box the tree gives it.
  ///
  /// `loading: lazy` because a frame is a whole second document — the Flutter one is an
  /// application — so it is fetched when a reader gets near it, not when the page opens. There is
  /// no `resize` grip: the comparison is between two windows of one size, and a reader who drags
  /// one narrower is no longer comparing like with like.
  String get markup =>
      '<iframe src="$src" title="$title" loading="lazy" '
      'style="border:0;width:100%;height:100%;display:block"></iframe>';
}
