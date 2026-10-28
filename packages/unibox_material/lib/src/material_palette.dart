import 'package:unibox_core/unibox_core.dart';

/// The colour roles of the Material 3 specification.
///
/// A component names one of these instead of a value, so the tree says "the
/// surface a card sits on" and the theme says what that is worth. The names are
/// the specification's own, in kebab case where they reach CSS
/// (`surfaceContainerHigh` → `--unibox-color-surface-container-high`).
enum MaterialColorRole {
  /// The accent a primary action is painted with.
  primary,

  /// The text and icons drawn on [primary].
  onPrimary,

  /// The less prominent container of a primary accent.
  primaryContainer,

  /// The text and icons drawn on [primaryContainer].
  onPrimaryContainer,

  /// The accent of a quieter, chosen thing: a selected chip, a selected segment.
  secondary,

  /// The text and icons drawn on [secondary].
  onSecondary,

  /// The container a chosen control fills with.
  secondaryContainer,

  /// The text and icons drawn on [secondaryContainer].
  onSecondaryContainer,

  /// The page itself.
  surface,

  /// The text and icons drawn on [surface].
  onSurface,

  /// The supporting text and icons: captions, hints, secondary labels.
  onSurfaceVariant,

  /// The highest surface tone, which is a white sheet on a light page.
  surfaceContainerLowest,

  /// The surface of a resting card, which sits just above the page.
  surfaceContainerLow,

  /// The surface of a dialog or a menu.
  surfaceContainerHigh,

  /// The surface of the most prominent container, such as a filled field.
  surfaceContainerHighest,

  /// The line around a control at rest.
  outline,

  /// The fainter line: dividers, the edge of a card.
  outlineVariant,

  /// The colour of a failure.
  error,

  /// The text and icons drawn on [error].
  onError,

  /// What covers the page behind a modal: black at 32%.
  scrim,

  /// The layer a pointer paints: 8% of [onSurface].
  hoverLayer,

  /// The layer keyboard focus paints: 10%.
  focusLayer,

  /// The layer a press paints: 10%.
  pressedLayer,

  /// The layer a drag paints: 16%.
  draggedLayer,
}

