# PagerNode

`PagerNode` is a [box](box.md) that settles on one child at a time. It scrolls along its own
`direction` and stops on a child instead of between two, so a row of full-width pages pages
sideways and a column of full-height pages pages downwards. The mechanism is each target's own
— `scroll-snap-type` with `scroll-snap-align: start` on the children in a browser, a scroll
view with page physics in Flutter — so what the model states is the *relation*, not either
implementation.

```dart
PagerNode(
  width: 280,
  height: 96,
  direction: Axis.horizontal,
  index: state.selected,
  onPageChanged: store.settled,
  children: <UINode>[
    for (final UINode page in pages) page,
  ],
)
```

It takes every parameter a `Box` takes, plus:

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `index` | `int?` | none | The child the pager shows, counted along its own axis. A tree drawn twice with the same index moves nothing; a different one moves a child, and that move is a jump. |
| `onPageChanged` | `PageChangedCallback?` | none | The page the pager came to rest on, whether the reader swiped there or the tree asked for it. |

It does **not** take `overflow`: a pager scrolls, and the node states that for the tree the
way it states that a page is the size of the box. A bag that names another value is overruled.

**Every child is the size of the pager.** That is the whole of the relation, and it is what
makes a browser's snap edge and Flutter's page edge the same one. `validateTree` reports a pager
that states no main-axis size, a child that states another size, a non-`Box` child, an index
past the last page, and a `pin` inside one — a band pinned to a viewport that shows one page at
a time would be painted over the page that replaced it.

**The move is a jump.** A browser's programmatic scroll can be given neither a duration nor a
curve, so an eased move would be an animation only Flutter has, and the two renderings would
differ by exactly the thing the model refuses to leave to a host. Where a move should be eased,
that is a component's business — the same line the model draws between a token and a look.

**Worth knowing.** The settled report is what lets one store drive both the pager and a bar
above it: the example's tabs demo composes a `MaterialTabBar` with a `PagerNode` over one store,
and needs no marker to tell a press from a swipe. On the web the index is applied with
`scrollTo` and reported from the browser's own `scrollend` (with a debounced `scroll` for
browsers that lack it); in Flutter it is the viewport's own page, applied after the frame that
laid the pager out.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
