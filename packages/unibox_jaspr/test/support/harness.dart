import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_jaspr/unibox_jaspr.dart';

/// Renders [node] as the root component of the current test tree.
void pumpNode(
  ComponentTester tester,
  core.UINode node, {
  core.UniboxTheme? theme,
}) {
  tester.pumpComponent(renderJaspr(node, theme: theme));
}

/// Resolves the DOM element rendered for the component matched by [finder].
///
/// [finder] must match exactly one component; narrow ambiguous finders with
/// `find.tag('div').first` or similar.
TestRenderElement elementOf(Finder finder) => elementsOf(finder).single;

/// Every DOM element rendered for [finder], in document order.
List<TestRenderElement> elementsOf(Finder finder) => <TestRenderElement>[
  for (final Element match in finder.evaluate()) _domElementOf(match),
];

/// The DOM element a component renders, skipping the components that have none of
/// their own — a `Component.fragment` or a stateless component builds its element
/// further down.
TestRenderElement _domElementOf(Element match) {
  DomElement? domElement;

  void visit(Element element) {
    if (domElement != null) {
      return;
    }
    if (element is DomElement) {
      domElement = element;
      return;
    }
    element.visitChildren(visit);
  }

  visit(match);
  return domElement!.renderObject as TestRenderElement;
}

/// The declarations that apply to the element matched by [finder].
///
/// The renderer writes a look once, as a class rule, and puts only the class on
/// the element — so a test reads the class's declarations and then the element's
/// own inline ones on top, which is the order a browser applies them in.
Map<String, String> stylesOf(Finder finder) {
  final TestRenderElement element = elementOf(finder);
  final Map<String, String> declarations = <String, String>{};

  for (final String name in classNamesOf(finder)) {
    declarations.addAll(declarationsOf('.$name'));
  }

  declarations.addAll(element.styles ?? const <String, String>{});

  return declarations;
}

/// The raw CSS rendered by the `<style>` element matched by [finder].
String cssOf(Finder finder) => _cssText(elementOf(finder));

/// The text of a rendered `<style>` element.
String _cssText(TestRenderElement element) => element.children
    .whereType<TestRenderText>()
    .map((TestRenderText child) => child.text)
    .join();

/// The text inside the element matched by [finder].
///
/// A `<style>` and a `<script>` carry their body as text and not as children, so a
/// test that reads one reads its text.
String textOf(Finder finder) => _cssText(elementOf(finder));

/// Every style rule the rendered component carries, in document order.
///
/// The renderer emits a `<style>` element for the typography of the model and one
/// for the classes of the tree, so a test that asks "is this rule there?" has to
/// look at all of them instead of at the first one it finds.
String allCss() => elementsOf(find.tag('style')).map(_cssText).join('\n');

/// The declarations of the rule with [selector].
///
/// Every rule the renderer writes is a single selector followed by a flat block of
/// declarations, so splitting on `;` and `:` reads it without a CSS parser. Throws
/// when no rule matches, which is the direction a rule that stopped being emitted
/// should fail in.
Map<String, String> declarationsOf(String selector) {
  final String css = allCss();
  final Map<String, String> declarations = <String, String>{};
  int from = 0;
  int found = 0;

  // A selector may own more than one block — the typography of the model and the
  // variables of the theme both live in `:root` — and a browser merges them, so a
  // test reading the declarations of a selector merges them too.
  while (true) {
    final int start = css.indexOf('$selector {', from);

    if (start == -1) {
      break;
    }

    found++;
    final int end = css.indexOf('}', start);

    for (final String declaration
        in css.substring(start + selector.length + 2, end).split(';')) {
      final int colon = declaration.indexOf(':');

      if (colon == -1) {
        continue;
      }

      declarations[declaration.substring(0, colon).trim()] = declaration
          .substring(colon + 1)
          .trim();
    }

    from = end;
  }

  if (found == 0) {
    throw StateError('No rule for $selector in:\n$css');
  }

  return declarations;
}

/// The `class` attribute of the element matched by [finder].
String? classesOf(Finder finder) => elementOf(finder).classes;

/// The single class names of the element matched by [finder].
List<String> classNamesOf(Finder finder) => (classesOf(finder) ?? '')
    .split(RegExp(r'\s+'))
    .where((String name) => name.isNotEmpty)
    .toList(growable: false);

/// The HTML attributes of the element matched by [finder].
Map<String, String> attributesOf(Finder finder) {
  return elementOf(finder).attributes ?? const <String, String>{};
}
