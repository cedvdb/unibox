import '../callbacks.dart';
import '../enums.dart';
import '../tokens/box_spacing.dart';
import '../tokens/box_text_style.dart';
import 'ui_node.dart';

/// A single line or multiline text input.
///
/// The node describes what the field is for, not how it looks: the keyboard and
/// the validation hints follow from [inputType], the visual style is inherited
/// from the enclosing box like every other typography token.
class TextInputNode extends UINode {
  /// Creates a text input node.
  const TextInputNode({
    super.key,
    this.value,
    this.placeholder,
    this.placeholderStyle,
    this.inputType = InputType.text,
    this.obscureText = false,
    this.multiline = false,
    this.maxLines,
    this.padding,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.semanticsLabel,
    this.required = false,
    this.invalid = false,
    this.description,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
  });

  /// The controlled value of the input.
  ///
  /// When `null` the input starts empty and is only managed by the renderer.
  final String? value;

  /// The hint shown while the input is empty.
  final String? placeholder;

  /// The typography of [placeholder], when it should differ from the value's.
  ///
  /// A hint is secondary text, so a design system usually paints it in a quieter
  /// colour than the text the user types. It is a token of its own rather than an
  /// inherited one because both targets hand the hint to the control: Flutter's
  /// `hintStyle`, the browser's `::placeholder`. Inheriting the value style would
  /// make an empty field look filled.
  final BoxTextStyle? placeholderStyle;

  /// The kind of value the input expects.
  ///
  /// Ignored for a [multiline] input, which always accepts plain text.
  final InputType inputType;

  /// Whether the entered text is hidden, e.g. for passwords.
  final bool obscureText;

  /// Whether the input accepts multiple lines and renders as a text area.
  final bool multiline;

  /// The maximum number of visible lines of a [multiline] input.
  final int? maxLines;

  /// The space inside the input, between its edge and the text.
  ///
  /// It belongs to the input and not to a box around it: padding on the box sits
  /// outside the control's hit area on both targets, so a press in it focuses
  /// nothing. A padding here is inside the field, which is what makes the whole
  /// surface tappable — the way a Material field is.
  final BoxSpacing? padding;

  /// Whether the field accepts input.
  ///
  /// A disabled field keeps its value and its layout, is skipped by the tab
  /// order and is announced as disabled.
  final bool enabled;

  /// Whether the value can be selected and copied but not changed.
  final bool readOnly;

  /// Whether the field takes focus as soon as it is rendered.
  final bool autofocus;

  /// The text a screen reader announces for the field.
  ///
  /// A [placeholder] is only a hint and disappears once the user types, so a
  /// field that needs an accessible name should carry one.
  final String? semanticsLabel;

  /// Whether the form needs a value here.
  ///
  /// A required field says so before it is submitted: `aria-required` on the web
  /// and `Semantics.isRequired` in Flutter, both of which a screen reader reads out
  /// with the label instead of after a failed submission.
  final bool required;

  /// Whether the value in the field is wrong.
  ///
  /// The tree does not decide what "wrong" means — the host validates and rebuilds
  /// with this flag — but it does report it in the same two places: `aria-invalid`
  /// and `Semantics.validationResult`.
  final bool invalid;

  /// A line that describes what the field expects: a format, or why the value was
  /// rejected.
  ///
  /// This is the accessible description of the field and not a visible message: the
  /// tree draws what the host asks it to draw, so a message that should also be seen
  /// stays a `TextNode` next to the field. The two targets attach it the same way —
  /// `aria-description` on the web, `Semantics.hint` in Flutter.
  final String? description;

  /// Called whenever the value of the input changes.
  final TextChangedCallback? onChanged;

  /// Called when the value of the input is submitted.
  final TextSubmittedCallback? onSubmitted;

  /// Called when the field gains or loses focus.
  final FocusChangedCallback? onFocusChanged;

  /// The name this node answers to in an inspector.
  ///
  /// A literal, not the type name: a compiled build mangles the latter.
  @override
  String? get debugLabel => 'text-input';
}
