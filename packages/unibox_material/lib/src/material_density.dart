/// The platform a rendering is for, in the model's vocabulary.
///
/// It is the one fact Material's own widgets read to decide how tight a control is drawn,
/// and it is a host's: a phone and a desk answer differently, and the model cannot ask. So it
/// is an input, like the language and the direction of a page (`design.md` §5.19), and a host
/// passes the platform it is.
enum MaterialPlatform {
  /// Android, with touch and a Material system UI.
  android,

  /// iOS, with touch.
  ios,

  /// Fuchsia, with touch.
  fuchsia,

  /// macOS, with a pointer.
  macos,

  /// Windows, with a pointer.
  windows,

  /// Linux, with a pointer.
  linux,
}

/// How tight Material draws a control, in steps of four pixels.
///
/// It mirrors `VisualDensity`: two steps one way or the other, and a step is four logical
/// pixels on a control's height — so a 40 pixel button is 32 at [compact], which is what
/// Flutter draws on a desk and in a browser.
///
/// **The model states the platform, not the density.** A host says what it is and this says
/// what follows, exactly as `VisualDensity.adaptivePlatformDensity` does: one derivation, in
/// the model, so the page and the application cannot disagree about which one applies.
enum MaterialDensity {
  /// Touch: what a phone does, and what this package's components state by default.
  standard(0),

  /// A pointer: what a desk and a browser do. Four pixels off a control's height per step.
  compact(-2);

  const MaterialDensity(this.vertical);

  /// The steps, which is `VisualDensity.vertical`: a step is four logical pixels.
  final int vertical;

  /// The density [platform] draws at, which is Flutter's own answer.
  static MaterialDensity forPlatform(MaterialPlatform platform) =>
      switch (platform) {
        MaterialPlatform.android ||
        MaterialPlatform.ios ||
        MaterialPlatform.fuchsia => standard,
        MaterialPlatform.macos ||
        MaterialPlatform.windows ||
        MaterialPlatform.linux => compact,
      };

  /// [height] drawn at this density: 40 becomes 32 at [compact].
  double adjust(double height) => height + vertical * 4;
}
