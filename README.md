# Unibox

Declare a UI region once in pure Dart. Render it as HTML and CSS on the server,
and as Flutter widgets in the application.

Unibox is for the parts both surfaces need: cards, headings, listings, promotional
bands and footers. The application owns routing, data, state and page composition.
Maps, booking flows and other application interaction remain ordinary Flutter.

## Project status

Experimental and unpublished. Depend on one coherent commit across packages.
Breaking spellings are removed outright; read each package's Unreleased changelog.

## How it works

```dart
final region = Box(
  gap: 12,
  children: <UINode>[
    TextNode('Apartments', headingLevel: 1),
    LinkNode('/apartments', children: <UINode>[TextNode('See all')]),
  ],
);

final html = toHtml(region);       // unibox_html, on the server
final widget = region.toWidget(); // unibox_flutter, in the app
```

Keep declarations in a pure Dart library. Flutter hosts import core with a prefix
when its names overlap Flutter's. Core has no package dependencies. Collections
passed into nodes and tokens must remain unchanged after construction: use const
collections or unmodifiable snapshots.

## Flutter SEO

The server renders readable text, headings, image alternatives and real links.
`toDocument` supplies metadata through `DocumentHead`. URLs, copy, canonical
addresses, robots, deployment and indexing policy belong to the application.
An HTML document is useful without Flutter and does not need a browser renderer.

## The nodes

See [the node reference](docs/nodes/README.md) for parameters and target mappings.
The declaration vocabulary includes boxes, text, images, links, grids, stacks,
positioned children, pagers, fields, overlays and stateful region adapters.
Custom paths, rings and progress indicators are outside the vocabulary; supply
host-owned artwork or native interaction through embeds or substitutions.

## Styles, colours and typography

Flat parameters override style bags, which merge left to right. State styles
contribute their own tokens; disabled state wins. Defaults belong to the model,
not to browser or Flutter defaults. Typography and writing direction can inherit.

Colour roles resolve through a shared `UniboxScope` theme. Literal colours work
without a theme. A host supplies its fonts and assets. Read the
[core guide](packages/unibox_core/README.md) for defaults and precedence.

## Material

The optional Material vocabulary is deliberately small:

| Declaration or value | Purpose |
| --- | --- |
| `MaterialPalette`, scheme variants | Shared colour roles and seed-derived schemes |
| `MaterialTypography`, type roles | Shared type scale |
| `MaterialCard` | Content surface |
| `MaterialButton` | Native button variants and server actions/links |
| `MaterialChip` | Labels, filters and removable selections |
| `MaterialSegmentedButton` | A supplied selection or navigational destinations |
| `MaterialIcon`, `MaterialIconButton` | Registered glyphs and native icon actions |

Every component has a native Flutter substitution. Install `materialComponents()`
from `unibox_material_flutter`; omitting a required mapping reports an error.
Register const `IconData` values through its `icons` argument. There is no custom
Flutter Material fallback and no Material-owned application store or ink runtime.
The server still receives a useful declaration built from core nodes.

See the [Material guide](packages/unibox_material/README.md) and
[native mappings](packages/unibox_material_flutter/README.md).

## Substitution

The generic Flutter substitution map lets an application draw its own components
with native widgets. Core structure remains the declaration's; a substitution
preserves words, order, destinations, selection and actions. Native paint can
vary. Test real shared regions when a handover needs close layout agreement.

## Optional Flutter handover

Handover is the transition between renderings, not an application runtime.
Server helpers live in `package:unibox_html/handover.dart`, so the server does
not require Flutter. The Flutter host uses `package:unibox_flutter/handover.dart`.

```dart
// Server: opt into recording and a readiness-controlled transition.
final document = toDocument(
  region,
  takeover: const Takeover(boot: '/flutter_bootstrap.js'),
);
```

The application chooses when to boot and signals when the right route, data and
layout are ready. `FlutterHandover.complete(controller: pageController)` restores
the latest document offset to that explicit controller, reveals Flutter and
replays at most one intercepted keyed action. A custom restoration callback can
handle a different page composition. Direct Flutter entry needs no handover.

Normal browser links are followed normally. Only eligible actions intercepted
by handover can replay; keys must be stable and unique across the document.
Read [the handover contract](docs/takeover.md) before integrating mixed pages.

## What the host owns

The host owns page composition, breakpoints that require alternative structures,
application state, network requests, routing, fonts, native embeds, and readiness.
The optional stateful adapter manages a region's store lifecycle; it does not
provide an application router, data layer or browser application runtime.

## How the renderers stay in step

`unibox_testing` defines shared presentation expectations. HTML tests inspect
emitted output; Flutter tests inspect widgets and relevant geometry. Information
must agree. Platform text shaping and native component paint can differ.
Declaration tests do not replace rendered integration checks for real layouts.

## Packages

| Package | Responsibility |
| --- | --- |
| [unibox_core](packages/unibox_core/README.md) | Pure Dart declarations and tokens |
| [unibox_html](packages/unibox_html/README.md) | Server HTML/CSS and optional server handover helpers |
| [unibox_flutter](packages/unibox_flutter/README.md) | Flutter rendering, substitutions and optional handover |
| [unibox_material](packages/unibox_material/README.md) | Small optional Material declarations and values |
| [unibox_material_flutter](packages/unibox_material_flutter/README.md) | Native Material substitution map |
| [unibox_testing](packages/unibox_testing/README.md) | Test-only presentation and behaviour contracts |

## Development

Read [AGENTS.md](AGENTS.md), [design.md](design.md) and
[the implementation plan](docs/plan-focused-rendering.md).
Run `tool/verify.sh`; use `--docs` for public API or README changes.
Use `tool/scale.sh` and `tool/performance.sh` for the relevant performance checks.
See [the examples](example/README.md), [consumer instructions](AI_INSTRUCTIONS.md)
and [maintenance](MAINTENANCE.md). Releases remain a human procedure.
