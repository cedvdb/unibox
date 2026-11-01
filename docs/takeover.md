# The takeover: a bootstrap we own, and a handover that waits

**Status: landed.** The design below is what shipped, in the order §10 gives; what the
implementation changed about it is recorded in §11. Nothing here is a proposal any more.

A page can be two things in a row: a document a crawler reads, and the application that
takes it over. The first half of that sentence is finished — `unibox_html` writes a document
that is worth reading, and a reader can act on it before any engine exists. The second half
is not: today the boot appends a `<script>` and then has no further opinion. The
application is shown the moment it has a canvas, whether or not that canvas is the page; a
bundle that never arrives leaves a document that thinks it booted; and the example's build
patches Flutter's generated loader with a string replacement to make any of it work.

This document is about the second half.

## 1. The vocabulary

The repository already has most of the words, and they are used here in the sense they
already carry:

| Word | Means |
| --- | --- |
| a **document** | the markup `unibox_html` writes: readable, crawlable, interactive without an engine |
| a **takeover** | `Takeover` — the one value a host passes to `toDocument` to become an application second |
| a **waiting frame** | a frame whose document waits to be asked before it boots (`BootPolicy.onIntent`) |
| a **boot policy** | *when* the application starts: `immediately`, `onPointer`, `onIntent` |
| a **recorder** | `pressScript` and `scrollScript`, which remember what a reader did before the application existed |
| the **handover** | the moment the application's pixels replace the document's, and everything that has to be true at that instant |
| the **reveal** | what the boot does at that moment: swap which of the two views is live, visible and in the accessibility tree |

The distinction this document adds is the last one. Today the repository conflates the
*start* of the boot with the *end* of the handover, and that conflation is the defect.

## 2. What is true today

`packages/unibox_html/lib/src/client/boot.dart` contains the whole handover, in sixteen
lines:

```js
function boot() {
  if (booted) { return; }
  booted = true;
  var offered = document.querySelector('[data-unibox-open]');
  if (offered) { offered.remove(); }
  var element = document.createElement('script');
  element.src = source;
  unibox.booted = true;
  (document.body || document.documentElement).appendChild(element);
}
```

It removes its own way-in control and appends the engine's script. Nothing hides, inerts,
removes, disables or fades the pre-boot document, and nothing watches for the first frame.
A grep for the primitives (`inert`, `aria-hidden`, `pointer-events`, `first-frame`) finds
them only as *renderer output for nodes* — a decorative icon, a bar's children — never in
the handover.

What makes that look like it works is Flutter: the engine appends a host element
(`flutter-view`, and `flt-glass-pane` before it) that covers the viewport, handles its own
pointer input, and paints an opaque canvas over everything. `tool/boot_check.sh` asserts
exactly that and nothing more:

```sh
if ! grep -q 'flt-glass-pane\|flutter-view' "$work/dom.html"; then
```

So the library's own check for a correct handover is *"the engine appeared"*. Every row below
is unverified in the repository today:

| # | Not handled | What a reader or a host pays |
| --- | --- | --- |
| 1 | the pre-boot content stays focusable and hit-testable | a ghost press on a page nobody can see; Tab walking the dead document |
| 2 | no `inert` / `aria-hidden` on it | two copies of the page in the accessibility tree, with nothing saying which is live |
| 3 | no scroll lock | the document scrolls under the canvas: the second scrollbar, and scroll chaining |
| 4 | no first-frame awareness | the swap is a hard cut at an unsynchronised instant |
| 5 | `unibox.booted` is set when the script is *appended* | a host gating on it gates on the wrong moment |
| 6 | no failure path (`onerror`, CSP, 404, an exception before the first frame) | a page that believes it booted, and shows nothing |
| 7 | focus is guarded before the boot, never moved after it | focus stays on an element underneath the canvas |
| 8 | the recorders keep running after the boot | presses on the invisible document are handed to the app as intent |

And the comment at `boot.dart:226` — *"The boot replaces every element in this document"* —
describes an intention nothing implements: the elements are covered, not replaced.

Two consequences follow, and they are the reasons to fix this rather than document it.

**A takeover has no loading state.** The engine is two megabytes compiled and started, about
1.9 seconds of blocking on a phone by this repository's own estimate. For that whole window
the reader is owed the document, and the document is already the right page. Today there is
no window: the first canvas wins.

**A host cannot tell what happened.** The one question an integrator has — *did it boot, and
what went wrong if not* — has no answer in the page.

## 3. The three moments

A takeover has three moments and one failure mode, and the boot has one moment.

```
                 the reader signals                the app is ready to be shown
document ──────────────────────▶ booting ─────────────────────────────▶ app
    │                               │
    │  readable, pressable,         │  engine loading; document still
    │  scrollable, recording        │  the page; presses recorded, not lost
    │                               │
    └───────────────────────────────┴──(error, or never ready)──▶ failed
                                                                  the document stays
```

