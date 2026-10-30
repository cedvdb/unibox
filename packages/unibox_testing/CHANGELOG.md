# Changelog

## Unreleased

- A case for `CrossAlign.baseline`, read back from the flex on one side and from
  `align-items: baseline` on the other, so a renderer that drops the baseline fails its
  own suite. The `README` records the one thing the table cannot hold: a child of a
  baseline aligned row that holds no text has no baseline to align, and the two engines
  fall back differently.

- `GridAppearance` and `gridCases`: the tracks each child of a grid ends up in, read
  out of each renderer's output, so a renderer that drops a `gridSpan` — or counts it
  as one slot and leaves the rest empty — fails its own suite.

- `TextAppearance.decoration` and `decorationColor`, with a case that strikes a price
  through and one that underlines a run in a colour of its own, both read back from
  each renderer's output.

- A case that typesets a label at `FontWeight.light`, and `300` read back as that
  weight on both sides of the table, so the two renderers are held to the light end
  of the scale.

## 0.1.0

- `BoxAppearance.corners` and a case that rounds two corners, so the four radii are
  compared the way every other token is.

The first release of the presentation contract: **test only**, a `dev_dependency`
of the two renderers and never something an application installs.

- `BoxAppearance` and `boxCases`: the appearance a rendered box has to produce —
  direction, alignment, gap, padding, margin, size, background, radius, border,
  opacity, transform and the transition's duration and curve — one case per token,
  one for composed style bags, and one with every token at once.
- `TextAppearance`, `textCases` and `defaultTextAppearance`: the typography a rendered
  text node has to be given — size, weight, colour, line height, letter spacing,
  family, alignment and truncation — plus the model's default for a text that
  declares nothing.
- `TokenDifference` and `differencesFrom`, which compare two appearances token by
  token and name the ones that drifted, so a failure says which token moved instead
  of printing two objects side by side.
- The suite checks the tables themselves: no two cases expect the same presentation,
  every token appears in the "every token at once" case, and the default text
  appearance matches the model's own defaults.
