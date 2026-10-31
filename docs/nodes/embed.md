# EmbedNode

The escape hatch, for what the ten nodes cannot describe: a chart from a package,
a video player, an effect that only exists on one platform.

A node carries **one implementation per renderer**, and each renderer draws the
first one whose type it understands. Nothing in `unibox_core` names a platform, so a
node class the library has never seen renders anywhere that can draw one of its
payloads.

```dart
final class InkRipple extends EmbedNode {
  const InkRipple({required super.child});

  @override
  List<Object> get implementations => <Object>[
    (Widget child) => InkWell(child: child),                 // Flutter
    (Component child) => div(<Component>[child], classes: 'ink'), // the web
  ];
}
```

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `implementations` | `List<Object>` | required | The payloads, one per renderer. A renderer accepts a `Widget`/`Component`, or a builder of one that wraps the child. |
| `child` | `UINode?` | none | The content the implementations wrap, for effects. |

Two conveniences cover the single-implementation case: `FlutterWidgetNode(widget)`
in `unibox_flutter` and `HtmlEmbed(markup)` in `unibox_html`.

**Worth knowing.** The payloads are platform values, so the node is usually
declared where both types are visible, or it takes its half through a parameter its
host supplies. An embed is the one place where the two renderings may differ, so it
is outside the tests that hold the targets together: use it last, not first. A node
with no implementation this target can draw — or with two of them — throws a message
naming what the renderer accepts and what the node carries, so a mistake is loud
instead of blank.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