`booting` is not an instant: it spans the engine download and start, and then whatever the
application needs before it is worth looking at. Naming it is the whole design, because every
requirement below is *"what must be true during `booting`"*.

The state is written on the document element, so a test can read it and a host can style it:

| `data-unibox-state` | The pre-boot content | The engine's host element |
| --- | --- | --- |
| `document` | live; the page | does not exist yet |
| `booting` | live; still the page | `opacity: 0`, `visibility: hidden`, `pointer-events: none`, `inert`, `aria-hidden="true"` |
| `ready` | still live, still recording | announced; fading in; `aria-hidden` removed |
| `app` | `inert`, `aria-hidden="true"`, scroll locked, focus moved → then removed | the page |
| `failed` | live; the page | removed |

Two rules that keep this honest:

- **The accessible page changes hands at the same instant the pixels do.** While `booting`
  the document is what a screen reader reads; after `ready` the engine is. There is never a
  moment where both are in the accessibility tree, and never a moment where neither is.
- **A press during `booting` is not lost.** The document stays interactive *because* the
  recorders exist: `pressScript` writes down what was pressed and where, and the application
  replays it as its own state. Making the document `inert` at the boot — which is what the
  first draft of this design said — would throw that away and is wrong.

## 4. Decisions

### D1. The document is the loading state

There is no spinner, no skeleton and no progress bar in this design. The document is already
the right page at the right offset in the right faces, so the only thing the handover owes
the reader is *not showing the application before it is the same page*.

A library that invented a loading skeleton would be inventing a second rendering of a page it
was handed, and it would have to be kept in step with the first. Refused.

What the library does owe is *an honest affordance that something is happening*, and it costs a
crawler nothing: **none of the boot's markup is in the served document**. The way-in button is
created by the script, so a crawler, a link preview and a reader without JavaScript see the
document's own links and no trace of a boot. The affordance is therefore written at runtime,
for a reader who is already using the page: under `BootPolicy.onIntent` the way-in control stays
in place while `booting`, labelled `Takeover.loadingLabel`, `aria-disabled="true"` — not
`disabled`, which would drop the reader's focus — with a `role="status"` region saying the same
words once.

`aria-busy` was in the first draft and is wrong: it announces that a *region* is being updated,
and what has happened here is that a control was accepted. Words are the host's; the timing and
the focus are the library's — see D8.

### D2. Two views, opposite isolation, swapped in one place

The engine's host element must be invisible and unreachable while it boots, and the document
live; after the reveal, exactly the reverse. That is one function applied to a pair, not two
independent rules, because the failure modes are mirrors of each other:

- engine visible and live while loading → the reader sees a half-painted app, and every press
  disappears into it;
- document live after the reveal → ghost presses, a dead Tab order, two pages for AT.

Three details that make it work and are easy to get wrong:

1. **Do not name the engine's element.** Snapshot `Array.from(document.body.children)` at the
   boot; anything that appears in `body` afterwards is the engine's, whatever this Flutter
   version calls it. A `MutationObserver` on `body` during `booting` styles what arrives. The
   repository's `flt-glass-pane\|flutter-view` grep is a version dependency; this is not.
2. **`opacity` and `visibility`, never `display: none`.** The engine measures its host and
   lays out against it: a zero-size host is a blank application that never reports a frame.
   `opacity: 0` keeps the layout, keeps `requestAnimationFrame` running, and therefore keeps
   *the first frame happening while hidden* — which is the entire point.
3. **`pointer-events: none` is not optional.** An invisible engine host on top of the
   document swallows every press into an application nobody can see. This is the mirror of
   the ghost click and the reason the pair is swapped together.

**On the fade: no animation is baked into the library.** The boot writes attributes and a small
rule of its own — it never sets an inline style — so a host can animate the change from its own
stylesheet. The boot marks the element it discovered with `data-unibox-app`, which is how a host
styles *whatever the engine inserted* without naming a Flutter version, exactly as D2 discovers
it rather than looking it up:

```css
@media (prefers-reduced-motion: no-preference) {
  [data-unibox-app] { transition: opacity 160ms ease-out }
  [data-unibox-state="booting"] [data-unibox-app] { opacity: 0 }
  [data-unibox-state="ready"]   [data-unibox-app] { opacity: 1 }
}
```

Three reasons the dissolve is the host's and the *timing* is the library's: a duration is taste;
`prefers-reduced-motion` is a rule the host already has to honour for its own motion — the
example's stylesheet carries exactly that guard for the hero's arrows — and a fade the library
forced would be an appearance token with no counterpart on the other target, which is what
`tool/surface_check.py` exists to refuse. A `Takeover.crossfade` field appeared in an earlier
draft of §5 and has been removed for that reason.

### D3. Two answers in the boot, three in the application

From inside the document there are only two observable events, so the boot understands only
two. What *ready* means is the application's business, and it has three honest answers in
increasing order of correctness.

