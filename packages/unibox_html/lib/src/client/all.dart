import 'press.dart';

/// Every behaviour a document has, as one file.
///
/// A host that wants the lot — ink and press recording — includes this. A host that wants
/// one of them includes that one: each is its own block, guarded so that including two of
/// them (or including one twice) does nothing the second time.
///
/// What is not here, deliberately: nothing that changes a state. Dismissing an overlay,
/// fetching anything, re-rendering a subtree — those need a state to change, and that is
/// the application's job or `unibox_dom`'s.
const String uniboxClientScript = pressScript;
