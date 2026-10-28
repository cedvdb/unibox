import 'package:unibox_core/unibox_core.dart';

import 'material_ink_well.dart';
import 'material_palette.dart';
import 'material_typography.dart';

/// One destination of a [MaterialNavigationBar]: a label, and the picture above
/// it.
///
/// The icon is a node rather than a glyph name because a font is a host asset this
/// package does not ship; `MaterialIcon` is the way in when an application has
/// one, and the example draws its few pictures from boxes.
final class MaterialNavigationDestination {
  /// Creates a destination around [label].
  const MaterialNavigationDestination({
    required this.label,
    this.icon,
    this.selectedIcon,
    this.semanticsLabel,
  });

  /// What the destination says.
  final UINode label;

  /// The picture above the label.
  ///
  /// It is drawn inside the indicator pill, so draw it in
  /// [MaterialNavigationBar.inactiveIconColor] — the bar colours the label, but a
  /// picture carries its own colour in both targets.
  final UINode? icon;

  /// The picture drawn in place of [icon] while this destination is the chosen
  /// one, for the filled glyph Material pairs with an outlined one.
  ///
  /// Draw it in [MaterialNavigationBar.activeIconColor]. Left `null`, the
  /// destination shows [icon] in both states.
  final UINode? selectedIcon;

  /// What a screen reader calls the destination, when the label is not enough.
  final String? semanticsLabel;
}

/// A Material 3 navigation bar: three to five destinations along the bottom edge
/// of a screen, one of them the page it is on.
///
/// ```dart
/// MaterialNavigationBar(
///   destinations: <MaterialNavigationDestination>[
///     MaterialNavigationDestination(
///       label: const TextNode('Listings'),
///       icon: MaterialIcon.ligature(
///         'list',
///         color: MaterialNavigationBar.inactiveIconColor,
///       ),
///       selectedIcon: MaterialIcon.ligature(
///         'list',
///         color: MaterialNavigationBar.activeIconColor,
///       ),
///     ),
///     MaterialNavigationDestination(
///       label: const TextNode('Map'),
///       icon: MaterialIcon.ligature(
///         'map',
///         color: MaterialNavigationBar.inactiveIconColor,
///       ),
///     ),
///   ],
///   selected: destination,
///   onSelect: store.choose,
/// )
/// ```
///
/// It is a [Box], so both renderers draw it with the renderer they already have
/// and every token it sets is one the conformance table already pins. What the
/// class buys is the combination Material states: a bar 80 pixels tall on
/// `surfaceContainer`, one equal share per destination, and inside each share an
/// icon on a 64 by 32 `secondaryContainer` pill at radius 16, four pixels above a
/// `labelMedium` label. The chosen destination's label is `onSurface`, the rest
/// `onSurfaceVariant`, and each destination is a [MaterialInkWell] — so a press
/// inks the whole destination and the hover and focus tints cover it rather than
/// its label.
///
/// **Where it sits is the tree's business.** The bar fills the width and states
/// its height; being at the bottom is a `PositionedNode` at the bottom of a
/// `StackNode`, or the last row of a full height column, exactly as any other box.
/// It adds no safe area inset either: the host that knows the window insets pads
/// it, because the model has no notion of a device.
///
/// **What it announces.** Each destination is a button that says, when it is the
/// chosen one, that it is the current page — which a browser writes as
/// `aria-current="page"` and a phone reads as the selected item of a set.
/// `selected` is deliberately not set as well: `aria-selected` is valid on options,
/// tabs and rows and not on a button, and Flutter already reads `current` as the
/// selected state, so one fact reaches both targets. The bar itself is a `nav`
/// landmark on the web. A tab strip's arrow keys and roving focus are not modelled,
/// which is why the role is a button and not a tab.
///
/// **What Material draws that this still does not.** The label fades between its two
/// colours where the pill fades and grows, and the icon swaps rather than cross-fading:
/// a text colour is not a paint a transition eases, and the icon is the caller's node.
/// The bar also does not hide as the page scrolls: that is scroll state, which the
/// model does not have.
final class MaterialNavigationBar extends Box {
  /// Creates a navigation bar with [destinations], [selected] of them chosen.
  ///
  /// Every token Material gives the bar is a parameter, so an application can
  /// restyle it without giving up the component: the surface [color], the
  /// [indicatorColor] of the chosen destination, the [labelStyle] of every label,
  /// the [ink] a press leaves, and the [transition] that eases the tints.
  MaterialNavigationBar({
    required List<MaterialNavigationDestination> destinations,
    required int selected,
    required void Function(int index) onSelect,
    BoxColor color = _surface,
    BoxColor indicatorColor = _indicatorFill,
    BoxTextStyle labelStyle = MaterialTypography.labelMedium,
    BoxColor? ink,
    BoxSemantics? semantics,
    super.margin,
    BoxTransition? transition,
    super.key,
  }) : super(
         width: double.infinity,
         height: barHeight,
         direction: Axis.horizontal,
         // Every destination is as tall as the bar, so its tint covers the whole
         // share of it rather than the label inside.
         crossAlign: CrossAlign.stretch,
         backgroundColor: color,
         semantics: semantics ?? const BoxSemantics(element: BoxElement.nav),
         children: <UINode>[
           for (int i = 0; i < destinations.length; i++)
             Box(
               // Equal shares: Material gives every destination the same width,
               // so the bar reads as one control and not as three of a weight.
               flex: 1,
               children: <UINode>[
                 _destination(
                   destination: destinations[i],
                   selected: i == selected,
                   onTap: () => onSelect(i),
                   indicatorColor: indicatorColor,
                   labelStyle: labelStyle,
                   ink: ink,
                   transition: transition,
                 ),
               ],
             ),
         ],
       );

