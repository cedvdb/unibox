import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'labels.dart';

/// Records where the reader scrolled to, so the tree that takes the page over can
/// start there.
///
/// A page can be two things in a row: static HTML a reader scrolls, and then the
/// Flutter application that replaces it. The application paints into a canvas the
/// size of the viewport, so the browser's own scroll position is not something it
/// can inherit — the only scrollable thing left is a box in the tree. This
/// component is the half of the handover that reads the static page: it records the
/// offset of every element a node keyed ([nodeKeyAttribute]) and hands the record
/// to the runtime that boots next.
///
/// ```js
/// // What the runtime reads. The shape is a list of the scroll regions:
/// // [{ key: 'listings', dx: 0, dy: 1400 }]
/// window.uniboxScroll.take();
/// ```
///
/// It is a `<script>` and not a compiled entry point: a takeover page is static
/// HTML with no client of its own to extend, so a second bundle would put a
/// download in front of the bootstrap for the fifteen lines that arrive inside the
/// markup already on the wire.
///
/// [renderJaspr] places it above the tree, so a host writes no wiring; the record
/// lives on `window`, not in an element, because the takeover replaces the elements
/// and the listeners with them.
///
/// A page served under a content security policy that refuses inline script needs
/// [nonce], or [scrollRecorderScript] written to a file of its own and served from
/// there — the string is public for exactly that reason.
class JasprScrollRecorder extends StatelessComponent {
  /// Creates the recorder, with [nonce] for a policy that refuses inline script.
  const JasprScrollRecorder({this.nonce, super.key});

  /// The `nonce` the policy of the page expects, if it has one.
  final String? nonce;

  @override
  Component build(BuildContext context) {
    final String? nonce = this.nonce;

    return Component.element(
      tag: 'script',
      attributes: nonce == null ? null : <String, String>{'nonce': nonce},
      children: <Component>[const RawText(scrollRecorderScript)],
    );
  }
}

/// The recorder, as the script a page carries.
///
/// Written with `RawText` because `<script>` is a raw text element: nothing inside
/// it is escaped, and a script written as text would ship `&amp;&amp;` for `&&`
/// and not run at all.
///
/// It reads an offset where the reader is, not where they were: a `scroll` listener
/// keeps the last record current, and `take()` reads once more so the answer is the
/// position at the moment the runtime asks, however long the reader has left the
/// page alone. Registering the listeners before the tree is parsed costs nothing and
/// is what makes them older than the first scroll anyone can make.
const String scrollRecorderScript =
    '''
(function () {
  if (window.uniboxScroll) { return; }
  var attribute = '$nodeKeyAttribute';
  var recorded = [];
  function snapshot() {
    var found = [];
    var elements = document.querySelectorAll('[' + attribute + ']');
    for (var i = 0; i < elements.length; i++) {
      found.push({
        key: elements[i].getAttribute(attribute),
        dx: elements[i].scrollLeft || 0,
        dy: elements[i].scrollTop || 0
      });
    }
    recorded = found;
  }
  window.uniboxScroll = {
    snapshot: snapshot,
    take: function () {
      snapshot();
      var taken = recorded;
      recorded = [];
      return taken;
    }
  };
  document.addEventListener('scroll', snapshot, { capture: true, passive: true });
  document.addEventListener('visibilitychange', snapshot);
  window.addEventListener('pointerdown', snapshot, { passive: true });
  window.addEventListener('pagehide', snapshot);
})();
''';
