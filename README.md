# Unibox

Declare a UI region once in pure Dart. Render it as HTML and CSS on the server,
and as Flutter widgets inside your application.

A product description, listing card or editorial section may need to appear in
both a readable web document and a Flutter app. Unibox lets those surfaces share
content, structure and design values. The host keeps its own page composition,
search, maps, navigation and application state.

**Experimental and unpublished.** Resolve all Unibox packages from one commit.
Breaking API removals are recorded in the package changelogs.

## When it helps

Use Unibox when the same content needs a server-rendered document and a Flutter
presentation, and maintaining two implementations would make them drift.

- Share listing cards between a public catalogue and your Flutter application.
- Publish product details, articles or landing-page sections as HTML, while using
  the same declarations in Flutter.
- Optionally let a readable document hand over to a Flutter application after
  the host has loaded its destination content and laid it out.

Existing Flutter widgets are not automatically converted to HTML. Declare only
the regions that need both targets. A Flutter-only screen can remain ordinary
Flutter. A server document can remain a document, with no Flutter bundle at all.

## One declaration, two hosts

Keep the shared code in a pure Dart package. For example, `shared/summary.dart`:

```dart
import 'package:unibox_core/unibox_core.dart' as ui;

ui.UINode buildSummary({required String city, required int count}) => ui.Box(
  gap: 12,
  padding: const ui.BoxSpacing.all(20),
  children: <ui.UINode>[
    ui.TextNode('Homes in $city', headingLevel: 2, fontSize: 24),
    ui.TextNode('$count homes to explore'),
    const ui.LinkNode(
      'https://example.com/homes',
      children: <ui.UINode>[ui.TextNode('See all homes')],
    ),
  ],
);
```

The **server** owns the document and its metadata:

```dart
import 'package:unibox_html/unibox_html.dart';
import 'shared/summary.dart';

void main() {
  final html = toDocument(
    buildSummary(city: 'Paris', count: 6),
    head: const DocumentHead(title: 'Homes in Paris'),
  );
  print(html); // Return this from your server, or write it to a static file.
}
```

The **Flutter host** places the region among its own widgets. This example uses
`material_ui`, matching the pinned Flutter SDK:

```dart
import 'package:material_ui/material_ui.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'shared/summary.dart';

void main() => runApp(MaterialApp(
  home: Scaffold(
    appBar: AppBar(title: const Text('Find a home')),
    body: SingleChildScrollView(
      child: FlutterLinkScope(
        open: (url) { /* Navigate using your application's link policy. */ },
        child: renderFlutter(buildSummary(city: 'Paris', count: 6)),
      ),
    ),
  ),
));
```

These are separate entry points. Only the shared declaration imports core;
the server does not import Flutter. In an application, pass loaded data and
callbacks into the declaration and rebuild it when the host's state changes.

The [worked example](example/README.md) uses this arrangement for six apartment
cards. Its Flutter host adds native search, filters and a dialog. Its server
publishes the listing region with headings, image alternatives and real links.

## What is shared

Unibox describes boxes, text, images, links, grids and other bounded regions.
See the [node reference](docs/nodes/README.md) for the full vocabulary and
[core guide](packages/unibox_core/README.md) for defaults.

Flat parameters override style bags; bags merge left to right. State styles
extend the resting appearance, and disabled state wins. Defaults belong to the
model, so the renderers do not independently choose browser or Flutter defaults.
Colour roles resolve through a shared theme. Hosts provide fonts and assets.
Collections passed into declarations must stay immutable: use const values or
unmodifiable snapshots.

Content, order, destinations and accessible meaning should agree. Text shaping,
line breaks and native component paint can differ. Shared contract tests hold
primitive presentation to one expectation; real regions also need layout checks
at representative widths and text sizes. Unibox does not promise pixel identity.

## Optional Material vocabulary

Core declarations do not require Material. The optional packages provide shared
colour and typography values and a small set of component declarations:

| Declaration or value | HTML and Flutter use |
| --- | --- |
| `MaterialPalette`, scheme variants | Shared colour roles |
| `MaterialTypography`, type roles | Shared type scale |
| `MaterialCard` | Content surfaces |
| `MaterialButton` | Buttons and destinations |
| `MaterialChip` | Labels, filters and removable selections |
| `MaterialSegmentedButton` | Supplied selections and navigation choices |
| `MaterialIcon`, `MaterialIconButton` | Codepoint glyphs and icon actions |

On Flutter, install `materialComponents()` from `unibox_material_flutter`.
Every component requires its native substitution; missing mappings report an
error. Register any icon glyphs as const `IconData` values through `icons:`.
The server renders the component's declaration as HTML/CSS. Selection and actions
are supplied by the host; this package does not own an application store.

An application can also define its own component declarations and use the
[generic substitution map](packages/unibox_flutter/README.md#substitution) to
render them with its own Flutter widgets. Substitutions preserve information and
actions while allowing native paint and interaction.

## Optional document-to-Flutter handover

Handover is a separate integration. Use it when a document should remain readable
while Flutter loads, then yield to the application on the same page.

The server opts in through `Takeover` and the helpers in
`package:unibox_html/handover.dart`. The Flutter host uses
`package:unibox_flutter/handover.dart` and explicitly completes its
`FlutterHandover` after the intended route, data and layout are ready.

The host supplies the destination scroll controller or a restoration callback.
Unibox restores the latest document offset before reveal and can replay one
intercepted keyed action afterwards. Keys must be stable and unique across the
document. Ordinary browser links retain their navigation behaviour. Startup
failure or timeout retains the document.

Different layouts can make absolute offsets approximate. Handover is not an
HTML event runtime or automatic synchronisation of application state. See the
[complete contract](docs/takeover.md) and the separate handover example before
integrating it into a real page.

## What the host owns

The host owns routing, data fetching, state, complex interaction, responsive page
composition, assets and link policy. The server also owns URLs, copy, metadata,
canonical addresses, deployment and indexing policy. Server HTML makes declared
content available to readers and crawlers; search rankings are outside the library.

The optional stateful region adapter manages a bounded store lifecycle. It is
not required by the main example and does not supply an application framework.
There is no DOM application runtime or hydration package.

## Packages

| Package | Responsibility |
| --- | --- |
| [unibox_core](packages/unibox_core/README.md) | Pure Dart declarations and tokens; no dependencies |
| [unibox_html](packages/unibox_html/README.md) | Server HTML/CSS and optional server handover helpers |
| [unibox_flutter](packages/unibox_flutter/README.md) | Widgets, substitutions and optional handover |
| [unibox_material](packages/unibox_material/README.md) | Optional Material declarations and design values |
| [unibox_material_flutter](packages/unibox_material_flutter/README.md) | Native Material substitutions and theme conversion |
| [unibox_testing](packages/unibox_testing/README.md) | Shared presentation and behaviour contracts |

## Try the examples

Use the Flutter version in `.flutter-version`, then run from the repository root:

```sh
flutter pub get
tool/site.sh --serve
```

The command prints the local address. The site compares the static document and
independent Flutter app. The optional handover and Material vocabulary have their
own pages. For a native Flutter run, use `flutter run` from
`example/unibox_example_flutter`.

Read [AGENTS.md](AGENTS.md), [design.md](design.md) and
[consumer instructions](AI_INSTRUCTIONS.md) before changing the API.
Run `tool/verify.sh --docs` for code and README changes. Site and handover checks
are described in [the example guide](example/README.md); ongoing checks are in
[maintenance](MAINTENANCE.md). Releases remain a human procedure.
