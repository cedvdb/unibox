# Changelog

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
