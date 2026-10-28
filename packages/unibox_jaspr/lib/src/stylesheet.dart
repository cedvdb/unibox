import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;
import 'package:unibox_core/unibox_core.dart' as core;

import 'values.dart';

/// The classes one rendering needs: one per distinct set of declarations.
///
/// A tree repeats itself — six listings with the same look, a label that appears
/// twice — and writing the same declarations on every element costs more than
/// bytes: an inline `style` beats every rule a host could write, so a page that
/// carried one per element could not be themed with a CSS custom property, a
/// `@media (prefers-color-scheme: dark)` block, or a stylesheet of its own.
///
/// So the renderer collects declarations here instead: the first element that
/// asks for a set registers a class for it, every element with the same set gets
/// the same class name back, and [rules] holds each rule once. Output then grows
/// with the number of *distinct* looks on a page rather than with the number of
/// elements.
///
/// The sheet belongs to one call of `renderJaspr` and travels down the tree in a
/// `UniboxStylesheetScope`, so two pages rendered in one process cannot share a
/// class by accident.
final class UniboxStylesheet {
  /// Creates an empty sheet.
  UniboxStylesheet();

  /// The class name of every declarations key seen so far.
  final Map<String, String> _classNames = <String, String>{};

  /// The rules, in the order their classes were first asked for.
  final List<StyleRule> _rules = <StyleRule>[];

  /// Where rules registered after the sheet was written out are sent.
  void Function(String css)? _sink;

  /// The class for [declarations], built by [rules] the first time it is asked
  /// for.
  ///
  /// [kind] only names the class (`unibox-box-…`, `unibox-text-…`) so the output
  /// says what an element is; the deduplication is [declarations]'s.
  String classFor(
    String kind,
    String declarations,
    List<StyleRule> Function(String className) rules,
  ) {
    final String key = '$kind|$declarations';
    final String? existing = _classNames[key];

    if (existing != null) {
      return existing;
    }

    final String className = 'unibox-$kind-${fnv1a(key)}';
    _classNames[key] = className;
    final List<StyleRule> added = rules(className);
    _rules.addAll(added);
    // A browser has already written the sheet into the document and redraws one
    // subtree at a time, so a look registered later has to reach the page by
    // itself; a server renders the whole sheet as text and never needs a sink.
    _sink?.call(added.map((StyleRule rule) => rule.toCss()).join('\n'));

    return className;
  }

  /// Sends every rule registered from now on to [sink] as well as into [rules].
  ///
  /// `JasprStylesheet` installs it in a browser, where the sheet is an element in
  /// the document rather than text in the response.
  void attachSink(void Function(String css) sink) => _sink = sink;

  /// Every rule this rendering needs, each one once.
  List<StyleRule> get rules => List<StyleRule>.unmodifiable(_rules);

  /// How many distinct looks the rendering has, which is its CSS cost.
  int get classCount => _classNames.length;
}

/// The declarations of [styles] as text, sorted so the same look always keys the
/// same class.
String declarationsOf(Styles styles) {
  final List<MapEntry<String, String>> entries =
      styles.properties.entries.toList(growable: false)..sort(
        (MapEntry<String, String> a, MapEntry<String, String> b) =>
            a.key.compareTo(b.key),
      );

  return entries
      .map((MapEntry<String, String> entry) => '${entry.key}:${entry.value}')
      .join(';');
}

/// A stable eight character hash of [value] (FNV-1a).
///
/// Tiny, deterministic and dependency free, so a class name is the same on the
/// server and on the client without any coordination.
String fnv1a(String value) {
  var hash = 0x811C9DC5;

  for (final int codeUnit in value.codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0xFFFFFFFF;
  }

  return hash.toRadixString(16).padLeft(8, '0');
}

/// Writes [UniboxStylesheet.rules] as the single `<style>` of a rendering.
///
/// It is placed after the tree so it can be built once every component has
/// registered its class; CSS applies to the whole document wherever the element
/// sits.
class JasprStylesheet extends StatelessComponent {
  /// Creates the stylesheet element of [sheet].
  const JasprStylesheet({required this.sheet, this.theme, super.key});

  /// The sheet to write out.
  final UniboxStylesheet sheet;

  /// The theme whose roles the rules point at, if the tree was given one.
  final core.UniboxTheme? theme;

  /// The id of the element a browser keeps the sheet in.
  static const String elementId = 'unibox-styles';

