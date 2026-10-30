import 'package:unibox_core/unibox_core.dart' as core;

import 'text_appearance.dart';

/// One text node together with the typesetting every renderer has to give it.
///
/// A renderer suite renders [node], reads the typography back from its own output
/// and compares it with [expected]. Since both renderers are checked against the
/// same entry, the entry is the only place the answer is written down: it cannot be
/// relaxed for one target without failing the other.
final class TextCase {
  /// Creates a case named [description] that renders [node] into [expected].
  const TextCase({
    required this.description,
    required this.node,
    required this.expected,
  });

  /// What the case describes, phrased as the test that checks it.
  final String description;

  /// The text node to render.
  final core.TextNode node;

  /// The typesetting the rendered output has to have.
  final TextAppearance expected;

  @override
  String toString() => 'TextCase($description)';
}

/// The typography a text node is typeset in when nothing in the tree overrides
/// it, as both renderers have to produce it.
///
/// It is written out rather than derived from [core.BoxTextStyle.defaults] so that
/// this stays a statement about what a page looks like: the two are held together
/// by a test in this package, and a change to either has to be made twice on
/// purpose.
///
/// The family is absent because the model names none — unset means the platform's
/// UI font, which CSS spells `system-ui` and Flutter leaves to the engine, and
/// which this description can therefore only observe as "no family chosen".
const TextAppearance defaultTextAppearance = TextAppearance(
  fontSize: 16,
  fontWeight: core.FontWeight.normal,
  color: core.BoxColor.black,
  lineHeight: 1.5,
  letterSpacing: 0,
);

/// The text nodes every renderer is checked against.
///
/// The table takes the tokens a text node can carry one by one — each case sets a
/// single token and expects plain text plus that token — and then all of them at
/// once, so a renderer has to both honour a token on its own and keep honouring it
/// next to the others. The two cases at the end cover the ways a style reaches a
/// node: through a `BoxTextStyle` with a flat override on top of it, and through
/// every token at once.
///
/// The truncation cases are the only ones where the two targets reach the same
/// outcome by different means: Flutter truncates with `maxLines` and
/// `TextOverflow`, CSS with a `-webkit-line-clamp` box and `text-overflow`. Both
/// end a line with an ellipsis, or cut it off, so both are compared by that
/// outcome.
const List<TextCase> textCases = <TextCase>[
  TextCase(
    description: 'renders a text node without tokens as plain text',
    node: core.TextNode('Rendered by both'),
    expected: TextAppearance(),
  ),
  TextCase(
    description: 'sets the font size in logical pixels',
    node: core.TextNode('Hello Unibox', fontSize: 24),
    expected: TextAppearance(fontSize: 24),
  ),
  TextCase(
    description: 'sets the weight of the font',
    node: core.TextNode('Hello Unibox', fontWeight: core.FontWeight.semiBold),
    expected: TextAppearance(fontWeight: core.FontWeight.semiBold),
  ),
  TextCase(
    description: 'recedes to a light weight for a label',
    node: core.TextNode('Category', fontWeight: core.FontWeight.light),
    expected: TextAppearance(fontWeight: core.FontWeight.light),
  ),
  TextCase(
    description: 'sets the colour of the glyphs',
    node: core.TextNode('Hello Unibox', color: _ink),
    expected: TextAppearance(color: _ink),
  ),
  TextCase(
    description: 'keeps the alpha of a translucent colour',
    node: core.TextNode('Hello Unibox', color: _veil),
    expected: TextAppearance(color: _veil),
  ),
  TextCase(
    description: 'sets the line height as a multiple of the font size',
    node: core.TextNode('Hello Unibox', fontSize: 16, lineHeight: 1.5),
    expected: TextAppearance(fontSize: 16, lineHeight: 1.5),
  ),
  TextCase(
    description: 'sets the space between characters',
    node: core.TextNode('Hello Unibox', letterSpacing: 0.4),
    expected: TextAppearance(letterSpacing: 0.4),
  ),
  TextCase(
    description: 'sets the family of the font',
    node: core.TextNode('Hello Unibox', fontFamily: 'Inter'),
    expected: TextAppearance(fontFamily: 'Inter'),
  ),
  TextCase(
    description: 'aligns the lines inside the space the text is given',
    node: core.TextNode('Hello Unibox', textAlign: core.TextAlign.center),
    expected: TextAppearance(textAlign: core.TextAlign.center),
  ),
  TextCase(
    description: 'truncates after a number of lines with an ellipsis',
    node: core.TextNode(
      'A description long enough that the second line has to be cut short.',
      maxLines: 2,
      overflow: core.TextOverflow.ellipsis,
    ),
    expected: TextAppearance(maxLines: 2, overflow: core.TextOverflow.ellipsis),
  ),
  TextCase(
    description: 'truncates a single line with an ellipsis',
    node: core.TextNode(
      'A description long enough that the line has to be cut short.',
      overflow: core.TextOverflow.ellipsis,
    ),
    expected: TextAppearance(overflow: core.TextOverflow.ellipsis),
  ),
  TextCase(
    description: 'clips a single line instead of ellipsizing it',
    node: core.TextNode(
      'Cut off at the edge of the line instead of ending in dots.',
      overflow: core.TextOverflow.clip,
    ),
    expected: TextAppearance(overflow: core.TextOverflow.clip),
  ),
  TextCase(
    description:
        'takes the typography from a style and lets the flat tokens win',
    node: core.TextNode(
      'Hello Unibox',
      style: core.BoxTextStyle(
        fontSize: 18,
        fontWeight: core.FontWeight.medium,
        color: _ink,
      ),
      fontSize: 22,
      letterSpacing: 1.5,
    ),
    expected: TextAppearance(
      fontSize: 22,
      fontWeight: core.FontWeight.medium,
      color: _ink,
      letterSpacing: 1.5,
    ),
  ),
  TextCase(
    description: 'typesets every token at once',
    node: core.TextNode(
      'Every token of the model, on one node, in both renderers.',
      fontSize: 20,
      fontWeight: core.FontWeight.bold,
      color: _veil,
      lineHeight: 1.6,
      fontFamily: 'Inter',
      letterSpacing: 0.6,
      textAlign: core.TextAlign.right,
      maxLines: 3,
      overflow: core.TextOverflow.ellipsis,
    ),
    expected: TextAppearance(
      fontSize: 20,
      fontWeight: core.FontWeight.bold,
      color: _veil,
      lineHeight: 1.6,
      fontFamily: 'Inter',
      letterSpacing: 0.6,
      textAlign: core.TextAlign.right,
      maxLines: 3,
      overflow: core.TextOverflow.ellipsis,
    ),
  ),
];

/// The ink of the table.
const core.BoxColor _ink = core.BoxColor.rgb(0x1A, 0x1C, 0x22);

/// A half transparent ink, for the alpha of a colour.
const core.BoxColor _veil = core.BoxColor(0x80112233);
