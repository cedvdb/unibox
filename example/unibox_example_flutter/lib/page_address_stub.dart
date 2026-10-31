/// The address this application was started from, on a target with no document.
///
/// A phone or a desk has no address bar, so there is nothing to route on and the tree that
/// draws is the one every address but the build's root draws: the example.
Uri get pageAddress => Uri.base;
