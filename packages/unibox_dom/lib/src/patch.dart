import 'dart:js_interop';

import 'package:unibox_element/unibox_element.dart';
import 'package:web/web.dart' as web;

/// Builds the element [plan] describes.
///
/// The same plan a client builds and a server wrote: the tag, the class, the attributes in the
/// order the plan holds them, and then its content. `onBuilt` is how a view learns which element a
/// plan became, which is what a re-render has to patch instead of build.
web.Element buildElement(
  ElementPlan plan, {
  void Function(ElementPlan plan, web.Element element)? onBuilt,
}) {
  final web.Element element = web.document.createElement(plan.tag);

  _patchSelf(element, const ElementPlan(tag: ''), plan);

  final List<ElementPlan> children = plan.children;
  for (final ElementPlan child in children) {
    element.append(buildElement(child, onBuilt: onBuilt));
  }

  onBuilt?.call(plan, element);

  return element;
}

/// Brings [element] in line with [next], reusing it when it can.
///
/// [previous] is the plan it was built from, which is what says which attributes to take away: an
/// attribute this renderer wrote and no longer writes is one no other writer owns.
///
/// Returns the element the plan is now drawn by — the same object unless the tag changed, in which
/// case the old element is replaced and the new one returned.
web.Element patchElement(
  web.Element element,
  ElementPlan previous,
  ElementPlan next, {
  void Function(ElementPlan plan, web.Element element)? onBuilt,
}) {
  if (element.tagName.toLowerCase() != next.tag) {
    final web.Element replacement = buildElement(next, onBuilt: onBuilt);
    element.parentNode?.replaceChild(replacement, element);

    return replacement;
  }

  _patchSelf(element, previous, next);

  // A plan holds text, or markup, or children — never two of them. Reconciling children after
  // writing markup would read that markup as an unmatched child and remove it, which is how an
  // embed's frame disappeared the moment a client adopted the page.
  if (next.raw == null && next.text == null) {
    patchChildren(element, previous, next, onBuilt: onBuilt);
  }

  onBuilt?.call(next, element);

  return element;
}

/// Patches [parent]'s children from [previous] to [next].
///
/// A child that is still there is patched where it stands, so an element keeps its identity — and
/// therefore its focus, its caret, its scroll and the listeners attached to it. That is not a
/// nicety: a browser decides whether a press became a click by comparing the element it saw pressed
/// with the one it sees released, so rebuilding the element under a pointer turns every press into
/// a click that never happens.
///
/// Matching is by `key` first, because a key is a statement about identity. The rest is matched from
/// **both ends**: a tree that inserts a child at the front — an ink drop, a spinner, a badge — keeps
/// everything after it, and matching from the end is what sees that. Whatever is left is matched by
/// position and kind, and whatever is still left is new.
void patchChildren(
  web.Element parent,
  ElementPlan previous,
  ElementPlan next, {
  void Function(ElementPlan plan, web.Element element)? onBuilt,
}) {
  // `children` holds elements by definition, which is why this needs no type test: the plan builds
  // nothing else.
  final List<web.Element?> pool = <web.Element?>[
    for (int i = 0; i < parent.children.length; i++)
      if (parent.children.item(i) case final web.Node node) node as web.Element,
  ];
  final List<ElementPlan> before = previous.children;
  final List<web.Element?> matched = List<web.Element?>.filled(
    next.children.length,
    null,
  );

  _matchKeys(next.children, pool, matched);
  _matchEnds(next.children, pool, matched);
  _matchStarts(next.children, pool, matched);

  final List<web.Element> built = <web.Element>[];

  for (int i = 0; i < next.children.length; i++) {
    final ElementPlan plan = next.children[i];
    final web.Element? existing = matched[i];

    built.add(
      existing == null
          ? buildElement(plan, onBuilt: onBuilt)
          : patchElement(
              existing,
              _planOf(existing, before),
              plan,
              onBuilt: onBuilt,
            ),
    );
  }

  // Place what is left in order: an element already in its place is not touched, which is what
  // keeps a keystroke from restarting an animation or a field's composition.
  web.Node? reference = parent.firstChild;

  for (final web.Element element in built) {
    if (identical(element, reference)) {
      reference = reference!.nextSibling;

      continue;
    }

    parent.insertBefore(element, reference);
  }

  for (final web.Element? leftover in pool) {
    leftover?.remove();
  }
}

