import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'support/harness.dart';

/// The style the rendered paragraph of [text] resolves to.
///
/// Reading it from the render object is the only honest check: it holds the
/// merged result of the node, the enclosing boxes and the ambient style.
TextStyle styleOf(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  group('inherited typography', () {
    testWidgets('passes the box typography to a text node', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          textStyle: core.BoxTextStyle(
            fontSize: 22,
            fontWeight: core.FontWeight.bold,
            color: core.BoxColor.black,
          ),
          children: <core.UINode>[core.TextNode('Hello')],
        ),
      );

      final TextStyle style = styleOf(tester, 'Hello');

      expect(style.fontSize, 22);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.color, const Color(0xFF000000));
    });

    testWidgets('lets a node override a single token', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          textStyle: core.BoxTextStyle(
            fontSize: 22,
            color: core.BoxColor.black,
            letterSpacing: 2,
          ),
          children: <core.UINode>[core.TextNode('Hello', fontSize: 12)],
        ),
      );

      final TextStyle style = styleOf(tester, 'Hello');

      expect(style.fontSize, 12);
      expect(style.color, const Color(0xFF000000));
      expect(style.letterSpacing, 2);
    });

    testWidgets('lets the closest box win over an outer one', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          textStyle: core.BoxTextStyle(
            fontSize: 22,
            color: core.BoxColor.black,
          ),
          children: <core.UINode>[
            core.TextNode('outer'),
            core.Box(
              textStyle: core.BoxTextStyle(color: core.BoxColor.white),
              children: <core.UINode>[core.TextNode('inner')],
            ),
          ],
        ),
      );

      final TextStyle inner = styleOf(tester, 'inner');

      expect(inner.fontSize, 22);
      expect(inner.color, const Color(0xFFFFFFFF));
      expect(styleOf(tester, 'outer').color, const Color(0xFF000000));
    });

    testWidgets('maps the line height and the family', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          textStyle: core.BoxTextStyle(lineHeight: 1.5, fontFamily: 'Inter'),
          children: <core.UINode>[core.TextNode('Hello')],
        ),
      );

      final TextStyle style = styleOf(tester, 'Hello');

      expect(style.height, 1.5);
      expect(style.fontFamily, 'Inter');
    });

    testWidgets(
      'makes a line box as tall as the font size times the line height',
      (tester) async {
        // A unitless CSS `line-height` and `TextStyle.height` mean the same thing,
        // so this is the one measurement the two targets can agree on without a
        // browser: the line box is `fontSize * lineHeight` on both. It is also why
        // a layout that has to line up should set `lineHeight`: without it the box
        // is as tall as the font's own metrics, which is 1em for the test font and
        // `normal` (a little over 1em, from the font's own table) in a browser.
        await pumpNode(
          tester,
          const core.TextNode('Hello', fontSize: 24, lineHeight: 1.5),
        );

        expect(tester.getSize(find.text('Hello')).height, 36);
      },
    );

    testWidgets('takes the typography from a style token', (tester) async {
      await pumpNode(
        tester,
        const core.Box(
          styles: <core.BoxStyle>[
            core.BoxStyle(textStyle: core.BoxTextStyle(fontSize: 18)),
          ],
          children: <core.UINode>[core.TextNode('Hello')],
        ),
      );

      expect(styleOf(tester, 'Hello').fontSize, 18);
    });

    testWidgets('typesets an undeclared text with the model typography', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.Box(children: <core.UINode>[core.TextNode('Hello')]),
      );

      // The two hosts have different ideas about this — 14 logical pixels of
      // black here, 16 pixels of `canvastext` in a browser — so the renderer
      // installs the default of the model instead of inheriting either.
      final TextStyle style = styleOf(tester, 'Hello');

      expect(style.fontSize, core.BoxTextStyle.defaults.fontSize);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, const Color(0xFF000000));
      expect(style.height, core.BoxTextStyle.defaults.lineHeight);
      expect(style.letterSpacing, core.BoxTextStyle.defaults.letterSpacing);
    });

    testWidgets('puts the extra line height half above, half below the glyphs', (
      tester,
    ) async {
      await pumpNode(
        tester,
        const core.TextNode('Hello', fontSize: 20, lineHeight: 2),
      );

      final TextStyle style = styleOf(tester, 'Hello');

      // What CSS calls half-leading: the line box is a fixed forty pixels, and
      // the leading it adds to the glyphs' own height is split evenly above and
      // below them, so the baseline lands halfway down the extra space.
      // Flutter's own default splits it in proportion to the font's ascent and
      // descent instead, which keeps the box the same height and moves the text
      // inside it — a jump a reader sees when a page is handed from the browser
      // to Flutter. The expectation is measured against the test host's font
      // rather than written as a number, so it holds whatever that font is.
      final TextPainter line = TextPainter(
        text: TextSpan(text: 'Hello', style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      // The glyphs with no leading at all: a line height of one is the font's
      // own height, so the distance to the baseline is the font's ascent.
      final TextPainter glyphs = TextPainter(
        text: TextSpan(text: 'Hello', style: style.copyWith(height: 1)),
        textDirection: TextDirection.ltr,
      )..layout();

      final double ascent = glyphs.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );
      final double lineBox = style.fontSize! * style.height!;

      expect(line.height, moreOrLessEquals(lineBox));
      expect(
        line.computeDistanceToActualBaseline(TextBaseline.alphabetic),
        moreOrLessEquals(
          (lineBox - glyphs.height) / 2 + ascent,
          epsilon: 0.001,
        ),
      );
    });

    testWidgets('keeps the font family the host brought', (tester) async {
      await pumpNode(
        tester,
        const core.TextNode('Hello'),
        wrap: (Widget child) => DefaultTextStyle(
          style: const TextStyle(fontFamily: 'HostFont', fontSize: 40),
          child: child,
        ),
      );

      // The default is merged over the ambient style rather than installed in
      // place of it: the model owns the tokens it declares, while the family is
      // the application's, because a font file is an asset.
      final TextStyle style = styleOf(tester, 'Hello');

      expect(style.fontFamily, 'HostFont');
      expect(style.fontSize, core.BoxTextStyle.defaults.fontSize);
    });

    testWidgets('lets a text field adopt the inherited typography', (
      tester,
    ) async {
      await pumpMaterialNode(
        tester,
        const core.Box(
          textStyle: core.BoxTextStyle(fontSize: 20),
          children: <core.UINode>[core.TextInputNode(placeholder: 'Email')],
        ),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).style?.fontSize,
        20,
      );
    });

    testWidgets('typesets a field with the model typography', (tester) async {
      await pumpMaterialNode(tester, const core.TextInputNode());

      // An `<input>` inherits the typography of the page on the web, so the
      // field adopts the tree's instead of keeping the Material input style.
      final TextStyle? style = tester
          .widget<TextField>(find.byType(TextField))
          .style;

      expect(style?.fontSize, core.BoxTextStyle.defaults.fontSize);
      expect(style?.height, core.BoxTextStyle.defaults.lineHeight);
    });
  });
}
