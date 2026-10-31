# StackNode and PositionedNode

`StackNode` layers its children on top of each other, painted in order, the last one
on top. `PositionedNode` places one of them at an offset from the edges.

```dart
StackNode(
  width: double.infinity,
  height: 120,
  children: <UINode>[
    Box(
      width: double.infinity,
      height: 120,
      backgroundColor: BoxColor.rgb(0x2D, 0x6C, 0xF3),
    ),
    PositionedNode(bottom: 8, left: 16, child: TextNode('Sale')),
  ],
);
```

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `StackNode.children` | `List<UINode>` | empty | The layers, bottom first. |
| `StackNode.width`, `height` | `double?` | largest child | The box the stack occupies. |
| `PositionedNode.child` | `UINode` | required | The node being placed. |
| `PositionedNode.top`, `right`, `bottom`, `left` | `double?` | auto | Distances from the edges of the stack. At least one is needed to place it. |
| `PositionedNode.alignment` | `BoxAlignment?` | none | Where in the stack the child sits, instead of at offsets: the child fills the stack and the alignment places it. This is how a control floats at the bottom centre of a surface at any window size. The names are reading ones — `topStart` is the corner the words begin at — so a page written right to left mirrors without a second tree. |

**Worth knowing.** A stack does not clip: a child that sticks out is still drawn,
which is what CSS does by default and what `Stack` does with `Clip.none`. A child
that is not positioned keeps its own size in the top start corner instead of
stretching to fill the stack, and a `PositionedNode` with no offset is drawn like a
plain child. A `PositionedNode` outside a stack is reported by `validateTree`,
because its offsets would be silently ignored, and so is one that states an alignment
and an offset together — the child fills the stack when it is aligned, so an offset
would have nothing left to move. A stack that places every child and states no size
is reported too: it has nothing in its flow to be as big as, and the two targets then
disagree — Flutter's `Stack` takes the room it is handed while a browser's grid
collapses. State a width and a height, as a frame or a screen does.

**A floating control** is an aligned child with a margin: it stays where the surface
puts it while everything under it scrolls, and no window is measured to know where
the bottom centre is.

---

[All nodes](README.md) · [Back to the README](../../README.md#the-nodes)