```dart
Takeover(
  boot: '../../flutter/flutter_bootstrap.js',
  policy: BootPolicy.onIntent,
  reveal: RevealPolicy.onFrame,          // or onReady
  readyTimeout: Duration(seconds: 8),    // reveal anyway, and say so
  loadingLabel: 'Opening the listings…',
)
```

| `reveal` | Fires when | Costs |
| --- | --- | --- |
| `onFrame` | the engine's first frame — the event `tool/boot_check.sh`'s probe already listens for on `window` | nothing; the default |
| `onReady` | the application calls `unibox.ready()` | one call from the app |

`onReady` is the honest default for a takeover, and the three app-side answers are:

| The app says ready | Where it comes from | What it fixes |
| --- | --- | --- |
| the tree drew the state it was given | a post-frame callback in `FlutterStateful` — automatic, no host code | the reveal lands after the scroll/press replay, so the reader never sees the jump |
| the data arrived | the host calls `uniboxReady()` when its store first has something to show | the reveal is the finished page, not the page with holes in it |
| the fonts are in | `document.fonts.ready` on the document side, awaited before the reveal | a reflow the moment the faces land: read as a twitch here, as renderer drift in a comparison |

`onFrame` stays the *default* even though `onReady` is better, because a host that has not
upgraded its application must not silently wait eight seconds for a call it never makes. The
example adopts `onReady`, the README recommends it, and a later minor can flip the default
once the automatic signal has shipped and been used.

**A caveat worth recording:** `flutter-first-frame` is an engine event, not a Dart API. The
repository already depends on it in a throwaway probe; making it a *library's* production
signal is a dependency on something undocumented, so it is watched rather than trusted, and
`unibox.ready()` is the primary signal wherever the application can give one.

### D4. Never wait forever

Three ways for `booting` to end badly, and each has an answer that is better than a dead page:

- **the engine fails to load** — `script.onerror`, a CSP refusal, a 404. The boot knows the
  resolved URL, so it says so (D6) and goes to `failed`: the script element is removed, the
  document is left live, and the reader still has the page they arrived at.
- **the engine loads and never draws** — `readyTimeout` with no first frame. Same as above:
  `failed`, document stays. A page that cannot become an application is still a page.
- **the engine draws but the application never says ready** — reveal anyway at
  `readyTimeout`, because there is a frame worth showing and holding it would be worse than
  showing it. Reported as `held`, not as a failure.

A minimum hold is deliberately *not* in the design: a fast reveal is the best outcome, and the
document and the application are the same page, so there is nothing to flicker between.

### D5. The Flutter build's `index.html`: reuse it, and stop patching it

**In one sentence: we keep it.** The `index.html` in `build/web` is Flutter's — we serve it
as-is at `/flutter/` and `/flutter/listings/` and never edit it. The only web file this project
owns is `web/flutter_bootstrap.js`, which `flutter build web` substitutes into, and that is
where the application's base URLs come from.

The rest of this decision is why that is possible, and what it replaces.

This is the question that decides how much of the above can even be tested, so it is answered
with the code that makes it possible.

**What exists today.** `example/unibox_example_flutter/web/index.html` is ours — twenty-one
lines, a `<base href="$FLUTTER_BASE_HREF">` and `<script src="flutter_bootstrap.js" async>`.
`flutter build web` reads it and writes `build/web/index.html`, a `build/web/main.dart.js`, a
`build/web/canvaskit/`, and a generated `build/web/flutter_bootstrap.js` whose entire content
is:

```js
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load();
```

`tool/site.sh` then string-patches that last line into a configured `load()` and saves it
beside it as `app.js`, because a takeover document sits two directories down and the loader
would otherwise resolve `main.dart.js` against `web/listings/` and get a 404. The patch
carries its own tripwire — `raise SystemExit('the bootstrap no longer ends with an
unconfigured load()')` — which is an admission: it is editing generated output, and it will
break on some SDK upgrade.

**The thing the repository has not been using.** `flutter build web` reads a
*project-owned* `web/flutter_bootstrap.js` when one exists, and uses the default above only
when it does not (`packages/flutter_tools/lib/src/build_system/targets/web.dart`), then
substitutes `{{flutter_js}}`, `{{flutter_build_config}}`, `{{flutter_service_worker_version}}`
and any `--web-define=NAME=VALUE` into whatever it found
(`lib/src/web_template.dart`). So the supported customisation point is a file we check in, not
a string we replace afterwards.

**Decision: own the bootstrap, serve Flutter's `index.html` unpatched.**

`example/unibox_example_flutter/web/flutter_bootstrap.js` — checked in, complete:

```js
{{flutter_js}}
{{flutter_build_config}}

// Where this file is served from, read before anything else: `currentScript` is only set
// while a classic script is executing, so it has to be read at the top.
var base = new URL('.', document.currentScript.src).href;

_flutter.loader.load({
  config: {
    entrypointBaseUrl: base,
    canvasKitBaseUrl: new URL('canvaskit/', base).href,
    assetBase: base
  }
});
```

Three things fall out of it, and each removes a piece of the old build:

