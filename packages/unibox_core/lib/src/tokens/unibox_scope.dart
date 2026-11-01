import '../enums.dart';
import 'unibox_theme.dart';

/// What a rendering is drawn *against*, rather than what it says.
///
/// A tree states what a page is — a box, a heading, a link. A scope states how that page is
/// drawn: the colour every role stands for, the language it is written in, and the direction its
/// rows run. It is a value of the **rendering** and not of the tree, which is what lets one tree be
/// rendered as a light page and a dark one, in English and in Arabic, without a node changing — and
/// what keeps a node a value that can be rendered twice.
///
/// **Environment, not domain.** What belongs here is a fact about the drawing: a colour, a
/// language, a direction. What the page is *about* — the signed-in reader, a cart, the currency a
/// price is in — is a parameter of the component that shows it. A node that read one could not be
/// rendered twice, and a scope that carried one would be a store wearing another name.
///
/// A renderer takes one of these where it used to take a theme, so a host that adds a language or a
/// direction to a page adds a field here rather than a parameter to every rendering call.
final class UniboxScope {
  /// Creates a scope that states [theme], [lang] and [writingDirection].
  ///
  /// [theme] is `null` for a rendering that states none: a tree that names no colour role draws
  /// without one, and a tree that names one is reported by `validateTree` rather than painted
  /// against an empty theme in silence.
  const UniboxScope({this.theme, this.lang = 'en', this.writingDirection});

  /// A rendering that states nothing: no theme, English, and no direction claimed.
  static const UniboxScope none = UniboxScope();

  /// The colour every role of the tree stands for, or `null` when the rendering states none.
  final UniboxTheme? theme;

  /// The language the page is written in.
  ///
  /// It is the `lang` of a document's root element, and what a component that words a date, a
  /// number or a message reads.
  final String lang;

  /// The direction the page is written in, or `null` to claim none.
  ///
  /// A language is not a direction: Azerbaijani, Kurdish and Punjabi are written in both scripts,
  /// and a page written right to left can hold a region that reads left to right.
  final WritingDirection? writingDirection;

  @override
  bool operator ==(Object other) =>
      other is UniboxScope &&
      other.theme == theme &&
      other.lang == lang &&
      other.writingDirection == writingDirection;

  @override
  int get hashCode => Object.hash(theme, lang, writingDirection);

  @override
  String toString() =>
      'UniboxScope(lang: $lang, writingDirection: $writingDirection, '
      'theme: $theme)';
}
