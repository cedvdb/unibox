import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_css/unibox_css.dart';

/// The rules one rendering needs, each one once.
///
/// A look becomes a class the first time it is asked for, so six listings with one look
/// declare it once and no element carries an inline style a host cannot override. The
/// class name is a hash of the declarations, so the same look gets the same name in every
/// rendering of the same tree — which is what lets a host write a stylesheet against it,
/// and what a client renderer would adopt.
final class Stylesheet {
  /// Creates an empty sheet.
  Stylesheet();

  /// The declarations of every class, in the order the classes were first asked for.
  ///
  /// A map rather than a list: a rendering asks for a class once per node, and finding out
  /// whether it already has one must not be a scan of every look a big page has. Insertion
  /// order is the order the rules are written in, which is what a `LinkedHashMap` gives.
  final Map<String, CssDeclarations> _rules = <String, CssDeclarations>{};

  /// The state rules, in the order their classes were asked for.
  final List<CssRule> _states = <CssRule>[];

  /// How many times a rule has been added, which is what tells a renderer whether the
  /// stylesheet it wrote into the page is still the one this sheet describes.
  ///
  /// A renderer that repaints on every publish — an ink ripple publishes sixty times a
  /// second — asks this before it serialises the sheet, because serialising a few thousand
  /// rules and handing them to a browser is the most expensive thing a publish can do, and
  /// between two publishes of the same tree it cannot have changed.
  int get revision => _revision;

  int _revision = 0;

  /// How many distinct looks the rendering has, which is its CSS cost.
  int get length => _rules.length;

  /// The class for [declarations], registered the first time it is asked for.
  ///
  /// [kind] only names the class (`unibox-box-…`, `unibox-text-…`) so the output says
  /// what an element is; the deduplication is the declarations'. [states] is asked once
  /// per class, so a state rule is written once however many elements wear the look.
  ///
  /// [key] overrides what is hashed, for an element whose class carries more than its own
  /// declarations — a field whose `::placeholder` rule differs from another field's must
  /// not share its class, or the first hint colour would win for both.
  String classFor(
    String kind,
    CssDeclarations declarations, {
    List<CssRule> Function(String className)? states,
    String? key,
  }) {
    final String className = classNameFor(kind, key ?? declarations.text);

    if (_rules.containsKey(className)) {
      return className;
    }

    _rules[className] = declarations;
    _revision++;

    if (states != null) {
      final List<CssRule> added = states(className);

      if (added.isNotEmpty) {
        _states.addAll(added);
        _revision++;
      }
    }

    return className;
  }

  /// Every rule, as the body of one `<style>` element.
  ///
  /// The looks first, then the states, so a state rule can override a resting one. A
  /// hover rule is wrapped in its media condition, because a phone that reported a hover
  /// would otherwise be stuck in it after a tap.
  String get css {
    final StringBuffer buffer = StringBuffer();

    for (final MapEntry<String, CssDeclarations> rule in _rules.entries) {
      if (rule.value.isEmpty) {
        continue;
      }

      buffer.writeln('.${rule.key}{${rule.value.text}}');
    }

    for (final CssRule rule in _states) {
      if (rule.declarations.isEmpty) {
        continue;
      }

      final String body = '${rule.selector}{${rule.declarations.text}}';
      final String? media = rule.media;
      final String? container = rule.container;

      if (media != null) {
        buffer.writeln('@media $media{$body}');
        continue;
      }

      buffer.writeln(container == null ? body : '@container $container{$body}');
    }

    return buffer.toString();
  }
}

/// The CSS a page needs before the tree: the typography of the model, the colours of the theme,
/// then every class the tree wears.
///
/// The `:root` block first, because it is what a text with no declarations of its own inherits; the
/// classes after it, so a look always outranks the default it started from.
///
/// Here rather than in a renderer because both web renderers have to produce the same text: a class
/// name is a hash of the declarations behind it, so a renderer that assembled its CSS differently
/// would write different class names for the same tree, and a client could no longer adopt a page a
/// server wrote.
String documentCss(Stylesheet sheet, {core.UniboxTheme? theme}) {
  final CssDeclarations root = defaultTypographyDeclarations();

  if (theme != null) {
    root
      // What the theme says it is, so the browser paints the chrome the tree does not draw —
      // scrollbars, the caret, the canvas before this stylesheet applies — in the same scheme.
      // Without it a light page in a dark-mode browser gets dark scrollbars and a white caret.
      ..add('color-scheme', theme.colorScheme.name)
      ..addAllIn(themeDeclarations(theme));
  }

  return ':root{${root.text}}${sheet.css}';
}
