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
| `key` | `Object?` | Keeps the state across rebuilds; a different key starts again. |

The view returns one tree for the state, so every state a page can be in — a
pending request, a result, an error — is an ordinary tree the renderers already
know how to draw. A view draws no overlay of its own: a dialog is an
[`OverlayNode`](overlay.md) in the tree the view returns, so the state decides
whether it exists and the node decides how it is presented.

**State lives in a store, not in the node.** [`Store`](../../packages/unibox_core/README.md#state)
is the contract and `StateStore` is the ready-made implementation in the same
package: its listener list is its own, so a store needs no dependency and runs in
Flutter, on a server and in a browser. `onMount` is where an initial request
starts, which is also why a server render can draw the first state without running
it.

`FlutterStateful` is the runtime: it creates the store, subscribes to it and disposes it. A
document has none — `unibox_html` creates the store only to read it, draws **the state it
starts with** and never calls `onMount`, so a page that loads is a page that says it is
loading. Reacting to a press is the application's job once it takes the page over.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
