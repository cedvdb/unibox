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

  /// The class names in the order they were first asked for, which is the order the rules are
  /// written in — a map keeps that order but cannot be read from the middle of.
  final List<String> _classOrder = <String>[];

  /// The state rules, in the order their classes were asked for.
  final List<CssRule> _states = <CssRule>[];

  /// The class each state rule belongs to, so forgetting a class can forget its states.
  ///
  /// A rule's selector says which class it is for, but not where the name ends: this is the
  /// sheet's own record, kept beside [_states] and pruned with it.
  final List<String> _owners = <String>[];

  /// The class of every look this sheet has already composed, so a look asked for twice is
  /// composed once. Its size is the number of distinct looks, which is what the rules cost
  /// too.
  final Map<Object, String> _looks = <Object, String>{};

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
    _classOrder.add(className);
    _revision++;

    if (states != null) {
      final List<CssRule> added = states(className);

      if (added.isNotEmpty) {
        _states.addAll(added);
        _owners.addAll(List<String>.filled(added.length, className));
        _revision++;
      }
    }

    return className;
  }

  /// The class for the look [look] names, with its declarations composed only the first
  /// time that look is asked for.
  ///
  /// A rendering asks for a look once per node that wears it: a list of a thousand rows
  /// wears one class, and every row built the declarations, sorted them, joined them into
  /// the canonical text and hashed that text — about three microseconds of work — only for
  /// [classFor] to answer with a class it already had. Remembering the answer costs about
  /// a fifth of that, and on a page of shared looks the plan was two thirds this work.
  ///
  /// [look] has to tell apart every pair of looks whose declarations *or state rules*
  /// differ: a settled look is never composed again, so two different looks behind one key
  /// would share a class and lose the difference between them. What counts is whatever the
  /// caller's declarations and states are computed from — a resolved style and the flags
  /// that change what it says.
  String classForLook(
    Object look,
    String kind,
    CssDeclarations Function() declarations, {
    List<CssRule> Function(String className)? states,
  }) {
    final String? known = _looks[look];

    if (known != null) {
      return known;
    }

    final String className = classFor(kind, declarations(), states: states);

    return _looks[look] = className;
  }

  /// Forgets every rule of a class that is not in [keep], and every look remembered for one.
  ///
  /// A view lives as long as the page it draws, and every look a store mints is a rule — a list
  /// whose styling follows its data, a ripple pressed in a new place, a spinner that does not
  /// repeat its steps. A look the page has stopped wearing is never asked for again by name, so
  /// holding its rule is holding nothing: [keep] is every class an element on the page wears, and
  /// everything else goes. A look that comes back is registered again, under the name it had,
  /// because the name is a hash of the declarations.
  ///
  /// Returns whether anything was forgotten, which is what a renderer needs to know: the rules a
  /// page holds cannot be taken out one at a time from outside, so a sheet that lost rules is
  /// written again whole.
  bool retain(Set<String> keep) {
    final int classes = _rules.length;
    final int states = _states.length;

    _rules.removeWhere((String className, _) => !keep.contains(className));
    _classOrder.removeWhere((String className) => !keep.contains(className));
    _looks.removeWhere((_, String className) => !keep.contains(className));

    int next = 0;

    for (int i = 0; i < _states.length; i++) {
      if (!keep.contains(_owners[i])) {
        continue;
      }

      _states[next] = _states[i];
      _owners[next] = _owners[i];
      next++;
    }

    _states.length = next;
    _owners.length = next;

    if (classes == _rules.length && states == _states.length) {
      return false;
    }

    _revision++;

    return true;
  }

  /// Where the sheet stands: how many class rules and how many state rules it holds.
  ///
  /// A renderer that writes a page and then adds to it keeps the mark of what it wrote, so the
  /// next write is only the rules that came after it.
  ({int classes, int states}) get mark =>
      (classes: _classOrder.length, states: _states.length);

  /// The rules added after [mark], as the text a page is given.
  ///
  /// A rule that declares nothing is not a rule: it is skipped here as it is in `css`, so a
  /// class with no declarations costs no bytes however many nodes wear it.
  List<String> rulesSince(({int classes, int states}) mark) {
    final List<String> rules = <String>[];

    for (int i = mark.classes; i < _classOrder.length; i++) {
      final String className = _classOrder[i];
      final CssDeclarations declarations = _rules[className]!;

      if (declarations.isEmpty) {
        continue;
      }

      rules.add('.$className{${declarations.text}}');
    }

    for (int i = mark.states; i < _states.length; i++) {
      final CssRule rule = _states[i];

      if (rule.declarations.isEmpty) {
        continue;
      }

      final String body = '${rule.selector}{${rule.declarations.text}}';
      final String? media = rule.media;
      final String? container = rule.container;

      if (media != null) {
        rules.add('@media $media{$body}');
        continue;
      }

      rules.add(container == null ? body : '@container $container{$body}');
    }

    return rules;
  }

  /// Every rule, as the body of one `<style>` element.
  ///
  /// The looks first, then the states, so a state rule can override a resting one. A
  /// hover rule is wrapped in its media condition, because a phone that reported a hover
  /// would otherwise be stuck in it after a tap.
  String get css {
    final StringBuffer buffer = StringBuffer();

    for (final String rule in rulesSince((classes: 0, states: 0))) {
      buffer.writeln(rule);
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
  final CssDeclarations root = rootDeclarations();

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