  @override
  Component build(BuildContext context) {
    final core.UniboxTheme? declared = theme;
    final List<StyleRule> rules = declared == null || declared.isEmpty
        ? sheet.rules
        // The theme once, in `:root`, whether or not a node names each role: a host
        // stylesheet or an embed has to be able to read a role the tree happens to
        // leave alone, and a `:root` block that changed with the tree would be a
        // different document every time the content did.
        : <StyleRule>[
            StyleRule(
              selector: const Selector(':root'),
              styles: Styles(
                raw: <String, String>{
                  for (final MapEntry<String, core.BoxColor> entry
                      in declared.variables.entries)
                    entry.key: toCssColor(entry.value).value,
                },
              ),
            ),
            ...sheet.rules,
          ];

    // A browser draws the sheet into the document head and keeps it there: a
    // state change redraws one subtree, and the class that subtree registers has
    // to reach the page without a second render of the whole document. A server
    // writes the `<style>` into the tree instead, which is the sheet a page
    // without JavaScript keeps.
    if (kIsWeb) {
      final web.HTMLStyleElement element = _styleElement();
      element.textContent = rules
          .map((StyleRule rule) => rule.toCss())
          .join('\n');
      sheet.attachSink((String css) {
        element.textContent = '${element.textContent ?? ''}\n$css';
      });

      return Component.fragment(const <Component>[]);
    }

    return Style(styles: rules);
  }

  /// The `<style>` of this document, created on first use.
  static web.HTMLStyleElement _styleElement() {
    final web.Element? existing = web.document.getElementById(elementId);

    if (existing != null) {
      return existing as web.HTMLStyleElement;
    }

    final web.HTMLStyleElement element = web.HTMLStyleElement()..id = elementId;
    web.document.head?.appendChild(element);

    return element;
  }
}

/// One `@container` block: the declarations a selector takes at a width.
///
/// A width is measured on the *layout box*, not on the window: the box that holds a
/// threshold declares `container-type: inline-size`, and a rule like this one is
/// resolved against the nearest such ancestor. That is the same box Flutter measures
/// with its constraints, which is what keeps the two renderings equal inside a panel
/// as well as on a full page.
class ContainerStyleRule implements StyleRule {
  /// Creates a rule for [selector] that applies from [minWidth] up.
  const ContainerStyleRule({
    required this.minWidth,
    required this.selector,
    required this.styles,
  });

  /// The narrowest width, in logical pixels, the block applies at.
  final double minWidth;

  /// The selector the declarations belong to.
  final Selector selector;

  /// The declarations.
  final Styles styles;

  @override
  String toCss([String indent = '']) {
    final String width = minWidth == minWidth.roundToDouble()
        ? '${minWidth.toInt()}px'
        : '${minWidth}px';

    return '$indent@container (min-width: $width) {'
        '\n${StyleRule(selector: selector, styles: styles).toCss('$indent  ')}\n'
        '$indent}';
  }
}

/// Hands the theme of a rendering to the components inside it.
///
/// `renderJaspr` installs it from its `theme` argument; a host that composes the
/// components itself — a page whose root is a `JasprStateful`, say — installs it
/// around its tree instead, and the stylesheet still writes the `:root` block.
class JasprThemeScope extends InheritedComponent {
  /// Creates the scope around [child].
  const JasprThemeScope({required this.theme, required super.child, super.key});

  /// The values the roles of the tree stand for.
  final core.UniboxTheme theme;

  /// The theme in scope, or `null` when there is none.
  static core.UniboxTheme? of(BuildContext context) =>
      context.dependOnInheritedComponentOfExactType<JasprThemeScope>()?.theme;

  @override
  bool updateShouldNotify(JasprThemeScope oldComponent) =>
      oldComponent.theme != theme;
}

/// Wraps [child] in a sheet of its own when the rendering has none in scope.
///
/// `renderJaspr` opens a sheet around the tree it renders, but a host may begin
/// somewhere else — `JasprStateful` is a component a page can use directly, and it
/// draws the node itself. Whichever component starts a tree calls this, so the
/// looks are written once and no element carries an inline style either way.
Component withStylesheet(BuildContext context, Component child) {
  if (UniboxStylesheetScope.of(context) != null) {
    return child;
  }

  final UniboxStylesheet sheet = UniboxStylesheet();
  final core.UniboxTheme? theme = JasprThemeScope.of(context);

  return Component.fragment(<Component>[
    UniboxStylesheetScope(sheet: sheet, child: child),
    JasprStylesheet(sheet: sheet, theme: theme),
  ]);
}

/// Hands the sheet of the rendering in progress to every component below it.
///
/// A component built on its own — `JasprBox(box: box)` in a test, or a host
/// rendering one node — finds no scope and writes its declarations inline, which
/// is what it did before the sheet existed.
class UniboxStylesheetScope extends InheritedComponent {
  /// Creates the scope around [child].
  const UniboxStylesheetScope({
    required this.sheet,
    required super.child,
    super.key,
  });

  /// The sheet to register classes in.
  final UniboxStylesheet sheet;

  /// The sheet in scope, or `null` when there is none.
  static UniboxStylesheet? of(BuildContext context) => context
      .dependOnInheritedComponentOfExactType<UniboxStylesheetScope>()
      ?.sheet;

  @override
  bool updateShouldNotify(UniboxStylesheetScope oldComponent) =>
      oldComponent.sheet != sheet;
}
