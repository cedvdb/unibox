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

/// [attributes] with the name of [node].
///
/// A renderer calls this with the attributes it already had, so an element
/// differs from one without a name by exactly one attribute and by nothing else:
/// no class, no element, no rule.
Map<String, String> withNodeLabel(
  core.UINode node, [
  Map<String, String>? attributes,
]) {
  return <String, String>{...?attributes, nodeLabelAttribute: node.debugName};
}
