import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:universal_web/web.dart' as web;

import 'labels.dart';
import 'render.dart';
import 'press_position.dart';
import 'stylesheet.dart';
import 'values.dart';

/// Delay after which a pressed box counts as a long press.
const Duration _longPressDuration = Duration(milliseconds: 500);

/// Renders a [core.Box] as a styled `<div>`.
///
/// A box is a CSS flex container whose `flex-direction`, `justify-content`,
/// `align-items` and `gap` mirror the `Row`/`Column` the same node renders to in
/// Flutter; a box without a direction is a column. Everything else is plain CSS:
/// `width`, `height`, `padding`, `border`, `border-radius`, `box-shadow`,
/// `overflow` and friends.
///
/// The styles of a state cannot be expressed with inline styles, since those
/// always win over a pseudo class. A box with state styles is therefore rendered
/// as a scoped `.<class>` rule plus one rule per state, emitted next to the
/// `<div>`: `:hover` inside `@media (hover: hover)`, `:focus-visible`, `:active`
/// and `[aria-disabled="true"]`. The class name is derived from the resolved
/// styles, which keeps the output deterministic and therefore identical for
/// server side rendering and client side hydration.
///
/// The semantics of the box become attributes: `role`, `aria-label`,
/// `aria-checked`, `aria-disabled` and `tabindex`, which is what makes a hand
/// drawn control a real control on the web.
class JasprBox extends StatelessComponent {
  /// Creates a renderer for [box].
  const JasprBox({required this.box, super.key});

  /// The node being rendered.
  final core.Box box;

  @override
  Component build(BuildContext context) {
    final List<Component> children = box.children
        .map(renderNode)
        .toList(growable: false);
    final Map<String, String> attributes = withNodeAttributes(
      box,
      _attributes(),
    );

    final Map<String, EventCallback>? events = _events();
    final core.BoxElement element =
        box.semantics?.element ?? core.BoxElement.div;
    final core.BoxStyle style = box.computedStyle;
    // A painted leaf takes no press: it has nothing to press, and letting it be the
    // target would put a decoration in front of the control it was drawn for. See
    // [toBoxStyles].
    final bool capturesPointer =
        box.children.isNotEmpty ||
        events != null ||
        box.stateStyle(core.BoxState.hover) != null ||
        box.stateStyle(core.BoxState.pressed) != null;
    Styles restingStyles = toBoxStyles(
      style,
      interactive: box.isInteractive,
      capturesPointer: capturesPointer,
      element: element,
    );
    // Mobile first: a box that only appears above a threshold starts hidden and the
    // container query below brings it back, so a browser without container queries
    // renders the narrow layout rather than a broken wide one.
    if (style.visibleFrom != null) {
      restingStyles = restingStyles.combine(Styles(display: Display.none));
    }
    // A box that holds a threshold is the box that threshold measures.
    if (_holdsThreshold) {
      restingStyles = restingStyles.combine(
        Styles(raw: <String, String>{'container-type': 'inline-size'}),
      );
    }
    final UniboxStylesheet? sheet = UniboxStylesheetScope.of(context);

    // Inside a rendering every look becomes a class, so six listings with one look
    // declare it once and no element carries an inline style a host cannot
    // override.
    if (sheet != null) {
      final String className = sheet.classFor(
        'box',
        _declarationsKey(restingStyles),
        (String name) => <StyleRule>[
          StyleRule(selector: Selector.className(name), styles: restingStyles),
          ..._stateRules(name),
          ..._thresholdRules(name, style: style),
        ],
      );

      return _element(
        element,
        children,
        classes: className,
        attributes: attributes,
        events: events,
      );
    }

    // A box rendered on its own has no sheet to register in.
    if (!_hasStateStyles && _thresholdRules('x', style: style).isEmpty) {
      return _element(
        element,
        children,
        styles: restingStyles,
        attributes: attributes,
        events: events,
      );
    }

    final String className =
        'unibox-box-${fnv1a(declarationsOf(restingStyles))}';

    return Component.fragment(<Component>[
      Style(
        styles: <StyleRule>[
          StyleRule(
            selector: Selector.className(className),
            styles: restingStyles,
          ),
          ..._stateRules(className),
          ..._thresholdRules(className, style: box.computedStyle),
        ],
      ),
      _element(
        element,
        children,
        classes: className,
        attributes: attributes,
        events: events,
      ),
    ]);
  }

