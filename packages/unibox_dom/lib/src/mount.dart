import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';
import 'package:unibox_element/unibox_element.dart';
import 'package:web/web.dart' as web;

import 'events.dart';
import 'patch.dart';

/// A tree drawn into a page, with the stores it created still running.
///
/// Created by [DomView.mount]: it plans the tree with this target's stylesheet, writes the
/// stylesheet into the document, builds the elements the plan describes and subscribes to every
/// `StatefulNode` it met. A publish re-plans the tree it was mounted with and patches the page — a
/// child that is still there is patched where it stands, so a field keeps its focus and a list
/// keeps its elements when it reorders.
///
/// This is the third rendering of one tree, and the only one that is both interactive and small: a
/// `Box(onTap: store.retry)` runs because the callback is a closure in the same program as the
/// store, so a request started in `onMount` is the same `Future` it would be in Flutter.
final class DomView {
  DomView._(this._host, this._tree, this._theme);

  /// Draws [tree] into [host], and returns the view that owns what it added.
  ///
  /// [host] is emptied: a view draws a whole tree, not a patch of one. [theme] answers the colour
  /// roles the tree names, exactly as in the string renderer — the same value produces the same
  /// `:root` block, so a class name and a custom property agree across the two renderings.
  static DomView mount(
    core.UINode tree,
    web.Element host, {
    core.UniboxTheme? theme,
  }) {
    final DomView view = DomView._(host, tree, theme).._paint();

    return view;
  }

  /// Draws [tree] over the elements a server already wrote, and keeps them.
  ///
  /// This is what a page and a client are for: the document a crawler read and the page a reader
  /// acts on are the same elements. Nothing is rebuilt — the plans are compared and only what
  /// differs is touched — so a reader who has scrolled, focused a field or selected text keeps all
  /// three, and there is no flash of a page drawn a second time.
  static DomView adopt(
    core.UINode tree,
    web.Element root, {
    core.UniboxTheme? theme,
  }) {
    final DomView view = DomView._(root.parentElement ?? root, tree, theme)
      .._element = root;
    view._paint();

    return view;
  }

  final web.Element _host;
  final core.UniboxTheme? _theme;
  final Stylesheet _sheet = Stylesheet();
  final Map<String, _Mount> _mounts = <String, _Mount>{};
  final Map<web.Element, List<void Function()>> _listeners =
      <web.Element, List<void Function()>>{};
  core.UINode _tree;
  web.HTMLStyleElement? _style;
  ElementPlan? _plan;
  web.Element? _element;
  bool _drawing = false;
  bool _dirty = false;
  bool _disposed = false;

  /// The element the tree was drawn into, which is what a host measures or scrolls.
  web.Element get element => _element!;

  /// Draws [tree] over the elements this view already has, and remembers it for the next publish.
  void render(core.UINode tree) {
    _tree = tree;
    _repaint();
  }

  /// Takes the view out of the page: the stores, the listeners, the tree and the stylesheet.
  void dispose() {
    _disposed = true;

    for (final _Mount mount in _mounts.values) {
      mount.release();
    }

    _mounts.clear();
    _unbindAll();

    // Walks what it drew and takes it out; the host is the page's element, not this view's to empty.
    for (int i = _host.children.length - 1; i >= 0; i--) {
      _host.children.item(i)?.remove();
    }
    _style?.remove();
    _style = null;
    _element = null;
    _plan = null;
  }

  /// Plans the tree again — a store published, or the host handed another tree.
  ///
  /// A publish can arrive while a pass is running (`onMount` may start work that finishes at
  /// once), so a second pass is queued instead of nested: two plans in flight would fight over the
  /// same elements.
  void _repaint() {
    if (_disposed) {
      return;
    }

    if (_drawing) {
      _dirty = true;

      return;
    }

    _drawing = true;

    try {
      do {
        _dirty = false;
        _paint();
      } while (_dirty && !_disposed);
    } finally {
      _drawing = false;
    }
  }

