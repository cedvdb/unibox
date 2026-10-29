import 'package:unibox_element/unibox_element.dart';

import 'escape.dart';

/// [plan] as HTML.
///
/// This is the only place a plan becomes text, which is what keeps the escaping honest: one
/// function escapes every attribute value and every piece of text a node carries, and the plan
/// itself holds values. A DOM renderer sets the same values as properties, where no escaping
/// exists to get wrong.
///
/// The tree is written into one buffer, depth first. A buffer per element would be a buffer
/// per node and a `toString()` per node, and its parent would then copy that string into its
/// own: the text of a leaf would be copied once for every level above it, which makes a deep
/// page cost its own depth squared. One buffer writes each character once, wherever it sits.
String writeElement(ElementPlan plan) {
  final StringBuffer buffer = StringBuffer();

  _write(plan, buffer);

  return buffer.toString();
}

/// [plan] and everything inside it, appended to [buffer].
void _write(ElementPlan plan, StringBuffer buffer) {
  buffer.write('<${plan.tag}');

  if (plan.className != null) {
    buffer.write(' class="${escapeAttribute(plan.className!)}"');
  }

  for (final MapEntry<String, String> attribute in plan.attributes.entries) {
    buffer.write(' ${attribute.key}="${escapeAttribute(attribute.value)}"');
  }

  if (_voidTags.contains(plan.tag)) {
    buffer.write('>');

    return;
  }

  buffer.write('>');

  // An embed is the host's markup, written as it is: escaping it would ship a tag a reader
  // would see as text.
  if (plan.raw != null) {
    buffer.write(plan.raw);
  }

  if (plan.text != null) {
    buffer.write(escapeText(plan.text!));
  }

  for (final ElementPlan child in plan.children) {
    _write(child, buffer);
  }

  buffer.write('</${plan.tag}>');
}

/// The tags that hold no content and take no closing tag.
const Set<String> _voidTags = <String>{
  'area',
  'base',
  'br',
  'col',
  'embed',
  'hr',
  'img',
  'input',
  'link',
  'meta',
  'source',
  'track',
  'wbr',
};
