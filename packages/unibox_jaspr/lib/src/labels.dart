import 'package:unibox_core/unibox_core.dart' as core;

/// The attribute every element a node drew carries.
///
/// Its value is the node's [core.UINode.debugName]. It exists so a wall of
/// `unibox-box-1f3c9a7b` can be read in a browser's inspector, and it is
/// deliberately an attribute rather than a class: the class attribute belongs to
/// the stylesheet, so a name written there would either collide with a rule or
/// invite a host to style on it — and a look the host can restyle is a look
/// Flutter cannot draw.
///
/// It is written always, not behind a flag: it carries no look, so there is
/// nothing to turn off, and a page cannot disagree between its server render and
/// the client that hydrates it when there is no switch for the two to differ on.
const String nodeLabelAttribute = 'data-unibox-node';

/// The attribute a keyed node's element carries.
///
/// `UINode.key` is the identity a renderer keeps an element attached to when a
/// list is reordered; writing it out makes that identity readable from outside
/// the tree, which is what lets a host find the element a node drew again — a
/// script that recorded where a page was scrolled before the page became an
/// application, a test that addresses one control without counting siblings.
///
/// **Only a `String` or an `int` key is written.** Any other key identifies a
/// node for reuse and nothing else: `toString()` of an arbitrary object is an
/// instance hash, which differs between the server render and the client that
/// hydrates it, so a page would carry a name that answers nothing. Nothing is
/// reported for such a key, because keying a node with the object it describes is
/// a legitimate spelling of "keep this child attached to its row".
///
/// It is an attribute and not the element's `id`, for two reasons that a tree
/// makes concrete: an `id` is unique in a **document** while a key is unique
/// among the **siblings** of one node, so the same tree drawn twice on a page —
/// a card in a listing and the same card alone — is legal for a key and invalid
/// for an `id`; and an `id` is addressable by a fragment and styleable by
/// `#name`, which is a look one target applies and the other cannot draw.
///
/// A key that a page has to find again should be unique in the document as well
/// as among its siblings. That is a fact about the tree a host builds, not
/// something a renderer can enforce, so a replayer finding several elements is
/// told to distrust the answer rather than to pick one.
const String nodeKeyAttribute = 'data-unibox-key';

/// [attributes] with the name of [node], and its key when it has one to write.
///
/// A renderer calls this with the attributes it already had, so an element
/// differs from one without a name or a key by exactly those attributes and by
/// nothing else: no class, no element, no rule.
Map<String, String> withNodeAttributes(
  core.UINode node, [
  Map<String, String>? attributes,
]) {
  final Object? key = node.key;

  return <String, String>{
    ...?attributes,
    nodeLabelAttribute: node.debugName,
    if (key is String || key is int) nodeKeyAttribute: key.toString(),
  };
}
