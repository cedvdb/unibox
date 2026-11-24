# HTML-to-Flutter handover

Handover is an optional bridge between renderings. It does not own routes, data,
application state or page composition. Server helpers are available through
`package:unibox_html/handover.dart`; Flutter helpers through
`package:unibox_flutter/handover.dart`. A server never depends on Flutter.

## Server configuration

Use `Takeover` with `toDocument` for a Unibox document. A mixed document can install
`uniboxClientScript` and `bootScript` itself. `hostId` identifies an existing direct
child of the document body. When omitted, the bridge creates a fixed viewport host.

```dart
final scripts = <String>[
  uniboxClientScript,
  bootScript(
    '/flutter_bootstrap.js',
    hostId: 'application',
    reveal: RevealPolicy.onReady,
  ),
];
```

The bridge exposes `window.unibox.hostElement` before loading the bundle. Pass it
as the engine configuration's `hostElement`, as the example bootstrap does. If no
`hostId` is supplied, the bridge creates a fixed viewport host. Embedding the engine
keeps it from resizing the document or resetting its scroll during startup; a
full-page engine would overwrite the position before the Flutter host can read it.
Reveal removes initial `inert` and `aria-hidden` markers. A direct Flutter launch
has no handover host and uses its normal engine configuration.

The host supplies the loader, start policy, accessible labels, optional CSP nonce
through `Takeover`, and whether developer comparison modes are permitted. Prefetch
is an optimisation, not permission to start the engine before the selected policy.

## Readiness and reveal

The document remains visible and usable while Flutter loads. Its engine layer is
hidden from interaction and accessibility. The transition proceeds from document
to booting, then app, or failed. Restoration occurs while the app is hidden.

`Takeover` defaults to explicit readiness. An engine first frame is not proof that
the intended route and data are ready. A stateful region does not signal readiness
on behalf of the host. If readiness never arrives before the configured timeout,
the bridge keeps the document rather than revealing an intermediate application.
Explicit `RevealPolicy.onFrame` remains available for hosts that want that policy.

The bridge moves focus into the application, announces the transition and retires
the document. If the bundle or readiness fails, the HTML remains the fallback.
Direct Flutter launches work without a document or browser bridge. The coordinator
keeps Flutter semantics enabled during handover; dispose it with its owning host to
release resources and cancel an unrevealed transition.

## Scroll restoration

The recorder tracks the latest document offset while the reader continues to
scroll during loading. Keyed internal scroll regions have separate offsets.
A page offset is never inferred from whichever Flutter scrollable happens to exist.

The host creates one `FlutterHandover` and calls it when routing, data and layout
are ready:

```dart
await handover.complete(controller: pageScrollController, root: context);
```

The destination must have exactly one attached, laid-out scroll position. The
bridge reads the latest document position, clamps it to that position's extent,
restores without animation, signals readiness and replays the pending intent.
Repeated completion calls share the same operation. Supply a `restore` callback
for custom page composition; it takes precedence over the controller. The raw
position is also available through `documentScrollFromPage()` for manual use.

The application chooses whether browser/history restoration or handover owns an
initial position. Do not run both competing restorations. Absolute offsets assume
close overall geometry; a future anchor strategy can handle measured drift.

Keyed region offsets can be read once through `scrollOffsetsFromPage()` and
supplied to `UniboxScrollScope`. They represent a region's internal scrolling,
not its position within the whole document.

## Press recording and replay

Only eligible clicks on declared application actions are intercepted. Ordinary
links keep browser navigation, downloads and modified/new-tab behaviour. Disabled,
ambiguous and unkeyed actions are not replay candidates. Recording is active only
when a handover has actually booted the application.

Keep one latest pending intent. The recorder cancels that click's browser action
and consumes its record once. Flutter resolves the same stable page-wide key and
uses the target's widget recogniser, including native Material controls. Missing,
ambiguous, disabled and offscreen targets are discarded. A delivered action is
not replayed by a subsequent rebuild.

String and integer keys must remain stable between renderings. Their document
spelling must be unique across the page, including sections supplied separately.
Sibling-local object keys are valid for widget identity but not handover identity.

## Mixed pages and host responsibilities

Unibox regions can sit beside host-rendered headers, maps and other content. The
host supplies the page controller and the readiness point because only it knows
how those regions compose. It must ensure matching content and close geometry,
and must not submit readiness from a stale or unmounted route.

Comover's integration configures the shared server bridge and registers the
catalogue's actual controller. Domain-specific loading decisions remain in its
route and screen code. Application-owned native surfaces remain its substitutions.

## Verification

Run HTML recording/boot tests and Flutter replay/handover tests. Verify the built
site with `tool/boot_check.sh` and `tool/doc_check.py`. Real application acceptance
includes scrolling during load, pressing an action before readiness, normal link
navigation, slow/failed boot, narrow/wide geometry and accessible focus transfer.
