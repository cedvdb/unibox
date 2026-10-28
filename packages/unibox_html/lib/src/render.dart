import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';

import 'client_script.dart';
import 'escape.dart';
import 'plan.dart';
import 'stylesheet.dart';

/// The tree as an HTML fragment, with one `<style>` element in front of it.
///
/// A fragment is what an island inside someone else's page needs; `toDocument` is what a
/// crawler needs. Both come from the same plan, so a page and a fragment never disagree
/// about what an element is.
///
/// Interactivity is not part of it: a `StatefulNode` draws the state its store starts in,
/// an `OverlayNode` draws its overlay open, and no callback becomes a listener. A document
/// is a snapshot of a state, and the application is what makes it move.
String toHtml(
  core.UINode node, {
  core.UniboxTheme? theme,
  bool showOverlays = false,
}) {
  final Stylesheet sheet = Stylesheet();
  final ElementPlan plan = planNode(
    node,
    sheet,
    options: PlanOptions(showOverlays: showOverlays),
  );

  return '<style>${sheetWithRoot(sheet, theme: theme)}</style>${plan.write()}';
}

/// The plan of [node] and the CSS it needs, for a caller that wants the two separately
/// — a page puts the stylesheet in the head and the tree in the body.
({ElementPlan plan, String css}) renderFragment(
  core.UINode node, {
  core.UniboxTheme? theme,
  bool showOverlays = false,
}) {
  final Stylesheet sheet = Stylesheet();
  final ElementPlan plan = planNode(
    node,
    sheet,
    options: PlanOptions(showOverlays: showOverlays),
  );

  return (plan: plan, css: sheetWithRoot(sheet, theme: theme));
}

/// The CSS a document needs before the tree: the typography of the model, the colours of
/// the theme, then every class the tree wears.
///
/// The `:root` block first, because it is what a text with no declarations of its own
/// inherits; the classes after it, so a look always outranks the default it started from.
String sheetWithRoot(Stylesheet sheet, {core.UniboxTheme? theme}) {
  final CssDeclarations root = defaultTypographyDeclarations();

  if (theme != null) {
    root.addAllIn(themeDeclarations(theme));
  }

  return ':root{${root.text}}${sheet.css}';
}

/// The plan of [node], with every look it needs registered in [sheet].
///
/// A node this renderer cannot draw is reported instead of skipped: a tree built for
/// another target fails loudly, rather than shipping a page with a piece missing.
ElementPlan planNode(
  core.UINode node,
  Stylesheet sheet, {
  PlanOptions options = const PlanOptions(),
}) => switch (node) {
  final core.Box box => _planBox(box, sheet, options),
  final core.TextNode text => _planText(text, sheet),
  final core.ImageNode image => _planImage(image, sheet),
  final core.LinkNode link => _planLink(link, sheet, options),
  final core.GridNode grid => _planGrid(grid, sheet, options),
  final core.StackNode stack => _planStack(stack, sheet, options),
  final core.TextInputNode field => _planTextInput(field, sheet),
  final core.OverlayNode overlay => _planOverlay(overlay, sheet, options),
  final core.StatefulNode<Object, core.Store<Object>> stateful => _planStateful(
    stateful,
    sheet,
    options,
  ),
  _ => throw UnsupportedError(
    'No HTML renderer for ${node.runtimeType} yet: this target draws $supportedNodes.',
  ),
};

/// What a rendering may say about the state it draws.
///
/// An overlay is hidden by default, because a document has no interaction: no reader can
/// ask for the dialog, so painting it would show a state nobody is in. A host that
/// publishes a state at its own url — a `/signup` page whose purpose *is* the dialog —
/// says so here, and the document shows it. Nothing about the node changes either way:
/// presence in the tree is the state, and this only decides whether a page draws it.
final class PlanOptions {
  /// Creates the options of a rendering.
  const PlanOptions({this.showOverlays = false});

  /// Whether an overlay in the tree is drawn rather than hidden.
  final bool showOverlays;
}

/// What this renderer draws so far, named for the message a missing one prints.
const String supportedNodes = 'a Box, a TextNode, an ImageNode and a LinkNode';