1. **Absolute URLs computed at runtime, so one artefact works from any depth.** `/flutter/`,
   `/flutter/listings/` and a takeover document at `/web/takeover/` can all load the same
   `flutter_bootstrap.js`; it states where the application is, which is exactly what the
   repository has been trying to say with `--base` interpolation and a patched copy.
2. **`app.js` disappears**, and with it the Python block in `tool/site.sh`, the second
   loader artefact, and the path table row in `example/README.md` that explains it.
3. **Flutter's `index.html` is reused exactly as generated.** We keep the `<base href>` the
   build writes (it is what lets a copy of the document at a deeper route resolve its assets)
   and we serve it at `/flutter/` and `/flutter/listings/`.

**On "markers".** The state machine does **not** belong in `index.html`, and no marker is
injected into it: the states describe a *handover between two documents*, and only the
takeover document has a document to hand over from. The Flutter-native route has no document
underneath, so its only loading concern is a colour: the page should not flash white before
the canvas paints. That is one rule in our own template's `<style>`, using the same surface
colour the tree's first box paints — not a state, not an attribute, not a marker.

**The option refused.** Serving a `unibox_html` `Document` at `/flutter/` and booting the
engine by hand would be philosophically tidy and would delete `index.html` entirely. It would
also make this repository the owner of Flutter's web bootstrap — the engine choice, the
service worker, the build config, the deprecations — which is maintenance this library exists
not to take on. `flutter build web` needs an `index.html` to build regardless, so "discard it"
would mean "do not serve it", at the cost of owning everything it does.

**What a host does.** The example is one shape of deployment; the general one looks like this,
and the answer is the same for all of them:

```text
flutter_app/                  the application, and the one `web/` directory that matters
  web/index.html              theirs — untouched
  web/flutter_bootstrap.js    theirs — added, a dozen lines
unibox_page/                  the shared trees both sides draw
server/                       renders them, serves them at whatever paths it likes
```

Two entries, one bundle: `web/index.html` is the launcher for the application's *own* address,
and the server's documents are the launcher for the pages that must be found. Neither knows
about the other, and the bootstrap is what makes the second entry work. In the pinned SDK,
`resolveUrlWithSegments` resolves against `document.baseURI` and `canvasKitBaseUrl` falls back to
a relative `canvaskit`, so *every* asset of the application is measured from the document that
asked for it:

| Where the Flutter build is served | Why the default is enough, or not |
| --- | --- |
| the same directory as the document | it is enough — `document.baseURI` happens to be right — but the file is still the safer default |
| same origin, another path (`/flutter/`) | **not** enough: `main.dart.js`, `canvaskit/` and the assets all resolve against the document and 404 |
| another origin or a CDN | **not** enough, and the file is only half of it: the build's files need `Access-Control-Allow-Origin`, and the document's CSP needs that origin in `script-src`, `font-src` and `connect-src` |

The alternative is to keep the token block in the host's own `index.html` — Flutter supports
that too — but the base is then baked at build time, so a second directory means a second build.
The sibling file has no such coupling, which is why it is the recommendation. Server side is one
line: `Takeover(boot: '/flutter/flutter_bootstrap.js')`, absolute, because a document that states
its own depth is a document that breaks when the routes change.

What the library never asks a host to do: patch `_flutter.loader.load()`, ship one bootstrap per
document, or carry a second loader beside the build. The example did all three for a while, and
this decision is the record of why it stopped.

### D6. A debug mode for the library's users

The integrator's question is not "what does this page look like" — that is the example's
problem. It is *"did the handover work, and if not, why"*. So the debug mode is about the
handover, and it reports in sentences.

`Takeover(debug: true)` / `bootScript(..., debug: true)`, which does three things:

**1. Marks.** One line each, `[unibox]` prefixed, and kept on `window.unibox.marks` for a
support request or a headless check:

```text
navigation  0          document  412        boot-start  412
script-load 480        first-frame 2310    ready 2402      reveal 2402
held        92         state app
```

`held` is the number that tunes `readyTimeout` and the reveal: milliseconds the document was
kept after a frame was available.

**2. Checks**, each reported as a sentence rather than a code:

| Reported | Means |
| --- | --- |
| `the bundle did not load: <resolved url>` | a 404, a CSP refusal, an `onerror` |
| `no frame after 8s` | the engine never drew; the document is still the page |
| `the application never said ready; revealed after 8000ms` | `onReady` with no call — the `held` case |
| `the engine's host does not cover the viewport` | the most common takeover defect: `flutter-view`'s rect against `innerWidth`/`innerHeight`, which is what lets old content show through |
| `a press landed on the pre-boot document after the app was up` | the ghost click, observed rather than reasoned about |
| `the document still scrolled after the app was up` | the scroll lock failed or was undone |

**3. The report is not reachable from the address.** A *user's* debug flag is a constructor
argument or a `-D` define: on production a URL is attacker-controlled, and a debug run a visitor
can turn on is a debug run in production. The address may still say two things — see D9 — and
both of them can only *narrow* what the build already allowed.

