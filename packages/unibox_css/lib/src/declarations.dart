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
  }

  /// Appends every declaration of [declarations], in their map order.
  void addAll(Map<String, String> declarations) {
    for (final MapEntry<String, String> entry in declarations.entries) {
      _entries.add(entry);
    }
  }

  /// Appends every declaration of [other], in its order.
  ///
  /// A duplicate stays a duplicate, so combining two lists behaves the way a browser
  /// reading the result does.
  void addAllIn(CssDeclarations other) {
    for (final MapEntry<String, String> entry in other._entries) {
      _entries.add(entry);
    }
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
  String get text {
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