  /// Everything the box paints, as text: the key a class is deduplicated on.
  ///
  /// Both the resting look and every state the box styles are part of it, so two
  /// boxes only share a class when they render identically in every state.
  String _declarationsKey(Styles resting) {
    final StringBuffer seed = StringBuffer(declarationsOf(resting));

    for (final core.BoxState state in core.BoxState.values) {
      final Styles? styles = _stateStyles(state);

      if (styles != null) {
        seed.write('|${state.name}:${declarationsOf(styles)}');
      }
    }

    return seed.toString();
  }

  /// Whether the box styles any interaction state at all.
  bool get _hasStateStyles => core.BoxState.values.any(
    (core.BoxState state) => box.stateStyle(state) != null,
  );

  /// Whether a child of this box declares a width threshold, which makes this box
  /// the box that threshold measures.
  bool get _holdsThreshold => box.children.any(
    (core.UINode child) =>
        child is core.Box && !child.computedStyle.isVisibleEverywhere,
  );

  /// The container queries that draw the box at only some widths.
  ///
  /// A wide-only box is hidden in its own rule and brought back here; a
  /// narrow-only one is drawn by its rule and taken away here. Both blocks are
  /// resolved against the nearest box that declares `container-type: inline-size`
  /// — the parent — so the width is the one the box is drawn in, not the window's.
  List<StyleRule> _thresholdRules(
    String className, {
    required core.BoxStyle style,
  }) {
    final Selector selector = Selector.className(className);
    final double? from = style.visibleFrom;
    final double? until = style.visibleUntil;
    final List<StyleRule> rules = <StyleRule>[];

    if (from != null) {
      rules.add(
        ContainerStyleRule(
          minWidth: from,
          selector: selector,
          // What the box's own rule said before it was hidden.
          styles: Styles(display: Display.flex),
        ),
      );
    }

    if (until != null) {
      rules.add(
        ContainerStyleRule(
          minWidth: until,
          selector: selector,
          styles: Styles(display: Display.none),
        ),
      );
    }

    return rules;
  }

  /// The pseudo class rules of the box, in cascade order.
  ///
  /// Hover is wrapped in `@media (hover: hover)` so a touch screen cannot get
  /// stuck in a hovered look, focus uses `:focus-visible` so a pointer click
  /// never paints a focus ring, and the disabled rule matches the
  /// `aria-disabled` attribute the element already carries, so the visual and
  /// the announced state can never disagree.
  List<StyleRule> _stateRules(String className) {
    final List<StyleRule> rules = <StyleRule>[];

    final Styles? hover = _stateStyles(core.BoxState.hover);
    if (hover != null) {
      rules.add(
        StyleRule.media(
          query: MediaQuery.all(canHover: true),
          styles: <StyleRule>[
            StyleRule(selector: Selector('.$className:hover'), styles: hover),
          ],
        ),
      );
    }

    final Styles? focus = _stateStyles(core.BoxState.focus);
    if (focus != null) {
      rules.add(
        StyleRule(
          selector: Selector('.$className:focus-visible'),
          styles: focus,
        ),
      );
    }

    final Styles? pressed = _stateStyles(core.BoxState.pressed);
    if (pressed != null) {
      rules.add(
        StyleRule(selector: Selector('.$className:active'), styles: pressed),
      );
    }

    final Styles? disabled = _stateStyles(core.BoxState.disabled);
    if (disabled != null) {
      rules.add(
        StyleRule(
          selector: Selector('.$className[aria-disabled="true"]'),
          styles: disabled,
        ),
      );
    }

    return rules;
  }

  /// The CSS of [state], or `null` when the box styles nothing for it.
  ///
  /// Only the tokens of the state are emitted, so the browser layers them over
  /// the resting rule exactly like the Flutter renderer layers them over the
  /// resting style. That includes the flex layout: the resting rule already
  /// decided it, and a state rule that restated it would move the content.
  Styles? _stateStyles(core.BoxState state) {
    final core.BoxStyle? style = box.stateStyle(state);
    return style == null ? null : toBoxStyles(style, declaredOnly: true);
  }

