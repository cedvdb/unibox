import 'package:unibox_core/unibox_core.dart';

import 'material_ink_well.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// One tab of a [MaterialTabBar]: what it says, and optionally a glyph above it.
///
/// The label is a node rather than a string, so a tab can carry an icon beside its text the
/// way a Material 3 primary tab does.
final class MaterialTab {
  /// Creates a tab around [label].
  const MaterialTab({required this.label, this.icon, this.semanticsLabel});

  /// What the tab says.
  final UINode label;

  /// A glyph shown above the label, when the tab is easier to read as a picture.
  final UINode? icon;

  /// What a screen reader calls the tab, when the label is not enough.
  final String? semanticsLabel;
}

/// Called with the index of the tab a reader pressed.
///
/// It is the bar's own callback rather than a `TapCallback`: a bar is one node around many
/// tabs, so the index is the only thing that tells the caller which of them it was.
typedef TabSelectCallback = void Function(int index);

/// How wide the tabs are.
enum MaterialTabVariant {
  /// Evenly distributed across the width, which is what a set of top-level destinations
  /// does. Material's *primary* tabs.
  primary,

  /// As wide as their label, packed to the start, which is what tabs inside a page do.
  /// Material's *secondary* tabs.
  secondary,
}

/// A Material 3 tab bar: one row of tabs, an indicator under the chosen one, and the
/// hairline the row sits on.
///
/// ```dart
/// MaterialTabBar(
///   tabs: const <MaterialTab>[
///     MaterialTab(label: TextNode('Overview')),
///     MaterialTab(label: TextNode('Listings')),
///     MaterialTab(label: TextNode('Reviews')),
///   ],
///   selected: 1,
///   onSelect: (int index) => chosen = index,
/// )
/// ```
///
/// It is a box around a row of boxes, each around a [MaterialInkWell], so both renderers
/// draw it with the nodes they already have. The look is the tokens: the chosen tab's label
/// takes `primary` and the others `onSurfaceVariant`, the indicator is three pixels of
/// `primary` under the chosen tab alone, and the row's hairline is a shadow with no blur,
/// because a border draws on all four sides.
///
/// **The two variants place the indicator differently, because they size a tab
/// differently.** A [MaterialTabVariant.primary] bar gives every tab the same share, so one
/// indicator a share wide moves by a multiple of *its own* width and slides to the chosen
/// tab without anyone measuring one. A [MaterialTabVariant.secondary] bar gives a tab the
/// width of its label, and labels are not the same width, so a share would land under no
/// tab at all: each tab carries its own underline instead, laid across the bottom of a
/// stack its own label sizes — which needs no measurement either, because the underline
/// spans the box that holds the label. The chosen tab's underline fades in rather than
/// sliding, since the distance between two tabs is the one thing this tree cannot state.
///
/// **A bar shows nothing itself.** It says which tab is chosen and reports a press; the node
/// that draws a page is [MaterialTabs], or the application's own view. Keeping the two apart
/// is what lets a bar sit above a page that swaps, above a pager, or beside a preview — the
/// choice is the tree's state in every case.
///
/// A tab says `role="tab"` inside a `role="tablist"`, and which of the set is chosen travels as
/// `selected` — `aria-selected` on the web and Flutter's own selected flag. It is not a button:
/// a button does something, and this one is one of a set.
final class MaterialTabBar extends Box {
  /// Creates a bar of [tabs], with [selected] drawn as the chosen one.
  ///
  /// [palette] answers the colour roles; without it the baseline light values are written
  /// out, exactly as [MaterialCard] does.
  MaterialTabBar({
    super.key,
    required List<MaterialTab> tabs,
    required int selected,
    TabSelectCallback? onSelect,
    MaterialTabVariant variant = MaterialTabVariant.primary,
    BoxColor? indicator,
    MaterialPalette? palette,
    super.margin,
  }) : super(
         height: tabHeight,
         width: double.infinity,
         // The row fills the bar, and it only can if the bar hands its width down: a box
         // starts its children by default, so the layer inside was as wide as the tabs it
         // held — 210 pixels of a 1080 pixel bar, packed at the left, with a "share" of the
         // bar that was really a share of the three labels.
         crossAlign: CrossAlign.stretch,
         // The set the tabs belong to. A reader is told it has entered a tab bar, which is what makes
         // the tabs inside it mean "one of these" rather than several buttons.
         semantics: const BoxSemantics(role: BoxRole.tablist),
         shadow: BoxShadow(
           color: palette?.outlineVariant ?? const BoxColor(0xFFD6C2C5),
           offsetY: 1,
           blurRadius: 0,
         ),
         children: <UINode>[
           StackNode(
             children: <UINode>[
               Box(
                 direction: Axis.horizontal,
                 width: double.infinity,
                 height: tabHeight,
                 children: <UINode>[
                   for (int index = 0; index < tabs.length; index++)
                     _tab(
                       tabs[index],
                       selected: index == selected,
                       variant: variant,
                       palette: palette,
                       indicator: _tint(palette, indicator),
                       onTap: onSelect == null ? null : () => onSelect(index),
                     ),
                 ],
               ),
               // A primary bar's tabs are the same width, so one indicator can be a share of the
               // bar and moved by a multiple of its own width: a whole tab per step, placed by
               // `selected` alone. The transform is what a transition eases, so it slides.
               //
               // It starts at the *start* edge, not the centre: an aligned child fills the stack
               // and the alignment places it, so a centred indicator already sits half a bar along
               // and every step is then one tab too far — the underline of a three-tab bar landed
               // under the second tab while the first was chosen.
               if (variant == MaterialTabVariant.primary)
                 PositionedNode(
                   alignment: BoxAlignment.bottomStart,
                   child: Box(
                     widthFraction: 1 / tabs.length,
                     height: indicatorHeight,
                     backgroundColor: _tint(palette, indicator),
                     transform: BoxTransform(fractionX: selected.toDouble()),
                     transition: const BoxTransition(
                       duration: Duration(milliseconds: 250),
                       curve: BoxCurve.easeOut,
                       parts: <BoxTransitionPart>[
                         BoxTransitionPart(
                           properties: <BoxProperty>{BoxProperty.transform},
                           duration: Duration(milliseconds: 250),
                         ),
                       ],
                     ),
                   ),
                 ),
             ],
           ),
         ],
       );

