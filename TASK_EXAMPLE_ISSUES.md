# Example issues

Five problems reported against the example page, with the diagnosis and the plan for
each. They are worked one at a time, each with its own commit and its own push, so a
review can stop after any of them.

The page they are about is `example/unibox_example_shared/lib/src/apartments.dart` and
the design system it leans on is `packages/unibox_material`.

- [ ] **1. The card layout is wrong on the web, right in Flutter.**

  The name row and the price row are `mainAlign: spaceBetween` with
  `width: double.infinity`, and the price and the badge do not reach the right edge of
  the card in the browser — they sit next to the text instead. Both rows hug their
  content instead of spanning the card.

  Likely cause: `width: double.infinity` is written as `width: 100%`, and a percentage
  inside a parent whose width is itself shrink-to-fit resolves to `auto` in CSS, while
  Flutter's `SizedBox(width: infinite)` takes the incoming constraint. To confirm by
  measuring the rendered widths, then fix where the model is wrong — a stretch that one
  target applies and the other does not is the drift this repository exists to prevent.

- [ ] **2. Cards do not share one shadow.**

  The example's cards draw different elevations. `MaterialCard` defaults to the level
  one shade while the listing card is a card with a photo, and nothing states one
  elevation for both. Fix in the design system if the default is wrong, in the example
  if the default is right and the page overrides it.

- [ ] **3. A hovered chip's ink well goes far beyond the chip.**

  `_chip` wraps a `MaterialInkWell` around a box that carries the pill's padding and
  radius, so the well is bigger than the pill it belongs to and its tint spills past the
  shape on hover. There is no chip in `unibox_material`: add `MaterialChip` (M3 filter
  chip: label, optional leading icon, selected state, 32 pixel height, radius 8) so the
  example states a chip instead of composing one.

- [ ] **4. There is no segmented button.**

  Add `MaterialSegmentedButton` to `unibox_material`, respecting M3: a set of segments
  in one outlined container, the selected one filled, dividers between them, a 40 pixel
  height and the button role per segment.

- [ ] **5. The map button cannot float at the bottom centre.**

  A floating action over the page needs a position the model cannot state: `Box` lays
  out in the flow and `PositionedNode` places a child inside a `StackNode` at exact
  offsets. A button pinned to the bottom centre of the surface needs an alignment in the
  stack (or a placement token) that both renderers honour — a core change, then the
  example uses it.
