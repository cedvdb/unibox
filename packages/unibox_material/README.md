# unibox_material

Material Design 3 for Unibox: the type scale, the colour roles and the components
built from them.

This package is pure Dart: it depends on `unibox_core` for the tokens and on
`material_color_utilities` for Material's colour algorithm — no Flutter, no
`dart:ui`, no Material widget library. It does
not import Flutter, `dart:ui` or Material, so the same scale is available to a
Flutter app, a web page and a command line tool that only builds a tree.

## Why a package

Material's type scale is a set of numbers, and numbers are exactly what the model
already knows how to carry: a role is a `BoxTextStyle`, which both renderers draw
the same way. The alternative — `Theme.of(context).textTheme` on one side and a
CSS class on the other — would put the type scale in each host and let them drift,
which is the drift the workspace exists to remove.

Keeping it out of `unibox_core` is deliberate too. The core is neutral about
design systems: it has a default (16 pixels, 1.5 line height) but no opinion about
Roboto, `onSurface` or elevation. Material is one opinion, and it can be replaced
without touching a single node.

## Usage

```dart
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

const card = Box(
  padding: BoxSpacing.all(16),
  borderRadius: 12,
  backgroundColor: BoxColor.white,
  // Installed once: every text inside inherits it.
  textStyle: MaterialTypography.bodyMedium,
  children: <UINode>[
    TextNode('Order summary', style: MaterialTypography.titleLarge),
    TextNode('Two nights, one room.'),
    TextNode('Total', style: MaterialTypography.labelLarge),
  ],
);
```

Typography is the one inherited axis of the model, so a page states the role of an
area once and the texts inside only say what makes them different. A role that a
text node sets itself wins over the box above it, exactly like every other style
token.

## The scale

| Role | Size | Line box | Tracking | Weight | Used for |
| --- | --- | --- | --- | --- | --- |
| `displayLarge` | 57 | 64 | -0.25 | 400 | a hero number or a display line |
| `displayMedium` | 45 | 52 | 0 | 400 | a display line, one step down |
| `displaySmall` | 36 | 44 | 0 | 400 | the smallest display line |
| `headlineLarge` | 32 | 40 | 0 | 400 | the title of a short page |
| `headlineMedium` | 28 | 36 | 0 | 400 | a section heading |
| `headlineSmall` | 24 | 32 | 0 | 400 | a heading inside a page |
| `titleLarge` | 22 | 28 | 0 | 400 | the title of a card or a dialog |
| `titleMedium` | 16 | 24 | 0.15 | 500 | a title for a smaller region |
| `titleSmall` | 14 | 20 | 0.1 | 500 | a dense row or a leading label |
| `bodyLarge` | 16 | 24 | 0.5 | 400 | the long form text of a page |
| `bodyMedium` | 14 | 20 | 0.25 | 400 | the default body text |
| `bodySmall` | 12 | 16 | 0.4 | 400 | a caption or a hint |
| `labelLarge` | 14 | 20 | 0.1 | 500 | a button or another control |
| `labelMedium` | 12 | 16 | 0.5 | 500 | a label, one step down |
| `labelSmall` | 11 | 16 | 0.5 | 500 | a dense control or a badge |

Size and line box are logical pixels (`px` on the web), tracking is extra space
between characters in the same unit, and the weight is the nearest of the four
weights the model has (`normal` 400, `medium` 500) — Material's scale only uses
those two, so nothing is approximated.

The same values are available as a table for code that walks the scale:

```dart
for (final role in MaterialTypeRole.values) {
  final style = MaterialTypography.of(role);
  // ...
}
```

`MaterialTypography.styles` is that table, keyed by `MaterialTypeRole` and ordered
like `MaterialTypeRole.values`, from `displayLarge` to `labelSmall`.

## What a role states, and what it leaves out

A role is a **complete** look: size, weight, tracking and line height are all
written down. That is what makes it safe to nest — a `titleMedium` inside a bold
heading keeps its 500 weight instead of inheriting the bold, because the role
states the weight rather than leaving it `null`.

Two tokens stay unset on purpose:

- **`color`** is Material's `onSurface` (and `onSurfaceVariant`, `primary`, ...),
  which belongs to the colour scheme and to the box that installs it. Every role
  inherits the colour of the text around it, so one scale serves a light theme, a
  dark theme and a coloured button:

  ```dart
  Box(
    backgroundColor: BoxColor.rgb(0x2D, 0x6C, 0xF3),
    // The role keeps its geometry and takes the colour of the theme.
    textStyle: MaterialTypography.labelLarge.merge(
      const BoxTextStyle(color: BoxColor.white),
    ),
    children: <UINode>[TextNode('Continue')],
  )
  ```

- **`fontFamily`** is an asset of the application, not of the scale. Unset means
  the platform's UI font on both targets; an app that ships Roboto declares it on
  the box at the root of the tree, or merges it into the roles it uses.

## Presets: values, not classes

The roles above are the whole vocabulary, so a screen usually installs one on a
box and only overrides what differs:

```dart
const Box(
  textStyle: MaterialTypography.bodyMedium,
  children: <UINode>[
    TextNode('Order summary', style: MaterialTypography.titleLarge),
    TextNode('Two nights, one room.'),
  ],
);
```

When a product needs its own names, those names belong to the product: a class of
`const` values, not a node type per role. The example does exactly this with its
`ExampleType`:

```dart
abstract final class AppType {
  static const BoxTextStyle body = MaterialTypography.bodyMedium;
  static const BoxTextStyle cardTitle = MaterialTypography.titleMedium;
  static const BoxTextStyle price = MaterialTypography.labelLarge;
}

const card = Box(
  textStyle: AppType.body, // every text inside inherits it
  children: <UINode>[
    TextNode('Order summary', style: AppType.cardTitle),
    TextNode('EUR 120', style: AppType.price, color: BoxColor.white),
  ],
);
```

A `TitleText` class would be four lines, not forty — `TextNode` takes the whole
look as one `style` field, so a preset repeats no typography token:

```dart
final class TitleText extends TextNode {
  const TitleText(super.text, {super.key, super.headingLevel})
    : super(style: MaterialTypography.titleLarge);
}
```

It is still the wrong default for a shared package, and this one does not export
one:

- **It bakes a look into a type.** The tree has no context, so `TitleText` cannot
  read a theme: a dark theme or a brand font can only change it by changing the
  class, while `MaterialTypography.titleLarge.merge(...)` changes per call.
- **It names a look like a structure.** `headingLevel` is the document level and
  typography is the look; a class called `TitleText` invites hardcoding one or
  forgetting the other, and a card title is not a heading at all.
- **It costs a second vocabulary.** `titleLarge` already means what Material
  means by it; `TitleText.medium` has to be mapped onto `titleMedium` or
  `titleSmall` and kept in step.
- **It widens a small contract.** Subclassing a node works today only because the
  renderers match a node by subtype, and this package leans on that once — for the
  card below. A promise made once, for a node that *is* a box, is a design
  decision; fifteen text presets would turn it into a habit.

The line is between a look and a component. A look has no children, so it is a
value, and a value can be themed by merging a token. A component owns children and
a surface that have to travel together, so it is a node — built by extending the
node that already draws it, which is why `MaterialCard` needs no renderer and no
conformance case. A `TitleText` is the first kind pretending to be the second.

