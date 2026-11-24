# Examples

The main example shares one stateless listing region between a server document
and an ordinary Flutter page. It deliberately leaves search, filtering, dialogs,
scroll ownership and page composition in the hosts.

## Read the code in this order

1. [The shared region](unibox_example_shared/lib/src/apartments.dart): data,
   a card and a listing grid. No store, map, navigation shell or form runtime.
2. [The server host](unibox_example_html/lib/document.dart): document composition,
   metadata, fonts and the region's HTML rendering.
3. [The Flutter host](unibox_example_flutter/lib/main.dart): native search and
   filters choose the data passed into the region. A supplied save callback opens
   a native dialog. `materialComponents()` renders the declared cards/buttons.

The listing information is shared; the hosts can add different functionality.
The static document remains useful without JavaScript. The Flutter example starts
independently and needs no handover globals. Browser links navigate normally; on
other platforms the example shows a copyable destination instead of depending on
a URL-launching plugin.

## Build and run

From the repository root, with the pinned Flutter SDK:

```sh
flutter pub get
tool/site.sh --serve
```

The command prints the address. Routes are relative to that site root:

| Route | Demonstrates |
| --- | --- |
| `/` | Project guide and two independent host previews |
| `/web/listings/` | Static server document with real listing content |
| `/flutter/listings/` | Shared region surrounded by native Flutter interaction |
| `/web/takeover/` | Separate opt-in document-to-Flutter handover |
| `/web/components/` | Optional Material vocabulary rendered as HTML |
| `/flutter/components/` | That vocabulary using required native substitutions |

For a native target, run `flutter run` from `unibox_example_flutter`.
`tool/site.sh --base=/unibox/` checks a deployment under a path prefix.

## Handover is a separate demonstration

Open `/web/takeover/`, scroll while Flutter starts, or press **Save this search**.
The HTML declares the action with key `listing-save`; the Flutter host provides
its callback and a real page `ScrollController`. After layout it calls
`FlutterHandover.complete(controller: …, root: …)`. Restoration happens before
reveal; the intercepted action then opens **Search saved** once.

This host omits its native search/filter strip during handover so it can restore
the document's simpler composition. Native text and control geometry can still
vary. No application state is copied automatically. Normal links remain normal
links; failure or timeout keeps the document available. The main comparison
never starts handover implicitly.

## Verification

```sh
tool/verify.sh --docs
tool/site.sh
python3 tool/doc_check.py build/site
tool/boot_check.sh build/site
tool/performance.sh build/site
```

Shared tests check supplied data and the absence of application controls. Widget
tests cover native host search, a keyed action opening a native dialog, and
narrow/wide layout. Document tests cover readable content, real links and separate
handover opt-in. The browser check uses the release app, scrolls to the keyed
action, and verifies restoration/reveal/replay in both automatic and existing hosts.

See [the library guide](../README.md) and [handover contract](../docs/takeover.md).
