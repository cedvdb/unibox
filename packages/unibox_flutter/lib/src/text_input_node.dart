import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:unibox_core/unibox_core.dart' as core;

import 'text_style_scope.dart';
import 'theme_scope.dart';
import 'values.dart';

/// Renders a [core.TextInputNode] as a Material [TextField].
///
/// The field owns a [TextEditingController] so that typing keeps working while
/// [core.TextInputNode.value] is `null`. When the node does carry a value, the
/// controller follows it: values pushed by the owner replace the field content,
/// values typed by the user are reported through
/// [core.TextInputNode.onChanged].
///
/// The node also drives the platform behaviour of the field:
/// [core.TextInputNode.inputType] picks the keyboard and the autofill hints, and
/// the enabled, read only and autofocus flags are passed straight through.
///
/// The field carries no decoration of its own — no underline, no fill, no
/// padding — so it looks like the `<input>` the web renderer emits: a box that
/// wants a field to look like a field draws the border and the padding around
/// it, which is what keeps the two targets showing the same form.
class FlutterTextInput extends StatefulWidget {
  /// Creates a renderer for [node].
  const FlutterTextInput({required this.node, super.key});

  /// The node being rendered.
  final core.TextInputNode node;

  @override
  State<FlutterTextInput> createState() => FlutterTextInputState();
}

class FlutterTextInputState extends State<FlutterTextInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.node.value ?? '',
  );
  late final FocusNode _focusNode = FocusNode()
    ..addListener(_handleFocusChanged);

  @override
  void didUpdateWidget(FlutterTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    final String? value = widget.node.value;
    if (value != null && value != _controller.text) {
      // The owner replaced the value, so move the caret to the end of it.
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// The hint's typography, or `null` to let the control keep its own.
  ///
  /// The hint is drawn by the field, not by the enclosing box, so it is handed to
  /// the control as `hintStyle` — the web renderer answers with a `::placeholder`
  /// rule — and an unset token means the field says nothing about it. A colour
  /// that names a role is resolved against the theme of the rendering, like the
  /// colour of any other text.
  TextStyle? _hintStyle(BuildContext context) {
    final core.BoxTextStyle? style = widget.node.placeholderStyle?.resolve(
      UniboxThemeScope.of(context) ?? core.UniboxTheme.none,
    );
    return style == null ? null : toTextStyle(style);
  }

  @override
  Widget build(BuildContext context) {
    final core.TextInputNode node = widget.node;
    final bool multiline = node.multiline;

    // A box that sets typography is a deliberate decision, so the field adopts
    // the ambient text style; `renderFlutter` installs the model's typography at
    // the root of every tree, so inside a tree there is always one to adopt.
    final bool inheritsTypography =
        FlutterTextStyleScope.maybeOf(context) != null;
    final String? semanticsLabel = node.semanticsLabel;

    final Widget field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: inheritsTypography ? DefaultTextStyle.of(context).style : null,
      obscureText: node.obscureText,
      keyboardType: multiline
          ? TextInputType.multiline
          : _keyboardType(node.inputType),
      autofillHints: multiline ? null : _autofillHints(node.inputType),
      enabled: node.enabled,
      readOnly: node.readOnly,
      autofocus: node.autofocus,
      maxLines: multiline ? node.maxLines : 1,
      minLines: multiline ? 1 : null,
      onChanged: node.onChanged,
      onSubmitted: node.onSubmitted,
      // A collapsed decoration drops everything Material puts around a field:
      // the underline, the content padding and the 48 pixel minimum height. The
      // field then occupies exactly its line box, which is what a plain
      // `<input>` does on the web, and the enclosing box decides how a field
      // looks on both targets instead of each platform styling it its own way.
      decoration: node.padding == null
          ? InputDecoration.collapsed(
              hintText: node.placeholder,
              hintStyle: _hintStyle(context),
            )
          : InputDecoration(
              hintText: node.placeholder,
              hintStyle: _hintStyle(context),
              border: InputBorder.none,
              isDense: true,
              contentPadding: toEdgeInsets(node.padding!),
            ),
    );

    // A field states what the form needs from it as well as its name, so the
    // wrapper is there whenever the node said anything a reader should hear.
    if (semanticsLabel == null &&
        !node.required &&
        !node.invalid &&
        node.description == null) {
      return field;
    }

    return Semantics(
      textField: true,
      label: semanticsLabel,
      enabled: node.enabled,
      readOnly: node.readOnly,
      isRequired: node.required ? true : null,
      validationResult: node.invalid
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      hint: node.description,
      child: field,
    );
  }

  /// Reports focus changes of the field to the node.
  void _handleFocusChanged() {
    widget.node.onFocusChanged?.call(_focusNode.hasFocus);
  }
}

/// The keyboard a field of [type] asks for.
TextInputType _keyboardType(core.InputType type) {
  return switch (type) {
    core.InputType.text => TextInputType.text,
    core.InputType.email => TextInputType.emailAddress,
    core.InputType.number => TextInputType.number,
    core.InputType.phone => TextInputType.phone,
    core.InputType.url => TextInputType.url,
  };
}

/// The autofill hints a field of [type] advertises, if any.
///
/// They let a password manager and the platform autofill offer the right entry,
/// which is the closest Flutter equivalent of the `autocomplete` attribute the
/// web renderer emits.
List<String>? _autofillHints(core.InputType type) {
  return switch (type) {
    core.InputType.text => null,
    core.InputType.email => const <String>[AutofillHints.email],
    core.InputType.number => null,
    core.InputType.phone => const <String>[AutofillHints.telephoneNumber],
    core.InputType.url => const <String>[AutofillHints.url],
  };
}