Keep those four lines in the application that wants them. The package exports
three names, and the day a preset needs a theme token it is a `BoxTextStyle`
again.

## The palette and the theme

`MaterialPalette` is the colour half of the design system: the Material 3 roles as
`const` `BoxColor` values, with a light and a dark instance. `MaterialColorRole` is
the vocabulary the components name, and a palette turns it into a theme:

```dart
// what a component says
Box(backgroundColor: const BoxColor.role(MaterialColorRole.surfaceContainerLow))

// what the application says, once, when it renders
toDocument(page, theme: MaterialPalette.lightTheme);
renderFlutter(page, theme: MaterialPalette.lightTheme);
```

A palette of your own is grown from a single colour — [A palette from one
seed](#a-palette-from-one-seed) is that section.

| Role | What Material paints with it |
| --- | --- |
| `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer` | an accent and the text on it |
| `secondary`, `onSecondary`, `secondaryContainer`, `onSecondaryContainer` | the quieter accent a chosen control wears |
| `surface`, `onSurface`, `onSurfaceVariant` | the page, its text, and its lower emphasis text |
| `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest` | the tones a card, a navigation bar, a dialog and a filled field sit at |
| `outline`, `outlineVariant` | a line that frames a control, and one that only separates |
| `error`, `onError` | what went wrong, and the text on it |
| `scrim` | what covers the page behind a modal |
| `hoverLayer`, `focusLayer`, `pressedLayer`, `draggedLayer` | 8%, 10%, 10% and 16% of `onSurface`, the state layers as translucent colours |

The layers are derived rather than listed, because Material states them as an
opacity over the on-surface colour: a translucent colour reads correctly over any
surface tone, which is what a CSS state layer does.

**A component names a role, and the host answers it.** Every component in this
package names roles, so *one* value themes it everywhere: `MaterialPalette.lightTheme`
and `MaterialPalette.darkTheme` are the two ready-made ones, and `UniboxTheme` is a
value, so a dark app is the same tree with another theme. On the web the roles are
written as custom properties and the theme once in `:root`, which is what lets a
stylesheet of the host override any of them — a `prefers-color-scheme: dark` block is
enough. In Flutter they are resolved while the widget tree is built.

**The one thing this package cannot do itself**: install the theme. It depends on
`unibox_core` and on Material's colour algorithm and never imports Flutter, so the
two wirings that make the values reach a `ColorScheme` and a page's CSS are the
application's — which is also what keeps the tree and any embedded Material widget
in step.

## A palette from one seed

A brand is one colour, not twenty. `MaterialPalette.fromSeed` grows the whole
palette from it, by the algorithm Material's own themes run:

```dart
const brand = BoxColor.rgb(0x2D, 0x6C, 0xF3);

final light = MaterialPalette.fromSeed(brand);
final dark = MaterialPalette.fromSeed(brand, isDark: true);

toDocument(page, theme: light.theme);
```

| Parameter | Default | What it decides |
| --- | --- | --- |
| `isDark` | `false` | which of the two schemes to build: the light one, or the one whose accent is a light tone and whose surfaces are near black |
| `variant` | `MaterialSchemeVariant.tonalSpot` | how the seed is spent, from a whisper to a shout |
| `contrastLevel` | `0` | `0` is Material's own contrast, `1` the highest the algorithm offers, `-1` the lowest, and anything between is interpolated; out-of-range values are clamped |

A palette is a pure function of those three: the same arguments give the same
twenty-four roles, and the four state layers are still derived from the generated
`onSurface`, so a tint belongs to the palette that made it.

**What a seed keeps, and what it does not.** Material keeps the seed's hue and
spends it on its own palettes, which means it *replaces the tone* — a palette needs
all of them, from a white sheet to a near-black line — and, in the default variant,
it lowers the chroma too. One of the example's own seeds, `#2D6CF3`, is a saturated
blue; its
`tonalSpot` accent is `#4A5C92`, a quiet one — and that is the palette the example
itself is drawn with, since its whole theme is grown from that one seed. That is
Material You's whole
temperament, and the variant is the dial:

| Variant | What it does with the seed |
| --- | --- |
| `tonalSpot` | pastel tones from a low chroma palette: the Material You scheme, and Flutter's default |
| `fidelity` | keeps the seed's own chroma, so the accent is the colour the brand chose |
| `content` | almost `fidelity`, with a container that is the seed itself |
| `vibrant` | the same hue at maximum chroma: `#0054D7` for the blue above |
| `expressive` | a medium chroma, and a hue that deliberately leaves the seed's |
| `neutral` | barely any chroma: greys with a hint of the seed |
| `monochrome` | no chroma at all, so the surface tones carry the hierarchy |
| `rainbow`, `fruitSalad` | playful schemes whose hues avoid the seed's |

**It is not `MaterialPalette.light` for Material's own seed.** The two `const`
palettes in the section above are the baseline scheme printed in the specification,
drawn before the algorithm was refined; `fromSeed` runs today's algorithm. So
`MaterialPalette.fromSeed(const BoxColor(0xFF6750A4))` is `#65558F` where the table
says `#6750A4`, and its containers sit a tone or two away. That is the scheme
Flutter's own `ColorScheme.fromSeed` builds from the same colour — both call this
algorithm — which is the parity that matters: install that scheme on the
`MaterialApp` and the tree and an embedded Material widget agree. Reaching for the
specification's numbers instead is what `MaterialPalette.light` and `.dark` are for.

**A seed is a colour, not a role.** `fromSeed` throws an `ArgumentError` for
`BoxColor.role(...)`: a role is a colour a theme answers, and this is the call that
builds the theme.

## The card

`MaterialCard` is the other half of the package: a Material 3 surface with
children.

```dart
const MaterialCard(
  children: <UINode>[
    TextNode('Order summary', style: MaterialTypography.titleMedium),
    TextNode('Two nights, one room.'),
  ],
);
```

It is a `Box`, so both renderers already draw it, and every token it sets is one
the conformance table already pins — the class is a combination, not a new token:

| Token | Value | Why |
| --- | --- | --- |
| padding | none | Flutter's `Card` pads nothing: padding on the surface is room no press inside it can reach |
| background | `BoxColors.white` | the surface, until a colour scheme exists |
| radius | `12` | the medium shape of Material 3 |
| shadows | `MaterialCard.elevatedShadows` — `MaterialElevation.level1` | elevation level one: the design file's ladder, one shade cast at 34% black |
| typography | `MaterialTypography.bodyMedium` | inherited by the texts inside |
| layout | a column (`Box`'s default), with `crossAlign: stretch` | a card stacks its content and stretches it to the card, so a row of it spans the width |

Every one is a parameter, so an application themes a card instead of forking it:

```dart
MaterialCard(
  color: surfaceContainerLow,
  border: const BoxBorder(color: outlineVariant),
  textStyle: MaterialTypography.bodyMedium.merge(
    const BoxTextStyle(color: onSurface),
  ),
  children: <UINode>[TextNode('Order summary')],
)
```

The layout of a box comes through too — `direction`, `gap`, `width`, `flex`,
`stateStyles`, `semantics`, ... — but the press does not: a card is a surface, the way
Flutter's `Card` is, and the press belongs to the ink inside it. That is the only
composition that can work, because a well paints its tints and its ink *under* its child,
so a well around the card would paint them behind an opaque surface:

```dart
// The whole card is the destination: ink inside, padding on the ink.
MaterialCard(
  overflow: Overflow.hidden,
  children: <UINode>[
    MaterialInkWell(
      url: '/spots/abc/book',
      padding: const BoxSpacing.all(16),
      child: content,
    ),
  ],
)
```

A pressable card can also be **one node**: `MaterialInkWell` already paints a fill, a line,
a radius, a clip and a padding, and it takes `shadows` and `textStyle` as well — so a well
given the card's tokens is a card that inks, with no second box and no ring of padding
nothing can reach. `MaterialCard` stays for the static surface.

What the card does not expose is a style bag: its own tokens are flat parameters, so a
bag would lose to them. A `Box` around it is the escape hatch, and it is the box this
class builds.

**What it is not.** Material takes a card's surface from a colour scheme
(`surfaceContainerLow`), and its three official variants differ by tone: the surface
here is `surfaceContainerLow` and the variant is the elevated one, so a card is a
value rather than a lookup. A press is `stateStyles` and paints no ink; a
`MaterialInkWell` inside the card is the ripple.

## The list tile

`MaterialListTile` is the row Material builds a list out of: an optional leading
node, a title with an optional subtitle, and an optional trailing node.

```dart
MaterialListTile(
  leading: const TextNode('AL'),
  title: const TextNode('Ada Lovelace'),
  subtitle: const TextNode('ada@example.com'),
  trailing: const TextNode('2m'),
  onTap: openContact,
);
```

It is a `Box` around a `MaterialInkWell` — a row wrapped in the ink — so neither
renderer has to know the name, and every token is a combination of ones the
conformance table already pins:

| Token | Value | Why |
| --- | --- | --- |
| layout | a row, centred across, filling its width | a tile is one line of a list |
| gap | `16` between the leading node, the text and the trailing node | Material's `horizontalTitleGap` |
| title gap | `2` between the title and the subtitle, or `textGap` | Material stacks the two lines close, and a tile whose two lines are the same size wants no gap at all |
| padding | `16` on the sides | the room Material gives a tile |
| minHeight | `56` / `72`, or `48` / `64` when `dense` | Material's one line and two line heights |
| title | `MaterialTypography.bodyLarge` | Material's title role |
| subtitle | `MaterialListTile.subtitleTextStyle` | `bodyMedium` in `onSurfaceVariant` |
| hover, focus, press | `hoverLayer`, `focusLayer`, `pressedLayer` | the roles Material's state layers are, resolved by the host's theme |
| ink | `MaterialInkWell.defaultInk`, from where the press landed | a press inks the tile the way it inks every other Material surface |
| role | `BoxRole.button` when it can be tapped | a tappable tile is a control, and the role is what makes it focusable |

A subtitle sits in its own box inside the text column, because typography is the
one thing this model inherits: the column states `bodyLarge` for the title and the
inner box states the subtitle style for the line under it.

`MaterialListTile.row` is the row itself — the parts, the padding, the gap and the
minimum height — and the tile around it only fills the width, paints the surface and
inks it. A test or a reader inspects the row; the ink belongs to the well.

**A tile in a rounded container needs the container to clip.** Its tint is a
background on its own box, so it paints square over a rounded corner unless the
container declares `overflow: Overflow.hidden` — which is what a Material container
does for its children — or the tile is given a `borderRadius` of its own. Two tiles
stacked in one container want the former, because only the outer corners are round.
The gallery in the example does exactly that.

## The button

`MaterialButton` is a label on a fill, with the ink of a press. Four named
constructors, one for each shape Material 3 has:

```dart
MaterialButton.filled(label: const TextNode('Create account'), onTap: save)
MaterialButton.tonal(label: const TextNode('Later'), onTap: snooze)
MaterialButton.outlined(label: const TextNode('Cancel'), onTap: close)
MaterialButton.text(label: const TextNode('Learn more'), onTap: open)
```

| Variant | Fill | Label | Line |
| --- | --- | --- | --- |
| `filled` | `primary` | `onPrimary` | — |
| `tonal` | `primaryContainer` | `onPrimaryContainer` | — |
| `outlined` | none | `primary` | `outline` |
| `text` | none | `primary` | — |

Every colour is a role, so a dark theme restyles all four with no parameter. It is a
`Box` around a `MaterialInkWell` — the fill on the box, the tints and the ink on the
well over it, so a tint cannot wash the colour out — which is also why it needs no
renderer work: neither target knows the class.

**It is as wide as its label, not as wide as its parent.** A button is laid out inside a
row, so a parent that stretches its children — a card's column, a grid track — stretches
something invisible, and the fill and the well inside it keep the size the label asks
for. That is what keeps a hover tint the width of the button: a fill that stretched while
its ink did not was a band with a pill at one end. Pass `width:` when a full-width button
is what is wanted, and the press takes exactly that.

**The pill is the press.** The 64 by 40 minimum belongs to the well, not to the fill
around it, so the fill hugs a control that is never smaller than the button it paints:
four pixels of vertical room still gives a 40 pixel target, and a pinned `width` or
`height` is the well's too. A minimum on the fill painted a pill bigger than the box that
answered the pointer, so the ends of a button looked pressable and were dead — on one page
a `text` button and an `outlined` one of the same header behaved differently.

Shape and states are Material's: a radius of 20 (a full round on a 40 pixel height —
`labelLarge`'s 20 pixel line plus ten above and below), 24 by 10 of room on the three
filled shapes and 12 by 10 on the text one, and the button role whenever the button can
be tapped, so it is focusable and activates on `Enter` and `Space`. `enabled: false`
takes the ink away and leaves the button in place.

**All four carry the same minimum, 64 by 40.** The text shape is narrower than the
others — 12 across rather than 24 — but it is the same height, so the four line up in a
row; it used to be the only one that painted 36, because Material's 40 is a *minimum
size* and not the sum of its padding. The label is centred in the press, so a button
pinned with `width:` centres its label rather than leaving it against the left edge, and
`minWidth` and `height` are the caller's to lower or raise. A minimum outranks a size on
both targets — `min-width` beats `width` in CSS and a `ConstrainedBox` clamps the same
way in Flutter — so the two agree about what `width: 40` means.

An `icon` puts a node before the label, `iconGap` pixels away (eight by default); `ink`,
`borderRadius`, `padding`, `labelStyle` and `border` are parameters when a screen needs
to differ, and all four constructors take `onTap`, `onLongPress`, `onHover` and
`transition` — a named shape used to drop the last three.

## The icon button

`MaterialIconButton` is one glyph in a 40 pixel square, with the ink of a press: the shape
every application was drawing by hand — a box, a glyph inside it and a counter over the
corner — as one node.

```dart
MaterialIconButton(
  icon: MaterialIcon.ligature('tune'),
  label: 'Filters',
  onTap: openFilters,
)
MaterialIconButton(
  icon: MaterialIcon.codePoint(Symbols.notifications.codePoint),
  label: 'Notifications, 3 unread',
  badgeCount: 3,
  variant: MaterialIconButtonVariant.filled,
  onTap: openInbox,
)
```

| Variant | Fill | Glyph | Line |
| --- | --- | --- | --- |
| `standard` | none | `onSurfaceVariant` | — |
| `filled` | `primary` | `onPrimary` | — |
| `tonal` | `secondaryContainer` | `onSecondaryContainer` | — |
| `outlined` | none | `onSurfaceVariant` | `outline` |

**The square is Material's.** 40 by 40, which is the smallest thing a finger is aimed at,
with the glyph centred in a 24 pixel box and 8 pixels of room round it. `height` and
`width` are the square — a control that names only a height is as wide as it is tall —
`iconSize`, `padding`, `borderRadius`, `ink` and `transition` are the rest of the
measurements, and `label` is what a screen reader says, because a glyph with no text beside
it names nothing. A control with no label leaves the reading order rather than announcing
an anonymous button.

**The badge is placed, not added.** `badgeCount` draws a pill of `error` with `onError`
labelled text, 16 pixels tall and as wide as the number needs, pinned to the top right
corner of the square — which is the corner of the glyph once the 8 pixel inset is taken
off. It sits in a `StackNode` over the square instead of beside it, so a count can never
grow the target the finger needs, and it is hidden from a screen reader: a count nobody is
told is a picture, and the control's own `label` is where the fact belongs. It is hidden
from the *pointer* as well — `capturesPointer: false` — because the corner it covers is
the first place a thumb lands: a badge that took the pointer there was a square whose
hover, hand and press stopped at a picture, on both targets.

**What Material draws that this does not.** A toggle icon button states `aria-pressed` and
changes its shape when it is on; this node has one shape, so a toggle is the caller's
rebuild — the store picks the variant — and it announces no pressed state, because a
`pressed` no view can change is a state a reader is told wrongly. There is no tooltip (that
is platform chrome), and the badge does not scale in (a transition the tree can say, if a
caller wants one).

## The ink well

`MaterialInkWell` is a tappable region: the three state layers of the palette, and
the ink a press spreads from where it landed.

```dart
Box(
  backgroundColor: palette.primary,
  borderRadius: 20,
  children: <UINode>[
    MaterialInkWell(
      onTap: store.save,
      borderRadius: 20,
      ink: palette.onPrimary,
      padding: const BoxSpacing.symmetric(horizontal: 20, vertical: 10),
      child: TextNode(
        'Save',
        style: MaterialTypography.labelLarge.copyWith(color: palette.onPrimary),
      ),
    ),
  ],
)
```

| Token | Value |
| --- | --- |
| hover, focus, press | `hoverLayer`, `focusLayer`, `pressedLayer` |
| transition | 100ms, so a tint eases instead of flashing |
| ink | `onSurface`, 12% where the press landed, 280 pixels wide at the end, gone after 450ms |
| role | `BoxRole.button` when it can be tapped |
| `url` | the region is a destination instead of a callback: one `<a href>`, wherever the press is |
| `minWidth`, `minHeight` | a floor on the shape — the box that takes the press — rather than on a fill around it |
| `shadows`, `textStyle` | the well can be a whole surface — a card — rather than a press inside one |

**A floor belongs to the shape.** `minWidth` and `minHeight` are the smallest the region
paints, and they are stated on the box that takes the press rather than on a fill around
it: a pill bigger than its control has ends that look pressable and are not. The floor is
never a clamp — a label taller than it grows the region.

The ripple is **state, not a renderer feature**. A press adds a drop to a
`MaterialInkStore`, a timer advances it every frame, and the view draws one box per
drop — a circle centred on the press, growing as it fades. Both targets therefore
draw the ink out of nodes they already draw, which is why the conformance table
needs no case for it: there is no second implementation to hold in step. A page
rendered without a client runtime subscribes to nothing, so it shows the resting
well, and a region that cannot be pressed listens to no pointer at all.

It paints **no surface unless it is given one**: the tints and the ink have to sit above
the fill they belong to, so by default the filled box goes around the ink well. Wrapped
the other way round the fill would hide both. Pass `fill:` — and `border:` with it —
and the well paints that surface itself, under a layer of tints of its own, which is
what a control needs when the whole of it is one target. The well clips its own content
to `borderRadius`, which is what keeps a drop inside a rounded button, and `ink` is the
one colour that is not a role — the ink has to contrast with the fill around the well,
which the well cannot see.

**A target can be taller than the shape.** `tapTargetHeight` makes the region a finger
can hit taller than the shape it paints, with the shape centred in it: Material states
48 for a touch target over a 32 pixel chip. The tints, the ink and the fill stay on the
shape — a tint is the shape — so the extra room takes the press and paints nothing, and
a drop that lands in it still starts where the pill would see the press. It is layout
and not paint: a row of chips is as tall as the target.

**A well can be a destination.** `url` puts the anchor wherever the press is — on the shape
in the plain case, on the outer box when the well paints a surface, and on the target when
`tapTargetHeight` adds one — which is one rule: where the press goes, the `href` goes. An
anchor is pressable with no callback, so the ink still starts on tap-down; an `<a>` inside
an `<a>` is not a link at all, which is why a shape inside a taller target names nothing.
The web follows the `href` with no runtime and a crawler reads it; Flutter opens it through
the host's link scope while the box keeps its ripple and its press state.

What it is not is a timeline the host owns: the ink is a state machine and a timer,
so a press costs a rebuild of one subtree per frame for 450ms. On the web that rebuild
stops costing anything after the first press — a drop is a fixed circle scaled out of
nothing, so every frame of every press asks for a look the sheet already has. A ripple
writes 30 rules the first time it is pressed in a place, one of which is where it
landed, and a press after that writes none until the press lands on another pixel.
`EmbedNode` remains the escape hatch when a host-side animation is what the effect
needs.

## The segmented button

`MaterialTabBar` is one row of tabs with an indicator under the chosen one, and
`MaterialTabs` is that bar with the page of the chosen tab under it: a `StatefulNode`
whose store holds the index, so a press swaps the page on both targets.

```dart
MaterialTabs(
  tabs: const <MaterialTab>[
    MaterialTab(label: TextNode('Overview')),
    MaterialTab(label: TextNode('Listings')),
  ],
  pages: <UINode>[overview, listings],
)
```

The bar on its own takes `selected` and `onSelect` and draws no page, which is what an
application wants when the page is its own node — above a pager, above a page that swaps,
beside a preview. A *primary* bar distributes its tabs across the width and a *secondary*
one packs them to the start at their own width.

A bar is as wide as its parent and hands that width down, so a primary tab is a third of a
three-tab bar: the width of a tab is the bar's, and the bar's is the parent's. Give it a
narrower parent to make the tabs tighter, which is also the only lever — the bar states
`width: double.infinity` and takes no width of its own.

The bar's measurements are parameters, and only one of them differs between the variants:
a tab is 48 tall with 8 across inside, 4 between an icon and its label, 3 pixels of
indicator. `height`, `tabPadding`, `labelGap`, `indicatorHeight` and `labelStyle` replace
them — and `tabPadding` also settles the difference, because a secondary tab's default
room is 16 rather than 8.

Its indicator is one element, a share of the bar wide, laid from the start edge and moved by a
multiple of its own width — so it slides between tabs with a `transform` a transition eases, and
nobody has to measure a tab. That is the *primary* bar, whose tabs are equal shares by
definition. It begins at the start edge rather than the centre: an aligned child fills the
layer and the alignment places it, so a centred indicator is already half a bar along and every
step after that lands one tab too far.

A *secondary* bar packs its tabs to the start and gives each one its label's width, so a share
would land under no tab at all. Each tab carries its own underline instead, pinned across the
bottom of a stack its label sizes — the one width a tree can have that its siblings do not
share, and still no measurement: a stack takes the size of the child it lays out. It fades
between tabs rather than sliding, because where the next label *starts* is the one distance
this tree cannot state.

It does not page between tabs: a swipe needs a controlled scroll position, and the model
reports an offset (`Box.onScroll`) without setting one. The pager is `Box(snap:
ScrollSnap.page)`, which pages by drag; a tab press swaps the page instead of sliding to it.

`MaterialSegmentedButton` is two to five choices in one divided pill.

```dart
MaterialSegmentedButton(
  segments: const <MaterialSegment>[
    MaterialSegment(label: TextNode('Day')),
    MaterialSegment(label: TextNode('Week')),
    MaterialSegment(label: TextNode('Month')),
  ],
  selected: 1,
  onSelect: store.choose,
)
```

| Token | Value |
| --- | --- |
| height, radius | 40, and 20: a full round. `height`, `borderRadius`, `padding` (12 across each segment's content), `iconGap` (8) and `labelStyle` are parameters |
| line | a 1 pixel `outline` line, `overflow: hidden` so a chosen fill is cut to the rounded ends it reaches. `border` is the line around the pill *and* between its segments, so a theme that draws the control with `outlineVariant` says it once |
| chosen | a `secondaryContainer` fill, an `onSecondaryContainer` label, a check, and `pressed` for a screen reader |
| check | 18 pixels, a `MaterialCheckMark`, in place of the chosen segment's icon; `showSelectedIcon: false` keeps the icon |
| icon | `iconSize` = 18, 8 from the label and 12 from the segment's edge |
| label | `labelLarge`, `onSurface` or `onSecondaryContainer`, on one line: a text too long for its share is cut with an ellipsis |
| dividers | a box as wide as the border's line and the colour of it, between two segments |
| width | equal shares (`flex: 1`) when the button was given a width, and each segment as wide as its label when it was not |
| disabled | the whole control at 38%, with no ink on any segment |

The container is one box and each segment is a box around a `MaterialInkWell`, so the
tint and the ink cover the segment rather than its label, and the container's clip
keeps them inside the pill. The well's content is centred and its stack stretches —
that is what the well's `mainAlign` and `crossAlign` are for, and why a segment can
say `width: double.infinity` and mean it on both targets.

**Give it a width when its parent stretches it.** A segment only takes a share when
there is a width to divide: without one each is as wide as its label, which is right for a
pill in a row of its own — a horizontally scrolling row, where a share of no width is a
contradiction rather than a measurement — and wrong for one a column or a grid track
stretches, where the outline fills the cell while the segments stay at the left and two
thirds of the control is empty. `width: double.infinity` fills the space the parent gives
and divides it equally, which is what Material's segmented button does; the example's
gallery does exactly that, and its listings page passes a fixed 216.

**A label is one line.** A segment is a share of the control's width and not a width of its
own, so a label longer than that share — a translation, or any label at twice the text
scale — gives way instead of widening the pill or painting over the segment beside it: a
text is drawn with `maxLines: 1` and an ellipsis, and any other node is cut at the share.
A hugging segment is untouched, because a row that scrolls has room for it.

A chosen segment draws an 18 pixel check in place of its icon, which is what Material
does, so a control of pictures still says which one is on. The check is a
`MaterialCheckMark` — two rotated bars with Material's own weight, because an icon font
is a host asset and this package ships none — and `showSelectedIcon: false` leaves the
icon where it is for a control whose fill is enough.

**A set of destinations is a set of links.** Give the segments a `url` and the control
stops being a set of buttons: each unchosen choice is one `<a href>` with the segment's
padding and fill, so a crawler reads where they lead and a page with no runtime follows
them. The chosen one is the page the reader is on — no link to itself, not in the tab
order, `aria-current="page"` — and `onSelect` is not called for a segment that has a url,
because the destination is the press:

```dart
MaterialSegmentedButton(
  selected: 1,
  segments: const <MaterialSegment>[
    MaterialSegment(label: TextNode('Day'), url: '/?period=day'),
    MaterialSegment(label: TextNode('Week'), url: '/?period=week'),
  ],
)
```

**What stays approximate.** The container is not a `radiogroup`, because `BoxSemantics`
has no group role: every selecting segment is a button that says whether it is the chosen
one. A disabled control fades as one at 38% rather than drawing `onSurface` at 12% under a
38% label, which would need an alpha role per token.

## The text field

`MaterialTextField` is a field with a state of its own: it is a `StatefulNode`, so it
knows the text, whether it has focus, and whether the user has touched it, and it
draws its own focus line, its own floating label and its own error.

```dart
MaterialTextField(
  label: 'Email',
  inputType: InputType.email,
  helper: 'We only use it for the receipt.',
  validator: (String value) =>
      value.contains('@') ? null : 'Enter an address with an @',
  onChanged: store.setEmail,
)
```

The field holds what only it can know. What the value is *worth* — the request it
starts, the button it enables — is the form's store, reached through `onChanged`.
`initialValue` seeds the text the user then owns, `value` controls it from outside, and
`error` shows a message the form decided on ("that address is taken"); all three
outrank what the store starts with.

`validator` is asked once the field has been touched, which is a keystroke or leaving
it. Answering `null` means nothing is wrong: the line and the label stay in the resting
colour and `helper` is the quiet message under the field. Answering a message turns the
line, the label and the row under the field into `error`, so an address becomes valid
and invalid as it is typed, with no flag passing through the host.

| State | Line |
| --- | --- |
| resting | `onSurfaceVariant`, one pixel |
| hover | `onSurface`, one pixel |
| focused | `primary`, two pixels |
| touched, and the validator answered | `error`, two pixels while focused, and the label and message with it |

The line is a shadow with no blur, because `BoxBorder` draws all four sides and a
filled field has none, and the value's padding lives on the input so a press anywhere
in the fill focuses the field. `contentPadding` is the room at the sides of the label,
the value and the message — the three stay in one column — and `messageGap` is the space
between the fill and the line under it.

**The label has Material's two positions.** Empty and unfocused, the label *is* the
line inside the field: body size, `onSurfaceVariant`, drawn as the input's own hint so
that the caret and the label are one piece of text and the field is 56 pixels tall.
Once the field holds a value or takes focus, the label shrinks to `bodySmall` at the top
of the fill and the value takes the row below it, which keeps the same 56 pixels.
Material animates the move and the model has no triggered timeline for a layout change,
so this one steps.

**Rounded at the top, square at the bottom.** Material's filled field is a shape cut to
the lines it sits between, so the field names the two top corners through
`BoxBorderRadius` and leaves the bottom two alone.

The caret, the selection, the IME and autofill are the platform's, because the input
node delegates them — so a dark app renders the same field with
`theme: MaterialPalette.darkTheme` *and* a matching `ColorScheme` to `MaterialApp`.

## The chip

`MaterialChip` is a filter chip: a label in a pill, chosen or not.

```dart
MaterialChip(label: const TextNode('Two rooms'), selected: true, onTap: filter)
MaterialChip(label: const TextNode('Studio'), onTap: filter)
```

| Token | Value |
| --- | --- |
| height | `controlHeight` = 32 painted, in a target of `minTapTarget` = 48: the pill is centred in the room Material gives a finger, so an 18 pixel glyph can make neither a taller chip nor a smaller one. `height` and `tapTargetHeight` are parameters |
| radius | 8, the small shape of Material 3, or `borderRadius` |
| unselected | no fill, a 1 pixel `outline` line, `onSurfaceVariant` label |
| selected | `secondaryContainer` fill, no line, `onSecondaryContainer` label |
| room | 16 on a side the label reaches, 8 on a side a node sits (`iconSize` = 18), 8 between them — Material pads the side, not the chip. `padding` replaces all of it and `gap` the space to a node |
| label | `labelLarge`, `onSurfaceVariant` or `onSecondaryContainer`; a `labelStyle` replaces the type and the state keeps the colour |
| hover, focus, press | `hoverLayer`, `focusLayer`, `pressedLayer` over the pill |
| disabled | the pill at 38%, with no ink: Material draws the label at 38% and the line at 12%, and one opacity is what this model can say without an alpha role per token |
| leading, trailing | a node before and after the label — a check, a folder, a cross |
| onRemove | an 18 pixel round target inside the pill: a press on it removes the chip, not the choice. `removeSemanticsLabel` is what that target announces, and it defaults to "Remove" |

It is a `Box` around a `MaterialInkWell`, like `MaterialButton`, and the padding is
**the well's alone**: one node carries the room inside the chip, so the tint of a
hover reaches exactly the edge of the pill. Two paddings — one on the well and one on
a box inside it — is what made a hand-built chip tint 14 pixels past itself. The well
clips to the radius, so the ink of a press stays inside too.

A chip is a control: it announces itself as a button when it can be pressed, and says
whether it is on — `pressed`, which a screen reader announces and a browser writes as
`aria-pressed`. It is not `selected`: `aria-selected` is only honoured on an option, a
tab, a row or a grid cell, so a button that carried it said nothing about its state on
the web, and said "selected" on a phone — one control described two ways.

**What stays approximate.** A chosen filter chip shows a check mark in Material; here the
check is `leading`, because a chip carries whatever node the caller gives it.
`MaterialCheckMark` is the one to pass, and it is what the example passes: the mark is
drawn from boxes, so it needs no font and looks like Material's own. The 48 pixel target
is the room around the pill and not a painted shape, so hovering the pill's top and
bottom eight pixels takes the press but paints no tint.

`leading` and `trailing` take a node each, and `onRemove` turns the chip into an input
chip: the trailing node is wrapped in a round well of its own, so a press on the cross
removes the chip instead of choosing it. That well centres its node on both axes — a
well is a column, and a cross pinned to its start would leave the ring of a hover four
pixels off the cross it belongs to. The glyph itself is the caller's — a folder and a
cross come from a font, and a font is a host asset this package does not ship.
`MaterialIcon` is the way in when an application has one; the example draws its four
glyphs from boxes instead. `removeSemanticsLabel` names what the cross removes, which a
row of applied filters should pass: eleven chips that all announce "Remove" leave a reader
with no idea which one is about to go.

## The navigation bar

`MaterialNavigationBar` is three to five destinations along the bottom edge of a
screen, one of them the page it is on.

```dart
MaterialNavigationBar(
  destinations: <MaterialNavigationDestination>[
    MaterialNavigationDestination(
      label: const TextNode('Listings'),
      icon: MaterialIcon.ligature(
        'list',
        color: MaterialNavigationBar.inactiveIconColor,
      ),
      selectedIcon: MaterialIcon.ligature(
        'list',
        color: MaterialNavigationBar.activeIconColor,
      ),
    ),
    MaterialNavigationDestination(label: const TextNode('Map')),
  ],
  selected: destination,
  onSelect: store.choose,
)
```

| Token | Value |
| --- | --- |
| height | `80` |
| container | `surfaceContainer`, and a `nav` landmark on the web |
| share | every destination is `flex: 1` and as tall as the bar |
| indicator | 64 by 32 at radius 16, `secondaryContainer`, behind the chosen icon |
| label | `labelMedium`: `onSurface` when chosen, `onSurfaceVariant` when not |
| ink | the label's own colour, from where the press landed |
| hover layer | `hoverLayer` in the pill's shape, faded over 50ms — `InkResponse`'s own hover duration |
| press | the splash alone: the indicator's highlight colour is transparent in Material, so a press inks the pill and then the pill settles into its new colour |
| room | 12 above the pill, 4 between it and the label, 16 below |

Every number in that table is a parameter — `height`, `indicatorWidth`,
`indicatorHeight`, `itemPadding` and `labelGap` — so a bar with taller destinations, a
wider pill or a different rhythm is the same component. Their defaults are the ones
Material states, which is what makes them add up to the bar's 80.

Each destination is a `Box` whose share is the control — a hover anywhere in it lights
the pill inside it — and the pill itself is three layers: the indicator colour, the hover
layer over it, and an ink well carrying the icon. The pill is filled only while the
destination is the chosen one. The 12 pixels above the pill, the 4 between it and
the label, and the 16 below add up to the bar's 80 with `labelMedium`'s 16 pixel
line box — which is why a destination needs no height of its own and both targets
put the icon in the same place.

**The icon is the caller's, and so is its colour.** A picture carries its own colour
on both targets — typography is the one inherited axis — so `activeIconColor` and
`inactiveIconColor` are public constants to build the two glyphs with, and
`selectedIcon` is the filled variant Material pairs with an outlined one. A
destination with no picture keeps its empty pill, so the labels of a bar still line
up.

**What it announces.** Each destination is a button that says whether it is chosen
and, when it is, that it is the current page — `aria-current="page"` on the web,
the selected item of a set in Flutter. That is the *only* state it sets: `aria-selected`
belongs to options, tabs and rows and not to a button, and Flutter already reads
`current` as the selected state, so one fact reaches both targets and neither is told
something invalid. The bar itself is a `nav` landmark on the web, which Flutter's screen
readers have no counterpart for. A tab strip's arrow keys are deliberately not modelled
(`BoxRole` has no tab), so the role is a button.

**Where it sits is the tree's business**, and so is the safe area: the bar is a row
that fills the width and states its height, and being at the bottom is a
`PositionedNode` at the bottom of a `StackNode`, or the last row of a full height
column.

**The pill arrives, the way Flutter draws it.** The chosen destination's indicator is
stretched sideways out of its icon — `scaleX` from 40% to full, at its own height — over
500ms, and faded over 100ms, which is `MaterialNavigationBar.indicatorTransition`'s two
parts: the fade is the base speed and the stretch its own (`BoxTransitionPart`). The pill
is in the tree at every destination and only its look changes, so a switch never inserts a
node; the model eases paint and never layout, which is also why the pill does not travel
*along* the bar between destinations. Two approximations: `easeOut` is the closest curve
the model shares with CSS to Material's emphatic easing, and the reverse uses the same one
where Flutter flips a differently shaped curve. The label changes colour at once, and the
icon swaps rather than cross-fading, because a text colour is not a paint a transition
eases and the icon is the caller's node.

**Three layers in the pill, and the order is the behaviour.** A destination is one control
— a box over the whole share, which is what a finger presses and what a reader hears — and
inside it the indicator is three layers, which is the arrangement Flutter draws:

1. **the colour**, 64 by 32 at radius 16, which fades in over 100ms and stretches sideways
   out of the icon over 500 as a destination becomes the chosen one;
2. **the hover layer** over it, faded over 50ms — a hover is not a selection, so it neither
   stretches nor waits for one, and a hovered destination that is *also* chosen keeps its
   colour and gains a tint instead of trading one for the other;
3. **an ink well** carrying the icon, whose tints are transparent and whose splash is the
   press: Material gives a navigation destination a transparent highlight colour, so a
   press shows ink inside the pill and then the indicator settling into its new colour, with
   no grey flash in between.

Flutter confines the ink with `_IndicatorInkWell.getRectCallback` to the indicator's rect,
and its ripple is an ink feature above the indicator and under the icon — the same three
layers, painted in the same order.

**The hover needs the runtime today, and what is missing is a token, not a stylesheet.**
The pointer is over the **share** and the tint is in the **pill**, and CSS says that in one
line — `.share:hover .pill { background-color: … }`. What the model cannot say is that the
two are related: a `stateStyles` entry describes the box it is on, and nothing in the tree
means *while I am hovered, a descendant of mine paints*. So the renderer has no rule to
write, and it will not guess which of a box's children should change — a look that a
renderer invents is the drift the contract exists to prevent. Where a runtime is present —
Flutter, or `unibox_dom` in a browser — the destination keeps the hover in its store and
the pill lights; a document with no runtime draws the pill for the chosen destination only.

Closing the gap is a small feature and not a trick: a box states *which* descendant wears
its state, the plan emits `.share:hover .pill` after both classes exist (the parent is
planned before its children, so this is a second pass), and Flutter answers the same
declaration from its own hover state — which would also let this component drop its store,
because a hover is the host's interaction and not the tree's state.
Two things keep the press single. The pill answers a press itself and its click stops
there — the innermost control wins, which is Flutter's gesture arena — so `onSelect` is
called once whichever layer the press landed on. And the label is a layer that takes no
pointer, so a press on it reaches the destination under it; that press selects without
ink, which is the one place this differs from Flutter, where a ripple starts anywhere in
destination and is still drawn inside the indicator.

## The dialog and the bottom sheet

Both are `OverlayNode`s, so they sit in the tree where the state says they belong, and
no renderer knows their names.

```dart
MaterialDialog(
  title: 'Delete listing?',
  content: const TextNode('The listing and its photos are removed.'),
  actions: <UINode>[Cancel(onTap: store.close), Delete(onTap: store.delete)],
  onDismiss: store.close,
)

MaterialBottomSheet(
  title: 'Filter listings',
  content: FilterForm(state: state, store: store),
  actions: <UINode>[Apply(onTap: store.applyFilters)],
  onDismiss: store.closeFilters,
)
```

| | Dialog | Sheet |
| --- | --- | --- |
| alignment | centre | bottom |
| surface | `surfaceContainerHigh` | `surfaceContainerLow` |
| width | 280 to 560 | up to 640 |
| barrier | `scrim`, dismissible by default | the same |
| title | `headlineSmall` in `onSurface` | the same |
| actions | a row against the end | the same |
| room | 24 of padding, 16 between the parts, radius 28, 8 between the actions and 8 above them | the same, rounded at the top only |

Every number in the last row is a parameter: `color`, `padding`, `gap`, `borderRadius`,
`actionGap` and `actionMargin` restyle the surface without a second component, which is
what a dialog on a small screen needs. A sheet's action row now keeps the 8 pixels above
it that a dialog's does, so the two read as one component at two edges.

Material's modal entrance and exit transitions are not here, and the sheet rounds only
its two upper corners because it rises from the edge.

## The icon

`MaterialIcon` is one glyph of an icon font, centred in a 24 pixel square: a `Box`
around a `TextNode`, so it recolours with `color` and scales with `size` like any
text, and needs no embed.

```dart
MaterialIcon.codePoint(Symbols.home.codePoint);             // by codepoint
MaterialIcon.ligature('home');                               // by ligature name
MaterialIcon.ligature('delete', label: 'Delete'); // on-surface by default
```

The font file is the host's, like any other font: declare the family in the
application (`fonts:` in the Flutter pubspec, an `@font-face` for the web) and name
it with `fontFamily`. A host that has no font for it draws the character as plain
text. A decorative icon is hidden from assistive technology; a `label` announces a
lone one.

**Tree shaking wants codepoints, not ligatures.** `--tree-shake-icons` reads const
`IconData` instances out of the application and subsets the fonts they name, so a
codepoint that comes from a const `IconData` turns a 10.7 MB variable font into a
few kilobytes — while a ligature name, being a string, leaves the whole font in the
build. Take the codepoint from `Symbols.home` (the `material_symbols_icons` package)
or from a `const IconData(0xe9b2, fontFamily: …)` of your own; the Symbols
codepoints are not the legacy `Icons` ones (`home` is `e9b2`, not `e88a`). A web
export has no shaker of its own: serve the subset the Flutter build wrote, or one
from `pyftsubset`, with its `@font-face`, plus `font-display: block` and a preload so
a glyph does not flash as text.

### The one glyph this package draws

`MaterialCheckMark` is Material's check without a font: the two strokes of the tick,
drawn as rotated bars, so a chosen chip or segment can say what is on even in an
application that ships no icons at all.

```dart
MaterialChip(
  label: const TextNode('Two rooms'),
  selected: true,
  leading: MaterialCheckMark(
    color: const BoxColor.role(MaterialColorRole.onSecondaryContainer),
  ),
)
```

Its numbers are the glyph's rather than a guess. Material's check is a polygon of its
24 pixel grid, and reduced to two centre lines it is a 2 pixel stroke, a 7.07 pixel
short arm and a 14 pixel long one at 45° each; the elbow then falls where the inked
mark is centred in the square, which is Material's own `9.55` across and a sixth of a
stroke below its `16.6` down — the difference between a round cap and the mitred end of
a polygon. The shares scale with `size`, so the same weight comes out at 18, at 12 and
at 40, and a tick drawn at a seventh of its box — nearly twice Material's weight — is
what makes a hand-tuned one read as a pen stroke beside Material's type.

It takes no semantics: it is decoration beside a label, and the control it sits in says
what is chosen through its own `pressed`.

## Elevation

Material states five levels for a raised surface, and a level here is what the design file
`doc/shadows_material_3_pink_seed.png` draws at that height: **one shade**, cast at 34% black at
level one and 40% above it, that grows wider as the surface rises. A box takes a list of
`BoxShadow`s, so a level is a list of one.

| Level | Offset, blur, shade | Material gives it to |
| --- | --- | --- |
| `level1` | `0 0.55px 0.61px` in black at 34% | a card, a sheet, a raised button |
| `level2` | `0 0.95px 2.35px` in black at 40% | a card under the pointer |
| `level3` | `0 1.25px 3.9px` in black at 40% | a dialog, a date picker, a floating action button |
| `level4` | `0 1.55px 5.02px` in black at 40% | a drawer as it opens |
| `level5` | `0 1.9px 6.5px` in black at 40% | the highest surface Material states |
| `sheet` | level one, pointing up | a sheet, which rises from the bottom edge |

**The ladder is the oracle, and it was measured.** The image in `doc/` is six cards at 2x — 120 dp, a 12 dp radius, a pink seed palette — and every row below a card's
edge was read out of it: level one reads `54, 32, 14, 4, 0` (darkness out of 255, half a dp
per row) and clears within two and a half dp; level five reads `65, 60, 54, 49, 44, 40, 36,
32` and still fades at ten. The table above is the gaussian that paints those rows, and the
example's suite holds the renderer to the rows themselves, so a level that stops matching the
file fails a test rather than a review.

**Neither of Flutter's two answers is that ladder.** `kElevationToShadow` — what the framework
states for a widget that needs a `BoxShadow` list, a menu's panel or a switch's thumb — is
three times wider: at level one it reads `72, 37, 15, 5, 2` and fades after four dp. A `Card`
is different again: it hands one opaque colour to `Canvas.drawShadow`, which spends it through
a light model and reads `56, 40, 28, 17, 9`. Copying either made a card on the page look a
level higher than the card in the design file, which is the drift this scale exists to
prevent, so the ladder won — and the difference with a Flutter `Card` is written down here
rather than papered over by a test that compares the two.

**A level is also a surface.** Material states elevation twice over, and the tonal half is the
half that shows: a shadow of 34% black over two pixels barely reads on a page of the same
tone. `level1` goes with `surfaceContainerLow`, `level2` with `surfaceContainer` and `level3`
with `surfaceContainerHigh`, so a card raised higher takes both halves:

```dart
MaterialCard(
  shadows: MaterialElevation.level2,
  color: palette.surfaceContainer,
  children: <UINode>[TextNode('A card under the pointer')],
)
```

The catalogue in the example draws the three pairs side by side, which is what makes the
climb visible at all.

A component names the level it rests at rather than writing a shadow, which is what keeps
`MaterialCard`, `MaterialDialog` and `MaterialBottomSheet` in step: an app that replaces one
level replaces it on every surface that uses it. A level states its blur in Flutter's unit,
and the web writes the CSS blur that paints the same width, so a card whose shadow is read at
the edge is the same height on the page as in the app. What stays outside the parity contract
is how the two engines *rasterise* that blur — a gaussian is drawn differently in a browser
and in Skia — so a level states the shape of the shadow, not a pixel promise.

## The circular progress indicator

`MaterialProgressRing` is a ring and the part of it that is done: two boxes, each **an
arc stroked in a colour**, one over the other.

```dart
MaterialProgressRing(value: 0.42, size: 48, thickness: 4, label: '42% complete')
```

| Token | Value |
| --- | --- |
| indicator / track | `primary`, and `surfaceContainerHighest` |
| size, thickness | 48 and 4, Material's touch target and its stroke |
| caps | `round`, which is what makes the ends of an arc read as Material's |
| value | a fraction of a turn, clamped: `-0.2` draws no value, `1.4` draws a closed ring |

Nothing about it is a renderer feature. The outline is `BoxShape.arc` — a circle's
centreline, inset by half the stroke so the stroke meets the box's edge — and the paint
is the box's `border`, whose `cap` states the rounded ends. So the component is three
nodes, the two arcs and the stack between them, and the two targets agree because they
draw the same shape and the same stroke. A ring states its thickness in pixels by
writing the shape in a grid as wide as the box, which is why `thickness: 4` is four
pixels at every size.

**The value is data, not a timeline.** Moving a ring is a store publishing a new value;
the component draws whatever it is given. When the value is not known it is
`MaterialSpinner`: the same arc at three quarters of a turn, rotated one step per frame
by a `MaterialSpinStore`.

```dart
MaterialSpinner(size: 48, thickness: 4, label: 'Loading')
```

The turn is a sequence of steps rather than a curve, and the sweep does not breathe the
way Material's does: the model has no keyframe timeline, so the clock is a store and the
rotation is a number it publishes. Sixty steps of six degrees repeat after one turn, so
on the web the sheet stops growing after the first revolution. A renderer that cannot
react never calls `onMount`, so a server export shows a still ring.

## Fidelity

What the components state against the Material 3 specification: a card in its three
variants (`MaterialCard.elevated`, `.filled`, `.outlined`), each taking the card's
whole parameter list as Flutter's `Card` does; a list tile with the 8
pixel vertical padding and the palette's title, supporting text and state layers; a
text field at least 56 pixels tall with a 2 pixel focused outline, a primary focused
label, an `onSurface` hover outline and 38% opacity when disabled; a dialog whose
content is `bodyMedium` in `onSurfaceVariant` over `labelLarge` actions in `primary`;
a navigation bar 80 pixels tall on `surfaceContainer`, its chosen destination's icon
on a 64 by 32 `secondaryContainer` pill; and a bottom sheet that fills the width up
to 640 pixels, with a drag handle and a shadow that rises. Still approximate: the sheet
rounds all four corners, the handle is not draggable, the navigation indicator fades and
grows in place instead of sliding between destinations, and the ink is one circle that
grows and fades where Material draws a splash with a fading highlight and a second ripple
when the press is released.

## Line heights

A `BoxTextStyle.lineHeight` is a multiple of the font size, because that is the
only form CSS (`line-height: 1.5`) and Flutter (`TextStyle(height: 1.5)`) scale
the same way. Material states its line heights in pixels, so each role writes the
division: `titleMedium` is 16 pixels with a 24 pixel line box, which is
`lineHeight: 24 / 16`.

The result is the specification's integral line box, not Flutter's rounded ratio
(`Typography.englishLike2021` writes `1.5` for that role and `1.12` for display
large). The two agree to within a fifth of a pixel per line, and using the exact
division keeps the promise the renderers are tested against: a line box is
`fontSize * lineHeight`, which is 64 pixels for `displayLarge`.

## Imports

`unibox_material` exports three names — `MaterialTypography`, `MaterialTypeRole`
and `MaterialCard` — and it **does not re-export `unibox_core`**. A file that also
imports Flutter can therefore import this package without a prefix; it still needs
one for the tree, as described in the
[core README](../unibox_core/README.md#beside-flutter).

## Testing

```shell
dart test
```

The suite holds every role to the specification's size, line box, tracking and
weight, checks that the table covers every role in order, and checks the two
properties the package relies on: a role is complete enough to reset what it does
not share, and it takes a theme colour without restating its geometry. For the
card it checks the defaults, that every one can be replaced, and that the node is
validated as the box it is. For the palette it checks the baseline schemes, that
every role is answered in both, and that `fromSeed` grows the scheme the algorithm
grows — every variant, both schemes and a contrast level either way — from one
colour. That a node extending `Box` renders on both targets is pinned by the
renderer suites, which is what lets the card exist without either of them knowing
its name.

## Scope

The type scale, the colour roles (written or grown from a seed), and ten
components. What is deliberately not here
is written on the class that lacks it, and it is all platform behaviour rather than a
value the model could carry:

| Left out | Why |
| --- | --- |
| the splash's second stage | Material fades a highlight under the press and adds a ripple on release; here one drop grows and fades |
| the floating label | an animation the model has no triggered timeline for |
| the caret, the selection and the focus ring | the platform draws them for the input node |
| modal entrance and exit transitions | the same missing timeline |
| `ColorScheme` and CSS custom properties | the two wirings an application owns. A palette *is* generated here (`MaterialPalette.fromSeed`), and installing it on the host stays the application's job |
| the icon font and its subset | a host asset: declared in `fonts:` or with an `@font-face`, and subset by the Flutter build |
| Material's breathing spinner | a rotating arc of a fixed sweep: a sweep that grows and shrinks needs a keyframe timeline |
| a `progressbar` role with its bounds | `BoxSemantics` has no progress role yet, so a ring announces its label as text |
| chips, menus, navigation | not built; each is a component, not a decision |

## License

MIT, like the rest of the workspace.

