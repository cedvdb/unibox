# unibox_element

What an element is, before anyone writes it.

`ElementPlan` is one node's answer: the tag it becomes, the attributes it carries and in what
order, the class it wears, the text inside it, and the elements inside that. `planNode` is what
turns a tree into one, and `Stylesheet` gives every look its class, once.

It holds no markup. A string renderer writes a plan to HTML; a DOM renderer builds nodes from the
same plan. That is what makes **one** element plan rather than two: a second web renderer reads
this package instead of deciding again what a `Box` looks like — and a renderer that decided
again would draw the same tree two ways, which is the drift this repository exists to prevent.

## What it answers

| Question | Answer |
| --- | --- |
| what does this tree become? | `planNode(node, sheet)` → an `ElementPlan` |
| which class does a look wear? | `sheet.classFor(kind, declarations)`, a hash of the declarations — or `classForLook(look, kind, () => declarations)`, which composes a look once however many nodes wear it |
| which rules does the tree need? | `sheet.css`, one rule per look and one per state |
| what does a page still need? | `sheet.mark` and `sheet.rulesSince(mark)`, the rules added since a renderer wrote the sheet — so a page is appended to, not rewritten |
| which rules may go? | `sheet.retain(classes)`, which forgets every rule of a class the page does not wear |
| may a destination be followed? | `isRiskyUrl`, `safeUrlValue` — a script url becomes `#` |
| which element is a link? | `linkAttributes(url, newTab:)` — the `href`, and the `target`/`rel` a new tab needs — for a `LinkNode`, which *is* the `<a>` |
| which tag does a box become? | `elementOf(box)` — the element it states, or the anchor a `url` makes it; an anchor with no destination is a placeholder, and names none |
| what does a control announce? | `boxAttributes(box)` — no `role`, no `tabindex` and no control state on an anchor, because the tag is the role |
| how is an embed drawn? | the renderer says, through `PlanOptions.embed` |

## What it deliberately does not do

- **No escaping.** Values are values; the renderer that writes them escapes them, and a DOM
  renderer sets them where no escaping exists. The one exception is `ElementPlan.raw`, which is
  markup the host wrote and trusts — an embed.
- **No markup.** Nothing here returns a `String` of HTML except `Stylesheet.css`, which is CSS.