  /// The height Material gives a navigation bar.
  static const double barHeight = 80;

  /// The width of the indicator pill behind a chosen destination's icon.
  static const double indicatorWidth = 64;

  /// The height of the indicator pill, and the radius that rounds it fully.
  static const double indicatorHeight = 32;

  /// How a chosen destination's pill arrives.
  ///
  /// Flutter animates the destination over 500ms with `easeInOutCubicEmphasized`,
  /// stretching the indicator **sideways** from 40% of its width, and fades it over
  /// 100ms whenever the animation changes direction. Those two speeds are what the
  /// parts below say: the fade is the base, the stretch its own part.
  ///
  /// Two approximations, both because of what the model has: `easeOut` is the
  /// closest of the five curves it shares with CSS to Material's emphatic easing, and
  /// the reverse curve is the same one flipped where Flutter uses a differently
  /// shaped one on the way back.
  static const BoxTransition indicatorTransition = BoxTransition(
    duration: Duration(milliseconds: 100),
    curve: BoxCurve.easeOut,
    parts: <BoxTransitionPart>[
      BoxTransitionPart(
        properties: <BoxProperty>{BoxProperty.transform},
        duration: Duration(milliseconds: 500),
        curve: BoxCurve.easeOut,
      ),
    ],
  );

  /// How wide the pill is, as a share of its own width, where it is not chosen.
  ///
  /// Material starts the stretch at four tenths and stops drawing it altogether once
  /// the destination is dismissed; the opacity above is what hides the sliver.
  static const double _indicatorRestScale = 0.4;

  /// The colour the icon of the chosen destination is drawn in, inside its pill.
  ///
  /// It is public because the caller draws the icon: a picture carries its own
  /// colour, so the glyph of the chosen destination has to be built with this role
  /// — or given as [MaterialNavigationDestination.selectedIcon].
  static const BoxColor activeIconColor = BoxColor.role(
    MaterialColorRole.onSecondaryContainer,
  );

  /// The colour every unchosen destination's icon is drawn in.
  static const BoxColor inactiveIconColor = BoxColor.role(
    MaterialColorRole.onSurfaceVariant,
  );

  /// The surface Material paints a navigation bar on.
  static const BoxColor _surface = BoxColor.role(
    MaterialColorRole.surfaceContainer,
  );

  /// The fill of the indicator behind the chosen destination's icon.
  static const BoxColor _indicatorFill = BoxColor.role(
    MaterialColorRole.secondaryContainer,
  );

  /// The room Material leaves above the indicator and below the label.
  ///
  /// 12 + 32 + 4 + 16 + 16 is the bar's 80: the room is what makes the pill, the
  /// gap and the label's line box meet the height exactly, so a destination needs
  /// no height of its own and the two targets agree on where the icon sits.
  static const BoxSpacing _itemPadding = BoxSpacing(top: 12, bottom: 16);

  /// The space between the indicator pill and the label.
  static const double _labelGap = 4;