  /// One pass: plan, patch, bind, and release the stores nothing holds any more.
  void _paint() {
    final _Pass pass = _Pass(this, _sheet);
    final ElementPlan next = pass.planTree(_tree);

    if (_element case final web.Element current) {
      // The first pass of an adoption has an element but no plan: the server's markup is the
      // previous state, and its plan is the one this tree describes now, so the two are compared
      // from the top and only what differs is written.
      _element = patchElement(
        current,
        _plan ??
            ElementPlan(
              tag: next.tag,
              className: current.className.isEmpty ? null : current.className,
            ),
        next,
        onBuilt: pass.record,
      );
      _style = _stylesheetIn(web.document.head);

      if (_style == null) {
        final web.HTMLStyleElement created =
            web.document.createElement('style') as web.HTMLStyleElement;
        web.document.head!.append(created);
        _style = created;
      }

      _style!.textContent = pass.css(_theme);
    } else {
      _element = buildElement(next, onBuilt: pass.record);
      _style = web.document.createElement('style') as web.HTMLStyleElement
        ..textContent = pass.css(_theme);
      web.document.head!.append(_style!);
      _host.replaceChildren(_element!);
    }

    _plan = next;
    _bindAll(pass, next);
    _syncElements(pass);
    _sweep(pass.visited);
  }

  /// Re-renders one stateful node's subtree, and nothing else.
  ///
  /// The boundary's element is patched, never replaced: a browser works out a click from the
  /// element it saw pressed, so a renderer that rewrites that element between the press and its
  /// release turns every press into a lost click.
  void _repaintBoundary(_Mount mount) {
    if (_disposed) {
      return;
    }

    final web.Element? element = mount.element;
    final ElementPlan? plan = mount.plan;

    if (element == null || plan == null) {
      // Published before this node was drawn: the pass in flight will draw the state it holds.
      _dirty = true;

      return;
    }

    // A mount inside this subtree that the new view no longer holds is gone from the page, so its
    // store has to stop doing whatever it was doing.
    // `contains` is true of the element itself, so the boundary's own mount is not in this list: a
    // store released here would be disposed by its own publish.
    final List<String> inside = <String>[
      for (final MapEntry<String, _Mount> entry in _mounts.entries)
        if (!identical(entry.value, mount))
          if (entry.value.element case final web.Element child
              when element.contains(child))
            entry.key,
    ];

    final _Pass pass = _Pass(this, _sheet);
    final ElementPlan next = planNode(
      mount.node.viewFor(mount.store.state, mount.store),
      _sheet,
      options: pass.options,
    );

    mount.element = patchElement(element, plan, next, onBuilt: pass.record);
    mount.plan = next;
    mount.element = pass.built[next] ?? mount.element;
    _style?.textContent = documentCss(_sheet, theme: _theme);

    _bindAll(pass, next);
    _syncElements(pass);

    for (final String slot in inside) {
      if (!pass.visited.contains(slot)) {
        _mounts.remove(slot)?.release();
      }
    }
  }

  /// Points every mount the last pass drew at the element it is drawn by now.
  void _syncElements(_Pass pass) {
    for (final String slot in pass.visited) {
      final _Mount? mount = _mounts[slot];
      final ElementPlan? plan = mount?.plan;

      if (mount != null && plan != null) {
        mount.element = pass.built[plan] ?? mount.element;
      }
    }
  }

  /// Attaches the behaviour of every node in [plan] to the element it became.
  ///
  /// The listeners of a previous render are taken off first: the closures they hold belong to a
  /// state the page has left, and a stale callback is how a button ends up doing what it did two
  /// publishes ago.
  void _bindAll(_Pass pass, ElementPlan plan) {
    final web.Element? element = pass.built[plan];
    final core.UINode? node = pass.nodes[plan];

    if (element != null && node != null) {
      for (final void Function() remove
          in _listeners.remove(element) ?? const <void Function()>[]) {
        remove();
      }

      final List<void Function()> undo = bindNode(node, element);

      if (undo.isNotEmpty) {
        _listeners[element] = undo;
      }
    }

    for (final ElementPlan child in plan.children) {
      _bindAll(pass, child);
    }
  }

  void _unbindAll() {
    for (final List<void Function()> undo in _listeners.values) {
      for (final void Function() remove in undo) {
        remove();
      }
    }

    _listeners.clear();
  }

  /// Releases the stores of nodes the new tree no longer holds.
  void _sweep(Set<String> alive) {
    final List<String> gone = <String>[
      for (final String slot in _mounts.keys)
        if (!alive.contains(slot)) slot,
    ];

    for (final String slot in gone) {
      _mounts.remove(slot)?.release();
    }
  }
}

/// The stylesheet a document wrote, if it is there, so a client rewrites it instead of adding a
/// second copy of the same rules.
web.HTMLStyleElement? _stylesheetIn(web.Element? head) =>
    head?.querySelector('style[data-unibox-css]') as web.HTMLStyleElement?;

