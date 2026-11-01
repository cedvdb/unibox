# A fold that moves a layout

**Status: decision note, for review. This pass changes no code.**

`BoxFold` may name the background, the border colour, the corner radius, the shadows, the
opacity and the transform, and nothing else: `validateTree` reports a fold that names a
layout token (`packages/unibox_core/lib/src/validation.dart:680-729`), and
`packages/unibox_core/lib/src/tokens/box_fold.dart:12-15` gives the reason — "a layout that
moves is not a look, and two engines interpolating a layout give two different pictures on
every frame in between".

The question is whether a scroll-driven construct should be allowed to move a layout. The
case that forces it: a page with a 48 px header and a 144 px toolbar that both pin, a 24 px
gutter and a 100 px hero that folds away, with a map panel beside the results that must take
what the window has left. Written as `BoxFraction.viewport(1, minus: 316)` — which the model
now has, and which resolves to `calc(100dvh - 316px)` on both targets — it is right at rest,
584 px in a 900 px window, and 100 px short once the hero has gone. The old site did it with a
script rewriting `--catalog-map-visible-top` under `calc(100dvh - visible-top - space-l)`.

Two things are being conflated, and the note keeps them apart:

- **(A) interpolating a layout across a range** — an eased height, a growing gap, a moving
  padding. Something has to be sampled *between* two states, and both engines sample it.
- **(B) deriving a layout from a scroll-derived number** — one formula, evaluated per frame
  by each renderer from the same inputs, with no easing of its own. There is no "in between"
  for two engines to disagree about.

## 1. What exactly the rule buys

| Guarantee | Where it is enforced today | Survives if only (B) is admitted |
| --- | --- | --- |
| The frame *in between* is the same picture on both targets | By construction for the six paint tokens: `BoxFold.looks` (`box_fold.dart:66-77`) is the list, `foldDeclarations` (`packages/unibox_html/lib/src/css/values.dart:245-269`) and `_RenderFoldedBox` (`packages/unibox_flutter/lib/src/box.dart:2263-2504`) are the two consumers. For a layout token it is not the frame that matters but the axis — §2, §3 | **Its height half, and not its width half.** Measured: a height reflows nothing, so an eased or a derived height is the same picture on both targets; a width walks text across line-break thresholds where the difference is a line, so the objection is against the width axis, not against (B) |
| A scroll costs a repaint and not a rebuild | Flutter: `_scrollChanged` answers with `markNeedsPaint()` and `markNeedsSemanticsUpdate()` (`box.dart:1952-1956`). Web: the fold is an `animation-timeline: view()` animation, which Blink runs off the main thread | **No.** A layout the scroll derives is a main-thread layout on both targets, measured in §3 at one layout per frame |
| No invalidation ripple | Flutter: nothing is marked for layout; the fold layer is marked for paint. Measured in §3: 0 of 2049 render objects | **Partly.** Measured: 3 render objects, a chain to the nearest relayout boundary, not a fan-out. It becomes a fan-out only when the derived size changes the extent of its container — measured at two layouts per frame |
| Graceful degradation | Claimed in `values.dart:250-252` and `README.md:666-668`, and **false** — measured in §5 | Nothing to lose: the guarantee is not held today. A layout fold's fallback is worse, though, and has to be designed rather than inherited |
| One place for the arithmetic | `BoxFold.progressAt` (`box_fold.dart:84`): one clamp, one fraction, both renderers | **Yes for a formula, no for a fixed point.** A box that resizes the range it reads is not a function of the offset until it has settled; measured in §4 |

So of the five: three survive in a formula's world — parity by construction, one place for
the arithmetic, and no rebuild — two do not, because a layout the scroll derives is a
main-thread layout and it marks a chain of render objects, and one, graceful degradation, is
not being delivered today at all. The guarantee that is strongest on paper — that both
renderers draw the same picture — turns out to be untested for the fold's *driver*, which is
where the two targets currently disagree (§5), and to be a claim about the **width axis** rather
than about layout as such (§2). So the rule forbids more than its reason supports — and it stays
as it is, because what actually stops the case is the model's vocabulary, not the permission
(§2, and the decision at the end).

## 2. Is the "two engines" objection a reason against (A), against (B), or against both?

**The way the rule states it is the weak version, and for a height it is simply wrong.** "Two
engines interpolating a layout give two different pictures on every frame in between" assumes
that an intermediate value is a picture neither can be held to. Three things are wrong with
that as written:

