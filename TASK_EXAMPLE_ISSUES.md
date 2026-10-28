# Example issues

Five problems reported against the example page, with the diagnosis and the plan for
each. They are worked one at a time, each with its own commit and its own push, so a
review can stop after any of them.

The page they are about is `example/unibox_example_shared/lib/src/apartments.dart` and
the design system it leans on is `packages/unibox_material`.

- [x] **1. The card layout is wrong on the web, right in Flutter.** *Done.*

  Cause confirmed by measuring the rendered page: the card's content column hugged
  its content (177 pixels of a 352 pixel card), so the rows' `width: 100%` resolved
  against that. `MaterialCard` now defaults to `crossAlign: CrossAlign.stretch`, which
  is the model's way to say "my children fill my width" and what Material's own card
  does; the gallery's sections stretch too, because a section's blocks fill it. The
  card's rows now end at 352 and the price at its right edge, checked in Chromium and
  pinned by a Flutter test that measures it.

  The name row and the price row are `mainAlign: spaceBetween` with
  `width: double.infinity`, and the price and the badge do not reach the right edge of
  the card in the browser — they sit next to the text instead. Both rows hug their
  content instead of spanning the card.

  Likely cause: `width: double.infinity` is written as `width: 100%`, and a percentage
  inside a parent whose width is itself shrink-to-fit resolves to `auto` in CSS, while
  Flutter's `SizedBox(width: infinite)` takes the incoming constraint. To confirm by
  measuring the rendered widths, then fix where the model is wrong — a stretch that one
  target applies and the other does not is the drift this repository exists to prevent.

- [x] **2. Cards do not share one shadow.** *Done.*

  Measured first: the four listing cards carried the same `box-shadow` on the web
  (`0 1px 3px` at 15%), so the difference was elsewhere — the dialog's own surface
  wrote a fourth shadow of its own (`0 12px 32px` at 8%) while the package already
  held three near-copies (card, dialog, sheet). `MaterialElevation` is now the one
  place a shadow is written, the three components read it by level, and the example's
  dialog uses `MaterialDialog.elevation` instead of a literal.

  The example's cards draw different elevations. `MaterialCard` defaults to the level
  one shade while the listing card is a card with a photo, and nothing states one
  elevation for both. Fix in the design system if the default is wrong, in the example
  if the default is right and the page overrides it.

- [x] **3. A hovered chip's ink well goes far beyond the chip.** *Done.*

  The cause was two paddings: the well carried 14/8 of room and a box inside it carried
  another 14/8, so the tint was a whole pill bigger than the pill. `MaterialChip` states
  the room once, in the well, and clips to the small 8 pixel shape; the filter row is a
  chip and nothing else. Measured in Chromium: the hover tint and the pill are both 75
  by 32 at radius 8. The palette also grew the four `secondary` roles, because a chosen
  control in Material 3 fills with the secondary container.

  `_chip` wraps a `MaterialInkWell` around a box that carries the pill's padding and
  radius, so the well is bigger than the pill it belongs to and its tint spills past the
  shape on hover. There is no chip in `unibox_material`: add `MaterialChip` (M3 filter
  chip: label, optional leading icon, selected state, 32 pixel height, radius 8) so the
  example states a chip instead of composing one.

- [x] **4. There is no segmented button.** *Done.*

  `MaterialSegmentedButton`: 40 pixels tall at radius 20, a 1 pixel outline around and
  between the segments, equal shares, the chosen one filled with `secondaryContainer`
  and announced as selected. It also needed `MaterialInkWell` to place its content and
  stretch its stack, because a segment is filled by its tint and not hugged by it. The
  gallery has a stateful demo, and pressing a segment moves the choice — checked in
  Chromium before and after the press.

  Add `MaterialSegmentedButton` to `unibox_material`, respecting M3: a set of segments
  in one outlined container, the selected one filled, dividers between them, a 40 pixel
  height and the button role per segment.

- [x] **5. The map button cannot float at the bottom centre.** *Done.*

  `PositionedNode` takes an `alignment` now: the child fills the stack and `BoxAlignment`
  places it, so a control sits at the bottom centre of any surface without measuring a
  window. Flutter draws it as `Positioned.fill` around an `Align`, the web as `inset: 0`
  with a `justify-content`/`align-items` pair, `validateTree` reports an alignment and
  an offset on one node, and the listings page floats its Map button over the list.

  Reaching that turned up two things underneath: the page had to become a stack so the
  list scrolls *under* the button, and a CSS flex item keeps its content as an automatic
  minimum, so a page of 1953 pixels of listings refused to shrink while the same tree
  filled a Flutter window. A box that states `flex` now writes `min-width: 0` and
  `min-height: 0`, which is what `Expanded` means. Measured in Chromium at 420 by 820:
  the button is 24 pixels from the bottom, centred, and does not move when the list
  scrolls.

  A floating action over the page needs a position the model cannot state: `Box` lays
  out in the flow and `PositionedNode` places a child inside a `StackNode` at exact
  offsets. A button pinned to the bottom centre of the surface needs an alignment in the
  stack (or a placement token) that both renderers honour — a core change, then the
  example uses it.
