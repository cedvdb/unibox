# A plan: the four gaps the explore page found

This is the working plan for the report from the application that uses Unibox to draw
an explore page (a header, a hero, a pinned search/filter bar, a grid of cards beside a
map panel, a footer — the scroll belongs to the host, never to the tree). It lists the
tasks in the order they land, what the model gains, and what each target does for it.
Tasks that are deliberately not done are listed with the reason.

The rule for every task is the repository's own: the model states it, both renderers
draw it, `unibox_testing` holds them to the same answer, and the docs move in the
same commit.

## 1. A share of the viewport, with an inset taken off

**The gap.** `heightFraction` is a share of the *parent*, and the parent of anything on
a scrolling page has no height to share, so a map panel cannot say "as tall as the
screen, less the header and the bar". `double.infinity` is a number, not a viewport.

**The decision.** The fraction tokens stop being bare numbers and become a value that
names *what the share is of*:

```dart
Box(heightFraction: BoxFraction.viewport(1, minus: 216))  // calc(100dvh - 216px), floored at 0
Box(heightFraction: BoxFraction.parent(0.5))              // 50% of the box around it
```

`BoxFraction` is one small value type (`of`, `value`, `minus`) with two const
constructors; `widthFraction` and `heightFraction` change type from `double?` to
`BoxFraction?`. A viewport share is `MediaQuery.sizeOf` minus the inset in Flutter and
`calc(<f>dvh - <inset>px)`, floored with `max(0px, …)`, on the web. A parent share
without an inset keeps `FractionallySizedBox` and `%`, so nothing that exists today
changes shape.

**Tasks.**

- [ ] `packages/unibox_core/lib/src/tokens/box_fraction.dart`: the value type, its
      constructors, `==`, `hashCode`, `toString`, and the resolution both renderers read.
- [ ] `box_style.dart`: the two fields change type, plus `merge`, `copyWith`, `==`,
      `hashCode` and `toString`.
- [ ] `box.dart`: the flat parameters and `_flatStyle`, and the doc comments that say
      "a share of the parent".
- [ ] `validation.dart`: a share of zero or less, and a negative inset, are reported; a
      parent share with an inset is not, because both targets can honour it.
- [ ] Flutter: `values.dart` and `box.dart` — `FractionallySizedBox` for a parent share,
      a `MediaQuery`-resolved `SizedBox` for a viewport share, and a `LayoutBuilder` only
      when a parent share carries an inset.
- [ ] Web: `values.dart` (`cssFractionOf`), `box.dart` (one declaration per axis).
- [ ] Tests: a core test for the merge and the resolution, a Flutter widget test that a
      viewport height follows the window, a CSS test for the declaration, and the
      contract note that the appearance table reads a parent share only.
- [ ] Docs: `docs/nodes/box.md`, `packages/unibox_core/README.md`, `design.md` §5.2,
      `AI_INSTRUCTIONS.md`, the changelogs.

## 2. A pinned band whose height is its own

**The gap.** `validateTree` demands a finite `height` on a pinned box because the Flutter
renderer held the band's slot open with the stated number. A filter bar that wraps has no
stated height, and CSS's `position: sticky` needs none.

**The decision.** The slot is the band's own measured height, on both targets: a browser
lays the sticky element out in the flow and only its paint offset moves, and the Flutter
renderer now does the same — the band is laid out once over the viewport and the flow
reads its height back for the slot. `minHeight` therefore composes with `pin`: the band is
at least what it says, and grows when its content wraps.

**Tasks.**

- [ ] `validation.dart`: drop the "pinned band without a finite height" error; keep the
      error for a band that states `height: double.infinity` (a band fills nothing) and
      the ones for a share, a negative inset and the wrong viewport.
- [ ] Flutter `box.dart`: `_RenderPinnedBand` lays the band out at the viewport's width
      and *measures* it instead of tightening it to a stated height; the flow's slot reads
      that height; the layer lays its children out in reverse and paints them in order, so
      the slot can read the band it follows and the band still paints over the content
      that scrolls under it.
