import 'package:unibox_core/unibox_core.dart';

import 'material_palette.dart';
import 'material_typography.dart';

/// A labelled, filled Material 3 text field, built from a [Box] around a
/// [TextInputNode].
///
/// ```dart
/// MaterialTextField(
///   label: "Email",
///   value: state.email,
///   onChanged: store.setEmail,
///   invalid: state.emailInvalid,
///   message: state.emailInvalid ? "Enter an address with an @" : null,
/// )
/// ```
///
/// The field is a box and the value is the core input node, so both targets draw
/// it with what they already have: a `TextField` on Flutter and an `<input>` or
/// `<textarea>` on the web. The caret, the selection, the IME and autofill are the
/// platform's, because the input node delegates them.
///
/// **The fill is drawn by the box, the padding by the input.** The box states the
/// surface, the radius and the bottom line; [TextInputNode.padding] states the
/// space inside the control, so a press anywhere in the field focuses it. Padding
/// on the box would sit outside the control's hit area on both targets — the
/// difference between a field that feels like a field and one that only responds on
/// its text line.
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
final class MaterialTextField extends Box {
  /// Creates the field, its label and its message.
  MaterialTextField({
    super.key,
    String? value,
    void Function(String value)? onChanged,
    void Function(String value)? onSubmitted,
    void Function(bool focused)? onFocusChanged,
    String? label,
    String? placeholder,
    String? message,
    bool invalid = false,
    bool focused = false,
    bool enabled = true,
    bool obscureText = false,
    bool multiline = false,
    bool required = false,
    String? description,
    int? maxLines,
    InputType inputType = InputType.text,
    double borderRadius = 4,
    super.width,
  }) : super(
         gap: 4,
         children: <UINode>[
           Box(
             minHeight: 56,
             backgroundColor: const BoxColor.role(
               MaterialColorRole.surfaceContainerHighest,
             ),
             corners: BoxBorderRadius(
               topLeft: borderRadius,
               topRight: borderRadius,
             ),
             opacity: enabled ? null : 0.38,
             shadow: _line(focused: focused, invalid: invalid),
             textStyle: _valueStyle(),
             hoverStyle: enabled && !focused && !invalid
                 ? const BoxStyle(
                     shadow: BoxShadow(
                       color: BoxColor.role(MaterialColorRole.onSurface),
                       offsetY: 1,
                       blurRadius: 0,
                     ),
                   )
                 : null,
             children: <UINode>[
               if (_floats(value, focused: focused, multiline: multiline) &&
                   label != null)
                 Box(
                   // Eight pixels to the top of the fill, then the label's own line:
                   // the value's row begins 24 pixels down, where Material puts it.
                   padding: const BoxSpacing.only(left: 16, right: 16, top: 8),
                   children: <UINode>[
                     TextNode(
                       label,
                       style: _labelStyle(invalid: invalid, focused: focused),
                     ),
                   ],
                 ),
               TextInputNode(
                 value: value,
                 // Empty and unfocused, the label sits where the value would be, so it
                 // is the hint; a field with no label keeps its own hint throughout.
                 placeholder:
                     _restsOnTheLine(
                       label,
                       value: value,
                       focused: focused,
                       multiline: multiline,
                     )
                     ? label
                     : placeholder,
                 placeholderStyle:
                     _restsOnTheLine(
                       label,
                       value: value,
                       focused: focused,
                       multiline: multiline,
                     )
                     ? _restingLabelStyle(invalid: invalid)
                     : _hintStyle(),
                 inputType: inputType,
                 obscureText: obscureText,
                 multiline: multiline,
                 maxLines: maxLines,
                 enabled: enabled,
                 required: required,
                 invalid: invalid,
                 description: description,
                 // Sixteen and sixteen with the label at rest fills Material's 56
                 // pixels with one line of body text; floated, the label has taken
                 // the top of the fill and the value sits under it.
                 padding: _floats(value, focused: focused, multiline: multiline)
                     ? const BoxSpacing.only(left: 16, right: 16, bottom: 8)
                     : const BoxSpacing.only(
                         left: 16,
                         right: 16,
                         top: 16,
                         bottom: 16,
                       ),
                 onChanged: onChanged,
                 onSubmitted: onSubmitted,
                 onFocusChanged: onFocusChanged,
               ),
             ],
           ),
           if (message != null)
             Box(
               padding: const BoxSpacing.only(left: 16, right: 16),
               children: <UINode>[
                 TextNode(message, style: _labelStyle(invalid: invalid)),
               ],
             ),
         ],
       );

  /// Whether [label] is drawn *inside* the field rather than above it: only a
  /// labelled field that is empty and unfocused has a label to rest on the line.
  static bool _restsOnTheLine(
    String? label, {
    required String? value,
    required bool focused,
    required bool multiline,
  }) {
    if (label == null) {
      return false;
    }

    return !_floats(value, focused: focused, multiline: multiline);
  }

  /// Whether the label has left the line: it floats as soon as the field holds a
  /// value, takes focus, or is a text area — a multi-line field has no single line
  /// for a label to rest on, so Material floats it there from the start.
  static bool _floats(
    String? value, {
    required bool focused,
    required bool multiline,
  }) {
    return multiline || focused || (value != null && value.isNotEmpty);
  }

  /// The bottom line: two pixels of primary while focused, one otherwise, and the
  /// error colour whenever the field is invalid.
  ///
  /// A shadow with no blur, because `BoxBorder` draws all four sides and a filled
  /// field has no side borders.
  static BoxShadow _line({required bool focused, required bool invalid}) {
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

  /// The label and the message: small, and the error colour when invalid.
  static BoxTextStyle _labelStyle({
    required bool invalid,
    bool focused = false,
  }) => MaterialTypography.bodySmall.merge(
    BoxTextStyle(
      color: invalid
          ? const BoxColor.role(MaterialColorRole.error)
          : focused
          ? const BoxColor.role(MaterialColorRole.primary)
          : const BoxColor.role(MaterialColorRole.onSurfaceVariant),
    ),
  );

  /// The label while it rests on the line: the value's size, in the quieter colour.
  ///
  /// It is handed to the input as its hint, which is why it is named for the label:
  /// at rest the two are the same piece of text.
  static BoxTextStyle _restingLabelStyle({required bool invalid}) =>
      MaterialTypography.bodyLarge.merge(
        BoxTextStyle(
          color: invalid
              ? const BoxColor.role(MaterialColorRole.error)
              : const BoxColor.role(MaterialColorRole.onSurfaceVariant),
        ),
      );

  /// The hint that waits for the label to float, in the same quieter colour.
  static BoxTextStyle _hintStyle() => MaterialTypography.bodyLarge.merge(
    const BoxTextStyle(
      color: BoxColor.role(MaterialColorRole.onSurfaceVariant),
    ),
  );

  /// The text the user types: the body role, in the on-surface colour.
  static BoxTextStyle _valueStyle() => MaterialTypography.bodyLarge.merge(
    BoxTextStyle(color: const BoxColor.role(MaterialColorRole.onSurface)),
  );
}
