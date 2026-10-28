import 'dart:io';

import 'package:test/test.dart';

/// The packages `unibox_material` may depend on, besides the Dart SDK.
///
/// `unibox_core` carries the tokens, and `material_color_utilities` carries
/// Material's colour algorithm — the same one a Flutter `ColorScheme.fromSeed`
/// runs, in pure Dart with no widget layer. A seed needs the algorithm itself, not
/// a table of values copied out of another Material package.
const _allowedPackages = <String>{
  'package:unibox_core/',
  'package:material_color_utilities/',
};

/// Libraries that would tie the tokens to one platform.
const _forbiddenLibraries = <String>{'dart:ui', 'dart:html', 'dart:js_interop'};

final _directivePattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

void main() {
  test('unibox_material depends on the SDK and the two packages', () {
    final libDirectory = Directory('lib');
    expect(
      libDirectory.existsSync(),
      isTrue,
      reason: 'Expected a lib/ directory next to the package root.',
    );

    final dartFiles = libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();

    expect(
      dartFiles,
      isNotEmpty,
      reason: 'unibox_material should expose sources.',
    );

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      final uris = _directivePattern
          .allMatches(source)
          .map((match) => match.group(1)!);

      for (final uri in uris) {
        final isRelative = !uri.contains(':') && !uri.startsWith('package:');
        final isSdk =
            uri.startsWith('dart:') && !_forbiddenLibraries.contains(uri);
        final isAllowed = _allowedPackages.any(uri.startsWith);

        expect(
          isRelative || isSdk || isAllowed,
          isTrue,
          reason: '${file.path} must not use "$uri".',
        );
      }
    }
  });
}