ElementPlan _planBox(core.Box box, Stylesheet sheet, PlanOptions options) {
  final core.BoxStyle style = box.computedStyle;

  if (style.visibleFrom != null || style.visibleUntil != null) {
    throw UnsupportedError(
      'A box that is visible only at some widths needs a container query, which this '
      'renderer does not write yet: ${box.debugName}.',
    );
  }

  final core.BoxElement element = box.semantics?.element ?? core.BoxElement.div;
  // A painted leaf takes no pointer: it has nothing to press, and letting it be the
  // target would put a decoration in front of the control it was drawn for.
  final bool listens =
      box.enabled &&
      (box.onTap != null ||
          box.onTapDown != null ||
          box.onLongPress != null ||
          box.onHover != null);
  final bool capturesPointer =
      box.children.isNotEmpty ||
      listens ||
      box.stateStyle(core.BoxState.hover) != null ||
      box.stateStyle(core.BoxState.pressed) != null;

  final CssDeclarations declarations = boxDeclarations(
    style,
    interactive: box.isInteractive,
    capturesPointer: capturesPointer,
    element: element,
  );
  if (listens) {
    sheet.markInk();
  }

  final String className = sheet.classFor(
    'box',
    declarations,
    states: (String name) => stateRules(box, name),
  );

  return ElementPlan(
    tag: element.name,
    className: className,
    attributes: <String, String>{
      // Where a press may paint. The marker is inert without the client script, which is
      // how a page opts out of ink: it includes no script.
      if (listens) inkAttribute: '',
      ...boxAttributes(box),
      ...nodeAttributes(box),
    },
    children: <ElementPlan>[
      for (final core.UINode child in box.children)
        planNode(child, sheet, options: options),
    ],
  );
}

/// The accessibility attributes of a box.
///
/// The element already announces what it is, so `role` is only written when the box asks
/// for one its element does not imply: a `<nav>` is a navigation landmark without a
/// `role="navigation"` next to it, and `role="link"` on a `<div>` is the only way to say
/// what that div means.
Map<String, String> boxAttributes(core.Box box) {
  final core.BoxSemantics? semantics = box.semantics;
  final core.BoxRole role = semantics?.role ?? core.BoxRole.none;
  final core.BoxElement element = semantics?.element ?? core.BoxElement.div;
  final Map<String, String> attributes = <String, String>{};
  final String? roleName = htmlRoleOf(role);
  final String? label = semantics?.label;
  final bool? checked = semantics?.checked;
  final bool isCheckable =
      role == core.BoxRole.checkbox || role == core.BoxRole.switch_;

  if (roleName != null && roleName != impliedRoleOf(element)) {
    attributes['role'] = roleName;
  }

  if (label != null) {
    attributes['aria-label'] = label;
  }

  if (isCheckable && checked != null) {
    attributes['aria-checked'] = '$checked';
  }

  if (!box.enabled) {
    attributes['aria-disabled'] = 'true';
  }

  if (box.isFocusable && box.enabled) {
    attributes['tabindex'] = '0';
  }

  final bool? expanded = semantics?.expanded;
  final bool? selected = semantics?.selected;

  if (expanded != null) {
    attributes['aria-expanded'] = '$expanded';
  }

  if (selected != null) {
    attributes['aria-selected'] = '$selected';
  }

  // A hidden box keeps its look and leaves the accessibility tree, and it is never
  // focusable, so it cannot be a focusable element with `aria-hidden`.
  if (semantics?.hidden ?? false) {
    attributes['aria-hidden'] = 'true';
  }

  if (semantics?.liveRegion ?? false) {
    attributes['aria-live'] = 'polite';
  }

  final core.BoxCurrent? current = semantics?.current;

  if (current != null) {
    // Which kind of current this is, not just that it is current: a navigation item
    // announces "current page", a step of a flow something else.
    attributes['aria-current'] = current.name;
  }

  return attributes;
}

/// The attributes every element a node drew carries: its name, and its key when it has one
/// a page could answer.
///
/// The name is a literal a node states, so an inspector reads a tree instead of a wall of
/// hashes. The key is the identity a client renderer adopts an element by, and it is
/// written only when it is a `String` or an `int`: any other key's `toString()` is an
/// instance hash, which names one node two ways across a server and a browser.
Map<String, String> nodeAttributes(core.UINode node) {
  final Object? key = node.key;

  return <String, String>{
    'data-unibox-node': node.debugName,
    if (key is String || key is int) 'data-unibox-key': key.toString(),
  };
}

ElementPlan _planText(core.TextNode node, Stylesheet sheet) {
  final String className = sheet.classFor('text', textDeclarations(node));

  return ElementPlan(
    tag: textTagOf(node.headingLevel),
    className: className,
    attributes: nodeAttributes(node),
    text: node.text,
  );
}

