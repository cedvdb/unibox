import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:unibox_core/unibox_core.dart' as core;

/// Every press the page recorded before the application arrived, read from the script the
/// document ran.
///
/// The record is `window.unibox.takePressed()`, which hands over the presses since the page
/// arrived and clears itself — so asking twice does not answer a press twice.
///
/// A press is only worth replaying where the tree can name the node that took it, so what comes
/// back is data: [core.replayPresses] decides whether the tree has an answer.
List<core.BoxPress> pressesFromPage() {
  final Object? taken = _take('takePressed');

  if (taken is! List<Object?>) {
    return const <core.BoxPress>[];
  }

  return <core.BoxPress>[
    for (final Object? record in taken)
      if (record is Map<Object?, Object?>) ?_read(record),
  ];
}

/// [record] as a press, or `null` when it names no element.
core.BoxPress? _read(Map<Object?, Object?> record) {
  final Object? key = record['key'];

  if (key is! String) {
    return null;
  }

  return core.BoxPress(
    key: key,
    dx: _number(record['dx']),
    dy: _number(record['dy']),
  );
}

/// The value [method] of `window.unibox` returns, or `null` when there is no such thing.
///
/// Every read is defensive: a build with no client script, a page whose script is an older one —
/// each answers with nothing rather than throwing in the boot path of an application. A dropped
/// press is a press the reader makes again; an exception is a blank screen.
Object? _take(String method) {
  final JSObject? api = globalContext.getProperty<JSObject?>('unibox'.toJS);

  if (api == null || api.getProperty<JSAny?>(method.toJS) == null) {
    return null;
  }

  return api.callMethod<JSAny?>(method.toJS)?.dartify();
}

double _number(Object? value) => switch (value) {
  final num number => number.toDouble(),
  _ => 0,
};
