# OverlayNode

Content drawn above the page instead of in the layout of its parent: a dialog, a
sheet, a menu. Being in the tree is being shown, so the state decides presence and
the node decides policy:

```dart
UINode details(StoreFrontState state, StoreFrontStore store) => Box(
  children: <UINode>[
    const TextNode('Store front'),
    if (state.details != null)
      OverlayNode(
        onDismiss: store.closeDetails,
        child: TextNode(state.details!.name),
      ),
  ],
);
```

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `child` | `UINode` | required | The content shown above the page. |
| `onDismiss` | `TapCallback?` | none | Called by `Escape` and by a press on the barrier. |
| `barrierDismissible` | `bool` | `true` | Whether a press on the barrier dismisses. |
| `barrierColor` | `BoxColor` | black at 32% | The scrim between the page and the content. |
| `alignment` | `OverlayAlignment` | `center` | `center`, `top` or `bottom`. |

**On each target.** Flutter presents it through an `OverlayPortal` on the root
overlay, so it escapes the clipping and scrolling of the boxes around it: a
barrier, `Escape`, focus kept inside and handed back on exit. The web renders a
fixed layer that holds the barrier and the content, and the interaction waits for
the client build.

**The layer is the window, and it bounds the content.** A dialog holding more than
the window is a scroll away rather than a taller box: both targets lay the content
out in the room the window gives and scroll the rest, so the same card is the same
height on both — a dialog that grew past the window used to be as tall as its
content on the web and cut off at the window in Flutter. `validateTree` reports a
dismissible barrier with no `onDismiss`, which could not dismiss anything, and a
content that fills its height, which the room it is drawn in has no end for.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
