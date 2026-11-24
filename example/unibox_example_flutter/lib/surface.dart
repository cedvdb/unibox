import 'package:material_ui/material_ui.dart';
import 'package:unibox_core/unibox_core.dart' show BoxColorScheme, UniboxScope;
import 'package:unibox_material/unibox_material.dart'
    show MaterialDensity, MaterialPalette;
import 'package:unibox_material_flutter/unibox_material_flutter.dart'
    show materialThemeData;

/// The text family bundled by both hosts.
const String fontFamily = 'UniboxText';

/// The Flutter host owns its Material surface, typography and scroll physics.
Widget surface({
  required String title,
  required UniboxScope scope,
  required Widget child,
  MaterialPalette? palette,
  MaterialDensity density = MaterialDensity.standard,
  ThemeData? themeData,
}) {
  return MaterialApp(
    title: title,
    // The native host and declaration renderer resolve the same supplied palette.
    theme:
        themeData ??
        (palette == null
            ? ThemeData(
                fontFamily: fontFamily,
                brightness: scope.theme?.colorScheme == BoxColorScheme.dark
                    ? Brightness.dark
                    : Brightness.light,
              )
            : materialThemeData(
                palette,
                fontFamily: fontFamily,
                density: density,
              )),
    debugShowCheckedModeBanner: false,
    home: ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      child: Scaffold(body: child),
    ),
  );
}