/// The Material 3 colour roles, as `const` values a tree can wear.
///
/// A Material application has a colour scheme; this package has a palette of the
/// same roles spelled as tokens, because the model has no theme of its own: a card
/// is a box, and a box takes colours, not a name to look one up by.
///
/// ```dart
/// const palette = MaterialPalette.light;
///
/// MaterialCard(
///   color: palette.surfaceContainerLow,
///   border: BoxBorder(color: palette.outlineVariant),
///   children: <UINode>[TextNode('Order summary')],
/// );
/// ```
///
/// **How a colour reaches the page.** The tree is built with palette values, so an
/// application passes the palette to its builders *and* installs the same roles as
/// its platform theme — `ColorScheme` on a `MaterialApp`, CSS custom properties on
/// the web — which is what keeps the tree and any embedded widget in step. The two
/// wirings are the application's, not this package's: it depends on `unibox_core`
/// alone and never imports Flutter.
///
/// **What it is not.** It is not a theme layer, it is not a `Theme` widget and it
/// resolves nothing at render time: the values are read when the tree is built, so
/// a change of palette is a rebuild, exactly like a change of state.
final class MaterialPalette {
  /// Creates a palette. Every role is required, because a missing role would be a
  /// colour nobody notices is wrong until a control using it appears.
  const MaterialPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.scrim,
  });

  /// The accent a primary action is painted with.
  final BoxColor primary;

  /// The text and icons drawn on [primary].
  final BoxColor onPrimary;

  /// The less prominent container of a primary accent.
  final BoxColor primaryContainer;

  /// The text and icons drawn on [primaryContainer].
  final BoxColor onPrimaryContainer;

  /// The accent of a quieter, chosen thing: a selected chip or segment.
  final BoxColor secondary;

  /// The text and icons drawn on [secondary].
  final BoxColor onSecondary;

  /// The container a chosen control fills with.
  final BoxColor secondaryContainer;

  /// The text and icons drawn on [secondaryContainer].
  final BoxColor onSecondaryContainer;

  /// The background of a page.
  final BoxColor surface;

  /// The text and icons drawn on [surface].
  final BoxColor onSurface;

  /// The text and icons of a lower emphasis: subtitles, trailing values, icons.
  final BoxColor onSurfaceVariant;

  /// The highest surface tone, which is a white sheet on a light page.
  final BoxColor surfaceContainerLowest;

  /// The surface of a resting card, which sits just above the page.
  final BoxColor surfaceContainerLow;

  /// The surface of a dialog or a menu: above a card, below the highest tone.
  final BoxColor surfaceContainerHigh;

  /// The surface of the most prominent container, such as a filled field.
  final BoxColor surfaceContainerHighest;

  /// The line around a control that needs one.
  final BoxColor outline;

  /// The line around a container that only needs to be separated, not framed.
  final BoxColor outlineVariant;

  /// The colour of something that went wrong.
  final BoxColor error;

  /// The text and icons drawn on [error].
  final BoxColor onError;

  /// What covers the page behind a modal: black at 32%, so the page is dimmed
  /// and not hidden.
  final BoxColor scrim;

  /// The layer Material paints while the pointer is on a control: 8% of
  /// [onSurface].
  ///
  /// The layers are translucent colours rather than mixed ones, so they sit over
  /// whatever the box is painted on — which is what a CSS state layer does, and
  /// why one palette can tint three different surfaces.
  BoxColor get hoverLayer => _layerOver(onSurface, 0.08);

  /// The layer Material paints while a control has keyboard focus: 10%.
  BoxColor get focusLayer => _layerOver(onSurface, 0.10);

  /// The layer Material paints while a control is pressed: 10%.
  BoxColor get pressedLayer => _layerOver(onSurface, 0.10);

  /// The layer Material paints over a control something is dragged onto: 16%.
  BoxColor get draggedLayer => _layerOver(onSurface, 0.16);

  /// This palette as a theme, so a tree can name roles instead of values.
  ///
  /// Every role is present, including the four state layers, which is what makes
  /// `BoxColor.role(MaterialColorRole.primary)` resolve in a component without the
  /// component knowing which palette is in force.
  UniboxTheme get theme => UniboxTheme(
    colors: <MaterialColorRole, BoxColor>{
      MaterialColorRole.primary: primary,
      MaterialColorRole.onPrimary: onPrimary,
      MaterialColorRole.primaryContainer: primaryContainer,
      MaterialColorRole.onPrimaryContainer: onPrimaryContainer,
      MaterialColorRole.secondary: secondary,
      MaterialColorRole.onSecondary: onSecondary,
      MaterialColorRole.secondaryContainer: secondaryContainer,
      MaterialColorRole.onSecondaryContainer: onSecondaryContainer,
      MaterialColorRole.surface: surface,
      MaterialColorRole.onSurface: onSurface,
      MaterialColorRole.onSurfaceVariant: onSurfaceVariant,
      MaterialColorRole.surfaceContainerLowest: surfaceContainerLowest,
      MaterialColorRole.surfaceContainerLow: surfaceContainerLow,
      MaterialColorRole.surfaceContainerHigh: surfaceContainerHigh,
      MaterialColorRole.surfaceContainerHighest: surfaceContainerHighest,
      MaterialColorRole.outline: outline,
      MaterialColorRole.outlineVariant: outlineVariant,
      MaterialColorRole.error: error,
      MaterialColorRole.onError: onError,
      MaterialColorRole.scrim: scrim,
      MaterialColorRole.hoverLayer: hoverLayer,
      MaterialColorRole.focusLayer: focusLayer,
      MaterialColorRole.pressedLayer: pressedLayer,
      MaterialColorRole.draggedLayer: draggedLayer,
    },
  );

  /// The baseline light scheme, as the theme a material tree is rendered with.
  static final UniboxTheme lightTheme = MaterialPalette.light.theme;

  /// The baseline dark scheme, as the theme a material tree is rendered with.
  static final UniboxTheme darkTheme = MaterialPalette.dark.theme;

  /// The resting palette of Material 3's baseline light scheme.
  static const MaterialPalette light = MaterialPalette(
    primary: BoxColor(0xFF6750A4),
    onPrimary: BoxColor(0xFFFFFFFF),
    primaryContainer: BoxColor(0xFFEADDFF),
    onPrimaryContainer: BoxColor(0xFF21005D),
    secondary: BoxColor(0xFF625B71),
    onSecondary: BoxColor(0xFFFFFFFF),
    secondaryContainer: BoxColor(0xFFE8DEF8),
    onSecondaryContainer: BoxColor(0xFF1D192B),
    surface: BoxColor(0xFFFEF7FF),
    onSurface: BoxColor(0xFF1D1B20),
    onSurfaceVariant: BoxColor(0xFF49454F),
    surfaceContainerLowest: BoxColor(0xFFFFFFFF),
    surfaceContainerLow: BoxColor(0xFFF7F2FA),
    surfaceContainerHigh: BoxColor(0xFFECE6F0),
    surfaceContainerHighest: BoxColor(0xFFE6E0E9),
    outline: BoxColor(0xFF79747E),
    outlineVariant: BoxColor(0xFFCAC4D0),
    error: BoxColor(0xFFB3261E),
    onError: BoxColor(0xFFFFFFFF),
    scrim: BoxColor(0x52000000),
  );

  /// The resting palette of Material 3's baseline dark scheme.
  static const MaterialPalette dark = MaterialPalette(
    primary: BoxColor(0xFFD0BCFF),
    onPrimary: BoxColor(0xFF381E72),
    primaryContainer: BoxColor(0xFF4F378B),
    onPrimaryContainer: BoxColor(0xFFEADDFF),
    secondary: BoxColor(0xFFCCC2DC),
    onSecondary: BoxColor(0xFF332D41),
    secondaryContainer: BoxColor(0xFF4A4458),
    onSecondaryContainer: BoxColor(0xFFE8DEF8),
    surface: BoxColor(0xFF141218),
    onSurface: BoxColor(0xFFE6E0E9),
    onSurfaceVariant: BoxColor(0xFFCAC4D0),
    surfaceContainerLowest: BoxColor(0xFF0F0D13),
    surfaceContainerLow: BoxColor(0xFF1D1B20),
    surfaceContainerHigh: BoxColor(0xFF2B2930),
    surfaceContainerHighest: BoxColor(0xFF36343B),
    outline: BoxColor(0xFF938F99),
    outlineVariant: BoxColor(0xFF49454F),
    error: BoxColor(0xFFF2B8B5),
    onError: BoxColor(0xFF601410),
    scrim: BoxColor(0x52000000),
  );

  /// [base] at [opacity], keeping its channels.
  static BoxColor _layerOver(BoxColor base, double opacity) {
    return BoxColor.rgba(
      base.red,
      base.green,
      base.blue,
      (opacity * 0xFF).round(),
    );
  }
}
