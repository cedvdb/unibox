import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';
import 'material_typography.dart';

/// What a [MaterialTextField] knows about itself: the text it holds, whether it
/// has focus, and whether the user has touched it.
///
/// These are the three facts only the field can know. A form's state — what the
/// address is worth, whether the request is in flight — belongs to the form's
/// store; the field owns what happens between the pointer and the value it hands
/// over, so a field shows its own focus and its own error as the user types,
/// without the host passing a flag down for every keystroke.
final class MaterialFieldState {
  /// Creates a field state holding [value], unfocused and untouched.
  const MaterialFieldState({
    this.value = '',
    this.focused = false,
    this.touched = false,
  });

  /// The text in the field.
  final String value;

  /// Whether the field has focus.
  final bool focused;

  /// Whether the user has typed in it or left it, which is what lets a field wait
  /// before telling them the address is wrong.
  final bool touched;

  /// The same state with the named facts replaced.
  MaterialFieldState copyWith({String? value, bool? focused, bool? touched}) {
    return MaterialFieldState(
      value: value ?? this.value,
      focused: focused ?? this.focused,
      touched: touched ?? this.touched,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MaterialFieldState &&
      other.value == value &&
      other.focused == focused &&
      other.touched == touched;

  @override
  int get hashCode => Object.hash(value, focused, touched);

  @override
  String toString() =>
      'MaterialFieldState(value: $value, focused: $focused, touched: $touched)';
}

/// The state a [MaterialTextField] draws.
///
/// It publishes the way every store does: a keystroke replaces the value, a focus
/// change replaces the flag, and a renderer subscribed to the field redraws it.
/// Nothing is validated here — the field asks its `validator` while it builds the
/// view, so the rule stays a property of the form and not a piece of state.
final class MaterialFieldStore extends StateStore<MaterialFieldState> {
  /// Creates a store for a field holding [value].
  MaterialFieldStore({String value = ''})
    : super(MaterialFieldState(value: value));

  /// Records what the user typed, and that they have typed at all.
  void setValue(String value) {
    state = state.copyWith(value: value, touched: true);
  }

  /// Records focus. Leaving a field counts as having looked at it, which is when
  /// Material starts telling the user what is wrong with it.
  void setFocused(bool focused) {
    state = state.copyWith(
      focused: focused,
      touched: state.touched || !focused,
    );
  }
}

/// The parameters of one [MaterialTextField], kept for the view.
///
/// `StatefulNode.view` receives only the state and the store, so the node closes
/// over what it was built with. One immutable holder keeps that closure to three
/// parameters instead of eighteen.
final class _Field {
  const _Field({
    required this.value,
    required this.initialValue,
    required this.label,
    required this.placeholder,
    required this.helper,
    required this.error,
    required this.validator,
    required this.inputType,
    required this.obscureText,
    required this.multiline,
    required this.maxLines,
    required this.enabled,
    required this.required,
    required this.description,
    required this.borderRadius,
    required this.width,
    required this.onChanged,
    required this.onSubmitted,
    required this.onFocusChanged,
  });

  final String? value;
  final String? initialValue;
  final String? label;
  final String? placeholder;
  final String? helper;
  final String? error;
  final String? Function(String value)? validator;
  final InputType inputType;
  final bool obscureText;
  final bool multiline;
  final int? maxLines;
  final bool enabled;
  final bool required;
  final String? description;
  final double borderRadius;
  final double? width;
  final void Function(String value)? onChanged;
  final void Function(String value)? onSubmitted;
  final void Function(bool focused)? onFocusChanged;
}

/// A labelled, filled Material 3 text field that owns its own state.
///
/// ```dart
/// MaterialTextField(
///   label: 'Email',
///   inputType: InputType.email,
///   validator: (String value) =>
///       value.contains('@') ? null : 'Enter an address with an @',
///   onChanged: store.setEmail,
/// )
/// ```
///
/// **It is a node with a state, not a look.** The text, the focus and whether the
/// field has been touched are [MaterialFieldStore]'s, so the field shows its own
/// focus line and its own error while the user types: `validator` is asked once the
/// field has been touched, and its answer is the message under the line and the
/// colour of the line and the label. A form still owns what the value is *worth* —
/// the request, the button it enables — through [onChanged].
///
/// Pass [initialValue] for a field the form does not control and [value] to control
/// one from outside; [error] shows a message the form decided on ("that address is
/// taken"), and all three outrank what the store starts with.
/// [helper] is the quiet line under the field while there is nothing wrong.
///
/// The field is a box and the value is the core input node, so both targets draw it
/// with what they already have: a `TextField` on Flutter and an `<input>` or
/// `<textarea>` on the web. The caret, the selection, the IME and autofill are the
/// platform's, because the input node delegates them.
///
/// **The fill is drawn by the box, the padding by the input.** The box states the
/// surface, the radius and the bottom line; [TextInputNode.padding] states the space
/// inside the control, so a press anywhere in the field focuses it. Padding on the
/// box would sit outside the control's hit area on both targets — the difference
/// between a field that feels like a field and one that only responds on its text
/// line.
///
/// **The label has the two positions Material gives it.** While the field is empty
/// and unfocused, the label *is* the line inside the field, at the value's size and
/// the quieter colour — drawn as the input's own hint, so the caret, the hint and the
/// label are one piece of text and the field stays 56 pixels tall. Once the field is
/// focused or holds a value, the label shrinks and moves to the top of the fill and
/// the input takes the row below it. Material animates that move; the model has no
/// triggered timeline for a layout change, so this one steps.
///
/// **Filled, not outlined.** Material's outlined field floats its label into a notch
/// cut in the border, and a uniform `BoxBorder` cannot be cut; the filled variant
/// needs only a surface, a radius and a bottom line, and the line is a shadow with no
/// blur because a border cannot be one-sided.
///
/// **Rounded at the top, square at the bottom.** Material's filled field is a shape
/// cut to the lines it sits between: the two top corners are round and the two
/// bottom ones are not, which is what [borderRadius] states through
/// [BoxBorderRadius].
///
/// Every colour is a role, so a dark scheme is the host's theme rather than a
/// parameter here (see [MaterialColorRole]).
final class MaterialTextField
    extends StatefulNode<MaterialFieldState, MaterialFieldStore> {
  /// Creates the field.
  MaterialTextField({
    Object? key,
    String? value,
    String? initialValue,
    String? label,
    String? placeholder,
    String? helper,
    String? error,
    String? Function(String value)? validator,
    InputType inputType = InputType.text,
    bool obscureText = false,
    bool multiline = false,
    int? maxLines,
    bool enabled = true,
    bool required = false,
    String? description,
    double borderRadius = 4,
    double? width,
    void Function(String value)? onChanged,
    void Function(String value)? onSubmitted,
    void Function(bool focused)? onFocusChanged,
  }) : this._(
         _Field(
           value: value,
           initialValue: initialValue,
           label: label,
           placeholder: placeholder,
           helper: helper,
           error: error,
           validator: validator,
           inputType: inputType,
           obscureText: obscureText,
           multiline: multiline,
           maxLines: maxLines,
           enabled: enabled,
           required: required,
           description: description,
           borderRadius: borderRadius,
           width: width,
           onChanged: onChanged,
           onSubmitted: onSubmitted,
           onFocusChanged: onFocusChanged,
         ),
         key: key,
       );

  MaterialTextField._(_Field field, {super.key})
    : super(
        create: () =>
            MaterialFieldStore(value: field.value ?? field.initialValue ?? ''),
        view: (MaterialFieldState state, MaterialFieldStore store) =>
            _fieldView(field, state, store),
      );
}

/// The field as one tree: the fill, the label, the input and the message.
UINode _fieldView(
  _Field field,
  MaterialFieldState state,
  MaterialFieldStore store,
) {
  // A host's value and a host's error outrank the field's own: the first is a
  // controlled field, the second is a message the form decided on.
  final String text = field.value ?? state.value;
  final String? error =
      field.error ?? (state.touched ? field.validator?.call(text) : null);
  final bool invalid = error != null;
  final bool floats = _floats(
    text,
    focused: state.focused,
    multiline: field.multiline,
  );
  final bool rests = !floats && field.label != null;
  final String? message = error ?? field.helper;

  return Box(
    width: field.width,
    gap: 4,
    children: <UINode>[
      Box(
        minHeight: 56,
        backgroundColor: const BoxColor.role(
          MaterialColorRole.surfaceContainerHighest,
        ),
        // Material's filled field is a shape cut to the lines it sits between: the
        // two top corners are round and the two bottom ones are not.
        corners: BoxBorderRadius(
          topLeft: field.borderRadius,
          topRight: field.borderRadius,
        ),
        opacity: field.enabled ? null : 0.38,
        shadow: _line(focused: state.focused, invalid: invalid),
        textStyle: _valueStyle(),
        hoverStyle: field.enabled && !state.focused && !invalid
            ? const BoxStyle(
                shadow: BoxShadow(
                  color: BoxColor.role(MaterialColorRole.onSurface),
                  offsetY: 1,
                  blurRadius: 0,
                ),
              )
            : null,
        children: <UINode>[
          if (floats && field.label != null)
            Box(
              // Eight pixels to the top of the fill, then the label's own line: the
              // value's row begins 24 pixels down, where Material puts it.
              padding: const BoxSpacing.only(left: 16, right: 16, top: 8),
              children: <UINode>[
                TextNode(
                  field.label!,
                  style: _labelStyle(invalid: invalid, focused: state.focused),
                ),
              ],
            ),
          TextInputNode(
            value: text,
            // Empty and unfocused, the label sits where the value would be, so it
            // is the hint; a field with no label keeps its own hint throughout.
            placeholder: rests ? field.label : field.placeholder,
            placeholderStyle: rests
                ? _restingLabelStyle(invalid: invalid)
                : _hintStyle(),
            inputType: field.inputType,
            obscureText: field.obscureText,
            multiline: field.multiline,
            maxLines: field.maxLines,
            enabled: field.enabled,
            required: field.required,
            invalid: invalid,
            description: field.description,
            // Sixteen and sixteen with the label at rest fills Material's 56 pixels
            // with one line of body text; floated, the label has taken the top of
            // the fill and the value sits under it.
            padding: floats
                ? const BoxSpacing.only(left: 16, right: 16, bottom: 8)
                : const BoxSpacing.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
            onChanged: (String value) {
              store.setValue(value);
              field.onChanged?.call(value);
            },
            onSubmitted: field.onSubmitted,
            onFocusChanged: (bool focused) {
              store.setFocused(focused);
              field.onFocusChanged?.call(focused);
            },
          ),
        ],
      ),
      if (message != null)
        Box(
          padding: const BoxSpacing.only(left: 16, right: 16),
          children: <UINode>[
            TextNode(message, style: invalid ? _errorStyle() : _helperStyle()),
          ],
        ),
    ],
  );
}

/// Whether the label has left the line: it floats as soon as the field holds a
/// value, takes focus, or is a text area — a multi-line field has no single line
/// for a label to rest on, so Material floats it there from the start.
bool _floats(String text, {required bool focused, required bool multiline}) {
  return multiline || focused || text.isNotEmpty;
}

/// The bottom line: two pixels of primary while focused, one otherwise, and the
/// error colour whenever the field is invalid.
///
/// A shadow with no blur, because `BoxBorder` draws all four sides and a filled
/// field has no side borders.
BoxShadow _line({required bool focused, required bool invalid}) {
  return BoxShadow(
    color: invalid
        ? const BoxColor.role(MaterialColorRole.error)
        : focused
        ? const BoxColor.role(MaterialColorRole.primary)
        : const BoxColor.role(MaterialColorRole.onSurfaceVariant),
    offsetY: focused ? 2 : 1,
    blurRadius: 0,
  );
}

/// The label once it has floated: small, and the error colour when invalid.
BoxTextStyle _labelStyle({required bool invalid, required bool focused}) {
  return MaterialTypography.bodySmall.merge(
    BoxTextStyle(
      color: invalid
          ? const BoxColor.role(MaterialColorRole.error)
          : focused
          ? const BoxColor.role(MaterialColorRole.primary)
          : const BoxColor.role(MaterialColorRole.onSurfaceVariant),
    ),
  );
}

/// The label while it rests on the line: the value's size, in the quieter colour.
///
/// It is handed to the input as its hint, which is why it is named for the label:
/// at rest the two are the same piece of text.
BoxTextStyle _restingLabelStyle({required bool invalid}) {
  return MaterialTypography.bodyLarge.merge(
    BoxTextStyle(
      color: invalid
          ? const BoxColor.role(MaterialColorRole.error)
          : const BoxColor.role(MaterialColorRole.onSurfaceVariant),
    ),
  );
}

/// The hint that waits for the label to float, in the same quieter colour.
BoxTextStyle _hintStyle() => MaterialTypography.bodyLarge.merge(
  const BoxTextStyle(color: BoxColor.role(MaterialColorRole.onSurfaceVariant)),
);

/// The message under a field that is wrong: small, and the error colour.
BoxTextStyle _errorStyle() => MaterialTypography.bodySmall.merge(
  const BoxTextStyle(color: BoxColor.role(MaterialColorRole.error)),
);

/// The message under a field that is right: small, and quieter than the value.
BoxTextStyle _helperStyle() => MaterialTypography.bodySmall.merge(
  const BoxTextStyle(color: BoxColor.role(MaterialColorRole.onSurfaceVariant)),
);

/// The text the user types: the body role, in the on-surface colour.
BoxTextStyle _valueStyle() => MaterialTypography.bodyLarge.merge(
  const BoxTextStyle(color: BoxColor.role(MaterialColorRole.onSurface)),
);
