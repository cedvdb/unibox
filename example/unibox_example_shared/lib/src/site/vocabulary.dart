import 'package:unibox_core/unibox_core.dart';

import '../theme.dart';
import 'section.dart';

/// Optional handover is explained separately from the primary rendering example.
UINode buildVocabularySection({ExampleSeed seed = ExampleSeed.defaultSeed}) {
  final palette = ExamplePalette.materialFor(seed);
  return siteSection(
    child: Box(
      width: double.infinity,
      gap: 24,
      children: <UINode>[
        siteHeading(
          palette,
          title: 'Optional: hand the document to Flutter',
          lead:
              'A document can stand alone. When the product needs an application on the same '
              'page, the host can opt into a coordinated transition.',
        ),
        const TextNode(
          'Open the separate demo below. Read and scroll the HTML while the Flutter '
          'bundle loads, or press Save this search. The host supplies the page scroll controller '
          'and signals readiness after its destination layout exists. Unibox restores the latest '
          'document offset before reveal, then replays one intercepted action using its stable key.',
        ),
        const TextNode(
          'Ordinary links keep their browser behaviour. If startup fails or times out, '
          'the document remains available. Absolute offsets are an initial restoration strategy: '
          'different line breaks or native control sizes can still shift content. Test representative '
          'layouts instead of assuming pixel identity.',
        ),
        const LinkNode(
          'web/takeover/',
          children: <UINode>[TextNode('Try the optional handover demo')],
        ),
        const LinkNode(
          'https://github.com/cedvdb/unibox/blob/main/docs/takeover.md',
          children: <UINode>[TextNode('Read the host integration contract')],
        ),
      ],
    ),
  );
}