- A transition's intermediate frame lasts one refresh and cannot be held, screenshotted or
  reached by a link. Nobody can compare it, so nobody needs it to match. That is why the model
  does not need a rule for transitions at all: `BoxProperty` has no layout member
  (`packages/unibox_core/lib/src/tokens/box_transition.dart:8-40`), so the vocabulary is the
  enforcement, and `validation.dart:630`'s claim that "a transition and a fold both refuse" the
  same thing is decoration.
- A *height* is not a reflow. Text depends on width: a box 100 px taller lays its paragraph out
  in the same line boxes at the same widths, and everything inside it moves only in the one
  direction both engines compute from the same number. Measured in §3: a panel stepped from
  584 px to 684 px leaves every child's x, width and line box byte-identical and the document
  height unchanged.
- Two interpolators sampling one number do not draw different pictures — they draw the same
  picture at numbers that differ in the last decimal. A browser's LayoutUnit is 1/64 px and
  Flutter's is a double, so an eased height can disagree by a fraction of a pixel and put a
  clipped row on the other side of an edge. That is a pixel, not a layout.

**What does survive, and it is narrower: a fold may not change a width.** A width is where two
text engines disagree in kind rather than in degree. Line breaking is a step function of width,
so a range of widths walks a paragraph across thresholds, and at a threshold one engine fits the
word and the other does not — the difference is a whole line, not a rounding. Measured for
137 characters of Arial at 16 px over a 100 px width sweep: exactly one threshold (at 390 px, a
four-line paragraph becoming three, 89.56 px → 67.17 px). One or two widths in a fold's range,
then, where the two targets must agree to the pixel and where no appearance in
`unibox_testing` pins anything — and a range is what turns that from a fact about one size into
a fact about a hundred sizes.

The same objection covers the tokens that distribute free space, for a different reason:
`gap`, `mainAlign`, `crossAlign`, `flex`, `gridSpan`, `direction`, `wrap` and `aspectRatio` are
where a browser's flexbox and `RenderFlex` genuinely differ, and neither the fold nor the table
can say which of them is right. Both groups change how much room something has; a height does
not.

So the parity objection is not against (A) as against (B) — it is against an **axis**. It bites
equally hard on an eased width and on a derived width, and not at all on an eased or derived
height. That is the correction this note owes the rule: it forbids the safe half of the layout
along with the unsafe half.

If a layout fold is admitted, a renderer must be forbidden from doing three things, and each is
checkable in `validateTree`:

1. **Easing a width.** No `curve` on a fold that names a width or a free-space token, because
   the threshold then falls at a time the reader did not choose rather than at a position they
   can hold. (On the height axis a curve is a position reparameterised and the same
   measurement applies — a linear fold and an eased one visit the same sizes in a different
   order — so it is a taste, not a rule; refusing it is still the cheaper decision, because one
   rule is easier to hold than two.)
2. **Naming a width, or a token that redistributes free space.** `width`, `widthFraction`,
   horizontal `padding` and `margin`, `gap`, `mainAlign`, `crossAlign`, `direction`, `wrap`,
   `flex`, `gridSpan` and `aspectRatio` stay refused: §3's measurement is about exactly these.
   `height`, `minHeight`, `maxHeight` and vertical `padding` and `margin` are the candidates,
   and on them the two targets are held to the same picture by the same argument that holds a
   static tree.
3. **Moving the range it reads.** The box whose size is derived may not be the box that defines
   the range: not the box whose exit fraction is the driver, not a box that changes the scroll
   extent of the box that scrolls it, and not a box inside one whose extent is the document's.
   Otherwise the value is a fixed point of `f`, not `f(t)` — measured in §4.

The third is the one the current model cannot express, because `BoxFold` is driven by *its own
box's* exit (`box.dart:2352`: `left = (-top / size.height)`). A fold on the map panel is
driven by the panel's exit, which does not begin until 316 px of scroll; the consumer's case is
driven by the *hero's* exit.

Half of the case has landed since this note was first written, which sharpens the point rather
than weakening it. A size can now be stated against the window: `BoxFraction.viewport(1, minus:
216)` resolves to `max(0px, calc(100dvh - 216px))` on both targets
(`packages/unibox_core/lib/src/tokens/box_style.dart:226-232`), so the panel the case describes
can be written correctly *at rest*, today, with no new token. What no token can say is which
number — the window less 316 while the hero is there, less 216 once it has gone. So the missing
piece is the driver, not the size: nothing lets that `minus` be a function of another box's exit,
and a fold reads its own. Removing the validator block today would therefore admit exactly one
shape — a box resizing the range it reads — which is §4.

