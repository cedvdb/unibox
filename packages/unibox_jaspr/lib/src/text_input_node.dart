import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:universal_web/web.dart' as web;

import 'labels.dart';
import 'stylesheet.dart';
import 'values.dart';

/// Renders a [core.TextInputNode] as an `<input>` or a `<textarea>`.
///
/// A single line input becomes `<input type="text">`, an obscured one becomes
/// `<input type="password">`, and a multiline one becomes a `<textarea>` whose
/// `rows` start at [core.TextInputNode.maxLines].
///
/// The node also drives the browser behaviour of the field: [core.InputType]
/// becomes the `type` attribute, which gives a touch device the right keyboard
/// and the browser its validation hints, and the enabled, read only and autofocus
/// flags become the matching attributes.
///
/// A [core.TextInputNode.value] is written into the field, which makes the field
/// controlled: rendering the node again with a new value replaces what the user
/// typed. Without a value the field keeps its own content and only reports
/// changes through [core.TextInputNode.onChanged].
///
/// [core.TextInputNode.onSubmitted] fires on `Enter` for a single line field and
/// on `Ctrl`/`Cmd` + `Enter` for a text area, because a plain `Enter` inserts a
/// newline there. That is the same split a Flutter `TextField` has, where the
/// multiline keyboard type only offers a newline action.
class JasprTextInput extends StatelessComponent {
  /// Creates a renderer for [node].
  const JasprTextInput({required this.node, super.key});

  /// The node being rendered.
  final core.TextInputNode node;

  @override
  Component build(BuildContext context) {
    final String? placeholder = node.placeholder;
    final Map<String, EventCallback>? listeners = _events();
    final Styles styles = toTextInputStyles(padding: node.padding);
    final Styles? hint = _hintStyles();
    // The hint is a rule of its own — `::placeholder` is not a declaration the field
    // carries — so its declarations are part of the class key. Without that, two
    // fields that differ only in the colour of their hint would share a class and the
    // first hint colour would win for both.
    final String key = hint == null
        ? declarationsOf(styles)
        : '${declarationsOf(styles)}|::placeholder:${declarationsOf(hint)}';
    final String? className = UniboxStylesheetScope.of(context)?.classFor(
      'field',
      key,
      (String name) => <StyleRule>[
        StyleRule(selector: Selector.className(name), styles: styles),
        if (hint != null)
          StyleRule(
            selector: Selector.chain(<Selector>[
              Selector.className(name),
              const Selector.pseudoElem('placeholder'),
            ]),
            styles: hint,
          ),
      ],
    );

    if (node.multiline) {
      final String? value = node.value;

      return textarea(
        <Component>[if (value != null) Component.text(value)],
        placeholder: placeholder,
        rows: node.maxLines ?? _defaultRows,
        disabled: !node.enabled,
        readonly: node.readOnly,
        autofocus: node.autofocus,
        attributes: withNodeAttributes(node, _attributes()),
        classes: className,
        styles: className == null ? styles : null,
        events: listeners,
      );
    }

    return input(
      type: _inputType(node),
      value: node.value,
      disabled: !node.enabled,
      attributes: withNodeAttributes(
        node,
        _attributes(includeBooleanFlags: true),
      ),

      classes: className,
      styles: className == null ? styles : null,
      events: listeners,
    );
  }

  /// The declarations of [core.TextInputNode.placeholderStyle], or `null` when the
  /// node says nothing about the hint.
  Styles? _hintStyles() {
    final core.BoxTextStyle? style = node.placeholderStyle;
    return style == null ? null : toTypographyStyles(style);
  }

