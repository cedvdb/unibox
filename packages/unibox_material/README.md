# unibox_material

Optional Material colour and typography values, and a small set of declarations
that render as server HTML and native Flutter components.

## Supported vocabulary

| Declaration | Native Flutter substitution |
| --- | --- |
| `MaterialCard` | `Card` |
| `MaterialButton` | `FilledButton`, tonal, outlined and text variants |
| `MaterialChip` | `InputChip` or `FilterChip` |
| `MaterialSegmentedButton` | `SegmentedButton<int>` |
| `MaterialIcon` | `Icon` with host-registered const `IconData` |
| `MaterialIconButton` | `IconButton` with an optional native badge |

`MaterialPalette`, `MaterialSchemeVariant`, `MaterialTypography` and
`MaterialTypeRole` are values rather than controls. Elevation and density values
support the retained components. No application state is owned by these controls.

## Flutter rendering

Install `materialComponents()` from `unibox_material_flutter` on the renderer.
A required mapping that is missing is reported; there is no custom Material
widget fallback. Hosts register their icon constants with the map, preserving
font tree shaking and the glyph's native widget implementation.

## Server rendering

Components are core-node declarations. HTML renders content, appearance, accessible
selection and real destinations. Application callbacks run only in Flutter after
handover; the server does not attach JavaScript interaction or run a store.

## Application-owned components

Scaffolds, app bars, navigation bars, tabs, fields, dialogs, sheets, ink surfaces
and progress indicators belong to the application. Compose shared regions from
core declarations and use generic Flutter substitutions when a native surface is
needed. Paths and drawn rings are not core tokens.

## Validation

The declaration tests cover supplied state and content. The native mapping suite
covers widget presence, selection, disabled state and actions. Shared primitive
appearance remains the responsibility of `unibox_testing`.
