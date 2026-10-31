import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_element/unibox_element.dart';

/// Which declaration wins when a node says the same thing twice.
///
/// The two conformance suites hold the *result* of this to one table, but they ask it of a tree that
/// states each token once. These ask the question the model actually documents — a flat parameter over
/// a style bag, a later bag over an earlier one, a state over the resting look — because that rule is
/// the one a caller relies on and the one a change to `computedStyle` can quietly invert.
void main() {
  /// The declarations the root element of [node] wears.
  Map<String, String> declarationsOf(core.UINode node) {
    final Stylesheet sheet = Stylesheet();
    final ElementPlan plan = planNode(node, sheet);
    final String css = sheet.css;
    final String? name = plan.className;

    if (name == null) {
      return const <String, String>{};
    }

    final RegExpMatch? rule = RegExp(
      r'\.' + RegExp.escape(name) + r'\{([^}]*)\}',
    ).firstMatch(css);

    final Map<String, String> declarations = <String, String>{};

    for (final String declaration in rule!.group(1)!.split(';')) {
      final int colon = declaration.indexOf(':');

      if (colon > 0) {
        declarations[declaration.substring(0, colon)] = declaration.substring(
          colon + 1,
        );
      }
    }

    return declarations;
  }

  group('a flat parameter', () {
    test('beats a style bag', () {
      // The spelling most callers use, and the one the model says wins.
      final Map<String, String> declarations = declarationsOf(
        const core.Box(
          styles: <core.BoxStyle>[
            core.BoxStyle(padding: core.BoxSpacing.all(20)),
          ],
          padding: core.BoxSpacing.all(4),
        ),
      );

      // Four equal sides are written once: the stylesheet is text, and a declaration that repeats
      // itself is a declaration a reader has to read four times.
      expect(declarations['padding'], '4px');
    });

    test('beats every bag, not just the first', () {
      final Map<String, String> declarations = declarationsOf(
        const core.Box(
          styles: <core.BoxStyle>[
            core.BoxStyle(gap: 8),
            core.BoxStyle(gap: 16),
          ],
          gap: 2,
        ),
      );

      expect(declarations['gap'], '2px');
    });
  });

  group('a style bag', () {
    test('later wins over earlier', () {
      final Map<String, String> declarations = declarationsOf(
        const core.Box(
          styles: <core.BoxStyle>[
            core.BoxStyle(gap: 8),
            core.BoxStyle(gap: 16),
          ],
        ),
      );

      expect(declarations['gap'], '16px');
    });

    test('carries the direction the words flow in to the element', () {
      // The class is where the web keeps it: `direction` is inherited, so a region states
      // its own once and everything inside it reads that way.
      final Map<String, String> declarations = declarationsOf(
        const core.Box(writingDirection: core.WritingDirection.rtl),
      );

      expect(declarations['direction'], 'rtl');
      expect(
        declarationsOf(const core.Box()).containsKey('direction'),
        isFalse,
        reason: 'the page states the direction, and a box that says nothing inherits it',
      );
    });

    test('is the model default when nothing sets the token', () {
      // Not the browser's default: a box with no direction is a column because the model says so.
      final Map<String, String> declarations = declarationsOf(const core.Box());

      expect(declarations['flex-direction'], 'column');
      // `start`, not `flex-start`: the declaration is CSS's, and the model's `MainAlign.start` is
      // what a flex item means by it.
      expect(declarations['justify-content'], 'start');
      expect(declarations['align-items'], 'start');
    });
  });

  group('a state style', () {
    test('overlays the resting look in its own rule', () {
      final Stylesheet sheet = Stylesheet();
      planNode(
        const core.Box(
          backgroundColor: core.BoxColor.rgb(0x11, 0x22, 0x33),
          hoverStyle: core.BoxStyle(
            backgroundColor: core.BoxColor.rgb(0xff, 0x00, 0x00),
          ),
        ),
        sheet,
      );

      final String css = sheet.css;

      // Two rules: the resting look, and the hover rule that only carries what changes.
      expect(css, contains(':hover{'));
      expect(css, contains('#ff0000'));
      expect(
        RegExp(r':hover\{([^}]*)\}').firstMatch(css)!.group(1),
        contains('background-color'),
      );
      expect(
        RegExp(r':hover\{([^}]*)\}').firstMatch(css)!.group(1),
        isNot(contains('flex-direction')),
        reason:
            'a state rule carries what the state changes, not the whole look',
      );
    });

    test('carries no paint when the state changes none', () {
      // A box that listens states the two structural declarations every state rule needs, and nothing
      // else: an empty hover style must not cost a browser a repaint.
      final Stylesheet sheet = Stylesheet();
      planNode(const core.Box(hoverStyle: core.BoxStyle()), sheet);

      final String? hover = RegExp(r':hover\{([^}]*)\}')
          .firstMatch(sheet.css)
          ?.group(1);

      expect(hover, isNotNull, reason: 'the rule is there for the structure');
      expect(hover, isNot(contains('background-color')));
      expect(hover, isNot(contains('opacity')));
      expect(hover, isNot(contains('flex-direction')));
    });
  });

  group('a disabled box', () {
    test('says so in its attributes, and takes no pointer', () {
      // The flag is a fact about the element, not a rule a stylesheet can wait for: a reader's browser
      // has to know before any CSS is matched, so it is written on the element and the look travels in
      // the class with the rest of it.
      final Stylesheet sheet = Stylesheet();
      final ElementPlan plan = planNode(const core.Box(enabled: false), sheet);

      expect(plan.attributes['aria-disabled'], 'true');
      expect(
        declarationsOf(const core.Box(enabled: false))['pointer-events'],
        'none',
      );
    });
  });
}
