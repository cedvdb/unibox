import 'package:jaspr/dom.dart' hide BoxShadow;
import 'package:jaspr/server.dart';
import 'package:unibox_core/unibox_core.dart';
import 'package:unibox_example_shared/unibox_example_shared.dart';
import 'package:unibox_material/unibox_material.dart';

import '../fonts.dart';
import 'site_root.dart';

/// The document a page of the site is served as.
///
/// The metadata belongs to the document, not to the tree: a title and a description
/// describe a page. `fill` is the browser half of [buildSiteFrame]'s `fill` — the
/// percentage heights of the showcase need a root with a height to resolve against,
/// and the body margin has to go or it paints a frame nothing in the tree asked for.
///
/// `build` is the commit the document was rendered from, written into the head as
/// `unibox-build`. A tab opened before a deploy and the deployed page look the
/// same, down to a layout the new build has already fixed, so the one thing that
/// separates them is a fact carried by the document itself: `curl` the page and the
/// stamp answers the question the screenshot cannot. It is `null` for a build that
/// cannot name itself — a test, or a local run outside a repository.
Document buildSiteDocument({required SitePage page, String? build}) {
  final MaterialPalette palette = ExamplePalette.material;

  return Document(
    lang: 'en',
    // The site is served from a subdirectory — `/unibox/` — so the default base
    // href of `/` would resolve every relative link, and both frames, against the
    // domain root: a page of 404s. No base element makes the browser resolve
    // against the document, which is what a page that links with `../` expects.
    base: null,
    title: switch (page) {
      SitePage.home => 'Unibox — one tree, two renderers',
      SitePage.material => 'Unibox — Material 3, as values and nodes',
      SitePage.showcase => 'Unibox — the same tree, drawn twice',
    },
    viewport: 'width=device-width, initial-scale=1',
    meta: <String, String>{
      'description': switch (page) {
        SitePage.home =>
          'Describe a screen once, in plain Dart, and draw it twice: Flutter '
              'widgets in an app and HTML with CSS in a browser.',
        SitePage.material =>
          'The Material 3 type scale, the colour roles and the components of '
              'Unibox, written as values and nodes that render the same on both '
              'targets.',
        SitePage.showcase =>
          'One Unibox node tree, drawn by Jaspr as HTML and CSS on the left and by '
              'Flutter on the right.',
      },
      // The commit this document was rendered from. A stale tab and the deployed
      // page are otherwise identical to look at.
      'unibox-build': ?build,
    },
    // The home document is the site root; the gallery and the showcase live one
    // directory below it.
    head: <Component>[
      fontFaces(page == SitePage.home ? '' : '../'),
      // The browser runtime, one directory up from every page but the root. It is
      // what makes the gallery's ripple move; the page reads without it.
      Component.element(
        tag: 'script',
        attributes: <String, String>{
          'src': '${'../' * page.depth}main.client.js',
          'defer': '',
        },
      ),
    ],
    styles: <StyleRule>[
      StyleRule(
        selector: const Selector('html, body'),
        styles: Styles(height: const Unit.percent(100), margin: Spacing.zero),
      ),
      StyleRule(
        selector: const Selector('body'),
        styles: Styles(
          raw: <String, String>{
            'background-color': '#${_hex(palette.surface)}',
            'font-family': "UniboxText, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif",
          },
        ),
      ),
    ],
    // The shell the browser redraws: the runtime renders the same root, so the
    // gallery arrives and keeps arriving as one tree.
    body: buildSiteRoot(page),
  );
}

/// A colour as `RRGGBB`, for the one rule the frame writes as raw CSS.
String _hex(BoxColor color) {
  final String digits = color.value.toRadixString(16).padLeft(8, '0');
  return digits.substring(2).toUpperCase();
}
