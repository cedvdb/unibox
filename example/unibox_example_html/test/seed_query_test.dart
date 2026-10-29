import 'package:test/test.dart';
import 'package:unibox_example_html/site/site_document.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

/// Which palette an address asks for.
///
/// The header's picker is a row of links, so the address is the whole protocol: the export writes
/// the default palette and the runtime answers `?seed=<name>`. A query read the wrong way does not
/// fail loudly — it quietly answers the default, which looks exactly like a picker that does
/// nothing.
void main() {
  group('a seed in the address', () {
    test('is the palette the name on the list says', () {
      for (final ExampleSeed seed in ExampleSeed.values) {
        expect(seedFromQuery('?seed=${seed.name}'), seed);
      }
    });

    test('is read with the question mark a location carries', () {
      // `Uri.splitQueryString` expects the query alone, so `?seed=blue` read as it arrives
      // answers the default palette.
      expect(seedFromQuery('?seed=blue'), ExampleSeed.blue);
    });

    test('falls back to the default when the address names none', () {
      expect(seedFromQuery(''), ExampleSeed.defaultSeed);
      expect(seedFromQuery('?'), ExampleSeed.defaultSeed);
      expect(seedFromQuery('?seed='), ExampleSeed.defaultSeed);
      expect(seedFromQuery('?seed=nonsense'), ExampleSeed.defaultSeed);
    });
  });
}
