# unibox_dom

The same tree, drawn into a browser's DOM — the third renderer, and the one that makes a
document interactive without Flutter.

`unibox_html` writes a tree as markup a crawler reads. This package builds the same
elements in the page and keeps them in step with the stores a `StatefulNode` created, so a
press runs a Dart closure because it is a closure in the same program as the store — no
attribute protocol, no handler name a host has to implement in JavaScript.

```dart
import 'package:unibox_dom/unibox_dom.dart';
import 'package:web/web.dart' as web;

void main() {
  // The markup the server wrote, adopted and then kept live.
  DomView.adopt(siteTree(), web.document.body!.firstElementChild!, theme: theme);
}
```

Two ways to start, and they differ in one thing — what happens to the page that is already
there:

| | |
| --- | --- |
| `DomView.mount(tree, host)` | the host is emptied and the tree is built from nothing: a page with no server rendering, or a subtree that appears later |
| `DomView.adopt(tree, root)` | the elements the server wrote are **kept**, compared with the plan and patched where they differ, so a reader who has scrolled, focused a field or selected text keeps all three |

`adopt` is the one a takeover and a standalone page both use, and it works because the two
renderers share their two decisions: the **element plan** (`unibox_element`) says which
element a node becomes and in which order its attributes are written, and the **stylesheet**
(`unibox_css`) gives every look one class name derived from its declarations. Same tree,
same tags, same classes — so there is nothing to reconcile.

`render(tree)` swaps the tree of a view that is already drawing, which is what a palette
change is: the plan differs only in the custom properties the roles resolve to.

## How it updates

A publish from a `StatefulNode`'s store re-plans **that node's subtree** and patches it in
place: a child that is still there is patched where it stands rather than replaced, so a
field keeps its focus and a list keeps its elements when it reorders. `dispose()` unsubscribes
every store and removes the listeners, which is what a view that is going away does.

## What it is not

Not a general-purpose framework. There is no virtual DOM diff of arbitrary trees, no
scheduler, no component lifecycle beyond `StatefulNode`, and no hydration of markup the
server did not produce. The tree is pure and the state boundaries are known, which is what
makes patching at those boundaries enough.

## Testing

Client only, so its suite runs in a browser:

```shell
(cd packages/unibox_dom && dart test -p chrome)
```

## Depends on

`unibox_core`, `unibox_css`, `unibox_element` and `package:web`. It is compiled by the host
(`dart compile js`) and never imported by a server.