That is the whole of the parity question, and it is not the decision. The decision is that the ban
stays as it is: a permission the model cannot express buys nothing, and the one shape it would
legalise today is the box that resizes the range it reads (§4). The three constraints above are
kept in the appendix for the change that would one day need them.

## 3. Cost, measured

### What was measured, and how

**The web.** Chromium 156.0.8078.4 (Playwright, headless), 1440×900, macOS arm64. One page,
built to the consumer's case: a 48 px sticky header, a 144 px sticky toolbar, a 100 px hero,
a 24 px gutter, a grid of result cards and a panel that takes the rest of the window. Five
variants of the same page — nothing scroll-driven, a paint-only fold on the hero
(`opacity` + `transform` under `animation-timeline: view()`), the panel's height animated
under `animation-timeline: scroll(root)` (`css`), the panel's height written by a scroll
listener (`js`), and a box that grows on entry so the *document height* changes
(`hero-layout`) — plus a box whose height is derived from its own exit (`self`).

Each run: a 90-frame scroll at 4× CPU throttling (`Emulation.setCPUThrottlingRate`), at
1.1 px a frame so that a 100 px fold range stays live on every frame, with Blink's own trace
events
(`UpdateLayoutTree`, `Layout`, `Paint`, `PrePaint`, `Layerize`, `EventDispatch`) summed and
divided by the frames committed. These are main-thread milliseconds per frame — what the
DevTools performance panel would show, aggregated.

### The numbers

Main-thread work per frame, 4× CPU throttle, 90 frames of scrolling:

| Page | Layout events | Layout | Style | Paint | Total main thread | Frames over 33 ms |
| --- | --- | --- | --- | --- | --- | --- |
| nothing scroll-driven, 24 cards | 0 | 0 | 0 | 0 | 0.40 ms | 0 |
| paint-only fold, 24 cards | 0 | 0 | 0.031 ms | 0 | 0.50 ms | 0 |
| paint-only fold, 2000 cards | 0 | 0 | 0.010 ms | 0 | 0.32 ms | 0 |
| panel height from the scroll timeline, 24 cards | 89 | 0.061 ms | 0.036 ms | 0.096 ms | 0.38 ms | 0 |
| panel height from the scroll timeline, 400 cards | 89 | 0.195 ms | 0.148 ms | 0.216 ms | 1.22 ms | 0 |
| panel height from the scroll timeline, 2000 cards | 89 | 0.180 ms | 0.108 ms | 0.468 ms | 1.64 ms | 0 |
| panel height from a scroll listener, 400 cards | 89 | 0.062 ms | 0.037 ms | 0.160 ms | 0.95 ms | 0 |
| a box that grows on entry, so the document height changes, 400 cards | 182 | 0.126 ms | 0.130 ms | 0.462 ms | 2.03 ms | 0 |

Four facts are worth taking out of that table.

1. **A paint-only fold costs the main thread nothing on the web.** Zero `Layout` and zero
   `Paint` events across the whole scroll: Blink runs the `view()` animation on the
   compositor. The rule's guarantee here is real and it is the strongest thing the rule buys.
2. **A layout the scroll derives costs one layout per frame** — 89 `Layout` events in 103
   frames, because the run crosses the fold's 100 px range a pixel at a time and the animation
   is therefore live on every frame — and it is *cheap*: 0.06 ms/frame at 24 cards at 4×,
   0.20 ms/frame at 400, 0.18 ms at 2000. The frame budget holds with two orders of magnitude
   to spare: no run in the matrix dropped a frame over 33 ms.
3. **The cost does not scale with the page.** 400 cards and 2000 cards cost the same layout
   time, because the panel's height changes the flex line's height and not the grid's
   constraints, so Blink skips the grid's subtree. This is exactly the shape the consumer's
   case has: the panel is beside the results, and the column's height is set by the grid.
4. **The cost doubles when the change reflows the page.** The `hero-layout` case, where the
   animated box changes the document's height, runs `Layout` twice per frame (182 in 103) and
   paints five times as much (0.462 ms against 0.096 ms). That is the shape to refuse, not
   the consumer's.

### What a height reflows: nothing, and what a width reflows: a line

