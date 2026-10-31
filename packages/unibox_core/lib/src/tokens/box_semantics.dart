/// The role a box plays for assistive technologies.
///
/// The roles are the ones both a screen reader and a browser expose, so a box
/// renders as a `Semantics` node in Flutter and as a `role` attribute on the
/// web. A role is also the opt in for keyboard focus: a box with a role the
/// user can act on becomes focusable, a box without one stays a plain
/// container and never lands in the tab order.
enum BoxRole {
  /// A plain container, the default.
  none,

  /// Something the user can press.
  button,

  /// A checkbox, usually paired with `BoxSemantics.checked`.
  checkbox,

  /// A switch, the on/off sibling of [checkbox].
  ///
  /// Carries a trailing underscore because `switch` is a reserved word.
  switch_,

  /// A link the tree cannot name a destination for: a control whose press is a
  /// callback, such as an icon the host opens a page from. A box with a `url` needs
  /// no role — the anchor is the role — and writing one is dropped.
  link,

  /// A heading; structural, so it is not focusable.
  heading,

  /// One tab of a [tablist]: the only role whose meaning is a set's.
  ///
  /// A screen reader announces which of the set is chosen, which is
  /// [BoxSemantics.selected] and `aria-selected` on the web, and Flutter has the same role for it.
  /// The keys that move between tabs belong to the set, not to this box.
  tab,

  /// The set a group of [tab] boxes belongs to.
  ///
  /// Structural: a container, so it is not focusable and takes no press.
  tablist;

  /// Whether the role is something the user can act on.
  ///
  /// Those roles make a box keyboard focusable, [heading] and [none] do not.
  bool get isInteractive =>
      this == button ||
      this == checkbox ||
      this == switch_ ||
      this == link ||
      this == tab;
}

/// Which item of a set a box currently is, for a navigation.
///
/// The three values are the ones ARIA allows for `aria-current` and that mean
/// something in an interface: the page the reader is on, the step of a flow, and
/// the place in a map or a list. `null` — no value at all — means the box is not
/// the current one.
///
/// Flutter has no `aria-current`; the closest thing it can say is that this box is
/// the selected item of a set, which is what a screen reader on a phone announces.
/// The web says precisely which kind of current it is.
enum BoxCurrent {
  /// The page being displayed.
  page,

  /// The step of a process being displayed.
  step,

  /// The location being displayed, in a map or a list of places.
  location,
}

/// The element a box becomes on the web.
///
/// A box is a `div` unless it says otherwise. The elements here are the ones that
/// give a page structure rather than a look — the landmarks (`main`, `nav`,
/// `header`, `footer`), the sectioning content of HTML (`section`, `article`,
/// `aside`, `figure`, `form`) and the list pair — so a tree can describe a
/// document instead of a pile of layers.
///
/// The two targets are not equally expressive here, which is the reason this is a
/// semantics token and not a style one: the web renderer emits the tag itself, and
/// Flutter has no landmark concept at all (its screen readers work from headings
/// and reading order). The three elements Flutter does have a role for become a
/// `SemanticsRole`, and the rest stay a plain container there, so a landmark is
/// structure a browser gets and a Flutter screen reader does not need.
enum BoxElement {
  /// A plain container, the default.
  div,

  /// The main content of the page: one per document, not inside another landmark.
  main,

  /// A navigation region.
  nav,

  /// The header of the page or of a section.
  header,

  /// The footer of the page or of a section.
  footer,

  /// Content beside the main content, which still makes sense on its own.
  aside,

  /// A section of related content, usually with a heading.
  section,

  /// A self contained composition, such as a card or a post.
  article,

  /// A form, as a landmark for assistive technologies.
  form,

  /// A picture with its caption; the renderer cancels the user agent margin.
  figure,

  /// An unordered list.
  ul,

  /// An ordered list.
  ol,

  /// One item of a [ul] or an [ol]; anywhere else it is invalid HTML and
  /// `validateTree` reports it.
  li,

  /// The caption of a [figure]: the line that describes it, which a screen reader
  /// reads out as the figure's name. Anywhere outside a figure it is invalid HTML
  /// and `validateTree` reports it.
  figcaption,

  /// An anchor: a link, whether or not the box names a destination.
  ///
  /// `url` makes the element one without asking, because a `href` on anything else is
  /// not a link at all. Stating it explicitly is what writes an `<a>` with no `href` — a
  /// placeholder, which a browser paints as text and no reader can follow — and it is the
  /// token that `url` and this enum have to agree about: a box that says it is an
  /// `article` *and* names a destination is reported, because one tag is written.
  a;

  /// Whether the element is a landmark of the page.
  ///
  /// Landmarks are what a screen reader lets a reader jump between.
  bool get isLandmark =>
      this == main || this == nav || this == header || this == footer;
}

