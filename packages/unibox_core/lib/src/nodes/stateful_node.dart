import '../state/store.dart';
import 'ui_node.dart';

/// A node that owns a state store and draws the tree of that state.
///
/// ```dart
/// final class SignupNode extends StatefulNode<SignupState, SignupStore> {
///   SignupNode() : super(create: SignupStore.new, view: signupView);
/// }
///
/// UINode signupView(SignupState state, SignupStore store) => Box(
///   children: <UINode>[
///     TextInputNode(value: state.email, onChanged: store.setEmail),
///     Box(onTap: store.submit, children: const <UINode>[TextNode('Join')]),
///   ],
/// );
/// ```
///
/// `StateStore` in this package is the ready made store; an application may also
/// implement [Store] itself.
///
/// **The node holds a factory, never the store.** A renderer calls
/// [createStore] once per mounting, subscribes to it, and disposes it on
/// unmount; a rebuild of the same node (same `key`) keeps the state, a different
/// key starts again. That is what keeps the tree immutable: the description of
/// the page is the node, and the mutable part is created next to it.
///
/// **The view is a function of state.** [viewFor] returns one tree for the
/// current state, so every state a component can be in — a pending request, a
/// result, an error — is an ordinary tree that the renderers, `validateTree` and
/// the conformance table already know how to handle. A view draws no overlay: a
/// dialog is not part of the model yet.
///
/// A renderer reaches any stateful node through [StatefulNode]<[Object],
/// [Store]<[Object]>, because generics are covariant and every instantiation is
/// a subtype of that one. `children` is empty: the children belong to the view
/// that is built at render time, not to the description.
class StatefulNode<S extends Object, C extends Store<S>> extends UINode {
  /// Creates a node whose state is created by [create] and drawn by [view].
  ///
  /// Neither function runs at construction time: [create] runs when a renderer
  /// mounts the node, [view] on every render of the state it was given.
  StatefulNode({required this.create, required this.view, super.key});

  /// The factory of the store this node draws.
  ///
  /// A renderer calls it once per mounting, then subscribes to the result; the
  /// node never holds the instance, which is what keeps the tree immutable.
  final C Function() create;

  /// Draws one state, with the store for the callbacks the view hands out.
  ///
  /// It is a function and not a method so that a view can be a top level
  /// function with its own types, shared by every node that draws it.
  final UINode Function(S state, C store) view;

  /// Creates the store for one mounting of this node.
  ///
  /// The spelling a renderer uses: it only knows the erased form of this node,
  /// so the typed field is behind this method.
  Store<S> createStore() => create();

  /// The tree of [state], with [store] for the callbacks the view hands out.
  ///
  /// [state] and [store] are [Object] because a renderer only knows the erased
  /// form of this node; the node casts them back to [S] and [C], so a view is
  /// written with its own types.
  UINode viewFor(Object state, Object store) => view(state as S, store as C);

  @override
  List<UINode> get children => const <UINode>[];

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'stateful';
}
