# Building shared regions with Unibox

Declare a region once in a pure Dart library; render it with `unibox_html` on the
server and `unibox_flutter` in the app. Keep routing, data, state and page composition
in the application. Maps and booking flows remain native Flutter.

- Use core nodes and model defaults. Flat parameters override style bags.
- Use immutable collection arguments: const values or unmodifiable snapshots.
- Give navigational content real `LinkNode` destinations. Flutter hosts supply
  `FlutterLinkScope`; application callbacks override navigation where declared.
- Theme colour roles through `UniboxScope`. Hosts ship fonts and image assets.
- Keep custom components as core-node declarations. Use Flutter substitutions for
  native components while preserving content, order, semantics and actions.
- Material is optional: palette, typography, card, button, chip, segmented control,
  codepoint icon and icon button. Install `materialComponents()` in Flutter and
  register const icon values. There is no custom Material widget fallback.
- Do not introduce a DOM application, custom path token, progress ring or ink store.
  Native indicators and application surfaces belong to the host.
- Optional handover waits for explicit host readiness. Supply the actual page
  controller; do not infer a main scrollable or signal from an arbitrary first frame.
  Handover keys must be stable and unique across the document. Ordinary links retain
  browser behaviour; only intercepted actions replay.

See [the node reference](docs/nodes/README.md), [core defaults](packages/unibox_core/README.md),
[handover](docs/takeover.md) and [the focused implementation plan](docs/plan-focused-rendering.md).
