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
  alignment and truncation.
- [`OverlayAppearance`](lib/src/overlay_appearance.dart) describes how an overlay
  is presented: the colour of its barrier and where its content sits.
- [`overlayCases`](lib/src/overlay_cases.dart) is the overlay table: one case per
  token, and one with both.
- [`textCases`](lib/src/text_cases.dart) is the text table: one case per token,
  one for the precedence of a `BoxTextStyle` and its flat overrides, and one with
  every token at once. It also holds `defaultTextAppearance`, the typography of a
  text node that declares nothing, which both renderers have to produce.

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
| the height of a line box                                          | `fontSize * lineHeight` on both: CSS multiplies the unitless `line-height`, `TextStyle.height` does the same |
| the layout of the boxes                                           | flexbox on one side, `Flex`/`Row`/`Column` on the other, with the same rules |
| the glyphs                                                        | **no**: Skia and the browser each rasterise text with their own engine |
| where a line wraps                                                | **no**: two engines measure the same string differently, so the break can fall elsewhere |
| a font family                                                     | only if the app ships the font to both hosts, which is why the model leaves that token out of its default |

Which is why a tree that has to be pixel-stable declares its `lineHeight` and
ships the same font file to both hosts. Do the two, and everything above the
glyphs is identical; leave the family out, and each platform uses its own UI font.

What stays approximate on purpose, and is therefore outside the contract
altogether: the font face, line breaking, shadow blur, placeholder and focus
colours, and hit testing.

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
