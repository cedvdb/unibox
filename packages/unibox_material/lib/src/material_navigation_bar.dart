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
/// `onSurfaceVariant`, and each destination answers a press with a [MaterialInkWell]
/// over its pill — so a press inks the pill, and a hover anywhere in the destination's share
/// lights it. That is why a destination is a `StatefulNode`: the pointer is over the share and
/// the look that changes is a layer down, which a box cannot style from itself.
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
                 _DestinationNode(
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
    required bool hovered,
    required TapCallback onTap,
    required HoverCallback onHover,
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
      // Hover is reported from the share, because the pill it lights is a layer down.
      onHover: onHover,
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
                    hovered: hovered,
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

  /// The indicator: the colour pill, and the ink well with the icon in it.
  ///
  /// Two layers, in the order Material paints them. The **colour** is the pill's fill and
  /// the only part that arrives — it fades in and stretches sideways out of the icon when
  /// its destination becomes the chosen one. The **well** sits over the colour with the
  /// icon as its content, so its hover layer is a full-size pill whatever state the fill
  /// is in, a press spreads ink across the pill over the colour it is settling to, and the
  /// icon is always drawn: an earlier shape faded the whole indicator, and an unselected
  /// destination lost its picture with it.
  ///
  /// The icon is inside the well and not a layer above it because a press has to reach the
  /// well: a text hit-tests as opaque, so a picture floating over the pill swallowed the
  /// press and the ripple never started.
  ///
  /// The well is the pill's control: it answers a press itself and its click stops
  /// there, so a press on the pill does not also reach the destination. A reader hears
  /// the destination, not the pill, which is why the well's semantics are hidden.
  static UINode _indicator({
    required UINode? icon,
    required bool selected,
    required bool hovered,
    required BoxColor color,
    required TapCallback onTap,
    required BoxColor ink,
    required BoxTransition? transition,
  }) {
    return StackNode(
      width: indicatorWidth,
      height: indicatorHeight,
      children: <UINode>[
        Box(
          width: indicatorWidth,
          height: indicatorHeight,
          borderRadius: indicatorHeight / 2,
          // A hovered destination wears Material's state layer where the chosen one
          // wears its indicator, and both are the pill: the layer is a tint of the
          // surface, so no icon of the bar is drawn over it.
          backgroundColor: selected
              ? color
              : hovered
              ? const BoxColor.role(MaterialColorRole.hoverLayer)
              : null,
          opacity: selected || hovered ? 1 : 0,
          // Sideways only: Material stretches the pill out of the icon at its own
          // height. A hover arrives at full width instead, because nothing is
          // stretching: the layer simply appears under the pointer.
          transform: BoxTransform(
            scaleX: selected || hovered ? 1 : _indicatorRestScale,
          ),
          transition: indicatorTransition,
        ),
        MaterialInkWell(
          onTap: onTap,
          width: indicatorWidth,
          height: indicatorHeight,
          borderRadius: indicatorHeight / 2,
          ink: ink,
          padding: BoxSpacing.zero,
          // The pill is what a hover lights, and the destination reports the hover: a
          // tint of the well would be a second one over the same shape.
          hoverStyle: const BoxStyle(backgroundColor: BoxColor.transparent),
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

/// Whether a pointer is over one destination's share.
final class _HoverStore extends StateStore<bool> {
  _HoverStore() : super(false);

  void setHovered(bool hovered) => state = hovered;
}

/// One destination of a bar: its share, and whether the pointer is over it.
///
/// It is a [StatefulNode] for one reason, and it is the reason the model has stores: Material
/// lights the indicator pill when the pointer is anywhere in the destination's share, and a box
/// can style only itself. Everything the view draws is the tree the bar would have drawn without
/// it; the hover is what moves.
final class _DestinationNode extends StatefulNode<bool, _HoverStore> {
  factory _DestinationNode({
    required MaterialNavigationDestination destination,
    required bool selected,
    required TapCallback onTap,
    required BoxColor indicatorColor,
    required BoxTextStyle labelStyle,
    required BoxColor? ink,
    required BoxTransition? transition,
    Object? key,
  }) {
    return _DestinationNode._(
      key: key,
      create: _HoverStore.new,
      view: (bool hovered, _HoverStore store) =>
          MaterialNavigationBar._destination(
            destination: destination,
            selected: selected,
            hovered: hovered,
            onTap: onTap,
            onHover: store.setHovered,
            indicatorColor: indicatorColor,
            labelStyle: labelStyle,
            ink: ink,
            transition: transition,
          ),
    );
  }

  _DestinationNode._({required super.create, required super.view, super.key});

  @override
  String? get debugLabel => 'material-navigation-destination';
}