/// The accessibility description of a box.
///
/// A box without semantics is a plain container: screen readers announce its
/// content and nothing else. Adding semantics is how a hand drawn control
/// becomes a real button, checkbox or link for a keyboard and a screen reader.
///
/// ```dart
/// const Button = Box(
///   onTap: submit,
///   semantics: BoxSemantics(role: BoxRole.button, label: 'Create account'),
/// );
///
/// const Page = Box(
///   direction: Axis.vertical,
///   semantics: BoxSemantics(element: BoxElement.main),
/// );
/// ```
final class BoxSemantics {
  /// Creates a description for a box.
  const BoxSemantics({
    this.role = BoxRole.none,
    this.element = BoxElement.div,
    this.label,
    this.checked,
    this.expanded,
    this.selected,
    this.pressed,
    this.hidden = false,
    this.liveRegion = false,
    this.current,
  });

  /// What the box means to assistive technologies.
  final BoxRole role;

  /// The text a screen reader announces instead of the contents.
  ///
  /// Leave it `null` when the contents already say what the box does, so the
  /// label and the visible text cannot drift apart.
  final String? label;

  /// The element the box is on the web, [BoxElement.div] by default.
  ///
  /// This is how a tree describes a page: `main` for what the page is about,
  /// `nav` for the links, `ul` and `li` for a list. Flutter has no counterpart for
  /// a landmark, so the element is structure the web gets and the Flutter tree
  /// does not need; the state tokens below are where both targets agree.
  final BoxElement element;

  /// Whether a checkbox or a switch is on.
  final bool? checked;

  /// Whether the control this box is shows its content, as a disclosure does.
  final bool? expanded;

  /// Whether the item this box is is the selected one of a set, as a tab is.
  final bool? selected;

  /// Whether this box is a toggle button that is on, as a filter chip is.
  ///
  /// It is [selected]'s sibling for the one control the two are not
  /// interchangeable on: `aria-selected` belongs to an *option*, a tab, a row or a
  /// grid cell, so a browser ignores it on a `button` — which is what a chip and a
  /// segment are. A toggle button states its own state with `aria-pressed`, and
  /// Flutter announces the same thing as `toggled`, so a chosen chip says "pressed"
  /// on both targets instead of saying nothing on the web.
  ///
  /// It belongs with [BoxRole.button]; the state is the button's, not the
  /// container's.
  final bool? pressed;

  /// Whether the box is hidden from assistive technologies.
  ///
  /// The content still paints: this hides a box from a screen reader and from the
  /// reading order, and takes it out of the tab order, which is what a decorative
  /// duplicate or a purely visual flourish needs. It is not `display: none` and
  /// it does not remove the box from the layout.
  final bool hidden;

  /// Whether a screen reader should announce a change of this box.
  ///
  /// A live region is how a form tells a reader that a field is invalid without
  /// moving the focus there.
  final bool liveRegion;

  /// Which item of a set this box currently is, or `null` for none.
  ///
  /// This is what tells a reader that the nav item it just read is the page it is
  /// on: `aria-current` on the web, the selected state of a set in Flutter.
  final BoxCurrent? current;

  /// Whether a box with this description takes keyboard focus.
  ///
  /// A hidden box never does: a control that a screen reader cannot see must not
  /// be reachable with the keyboard either, or the reader lands on something no
  /// assistive technology can name. Both renderers read this, so the tab order and
  /// the accessibility tree stay in step.
  bool get isFocusable => role.isInteractive && !hidden;

  /// Creates a copy of this description with the given fields replaced.
  BoxSemantics copyWith({
    BoxRole? role,
    BoxElement? element,
    String? label,
    bool? checked,
    bool? expanded,
    bool? selected,
    bool? pressed,
    bool? hidden,
    bool? liveRegion,
    BoxCurrent? current,
  }) {
    return BoxSemantics(
      role: role ?? this.role,
      element: element ?? this.element,
      label: label ?? this.label,
      checked: checked ?? this.checked,
      expanded: expanded ?? this.expanded,
      selected: selected ?? this.selected,
      pressed: pressed ?? this.pressed,
      hidden: hidden ?? this.hidden,
      liveRegion: liveRegion ?? this.liveRegion,
      current: current ?? this.current,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BoxSemantics &&
      other.role == role &&
      other.element == element &&
      other.label == label &&
      other.checked == checked &&
      other.expanded == expanded &&
      other.selected == selected &&
      other.pressed == pressed &&
      other.hidden == hidden &&
      other.liveRegion == liveRegion &&
      other.current == current;

  @override
  int get hashCode => Object.hash(
    role,
    element,
    label,
    checked,
    expanded,
    selected,
    pressed,
    hidden,
    liveRegion,
    current,
  );

  @override
  String toString() {
    final fields = <String>[
      'role: $role',
      if (element != BoxElement.div) 'element: $element',
      if (label != null) 'label: $label',
      if (checked != null) 'checked: $checked',
      if (expanded != null) 'expanded: $expanded',
      if (selected != null) 'selected: $selected',
      if (pressed != null) 'pressed: $pressed',
      if (hidden) 'hidden: $hidden',
      if (liveRegion) 'liveRegion: $liveRegion',
      if (current != null) 'current: $current',
    ];
    return 'BoxSemantics(${fields.join(', ')})';
  }
}
