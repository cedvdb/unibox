import 'package:unibox_core/unibox_core.dart' as core;

import 'appearance.dart';

/// One box together with the presentation every renderer has to give it.
///
/// A renderer suite renders [box], reads the presentation back from its own
/// output and compares it with [expected]. Since both renderers are checked
/// against the same entry, the entry is the only place the answer is written
/// down: it cannot be relaxed for one target without failing the other.
final class BoxCase {
  /// Creates a case named [description] that renders [box] into [expected].
  const BoxCase({
    required this.description,
    required this.box,
    required this.expected,
  });

  /// What the case describes, phrased as the test that checks it.
  final String description;

  /// The box to render.
  final core.Box box;

  /// The presentation the rendered output has to have.
  final BoxAppearance expected;

  @override
  String toString() => 'BoxCase($description)';
}

/// The boxes every renderer is checked against.
///
/// The table takes the tokens a box can carry one by one — each case sets a
/// single token and expects the presentation of a plain box plus that token —
/// and then all of them at once, so a renderer has to both honour a token on its
/// own and keep honouring it next to the others.
///
/// Every case lays out the same two empty children: `gap` only becomes visible
/// between children, and a case that could not show its own token would pass on
/// a renderer that ignores it.
const List<BoxCase> boxCases = <BoxCase>[
  BoxCase(
    description: 'renders a box without tokens as a flex column at the start',
    box: core.Box(children: _children),
    expected: BoxAppearance(),
  ),
  BoxCase(
    description: 'lays the children out in a row for Axis.horizontal',
    box: core.Box(direction: core.Axis.horizontal, children: _children),
    expected: BoxAppearance(direction: core.Axis.horizontal),
  ),
  BoxCase(
    description: 'distributes the children with mainAlign',
    box: core.Box(mainAlign: core.MainAlign.spaceBetween, children: _children),
    expected: BoxAppearance(mainAlign: core.MainAlign.spaceBetween),
  ),
  BoxCase(
    description: 'aligns the children across the axis with crossAlign',
    box: core.Box(crossAlign: core.CrossAlign.center, children: _children),
    expected: BoxAppearance(crossAlign: core.CrossAlign.center),
  ),
  BoxCase(
    description: 'keeps a gap between two children',
    box: core.Box(gap: 12, children: _children),
    expected: BoxAppearance(gap: 12),
  ),
  BoxCase(
    description: 'keeps the padding inside the border',
    box: core.Box(padding: core.BoxSpacing.all(8), children: _children),
    expected: BoxAppearance(padding: core.BoxSpacing.all(8)),
  ),
  BoxCase(
    description: 'keeps an asymmetric padding on the edges it names',
    box: core.Box(
      padding: core.BoxSpacing.symmetric(horizontal: 12, vertical: 4),
      children: _children,
    ),
    expected: BoxAppearance(
      padding: core.BoxSpacing.symmetric(horizontal: 12, vertical: 4),
    ),
  ),
  BoxCase(
    description: 'keeps the padding inside the border and the margin outside',
    // Both insets in one case: a padding and a margin of the same size are
    // indistinguishable in a widget tree that paints nothing between them, so a
    // case with only one of the two could not be read back on both targets.
    box: core.Box(
      padding: core.BoxSpacing.all(4),
      margin: core.BoxSpacing.all(6),
      children: _children,
    ),
    expected: BoxAppearance(
      padding: core.BoxSpacing.all(4),
      margin: core.BoxSpacing.all(6),
    ),
  ),
  BoxCase(
    description: 'sizes the box to its width',
    box: core.Box(width: 120, children: _children),
    expected: BoxAppearance(width: 120),
  ),
  BoxCase(
    description: 'expands a width of double.infinity over the available space',
    box: core.Box(width: double.infinity, children: _children),
    expected: BoxAppearance(width: double.infinity),
  ),
  BoxCase(
    description: 'sizes the box to its height',
    box: core.Box(height: 40, children: _children),
    expected: BoxAppearance(height: 40),
  ),
  BoxCase(
    description: 'paints the background colour behind the box',
    box: core.Box(backgroundColor: _blue, children: _children),
    expected: BoxAppearance(backgroundColor: _blue),
  ),
  BoxCase(
    description: 'paints a translucent background in its own alpha',
    box: core.Box(backgroundColor: _veil, children: _children),
    expected: BoxAppearance(backgroundColor: _veil),
  ),
  BoxCase(
    description: 'rounds the corners by borderRadius',
    box: core.Box(borderRadius: 8, children: _children),
    expected: BoxAppearance(borderRadius: 8),
  ),
  BoxCase(
    description: 'rounds only the corners it names',
    box: core.Box(
      corners: core.BoxBorderRadius(topLeft: 8, topRight: 8),
      children: _children,
    ),
    expected: BoxAppearance(
      corners: core.BoxBorderRadius(topLeft: 8, topRight: 8),
    ),
  ),
  BoxCase(
    description: 'draws the border of the box',
    box: core.Box(
      border: core.BoxBorder(width: 2, color: _line),
      children: _children,
    ),
    expected: BoxAppearance(borderWidth: 2, borderColor: _line),
  ),
  BoxCase(
    description: 'eases a look change over a duration with a curve',
    // A transition eases paint, so the case paints something: a box with nothing
    // to change has nothing to ease on either target.
    box: core.Box(
      backgroundColor: _blue,
      transition: core.BoxTransition(
        duration: Duration(milliseconds: 150),
        curve: core.BoxCurve.easeOut,
      ),
      children: _children,
    ),
    expected: BoxAppearance(
      backgroundColor: _blue,
      transitionDuration: Duration(milliseconds: 150),
      transitionCurve: core.BoxCurve.easeOut,
    ),
  ),
  BoxCase(
    description: 'fades the box without giving up its room',
    box: core.Box(opacity: 0.4, children: _children),
    expected: BoxAppearance(opacity: 0.4),
  ),
  BoxCase(
    description: 'moves, turns and scales the box about its centre',
    box: core.Box(
      transform: core.BoxTransform(
        scale: 1.5,
        rotation: 15,
        offsetX: 6,
        offsetY: -8,
      ),
      children: _children,
    ),
    expected: BoxAppearance(
      // A rendering can only report the two axis factors: `scale` is a shorthand
      // for stretching both, and a matrix does not remember which was written.
      transform: core.BoxTransform(
        scaleX: 1.5,
        scaleY: 1.5,
        rotation: 15,
        offsetX: 6,
        offsetY: -8,
      ),
    ),
  ),
  BoxCase(
    description: 'moves the box by a multiple of its own width',
    box: core.Box(
      transform: core.BoxTransform(fractionX: 1.5),
      children: _children,
    ),
    // A fraction is a translate of the box's own size, which is how a tab indicator moves one
    // tab: `translate(150%, 0%)`, not `translate(150px, 0px)`.
    expected: BoxAppearance(transform: core.BoxTransform(fractionX: 1.5)),
  ),
  BoxCase(
    description: 'takes a share of the width it is given',
    box: core.Box(widthFraction: 0.5, children: _children),
    // A share rather than a length: `width: 50%` is the statement a box makes when the number is
    // the layout's business, and it wins over a stated width.
    expected: BoxAppearance(widthFraction: 0.5),
  ),
  BoxCase(
    description: 'stretches the box on one axis and not the other',
    box: core.Box(
      transform: core.BoxTransform(scaleX: 0.4),
      children: _children,
    ),
    expected: BoxAppearance(
      transform: core.BoxTransform(scaleX: 0.4, scaleY: 1),
    ),
  ),
  BoxCase(
    description: 'merges the style bags in the order they are given',
    box: core.Box(
      styles: <core.BoxStyle>[
        core.BoxStyle(
          gap: 8,
          padding: core.BoxSpacing.all(4),
          backgroundColor: _blue,
        ),
        core.BoxStyle(padding: core.BoxSpacing.all(12), borderRadius: 6),
      ],
      children: _children,
    ),
    // The second bag wins the padding and adds a radius; the first keeps the gap
    // and the colour it is the only one to name.
    expected: BoxAppearance(
      gap: 8,
      padding: core.BoxSpacing.all(12),
      backgroundColor: _blue,
      borderRadius: 6,
    ),
  ),
  BoxCase(
    description: 'presents every token at once',
    box: core.Box(
      direction: core.Axis.horizontal,
      mainAlign: core.MainAlign.spaceBetween,
      crossAlign: core.CrossAlign.center,
      gap: 8,
      padding: core.BoxSpacing.symmetric(horizontal: 18, vertical: 12),
      margin: core.BoxSpacing.all(6),
      width: 320,
      height: 96,
      widthFraction: 0.75,
      backgroundColor: core.BoxColor.white,
      borderRadius: 10,
      border: core.BoxBorder(color: _line),
      transition: core.BoxTransition(
        duration: Duration(milliseconds: 120),
        curve: core.BoxCurve.easeIn,
      ),
      opacity: 0.75,
      transform: core.BoxTransform(scale: 1.25, scaleY: 0.8, fractionY: 0.25),
      children: _children,
    ),
    expected: BoxAppearance(
      direction: core.Axis.horizontal,
      mainAlign: core.MainAlign.spaceBetween,
      crossAlign: core.CrossAlign.center,
      gap: 8,
      padding: core.BoxSpacing.symmetric(horizontal: 18, vertical: 12),
      margin: core.BoxSpacing.all(6),
      height: 96,
      widthFraction: 0.75,
      backgroundColor: core.BoxColor.white,
      borderRadius: 10,
      borderWidth: 1,
      borderColor: _line,
      transitionDuration: Duration(milliseconds: 120),
      transitionCurve: core.BoxCurve.easeIn,
      opacity: 0.75,
      transform: core.BoxTransform(scaleX: 1.25, scaleY: 1, fractionY: 0.25),
    ),
  ),
];

/// The two empty children every case lays out, so `gap` has something to sit
/// between.
const List<core.UINode> _children = <core.UINode>[core.Box(), core.Box()];

/// The accent blue of the table.
const core.BoxColor _blue = core.BoxColor.rgb(0x2D, 0x6C, 0xF3);

/// A half transparent ink, for the alpha of a background.
const core.BoxColor _veil = core.BoxColor(0x80112233);

/// The hairline grey of the borders in the table.
const core.BoxColor _line = core.BoxColor.rgb(0xE5, 0xE7, 0xEB);
