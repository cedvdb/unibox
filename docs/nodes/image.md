# ImageNode

A picture, from a URL or from the assets the host ships.

```dart
ImageNode('https://example.com/room.jpg', alt: 'A bright room', fit: ImageFit.cover);
```

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `src` | `String` | required | `http`/`https` loads from the network, anything else is an asset path. |
| `alt` | `String` | `''` | Text for screen readers and for a failed load. Empty means decorative. |
| `width`, `height` | `double?` | natural size | Logical pixels; `double.infinity` fills. One dimension keeps the aspect ratio. |
| `fit` | `ImageFit?` | `scaleDown` | `cover`, `contain`, `fill`, `scaleDown`. |
| `borderRadius` | `double?` | square | Rounds the corners and clips the picture. |
| `srcSet` | `Map<int, String>` | `{}` | Candidate widths and their URLs, narrowest first. The web picks one; Flutter loads `src`. |
| `sizes` | `String?` | none | How wide the image is laid out, in CSS `sizes` syntax. Read only with `srcSet`. |
| `loading` | `ImageLoading` | `eager` | `eager`, `lazy` or `auto`. Web only. |
| `fetchPriority` | `ImageFetchPriority` | `auto` | `high`, `low` or `auto`. Web only. |

**Worth knowing.** The default fit is the model's, not the platform's: without it a
Flutter `Image` scales a picture down while a browser stretches it over its box, and
the same image looked different on each target.

The four responsive fields are the one part of a node the web renderer reads and
Flutter cannot: they become `<img>` attributes (`srcset`, `sizes`, `loading`,
`fetchpriority`, and the element's `width`/`height` so the browser reserves the box
before the picture arrives). Flutter loads a single source, so ship `src` at the size
a phone needs and the denser candidates are a free improvement on the web.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
