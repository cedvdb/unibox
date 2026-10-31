# LinkNode

`LinkNode` is a [box](box.md) that names a destination. It *is* the box — the same element,
the same look, the same children, the same press — with a `url` on it, so the whole of it is
what a reader presses and, on the web, a real `<a href>` that a crawler follows and a page
without JavaScript can use. A wrapper around a box cannot do that: it states no layout, so a
control inside it keeps the `flex` share, the height and the padding the anchor should have
had.

```dart
LinkNode(
  '/apartments/amsterdam',
  padding: BoxSpacing.all(16),
  borderRadius: 12,
  children: <UINode>[TextNode('See all')],
)
```

It takes every parameter a `Box` takes, plus:

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `url` | `String` | required | The destination. The element is the anchor (`BoxSemantics.element: BoxElement.a`), and a disabled link writes no `href`. |
| `newTab` | `bool` | `false` | Opens elsewhere: `target="_blank"` with `rel="noopener noreferrer"` on the web. Flutter has no tab; the host decides there. |

**Worth knowing.** In Flutter there is no browser, so the host decides what following a
destination means: wrap the tree in `FlutterLinkScope(open: (url) => ...)` and every link
calls it — unless the link has an `onTap`, which answers the press itself, the same way the
web renderer cancels the navigation rather than doing both. A link with neither a scope nor
an `onTap` is reported in debug builds, because pressing it would do nothing. The browser's
own link styling — underline and blue — is cancelled, so a link looks exactly like the box
it is. A box with `BoxSemantics(element: BoxElement.a)` and no destination is HTML's
placeholder anchor: a browser paints it as text, nothing follows it and nothing can tab to
it.

**What cannot be one.** HTML forbids interactive content inside `<a>`, so a control inside a
link is reported by `validateTree` rather than painted two ways: a chip with a remove cross
is two nodes side by side, not one inside the other. A link inside a link is reported for the
same reason — it would navigate twice. A link that names a landmark (`element: article`)
*and* a destination is reported too, because only one tag is written and the anchor is the
one that navigates.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
