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
/// **A bar shows nothing itself.** It says which tab is chosen and reports a press; the node
/// that draws a page is [MaterialTabs], or the application's own view. Keeping the two apart
/// is what lets a bar sit above a page that swaps, above a pager, or beside a preview — the
/// choice is the tree's state in every case.
///
/// A tab is a *selected button* rather than a `role="tab"`: the model names no tab role yet,
/// and inventing one on one target only would be the drift the contract exists to prevent.
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
         direction: Axis.horizontal,
         crossAlign: CrossAlign.start,
         width: double.infinity,
         shadow: BoxShadow(
           color: palette?.outlineVariant ?? const BoxColor(0xFFD6C2C5),
           offsetY: 1,
           blurRadius: 0,
         ),
         children: <UINode>[
           for (int index = 0; index < tabs.length; index++)
             _tab(
               tabs[index],
               selected: index == selected,
               variant: variant,
               indicator: indicator ?? palette?.primary ?? _baselinePrimary,
               palette: palette,
               onTap: onSelect == null ? null : () => onSelect(index),
             ),
         ],
       );

  /// The baseline `primary` of the Material 3 light scheme, for a bar built without a
  /// palette: the same value [MaterialCard] writes out for its own surface.
  static const BoxColor _baselinePrimary = BoxColor(0xFF8C4A5D);

  /// The height of a tab without an icon: Material's own.
  static const double tabHeight = 48;

  /// How tall the indicator is, and therefore how much of the bottom of a tab it takes.
  static const double indicatorHeight = 3;

  static UINode _tab(
    MaterialTab tab, {
    required bool selected,
    required MaterialTabVariant variant,
    required BoxColor? indicator,
    required MaterialPalette? palette,
    required TapCallback? onTap,
  }) {
    final BoxColor labelColour = palette == null
        ? (selected ? _baselinePrimary : const BoxColor(0xFF514346))
        : (selected ? palette.primary : palette.onSurfaceVariant);

    return Box(
      // A primary tab takes an equal share of the row; a secondary one is as wide as its
      // label, so it asks for no share at all.
      flex: variant == MaterialTabVariant.primary ? 1 : null,
      height: tabHeight,
      children: <UINode>[
        MaterialInkWell(
          onTap: onTap,
          flex: 1,
          mainAlign: MainAlign.center,
          crossAlign: CrossAlign.center,
          padding: BoxSpacing.symmetric(
            horizontal: variant == MaterialTabVariant.primary ? 8 : 16,
          ),
          // The label belongs to the caller, so its colour is inherited rather than reached
          // into: a box hands its `textStyle` down to the texts inside it, which is the
          // model's copy of CSS font inheritance.
          child: Box(
            gap: 4,
            crossAlign: CrossAlign.center,
            textStyle: MaterialTypography.titleSmall.copyWith(
              color: labelColour,
            ),
            children: <UINode>[?tab.icon, tab.label],
          ),
          semantics: BoxSemantics(
            role: BoxRole.button,
            label: tab.semanticsLabel,
            selected: selected,
          ),
        ),
        // The indicator is a box of its own, so an unchosen tab draws nothing at all: a rule
        // that hid a layer would be a second way to say what a missing box already says.
        Box(
          width: double.infinity,
          height: indicatorHeight,
          backgroundColor: selected ? indicator : null,
        ),
      ],
    );
  }
}
