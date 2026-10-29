import 'package:unibox_core/unibox_core.dart' as core;

/// Every press the page recorded before the application arrived.
///
/// There is no page on iOS, Android or in a test, so the answer is nothing — which is what a
/// build with no document in front of it should start from.
List<core.BoxPress> pressesFromPage() => const <core.BoxPress>[];
