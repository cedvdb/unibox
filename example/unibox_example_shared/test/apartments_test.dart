import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';

import 'support/tree.dart';

void main() {
  test(
    'declares the supplied listings without application controls or stores',
    () {
      final region = buildListingRegion(
        apartments: exampleApartments.take(2).toList(),
      );
      final nodes = flatten(region);
      expect(nodes.whereType<MaterialCard>(), hasLength(2));
      expect(textsIn(region), contains(exampleApartments.first.name));
      expect(textsIn(region), isNot(contains(exampleApartments.last.name)));
      expect(nodes.whereType<TextInputNode>(), isEmpty);
      expect(nodes.whereType<OverlayNode>(), isEmpty);
      expect(nodes.whereType<StatefulNode<Object, Store<Object>>>(), isEmpty);
      expect(
        validateTree(
          region,
          scope: UniboxScope(
            theme: ExamplePalette.themeFor(ExampleSeed.defaultSeed),
          ),
        ),
        isEmpty,
      );
    },
  );
  test('offers one stable save action only when the host supplies it', () {
    int saves = 0;
    expect(
      flatten(buildListingRegion()).where((node) => node.key == 'listing-save'),
      isEmpty,
    );
    final action = flatten(buildListingRegion(onSave: () => saves++))
        .whereType<MaterialButton>()
        .single;
    expect(action.key, 'listing-save');
    action.onPressed!();
    expect(saves, 1);
  });
  test('describes an empty result without inventing a search runtime', () {
    final region = buildListingRegion(apartments: const <Apartment>[]);
    expect(flatten(region).whereType<MaterialCard>(), isEmpty);
    expect(
      textsIn(region),
      contains('No homes match your search. Try another city.'),
    );
  });
  test('names photos and defers their location to the host', () {
    final photos = flatten(buildListingRegion(photoPrefix: '../../'))
        .whereType<ImageNode>()
        .toList();
    expect(photos, hasLength(exampleApartments.length));
    expect(
      photos.first.src,
      '../../assets/photos/${exampleApartments.first.photo}',
    );
    expect(photos.every((photo) => photo.alt.isNotEmpty), isTrue);
  });
}
