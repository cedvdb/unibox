import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:unibox_core/unibox_core.dart' as core;

/// Every scroll offset the page recorded before the application arrived, read from the
/// script the document ran.
///
/// The record is `window.unibox.takeScroll()`, which reads the page again before answering
/// and clears itself — so the value is the position at the moment the application asks, and
/// asking twice does not move a region twice.
///
/// Every read is defensive: a build with no client script, a page whose script is an older
/// one, a record that is not what we expect — each answers with nothing rather than throwing
/// in the boot path of an application. A wrong offset is a jump; an exception is a blank
/// screen.
List<core.BoxScrollOffset> scrollOffsetsFromPage() {
  final JSObject? api = globalContext.getProperty<JSObject?>('unibox'.toJS);

  if (api == null) {
    return const <core.BoxScrollOffset>[];
  }

  if (api.getProperty<JSAny?>('takeScroll'.toJS) == null) {
    return const <core.BoxScrollOffset>[];
  }

  final Object? taken = api.callMethod<JSAny?>('takeScroll'.toJS)?.dartify();

  if (taken is! List<Object?>) {
    return const <core.BoxScrollOffset>[];
  }

  return <core.BoxScrollOffset>[
    for (final Object? record in taken)
      if (record is Map<Object?, Object?>) ?_read(record),
  ];
}

/// [record] as an offset, or `null` when it names no region.
///
/// A record without a key cannot be placed, and guessing where it belongs would move the
/// wrong region, so it is dropped instead.
core.BoxScrollOffset? _read(Map<Object?, Object?> record) {
  final Object? key = record['key'];

  if (key is! String) {
    return null;
  }

  return core.BoxScrollOffset(
    key: key,
    dx: _number(record['dx']),
    dy: _number(record['dy']),
  );
}

double _number(Object? value) => switch (value) {
  final num number => number.toDouble(),
  _ => 0,
};
