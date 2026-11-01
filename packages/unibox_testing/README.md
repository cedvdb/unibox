# unibox_testing

**Test only.** Nothing in this package ships: it is a `dev_dependency` of the two
renderers, it is not published (`publish_to: none`), and an application never
depends on it.

The presentation contract both Unibox renderers are tested against.

The renderers produce different kinds of output — a widget tree on one side,
HTML and CSS on the other — so the only thing that can be compared is what the
output *does* with the same node. This package writes that down once:

- [`BoxAppearance`](lib/src/appearance.dart) describes how a box is presented:
  the axis it lays its children out on, its alignment, gap, padding, margin,
  size, background, corner radius and border.
- [`boxCases`](lib/src/cases.dart) is the box table a renderer is checked
  against: one case per token, and one with every token at once.
- [`TextAppearance`](lib/src/text_appearance.dart) describes how a text node is
  typeset: font size, weight, colour, line height, letter spacing, family,
  decoration, alignment and truncation.
- [`GridAppearance`](lib/src/grid_appearance.dart) describes how a grid placed its
  children: the number of tracks each one occupies.
- [`gridCases`](lib/src/grid_cases.dart) is the grid table: a grid of plain cards,
  one with a banner across two tracks, and one whose span is wider than the column
  count. A case states the width it is laid out at, because a span is counted in
  tracks and the count comes from the width.
- [`OverlayAppearance`](lib/src/overlay_appearance.dart) describes how an overlay
  is presented: the colour of its barrier, where its content sits, and that the
  layer bounds the content and scrolls what does not fit.
- [`overlayCases`](lib/src/overlay_cases.dart) is the overlay table: one case per
  token, and one with both.
- [`textCases`](lib/src/text_cases.dart) is the text table: one case per token,
  one for the precedence of a `BoxTextStyle` and its flat overrides, and one with
  every token at once. It also holds `defaultTextAppearance`, the typography of a
  text node that declares nothing, which both renderers have to produce.
- [`BehaviourCase`](lib/src/behaviour.dart) is the other half of the contract: a
  component, the steps a reader takes against it — a press on a node by key, or the
  component drawn again with other parameters — and the text the page has to show at
  each key afterwards. Appearance describes one drawing; a state is what only a store
  can change, and it is the half a component is most likely to get wrong.
- [`behaviourCases`](lib/src/behaviour_cases.dart) is that table: a press that
  publishes and redraws the page, and a store reconciled with the node drawn in its
  place after its parameter changed.

The package holds the contract, not the tests. A renderer suite renders each
case, reads the appearance back from its own output and compares it with the
expected one:

```dart
for (final TextCase textCase in textCases) {
  render(textCase.node);

  expect(
    textAppearanceOf().differencesFrom(textCase.expected),
    isEmpty,
    reason: textCase.description,
  );
}
```

`unibox_flutter` reads the appearance out of the widgets its renderer built,
`unibox_html` out of the CSS it emitted. Neither reads the node tree, so a
renderer that drops a token fails its own suite instead of drifting away from
the other one — and because both are checked against the same entry, the answer
cannot be relaxed for one target without failing the other.

## Behaviour

A tree that only ever shows the state it started with is half a component, and the
other half is not a presentation: no token says which tab a press chooses, or that a
store reconciled itself with the node drawn over it. So a [`BehaviourCase`](lib/src/behaviour.dart)
writes that down too, in the same table-over-outputs shape:

```dart
BehaviourCase(
  description: 'draws the tree of the state a press published',
  tree: _Counter(),
  steps: <BehaviourStep>[
    BehaviourStep.press('raise', <Object, String>{'count': '1'}),
    BehaviourStep.press('raise', <Object, String>{'count': '2'}),
  ],
)
```

A step is an intent and the text it has to produce, by key: `press` a node the tree
draws, or `redraw` the component with a node whose parameters changed. A suite plays
the table with its own three moves — `draw` a tree, `press` a key, read `textAt` a
key — and `behaviourDifferences` returns every disagreement rather than failing, so
the suite owns the assertion. `unibox_flutter` pumps and taps a widget tree,
`unibox_dom` mounts and clicks a page.