  /// The attributes the field needs beyond the typed parameters.
  ///
  /// The `autocomplete` hint has no equivalent on the node type and the input
  /// component has no `aria-label`, so they are passed through the attribute
  /// escape hatch. The read only and autofocus flags are only added for an
  /// `<input>`, since a `<textarea>` has typed parameters for both.
  Map<String, String>? _attributes({bool includeBooleanFlags = false}) {
    final Map<String, String> attributes = <String, String>{};
    final String? placeholder = node.placeholder;
    final String? label = node.semanticsLabel;
    final Map<String, String>? autofill = _autofillAttributes();

    if (placeholder != null) {
      attributes['placeholder'] = placeholder;
    }
    if (node.required) {
      attributes['aria-required'] = 'true';
    }
    if (node.invalid) {
      attributes['aria-invalid'] = 'true';
    }
    if (node.description != null) {
      // A description needs no element to point at: `aria-description` carries the
      // text itself, which is also what the Flutter side hands to `Semantics.hint`.
      attributes['aria-description'] = node.description!;
    }
    if (label != null) {
      attributes['aria-label'] = label;
    }
    if (includeBooleanFlags && node.readOnly) {
      attributes['readonly'] = '';
    }
    if (includeBooleanFlags && node.autofocus) {
      attributes['autofocus'] = '';
    }
    if (autofill != null) {
      attributes.addAll(autofill);
    }

    return attributes.isEmpty ? null : attributes;
  }

  /// The `autocomplete` hint of the field, which is what lets a password manager
  /// offer the right entry. The typed parameters do not cover it.
  Map<String, String>? _autofillAttributes() {
    return switch (node.inputType) {
      core.InputType.text => null,
      core.InputType.email => <String, String>{'autocomplete': 'email'},
      core.InputType.number => null,
      core.InputType.phone => <String, String>{'autocomplete': 'tel'},
      core.InputType.url => <String, String>{'autocomplete': 'url'},
    };
  }

  /// The listeners of the field, or `null` when the node reacts to nothing.
  ///
  /// The `input` event carries the text of an input or text area directly, so
  /// [core.TextInputNode.onChanged] is attached with the typed `events` helper.
  Map<String, EventCallback>? _events() {
    final core.TextChangedCallback? onChanged = node.onChanged;
    final core.TextSubmittedCallback? onSubmitted = node.onSubmitted;
    final core.FocusChangedCallback? onFocusChanged = node.onFocusChanged;

    if (onChanged == null && onSubmitted == null && onFocusChanged == null) {
      return null;
    }

    final bool multiline = node.multiline;

    return <String, EventCallback>{
      ...events<String>(onInput: onChanged),
      if (onSubmitted != null)
        'keydown': (event) {
          if (_isSubmit(event, multiline: multiline)) {
            onSubmitted(_fieldValue(event));
          }
        },
      if (onFocusChanged != null) ...<String, EventCallback>{
        'focus': (event) => onFocusChanged(true),
        'blur': (event) => onFocusChanged(false),
      },
    };
  }
}

/// The height of a text area that declares no [core.TextInputNode.maxLines].
///
/// A browser starts a text area at two rows and a Flutter field at one line, so
/// the value is written out instead of being left to the user agent. One row is
/// the closer of the two answers to Flutter's: a multiline field grows with its
/// content there, while a text area of a fixed number of rows scrolls, which is a
/// difference no declaration can remove.
const int _defaultRows = 1;

/// The `type` of the `<input>` for [node].
///
/// An obscured field is a password field whatever else it says, and a text area
/// has no type of its own.
InputType _inputType(core.TextInputNode node) {
  if (node.obscureText) {
    return InputType.password;
  }

  return switch (node.inputType) {
    core.InputType.text => InputType.text,
    core.InputType.email => InputType.email,
    core.InputType.number => InputType.number,
    core.InputType.phone => InputType.tel,
    core.InputType.url => InputType.url,
  };
}

/// Whether [event] is the key press that submits a field.
///
/// A single line field submits on a bare `Enter`; a text area needs
/// `Ctrl`/`Cmd` + `Enter` because it consumes `Enter` for its own line breaks.
///
/// The DOM types of `package:web` are extension types, which are erased at
/// runtime: a runtime `is` check would always succeed. The cast therefore only
/// tells the analyzer what the browser already guarantees — a `keydown` listener
/// of a field can only receive a keyboard event.
bool _isSubmit(web.Event event, {required bool multiline}) {
  final web.KeyboardEvent keyEvent = event as web.KeyboardEvent;

  if (keyEvent.key != 'Enter') {
    return false;
  }
  return multiline ? keyEvent.ctrlKey || keyEvent.metaKey : true;
}

/// The text currently shown by the field that emitted [event].
///
/// The listener is only attached to a single input or text area, and both expose
/// their content as `value`.
String _fieldValue(web.Event event) {
  return (event.target as web.HTMLInputElement).value;
}