ElementPlan _planImage(core.ImageNode node, Stylesheet sheet) {
  final String className = sheet.classFor('image', imageDeclarations(node));
  final int? width = _pixels(node.width);
  final int? height = _pixels(node.height);

  return ElementPlan(
    tag: 'img',
    className: className,
    attributes: <String, String>{
      'src': safeUrl(node.src),
      'alt': node.alt,
      // A browser that knows the size reserves the box before the picture arrives, which
      // is the difference between a page that settles and one that shifts.
      if (width != null) 'width': '$width',
      if (height != null) 'height': '$height',
      'srcset': ?node.resolvedSrcSet,
      'sizes': ?node.sizes,
      // The browser's own default is omitted: a document states what it wants, not
      // what it would have done anyway.
      if (node.loading != core.ImageLoading.eager) 'loading': node.loading.name,
      if (node.fetchPriority != core.ImageFetchPriority.auto)
        'fetchpriority': node.fetchPriority.name,
      ...nodeAttributes(node),
    },
  );
}

/// [value] in whole pixels, or `null` when it is missing or unbounded.
///
/// The attributes are a hint for the browser's layout, so a fraction of a pixel or an
/// infinite box has nothing to say — the CSS keeps the exact size.
int? _pixels(double? value) {
  if (value == null || !value.isFinite) {
    return null;
  }

  return value.round();
}

ElementPlan _planLink(
  core.LinkNode node,
  Stylesheet sheet,
  PlanOptions options,
) {
  final String className = sheet.classFor('link', linkDeclarations());
  final bool newTab = node.newTab;

  return ElementPlan(
    tag: 'a',
    className: className,
    attributes: <String, String>{
      'href': safeUrl(node.url),
      if (newTab) 'target': '_blank',
      // A link that opens a new tab hands the opener to the page it opens unless it is
      // told not to.
      if (newTab) 'rel': 'noopener noreferrer',
      ...nodeAttributes(node),
    },
    children: <ElementPlan>[planNode(node.child, sheet, options: options)],
  );
}

ElementPlan _planGrid(
  core.GridNode node,
  Stylesheet sheet,
  PlanOptions options,
) {
  final String className = sheet.classFor('grid', gridDeclarations(node));

  return ElementPlan(
    tag: 'div',
    className: className,
    attributes: nodeAttributes(node),
    children: <ElementPlan>[
      for (final core.UINode child in node.children)
        planNode(child, sheet, options: options),
    ],
  );
}

/// A stack, with every child in a cell of its own.
///
/// The wrapper is the renderer's, not a node's: it takes the whole cell and lays its
/// child out inside it, which is what a Flutter stack does with a child that is not
/// positioned. It carries no `data-unibox-node`, because no node drew it — and that
/// absence is meaningful: an element without the attribute is not part of the
/// description.
ElementPlan _planStack(
  core.StackNode node,
  Stylesheet sheet,
  PlanOptions options,
) {
  final String className = sheet.classFor('stack', stackDeclarations(node));

  return ElementPlan(
    tag: 'div',
    className: className,
    attributes: nodeAttributes(node),
    children: <ElementPlan>[
      for (final core.UINode child in node.children)
        _planStackCell(child, sheet, options),
    ],
  );
}

ElementPlan _planStackCell(
  core.UINode child,
  Stylesheet sheet,
  PlanOptions options,
) {
  final core.UINode content = child is core.PositionedNode
      ? child.child
      : child;
  final CssDeclarations declarations = switch (child) {
    final core.PositionedNode node when node.isAligned => alignedDeclarations(
      node.alignment!,
    ),
    final core.PositionedNode node when !node.isUnpositioned =>
      positionedDeclarations(node),
    _ => stackCellDeclarations(),
  };

  return ElementPlan(
    tag: 'div',
    className: sheet.classFor('stack-child', declarations),
    children: <ElementPlan>[planNode(content, sheet, options: options)],
  );
}