Behaviour cases are not per token, so they do not belong beside the appearance tables
one to one: a case is worth writing when a component's *state* is what a renderer
could get wrong, and the two cases here are the two rules every renderer owes —
a publish redraws the page, and a store drawn again is reconciled with the node that
drew it. A component with a table of its own, in `unibox_material`, is still tested
against its own store in a plain `dart test`: `BehaviourRun` mounts it headlessly with
no renderer at all, which is also the cheapest way to check an application's page
logic.

```dart
expect(await playBehaviour(behaviourCase), isEmpty);
```

## How close is close

Passing both tables means the two renderers ask their host to draw the same
thing. It does not mean the hosts draw the same pixels, and nothing here claims
it does. The line runs between what a renderer *declares* and what a text engine
*makes of it*:

| Same                                                              | Why |
| ----------------------------------------------------------------- | --- |
| the tokens a node declares                                        | one table, read back from each output |
| the typography nobody declares                                    | yes: `BoxTextStyle.defaults` is the model's, and both renderers install it at the root — a `DefaultTextStyle` around the widget tree, a `:root` rule on the page |
| an opacity, and a transform in its parts                          | yes: `Opacity`/`transform` on the web, `Opacity`/`Transform` (read back out of the matrix) in Flutter |
| a transition: its duration and its curve                          | yes: one `BoxTransition` becomes a CSS `transition` on the paint properties and an implicit animation of the decoration in Flutter |
| the height of a line box, and where the glyphs sit in it               | both compute the height the same way — CSS multiplies the unitless `line-height`, `TextStyle.height` does the same — and both put the glyphs in it by half-leading: the extra height is split evenly above and below them, so the baseline lands in the same place too |
| the layout of the boxes                                           | flexbox on one side, `Flex`/`Row`/`Column` on the other, with the same rules |
| the glyphs                                                        | **no**: Skia and the browser each rasterise text with their own engine |
| where a line wraps                                                | **no**: two engines measure the same string differently, so the break can fall elsewhere |
| a font family                                                     | only if the app ships the font to both hosts, which is why the model leaves that token out of its default |

Which is why a tree that has to be pixel-stable declares its `lineHeight` and
ships the same font file to both hosts. Do the two, and everything above the
glyphs is identical; leave the family out, and each platform uses its own UI font.

What stays approximate on purpose, and is therefore outside the contract
altogether: the font face, line breaking, how a blur is rasterised, placeholder and
focus colours, and hit testing.

One layout fact sits at that edge rather than in the table: a child of a
baseline-aligned row that holds no text reports no baseline, and the two engines
then fall back differently — Flutter tops the child out, a browser uses its bottom
edge. The alignment itself is in the table, because both outputs declare it; what
each host does with a child that has nothing to align is where the two stop
agreeing, so a row that aligns on the baseline is a row of text.

An overlay's bound is at the same edge. `OverlayAppearance.scrolls` is in the table
because both outputs say it — `overflow: auto` on the layer, a scroll view between
the layer and the content — but the height it produces is a measurement, and a
string renderer emits markup rather than a laid-out page. Each renderer suite pins
the measurement instead: `packages/unibox_dom/test/overlay_test.dart` mounts a
dialog taller than the browser window and reads the content's box back out of the
document, and `packages/unibox_flutter/test/overlay_widget_test.dart` pumps one into
a fixed surface and drags it. A difference there is a card drawn at a different
height, which is how the drift was found.

The geometry of a `BoxShape` is not in the table either, for a different reason: it
is exact on both targets, but it is *not a fact one rendering can read back and the
other state*. Flutter paints a `Path` and the web writes a `d` attribute, so there
is no third thing to compare them against — they are the same description, not two
measurements of one look. Each renderer suite pins it instead: `pathOf` against the
bounds and the containment of a known shape, the `d` against the commands. A
difference there shows up as a changed path, which is a louder failure than a
drifted colour.

One combination inside the model has no exact counterpart, which is why it is not
in the table: `maxLines` with `TextOverflow.clip`. Flutter cuts the text off after
the last line; a `-webkit-line-clamp` box always ends it with an ellipsis, and
`text-overflow: clip` does not take the ellipsis away (checked in Chrome, not
assumed). An application that needs the two to agree uses `maxLines` with
`TextOverflow.ellipsis`.

## Testing

```shell
dart test
```

The suite checks the tables themselves: that the plain box and the plain text are
the first cases, that every other case changes its presentation, that every token
of a node appears in the "every token at once" case, and that a comparison names
the token that drifted.

## License

MIT, like the rest of the workspace.
