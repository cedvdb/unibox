import 'package:unibox_core/unibox_core.dart' as core;
import 'package:universal_web/web.dart' as web;

/// The press in [event]'s frame, or `null` where nothing can measure one.
///
/// A test renders on the VM: there is no DOM to ask, no pointer to point, and
/// nothing to press. This is what the suites compile against; the browser build
/// uses the real reader beside it.
core.BoxPoint? pressPositionOf(web.Event event) => null;