  /// The baseline `primary` of the Material 3 light scheme, for a bar built without a
  /// palette: the same value [MaterialCard] writes out for its own surface.
  static const BoxColor _baselinePrimary = BoxColor(0xFF8C4A5D);

  /// The colour of the indicator: the one the caller named, else the palette's `primary`,
  /// else the baseline.
  static BoxColor _tint(MaterialPalette? palette, BoxColor? indicator) =>
      indicator ?? palette?.primary ?? _baselinePrimary;

  /// The height of a tab without an icon: Material's own.
  static const double tabHeight = 48;

  /// How tall the indicator is, and therefore how much of the bottom of a tab it takes.
  static const double indicatorHeight = 3;

  static UINode _tab(
    MaterialTab tab, {
    required bool selected,
    required MaterialTabVariant variant,
    required MaterialPalette? palette,
    required BoxColor indicator,
    required TapCallback? onTap,
  }) {
    final bool primary = variant == MaterialTabVariant.primary;

    final BoxColor labelColour = palette == null
        ? (selected ? _baselinePrimary : const BoxColor(0xFF514346))
        : (selected ? palette.primary : palette.onSurfaceVariant);

    // The label belongs to the caller, so its colour is inherited rather than reached into:
    // a box hands its `textStyle` down to the texts inside it, which is the model's copy of
    // CSS font inheritance.
    final Box label = Box(
      gap: 4,
      crossAlign: CrossAlign.center,
      textStyle: MaterialTypography.titleSmall.copyWith(color: labelColour),
      children: <UINode>[?tab.icon, tab.label],
    );

    // The tab is the well, filling all 48 pixels and the whole share: Material tints the tab, and a
    // column that held the well above an indicator strip made the tint as wide as its label and
    // left the bottom three pixels outside the thing a pointer could reach.
    return Box(
      flex: primary ? 1 : null,
      height: tabHeight,
      // A share cannot be split, so a primary tab stretches its well across its share; a secondary
      // tab is as wide as its label, which is what packing them to the start means.
      crossAlign: primary ? CrossAlign.stretch : CrossAlign.center,
      children: <UINode>[
        MaterialInkWell(
          onTap: onTap,
          width: primary ? double.infinity : null,
          height: tabHeight,
          mainAlign: MainAlign.center,
          crossAlign: CrossAlign.center,
          padding: BoxSpacing.symmetric(horizontal: primary ? 8 : 16),
          child: primary
              ? label
              : _underlined(label, selected: selected, indicator: indicator),
          semantics: BoxSemantics(
            role: BoxRole.tab,
            label: tab.semanticsLabel,
            // Which of the set is chosen: `aria-selected` on the web, and Flutter's own selected
            // flag, which is what a screen reader announces for a tab.
            selected: selected,
          ),
        ),
      ],
    );
  }

  /// [label] with the indicator drawn across the bottom of it, shown when [selected].
  ///
  /// The stack is sized by the label and the indicator is pinned to both of its edges, so the
  /// underline is exactly as wide as the text above it — the one width a tab can have that its
  /// siblings do not share. Nothing measures it: a stack takes the size of the child it lays
  /// out, and a positioned child with no width of its own spans whatever that was.
  ///
  /// It fades rather than sliding, because where the *next* tab starts is the one thing this
  /// tree cannot state: two labels are not a share apart, they are a measurement apart.
  static UINode _underlined(
    UINode label, {
    required bool selected,
    required BoxColor indicator,
  }) {
    return StackNode(
      height: tabHeight,
      children: <UINode>[
        Box(
          height: tabHeight,
          mainAlign: MainAlign.center,
          crossAlign: CrossAlign.center,
          children: <UINode>[label],
        ),
        PositionedNode(
          left: 0,
          right: 0,
          bottom: 0,
          child: Box(
            height: indicatorHeight,
            backgroundColor: indicator,
            opacity: selected ? 1 : 0,
            transition: const BoxTransition(
              duration: Duration(milliseconds: 250),
              curve: BoxCurve.easeOut,
              parts: <BoxTransitionPart>[
                BoxTransitionPart(
                  properties: <BoxProperty>{BoxProperty.opacity},
                  duration: Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
