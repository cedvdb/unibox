import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_flutter/handover.dart';
import 'package:unibox_flutter/unibox_flutter.dart';
import 'package:unibox_material_flutter/unibox_material_flutter.dart';

import 'components_app.dart';
import 'page_address.dart';
import 'site.dart';
import 'surface.dart';
import 'link_policy.dart';

void main() => runApp(switch (hostedPageFor(pageAddress)) {
  HostedPage.site => const SiteApp(),
  HostedPage.components => const ComponentsApp(),
  HostedPage.example => const ExampleApp(),
});

/// Renders the shared declaration and completes document-to-Flutter handover.
class ExampleApp extends StatefulWidget {
  /// Creates the Flutter host without adding presentation outside the declaration.
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final ScrollController _page = ScrollController();
  final FlutterHandover _handover = FlutterHandover();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_handover.complete(controller: _page, root: context));
      }
    });
  }

  @override
  void dispose() {
    _handover.dispose();
    _page.dispose();
    super.dispose();
  }

  void _save(BuildContext context) => unawaited(
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Homes saved'),
        content: const Text('These homes are in your saved collection.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scope = core.UniboxScope(
      theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
    );
    return surface(
      title: 'Unibox — one UI, two renderers',
      scope: scope,
      palette: ExamplePalette.materialFor(ExampleSeed.defaultSeed),
      child: Builder(
        builder: (context) => SingleChildScrollView(
          controller: _page,
          child: ExampleLinks(
            child: renderFlutter(
              buildListingExample(onSave: () => _save(context)),
              scope: scope,
              substitutions: materialComponents(),
            ),
          ),
        ),
      ),
    );
  }
}
