# StatefulNode

A subtree that owns its state. The node carries two functions — a factory for a
*store* and a view — and a renderer creates the store once, subscribes to it, and
rebuilds the view whenever the store publishes a new state.

```dart
final class SignupNode extends StatefulNode<SignupState, SignupStore> {
  SignupNode() : super(create: SignupStore.new, view: signupView);
}

UINode signupView(SignupState state, SignupStore store) => Box(
  children: <UINode>[
    TextNode(state.pending ? 'Joining…' : 'Join'),
    Box(onTap: store.submit, children: const <UINode>[TextNode('Continue')]),
  ],
);
```

| Member | Type | Meaning |
| --- | --- | --- |
| `create` | `C Function()` | Makes the store for one mounting. The node never holds the instance, so the tree stays a description. |
| `view` | `UINode Function(S state, C store)` | Draws one state, with the store for the callbacks the view hands out. |
| `update` | `void Function(S state, C store)?` | Reconciles the store with the parameters of the node drawn in its place. `null` means there is nothing a parameter could make stale. |
| `key` | `Object?` | Keeps the state across rebuilds; a different key starts again. |

The view returns one tree for the state, so every state a page can be in — a
pending request, a result, an error — is an ordinary tree the renderers already
know how to draw. A view draws no overlay of its own: a dialog is an
[`OverlayNode`](overlay.md) in the tree the view returns, so the state decides
whether it exists and the node decides how it is presented.

**What a view reads is current; what the store copied is not.** The view is built
from the node drawn *now*, so a parameter it reads has already changed. A store,
though, is created once per place in the tree and outlives the node that made it,
and a store cannot look at a node: a number it read at creation — how many tabs it
can select, which value it was seeded with — stays what it was. `update` is where a
component hands the store the parameters of the node that replaced it, before the
view is built:

```dart
final class Countdown extends StatefulNode<int, CountdownStore> {
  Countdown(int from)
    : super(
        create: CountdownStore.new,
        view: countdownView,
        // The store was created with a ceiling; the node drawn now is the one that says it.
        update: (int count, CountdownStore store) => store.setCeiling(from),
      );
}
```

Both renderers call it when a node of the same type and key is drawn where this one
was, and a state equal to the current one publishes nothing — so it is safe, and
intended, for it to run on drawings whose parameters did not change. A component
that keeps every parameter out of its store needs no hook at all, which is most of
them.

**State lives in a store, not in the node.** [`Store`](../../packages/unibox_core/README.md#state)
is the contract and `StateStore` is the ready-made implementation in the same
package: its listener list is its own, so a store needs no dependency and runs in
Flutter, on a server and in a browser. `onMount` is where an initial request
starts, which is also why a server render can draw the first state without running
it.

`FlutterStateful` is the runtime: it creates the store, subscribes to it and disposes it. A
document drawn by `unibox_html` has none — it creates the store only to read it, draws **the
state it starts with** and never calls `onMount`, so a page that loads is a page that says it
is loading. A page that reacts is one an application takes over, or one that ships the client
renderer: `unibox_dom` adopts the markup, keeps the stores and patches the page as they
publish, which is the same node and the same store a widget tree would have.

**A layout is a state too, and a document cannot follow a scroll.** `unibox_html` draws the
size the state it starts with asks for, so a box that should grow as the reader scrolls — a
map that stretches down a column of results — is drawn at the size of its first frame and
stays there. A stylesheet cannot take it over: the size is a class rule a host may restyle,
but the number it would need is the scroll offset, and the one scroll-driven motion the model
has is `fold:` — paint only, because a frame of an eased layout is a picture neither engine
can be held to. So a layout that follows the scroll is the application's: a `StatefulNode`
whose view puts `onScroll` on the box that scrolls and keeps the offset it is handed, drawn
by Flutter, or by a page that ships `unibox_dom` and draws that state again.

The behaviour half of the contract is tested without either target: a
[`BehaviourCase`](../../packages/unibox_testing/README.md#behaviour) names a component, the
presses a reader makes and the text each one has to produce, and both renderer suites play
that one table.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
