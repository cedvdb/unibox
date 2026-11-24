# Example

**One declaration → HTML and Flutter → handover.**

[`buildListingExample`](unibox_example_shared/lib/src/apartments.dart) defines the
entire example UI once. Both hosts render that function with the same data, theme,
content, layout and keys. Only asset paths and callbacks differ.

- [HTML host](unibox_example_html/lib/document.dart): metadata, fonts and handover scripts.
- [Flutter host](unibox_example_flutter/lib/main.dart): native mappings, page scroll controller and readiness.

## Run

From the repository root with the pinned Flutter SDK:

```sh
flutter pub get
tool/site.sh --serve
```

The left frame is the HTML reference. The right frame starts with that same HTML,
then hands over to Flutter. Scroll or press **Save these homes** during loading;
Flutter restores the position and replays the action, opening **Homes saved**.

| Route | Purpose |
| --- | --- |
| `/` | Two renderers and live handover |
| `/web/takeover/` | Full-size handover demo |
| `/web/listings/` | HTML reference for comparison |
| `/flutter/listings/` | Direct Flutter rendering for inspection |
| `/web/components/`, `/flutter/components/` | Material component reference |

The reference routes inspect the renderers; the intended flow is HTML to Flutter.
Hosts own routing, data and actions. They do not add a second version of this UI.

## Verify

```sh
tool/verify.sh --docs
tool/site.sh
python3 tool/doc_check.py build/site
tool/boot_check.sh build/site
```

Tests compare the initial content against the shared declaration, cover narrow
and wide layouts with enlarged text, and exercise nonzero scroll restoration and
keyed replay in a release browser. See the [handover contract](../docs/takeover.md).