  /// The accessibility attributes of the box, or `null` when it needs none.
  ///
  /// The element already announces what it is, so `role` is only written when the
  /// box asks for a role its element does not imply: `<nav>` is a navigation
  /// landmark without a `role="navigation"` next to it, and `role="link"` on a
  /// `<div>` is the only way to say what that div means.
  Map<String, String>? _attributes() {
    final core.BoxSemantics? semantics = box.semantics;
    final core.BoxRole role = semantics?.role ?? core.BoxRole.none;
    final core.BoxElement element = semantics?.element ?? core.BoxElement.div;
    final Map<String, String> attributes = <String, String>{};
    final String? htmlRole = _htmlRole(role);
    final String? label = semantics?.label;
    final bool? checked = semantics?.checked;
    final bool isCheckable =
        role == core.BoxRole.checkbox || role == core.BoxRole.switch_;

    if (htmlRole != null && htmlRole != _impliedRole(element)) {
      attributes['role'] = htmlRole;
    }
    if (label != null) {
      attributes['aria-label'] = label;
    }
    if (isCheckable && checked != null) {
      attributes['aria-checked'] = '$checked';
    }
    if (!box.enabled) {
      attributes['aria-disabled'] = 'true';
    }
    if (box.isFocusable && box.enabled) {
      attributes['tabindex'] = '0';
    }

    final bool? expanded = semantics?.expanded;
    final bool? selected = semantics?.selected;

    if (expanded != null) {
      attributes['aria-expanded'] = '$expanded';
    }
    if (selected != null) {
      attributes['aria-selected'] = '$selected';
    }
    // A hidden box keeps its look and leaves the accessibility tree, and it is
    // never focusable, so it cannot be a focusable element with aria-hidden.
    if (semantics?.hidden ?? false) {
      attributes['aria-hidden'] = 'true';
    }
    if (semantics?.liveRegion ?? false) {
      attributes['aria-live'] = 'polite';
    }

    final core.BoxCurrent? current = semantics?.current;
    if (current != null) {
      // Which kind of current this is, not just that it is current: a nav item
      // announces "current page", a step of a flow something else.
      attributes['aria-current'] = current.name;
    }

    return attributes.isEmpty ? null : attributes;
  }

  /// The DOM listeners of the box, or `null` when it reacts to nothing.
  ///
  /// A disabled box listens to nothing at all, and a box whose role makes it
  /// focusable also activates on Enter and Space, which is what a native button
  /// does.
  Map<String, EventCallback>? _events() {
    if (!box.enabled) {
      return null;
    }

    final Map<String, EventCallback> events = _buildEvents(box);
    final core.TapCallback? onTap = box.onTap;

    if (onTap != null && box.isFocusable) {
      var activated = false;

      events['keydown'] = (web.Event event) {
        final web.KeyboardEvent keyEvent = event as web.KeyboardEvent;

        if (activated || !_isActivationKey(keyEvent.key)) {
          return;
        }

        // Space would otherwise scroll the page instead of pressing the box.
        keyEvent.preventDefault();
        activated = true;
        onTap();
      };
      events['keyup'] = (web.Event event) {
        final web.KeyboardEvent keyEvent = event as web.KeyboardEvent;

        if (_isActivationKey(keyEvent.key)) {
          activated = false;
        }
      };
    }

    return events.isEmpty ? null : events;
  }
}

/// Where a press landed inside the box that listens, in the box's own pixels.
///
/// Measured from the box, not from the element the pointer hit: `offsetX` and
/// `offsetY` are relative to the hit target, and a press on a label is reported in
/// the label's frame — which put an ink drop somewhere else entirely, or nowhere at
/// all once the drop was clipped to the well around it. These are the four numbers
/// the browser can give, so this is the arithmetic on its own, away from the DOM.
core.BoxPoint pressPointInside({
  required double clientX,
  required double clientY,
  required double originX,
  required double originY,
}) => core.BoxPoint(clientX - originX, clientY - originY);

