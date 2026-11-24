import 'package:flutter/widgets.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

import 'link_policy.dart';
import 'page_address.dart';
import 'showcase_frame.dart';
import 'surface.dart';

/// Renderer inspection and component reference destinations in the example bundle.
enum HostedPage {
  /// The documentation guide at the Flutter build root.
  site,

  /// The same example declaration used by the server and handover.
  example,

  /// Optional Material declarations with native widget substitutions.
  components,
}

/// The host selects a destination without an application router in Unibox.
HostedPage hostedPageFor(Uri address) {
  final segments = address.pathSegments
      .where((value) => value.isNotEmpty)
      .toList();
  if (segments.contains('components')) return HostedPage.components;
  return segments.isNotEmpty && segments.last == 'flutter'
      ? HostedPage.site
      : HostedPage.example;
}

/// The project guide can itself be rendered by the Flutter target.
class SiteApp extends StatelessWidget {
  /// Uses the same shared design values as the HTML guide.
  const SiteApp({super.key, this.seed = ExampleSeed.defaultSeed});

  /// A palette supplied by this documentation host.
  final ExampleSeed seed;

  @override
  Widget build(BuildContext context) {
    final scope = UniboxScope(theme: ExamplePalette.themeFor(seed));
    return surface(
      title: 'Unibox — shared UI regions',
      scope: scope,
      palette: ExamplePalette.materialFor(seed),
      child: ExampleLinks(
        base: pageAddress.resolve('../'),
        child: SingleChildScrollView(
          child: renderFlutter(
            buildSitePage(seed: seed, frame: showcaseFrame),
            scope: scope,
            substitutions: materialComponents(),
          ),
        ),
      ),
    );
  }
}