The parity question is not "does a layout move" but "does a *width* move", and two measurements
say why.

A panel stepped from 584 px to 684 px, holding a 137-character paragraph and beside a grid of
cards: every child's `x`, width and line box is **identical** at both heights
(`sameWidthsAndLineBoxes: true`), and the document's scroll height does not change either. A
height moves content down the page and changes nothing about how it is laid out, because text
measures against width.

The same paragraph over a 100 px **width** sweep, Arial 16 px, line height 1.4:

| Sweep | Samples | Line-count changes |
| --- | --- | --- |
| 373 → 473 px, 1 px steps | 101 | 1, at 390 px (89.56 px → 67.17 px: four lines become three) |
| 373 → 473 px, 0.25 px steps | 401 | 1, the same one |

So a width fold buys one or two widths per 100 px of range at which the two text stacks must
agree to the pixel, and where a disagreement is a whole line — 22.4 px of reflow and everything
below it — rather than a rounding. One threshold in a hundred widths sounds small until it is a
range: a static tree is checked at the widths it states, and a fold is a hundred states, none of
which is in the table.

These two sweeps are Chromium's thresholds for one font and one paragraph. The thresholds
Flutter's text stack has are not measured here, because the test harness lays text out in its own
monospaced test font, which is not comparable to a browser with Arial loaded; the comparison needs
the same font file in both, which means a Flutter web build or a device. What the sweeps establish
is only the shape of the risk — a step function with one threshold per ~100 px of width — and
that a height contributes none.

### Flutter

`flutter test` on the same machine: a 375×800 scrolling viewport holding a hero, 200 listing
rows (each a `Box` with a `TextNode`, so text layout is in the loop) and a panel, driven by
120 scroll ticks of 8 px, with every render object inspected between the tick and the frame:
`debugNeedsLayout` and `debugNeedsPaint` count the invalidation the tick caused, and the pump
is timed. The scroll-derived height is a `RenderProxyBox` that answers a scroll tick with
`markNeedsLayout()` and sizes itself from `position.pixels` — the shape a layout-permitting
renderer would have, in the place `_RenderFoldedBox` sits today. The rebuild variant is the
documented alternative: a widget that listens to the `ScrollPosition` and rebuilds the whole
column with the new height.

| Variant | Marked for layout per tick | Marked for paint | Pump time per frame |
| --- | --- | --- | --- |
| nothing scroll-driven | 0 of 2049 | 1 | 0.81 ms |
| paint-only fold (`BoxFold`) | 0 of 2049 | 8 | 0.84 ms |
| height derived from the scroll | 3 of 2050 | 1 | 0.90 ms |
| height derived, with a width-threshold child (`LayoutBuilder`) | 3 of 2068 | 1 | 0.85 ms |
| rebuilt from host state per tick | 0 of 2050 | 1 | 0.93 ms |

At 600 rows the same five are 3.17, 3.15, 2.64, 2.62 and 2.60 ms — the rows dominate, and
the mechanism disappears into the noise.

Three things to take out of this.

1. **The ripple is a chain, not a fan-out.** Three render objects are marked: the derived box,
   the flex that holds it, and the viewport child that is the nearest relayout boundary.
   `RenderFlex` does not lay a child out again whose constraints and layout state are
   unchanged, so none of the 200 rows is relaid out — 0.00 row layouts per tick, measured
   directly on a counting proxy. "The column relayouts on every frame" is not what Flutter
   does; what it does is walk the flex's child list, which is 200 cheap early-outs.
2. **`LayoutBuilder` makes it neither better nor worse here.** The `_holdsThreshold` wrapper
   (`box.dart:203-213`, `:1358-1363`) is a relayout boundary, so the ripple stops at it
   instead of passing through it — but its builder re-runs only when its constraints change,
   and they do not. It would make it worse in the case the model should refuse: a derived box
   *above* the `LayoutBuilder`, whose size change reaches the builder's constraints and
   rebuilds the subtree under them on every frame.
3. **The rebuild the docs recommend is not cheaper.** 0.93 ms against 0.90 ms, with every node
   in the tree rebuilt; and the example's collapsing app bar, which is the worked reference
   (`example/unibox_example_shared/lib/src/site/gallery.dart:890-939`), also changes
   `padding` and `fontSize` per tick, so it re-measures text as well.

### What these numbers are not

