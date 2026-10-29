import 'package:unibox_core/unibox_core.dart' as core;

/// One element a tree becomes, with nothing yet written.
///
/// This is the element plan: which tag a node renders to, which attributes it carries,
/// which class it wears, and the elements inside it. It holds no markup, so a string
/// renderer writes it to HTML and a DOM renderer builds nodes from the same value — which
/// is what lets the second one adopt the first one's page instead of repainting it.
///
/// Attributes are a `Map` because HTML is one: an attribute written twice is a mistake,
/// not a fallback, and a browser keeps the first.
final class ElementPlan {
  /// Creates an element.
  const ElementPlan({
    required this.tag,
    this.attributes = const <String, String>{},
    this.className,
    this.text,
    this.children = const <ElementPlan>[],
  }) : raw = null;

  /// An element whose content is markup the host wrote.
  const ElementPlan.raw({
    required this.tag,
    required String this.raw,
    this.attributes = const <String, String>{},
    this.className,
  }) : text = null,
       children = const <ElementPlan>[];

  /// The tag: `div`, `span`, `h1`, `a`, `img`, `input`.
  final String tag;

  /// The attributes, in the order they will be written.
  final Map<String, String> attributes;

  /// The class the element wears, or `null` when its look is the browser's.
  final String? className;

  /// Markup written verbatim, for an embed.
  final String? raw;

  /// The text inside the element, for the elements that hold text and nothing else.
  ///
  /// Unescaped: escaping belongs to whoever writes the markup, so a DOM renderer sets it
  /// as `textContent` and never has to think about it.
  final String? text;

  /// The elements inside this one, in paint order.
  final List<ElementPlan> children;

  /// Markup written as it is, with nothing escaped.
  ///
  /// Only an embed produces it: it is the host saying "this is markup I trust", for a web
  /// component, a `<video>` or a chart the model does not describe. Every other string a node
  /// carries is a value, which the renderer that writes the page escapes.
}

/// The ARIA role of [role], or `null` for a plain container.
String? htmlRoleOf(core.BoxRole role) => switch (role) {
  core.BoxRole.none => null,
  core.BoxRole.button => 'button',
  core.BoxRole.checkbox => 'checkbox',
  core.BoxRole.switch_ => 'switch',
  core.BoxRole.link => 'link',
  core.BoxRole.heading => 'heading',
};

/// The role [element] already announces, which a `role` attribute would only repeat.
String? impliedRoleOf(core.BoxElement element) => switch (element) {
  core.BoxElement.main => 'main',
  core.BoxElement.nav => 'navigation',
  core.BoxElement.header => 'banner',
  core.BoxElement.footer => 'contentinfo',
  core.BoxElement.aside => 'complementary',
  core.BoxElement.section => 'region',
  core.BoxElement.article => 'article',
  core.BoxElement.form => 'form',
  core.BoxElement.figure => 'figure',
  core.BoxElement.ul || core.BoxElement.ol => 'list',
  core.BoxElement.li => 'listitem',
  // A caption names the figure it belongs to; no role says that, the tag does.
  core.BoxElement.figcaption => null,
  core.BoxElement.div => null,
};

/// The tag of a text node: a heading at the level it states, a span otherwise.
///
/// A span rather than a paragraph, because a text flows inline inside a row exactly as a
/// Flutter `Text` does inside a `Row`; a paragraph would bring a line box of its own.
String textTagOf(int? headingLevel) =>
    headingLevel == null ? 'span' : 'h$headingLevel';
