# GridNode

Equal columns whose count follows the width of the box — a card grid that reflows without a
breakpoint — **or** one row of columns whose widths you state: the same node, in the two
forms CSS has for `grid-template-columns`.

```dart
// a card grid that reflows
GridNode(
  minItemWidth: 280,   // the narrowest a card may get
  maxColumns: 3,       // the widest count; the columns keep growing instead
  gap: 16,
  children: cards,
)

// one row of columns, as `1fr 2fr 1fr` states them
GridNode.columns(<int>[1, 2, 1], gap: 12, children: <UINode>[nav, main, aside])
```

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `minItemWidth` | `double?` | required | The narrowest a column may get in a reflowing grid. |
| `maxColumns` | `int?` | none | Where the count stops; the columns share the width instead. |
| `columns` | `List<int>?` | none | One flex factor per child of a stated grid, in one row. |
| `gap` | `double` | `0` | The gutter between two columns and two rows. |
| `crossAlign` | `CrossAlign?` | `start` | `align-items`: `stretch` makes every column as tall as the tallest. |
| `children` | `List<UINode>` | `[]` | The cards, or the columns, in reading order. |

**A stated grid is one row of columns.** Each child gets a flex factor — the number `1fr`
takes in CSS and the one `Expanded(flex:)` takes in Flutter — and every column is as wide
as the widest content per unit, so `[1, 2, 1]` over a `nav` of 80 and a `main` of 200 is a
row of 100, 200 and 100. Given a width, the factors divide it. A column is the grid's
answer and not the child's: `validateTree` reports a `flex`, a width of its own, a
`gridSpan`, and a template whose length is not the number of children — a stated grid has
one column per child and no second row, which is what both targets can draw.

**A grid takes the width it is given and measures when it is given none.** A browser writes
`width: 100%`, which resolves against the box the grid is in and falls back to the content
where that box has no width; Flutter fills the width it is offered on the same terms. A
pill of segments therefore fills the cell it was given and hugs inside a row that scrolls,
without the tree saying which case it is in.

**A reflowing grid** fits as many columns of at least `minItemWidth` as the width allows,
caps the count at `maxColumns`, and lets the tracks share the width. The web renderer
writes one declaration — `repeat(auto-fill, minmax(min(100%, max(280px, (100% - 32px) / 3)),
1fr))` — and Flutter applies the same arithmetic (`columnsFor`, `cellWidthFor`) to the
constraints it is given, so the two agree at every width: one column at 375, two at 600,
three from 900 on, and 250 is one column of 250. Nothing in the tree reads a viewport, and
a resize sends no request.

A short last row keeps its empty tracks, because `auto-fill` creates them; a grid child
does not size or flex itself (the same `validateTree` rules as a stated grid), and a photo
inside a grid needs a height that is known before the file arrives.

**A row can be interrupted.** A card that states `gridSpan` covers that many columns, so a
promo banner between the cards is one grid rather than two grids that have to agree on a
column count:

```dart
GridNode(
  minItemWidth: 280,
  maxColumns: 3,
  gap: 16,
  children: <UINode>[
    card, card,
    Box(gridSpan: 3, children: <UINode>[banner]),   // the whole row
    ...cards,
  ],
)
```

A span wider than the grid is clamped to its column count, because the columns follow the
width: three at 900 pixels is three tracks for a banner asking for more, and one on a
phone. A span that does not fit what is left of a row starts the next one, leaving the rest
of the current row empty — what a browser's `auto-flow` does. `unibox_testing` holds both
renderers to the same placement. A stated grid has no spans: the template already says
which column each child has.

`MaterialSegmentedButton` is the component built on the stated form: a pill whose segments
are columns of one factor each.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
