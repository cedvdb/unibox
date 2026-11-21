import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:unibox_core/unibox_core.dart' show UniboxScope, UniboxTheme;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material/unibox_material.dart'
    show MaterialDensity, MaterialPlatform;
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

import 'surface.dart';

/// The Material catalogue, drawn twice, side by side.
///
/// The catalogue is the section the site closes on — `buildMaterialSection`, the node the page
/// and this app both draw — so there is one description of it and no second one to keep in step.
/// Here the *app* draws that one node twice: once from the design system's values, the way the
/// document at `web/components/` is served, and once with `unibox_material_flutter`'s map, so the
/// card is a `Card` and the bar a `NavigationBar`.
///
/// The two-up frame is the host's, not the tree's, and deliberately so: a tree has no way to say
/// `draw this subtree with the other painter` — a substitution is what a *host* asks for — and a
/// renderer that guessed would be the drift the model exists to prevent. So this is a comparison
/// harness, like the site's `showcaseFrame`: the page is the catalogue, and this is two windows
/// onto it.
class ComponentsApp extends StatelessWidget {
  /// Creates the comparison.
  const ComponentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final UniboxTheme theme = ExamplePalette.themeFor(ExampleSeed.defaultSeed);
    // The platform this app is, in the model's vocabulary: a desk draws a tighter control than a
    // phone, and the catalogue is built for one of them.
    final MaterialDensity density = MaterialDensity.forPlatform(
      switch (defaultTargetPlatform) {
        TargetPlatform.android => MaterialPlatform.android,
        TargetPlatform.iOS => MaterialPlatform.ios,
        TargetPlatform.fuchsia => MaterialPlatform.fuchsia,
        TargetPlatform.macOS => MaterialPlatform.macos,
        TargetPlatform.windows => MaterialPlatform.windows,
        TargetPlatform.linux => MaterialPlatform.linux,
      },
    );

    return surface(
      title: 'Unibox — the Material catalogue, drawn twice',
      scope: UniboxScope(theme: theme),
      child: SingleChildScrollView(
        // Side by side, on the window the comparison asks for: a desktop page. Each half is
        // the full catalogue at the width a page gets on a 1920 screen — 960 — so the sections
        // line up across the fold rather than four thousand pixels apart.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _half(
                caption: 'The values — what the document is served',
                theme: theme,
                density: density,
                substitutions: const UniboxSubstitutions.none(),
              ),
            ),
            Expanded(
              child: _half(
                caption: 'Flutter widgets, vanilla: its own theme and density',
                theme: theme,
                density: density,
                substitutions: materialComponents(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One rendering of the catalogue, under the caption that says which one it is.
  Widget _half({
    required String caption,
    required UniboxTheme theme,
    required UniboxSubstitutions substitutions,
    required MaterialDensity density,
  }) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0x22000000))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(caption),
          ),
          UniboxSubstitutionsWidget(
            substitutions: substitutions,
            child: renderFlutter(
              buildMaterialSection(density: density),
              scope: UniboxScope(theme: theme),
            ),
          ),
        ],
      ),
    );
  }
}
