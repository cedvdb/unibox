/// The presentation contract of the two Unibox renderers.
///
/// One table of boxes, one of texts, one of overlays, and the presentation each
/// of them has to be given, checked from the output of every renderer: `unibox_flutter` reads
/// it out of the widget tree it built, `unibox_html` out of the CSS it emitted.
/// Neither reads the node tree, so a renderer that stops honouring a token fails a
/// test instead of drifting away from the other one.
///
/// This package holds the contract, not the tests. A renderer suite imports it,
/// extracts a [BoxAppearance], a [TextAppearance] or an [OverlayAppearance]
/// from its own output and compares it with the one the case it rendered
/// expects.
///
/// What the contract covers is the appearance both targets can express exactly.
/// What is left out is left out on purpose: a text is compared by the typography
/// it asks for, never by the pixels it paints, because glyph shapes, hinting and
/// line breaking belong to the text engine and a browser and Flutter do not have
/// the same one.
library;

export 'src/appearance.dart';
export 'src/cases.dart';
export 'src/overlay_appearance.dart';
export 'src/overlay_cases.dart';
export 'src/text_appearance.dart';
export 'src/text_cases.dart';
