import 'package:unibox_core/unibox_core.dart' as core;

import 'declarations.dart';
import 'values.dart';

/// The declarations of a text node.
///
/// Only the typography tokens the node states are written, so the text inherits
/// everything else from the box around it — which is what a Flutter `Text` does inside
/// a `DefaultTextStyle`.
///
/// A heading arrives from a user agent with a size, a bold weight and a margin of its
/// own, none of which is in the model: a heading is structure. The reset states only the
/// tokens the node does not, so the tree's typography stays in charge and a heading
/// looks exactly like the text it would be without the element.
CssDeclarations textDeclarations(core.TextNode node) {
  final core.TextAlign? align = node.textAlign;
  final CssDeclarations declarations = CssDeclarations()
    ..addAllIn(typographyDeclarations(node.computedStyle) ?? CssDeclarations())
    ..addIf('text-align', align == null ? null : cssTextAlign(align));

  final int? maxLines = node.maxLines;
  final core.TextOverflow? overflow = node.overflow;

  if (maxLines != null) {
    // Clamping to a number of lines needs the prefixed box layout, which no typed
    // property exposes.
    declarations
      ..add('display', '-webkit-box')
      ..add('-webkit-box-orient', 'vertical')
      ..add('-webkit-line-clamp', '$maxLines')
      ..add('overflow', 'hidden')
      ..addIf(
        'text-overflow',
        overflow == core.TextOverflow.clip ? 'clip' : null,
      );
  } else if (overflow != null) {
    declarations
      ..add('overflow', 'hidden')
      ..add(
        'text-overflow',
        overflow == core.TextOverflow.ellipsis ? 'ellipsis' : 'clip',
      )
      ..addIf(
        'white-space',
        overflow == core.TextOverflow.ellipsis ? 'nowrap' : null,
      );
  }

  if (node.headingLevel != null) {
    final core.BoxTextStyle style = node.computedStyle;

    declarations
      ..add('margin', '0')
      ..addIf('font-size', style.fontSize == null ? 'inherit' : null)
      ..addIf('font-weight', style.fontWeight == null ? 'inherit' : null);
  }

  return declarations;
}

/// The declarations of an image node.
///
/// The picture is a block, so it behaves like the leaf box it is in Flutter: no
/// baseline gap under it and no line box contribution. `object-fit` is always written,
/// because left unset a browser stretches the picture over its box, which is not what a
/// Flutter `Image` does.
CssDeclarations imageDeclarations(core.ImageNode node) {
  final double? radius = node.borderRadius;

  return CssDeclarations()
    ..add('display', 'block')
    ..addIf('width', cssLength(node.width))
    ..addIf('height', cssLength(node.height))
    ..addIf('border-radius', radius == null ? null : cssPixels(radius))
    ..add('object-fit', cssObjectFit(node.resolvedFit));
}

/// The declarations of a grid.
///
/// The grid takes the width it is given, because the tracks are counted from it — which
/// is what the Flutter renderer does with the constraints of the same box. A block-level
/// grid already fills its parent, but a box aligns its children to the start by default
/// and a flex item that is not stretched shrinks to fit, where `auto-fill` would then
/// find room for exactly one column.
CssDeclarations gridDeclarations(core.GridNode node) {
  final String minimum = cssPixels(node.minItemWidth);
  final int? cap = node.maxColumns;
  final String tracks;

  if (cap == null) {
    tracks = 'repeat(auto-fill, minmax(min(100%, $minimum), 1fr))';
  } else {
    final double gutters = (cap - 1) * node.gap;
    final String share = gutters == 0
        ? '100% / $cap'
        : '(100% - ${cssPixels(gutters)}) / $cap';

    tracks = 'repeat(auto-fill, minmax(min(100%, max($minimum, $share)), 1fr))';
  }

  return CssDeclarations()
    ..add('display', 'grid')
    ..add('width', '100%')
    ..add('min-width', '0')
    ..addIf('gap', node.gap > 0 ? cssPixels(node.gap) : null)
    ..add('align-items', 'start')
    ..add('grid-template-columns', tracks);
}

