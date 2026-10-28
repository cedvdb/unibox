/// Material Design 3 for Unibox: the type scale, the palette, and the components
/// built from them.
///
/// The package holds values and nodes, and no renderer code. The fifteen roles of
/// the Material 3 type scale are `const BoxTextStyle` values, the colour roles are
/// `const BoxColor` values ([MaterialPalette]), and every component is a node built
/// from the node that already draws it — a card and a tile are a `Box`, a dialog and
/// a sheet are an `OverlayNode`. A look is a value and a component is a node, so
/// neither renderer has to know that this package exists.
///
/// ```dart
/// import 'package:unibox_core/unibox_core.dart';
/// import 'package:unibox_material/unibox_material.dart';
///
/// const palette = MaterialPalette.light;
///
/// MaterialCard(
///   children: <UINode>[
///     TextNode('Order summary', style: MaterialTypography.titleLarge),
///     const TextNode('Two nights, one room.'),
///   ],
/// )
/// ```
///
/// The palette is a value the tree wears, not a scope anything looks up: a
/// component takes `palette:` and reads its roles while the tree is built, so a
/// theme change is a rebuild. Making the host's `ColorScheme` and the page's CSS
/// custom properties agree with it is the application's job, which is why this
/// package depends on `unibox_core` alone and never imports Flutter or Jaspr.
///
/// What the components leave to the platform is written down on each of them: the
/// ripple, the floating label, the caret and selection colours, and Material's modal
/// transitions.
library;

export 'src/material_bottom_sheet.dart';
export 'src/material_card.dart';
export 'src/material_dialog.dart';
export 'src/material_icon.dart';
export 'src/material_ink_well.dart';
export 'src/material_list_tile.dart';
export 'src/material_palette.dart';
export 'src/material_text_field.dart';
export 'src/material_type_role.dart';
export 'src/material_typography.dart';
