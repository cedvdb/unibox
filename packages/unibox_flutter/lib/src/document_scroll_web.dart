import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';

/// Reads the document's latest position without consuming keyed region offsets.
Offset documentScrollFromPage() {
  final JSAny? value = globalContext.getProperty<JSAny?>('unibox'.toJS);
  if (value == null || !value.isA<JSObject>()) return Offset.zero;
  final JSObject api = value as JSObject;
  final JSAny? method = api.getProperty<JSAny?>('documentScroll'.toJS);
  if (method == null || !method.isA<JSFunction>()) return Offset.zero;
  final Object? record = api
      .callMethod<JSAny?>('documentScroll'.toJS)
      ?.dartify();
  if (record is! Map<Object?, Object?>) return Offset.zero;
  double number(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : 0;
  return Offset(number(record['dx']), number(record['dy']));
}