/// The declarations of a stack.
///
/// A relative grid whose single row is `100%` of the stack rather than the height of
/// what sits in it. A Flutter stack hands its own constraints to a child that is not
/// positioned, so a child that fills the stack is exactly as tall as the stack and a list
/// with `overflow: auto` inside it scrolls. An `auto` row is at least as tall as its
/// content and only ever grows, so the same cell would be the whole of a long list inside
/// a short window, nothing would scroll and the document would grow instead. `100%`
/// resolves to `auto` when the stack has no height of its own.
CssDeclarations stackDeclarations(core.StackNode node) {
  return CssDeclarations()
    ..add('position', 'relative')
    ..add('display', 'grid')
    ..add('grid-template-rows', '100%')
    ..addIf('width', cssLength(node.width))
    ..addIf('height', cssLength(node.height));
}

/// The declarations of the cell a stack puts each child in.
///
/// The wrapper takes the whole cell and lays its child out at the start of both axes,
/// which is what a Flutter stack does with a child that is not positioned. Sizing the
/// wrapper to its own content looks like the same thing and is not: a child that fills
/// the cell would then resolve its percentage against a wrapper with no width of its own
/// and collapse.
///
/// It takes no pointer of its own: what the cell holds takes the press, and a cell that
/// holds nothing painted lets it through to the cell underneath.
CssDeclarations stackCellDeclarations() {
  return CssDeclarations()
    ..add('display', 'flex')
    ..add('align-items', 'start')
    ..add('justify-content', 'start')
    ..add('pointer-events', 'none')
    ..add('grid-area', '1 / 1');
}

/// The declarations of a positioned node.
///
/// The offsets resolve against the nearest positioned ancestor, which is the stack the
/// node belongs to. When all four offsets are stated and equal they collapse into one
/// `inset`, which is shorter and says the same thing in CSS's order: top, right, bottom,
/// left.
CssDeclarations positionedDeclarations(core.PositionedNode node) {
  final CssDeclarations declarations = CssDeclarations()
    ..add('position', 'absolute');

  final double? top = node.top;
  final double? right = node.right;
  final double? bottom = node.bottom;
  final double? left = node.left;

  if (top != null && top == right && top == bottom && top == left) {
    declarations.add('inset', cssPixels(top));
  } else {
    declarations
      ..addIf('top', cssLength(top))
      ..addIf('right', cssLength(right))
      ..addIf('bottom', cssLength(bottom))
      ..addIf('left', cssLength(left));
  }

  return declarations..add('pointer-events', 'none');
}

/// The declarations of a child placed by an alignment rather than by an offset.
///
/// It fills the stack and a flex alignment puts the child where the alignment says,
/// which is a Flutter `Positioned.fill` with an `Align`: a control pinned to the bottom
/// centre stays there whatever the window is, and no measurement of one is needed.
///
/// The layer takes no pointer: the whole of the stack would otherwise be the topmost
/// thing a press meets, and a button floating over a page would make the page under it
/// unclickable. The child inside restores the pointer when it listens.
CssDeclarations alignedDeclarations(core.BoxAlignment alignment) {
  final core.MainAlign horizontal = switch (alignment) {
    core.BoxAlignment.topStart ||
    core.BoxAlignment.centerStart ||
    core.BoxAlignment.bottomStart => core.MainAlign.start,
    core.BoxAlignment.topCenter ||
    core.BoxAlignment.center ||
    core.BoxAlignment.bottomCenter => core.MainAlign.center,
    core.BoxAlignment.topEnd ||
    core.BoxAlignment.centerEnd ||
    core.BoxAlignment.bottomEnd => core.MainAlign.end,
  };
  final core.CrossAlign vertical = switch (alignment) {
    core.BoxAlignment.topStart ||
    core.BoxAlignment.topCenter ||
    core.BoxAlignment.topEnd => core.CrossAlign.start,
    core.BoxAlignment.centerStart ||
    core.BoxAlignment.center ||
    core.BoxAlignment.centerEnd => core.CrossAlign.center,
    core.BoxAlignment.bottomStart ||
    core.BoxAlignment.bottomCenter ||
    core.BoxAlignment.bottomEnd => core.CrossAlign.end,
  };

  return CssDeclarations()
    ..add('position', 'absolute')
    ..add('inset', '0')
    ..add('display', 'flex')
    ..add('flex-direction', 'row')
    ..add('justify-content', cssJustifyContent(horizontal))
    ..add('align-items', cssAlignItems(vertical))
    ..add('pointer-events', 'none');
}
