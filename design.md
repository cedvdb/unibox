# Design

## 1. Purpose

Unibox is a UI declaration that can be rendered as server HTML/CSS or as Flutter
widgets. It shares regions rather than owning application screens. Searchable
content and application content should come from the same declaration, avoiding
two descriptions that drift whenever wording or design changes.

A card, footer, heading or list is a suitable region. Maps, booking workflows,
routing and asynchronous data ownership remain with the application. The model
does not attempt to reproduce Flutter or a browser application framework.

## 2. Dependency boundaries

- `unibox_core` has no package dependencies and no platform imports.
- `unibox_html` depends on core and produces documents and fragments.
- `unibox_flutter` depends on core and Flutter and produces widgets.
- `unibox_testing` holds shared test expectations and never ships with an app.
- `unibox_material` holds optional values and declarations built from core nodes.
- `unibox_material_flutter` knows both the Material declarations and Flutter and
  supplies native substitutions. Generic renderers know nothing of Material.

There is no DOM application runtime. HTML planning and CSS emission are internal
rendering mechanisms, not a browser state/reconciliation layer.

## 3. Rendering

Core nodes are descriptions; targets implement them independently. The HTML
pipeline plans elements and their stylesheet, then writes markup through one
escaping boundary. Flutter builds widgets through its dispatcher and layout
implementations. Neither target wraps the other.

Defaults are model values. A missing direction means a column on both targets;
missing typography uses the model's scale. Platform defaults must not silently
change the declared presentation.

## 4. Optional handover

Handover belongs to the boundary between renderings. Server helpers live in the
HTML package and Flutter coordination lives in the Flutter package, behind optional
handover entry points. A server must not require the Flutter SDK to configure it.

The host chooses when to start Flutter and when the intended route, data and
layout are ready. The bridge keeps HTML visible, captures position and intercepted
intent, restores to a host-supplied scroll controller or callback, reveals the app,
transfers focus and replays one pending keyed press. A first frame is not content
readiness. Failed startup or readiness retains the document.

See [the handover contract](docs/takeover.md) for focus, recording, fallback and
mixed-page responsibilities.

## 5. API conventions

### 5.1 Naming

Core structural nodes use the `Node` suffix except `Box`: `TextNode`, `ImageNode`,
`LinkNode`, `GridNode`, `StackNode`, `PositionedNode`, `PagerNode`, `TextInputNode`,
`StatefulNode`, `OverlayNode`, `EmbedNode`. Component names belong to their design
system. Tokens use the `Box` prefix and enum identifiers use ordinary type names.
Renderer widget names use `Flutter`. Renderers do not re-export core; Flutter
hosts prefix core imports where identifiers overlap platform names.

### 5.2 Precedence

Style bags merge left to right. Flat node parameters overlay the bags. State styles
overlay the resting style; disabled state wins over other states. Typography and
writing direction may inherit. Other layout and paint values do not inherit.
An unspecified value is decided by the model, rather than the ambient host.

### 5.3 Dimensions

Numbers are logical pixels, emitted as CSS pixels. Infinite dimensions fill the
available extent, which must be bounded. Parent fractions, viewport fractions,
aspect ratios and maximum sizes express distinct constraints. Finite sizes and
caps can bound descendants even inside an otherwise unbounded scroll axis.
A capped fill must yield to its parent's available space and retain its alignment
when the parent is wider than the cap.

### 5.4 Parity

Content, order, destinations and accessible meaning must agree. Primitives share
a presentation table; native component paint may differ where the platforms do.
Typography tokens and spacing are decisions; font rasterisation and line breaking
belong to the engines. Do not promise pixel identity or infer rendered geometry
merely because CSS declarations and widget parameters agree.

A new presentational token needs an isolated case and the all-token case, plus
output readers on both targets. Geometry, scroll and behaviour that cannot be
read from that table need renderer-level tests. Unsupported constructs belong in
validation or in a documented platform approximation, never a silent fallback.

### 5.5 Interaction

Flutter binds supplied callbacks. Server HTML is a snapshot with no application
event runtime. A destination is a real link. Controls retain declared accessible
roles and enabled/selected state. Platform chrome must not add an accidental
second appearance to core primitives; native substitutions deliberately use the
platform's control behaviour.

Handover records only intercepted actions with stable, page-wide keys. Normal
browser links and modified clicks keep their browser behaviour. A pending intent
is consumed once, after the application has actually been revealed.

