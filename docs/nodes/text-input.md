# TextInputNode

A single line field, a password field, or a text area. The node describes what the
field is *for*; the box around it describes what it looks like.

```dart
TextInputNode(
  value: state.email,
  placeholder: 'ada@example.com',
  inputType: InputType.email,
  onChanged: onEmailChanged,
);
```

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `value` | `String?` | `null` | Controlled value. `null` lets the field keep what the user types; a value replaces it. |
| `placeholder` | `String?` | none | Hint shown while the field is empty. |
| `placeholderStyle` | `BoxTextStyle?` | inherit | The hint's typography: `hintStyle` on Flutter, a `::placeholder` rule on the web. |
| `inputType` | `InputType` | `text` | `text`, `email`, `number`, `phone`, `url`: picks the on-screen keyboard and the browser's validation hints. |
| `obscureText` | `bool` | `false` | Hides the characters, for passwords. |
| `multiline` | `bool` | `false` | Renders a text area instead of a single line field. |
| `maxLines` | `int?` | one row | Visible rows of a text area. |
| `enabled` | `bool` | `true` | Disabled fields keep their value and layout and leave the tab order. |
| `readOnly` | `bool` | `false` | Selectable and copyable, not editable. |
| `autofocus` | `bool` | `false` | Takes focus as soon as it is drawn. |
| `required` | `bool` | `false` | The form needs a value here: `aria-required`, and announced with the label in Flutter. |
| `invalid` | `bool` | `false` | The value is wrong, decided by the host: `aria-invalid`, and the invalid state of the field in Flutter. |
| `description` | `String?` | none | What the field expects, or why it was rejected. It is the accessible description (`aria-description`, `Semantics.hint`), not a drawn message: that stays a text node. |
| `semanticsLabel` | `String?` | none | The name a screen reader announces. |
| `onChanged` | `TextChangedCallback?` | none | Fires on every change, with the current text. |
| `onSubmitted` | `TextSubmittedCallback?` | none | Fires on `Enter` (or `Ctrl`/`Cmd`+`Enter` in a text area). |
| `onFocusChanged` | `FocusChangedCallback?` | none | Fires when the field gains or loses focus. |

**Worth knowing.** The field brings no chrome of its own: no Material underline, no
browser border, padding, background, focus ring or resize handle. The box around it
draws what a field should look like, which is the only way the same tree can look
the same on both targets. The typography is the tree's, inherited like any text.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
