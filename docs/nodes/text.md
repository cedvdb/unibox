# TextNode

A run of text.

```dart
TextNode('Join Unibox', fontSize: 22, fontWeight: FontWeight.bold);
```

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `text` | `String` | required | The characters to draw. |
| `headingLevel` | `int?` | none | `1`–`6` makes it a heading: `<h1>`–`<h6>` on the web, a heading of that level in Flutter's accessibility tree. It changes no look. |
| `fontSize` | `double?` | inherited | Logical pixels. |
| `fontWeight` | `FontWeight?` | inherited | `light`, `normal`, `medium`, `semiBold`, `bold` — `300`–`700` on both targets. |
| `color` | `BoxColor?` | inherited | Colour of the glyphs. |
| `lineHeight` | `double?` | inherited | Multiple of the font size. A line box is `fontSize * lineHeight` tall on both targets. |
| `fontFamily` | `String?` | the platform's UI font | One family name, resolved by the host. |
| `letterSpacing` | `double?` | inherited | Extra space between characters, in logical pixels. |
| `decoration` | `TextDecoration?` | inherited | The line drawn across the text: `none`, `lineThrough` or `underline`. |
| `decorationColor` | `BoxColor?` | the glyph colour | The colour of that line. |
| `decorationThickness` | `double?` | the font's own | How thick the line is, in logical pixels. |
| `textAlign` | `TextAlign?` | start | `left`, `center`, `right`, `justify`. |
| `padding` | `BoxSpacing?` | none | The space inside the field; padding on the box around it sits outside the control. |
| `maxLines` | `int?` | unlimited | Number of lines the text may occupy. |
| `overflow` | `TextOverflow?` | none | How text too long for its lines is cut: `clip` or `ellipsis`. With `maxLines` it cuts after those lines, without it on the single line. |
| `style` | `BoxTextStyle?` | none | A bundle of the typography values; a flat parameter wins. |

**On each target.** A `<span>` with the typography as CSS in the browser, a `Text`
in Flutter. A heading becomes `<h1>`–`<h6>` with the browser's own heading styles
turned off (no margin, size or weight of its own), so the tree still decides how it
looks.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
