import 'package:unibox_core/unibox_core.dart' as core;

import 'box.dart';
import 'declarations.dart';

/// One CSS rule: a selector, what it declares, and the media condition it lives under.
///
/// A rule is a value here and not an element or a component, so the same rule can be
/// written into a `<style>` block by a string renderer and into a stylesheet by a DOM
/// one, and both spellings come from this file.
final class CssRule {
  /// Creates a rule.
  const CssRule({
    required this.selector,
    required this.declarations,
    this.media,
  });

  /// The selector, class and pseudo class included: `.unibox-box-1f3c9a7b:hover`.
  final String selector;

  /// What the rule declares.
  final CssDeclarations declarations;

  /// The media condition the rule lives under, or `null` for a rule that always
  /// applies. Written as a condition, without the `@media` keyword.
  final String? media;

  @override
  String toString() => media == null
      ? '$selector { ${declarations.text} }'
      : '@media $media { $selector { ${declarations.text} } }';
}

/// The media condition a hover rule lives under.
///
/// Hover is wrapped in `@media (hover: hover)` so a touch screen cannot get stuck in a
/// hovered look after a tap: a phone reports a hover only if its pointer can hover.
const String hoverCapableMediaQuery = '(hover: hover)';

/// The pseudo class a state is matched by, or the attribute the element carries.
///
/// `focus` maps to `:focus-visible` rather than `:focus`, so a pointer press never
/// paints a focus ring; `disabled` matches the `aria-disabled` attribute the element
/// already carries, so the visual and the announced state can never disagree.
String cssStateSelector(core.BoxState state) => switch (state) {
  core.BoxState.hover => ':hover',
  core.BoxState.focus => ':focus-visible',
  core.BoxState.pressed => ':active',
  core.BoxState.disabled => '[aria-disabled="true"]',
};

/// The state rules of [box], in cascade order.
///
/// Each one declares only what its state states — the `declaredOnly` rule of
/// [boxDeclarations] — so a hover rule cannot reset the layout of the resting one, and
/// a transition stays on the resting rule where the change is declared.
List<CssRule> stateRules(core.Box box, String className) {
  final List<CssRule> rules = <CssRule>[];

  for (final core.BoxState state in <core.BoxState>[
    core.BoxState.hover,
    core.BoxState.focus,
    core.BoxState.pressed,
    core.BoxState.disabled,
  ]) {
    final core.BoxStyle? style = box.stateStyle(state);

    if (style == null) {
      continue;
    }

    rules.add(
      CssRule(
        selector: '.$className${cssStateSelector(state)}',
        media: state == core.BoxState.hover ? hoverCapableMediaQuery : null,
        declarations: boxDeclarations(style, declaredOnly: true),
      ),
    );
  }

  return rules;
}
