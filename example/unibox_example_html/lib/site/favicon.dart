/// The site's own mark: a box in a box, in the palette the page is drawn with.
///
/// A document that names no icon leaves the browser asking the origin for `/favicon.ico`, which
/// GitHub Pages answers with a 404 — one console error on every page of the site, and one every
/// "browser errors" audit of it reports. The mark is written by the build rather than shipped as an
/// asset because it is one value, in one place, and the two documents that sit at different depths
/// have to name it differently.
///
/// It is drawn with two rectangles and no text: a `U` set in a font is a mark that moves with the
/// machine it is drawn on.
library;

import 'package:unibox_html/unibox_html.dart';

/// The file the mark is written to, below the site root.
const String faviconPath = 'favicon.svg';

/// The mark itself, as an `image/svg+xml` file.
const String faviconSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
    '<rect width="32" height="32" rx="9" fill="#8c4a5d"/>'
    '<rect x="9" y="9" width="14" height="14" rx="3" fill="none" '
    'stroke="#ffffff" stroke-width="2.5"/>'
    '</svg>';

/// The `<link rel="icon">` for a document [prefix] away from the site root — `''` for `/`,
/// `'../'` for a page one directory down.
DocumentLink faviconLink(String prefix) => DocumentLink(
  rel: 'icon',
  href: '$prefix$faviconPath',
  type: 'image/svg+xml',
);