/// Matches children that state a key, wherever they moved to.
void _matchKeys(
  List<ElementPlan> plans,
  List<web.Element?> pool,
  List<web.Element?> matched,
) {
  for (int i = 0; i < plans.length; i++) {
    final String? key = plans[i].attributes['data-unibox-key'];

    if (key == null) {
      continue;
    }

    for (int j = 0; j < pool.length; j++) {
      if (pool[j]?.getAttribute('data-unibox-key') == key) {
        matched[i] = pool[j];
        pool[j] = null;

        break;
      }
    }
  }
}

/// Matches from the end: a child inserted at the front leaves everything after it where it was.
void _matchEnds(
  List<ElementPlan> plans,
  List<web.Element?> pool,
  List<web.Element?> matched,
) {
  int plan = plans.length - 1;
  int element = pool.length - 1;

  while (plan >= 0 && element >= 0) {
    if (matched[plan] != null) {
      plan--;

      continue;
    }

    final web.Element? candidate = pool[element];

    if (candidate == null ||
        candidate.tagName.toLowerCase() != plans[plan].tag) {
      return;
    }

    matched[plan] = candidate;
    pool[element] = null;
    plan--;
    element--;
  }
}

/// Matches the rest from the front, by position and kind.
void _matchStarts(
  List<ElementPlan> plans,
  List<web.Element?> pool,
  List<web.Element?> matched,
) {
  int element = 0;

  for (int plan = 0; plan < plans.length; plan++) {
    if (matched[plan] != null) {
      continue;
    }

    while (element < pool.length && pool[element] == null) {
      element++;
    }

    if (element >= pool.length) {
      return;
    }

    final web.Element? candidate = pool[element];

    if (candidate != null &&
        candidate.tagName.toLowerCase() == plans[plan].tag) {
      matched[plan] = candidate;
      pool[element] = null;
    }

    element++;
  }
}

/// The plan an element in [before] was built from, by its key or by its place.
///
/// It only supplies the attributes to take away, so an approximate answer is safe: the worst case
/// is an attribute left on an element that already wears it.
ElementPlan _planOf(web.Element element, List<ElementPlan> before) {
  final String? key = element.getAttribute('data-unibox-key');

  for (final ElementPlan plan in before) {
    if (plan.attributes['data-unibox-key'] == key &&
        plan.attributes['data-unibox-key'] != null) {
      return plan;
    }
  }

  return const ElementPlan(tag: '');
}

/// The element's own part of the plan: class, attributes, and its content.
void _patchSelf(web.Element element, ElementPlan previous, ElementPlan next) {
  final String? className = next.className;

  if (className == null) {
    if (element.hasAttribute('class')) {
      element.removeAttribute('class');
    }
  } else if (element.className != className) {
    element.className = className;
  }

  for (final String name in previous.attributes.keys) {
    if (!next.attributes.containsKey(name)) {
      element.removeAttribute(name);
    }
  }

  next.attributes.forEach((String name, String value) {
    if (element.getAttribute(name) != value) {
      element.setAttribute(name, value);
    }
  });

  // A plan holds text, or markup, or children — never two of them.
  if (next.raw != null) {
    if (next.raw != previous.raw) {
      element.innerHTML = next.raw!.toJS;
    }

    return;
  }

  if (next.text != null) {
    if (next.text != previous.text) {
      element.textContent = next.text;
    }
  }
}