Not a phone. The web numbers are a desktop-class arm64 core under a 4× throttle, which is a
reasonable stand-in for a mid-range Android main thread and not a measurement of one; the
Flutter numbers are a debug-mode VM in the test harness, where a pump also builds and paints
a whole frame, so they compare variants with each other and not with a device. A scroll
driven from JavaScript is also not a fling: the scroll itself then runs on the main thread,
which is why the busy-main-thread runs in this pass were discarded rather than quoted. The
measurement a renderer change would want before it lands:

- `flutter drive --profile` on a mid-range device (a Pixel 4a, a Galaxy A54), streaming
  `SchedulerBinding.addTimingsCallback` build and raster durations over 300 frames per
  variant, with the scroll driven by a real drag rather than `jumpTo`;
- the same harness with a `RepaintBoundary` between the derived box and the rows — the case
  where a paint-only tree stops paying for a full-viewport repaint each frame and the
  layout's three objects stand alone;
- an Android Chrome trace of the consumer's page at 4× and 6× throttling, to find where the
  1.6 ms/frame at 2000 cards becomes a dropped frame.

## 4. Feedback: the box that resizes the range it reads

Measured, on the page above, with a box whose height is derived from its own exit from the
viewport (`height: 100px → 500px` over `entry 0% → exit 100%`), holding the scroll still at a
fixed offset and sampling the box's height every frame:

| Offset | First frame | Second | Third | Settles at | Document height changed |
| --- | --- | --- | --- | --- | --- |
| 300 px | 400 px | 384 px | 383 px | 383 px, from frame 3 | 3 times |
| 600 px | 499 px | 459 px | 456 px | 456 px, from frame 3 | 3 times |
| jumped to 300 px from 900 px | 359 px | 382 px | 383 px | 383 px, from frame 3 | 3 times |

So: **no runaway, no path dependence, and a visible transient.** The loop converges in two
frames to the same fixed point whether it is approached from above or below, which is the good
news; but it is a fixed point, not a function — the frame after a jump is up to 43 px from the
value it settles at (499 → 459 → 456 at 600 px), and a link that lands mid-page (`#anchor`, a
restored scroll, a deep link) shows that jump. The same loop on the main thread — a scroll
listener reading `getBoundingClientRect` and writing the height — was stable on its first frame,
because the handler reads the box after the layout it caused.

**What the model should require.** Not "the document height may not change": that is a
property of a page, not of a box, and it is not what makes the loop stable. The requirement is
local and checkable: *the box a fold resizes may not be the box the fold's range is measured
on.* In the consumer's case the panel resizes and the **hero's** exit is the driver, so the
range is fixed by the tree's own geometry and the derived value is a function of the offset
rather than a fixed point of itself. That condition is why the construct the case needs is a
fold with a *named* driver, not a layout token added to today's `BoxFold`.