### D7. Numbers: facts in the renderers, durations in the host

A second, quieter surface applies to both renderers, because the same question — *what did this
cost* — is asked of the HTML rendering and of the application:

- **facts**, deterministic and worth a test: node count, count by node name, depth, distinct
  looks, validation issues, and on the web the class count and stylesheet bytes, which
  `tool/scale.sh` already baselines;
- **durations**, machine-dependent and never asserted: `Stopwatch` in the host around plan,
  css and paint; `FrameTiming` in Flutter; and the boot marks above.

They are not one type yet. They measure different machines (`looks` against `classes`), and a
union type would be the style bag the model keeps refusing. `unibox_core` gains nothing.

### D8. The reveal is an accessibility event, not a visual one

Handing a reader from a document to an application is the most disruptive thing this library
does, and three facts about the platform make it worse than it looks:

1. **The document is the accessible rendering.** A takeover starts as real text, real headings,
   real links and real fields. The application is a canvas.
2. **Flutter ships its semantics tree off on the web.** A reader turns it on through
   `flt-semantics-placeholder`, a button inside `flt-glass-pane`'s shadow root — which is to
   say: by default there is exactly one focusable thing in the application, and it is not the
   page. A reveal that merely hides the document therefore hands an assistive-technology
   reader a page with one unlabelled control on it.
3. **`inert` also removes content from the accessibility tree**, so "hide it from the pointer
   but leave it for the screen reader" is not a state that exists.

This is the strongest argument for `BootPolicy.onIntent` being the recommended policy for a
takeover, and it turns into rules:

- **Never reveal while focus is inside the document.** Today `_focusGuard` is an `onIntent`
  detail. It becomes a rule of the *reveal*, for every policy, because the reveal is what
  destroys the element under the focus.
- **Move focus, announce, then hide — in that order.** Focus goes to the application's entry
  point, then the pre-boot content is `inert`, `aria-hidden` and removed. `inert` blurs whatever
  is inside it, so hiding first and focusing afterwards drops the reader on the body.
- **Announce the change.** One `role="status"` sentence at the reveal, in the document's
  language, because focus landing on an unfamiliar control with no announcement loses a reader
  even when nothing is broken.
- **The application has to be readable before it is the only thing left.** A takeover enables
  `SemanticsBinding.instance.ensureSemantics()` at its first draw and keeps the handle for the
  life of the app (letting it go turns the tree off again), so the tree exists whether or not the
  reader ever finds Flutter's placeholder. *Who* does that is the last row of the table below.
- **A reveal with no tree is reported, not papered over.** The debug mode says *"the
  application has no accessibility tree"* — an integration defect the boot cannot fix, and one
  that is invisible to everybody who is not using a screen reader.
- **The way back is an address** — D9.

**So the library does it, and the app does nothing.** The rule for this decision is *plug and
play*: a host that has wired up `Takeover` has done enough, so every step below belongs to the
boot or to the renderer, and none of them is a method an application has to remember to call.

| Step | Who does it | What it takes |
| --- | --- | --- |
| the engine's host can be focused | the boot | `tabindex="-1"` on `data-unibox-app`: focusable by the boot, never entered by Tab |
| focus moves, then the document hides | the boot | focus the application, announce, `inert`, `aria-hidden`, remove — in that order |
| the change is announced | the boot | one `role="status"` sentence from `Takeover.readyLabel`, with the page's `lang` copied onto it so a screen reader pronounces it in the document's language |
| the application has an accessibility tree | `unibox_flutter`, without being asked | the boot sets `window.unibox.takeover = true` before the bundle loads; the renderer reads it through the same conditional import it already uses for the browser and calls `SemanticsBinding.instance.ensureSemantics()` at the first draw, holding the handle for the life of the app |

Two consequences worth stating:

- **`uniboxSemantics()` is therefore not public API.** It is what the renderer does when it was
  booted as a takeover, and the flag is how it knows: an application opened at its own address
  has no `window.unibox.takeover`, so it enables nothing it was not asked to.
- **The focus ring is suppressed on the container and nowhere else** — `[data-unibox-app]:focus
  { outline: none }`. A container that took focus as part of a page change is not a control, and
  the reader's next Tab lands on a real one. What is left to the host is *words*: `openLabel`,
  `loadingLabel`, `readyLabel` — because a library cannot write a sentence in a language it was
  never told about.

### D9. What the address may say

D6 said the *report* is not reachable from the address. That is still true, and it is not the
same as saying the address says nothing. There are four values, in two tiers:

| Parameter | Effect | Tier |
| --- | --- | --- |
| `?unibox=document` | never boot; the page stays the document | **narrows** — always allowed |
| `?unibox=debug` | the handover marks and checks, printed and kept on `window.unibox.marks` | inspects — needs `Takeover(debug: true)` |
| `?unibox=profile` | the same marks as `performance.measure` entries and as `window.unibox.profile` | inspects — needs the same flag |
| `?unibox=compare` | both renderings at once: the document kept, the application at 50% over it | inspects — needs the same flag |

