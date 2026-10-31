import 'package:unibox_core/unibox_core.dart' as core;

import 'box.dart';
import 'values.dart';
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
    this.container,
  });

  /// The selector, class and pseudo class included: `.unibox-box-1f3c9a7b:hover`.
  final String selector;

  /// What the rule declares.
  final CssDeclarations declarations;

  /// The media condition the rule lives under, or `null` for a rule that always
  /// applies. Written as a condition, without the `@media` keyword.
  final String? media;

  /// The container condition the rule lives under, or `null`.
  ///
  /// A container query asks about the box that holds the element rather than about the
  /// window, which is the only question a component can answer: a card in a narrow column
  /// is narrow whatever the window is.
  final String? container;

  @override
  String toString() => media == null
      ? '$selector { ${declarations.text} }'
      : '@media $media { $selector { ${declarations.text} } }';
}

/// One `@keyframes` block: the two frames it stands for, and the name an animation calls it by.
///
/// A class is a hash of the declarations it wears, which is what makes six listings one rule.
/// Keyframes cannot work that way — they are not worn, they are called by name from an
/// `animation-name` declaration — so the name is a hash of the frames instead: the same fold
/// asked for twice is one block, and a look that comes back after being forgotten comes back
/// under the name it had.
final class CssKeyframes {
  /// Creates a block from [from] to [to].
  ///
  /// [kind] only names the block (`unibox-fold-…`), so a page says what an at-rule is for.
  const CssKeyframes({
    required this.from,
    required this.to,
    this.kind = 'fold',
  });

  /// The declarations at the start of the travel.
  final CssDeclarations from;

  /// The declarations at the end of it.
  final CssDeclarations to;

  /// What the block is for, which is the prefix of [name].
  final String kind;

  /// The text of the frames, which is what [name] is a hash of.
  String get body => 'from{${from.text}}to{${to.text}}';

  /// The name an `animation-name` declaration reaches this block by.
  String get name => classNameFor(kind, body);

  @override
  String toString() => '@keyframes $name{$body}';
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

/// The rules that draw a box at only some widths.
///
/// A wide-only box is hidden in its own rule and brought back here; a narrow-only one is
/// drawn by its rule and taken away here. Both ask about the *container* rather than the
/// window, and they resolve against the nearest box that declares `container-type:
/// inline-size` — the parent — so the width is the one the box is drawn in.
///
/// `from` is the width the box starts being drawn at, `until` the width it stops at: the two
/// together are a band, and either alone is a floor or a ceiling.
/// The rules that make a pager's children the stops it settles on.
///
/// `scroll-snap-align` belongs to the child, and the parent's class is the only thing this
/// renderer can select it by: the children of a pager are the tree's own children, in the
/// order the box lays them out, so `> *` names exactly the pages.
///
/// `flex-shrink: 0` is the other half, and it is what makes a page a page: a flex item shrinks to
/// fit by default, so three pages of 120 pixels inside a box of 120 shrank to a third each and the
/// box had nothing to scroll — a pager with three pages and one page of width. A child of a pager
/// is the size the tree says it is.
List<CssRule> snapRules(String className, core.BoxStyle style) {
  if (style.snap != core.ScrollSnap.page) {
    return const <CssRule>[];
  }

  return <CssRule>[
    CssRule(
      selector: '.$className > *',
      declarations: CssDeclarations()
        ..add('scroll-snap-align', 'start')
        ..add('flex-shrink', '0'),
    ),
  ];
}

List<CssRule> thresholdRules(
  String className, {
  required double? from,
  required double? until,
}) {
  final List<CssRule> rules = <CssRule>[];

  if (from != null) {
    // Drawn from here up, which is what the hidden resting rule left to do.
    rules.add(
      CssRule(
        selector: '.$className',
        container: '(min-width: ${cssPixels(from)})',
        declarations: CssDeclarations()..add('display', 'flex'),
      ),
    );
  }

  if (until != null) {
    rules.add(
      CssRule(
        selector: '.$className',
        container: '(min-width: ${cssPixels(until)})',
        declarations: CssDeclarations()..add('display', 'none'),
      ),
    );
  }

  return rules;
}

/// The declarations of a box that measures its own width, so a child can ask.
CssDeclarations containerDeclarations() =>
    CssDeclarations()..add('container-type', 'inline-size');
