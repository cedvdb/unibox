import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';
import 'package:unibox_element/unibox_element.dart';
import 'package:web/web.dart' as web;

import 'events.dart';
import 'patch.dart';

/// The attribute that marks a stylesheet as this library's own.
const String _cssAttribute = 'data-unibox-css';

/// The value that marks the sheet a *runtime* wrote, apart from the one a document was served
/// with.
///
/// The two must not share an element, because adoption keeps elements it never planned: a
/// `BoxShape`'s `<svg>` layer and its `<path>` are invented by the plan rather than by the tree, so
/// no node pairs with them and no class of theirs is registered here. Writing this view's sheet
/// over the served one therefore deleted the rules those adopted elements were painted by — a
/// shaped box lost its `fill` and `stroke` and fell back to SVG's initial black, which turned a
/// progress ring into a black disc.
const String _clientSheet = 'client';

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

    // The page and this bundle are from two builds of one tree. When they are from the *same* build
    // the markup is what this client would have drawn, so the client only has to say which element
    // does what — no plan, no patch, no stylesheet, and therefore no touch on the scroll position,
    // the focus or the caret of a reader who has already started reading.
    //
    // A mismatch — a cached document against a newer bundle — takes the slow path: plan, patch,
    // rewrite. That path is also what repairs the page.
    if (!view._adopt(root)) {
      view._paint();
    }

    return view;
  }

  final web.Element _host;
  final core.UniboxTheme? _theme;
  final Stylesheet _sheet = Stylesheet();
  final Map<String, _Mount> _mounts = <String, _Mount>{};
  final Map<web.Element, List<void Function()>> _listeners =
      <web.Element, List<void Function()>>{};

  /// The page each pager was last moved to, so a rebuild with the same page leaves a reader alone.
  final Map<web.Element, int> _pages = <web.Element, int>{};
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
            web.document.createElement('style') as web.HTMLStyleElement
              ..setAttribute(_cssAttribute, _clientSheet);
        web.document.head!.append(created);
        _style = created;
      }

      _style!.textContent = pass.css(_theme);
    } else {
      _element = buildElement(next, onBuilt: pass.record);
      // Marked as the tree's stylesheet either way, so an adoption later rewrites this element
      // instead of adding a second copy of the same rules — and so a reader can find it.
      _style = web.document.createElement('style') as web.HTMLStyleElement
        ..setAttribute(_cssAttribute, _clientSheet)
        ..textContent = pass.css(_theme);
      web.document.head!.append(_style!);
      _host.replaceChildren(_element!);
    }

    _plan = next;
    _bindAll(pass, next);
    _syncElements(pass);
    _sweep(pass.visited);
  }

  /// Pairs the tree's nodes with the page's elements and binds what they do.
  ///
  /// Returns `false` when the page is not this tree's own rendering — a label that does not match,
  /// a count that does not line up, or a document from another build — so the caller falls back to
  /// planning and patching.
  bool _adopt(web.Element root) {
    if (!_sameBuild()) {
      return false;
    }

    final _Pass pass = _Pass(this, _sheet);
    final List<core.UINode> nodes = <core.UINode>[];
    pass.collect(_tree, nodes);

    final List<web.Element> elements = <web.Element>[
      if (root.getAttribute('data-unibox-node') != null) root,
      for (
        int i = 0;
        i < root.querySelectorAll('[data-unibox-node]').length;
        i++
      )
        root.querySelectorAll('[data-unibox-node]').item(i)! as web.Element,
    ];

    if (nodes.length != elements.length) {
      return false;
    }

    for (int i = 0; i < nodes.length; i++) {
      if (elements[i].getAttribute('data-unibox-node') != nodes[i].debugName) {
        return false;
      }
    }

    for (int i = 0; i < nodes.length; i++) {
      final List<void Function()> undo = bindNode(nodes[i], elements[i]);

      if (undo.isNotEmpty) {
        _listeners[elements[i]] = undo;
      }
    }

    _plan = null;

    for (final String slot in pass.visited) {
      final _Mount? mount = _mounts[slot];
      final int? at = mount?.at;

      if (mount != null && at != null && at < elements.length) {
        mount.element = elements[at];
      }
    }

    return true;
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

    if (element == null) {
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

    final _Pass pass = _Pass(this, _sheet, boundary: mount.slot);
    final ElementPlan next = planNode(
      mount.node.viewFor(mount.store.state, mount.store),
      _sheet,
      options: pass.options,
    );

    // A boundary adopted from a page has no plan yet: it was paired with its element, never drawn.
    // The first publish is when it is planned — and from then on it patches like any other.
    mount.element = patchElement(
      element,
      mount.plan ??
          ElementPlan(
            tag: next.tag,
            className: element.className.isEmpty ? null : element.className,
          ),
      next,
      onBuilt: pass.record,
    );
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

      _applyPage(node, element);
    }

    for (final ElementPlan child in plan.children) {
      _bindAll(pass, child);
    }
  }

  /// Slides a pager to the page the tree says it shows, when that is not where it already is.
  ///
  /// A page is a position rather than a command: the box moves only when the value differs from the
  /// one last applied, so a publish during a reader's swipe does not pull the page out from under it.
  /// The width of a page is the box's own, which is why the target is `page × clientWidth`.
  void _applyPage(core.UINode node, web.Element element) {
    if (node case final core.Box box
        when box.page != null && box.snap == core.ScrollSnap.page) {
      final int page = box.page!;

      if (_pages[element] == page) {
        return;
      }

      final bool first = !_pages.containsKey(element);
      _pages[element] = page;

      final core.BoxStyle style = box.computedStyle;
      final bool horizontal = style.resolvedDirection == core.Axis.horizontal;
      // The extent of a page comes from the box, when the box states one: a pager is a child the size
      // of its box, so the size is in the tree. It is read from the layout only when the box expands,
      // because an element that was inserted in this frame has not been laid out yet and reports 0.
      final double? stated = horizontal ? style.width : style.height;
      final double extent = stated != null && stated.isFinite
          ? stated
          : (horizontal
                ? element.clientWidth.toDouble()
                : element.clientHeight.toDouble());

      // Reading the scrollable extent flushes layout, which an element inserted in this frame does not
      // have yet: a scroll applied before it is clamped to zero and the page never moves.
      final double scrollable = horizontal
          ? element.scrollWidth.toDouble()
          : element.scrollHeight.toDouble();

      if (extent <= 0 || scrollable <= 0) {
        return;
      }

      final double target = page * extent;

      element.scrollTo(
        web.ScrollToOptions(
          left: horizontal ? target : 0,
          top: horizontal ? 0 : target,
          // A jump on the first application — a pager sliding into place as it appears is a flash —
          // and a slide for every press after it.
          behavior: first ? 'instant' : 'smooth',
        ),
      );
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

/// The build this bundle was compiled from, if the build said so.
///
/// `tool/site.sh` passes it to `dart compile js` and to the document, so a page and a client are
/// known to come from one build — which is the whole question an adopting client asks before it
/// trusts markup it did not write.
const String _clientBuild = String.fromEnvironment('unibox-build');

/// Whether the page was written by this build.
bool _sameBuild() {
  final web.Element? meta = web.document.querySelector(
    'meta[name="unibox-build"]',
  );

  return (meta?.getAttribute('content') ?? '') == _clientBuild;
}

/// The stylesheet a document wrote, if it is there, so a client rewrites it instead of adding a
/// second copy of the same rules.
web.HTMLStyleElement? _stylesheetIn(web.Element? head) =>
    head?.querySelector('style[$_cssAttribute="$_clientSheet"]')
        as web.HTMLStyleElement?;

/// One planning pass: the stylesheet it builds, the node each plan came from, and the element each
/// plan became.
final class _Pass {
  /// Plans a tree, or one boundary's view of its state.
  ///
  /// [boundary] is the slot of the node the pass starts at, and it is what keeps a store on the
  /// element that drew it: a repaint of a boundary plans that node's view directly, so the nodes
  /// inside it are numbered from the boundary's own address — the address the pass that drew the
  /// boundary gave them. Numbered from nothing instead, they would take the addresses of the
  /// controls beside the boundary, and one control's store would be drawn by another's element.
  _Pass(this._view, this.sheet, {String boundary = ''})
    : _path = <String>[boundary];

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
  final List<String> _path;
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

  /// Collects the nodes of [tree] in the order their elements appear, expanding stateful nodes.
  ///
  /// A stateful node has no view until its store exists, so this is where the stores are created:
  /// one per address, as in a planning pass, and the same mounts are the ones a later publish
  /// re-renders.
  void collect(core.UINode tree, List<core.UINode> into) {
    if (tree
        case final core.StatefulNode<Object, core.Store<Object>> stateful) {
      final String slot = _slotOf(stateful);
      visited.add(slot);

      final _Mount mount = _view._mounts[slot] ??= _Mount(
        slot,
        stateful,
        _view,
      );
      mount.node = stateful;
      // Where this boundary starts in the node list, so an adoption can pair it with the element the
      // page already has: the first element of the view it draws.
      mount.at = into.length;

      _path.add(slot);
      _counts.add(0);

      try {
        collect(stateful.viewFor(mount.store.state, mount.store), into);
      } finally {
        _path.removeLast();
        _counts.removeLast();
      }

      return;
    }

    into.add(tree);

    for (final core.UINode child in tree.children) {
      collect(child, into);
    }
  }

  /// Records the element a plan became, for binding and for the next pass.
  void record(ElementPlan plan, web.Element element) => built[plan] = element;

  ElementPlan _planStateful(
    core.StatefulNode<Object, core.Store<Object>> node,
    Stylesheet sheet,
    PlanOptions options,
  ) {
    final String slot = _slotOf(node);
    visited.add(slot);

    final _Mount mount = _view._mounts[slot] ??= _Mount(slot, node, _view);
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
  _Mount(this.slot, this.node, DomView view) : store = node.createStore() {
    _changed = () => view._repaintBoundary(this);
    store.addListener(_changed);
    // `onMount` is what starts the work a component does when it appears. A publish from it is
    // queued by the view rather than drawn in the middle of the first pass.
    store.onMount();
  }

  /// The address this store is kept at: the node's place in the tree.
  ///
  /// A repaint of this boundary plans its view from here, so the nodes inside it are addressed the
  /// way the pass that drew them addressed them.
  final String slot;

  core.StatefulNode<Object, core.Store<Object>> node;
  final core.Store<Object> store;
  late final void Function() _changed;

  /// The plan of the view this node drew, and the element it became: the boundary a publish
  /// re-renders. A ripple publishes sixty times a second, and a page re-planned on each of those
  /// would put a whole page's patching between a press and its release.
  ElementPlan? plan;
  web.Element? element;

  /// Where this boundary's first element sits among the nodes an adoption walked.
  int? at;

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
