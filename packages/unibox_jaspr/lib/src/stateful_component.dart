import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'render.dart';
import 'stylesheet.dart';

/// A Jaspr component that draws a [core.StatefulNode].
///
/// A server draws the state the store starts with and stops there: nothing
/// listens, `onMount` is not called, and the store is released, so rendering a
/// page never starts a request. A browser does the whole job: it keeps the store,
/// calls `onMount`, and redraws the tree whenever the store changes.
///
/// Use it for the part of a page that has to react. Write one subclass, mark it
/// `@client` so that Jaspr also compiles it for the browser, and return the node
/// from [createNode]:
///
/// ```dart
/// @client
/// class ListingsPage extends JasprStateful {
///   const ListingsPage({required this.apiBase, super.key});
///
///   final String apiBase;
///
///   @override
///   core.StatefulNode<Object, core.Store<Object>> createNode() =>
///       StoreFrontPageNode(api: HttpApi(apiBase));
/// }
/// ```
///
/// [createNode] is a method and not a constructor parameter because a `@client`
/// component may only receive simple values — the ones Jaspr can write into the
/// page and read back in the browser. A node is a group of functions, so each
/// side builds it instead of passing it across.
abstract class JasprStateful extends StatefulComponent {
  /// Creates the component. A subclass passes its own serialisable parameters.
  const JasprStateful({super.key});

  /// The node to draw. It is built on the server and in the browser.
  core.StatefulNode<Object, core.Store<Object>> createNode();

  @override
  State<JasprStateful> createState() => JasprStatefulState();
}

/// A [JasprStateful] that draws a node the tree already holds.
///
/// [JasprStateful] is for a page: a host subclasses it and builds its node. A node
/// that sits in the middle of a tree already exists, so this component takes it and
/// gives it the same lifecycle: a server reads the first state and lets the store
/// go, a browser subscribes, calls `onMount` and redraws when it is notified. A node
/// is a group of closures, so it is handed over in the same process and never has to
/// cross the wire — which is why this needs neither a `@client` marker nor generated
/// code, unlike a component whose *parameters* must be serialisable.
class JasprStatefulNode extends JasprStateful {
  /// Creates the component around [node].
  const JasprStatefulNode({required this.node, super.key});

  /// The node to draw, kept rather than built.
  final core.StatefulNode<Object, core.Store<Object>> node;

  @override
  core.StatefulNode<Object, core.Store<Object>> createNode() => node;
}

class JasprStatefulState extends State<JasprStateful> {
  late final core.StatefulNode<Object, core.Store<Object>> _node = component
      .createNode();

  /// The long-lived store, in a browser only.
  core.Store<Object>? _store;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _store = _node.createStore()
        ..addListener(_changed)
        ..onMount();
    }
  }

  @override
  void dispose() {
    _store
      ?..onUnmount()
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Component build(BuildContext context) {
    final core.Store<Object> store = _store ?? _node.createStore();
    // The node is read again on every build: a parent that redraws hands this
    // component a new node, whose view closes over the parent's new state. Only the
    // store outlives a rebuild.
    final Component tree = renderNode(
      component.createNode().viewFor(store.state, store),
    );

    if (!kIsWeb) {
      // A server render reads the first state and lets the store go: nothing
      // will ever notify it.
      store.dispose();
    }

    // A host may use this component as the root of a page, in which case nothing
    // above it opened a stylesheet.
    return withStylesheet(context, tree);
  }
}
