import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_material/unibox_material.dart';

/// A host-supplied seed for the shared example's design values.
enum ExampleSeed {
  /// The guide's default warm accent.
  rose(BoxColor(0xffb3265e)),

  /// An alternative used to check that declarations do not hardcode the palette.
  blue(BoxColor(0xff2d6cf3));

  const ExampleSeed(this.color);

  /// The colour from which the palette is derived.
  final BoxColor color;

  /// The default across both example hosts.
  static const ExampleSeed defaultSeed = rose;
}

/// The same Material values installed by the server and Flutter hosts.
abstract final class ExamplePalette {
  static final Map<ExampleSeed, MaterialPalette> _palettes =
      <ExampleSeed, MaterialPalette>{
        for (final seed in ExampleSeed.values)
          seed: MaterialPalette.fromSeed(seed.color),
      };

  /// The colour palette supplied to native Flutter theme conversion.
  static MaterialPalette materialFor(ExampleSeed seed) => _palettes[seed]!;

  /// The same roles supplied to the shared declaration renderer.
  static UniboxTheme themeFor(ExampleSeed seed) => materialFor(seed).theme;
}
