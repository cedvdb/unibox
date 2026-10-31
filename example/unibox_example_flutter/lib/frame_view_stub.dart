import 'package:flutter/widgets.dart';

/// A frame on a target with no browser: the window, and nothing in it.
///
/// Only a browser has documents, so an application running anywhere else has nothing to put
/// in a frame. The box around it still draws its border and its surface, so the diagram
/// keeps both of its windows, and the empty window is the page saying which of its parts
/// this target cannot show.
Widget frameView({required String src, required String title}) =>
    SizedBox.expand(key: ValueKey<String>(src));
