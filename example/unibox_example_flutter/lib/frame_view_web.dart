import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'page_address.dart';

/// The view types this session has registered, one per frame source.
///
/// A factory can be registered once per view type and the element it builds is created per
/// view, so the source has to be part of the type. Registering the same name twice throws,
/// and this set is what keeps a rebuild of the page from doing it again.
final Set<String> _viewTypes = <String>{};

/// A frame a browser draws: a real `iframe`, which is the element the HTML page has.
///
/// The source is relative to the site root and the Flutter build is one directory below it,
/// so `../` is the whole of the translation: the same two documents the document frames,
/// framed by Flutter instead of by markup. That is what keeps the comparison a comparison —
/// the left frame is still HTML and the right one is still the application.
Widget frameView({required String src, required String title}) {
  final String address = pageAddress.resolve('../$src').toString();
  final String viewType = 'unibox-frame-${address.hashCode}';

  if (_viewTypes.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      return web.HTMLIFrameElement()
        ..src = address
        ..title = title
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block';
    });
  }

  return HtmlElementView(viewType: viewType);
}
