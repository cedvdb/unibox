/// What an element is, before anyone writes it.
///
/// One plan per node: the tag it becomes, the attributes it carries and in what order, the
/// class it wears, the text inside it, and the elements inside that — plus the planning that
/// turns a tree into one, and the stylesheet that gives every look its class.
///
/// It holds no markup. A string renderer writes a plan to HTML; a DOM renderer builds nodes from
/// the same plan. That is what makes one element plan instead of two: a second web renderer
/// reads this package rather than deciding again what a `Box` looks like.
///
/// Pure Dart. The only thing it knows about the web is what CSS calls things, which it takes
/// from `unibox_css`.
library;

export 'src/plan.dart';
export 'src/plan_node.dart';
export 'src/stylesheet.dart';
export 'src/url.dart';
