import 'package:unibox_core/unibox_core.dart' as core;

/// Every scroll offset the page recorded before the application arrived.
///
/// Written once here and implemented twice: a browser reads the record the client script
/// left on `window.unibox`, and every other platform answers with nothing, because there is
/// no page to read. The host calls this where it does its other reads — the url it was
/// served at, a value from storage — and hands the result to [core.BoxScrollOffset]'s
/// consumer, `UniboxScrollScope`.
///
/// ```dart
/// runApp(UniboxScrollScope(offsets: scrollOffsetsFromPage(), child: page.toWidget()));
/// ```
///
/// It is an empty list on iOS, Android and in a test, which is what a build with no
/// document in front of it should start from.
List<core.BoxScrollOffset> scrollOffsetsFromPage() =>
    const <core.BoxScrollOffset>[];
