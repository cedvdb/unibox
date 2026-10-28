/// How Material spends the colour of a seed.
///
/// Material's colour system has two dials. One is the source colour — the brand
/// colour a palette is grown from. The other is the variant: the way that colour
/// is spent, from a whisper to a shout, and the reason the same blue can be a
/// quiet application and a playful one. [MaterialPalette.fromSeed] takes both.
///
/// [tonalSpot] is the default, and the scheme a Material You application runs on
/// Android: pastel containers over palettes of low chroma. Every other variant
/// trades something to protect something else, and each member says what it
/// protects. None of them is a different colour space: they assign the same
/// roles from the same tonal palettes, with a different hue and chroma and a
/// different tone.
enum MaterialSchemeVariant {
  /// Pastel tones from a low chroma palette — the default Material You scheme,
  /// and the one a Flutter `ColorScheme.fromSeed` builds when it is given no
  /// variant of its own.
  tonalSpot,

  /// The seed's own colour, at the seed's own chroma, so the accent is the
  /// colour the brand chose. A container is moved in tone until it reads against
  /// the surface instead.
  fidelity,

  /// Almost [fidelity], with a container that is the seed itself, adjusted only
  /// when it would not read against the surface.
  content,

  /// Pastel tones from a palette at its maximum chroma: the same hue as
  /// [tonalSpot] with far more colour in the accents.
  vibrant,

  /// A medium chroma, and a hue that deliberately leaves the seed's: a scheme
  /// that is recognisably related to the brand without repeating it.
  expressive,

  /// Barely any chroma at all: a quiet scheme that reads as greys with a hint of
  /// the seed's hue, for an interface whose colour should come from its content.
  neutral,

  /// No chroma at all. Every role is a grey, and the surface tones carry the
  /// whole hierarchy — the scheme to reach for when a page must not have a
  /// colour of its own.
  monochrome,

  /// A playful scheme whose hues avoid the seed's altogether: a page in colours
  /// the brand never uses.
  rainbow,

  /// The same idea as [rainbow] with different hue rotations, so two playful
  /// seeds do not land on the same palette.
  fruitSalad,
}
