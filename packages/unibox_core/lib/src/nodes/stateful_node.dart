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
/// the conformance table already know how to handle. A view draws no overlay of its
/// own: a dialog is an [OverlayNode] in the tree the view returns, so the state
/// decides whether it is there and the node decides how it is presented.
///
/// **A parameter the store copied is reconciled by [update].** The view is built
/// from the node drawn *now*, so a parameter it reads is always current; a parameter
/// the store copied when it was created is not, and a store cannot look at a node.
/// [updateFor] is where a component brings the two back together, and a renderer
/// calls it when a node of the same type and key is drawn where this one was. A
/// component that keeps every parameter out of its store needs no hook at all.
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
  StatefulNode({
    required this.create,
    required this.view,
    this.update,
    super.key,
  });

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

  /// Reconciles [Store] with the parameters of the node that replaced this one.
  ///
  /// A renderer calls it when an instance of the same type and key is drawn where
  /// this node was — the same place in the tree, and therefore the same store — and
  /// builds the view from the state it leaves behind. `null` is a component that
  /// keeps nothing a parameter could make stale, which is most of them.
  ///
  /// The closure is the *new* node's, so it reads the parameters that changed;
  /// `state` is what the store held before, and publishing through the store is how
  /// a reconciliation takes effect. Assigning a state equal to the current one
  /// publishes nothing, so it is safe to call for a node whose parameters did not
  /// change — a fact a renderer cannot know, because the node only describes them.
  ///
  /// A view always sees the current parameters, because it is built from the node
  /// drawn now. This hook exists for the other half: what a store copied when it was
  /// created — the number of tabs it can select, the value it was seeded with — and
  /// which only the component knows how to repair.
  final void Function(S state, C store)? update;

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

  /// Brings [Store] up to date with this node, for the erased types a renderer holds.
  ///
  /// A node with no [update] does nothing, which is what makes the hook optional; a
  /// renderer therefore calls it for every node it draws where it drew another one of
  /// the same type and key, rather than asking whether there is anything to do.
  void updateFor(Object state, Object store) =>
      update?.call(state as S, store as C);

  @override
  List<UINode> get children => const <UINode>[];

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'stateful';
}