- [ ] Tests: Flutter — a band that wraps pins with no stated height, and the results below
      it keep their place; core — the validation cases that change.
- [ ] Docs: `docs/nodes/box.md`, the pin section of the core README, `design.md` §5.5,
      `AI_INSTRUCTIONS.md`, the changelogs.


## 3. A stretch that is as tall as the tallest sibling

**The gap.** `CrossAlign.stretch` on a row inside an unbounded column throws in Flutter
("BoxConstraints forces an infinite height") because the child was filled with
`SizedBox(height: double.infinity)`. The web does what CSS does: the line is as tall as
its tallest item, and the others fill it.

**The decision.** A renderer fix, no model change: a line that was given no end on its
cross axis resolves its own extent from its children, and a child fills *that*. A child
that states its own height keeps it, which is what `align-items: stretch` means.

**Tasks.**

- [ ] Flutter `box.dart`: `_StretchedLine`, which lays a line out twice when its cross
      axis is unbounded — once to find the tallest child, once tight to that extent — and
      `_FillCross`, which fills the room it is offered instead of asking for infinity (so
      the line can be laid out a second time without an infinite constraint).
- [ ] Tests: Flutter — a row of stretch children in a scrolling column is as tall as its
      tallest child, and one that states a height keeps it; web — the same tree measures
      as the tallest child (`align-items: stretch` is already declared).
- [ ] Docs: the stretch paragraph of the core README and of both renderer READMEs.

## 4. The components forward the pin

**The gap.** `MaterialAppBar` takes `pin`; `MaterialCard` does not, so pinning a card means
a bare wrapper and the height stated twice.

**Tasks.**

- [ ] `material_card.dart`: `pin` and `pinOffset` in the constructor and in every variant.
- [ ] Walk the other box-wrapping components (`MaterialListTile`, `MaterialButton`,
      `MaterialIconButton`, `MaterialChip`, `MaterialTabBar`, `MaterialSegmentedButton`,
      `MaterialNavigationBar`, `MaterialScaffold`, the app bars, `MaterialDialog`,
      `MaterialBottomSheet`, `MaterialInkWell`, `MaterialTextField`) and forward the
      tokens a caller would reach for on a box — the pin, and the size tokens the surface
      wrappers were dropping.
- [ ] Tests: a test per component that pins, asserting the token reaches the box.
- [ ] Docs: the Material table entry for the card, and the changelog.

## 5. Not doing: an offset that names its neighbour

`pinOffset: 48` because the header above is 48 tall is a number written twice, and a
`pinBelow: key` relation would remove the copy. It is not done because the web cannot
honour it: a browser has no way to say "the height of that other element" in CSS, so the
relation would have to resolve to a number when the tree is planned — which means the tree
carries the header's measured height, and the two targets drift the moment a language with
longer labels makes the header wrap. The number stays stated on both sides, which is
honest, and task 2 is what makes it unnecessary for the pinned band itself.

## 6. Not doing: telling a component's internals from a page's

A tree-walking test cannot tell a `GridNode` inside `MaterialSegmentedButton` from the
results grid on the page. The suggested fix — a role or a flag on component-layout nodes —
is a second vocabulary for something the model already has a word for: a component's
internals are the component's, and a walker should ask the component, not the node. The
cheap honest alternative is to reach the node by structure (the segmented button's own
children) rather than by type, and the README now says so. A flag would also be a token
with no appearance on either target, which is the one thing `tool/surface_check.py` exists
to refuse.

## 7. Not doing: a pin under a sliver child

A `CustomScrollView` → `SliverToBoxAdapter` → tree whose child pins is a case the Flutter
renderer does not honour, and the model already reports the tree it cannot honour: a pin is
a child of the box that scrolls it, and a host's scroll view is not part of the tree. Making
it work means the band's layer follows a `Scrollable` the tree does not own, plus a second
geometry (the layer's own offset inside somebody else's viewport) — a feature, not a fix,
and one whose two targets would then disagree about the *containing block* a band is clamped
to. It is recorded in the Flutter README's "what stays approximate" so nobody discovers it
twice.
