/// The attribute that ties an element to the node that drew it.
///
/// The renderer writes it on every element a keyed node produced, and it is how everything
/// outside the tree finds that element again: a recorded press, a recorded scroll offset,
/// and — later — the runtime that adopts the page.
///
/// It is written only when the key is a `String` or an `int`: any other key's `toString()`
/// is an instance hash, which names one node two ways across a server and a browser.
const String nodeKeyAttribute = 'data-unibox-key';
