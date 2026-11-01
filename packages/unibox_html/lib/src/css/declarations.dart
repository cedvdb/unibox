/// A list of CSS declarations, in the order they were written.
///
/// A list and not a `Map`, for two reasons the format itself gives. CSS allows a
/// property to be written twice — a fallback, or a value a browser that does not
/// understand the second one keeps — and a map would silently drop the first. And
/// the order the declarations were added in is part of what a reader sees, while a
/// map's order is an accident of how a renderer happened to build it.
///
/// [text] is the canonical spelling of the list, which is what makes the class name
/// of a look the same on a server and in a browser, and in two renderers that agree
/// on the model.
final class CssDeclarations {
  /// Creates an empty list.
  CssDeclarations();

  /// Creates a list holding [declarations], in their map order.
  CssDeclarations.of(Map<String, String> declarations) {
    addAll(declarations);
  }

  final List<MapEntry<String, String>> _entries = <MapEntry<String, String>>[];

  /// The canonical text of the list, built the first time it is asked for.
  ///
  /// Every box and every field asks for it to hash a class name, and the stylesheet asks
  /// again for the rule it writes; a page with thousands of nodes asks thousands of times,
  /// and sorting and joining thirty declarations per ask is work nobody sees.
  String? _text;

  /// Whether nothing is declared at all.
  bool get isEmpty => _entries.isEmpty;

  /// Whether at least one declaration is there.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// How many declarations the list holds, duplicates included.
  int get length => _entries.length;

  /// Whether [property] is declared at least once.
  bool has(String property) =>
      _entries.any((MapEntry<String, String> entry) => entry.key == property);

  /// The last value written for [property], or `null` when it is not declared.
  ///
  /// The last one, because that is the one a browser applies.
  String? operator [](String property) {
    for (int i = _entries.length - 1; i >= 0; i--) {
      if (_entries[i].key == property) {
        return _entries[i].value;
      }
    }

    return null;
  }

  /// Appends `property: value`.
  ///
  /// A second write of the same property is kept: it is a fallback, not a mistake.
  void add(String property, String value) {
    _entries.add(MapEntry<String, String>(property, value));
    _text = null;
  }

  /// Appends every declaration of [declarations], in their map order.
  void addAll(Map<String, String> declarations) {
    for (final MapEntry<String, String> entry in declarations.entries) {
      _entries.add(entry);
    }

    _text = null;
  }

  /// Appends every declaration of [other], in its order.
  ///
  /// A duplicate stays a duplicate, so combining two lists behaves the way a browser
  /// reading the result does.
  void addAllIn(CssDeclarations other) {
    for (final MapEntry<String, String> entry in other._entries) {
      _entries.add(entry);
    }

    _text = null;
  }

  /// Appends `property: value` unless [value] is `null`.
  ///
  /// A token the model leaves unset writes nothing at all, so a renderer that walks
  /// its tokens says so once per token instead of wrapping each in an `if`.
  void addIf(String property, String? value) {
    if (value != null) {
      add(property, value);
    }
  }

  /// The declarations as the text of a rule, or of a `style` attribute.
  ///
  /// Sorted by property name, and by insertion order when one property is written
  /// more than once, so the same look always produces the same text — and therefore
  /// the same class name — however the renderer built the list.
  ///
  /// Built once and kept: a list that is added to after it was asked for starts again, so
  /// a caller sees the text of the whole list either way.
  String get text => _text ??= _compose();

  String _compose() {
    final List<({int index, MapEntry<String, String> entry})> ordered =
        <({int index, MapEntry<String, String> entry})>[
          for (int i = 0; i < _entries.length; i++)
            (index: i, entry: _entries[i]),
        ];

    ordered.sort((
      ({int index, MapEntry<String, String> entry}) a,
      ({int index, MapEntry<String, String> entry}) b,
    ) {
      final int byProperty = a.entry.key.compareTo(b.entry.key);

      return byProperty != 0 ? byProperty : a.index.compareTo(b.index);
    });

    return ordered
        .map(
          (({int index, MapEntry<String, String> entry}) pair) =>
              '${pair.entry.key}:${pair.entry.value}',
        )
        .join(';');
  }

  @override
  String toString() => _entries.isEmpty ? 'CssDeclarations()' : text;
}

/// A stable eight character hash of [value] (FNV-1a).
///
/// Tiny, deterministic and dependency free, so a class name is the same on a server and
/// in a browser without any coordination — and the same in two renderers that agree on
/// the declarations.
String fnv1a(String value) {
  var hash = 0x811C9DC5;

  for (final int codeUnit in value.codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0xFFFFFFFF;
  }

  return hash.toRadixString(16).padLeft(8, '0');
}

/// The class a look wears: `unibox-box-1f3c9a7b`.
///
/// [kind] only names the class, so an inspector says what an element is; the
/// deduplication is the declarations', so six listings with one look cost one rule. The
/// hash covers the kind as well, so a box and a text that happened to declare the same
/// thing still get a class of their own.
String classNameFor(String kind, String declarations) =>
    'unibox-$kind-${fnv1a('$kind|$declarations')}';