/// Maps the interaction callbacks of [box] to DOM event listeners.
///
/// The listeners are omitted entirely for a non interactive box, so a static
/// tree renders without any JavaScript.
Map<String, EventCallback> _buildEvents(core.Box box) {
  final core.TapCallback? onTap = box.onTap;
  final core.TapDownCallback? onTapDown = box.onTapDown;
  final core.HoverCallback? onHover = box.onHover;
  final core.LongPressCallback? onLongPress = box.onLongPress;
  final Map<String, EventCallback> events = <String, EventCallback>{};

  if (onTap == null &&
      onTapDown == null &&
      onHover == null &&
      onLongPress == null) {
    return events;
  }

  // The press is reported in the frame Flutter calls `localPosition`; see
  // [pressPointInside] for why the offsets the event carries are not that frame.
  // `pointerType` names the device. The listener only runs once the client runtime
  // does.
  if (onTapDown != null) {
    events['pointerdown'] = (web.Event event) {
      final web.PointerEvent pointer = event as web.PointerEvent;

      onTapDown(
        core.BoxTapEvent(
          position: pressPositionOf(event) ?? const core.BoxPoint(0, 0),
          pointer: _pointerKind(pointer.pointerType),
        ),
      );
    };
  }

  var longPressed = false;
  Timer? pressTimer;

  void cancelPress() {
    pressTimer?.cancel();
    pressTimer = null;
  }

  if (onTap != null) {
    events['click'] = (event) {
      if (longPressed) {
        longPressed = false;
        return;
      }
      onTap();
    };
  }

  if (onHover != null) {
    events['mouseenter'] = (event) => onHover(true);
    events['mouseleave'] = (event) => onHover(false);
  }

  if (onLongPress != null) {
    events['pointerdown'] = (event) {
      cancelPress();
      pressTimer = Timer(_longPressDuration, () {
        pressTimer = null;
        longPressed = true;
        onLongPress();
      });
    };
    events['pointerup'] = (event) => cancelPress();
    events['pointerleave'] = (event) => cancelPress();
    events['pointercancel'] = (event) => cancelPress();
  }

  return events;
}

/// Builds the element [element] of a box, or a `<div>` when it is a plain one.
///
/// Everything the box needs — styles, classes, attributes and listeners — goes on
/// that one element, so the semantic element is the box and not a wrapper around
/// it: `<main>` *is* the page box.
Component _element(
  core.BoxElement element,
  List<Component> children, {
  String? classes,
  Styles? styles,
  Map<String, String>? attributes,
  Map<String, EventCallback>? events,
}) {
  if (element == core.BoxElement.div) {
    return div(
      children,
      classes: classes,
      styles: styles,
      attributes: attributes,
      events: events,
    );
  }

  return Component.element(
    tag: element.name,
    classes: classes,
    styles: styles,
    attributes: attributes,
    events: events,
    children: children,
  );
}

/// The ARIA role [element] already implies, or `null` when it implies none.
///
/// These are the implicit roles of the HTML elements the model has, which is what
/// lets the renderer skip a `role` attribute that would only repeat the tag.
String? _impliedRole(core.BoxElement element) {
  return switch (element) {
    core.BoxElement.main => 'main',
    core.BoxElement.nav => 'navigation',
    core.BoxElement.header => 'banner',
    core.BoxElement.footer => 'contentinfo',
    core.BoxElement.aside => 'complementary',
    core.BoxElement.section => 'region',
    core.BoxElement.article => 'article',
    core.BoxElement.form => 'form',
    core.BoxElement.figure => 'figure',
    core.BoxElement.ul || core.BoxElement.ol => 'list',
    core.BoxElement.li => 'listitem',
    // A caption names the figure it belongs to; no role says that, the tag does.
    core.BoxElement.figcaption => null,
    core.BoxElement.div => null,
  };
}

/// The ARIA role of [role], or `null` for a plain container.
String? _htmlRole(core.BoxRole role) {
  return switch (role) {
    core.BoxRole.none => null,
    core.BoxRole.button => 'button',
    core.BoxRole.checkbox => 'checkbox',
    core.BoxRole.switch_ => 'switch',
    core.BoxRole.link => 'link',
    core.BoxRole.heading => 'heading',
  };
}

/// Whether [key] is a key that activates a control.
bool _isActivationKey(String key) => key == 'Enter' || key == ' ';

/// Flattens [styles] into a stable `property:value;` string.

/// Converts a DOM `pointerType` to the portable kind.
///
/// The browser names three devices and leaves the rest to the platform, so anything
/// it does not know is reported as unknown rather than guessed.
core.BoxPointerKind _pointerKind(String pointerType) {
  return switch (pointerType) {
    'touch' => core.BoxPointerKind.touch,
    'mouse' => core.BoxPointerKind.mouse,
    'pen' => core.BoxPointerKind.pen,
    _ => core.BoxPointerKind.unknown,
  };
}
