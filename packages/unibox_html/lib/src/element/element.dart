/// What an element is, before anyone writes it.
///
/// One plan per node: the tag it becomes, the attributes it carries and in what order, the
/// class it wears, the text inside it, and the elements inside that — plus the planning that
/// turns a tree into one, and the stylesheet that gives every look its class.
///
/// It holds no markup. `unibox_html` writes a plan to HTML; `unibox_dom` builds nodes from the
/// same plan, which is what makes one element plan instead of two — a third web renderer would
/// read this layer rather than decide again what a `Box` looks like.
///
/// Pure Dart. The only thing it knows about the web is what CSS calls things, which it takes
/// from the layer beside it, `unibox_html`'s `css/`.
library;

export 'plan.dart';
export 'plan_node.dart';
export 'stylesheet.dart';
export 'url.dart';
