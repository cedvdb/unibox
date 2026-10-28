import 'package:unibox_css/unibox_css.dart';

import 'client_script.dart';

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
  final List<({String className, CssDeclarations declarations})> _rules =
      <({String className, CssDeclarations declarations})>[];

  /// The state rules, in the order their classes were asked for.
  final List<CssRule> _states = <CssRule>[];

  /// Whether the tree marked a press the client script may paint.
  bool get usesInk => _usesInk;

  bool _usesInk = false;

  /// Records that the tree marked a press, so the drop's own rule is written.
  void markInk() => _usesInk = true;

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
    final bool known = _rules.any(
      (({String className, CssDeclarations declarations}) rule) =>
          rule.className == className,
    );

    if (known) {
      return className;
    }

    _rules.add((className: className, declarations: declarations));

    if (states != null) {
      _states.addAll(states(className));
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

    if (_usesInk) {
      buffer.writeln(inkDeclarations);
    }

    for (final ({String className, CssDeclarations declarations}) rule
        in _rules) {
      if (rule.declarations.isEmpty) {
        continue;
      }

      buffer.writeln('.${rule.className}{${rule.declarations.text}}');
    }

    for (final CssRule rule in _states) {
      if (rule.declarations.isEmpty) {
        continue;
      }

      final String? condition = rule.media;

      if (condition == null) {
        buffer.writeln('${rule.selector}{${rule.declarations.text}}');
        continue;
      }

      buffer.writeln(
        '@media $condition{${rule.selector}{${rule.declarations.text}}}',
      );
    }

    return buffer.toString();
  }
}
