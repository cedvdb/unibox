import 'package:unibox_core/unibox_core.dart';

import 'theme.dart';

/// The row of palettes the page can be drawn with.
///
/// Six dots and nothing else: the row is a control, not a caption, and each swatch
/// carries the name of the palette it selects, so a reader who cannot see the colour
/// is told which one it is and which one is in force.
///
/// It carries no width, no background and no padding, because where it sits is the
/// page's: the header places it beside the name, and a band of its own would push the
/// name off the row it belongs to.
///
/// A swatch is a link to the page it is on with `?seed=<name>` in the address. The
/// address is what a browser follows, so a document can be rendered in any palette
/// without a runtime; the Flutter host reads the same address in its link policy and
/// rebuilds with another theme instead of loading a page, which is why the picker is
/// a link and not a switch: the tree states where to go, the host decides what going
/// there means.
///
/// The swatch is painted with the accent its seed *grows*, not with the seed itself.
/// A tonal spot palette spends a saturated colour on a low chroma one, so a picker
/// showing the seed would promise a blue and deliver a slate.
UINode seedPicker({required ExampleSeed current}) {
  return Box(
    direction: Axis.horizontal,
    crossAlign: CrossAlign.center,
    gap: 8,
    textStyle: ExampleType.muted,
    children: <UINode>[
      for (final ExampleSeed seed in ExampleSeed.values)
        // The swatch is the link: a destination with no text has to name itself, and the
        // name belongs on the element that navigates. A box wrapped in another box that
        // carried the url would put the name on an element inside the anchor, and a
        // control inside a link is what `validateTree` refuses.
        Box(
          url: '?seed=${seed.name}',
          width: 22,
          height: 22,
          borderRadius: 11,
          backgroundColor: seed.accent,
          // The seed in force is ringed: a swatch of its own accent does not say which
          // of the six the page is drawn with.
          border: BoxBorder(
            width: seed == current ? 2 : 1,
            color: BoxColor.role(
              seed == current ? ExampleColor.text : ExampleColor.border,
            ),
          ),
          semantics: BoxSemantics(
            label: seed == current
                ? '${seed.label} palette, in force'
                : '${seed.label} palette',
          ),
          stateStyles: const <BoxState, BoxStyle>{
            BoxState.hover: BoxStyle(transform: BoxTransform(scale: 1.15)),
          },
          transition: ExampleType.transition,
        ),
    ],
  );
}
