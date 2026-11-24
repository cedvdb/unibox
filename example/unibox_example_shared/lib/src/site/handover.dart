import 'package:unibox_core/unibox_core.dart';

import '../theme.dart';
import 'section.dart';

/// The handover demo and the minimal rendering pipeline.
UINode buildHandoverSection({ExampleSeed seed = ExampleSeed.defaultSeed}) {
  final palette = ExamplePalette.materialFor(seed);
  return siteSection(
    vertical: 32,
    child: Box(
      width: double.infinity,
      gap: 20,
      children: <UINode>[
        siteHeading(palette, title: 'HTML first. Flutter next.'),
        const TextNode(
          'Scroll the example or press Save these homes while Flutter loads. '
          'Handover restores your position and replays the action when Flutter is ready.',
        ),
        const Box(
          padding: BoxSpacing.all(20),
          backgroundColor: BoxColor(0xfff7f7fa),
          children: <UINode>[
            TextNode(
              'final ui = buildListingExample(onSave: save);\n'
              'toHtml(ui);        // server\n'
              'renderFlutter(ui); // Flutter',
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ],
        ),
        const TextNode(
          'The content, layout and action keys come from one declaration. '
          'Your app supplies the data, callbacks and readiness signal.',
        ),
        const LinkNode(
          'web/takeover/',
          children: <UINode>[TextNode('Try the handover')],
        ),
      ],
    ),
  );
}