What keeps this safe is not "one key, a closed set of values" — though it is both — but that **a
value may only narrow what the build already allowed**. Removing an application is always safe,
so `document` needs no flag; showing the numbers, or drawing one rendering over the other, is
something the host agreed to at build time, so the other three need `debug: true`. Unknown values
are ignored rather than erroring.

`?unibox=document` is the escape hatch D8 needs. A reader who wants the text can say so in a URL
they can bookmark, share or paste into a support ticket — and it survives a reload, which a
button in a canvas does not. It is also what a comparison harness uses to pin a frame to the
document. `Takeover(query: false)` is for a host whose page must not read its own address at all.

**`profile`.** The marks D6 lists *are* the profile: `navigation → document → boot-start →
script-load → first-frame → ready → reveal`, plus `held`. `?unibox=profile` publishes them twice
— as `performance.mark`/`performance.measure` entries named `unibox:*`, which the browser's
Performance panel draws on its own timeline, and as `window.unibox.profile`, which a harness reads
without a console. The split that matters is **download against engine start**: Resource Timing
says when the bundle finished arriving, `first-frame` says when the engine could paint, and the
single figure the repository quotes today cannot tell a host whether to shrink the bundle or to
shorten the first frame.

**`compare`.** A takeover is already two renderings of one tree — a document and an application
drawn from the same nodes — so the cheapest way to see whether they match is to keep both: the
document stays in the page, the application is revealed at 50% over it, and a difference that
should not exist shows up as a doubled edge or a ghost of the other's text. Three constraints
keep it honest and cheap:

- **The document is kept, not released.** It stays `inert` and `aria-hidden` — so a screen reader
  still sees one page — but it is *not removed*, and the state stays `app`. `data-unibox-compare`
  records that the pair is being shown, and at what opacity.
- **One rendering takes the input, and it is the application.** The document is under the canvas,
  so it cannot be pressed: a comparison is something a reader *looks* at. Scrolling moves the
  application and the document stays where it was, which is why the useful moment is at rest, at
  the offset the application replayed.
- **Nothing about it is a state of its own.** Compare is the reveal with the removal skipped, so
  there is no fifth state and no second code path through the handover.

## 5. The API this adds

```dart
// packages/unibox_html/lib/src/client/boot.dart
enum RevealPolicy { onFrame, onReady }

String bootScript(
  String src, {
  BootPolicy policy = BootPolicy.onPointer,
  String openLabel = 'Open the application',
  RevealPolicy reveal = RevealPolicy.onFrame,
  Duration readyTimeout = const Duration(seconds: 8),
  String loadingLabel = 'Opening the application…',
  String readyLabel = 'The application is ready',
  bool debug = false,
  bool query = true,
});

// packages/unibox_html/lib/src/takeover.dart
final class Takeover {
  const Takeover({
    required this.boot,
    this.policy = BootPolicy.onPointer,
    this.reveal = RevealPolicy.onFrame,
    this.readyTimeout = const Duration(seconds: 8),
    this.loadingLabel = 'Opening the application…',
    this.readyLabel = 'The application is ready',
    this.openLabel = 'Open the application',
    this.record = true,
    this.debug = false,
    this.query = true,
    this.nonce,
  });
}

// packages/unibox_flutter/lib/src/unibox_ready.dart — client only, no-op elsewhere.
// Semantics are not here: a takeover enables them itself, see D8.
void uniboxReady();   // only for an application that has data to wait for
```

There is deliberately no `crossfade`: see D2.

And the contract a test can read, on `<html>` and on the element the boot discovered:

| Attribute | Where | Values |
| --- | --- | --- |
| `data-unibox-state` | `<html>` | `document`, `booting`, `ready`, `app`, `failed` |
| `data-unibox-held` | `<html>` | milliseconds, written when a frame was available before the reveal |
| `data-unibox-boot` | `<html>` | the debug mode's mark list, as JSON, when `debug` is on |
| `data-unibox-app` | the engine's host element | `true` — what a host's CSS styles and animates |
| `data-unibox-compare` | `<html>` | the opacity the application is drawn at, when `?unibox=compare` is in force |

`unibox.booted` keeps its meaning (*the boot was asked for*) and `unibox.ready` is added, so the
old, wrong assumption — `booted` means "up" — is written down rather than silently corrected.
The address's four values (`document`, `debug`, `profile`, `compare`) are documented beside these,
because they are the same contract seen from the reader's side.

## 6. What each package gains, and what stays out

