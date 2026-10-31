import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_flutter/unibox_flutter.dart';

import 'frame_view_stub.dart'
    if (dart.library.js_interop) 'frame_view_web.dart'
    as platform;

/// A frame of the site's comparison, as a node this target can draw.
///
/// A frame is a document inside a document — the one thing the model cannot describe — so
/// it reaches the tree as a builder (`ShowcaseFrame`) and each host answers it with what it
/// has: a real `iframe` in a browser, and nothing but the window on a target without one.
UINode showcaseFrame({required String src, required String title}) =>
    _filled(FlutterWidgetNode(platform.frameView(src: src, title: title)));

/// The box that gives a frame the rectangle it fills.
///
/// A flex lays its children out on an unbounded main axis — both of them, so neither a row
/// nor a column can tell a child how big the box is. A *stack* is the one layout in the model
/// that takes the box's own constraints, and `height: double.infinity` is the share of the
/// height the tree gave the frame: together they are the `height: 100%` the document's frame
/// states, in the vocabulary both targets already share.
UINode _filled(UINode child) => Box(
  width: double.infinity,
  height: double.infinity,
  children: <UINode>[
    StackNode(
      // The layer states the rectangle it places the frame in: a box that hugs its content
      // is a stack of no width, and a document drew the frame while the app, whose stack
      // takes the room it is handed, put nothing in its window.
      width: double.infinity,
      height: double.infinity,
      children: <UINode>[
        PositionedNode(alignment: BoxAlignment.center, child: child),
      ],
    ),
  ],
);
