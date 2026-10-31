# The nodes

The eleven node types of [`unibox_core`](../../packages/unibox_core/README.md), in ten
pages: `PositionedNode` is documented beside the `StackNode` it places in. A page holds
the parameters a node takes, the defaults the model gives it, and what each renderer does
with it.

| Node | What it is | Page |
| --- | --- | --- |
| `Box` | the container, its layout and paint tokens, and the shapes it can be painted in | [Box](box.md) |
| `TextNode` | a run of text, its typography and its heading level | [TextNode](text.md) |
| `ImageNode` | a picture, its fit, and the responsive attributes only the web reads | [ImageNode](image.md) |
| `LinkNode` | a box that names a destination, and what cannot be one | [LinkNode](link.md) |
| `StackNode`, `PositionedNode` | layers, and one child placed at an offset | [StackNode and PositionedNode](stack.md) |
| `TextInputNode` | a single line field, a password field or a text area | [TextInputNode](text-input.md) |
| `StatefulNode` | a store, a view, and the lifecycle a renderer calls | [StatefulNode](stateful.md) |
| `GridNode` | columns that follow the width, or a row of stated factors | [GridNode](grid.md) |
| `OverlayNode` | a dialog, a sheet or a menu, and the policy behind it | [OverlayNode](overlay.md) |
| `EmbedNode` | one implementation per renderer, for what the model cannot describe | [EmbedNode](embed.md) |

Every node accepts a `key`, which the renderers hand to the target's own key mechanism,
so a reordered list keeps each child's state. A node is immutable and has a `const`
constructor; the values it takes are documented once, in the
[README](../../README.md): [colours](../../README.md#colours),
[roles and theming](../../README.md#roles-and-theming),
[typography](../../README.md#typography), [motion](../../README.md#motion) and
[semantics](../../README.md#semantics).

The Material components built from these nodes are summarised in the
[Material section](../../README.md#material) of the README, and documented in
[`unibox_material`](../../packages/unibox_material/README.md).
