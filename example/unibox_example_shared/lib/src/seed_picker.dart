import 'package:unibox_core/unibox_core.dart';

import 'theme.dart';

/// The row of palettes the page can be drawn with.
///
/// The example page puts it above its navigation bar and the catalogue puts it above
/// its specimens: one builder, so the two cannot drift into two different pickers.
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
UINode seedPicker({required ExampleSeed current, String label = 'Palette'}) {
  return Box(
    direction: Axis.horizontal,
    mainAlign: MainAlign.center,
    crossAlign: CrossAlign.center,
    width: double.infinity,
    gap: 8,
    padding: const BoxSpacing.symmetric(horizontal: 24, vertical: 8),
    backgroundColor: const BoxColor.role(ExampleColor.panel),
    textStyle: ExampleType.muted,
    children: <UINode>[
      TextNode(label),
      for (final ExampleSeed seed in ExampleSeed.values)
        LinkNode(
          '?seed=${seed.name}',
          child: Box(
            width: 22,
            height: 22,
            borderRadius: 11,
            backgroundColor: seed.accent,
            // The seed in force is ringed: a swatch of its own accent does not say
            // which of the six the page is drawn with.
            border: BoxBorder(
              width: seed == current ? 2 : 1,
              color: BoxColor.role(
                seed == current ? ExampleColor.text : ExampleColor.border,
              ),
            ),
            semantics: BoxSemantics(
              role: BoxRole.link,
              label: seed == current
                  ? '${seed.label} palette, in force'
                  : '${seed.label} palette',
            ),
            stateStyles: const <BoxState, BoxStyle>{
              BoxState.hover: BoxStyle(transform: BoxTransform(scale: 1.15)),
            },
            transition: ExampleType.transition,
          ),
        ),
    ],
  );
}