| Package | Change |
| --- | --- |
| `packages/unibox_html` | the state machine in `boot.dart`, `RevealPolicy`, the new `Takeover` fields, the bootstrap recipe in the README. This is the whole handover. |
| `packages/unibox_flutter` | `unibox_ready.dart` (a conditional import, client only, no-op elsewhere); a post-frame signal so `onReady` works with no host code; and, on a page that was booted as a takeover, `ensureSemantics()` at the first draw — so an application that was handed the page is readable without being told to be |
| `packages/unibox_dom` | nothing. It already replaces the children of the host it was given (`mount.dart`), which is why it has never had this problem |
| `packages/unibox_core` | nothing. The state of a takeover is a host fact, like a route — not model vocabulary |
| `packages/unibox_testing` | nothing. **No appearance changes**, which is the check that this is a handover fix and not a rendering one, and why `tool/surface_check.py` has nothing to say about it |
| `packages/unibox_material` | nothing |
| `example/unibox_example_flutter` | `web/flutter_bootstrap.js` (new, checked in), a loading colour in `web/index.html`, `Takeover(reveal: onReady)` in the host |
| `example/unibox_example_html` | `boot:` points at `../../flutter/flutter_bootstrap.js`; `app.js` is gone |
| `tool/site.sh` | the Python patch and the `app.js` copy are deleted; the build gets shorter |

## 7. Tests and gates

The repository's rule is that a construct arrives with a test on both targets, and this one
also has a place where it can be tested honestly for the first time:

1. `packages/unibox_html/test/boot_script_test.dart` — the script writes the state, hides and
   inerts the engine host, listens for the frame or for `unibox.ready`, honours `readyTimeout`,
   and writes no marks when `debug` is off. `node --check` over every `BootPolicy` ×
   `RevealPolicy` pair, which the suite already does for the policies.
2. `packages/unibox_html/test/boot_accessibility_test.dart` — a reveal that never happens under
   the focus, the order of the reveal (focus moved, then `inert`, then removed), the `role="status"`
   sentence written once, and the way-in control that keeps focus because it is `aria-disabled`
   rather than `disabled`.
3. `packages/unibox_html/test/boot_query_test.dart` — `?unibox=document` never appends the
   script; an unknown value does nothing; `debug`, `profile` and `compare` do nothing unless the
   build passed `debug: true`; `?unibox=profile` writes `unibox:*` measures; and
   `?unibox=compare` keeps the pre-boot content, leaves it `inert`, and draws the application at
   the recorded opacity.
4. `packages/unibox_html/test/takeover_test.dart` — the document carries the reveal
   configuration, still prefetches the loader, and still places the recorders before the boot.
5. `packages/unibox_dom/test/handover_test.dart` — **the assertion this repository has never
   had**, in a real browser and a real DOM: the boot hands the page over at the first frame
   (`data-unibox-state="app"`, the engine marked `data-unibox-app`, the document *removed*), the
   `role="status"` sentence is written in the page's language, a page whose engine never draws
   goes back to being a document with its content intact, and an `onReady` page reveals when the
   timeout expires. The engine is a data-url script that appears in the body and dispatches
   `flutter-first-frame`, so the test needs neither a Flutter build nor a network.
6. `tool/boot_check.sh` — unchanged in what it asks: the real engine, through the real loader,
   paints into a real page. It is the half the browser suite cannot cover (a Flutter build) and
   the browser suite is the half it cannot (the handover).
7. `packages/unibox_flutter/test/stateful_node_test.dart` — an application opened at its own
   address was handed nothing: `wasTakenOver` is false and `uniboxReady()` is a no-op. The web
   path itself needs a browser and a Flutter build, and is covered by 5's fake engine.
8. `example/unibox_example_html/test/document_test.dart` — the takeover document names
   `flutter_bootstrap.js`, and `app.js` appears nowhere in the site's documents or scripts.
9. The gate: `tool/verify.sh --docs`, because a public API and several READMEs change, plus
   `python3 tool/check_docs.py` because this file is in the index.

An appearance case is deliberately **not** added. If this change needed one, it would mean the
handover had started deciding what a node looks like.

## 8. What this unblocks

Three things that cannot be built honestly before it:

- **A comparison you can eyeball, immediately.** `?unibox=compare` is a takeover compared with
  itself: the document and the application from the same tree, one at 50% over the other. It is
  free, because the takeover already *is* two renderings of one tree.
- **The two-frame comparison**, for two *different* trees. Laying `/web/listings/` under
  `/flutter/listings/` with a wipe, a blink or a difference blend only measures something once
  the top frame is *ready*; before that, a rect comparison reads a canvas that has not drawn.
  `data-unibox-state` is exactly the gate such a harness waits on.
- **A boot number that means something.** `tool/boot_time.dart` drives a real browser in real
  time and reads one mark off a probe page the check writes and deletes. With the marks above,
  it can read a real page — and separate the download from the engine start, which one figure
  cannot.

## 9. Risks, and what holds each one down

