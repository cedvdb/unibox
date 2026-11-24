import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:unibox_flutter/unibox_flutter.dart';

import 'page_address.dart';

/// The example host's link policy, independent of the shared declaration.
class ExampleLinks extends StatelessWidget {
  /// Navigates in a browser, or displays a copyable destination on native targets.
  const ExampleLinks({required this.child, this.base, super.key});

  /// The shared region or guide that can request a destination.
  final Widget child;

  /// An explicit document base when the guide is hosted under `/flutter/`.
  final Uri? base;

  @override
  Widget build(BuildContext context) => FlutterLinkScope(
    open: (url) {
      final destination = base?.resolve(url).toString() ?? url;
      if (navigateTo(destination)) return;
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Link destination'),
            content: SelectableText(destination),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
    child: child,
  );
}
