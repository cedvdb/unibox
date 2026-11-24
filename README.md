# Unibox - Experiment

**One declarative UI. Two renderers. Flutter handover.**

Declare UI in pure Dart. Render it as HTML/CSS on the server and as Flutter
widgets in your app. Visitors see the HTML immediately; Flutter takes over when
ready, preserving their scroll position and replaying an intercepted keyed action.

The same declaration supplies the content, layout, styling and action keys to
both targets. Your application supplies data, callbacks, routing and readiness.

## Declare once

```dart
import 'package:unibox_core/unibox_core.dart';

UINode buildRegion({required void Function() save}) => Box(
  gap: 12,
  children: <UINode>[
    const TextNode('Homes in Paris', headingLevel: 1, fontSize: 28),
    Box(
      key: 'save',
      onTap: save,
      semantics: const BoxSemantics(role: BoxRole.button),
      children: const <UINode>[TextNode('Save these homes')],
    ),
  ],
);
```

Render that declaration on both sides:

```dart
// Server — unibox_html
final html = toDocument(
  ui,
  takeover: const Takeover(boot: '/flutter/flutter_bootstrap.js'),
);

// Application — unibox_flutter
final widget = renderFlutter(ui);
```

After the destination data and layout are ready, the Flutter host completes the
handover with its page scroll controller:

```dart
await handover.complete(controller: pageController, root: context);
```

The bootstrap passes `window.unibox.hostElement` to the Flutter engine. Scroll
restoration happens before reveal; keyed replay happens afterwards. Normal links
keep their browser behaviour. Read the [handover guide](docs/takeover.md) for the
complete host setup and failure handling.

## See it work

```sh
flutter pub get
tool/site.sh --serve
```

The site displays the same example through both renderers, with live handover in
the Flutter frame. The [example source](example/README.md) uses one
`buildListingExample` declaration for both targets, with the same content and layout.

## Material and custom components

The optional Material packages provide palette, typography, card, button, chip,
segmented control and icon declarations. Install `materialComponents()` for their
native Flutter substitutions; register const icon glyphs through `icons:`.
See the [Material guide](packages/unibox_material/README.md).

Applications can supply their own [native substitutions](packages/unibox_flutter/README.md#substitution).
Shared content and design values stay in the declaration; native control paint
and text shaping can vary between engines. Layout checks help keep handover close.

## Packages

| Package | Role |
| --- | --- |
| [unibox_core](packages/unibox_core/README.md) | Pure Dart declarations and tokens |
| [unibox_html](packages/unibox_html/README.md) | Server HTML/CSS and handover scripts |
| [unibox_flutter](packages/unibox_flutter/README.md) | Flutter widgets and handover coordination |
| [unibox_material](packages/unibox_material/README.md) | Material declarations and design values |
| [unibox_material_flutter](packages/unibox_material_flutter/README.md) | Native Material substitutions |
| [unibox_testing](packages/unibox_testing/README.md) | Shared renderer contracts |

Experimental and unpublished. Pin all packages to one commit. Use the Flutter
version in `.flutter-version`. See the [node reference](docs/nodes/README.md),
[API decisions](design.md) and [contributor instructions](AGENTS.md).

Run `tool/verify.sh --docs` for the full gate, and `tool/performance.sh` for site,
handover and performance checks.
