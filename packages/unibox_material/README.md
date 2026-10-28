# unibox_material

Material Design 3 for Unibox: the type scale, the colour roles and the components
built from them.

This package is pure Dart: it depends on `unibox_core` and nothing else. It does
not import Flutter, `dart:ui` or Material, so the same scale is available to a
Flutter app, a Jaspr page and a command line tool that only builds a tree.

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
renderJaspr(page, theme: MaterialPalette.lightTheme);
renderFlutter(page, theme: MaterialPalette.lightTheme);
```

| Role | What Material paints with it |
| --- | --- |
| `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer` | an accent and the text on it |
| `secondary`, `onSecondary`, `secondaryContainer`, `onSecondaryContainer` | the quieter accent a chosen control wears |
| `surface`, `onSurface`, `onSurfaceVariant` | the page, its text, and its lower emphasis text |
| `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainerHigh`, `surfaceContainerHighest` | the tones a card, a dialog and a filled field sit at |
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
`unibox_core` alone and never imports Flutter, so the two wirings that make the
values reach a `ColorScheme` and a page's CSS are the application's — which is also
what keeps the tree and any embedded Material widget in step.

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
| padding | `16` on every edge | the room Material gives card content |
| background | `BoxColors.white` | the surface, until a colour scheme exists |
| radius | `12` | the medium shape of Material 3 |
| shadow | `MaterialCard.elevatedShadow` — `MaterialElevation.level1` | elevation level one, one of its two layers |
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

The layout and interaction of a box come through too — `direction`, `gap`,
`width`, `flex`, `onTap`, `stateStyles`, `semantics`, ... — so a clickable card
states `onTap` and its role, not a wrapper component. What the card does not
expose is a style bag: its own tokens are flat parameters, so a bag would lose to
them. A `Box` around it is the escape hatch, and it is the box this class builds.

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
is what is wanted, and the fill takes exactly that.

Shape and states are Material's: a radius of 20 (a full round on a 40 pixel height —
`labelLarge`'s 20 pixel line plus ten above and below), 20 by 10 of room on the three
filled shapes and 12 by 8 on the text one, and the button role whenever the button can
be tapped, so it is focusable and activates on `Enter` and `Space`. `enabled: false`
takes the ink away and leaves the button in place.

An `icon` puts a node before the label, eight pixels away; `ink`, `borderRadius`,
`padding` and `labelStyle` are parameters when a screen needs to differ.

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

The ripple is **state, not a renderer feature**. A press adds a drop to a
`MaterialInkStore`, a timer advances it every frame, and the view draws one box per
drop — a circle centred on the press, growing as it fades. Both targets therefore
draw the ink out of nodes they already draw, which is why the conformance table
needs no case for it: there is no second implementation to hold in step. A page
rendered without a client runtime subscribes to nothing, so it shows the resting
well, and a region that cannot be pressed listens to no pointer at all.

It paints **no surface of its own**: the tints and the ink have to sit above the
fill they belong to, so the filled box goes around the ink well. Wrapped the other
way round the fill would hide both. The well clips its own content to
`borderRadius`, which is what keeps a drop inside a rounded button, and `ink` is the
one colour that is not a role — the ink has to contrast with the fill around the
well, which the well cannot see.

What it is not is a timeline the host owns: the ink is a state machine and a timer,
so a press costs a rebuild of one subtree per frame for 450ms. On the web that is
visible in the sheet — a frame's circle is a look of its own — and it is why a drop
moves by `transform` rather than by the offsets of the node that holds it: one rule
per frame instead of two, measured at 30 rules for one press against 58 before.
`EmbedNode` remains the escape hatch when a host-side animation is what the effect
needs.

## The segmented button

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
| height, radius | 40, and 20: a full round |
| container | a 1 pixel `outline` line, `overflow: hidden` so a chosen fill is cut to the rounded ends it reaches |
| chosen | a `secondaryContainer` fill, an `onSecondaryContainer` label, a check, and `selected` for a screen reader |
| check | 18 pixels, a `MaterialCheckMark`, in place of the chosen segment's icon; `showSelectedIcon: false` keeps the icon |
| icon | `iconSize` = 18, 8 from the label and 12 from the segment's edge |
| label | `labelLarge`, `onSurface` or `onSecondaryContainer` |
| dividers | a 1 pixel box the colour of the outline between two segments |
| width | equal shares: every segment is `flex: 1` |
| disabled | the whole control at 38%, with no ink on any segment |

The container is one box and each segment is a box around a `MaterialInkWell`, so the
tint and the ink cover the segment rather than its label, and the container's clip
keeps them inside the pill. The well's content is centred and its stack stretches —
that is what the well's `mainAlign` and `crossAlign` are for, and why a segment can
say `width: double.infinity` and mean it on both targets.

A chosen segment draws an 18 pixel check in place of its icon, which is what Material
does, so a control of pictures still says which one is on. The check is a
`MaterialCheckMark` — two rotated bars with Material's own weight, because an icon font
is a host asset and this package ships none — and `showSelectedIcon: false` leaves the
icon where it is for a control whose fill is enough.

**What stays approximate.** The container is not a `radiogroup`, because `BoxSemantics`
has no group role: every segment is a button that says whether it is the chosen one. A
disabled control fades as one at 38% rather than drawing `onSurface` at 12% under a 38%
label, which would need an alpha role per token.

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
in the fill focuses the field.

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
| height | `controlHeight` = 32, stated rather than left to the line, so an 18 pixel glyph does not make one chip taller than another |
| radius | 8, the small shape of Material 3 |
| unselected | no fill, a 1 pixel `outline` line, `onSurfaceVariant` label |
| selected | `secondaryContainer` fill, no line, `onSecondaryContainer` label |
| room | 16 on a side the label reaches, 8 on a side a node sits (`iconSize` = 18), 8 between them — Material pads the side, not the chip |
| label | `labelLarge`, `onSurfaceVariant` or `onSecondaryContainer` |
| hover, focus, press | `hoverLayer`, `focusLayer`, `pressedLayer` over the pill |
| disabled | the pill at 38%, with no ink: Material draws the label at 38% and the line at 12%, and one opacity is what this model can say without an alpha role per token |
| leading, trailing | a node before and after the label — a check, a folder, a cross |
| onRemove | an 18 pixel round target inside the pill: a press on it removes the chip, not the choice |

It is a `Box` around a `MaterialInkWell`, like `MaterialButton`, and the padding is
**the well's alone**: one node carries the room inside the chip, so the tint of a
hover reaches exactly the edge of the pill. Two paddings — one on the well and one on
a box inside it — is what made a hand-built chip tint 14 pixels past itself. The well
clips to the radius, so the ink of a press stays inside too.

A chip is a control: it announces itself as a button when it can be pressed, and says
whether it is chosen, which is a state a screen reader hears rather than a colour.

**What stays approximate.** Material gives a 32 pixel chip a 48 pixel touch target by
padding the shape invisibly, and this model has no invisible padding — a chip's target
is the chip. A chosen filter chip also shows a check mark in Material; here the check is
`leading`, because a chip carries whatever node the caller gives it. `MaterialCheckMark`
is the one to pass, and it is what the example passes: the mark is drawn from boxes, so
it needs no font and looks like Material's own.

`leading` and `trailing` take a node each, and `onRemove` turns the chip into an input
chip: the trailing node is wrapped in a round well of its own, so a press on the cross
removes the chip instead of choosing it. That well centres its node on both axes — a
well is a column, and a cross pinned to its start would leave the ring of a hover four
pixels off the cross it belongs to. The glyph itself is the caller's — a folder and a
cross come from a font, and a font is a host asset this package does not ship.
`MaterialIcon` is the way in when an application has one; the example draws its four
glyphs from boxes instead.

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

Material's modal entrance and exit transitions are not here, and the sheet's four
corners are rounded because the model has one radius per box.

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
what is chosen through its own `selected`.

## Elevation

Material states five levels for a raised surface, and each is two shadow layers; a
`BoxShadow` is one, so `MaterialElevation` holds the wide, soft layer of each — the
one that reads as height — in one place:

| Level | Shadow | Material gives it to |
| --- | --- | --- |
| `level1` | 0 1px 3px at 15% | a card, a sheet, a raised button |
| `level2` | 0 2px 6px | a card under the pointer |
| `level3` | 0 4px 8px | a dialog, a date picker, a floating action button |
| `level4` | 0 6px 10px | a drawer as it opens |
| `level5` | 0 8px 12px | the highest surface Material states |
| `sheet` | 0 -1px 3px | level one, cast upwards: a sheet rises from the bottom edge |

A component names the level it rests at rather than writing a shadow, which is what
keeps `MaterialCard`, `MaterialDialog` and `MaterialBottomSheet` in step: an app that
replaces one level replaces it on every surface that uses it. How a shadow is
*blurred* is outside the parity contract — a browser and Skia rasterise it
differently — so a level states the shape of the shadow, not a pixel promise.

## Fidelity

What the components state against the Material 3 specification: a card in its three
variants (`MaterialCard.elevated`, `.filled`, `.outlined`), each taking the card's
whole parameter list as Flutter's `Card` does; a list tile with the 8
pixel vertical padding and the palette's title, supporting text and state layers; a
text field at least 56 pixels tall with a 2 pixel focused outline, a primary focused
label, an `onSurface` hover outline and 38% opacity when disabled; a dialog whose
content is `bodyMedium` in `onSurfaceVariant` over `labelLarge` actions in `primary`;
and a bottom sheet that fills the width up to 640 pixels, with a drag handle and a
shadow that rises. Still approximate: the sheet rounds all four corners, the handle
is not draggable, shadows are one layer where Material has two, and the ink is one
circle that grows and fades where Material draws a splash with a fading highlight
and a second ripple when the press is released.

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
validated as the box it is. That a node extending `Box` renders on both targets is
pinned by the renderer suites, which is what lets the card exist without either of
them knowing its name.

## Scope

The type scale, the colour roles, and ten components. What is deliberately not here
is written on the class that lacks it, and it is all platform behaviour rather than a
value the model could carry:

| Left out | Why |
| --- | --- |
| the splash's second stage | Material fades a highlight under the press and adds a ripple on release; here one drop grows and fades |
| the floating label | an animation the model has no triggered timeline for |
| the caret, the selection and the focus ring | the platform draws them for the input node |
| modal entrance and exit transitions | the same missing timeline |
| `ColorScheme`, CSS custom properties, dynamic colour | the two wirings an application owns, described in Task 96 of `TASK_PLAN.md` |
| the icon font and its subset | a host asset: declared in `fonts:` or with an `@font-face`, and subset by the Flutter build |
| chips, menus, navigation | not built; each is a component, not a decision |

## License

MIT, like the rest of the workspace.