| Risk | Held down by |
| --- | --- |
| `inert` behaviour differs across browsers | it is one attribute doing what three used to; the fallback (`aria-hidden` + `tabindex="-1"` + `pointer-events: none`) is written in the same function, so a browser without it degrades rather than breaks |
| `document.currentScript` is null if a host wraps the bootstrap in a callback or loads it as a module | it is read as the first statement of the checked-in file, and the file is documented as a classic script; a build that needs `type="module"` is out of scope |
| the engine's host element is discovered, not named | the snapshot answers *which* element, so no Flutter version is named; the first frame re-queries the body for anything the observer missed |
| `flutter-first-frame` is undocumented | `onReady` is the recommended signal and `uniboxReady()` is the library's own; the frame is the fallback, not the contract |
| a canvas at `opacity: 0` behaves differently from one at 1 | the headless check asserts the state *and* that a frame was drawn, on every run, so a change in engine behaviour is a red step rather than a mystery |
| `data-unibox-state` becomes an API by accident | it is documented, named in this file, and asserted by `tool/boot_check.sh` — so it is a contract on purpose, not by drift |
| a crossfade in the library would be the model deciding an appearance | the library writes the state and the host styles the transition from it (see §11) |
| Flutter's semantics tree is off by default, so a canvas can be an inaccessible page | a takeover enables it at its first draw with no host code (D8), the debug mode reports the page's state when the tree cannot be confirmed, and `?unibox=document` is the way back to the text |
| a visitor can switch the application off with a query parameter | it only ever narrows what the build allowed, and `Takeover(query: false)` removes even that |
| a library that moves focus and speaks a sentence is doing a host's job | every sentence is a field with an English default, the pronunciation comes from the document's `lang`, and the alternative — each host remembering the order — ships a page a screen reader cannot use (D8) |

## 10. The commits

Seven, in this order, each landing green on its own. The first is separate because it changes how
the example is *built* and unblocks the browser-level check the rest rely on.

```text
feat(html): own the bootstrap Flutter builds, instead of patching it
feat(html): give a takeover three states instead of one
feat(html): reveal the application only when it is ready
feat(html): hand the page over whole — focus, announcement, and a way back
feat(flutter): let an application say when it has drawn, and be readable when it is
feat(html): let the address narrow, and let a dev build inspect
feat(html): report a handover an integrator can read
```

Each carries its README section and its `## Unreleased` bullet, as the repository requires.
This file is updated in the last commit to say what landed and what was dropped.

## 11. What the implementation settled

The four questions this document carried are answered, and the answers are in the code:

1. **The default `reveal` is `onFrame`.** A host's application is not expected to have been
   changed for a page to keep working, so the default is the answer that needs nothing from it;
   `RevealPolicy.onReady` is documented as the better setting for a takeover and is what the
   example uses.
2. **The ready signal lives in `FlutterStateful`.** The semantics flag settled it: the widget has
   to be there anyway, because the first draw is what both answers are about. One post-frame
   callback, no host code.
3. **The state contract is public.** `data-unibox-state` is in this document, in the
   `unibox_html` README's table, and asserted by `packages/unibox_dom/test/handover_test.dart` —
   so it is a promise on purpose rather than by drift.
4. **The address is implemented in two tiers**, as D9 describes, with `Takeover(query: false)`
   turning it off entirely.

Two things about the implementation are worth recording because they differ from the sketch:

- The browser test arrived as `packages/unibox_dom/test/handover_test.dart` rather than as an
  extension of `tool/boot_check.sh`. A shell check that greps a `--dump-dom` cannot drive a boot
  that waits for a signal, and a fake engine in a real DOM tests the state machine properly —
  while `boot_check.sh` keeps the one thing only it can do, a real Flutter build.
- `packages/unibox_flutter` reads `window.unibox` through `dart:js_interop` alone, so the
  takeover costs no new dependency.

## 12. Not doing

- **Pixel diffing in CI.** It needs screenshots of a Flutter canvas and of a DOM, plus a
  baseline per platform — a second benchmark without the determinism of the first.
- **A `unibox_dev` package.** One consumer (the example). When a real application asks for the
  panel, it moves out with a version and a test.
- **Markers injected into Flutter's `index.html`.** The handover belongs to the takeover
  document; the Flutter route's only concern is a background colour it can state itself.
- **Owning Flutter's engine bootstrap.** A document that boots the engine by hand would delete
  `index.html` from the served output and take on the service worker, the engine choice and the
  deprecations with it.
- **A loading skeleton.** The document is the loading state.
- **An animation in the library.** The state attribute is the hook; the dissolve is the host's.
- **A scroll-synchronised compare.** In `compare` the application takes the input and the document
  stays where it was; keeping two scrollings in step is a harness's job, not a boot's.
- **An accessibility control of our own.** Flutter already ships `flt-semantics-placeholder`; the
  library's job is to make the tree *exist* before the reveal, not to duplicate the button.
- **A minimum hold before the reveal.** The document and the application are the same page.
- **A debug flag on a node or in a style bag.** `tool/surface_check.py` exists to refuse a token
  with no appearance, and `PLAN.md` §6 already refused the same shape once.
- **Touching `BootPolicy`.** *When the boot starts* and *when the reveal happens* are different
  questions with different answers, and merging them would make one enum answer both badly.

