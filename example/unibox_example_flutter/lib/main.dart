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
  HostedPage.example => ExampleApp(handover: wasTakenOver),
});

/// An ordinary Flutter application containing one Unibox listing region.
class ExampleApp extends StatefulWidget {
  /// Enables the separate document-to-Flutter demonstration when requested.
  const ExampleApp({super.key, this.handover = false});

  /// Whether this host is completing a document handover.
  final bool handover;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final ScrollController _page = ScrollController();
  final FlutterHandover _handover = FlutterHandover();
  String _query = '';
  bool _twoRooms = false;

  @override
  void initState() {
    super.initState();
    if (widget.handover) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_handover.complete(controller: _page, root: context));
        }
      });
    }
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
        title: const Text('Search saved'),
        content: const Text(
          'This dialog and the search state belong to the Flutter host.',
        ),
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
    final apartments = exampleApartments
        .where(
          (apartment) =>
              (!_twoRooms || apartment.rooms == 2) &&
              '${apartment.name} ${apartment.city}'.toLowerCase().contains(
                _query.toLowerCase(),
              ),
        )
        .toList(growable: false);
    final scope = core.UniboxScope(
      theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
    );
    return surface(
      title: 'Unibox — shared region',
      scope: scope,
      palette: ExamplePalette.materialFor(ExampleSeed.defaultSeed),
      child: Builder(
        builder: (context) {
          return SingleChildScrollView(
            controller: _page,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Homes worth a closer look',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Six homes. One shared listing region. Each host owns the rest of the page.',
                      ),
                      const SizedBox(height: 24),
                      if (!widget.handover) ...<Widget>[
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search by city or address',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilterChip(
                            label: const Text('Two rooms'),
                            selected: _twoRooms,
                            onSelected: (value) =>
                                setState(() => _twoRooms = value),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      ExampleLinks(
                        child: renderFlutter(
                          buildListingRegion(
                            apartments: apartments,
                            onSave: () => _save(context),
                          ),
                          scope: scope,
                          substitutions: materialComponents(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Flutter owns search, filters, dialogs and this page scroll. Unibox declares the listing content.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