  /// One destination: a target the whole share presses, an indicator that is the only
  /// thing which tints and inks, and a label above the ink.
  ///
  /// This is the arrangement Material draws, read from Flutter: the destination is one
  /// control, the ink and the hover layer are the **indicator's** — a 64 by 32 pill, not
  /// the share — and the ripple is painted over the pill's fill rather than behind it.
  /// The pill is a [MaterialInkWell] of its own for that reason, with its own `fill` so
  /// the tints sit above the colour instead of replacing it.
  ///
  /// Two things keep the press single. The pill's click stops there, which is what
  /// Flutter's gesture arena does — the innermost control wins — so `onSelect` is called
  /// once whichever layer the press landed on. And the label is a layer that takes no
  /// pointer, so a press on it reaches the target under it.
  static UINode _destination({
    required MaterialNavigationDestination destination,
    required bool selected,
    required TapCallback onTap,
    required BoxColor indicatorColor,
    required BoxTextStyle labelStyle,
    required BoxColor? ink,
    required BoxTransition? transition,
  }) {
    final BoxColor foreground = _foregroundOf(selected);
    // The filled glyph Material pairs with an outlined one, when the caller has both.
    final UINode? icon = selected
        ? destination.selectedIcon ?? destination.icon
        : destination.icon;

    // The role and the colour are stated once on the box around the label, because
    // typography is the one thing a box passes down.
    final BoxTextStyle style = labelStyle.merge(
      BoxTextStyle(color: foreground),
    );

    return Box(
      width: double.infinity,
      height: barHeight,
      // The whole share is the control, and the one thing a reader hears.
      onTap: onTap,
      textStyle: style,
      semantics: BoxSemantics(
        role: BoxRole.button,
        label: destination.semanticsLabel,
        // The chosen destination is the page being read — `aria-current="page"` on the
        // web, the selected state of a set in Flutter.
        current: selected ? BoxCurrent.page : null,
      ),
      children: <UINode>[
        StackNode(
          width: double.infinity,
          height: barHeight,
          children: <UINode>[
            // The indicator, centred on the share and as far from the top as the icon
            // is: the slot the icon sits in.
            PositionedNode(
              left: 0,
              right: 0,
              top: _itemPadding.top,
              child: Box(
                direction: Axis.horizontal,
                mainAlign: MainAlign.center,
                children: <UINode>[
                  _indicator(
                    icon: icon,
                    selected: selected,
                    color: indicatorColor,
                    onTap: onTap,
                    ink: ink ?? foreground,
                    transition: transition,
                  ),
                ],
              ),
            ),
            // The label, under the indicator and above its ink. A layer takes no
            // pointer, so a press here is the target's.
            PositionedNode(
              left: 0,
              right: 0,
              top: _itemPadding.top + indicatorHeight + _labelGap,
              child: Box(
                direction: Axis.horizontal,
                mainAlign: MainAlign.center,
                children: <UINode>[destination.label],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// The indicator: the pill, its fill, its tints and its ink.
  ///
  /// It is a [MaterialInkWell] of its own, because the ink and the hover layer belong
  /// to the indicator and not to the share: the well paints the fill under a layer of
  /// tints, then the drops, then the icon, so a press shows ink across the pill and the
  /// pill settles to its colour. Its semantics are hidden — the destination around it is
  /// the control a reader hears — but its click is real: it answers a press itself and
  /// stops there, so a press on the pill does not also reach the destination.
  ///
  /// The fade and the sideways stretch are on the box around it, so the ink and the
  /// drag of a press are shaped by the same animation as the colour.
  static UINode _indicator({
    required UINode? icon,
    required bool selected,
    required BoxColor color,
    required TapCallback onTap,
    required BoxColor ink,
    required BoxTransition? transition,
  }) {
    return Box(
      width: indicatorWidth,
      height: indicatorHeight,
      opacity: selected ? 1 : 0,
      // Sideways only: Material stretches the pill out of the icon at its own height.
      transform: BoxTransform(scaleX: selected ? 1 : _indicatorRestScale),
      transition: indicatorTransition,
      children: <UINode>[
        MaterialInkWell(
          onTap: onTap,
          width: indicatorWidth,
          height: indicatorHeight,
          borderRadius: indicatorHeight / 2,
          fill: selected ? color : null,
          ink: ink,
          padding: BoxSpacing.zero,
          transition: transition ?? MaterialInkWell.defaultTransition,
          semantics: const BoxSemantics(hidden: true),
          child: Box(
            width: indicatorWidth,
            height: indicatorHeight,
            mainAlign: MainAlign.center,
            crossAlign: CrossAlign.center,
            children: <UINode>[?icon],
          ),
        ),
      ],
    );
  }

  /// The colour the label is drawn in, and the ink a press leaves.
  static BoxColor _foregroundOf(bool selected) => selected
      ? const BoxColor.role(MaterialColorRole.onSurface)
      : const BoxColor.role(MaterialColorRole.onSurfaceVariant);

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'material-navigation-bar';
}
