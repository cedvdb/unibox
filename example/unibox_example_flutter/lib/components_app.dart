import 'package:material_ui/material_ui.dart';
import 'package:unibox_core/unibox_core.dart' show UniboxScope;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

import 'surface.dart';
import 'link_policy.dart';

/// The supported Material vocabulary, drawn with native Flutter controls.
class ComponentsApp extends StatelessWidget {
  /// Creates the native component example.
  const ComponentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = UniboxScope(
      theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
    );
    return surface(
      title: 'Unibox — native Material',
      scope: scope,
      palette: ExamplePalette.materialFor(ExampleSeed.defaultSeed),
      child: ExampleLinks(
        child: SingleChildScrollView(
          child: renderFlutter(
            buildComponentReference(),
            scope: scope,
            substitutions: materialComponents(),
          ),
        ),
      ),
    );
  }
}
