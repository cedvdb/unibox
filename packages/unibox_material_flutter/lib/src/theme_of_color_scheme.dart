import 'package:material_ui/material_ui.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_material/unibox_material.dart' as material;

/// A Flutter `ColorScheme` as the theme a tree is drawn with.
///
/// The inverse of [materialThemeData]: an application that has a `ThemeData` and draws a band
/// from a tree beside its own widgets knows its colours in Flutter's vocabulary, and the tree
/// asks for them in the model's. Reading them from the scheme rather than growing a palette from
/// the seed is what keeps the two identical — a second run of the colour algorithm agrees until
/// somebody overrides a tone, and then quietly does not.
///
/// [also] carries the roles a design system adds to Material's: an application names them in the
/// model (an `enum` of its own) and fills them here, which is the one thing this cannot know.
core.UniboxTheme uniboxThemeOf(
  ColorScheme scheme, {
  Map<Enum, core.BoxColor> also = const <Enum, core.BoxColor>{},
}) => core.UniboxTheme(
  colorScheme: scheme.brightness == Brightness.dark
      ? core.BoxColorScheme.dark
      : core.BoxColorScheme.light,
  colors: <Enum, core.BoxColor>{
    material.MaterialColorRole.primary: _of(scheme.primary),
    material.MaterialColorRole.onPrimary: _of(scheme.onPrimary),
    material.MaterialColorRole.primaryContainer: _of(scheme.primaryContainer),
    material.MaterialColorRole.onPrimaryContainer: _of(
      scheme.onPrimaryContainer,
    ),
    material.MaterialColorRole.secondary: _of(scheme.secondary),
    material.MaterialColorRole.onSecondary: _of(scheme.onSecondary),
    material.MaterialColorRole.secondaryContainer: _of(
      scheme.secondaryContainer,
    ),
    material.MaterialColorRole.onSecondaryContainer: _of(
      scheme.onSecondaryContainer,
    ),
    material.MaterialColorRole.tertiary: _of(scheme.tertiary),
    material.MaterialColorRole.onTertiary: _of(scheme.onTertiary),
    material.MaterialColorRole.primaryFixedDim: _of(scheme.primaryFixedDim),
    material.MaterialColorRole.secondaryFixedDim: _of(scheme.secondaryFixedDim),
    material.MaterialColorRole.surface: _of(scheme.surface),
    material.MaterialColorRole.onSurface: _of(scheme.onSurface),
    material.MaterialColorRole.onSurfaceVariant: _of(scheme.onSurfaceVariant),
    material.MaterialColorRole.surfaceContainerLowest: _of(
      scheme.surfaceContainerLowest,
    ),
    material.MaterialColorRole.surfaceContainerLow: _of(
      scheme.surfaceContainerLow,
    ),
    material.MaterialColorRole.surfaceContainer: _of(scheme.surfaceContainer),
    material.MaterialColorRole.surfaceContainerHigh: _of(
      scheme.surfaceContainerHigh,
    ),
    material.MaterialColorRole.surfaceContainerHighest: _of(
      scheme.surfaceContainerHighest,
    ),
    material.MaterialColorRole.outline: _of(scheme.outline),
    material.MaterialColorRole.outlineVariant: _of(scheme.outlineVariant),
    material.MaterialColorRole.error: _of(scheme.error),
    material.MaterialColorRole.onError: _of(scheme.onError),
    material.MaterialColorRole.scrim: _of(scheme.scrim),
    // The state layers are a tint of the content's own colour over what is beneath, which a
    // scheme has no field for: the model states them as a shade of `onSurface` at Material's
    // own percentages, and a theme built from a scheme has to answer the same colours a theme
    // built from a seed does — a hover that is black at four percent on one path and
    // `onSurface` at eight on the other is one declaration painted two ways.
    material.MaterialColorRole.hoverLayer: _layerOver(scheme.onSurface, 0.08),
    material.MaterialColorRole.focusLayer: _layerOver(scheme.onSurface, 0.10),
    material.MaterialColorRole.pressedLayer: _layerOver(scheme.onSurface, 0.10),
    material.MaterialColorRole.draggedLayer: _layerOver(scheme.onSurface, 0.16),
    ...also,
  },
);

/// A Flutter colour as the model's, alpha included.
core.BoxColor _of(Color color) => core.BoxColor(color.toARGB32());

/// [color] at [alpha], which is how a state layer is painted: over whatever it covers.
core.BoxColor _layerOver(Color color, double alpha) => core.BoxColor(
  ((alpha * 255).round() << 24) | (color.toARGB32() & 0xFFFFFF),
);