/// One planning pass: the stylesheet it builds, the node each plan came from, and the element each
/// plan became.
final class _Pass {
  _Pass(this._view, this.sheet);

  final DomView _view;
  final Stylesheet sheet;
  final Map<ElementPlan, core.UINode> nodes =
      Map<ElementPlan, core.UINode>.identity();
  final Map<ElementPlan, web.Element> built =
      Map<ElementPlan, web.Element>.identity();
  final Set<String> visited = <String>{};

  /// The address of the stateful node being planned, so a slot is a place and not an order: a
  /// store is kept for the node at that address, the way Flutter keeps state on the element that
  /// sits there.
  final List<String> _path = <String>[''];
  final List<int> _counts = <int>[0];

  ElementPlan planTree(core.UINode tree) =>
      planNode(tree, sheet, options: options);

  /// The questions this target answers when planning: a runtime is present, so an overlay in the
  /// tree is a dialog a reader can see and close, and a stateful node keeps its store instead of
  /// being read once.
  PlanOptions get options => PlanOptions(
    showOverlays: true,
    embed: (core.EmbedNode embed) => planEmbed(embed, sheet),
    onPlanned: (ElementPlan plan, core.UINode node) =>
        nodes.putIfAbsent(plan, () => node),
    stateful: _planStateful,
  );

  String css(core.UniboxTheme? theme) => documentCss(sheet, theme: theme);

  /// Records the element a plan became, for binding and for the next pass.
  void record(ElementPlan plan, web.Element element) => built[plan] = element;

  ElementPlan _planStateful(
    core.StatefulNode<Object, core.Store<Object>> node,
    Stylesheet sheet,
    PlanOptions options,
  ) {
    final String slot = _slotOf(node);
    visited.add(slot);

    final _Mount mount = _view._mounts[slot] ??= _Mount(node, _view);
    mount.node = node;

    _path.add(slot);
    _counts.add(0);

    try {
      final ElementPlan plan = planNode(
        node.viewFor(mount.store.state, mount.store),
        sheet,
        options: options,
      );
      mount.plan = plan;

      return plan;
    } finally {
      _path.removeLast();
      _counts.removeLast();
    }
  }

  /// The address of [node] within the tree: its key when it has one, else where it sits.
  String _slotOf(core.UINode node) {
    final int ordinal = _counts.last++;
    final String name = node.key?.toString() ?? '#$ordinal';

    return '${_path.last}/${node.runtimeType}:$name';
  }
}

/// A store, the node that draws it, and the subscription that keeps the page up to date.
final class _Mount {
  _Mount(this.node, DomView view) : store = node.createStore() {
    _changed = () => view._repaintBoundary(this);
    store.addListener(_changed);
    // `onMount` is what starts the work a component does when it appears. A publish from it is
    // queued by the view rather than drawn in the middle of the first pass.
    store.onMount();
  }

  core.StatefulNode<Object, core.Store<Object>> node;
  final core.Store<Object> store;
  late final void Function() _changed;

  /// The plan of the view this node drew, and the element it became: the boundary a publish
  /// re-renders. A ripple publishes sixty times a second, and a page re-planned on each of those
  /// would put a whole page's patching between a press and its release.
  ElementPlan? plan;
  web.Element? element;

  void release() {
    store.onUnmount();
    store.removeListener(_changed);
    store.dispose();
  }
}

/// An embed, written into the page as the markup it carries.
///
/// Only a `String` payload is drawn: an embed carrying something for another target is reported
/// rather than skipped, because a page with a piece missing is worse than a failure. The wrapper
/// takes no part in the layout, for the reason the string renderer gives — an `<iframe>` asking for
/// `height: 100%` needs an ancestor with a height.
ElementPlan planEmbed(core.EmbedNode embed, Stylesheet sheet) {
  for (final Object implementation in embed.implementations) {
    if (implementation is String) {
      return ElementPlan.raw(
        tag: 'div',
        raw: implementation,
        className: sheet.classFor(
          'embed',
          CssDeclarations()..add('display', 'contents'),
        ),
        attributes: nodeAttributes(embed),
      );
    }
  }

  throw UnsupportedError(
    'No DOM renderer for ${embed.runtimeType}: this target draws an HtmlEmbed, and the node '
    'carries ${embed.implementations.map((Object it) => it.runtimeType).join(', ')}.',
  );
}