### 5.6 Non-goals

Unibox does not own application routes, networking, data stores, deployment or
SEO policy. It provides no client DOM application, generic path/vector API,
custom Material ripple engine or progress-ring subsystem. Hosts supply artwork,
native indicators and complex interaction through embeds or substitutions.

### 5.7 Compatibility

Packages remain experimental and unpublished until a human release procedure.
Breaking names are removed outright rather than kept as deprecated forwarders.
Consumers must resolve a coherent revision across packages. Do not bump versions
or change SDK pins as part of an implementation convenience.

### 5.8 Immutable declarations

Nodes and tokens retain const-compatible constructors. Collection arguments remain
caller-owned and must not be mutated after construction. Use const collections or
unmodifiable snapshots when their source can change. Equality and hashing of value
tokens must agree by value, including collection contents used by caches.

### 5.9 Design systems

A design system is values plus components built from existing core nodes. The
small Material vocabulary is palette, typography, card, button, chip, segmented
control, codepoint icon and icon button, with supporting density/elevation values.
Every retained Material component requires a native Flutter substitution. Having
a native mapping is necessary but does not justify an unbounded catalogue.
Application-specific components belong to the application.

### 5.10 Themes and assets

Colour roles resolve through a host-supplied theme; a missing role is reported.
Fonts, image files and icon assets belong to the host. Codepoint icons require
matching const `IconData` registration in the native Material mapping; do not
replace an unregistered glyph with an approximate text renderer.

### 5.11 Validation

Validate constructs that cannot honour the declaration on both targets. A validator
must also accept valid bounded descendants: an outer scroll axis does not invalidate
a filling child inside a finite box. Validation is not a substitute for renderer tests.

### 5.12 State

Applications own state and rebuild declarations when it changes. The existing
optional `StatefulNode`/store adapter remains a bounded region lifecycle facility:
create, mount, subscribe, reconcile and dispose. It introduces no router or data
layer and is not used to reimplement Material controls. HTML reads a snapshot and
does not start store side effects. A store's copied parameters reconcile in `update`.

### 5.13 Semantics

Headings, landmarks, accessible names, selection and disabled state are information.
A document and a native substitution must preserve them. Decorative content should
not become an extra target or accessible name.

### 5.14 Embeds

An embed explicitly hands an implementation to a host for a region the declaration
does not describe. It is outside primitive appearance parity. Raw HTML embeds are
trusted host markup; ordinary text, URLs and style strings remain escaped values.

### 5.15 Motion

State transitions ease declared paint values. Scroll effects that remain in core
must not turn application state into a browser runtime. Document reduced-motion
and unsupported-engine behaviour explicitly. Removed paths have no transition API.

### 5.16 Pagers and scrolling

Scroll positions and page selection are supplied or exposed to the host. Handover's
page offset is distinct from a keyed region's internal offset. Never guess which
Flutter scrollable corresponds to the whole document.

### 5.17 Overlays

The generic overlay node remains available for declared region presentation.
Application flow and opening/closing policy belong to host state. Removed Material
dialog and sheet wrappers do not require removing the generic primitive.

### 5.18 Responsive regions

Visibility thresholds can select a declaration's alternate fragments. The host
owns responsive page composition that needs different structures or native layouts.
Hidden and absent content must take the same layout space: none.

### 5.19 Native density

The host supplies platform density when the retained design system needs it.
Density does not give the declaration permission to read a platform runtime.

### 5.20 Text

The model owns default typography, inheritance and decoration semantics. Absolute
text-decoration thickness is a documented approximation in Flutter, whose native
API expresses a font-relative multiplier. Input caret, selection, text shaping and
font availability remain platform responsibilities.

### 5.21 Grids

A grid owns its tracks. Spans are clamped to the available columns; a whole-row
span remains a whole row at every width. Explicit column factors divide bounded
space or the measured intrinsic extent according to the same declared rule.

### 5.22 Native substitutions

Substitutions are keyed by exact component type. Structural primitives cannot be
replaced wholesale. A builder receives the declaration and its rendered content;
whole native controls may consume the component's retained parameters instead.
Content, order, destinations, accessible meaning and actions must survive.

A component can require a native widget substitution without importing Flutter.
The generic renderer reports a missing required mapping. HTML still renders its
core declaration. Native paint differences must be explicit, and shared regions
used during handover need real layout checks at representative sizes.
