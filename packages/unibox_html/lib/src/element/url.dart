/// Whether [value] names a URL scheme that would run as a script.
///
/// The check ignores case and leading whitespace, and it looks at the raw value, because a URL
/// that has already been escaped is no longer recognisable.
///
/// It belongs to the plan rather than to a renderer: a `javascript:` href is a script that runs
/// when a reader clicks, whichever target set the attribute.
bool isRiskyUrl(String value) {
  final String normalised = value.trimLeft().toLowerCase();

  return normalised.startsWith('javascript:') ||
      normalised.startsWith('vbscript:');
}

/// [value] as a destination an element may point at.
///
/// A script url becomes `#`, which keeps the element a link with a destination that does
/// nothing rather than dropping the attribute and quietly changing the markup.
String safeUrlValue(String value) => isRiskyUrl(value) ? '#' : value;
