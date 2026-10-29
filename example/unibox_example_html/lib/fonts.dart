/// The family both hosts ship.
///
/// The Flutter app bundles the same files through `flutter: fonts:` in its
/// pubspec, which is what makes `w400`, `w500`, `w600` and `w700` four *drawn*
/// faces on both renderings. Without them a browser substitutes the nearest face
/// its system family has and Skia does the same, from a different family — so a
/// semibold page and a semibold app came out at visibly different weights.
const String fontFamily = 'UniboxText';

/// The weights the example ships, in the order a browser prefers them.
///
/// The web files are `woff2`, subsetted to the Latin range: 496 kB of `truetype` became 80 kB, and
/// under a phone's network that is most of a second before text settles. Flutter bundles the same
/// four faces as `ttf`, because that is the format it draws; the two are generated from one source
/// and the weights have to agree, which is what this list is for.
const List<String> fontWeights = <String>['400', '500', '600', '700'];

/// The two weights that paint above the fold, and so are worth fetching before the CSS is parsed.
///
/// Body text and a heading are `400` and `500` in the Material scale this example is drawn with.
/// A `preload` is not decoration: a font is discovered only after the stylesheet that names it has
/// been parsed, which puts the download a round trip behind the document. Naming the two here starts
/// it with the document instead.
const List<String> fontPreloadWeights = <String>['400', '500'];

/// The `<link rel="preload">` elements for [fontPreloadWeights], at [prefix].
///
/// `crossorigin` is required even for a same-origin font: without it the browser fetches the file
/// twice, once for the preload and once for the `@font-face`, which is worse than not preloading.
String fontPreloadLinks(String prefix) {
  return fontPreloadWeights
      .map(
        (String weight) =>
            '<link rel="preload" href="${prefix}assets/fonts/roboto-$weight.woff2" '
            'as="font" type="font/woff2" crossorigin>',
      )
      .join();
}

/// The `@font-face` rules of the family, one per weight.
///
/// [prefix] is how far the document sits from the site root — `''` for `/`,
/// `'../'` for `/material/`, `'../../'` for `/web/listings/`. The site writes no
/// `<base>` element, so a relative url is resolved against the document, and every
/// document has to say where it is.
String fontFaceCss(String prefix) {
  String face(String weight) =>
      """
@font-face {
  font-family: '$fontFamily';
  font-style: normal;
  font-weight: $weight;
  font-display: swap;
  src: url(${prefix}assets/fonts/roboto-$weight.woff2) format('woff2');
}""";

  return fontWeights.map(face).join();
}