/// A field, as an `<input>` or a `<textarea>`.
///
/// A field is a replaced element, so most of what makes it look like the tree is done in
/// `textInputDeclarations`; what is left is the element and its attributes, and the hint,
/// which is a `::placeholder` rule of its own.
///
/// The hint is part of the class key and not only of the rule: two fields that differ only
/// in the colour of their hint would otherwise share a class, and the first hint colour
/// would win for both.
ElementPlan _planTextInput(core.TextInputNode node, Stylesheet sheet) {
  final CssDeclarations declarations = textInputDeclarations(
    padding: node.padding,
  );
  final core.BoxTextStyle? hintStyle = node.placeholderStyle;
  final CssDeclarations? hint = hintStyle == null
      ? null
      : typographyDeclarations(hintStyle);
  final String className = sheet.classFor(
    'field',
    declarations,
    key: hint == null
        ? null
        : '${declarations.text}|::placeholder:${hint.text}',
    states: hint == null
        ? null
        : (String name) => <CssRule>[
            CssRule(selector: '.$name::placeholder', declarations: hint),
          ],
  );

  final Map<String, String> attributes = <String, String>{
    if (node.placeholder != null) 'placeholder': node.placeholder!,
    if (!node.enabled) 'disabled': '',
    if (node.readOnly) 'readonly': '',
    if (node.autofocus) 'autofocus': '',
    if (node.required) 'aria-required': 'true',
    if (node.invalid) 'aria-invalid': 'true',
    // A description needs no element to point at: the attribute carries the text
    // itself, which is also what the Flutter side hands to `Semantics.hint`.
    if (node.description != null) 'aria-description': node.description!,
    if (node.semanticsLabel != null) 'aria-label': node.semanticsLabel!,
    ...?autofillAttributeOf(node),
    ...nodeAttributes(node),
  };

  if (node.multiline) {
    return ElementPlan(
      tag: 'textarea',
      className: className,
      // A browser starts a text area at two rows and a Flutter field at one line, so the
      // row count is written rather than left to the user agent.
      attributes: <String, String>{
        'rows': '${node.maxLines ?? 1}',
        ...attributes,
      },
      text: node.value,
    );
  }

  return ElementPlan(
    tag: 'input',
    className: className,
    attributes: <String, String>{
      'type': inputTypeOf(node),
      if (node.value != null) 'value': node.value!,
      ...attributes,
    },
  );
}

/// The `type` of the `<input>` for [node].
///
/// The type drives the on-screen keyboard of a touch device and the validation hints of a
/// browser, so an address on a phone offers the right keys with no host code.
String inputTypeOf(core.TextInputNode node) {
  if (node.obscureText) {
    return 'password';
  }

  return switch (node.inputType) {
    core.InputType.text => 'text',
    core.InputType.email => 'email',
    core.InputType.number => 'number',
    core.InputType.phone => 'tel',
    core.InputType.url => 'url',
  };
}

/// The `autocomplete` hint of the field, which is what lets a password manager offer the
/// right entry.
///
/// Only for the types that have one: `text` and `number` say nothing a browser could act
/// on, and an empty attribute would.
Map<String, String>? autofillAttributeOf(core.TextInputNode node) {
  return switch (node.inputType) {
    core.InputType.text || core.InputType.number => null,
    core.InputType.email => <String, String>{'autocomplete': 'email'},
    core.InputType.phone => <String, String>{'autocomplete': 'tel'},
    core.InputType.url => <String, String>{'autocomplete': 'url'},
  };
}

/// An overlay, drawn open.
///
/// A document is a snapshot of a state, and the state of an overlay is a node inside the
/// tree: it is drawn where the tree put it and taken out of the flow by
/// `position: fixed`, never by a second slot on a parent. Its layer carries the dialog
/// semantics, its scrim covers the page, and its content paints above the scrim.
ElementPlan _planOverlay(
  core.OverlayNode node,
  Stylesheet sheet,
  PlanOptions options,
) {
  final String layer = sheet.classFor(
    'overlay',
    overlayDeclarations(node.alignment),
  );
  final String barrier = sheet.classFor(
    'overlay-barrier',
    overlayBarrierDeclarations(node.barrierColor),
  );
  final String content = sheet.classFor(
    'overlay-content',
    overlayContentDeclarations(),
  );

  return ElementPlan(
    tag: 'div',
    className: layer,
    attributes: <String, String>{
      // `hidden` is HTML's own way of saying "not rendered": no layout, no box, and
      // nothing for a screen reader. The element stays in the page so a client renderer
      // can adopt it instead of building it, and unhides it when its state says open.
      if (!options.showOverlays) 'hidden': '',
      'role': 'dialog',
      'aria-modal': 'true',
      ...nodeAttributes(node),
    },
    children: <ElementPlan>[
      ElementPlan(tag: 'div', className: barrier),
      ElementPlan(
        tag: 'div',
        className: content,
        children: <ElementPlan>[planNode(node.child, sheet, options: options)],
      ),
    ],
  );
}

/// A stateful node, drawn as the state its store starts in.
///
/// The store is created only to be read: `onMount` is not called and no listener is
/// added, which is what the store's own contract asks for, so a server render never
/// starts the work an application would — a request, a timer, a subscription. The tree
/// is a function of the state, so this is exactly the state a reader arriving for the
/// first time sees.
ElementPlan _planStateful(
  core.StatefulNode<Object, core.Store<Object>> node,
  Stylesheet sheet,
  PlanOptions options,
) {
  final core.Store<Object> store = node.createStore();

  return planNode(node.viewFor(store.state, store), sheet);
}