A second requirement falls out of the same measurement: the derived size may not change the
scroll extent of the box that scrolls it. In the consumer's case the column's height is set by
the results grid, so the panel's growth changes neither the document's height nor the scroll
range — and the measurement says the cost stays at one layout per frame (§3, "the cost does not
scale"), while the `hero-layout` row shows what happens when it does not hold: two layouts per
frame and five times the paint. Express it as a check on the driver, not on the result: a box
whose derived size is measured by the same scroll it is drawn in is refused, and a derived size
laid out through `LayoutBuilder`, a grid cell or an `IntrinsicWidth` is refused too, because
the first rebuilds a subtree per frame and the second re-measures text per frame through the
intrinsic passes.

## 5. Degradation: what a browser without timelines, a crawler and a reader see

**The claim in the repository is wrong, and this is measurable.** `foldDeclarations` says that
"a browser that does not know [the duration] falls back to `0s` and paints the resting look
rather than a broken one" (`packages/unibox_html/lib/src/css/values.dart:250-252`), and the README
repeats it (`README.md:666-668`). The duration does fall back to `0s`; the resting look does
not follow. `animation-fill-mode: both` fills *forwards*, so a zero-length animation sits at
its last frame — the *folded* look.

Measured on the repository's own output: a document emitted by `toDocument` for a hero with
`fold: BoxFold(to: BoxStyle(opacity: 0))`, loaded in Chromium with the timeline removed
(`animation-timeline: none`, which is what an engine that does not know `view()` leaves
behind, and equivalently `animation-duration: 0s` where `auto` is not understood):

| | `animation-duration` | `animation-timeline` | Computed opacity |
| --- | --- | --- | --- |
| as emitted, timeline understood | `auto` | `view()` | 0.135 at scroll 0 — the first defect at the end of this note |
| timeline not understood | `auto` → `0s` | none | **0** |
| duration not understood either | `0s` | none | **0** |

A hero whose fold ends at `opacity: 0` is therefore **invisible** on a browser without
scroll-driven animations, not at rest. That is a live defect with nothing to do with this
decision, and it also disposes of the guarantee: the rule is not currently buying graceful
degradation for anything.

For a *layout* fold the same fallback would serve the folded geometry — for the consumer's
panel, the 584 px panel at every offset, i.e. a page permanently 100 px short. That is arguably
the least-bad static answer (it is the page at rest, which is what a crawler wants), but it is
not the resting look, and it has to be written down rather than inherited. The fix for both is
the same and it is one shape: guard the fold's declarations with
`@supports (animation-timeline: view())`, so a browser that cannot drive it writes no animation
at all and paints the resting look, which is the claim the documents already make.

**A crawler and a reader with no script** see the resting look either way, because a fold is a
document's own CSS: nothing about a fold needs JavaScript, and that is the property that makes
the construct worth having at all. A layout the *store* drives has no such property — with no
script the document shows whatever state the tree was rendered in, so the consumer's panel
would sit at a static number until Flutter or `unibox_dom` takes the page over. That asymmetry
is the strongest argument for the construct, and it is the reason the old site shipped the
`--catalog-map-visible-top` script: without a declarative construct, the document cannot do it.

**Flutter with no scrollable above the box** keeps the resting look, and it does so by not
building the fold at all: `foldedAt` is `null` when `Scrollable.maybeOf` finds nothing
(`packages/unibox_flutter/lib/src/box.dart:202-209`), so the box is drawn by the ordinary path.
That is right for a look and would be right for a layout too — a derived height with no driver
has no input, and the resting value is the only answer that is not a guess.

## 6. What replaces the sentence

The ban stays whole, so the documents have two jobs: stop repeating the two claims of §5 that are
false, and replace "move the layout with a state instead" with something a consumer can act on.

### `packages/unibox_core/lib/src/tokens/box_fold.dart`

> It is paint only, and the reason is narrower than the paragraph above used to say. A fold has
> no duration: the scroll is the clock, and the reader decides where it stops, so every offset is
> a state they can hold and look at rather than a frame that flashes past. Two things follow. A
> width would walk the box's text across the widths where a line breaks, and at one of those
> widths a browser and Flutter need not agree — by a line, not by a pixel. And a size cannot be
> named here anyway: the tree can say "the window less 216" and it can say nothing about what the
> hero still takes up — and a fold reads *its own* box's exit, so a fold that resized that box
> would be reading a range it moves.
>
> A height that follows the reader is therefore not a fold. It is a store: `onScroll` reports
> the offset, a `StateStore` keeps it, and the view is drawn again with the next number. That is
> a number rather than a tween, it is the same on both targets, and it has a price the reader can
> see — a served document cannot do it, so the box keeps the height the tree gave it until the
> application takes the page over. A fold, by contrast, works before anything is loaded.

### `packages/unibox_core/lib/src/validation.dart`

The comment above the block:

> A fold is a look that arrives as the box leaves its viewport, so it may only name the looks a
> box paints. A fold has no duration — the scroll is the clock and the reader holds it where they
> like — so a width it moved would land on the widths where a line breaks, and a size it moved is
> one the tree can only state as a number. A size that follows the scroll is a store and a rebuild,
> which `CollapsingAppBarDemo` in the example demonstrates; a served document cannot move that
> way, and that is the trade this rule makes.

The message a consumer is shown:

> A fold names ${moves.join(', ')}, and a fold may only name a look: the background, the border
> colour, the corner radius, the shadows, the opacity and the transform. A fold is driven by the
> scroll, not by a clock, so a width it moved would land on the widths where a line breaks, and a
> size it moved is one the tree can only state as a number. If the box's height should follow
> the reader, state
> it from a store: `onScroll` reports the offset, a `StateStore` keeps it, and the view states the
> next number — `CollapsingAppBarDemo` in the example is the worked case. Note that it moves once
> the application has taken the page over; a served document shows the resting height until then.

### `packages/unibox_flutter/README.md` (`:56`, `:126-133`)

> A **fold** is drawn the same way: a `_RenderFoldedBox` reads how far the box has left its
> viewport when it paints and interpolates the decoration, the opacity and the transform there,
> so a scroll costs a repaint of one layer — nothing is rebuilt, and nothing is laid out again.
> That is why a fold may only name paint: it has no duration, the reader decides where the scroll
> stops, so a size it moved would be a size at an offset nobody stated, and the two targets would
> have to agree at every one of them.
>
> A band whose **height** follows the reader is a store and a rebuild instead — `onScroll` into a
> `StateStore`, the view stating the next number. `MaterialLargeAppBar` records why Material's
> collapsing bar is that and not a fold. On the web the difference is when it starts: the served
> document shows the resting height, and the height begins to follow the scroll when the
> application takes the page over.

### `README.md` §motion (`:627-684`) and `packages/unibox_html/README.md`

> It is paint only, and that is what lets the two renderings be the same page: the web
> interpolates two keyframes it was served, on the compositor, where a busy main thread cannot
> stall it; Flutter repaints one layer. Nothing below the box moves, and nothing is laid out
> again while it runs.
>
> A height that follows the reader is not a fold; it is a store the view reads — `onScroll` into
> a `StateStore`, and the next number drawn. It is the one thing on this page a *served* document
> cannot do, because it needs the application to be running. Everything else about a fold works
> with no script at all, which is why the restriction is worth having.
>
> A browser without scroll-driven animations keeps the resting look, and the sheet makes that
> true rather than hoping for it: a fold's declarations are guarded by
> `@supports (animation-timeline: view())`, so a browser that cannot drive the animation writes
> no animation at all instead of a zero-second one frozen on its last frame.

## 7. What the decision costs, and what guards it

**The cost, plainly.** A reader who never lets the application start — no JavaScript, a crawler,
someone who reads and leaves — sees the resting layout: in the measured case a panel 584 px tall
where the application would make it 684 px. That is a cosmetic loss, not a content loss, and it
is the price of not widening the model.

**The asymmetry has to be written down, in the places this repository writes the others.** Both
renderer READMEs keep a "what stays approximate" section beside the pin and `srcSet` entries
(`AGENTS.md` §D calls an undocumented difference a bug); a scroll-driven size belongs there, with
one sentence each: the document keeps the resting layout, and the application moves it.

**No validator change is needed, and that is the point.** The ban is unchanged, so the guard is
not a new rule but three existing things held to: the store route stays the documented answer and
keeps its test (`example/unibox_example_flutter/test/collapsing_app_bar_test.dart`, which asserts
the bar's height changes as the body scrolls), the example stays the reference an author copies,
and the two defects below are fixed — because this decision leans on the *resting* state being
right, which is exactly what defect 1 gets wrong.

**What would reopen it.** One concrete requirement for a *served* page to resize without
JavaScript. Then the appendix below is the shape, not a debate.

## Decision

**Keep the ban, as written, and stop describing it as temporary.**

A scroll changes how a page looks; it changes a page's layout through the application's state.
That is the rule, it is not waiting on a follow-up, and a client that wants a size to follow the
scroll ships JavaScript — the Flutter build it already has, or `unibox_dom` — and drives it from
`onScroll`.

Four reasons, in the order that decided it:

1. **The permission would be inert on its own.** Half the case is already expressible and the
   other half is not: `BoxFraction.viewport(1, minus: 316)` gives the resting height on both
   targets, so the panel can be written correctly before the reader scrolls, while no token can
   say which number applies as the hero leaves — a fold reads its own box's exit, not another
   box's (§2). Deleting the error would legalise exactly one shape, a box resizing the range it
   reads, which is the shape measured to settle over three frames and to jump when a reader lands
   mid-page (§4).
2. **The application already does it, at the same measured cost.** `onScroll` into a store and a
   rebuild costs 0.93 ms a frame on Flutter against 0.90 ms for a derived size, and on the web
   0.95 ms against 1.22 ms for the declarative route (§3). Nobody buys anything by moving it into
   CSS.
3. **A crawler never scrolls.** Nothing this project exists for — indexable text, real headings and
   links, a preview that renders — improves by a panel resizing itself on a scroll nobody performs.
   The page at rest is a valid page, and it is the page a crawler should see.
4. **One mechanism instead of two.** The model keeps one way to say "a layout follows the scroll",
   so there is one thing to test and one place to look. The alternative — a fold that resizes plus
   a store that resizes — is the drift between two implementations that produced the range defect
   in §5.

### The trade, stated once

A served document will show the resting layout for anything that follows the scroll with its size.
That is a deliberate choice of a smaller model over a finished page for that one behaviour. It is
acceptable here because the behaviour is an *interaction*, not content: a reader meets the page,
then the reader scrolls, and by then the application is running. It is worth revisiting only if a
page must be complete — layout included — for a reader who never runs JavaScript.

### The alternative rejected: lift it for heights now

It is sound on the merits — a height does not re-wrap text (§3), so nothing about the picture is at
risk — and it is rejected for scope, not for correctness: it would add a size token, a cross-box
driver, a validator rule set and two renderer paths to buy a behaviour a store already provides,
before anyone has asked for the served-page version. The sketch is kept in the appendix so the next
reader does not have to re-derive it.

## The two defects, which are the only code this note asks for

This decision leans on the resting state being right — it is the state a crawler sees, the state
the page shows before anything scrolls, and the state the reader is looking at when the application
boots. Both defects are about that state, and both are live.

1. **A fold's range is the wrong range on the web.** `foldDeclarations` writes `animation-range`
   only when `over < 1` (`packages/unibox_html/lib/src/css/values.dart:265-268`), so the default fold
   runs over `view()`'s whole cover range — entering *and* leaving — while `_progress` and
   `BoxFold.progressAt` measure the exit alone. Measured on the emitted document: a 100 px hero at
   the top of a page reads `opacity: 0.135` at scroll 0 in Chromium and `1` in Flutter, which its
   own suite pins (`packages/unibox_flutter/test/fold_widget_test.dart:45-58`). With
   `over: 0.999` the browser matches Flutter at every offset tested. The omission is not something
   the suite could have caught by accident: it is pinned, by a test that asserts the default fold
   writes no `animation-range` at all (`packages/unibox_html/test/css_nodes_test.dart:225`). The
   fix is to write `exit 0% exit ${over * 100}%` unconditionally, and to flip that assertion.
2. **A browser without scroll timelines paints the folded look, not the resting one.** Measured in
   §5: `0s` with `animation-fill-mode: both` fills forwards, so a fold ending at `opacity: 0` is
   invisible, and two documents say the opposite. The fix is
   `@supports (animation-timeline: view())` around the fold's declarations, in
   `packages/unibox_html/lib/src/element/stylesheet.dart`.

With the ban kept, this decision makes the document's scroll behaviour depend entirely on CSS
scroll-driven animations — the newest thing in the stack. That is one more reason the `@supports`
guard is not optional: without it, a browser that cannot drive a fold paints a page with its heroes
invisible, and a reader would be right to call that broken.

## Appendix — if a served page ever has to resize without JavaScript

Kept for the record, so a future decision does not start from nothing. None of it is in scope now.

The rule would split by axis rather than by "layout":

- `height`, `minHeight`, `maxHeight`, vertical `padding` and `margin` — allowed, because a height
  does not re-wrap text (§3).
- `width`, `widthFraction`, horizontal `padding` and `margin`, `gap`, `mainAlign`, `crossAlign`,
  `direction`, `wrap`, `flex`, `gridSpan`, `aspectRatio` — still refused, because a width walks the
  box's text across the widths where a line breaks, and because two layout engines distribute free
  space by different rules.
- A size that changes on a **clock** rather than a position — still refused, for a third reason: a
  fold has no start to synchronise, a timed animation has one, and a browser cannot ease from a
  content-sized height at all.

What the model would need: the size exists (`BoxFraction.viewport(1, minus: 316)` already resolves
to `calc(100dvh - 316px)` on both targets), so the missing piece is the driver — a fold whose range
belongs to *another* box's exit, because the panel does not leave the screen, the hero does — and
with it the `minus` becomes a function of that exit rather than a constant.
Then the order this repository uses: the token and the validator first (a `driver`, the axis split,
and the rule that the resized box may not be the box providing the range), the renderers second,
and two tests that matter — the resting state on both targets, and one intermediate offset on both.

## What this pass did not do

No file in `packages/`, `example/` or `tool/` was changed, and no version or changelog entry was
touched: this note asks for two CSS fixes and some prose, not for a change to the model. The
measurements were taken with a throwaway Playwright harness in `/tmp` and a throwaway `flutter test`
file in the package's `test/` directory, both removed; `git status` holds this note and one line in
`llms.txt` and nothing else. Nothing was run against a physical device, and §3 records what that
measurement would need.

