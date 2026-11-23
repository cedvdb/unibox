# unibox_material_flutter

Draws [`unibox_material`](../unibox_material)'s components with Flutter's own widgets, for an
application that asks for it.

## Project status

**The standard rendering for a Flutter host.** A document is served first and the application
takes it over, so what a reader uses for the rest of the session should be Flutter's own
widgets: a host passes `substitutions: materialComponents()` and `materialThemeData(palette,
density: …)` with its scope, and never mentions a component again. That is the recommended
wiring, not a demo.

**Still experimental in one way.** The project's status is the root
[README's](../../README.md#project-status) — unpublished, `publish_to: none`, an addition is minor
and a rename is made outright. This package is younger than that paragraph: it is the one door
that trades pixel parity for the platform's behaviour, it maps two components today, and the
`materialComponents()` signature may move while the rest of the model settles. Depend on a
commit rather than a version, and read this package's `## Unreleased` before you move it forward.

**The rule is settled; this package is the first draft of it.** `design.md` §5.22 states what a
substitution may and may not change. What is not settled is how far it should go — whether the
ink, the tabs and the fields follow, whether a takeover screen may ever use one, and what a
`compare` run actually shows when a card is a `Card`. Those are open questions, not documented
behaviour.

```dart
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

Widget widget = renderFlutter(
  page,
  scope: UniboxScope(theme: palette),
  substitutions: materialComponents(),
);
```

That is the whole API. One map, one call, and a card is a `Card` and a bar is a
`NavigationBar` — without this package both are boxes built from the design system's values.

## Why it exists

A tree describes a screen for two renderers, and by default both draw the model's values:
that is what keeps a page and an application the same screen, to the pixel the conformance
table holds them to.

A *component* is where that promise costs the application something a token cannot pay back.
`Card`, `NavigationBar` and the rest carry behaviour their look does not describe — the
platform's ink, the click and the haptic on a press, the reader's text scale growing the
control with it, `disableAnimations`, the tap-target minimum, and a decade of accessibility
work — and none of it reaches a box that re-derives the look from tokens. This package is
the door: the application keeps its widgets, and the model keeps the layout, the structure and
the content.

## What it may and may not change

| Kept by the tree | The widget's |
| --- | --- |
| the children and their order, the layout, the gap and the alignment | the surface: fill, radius, border, shadow |
| the words, the links, the semantics and the roles | the ink, the feedback, the animation curves |
| where the component sits, the room it takes, its margin | the text scale and the platform's own answers |

A substitution may change the paint. It may not change the information. A page and an
application that disagree about content were never the same screen, so a component here is
built from the node it was given: a `MaterialButton` keeps its `label` and its `onPressed`
precisely so this package can hand them to a `FilledButton` unchanged.

## What it costs

**The pixel, and the bill arrives at the takeover.** `Card` spends its elevation through
`drawShadow`, whose ladder is not the one `MaterialElevation` measured, and `NavigationBar`
states its indicator's size internally. A substituted component can therefore lay out
differently from the document that was on screen — the one thing a takeover reveal promises
not to do. So the rule is per screen and checkable: **a takeover screen may only use
components whose two renderings agree.** A screen that does not is served as a document with
no Flutter on it, or held to `?unibox=compare` in the example.

**The components the map names.** `MaterialCard`, `MaterialButton` (all four shapes),
`MaterialChip`, `MaterialIcon`, `MaterialIconButton`, `MaterialProgressRing`, `MaterialListTile`
and `MaterialSpinner`.

**An icon needs the host's list.** `materialComponents(icons:)` takes the `IconData` values the
application already names, because `flutter build` keeps a glyph only while a constant `IconData`
for it is part of the program and refuses to subset the icon fonts when one is built at run time —
a codepoint read out of an icon (`Icons.sell.codePoint`) is folded to an integer and dropped. A
glyph the list does not name is drawn as the character it is, from the node's own font family. A type it does not name is drawn from the values, exactly as before, so
the map can arrive one component at a time — and `UniboxSubstitutions` refuses the structural
nodes (`Box`, `TextNode`, a stack, a grid, a link, a field) by construction, so it cannot become
a second renderer.

## Dependencies

It depends on `unibox_core`, `unibox_flutter` and `unibox_material`, and nothing depends on
it: a renderer knows nothing of a design system, and a design system knows nothing of a
renderer. It is pure Dart and Flutter, with no Material widget layer of its own.

## Where to look at it

The example has a page whose subject is this comparison: `/flutter/components/` draws the
Material catalogue — `buildMaterialSection`, the section the site closes on, so there is one
description of it — twice, side by side: once from the design system's values, which is what the
document at `web/components/` is served, and once with `materialComponents()`. The captions say
which is which, and the page wants a desktop window: at 1920 each half is 960 wide, which is what
the catalogue's demos need. No address parameter, and the pages held to each other — the
listings and the site — carry no switch at all.

