import 'enums.dart';
import 'nodes/box.dart';
import 'nodes/embed_node.dart';
import 'nodes/grid_node.dart';
import 'nodes/image_node.dart';
import 'nodes/link_node.dart';
import 'nodes/overlay_node.dart';
import 'nodes/positioned_node.dart';
import 'nodes/stack_node.dart';
import 'nodes/text_node.dart';
import 'nodes/ui_node.dart';
import 'tokens/box_border.dart';
import 'tokens/box_color.dart';
import 'tokens/box_semantics.dart';
import 'tokens/box_shadow.dart';
import 'tokens/box_shape.dart';
import 'tokens/box_style.dart';
import 'tokens/box_text_style.dart';
import 'tokens/box_transition.dart';
import 'tokens/unibox_theme.dart';

/// How much a [TreeIssue] matters.
enum TreeIssueSeverity {
  /// The tree still renders, but not as described: an offset is dropped, a
  /// child cannot be reached.
  warning,

  /// At least one target cannot render the tree faithfully.
  error,
}

/// A problem in a node tree that no renderer can compensate for.
///
/// Issues point at the node that caused them and explain how to fix the tree,
/// so a warning printed in debug mode is enough to locate it.
class TreeIssue {
  /// Creates an issue for [node].
  const TreeIssue({
    required this.node,
    required this.message,
    this.severity = TreeIssueSeverity.warning,
  });

  /// The node the issue belongs to.
  final UINode node;

  /// What is wrong and how to fix it.
  final String message;

  /// How much the issue matters.
  final TreeIssueSeverity severity;

  /// Whether this issue is an [TreeIssueSeverity.error].
  bool get isError => severity == TreeIssueSeverity.error;

  @override
  String toString() => message;
}

/// Checks the tree rooted at [root] for constructs that do not survive
/// rendering.
///
/// The checks are pure and cheap, so both renderers run them inside an
/// assertion: a broken tree is reported in debug builds and costs nothing in
/// release builds. Call it directly to lint a tree in a test or a command line
/// tool.
///
/// Detected issues:
/// * a [PositionedNode] whose parent is not a [StackNode], which silently drops
///   its offsets,
/// * a [LinkNode] nested inside another [LinkNode], which is invalid HTML and
///   navigates twice,
/// * a box that scrolls along its main axis while distributing its children
///   with [Box.mainAlign], which pushes overflowing children out of reach,
/// * a box that aligns on the baseline without a row to align, where the two
///   targets lay the children out differently,
/// * an aspect ratio that cannot divide anything — a ratio next to a width and a
///   height, or one that is not positive,
/// * a list item whose parent is not a list, and a caption whose parent is not a
///   figure, both of which are invalid HTML and name nothing where they stand,
/// * a grid span on a box that is not a grid child, and a span no track can hold,
/// * an embed that carries no implementation at all, which no renderer can draw
///   and which would otherwise vanish from the page,
/// * a transition declared on a state style instead of the resting one, which no
///   renderer applies,
/// * a transition with a duration that changes nothing,
/// * an opacity outside the `0` to `1` that both targets accept,
/// * a colour role no theme can answer, when a theme is passed to the check,
/// * a decoration colour or thickness on a style that draws no decoration, and a
///   thickness no line can be drawn with,
/// * a visibility range that is empty or negative, which no width can show,
/// * an image candidate whose width is not positive, which no browser can pick,
/// * an image that gives `sizes` without a `srcSet`, which a browser never reads.
List<TreeIssue> validateTree(UINode root, {UniboxTheme? theme}) {
  final List<TreeIssue> issues = <TreeIssue>[];
  _validate(
    root,
    parent: null,
    inLink: false,
    theme: theme,
    inGrid: false,
    definiteHeight: null,
    decoratedAbove: false,
    issues: issues,
  );
  return issues;
}

/// Records a colour role [node] names that no theme can answer.
///
/// A role is only resolvable by the theme the renderer was given, so this is the
/// one check that needs an argument: without it a role is a tree the renderer
/// cannot paint, and with one the role has to be a member the theme defines.
void _validateRoles(UINode node, UniboxTheme? theme, List<TreeIssue> issues) {
  for (final BoxColor color in _roleColorsOf(node)) {
    final Enum? role = color.role;

    if (role == null) {
      continue;
    }

    if (theme == null) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A ${node.runtimeType} names the colour role $role, but no theme '
              'was given. Pass a UniboxTheme to the renderer and to this check.',
        ),
      );
      continue;
    }

    if (theme.colorOf(role) == null) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'The colour role $role is not in the theme, so a '
              '${node.runtimeType} would have no colour. Add it to '
              'UniboxTheme.colors.',
        ),
      );
    }
  }
}

/// Every colour [node] names, roles and values alike.
Iterable<BoxColor> _roleColorsOf(UINode node) {
  final List<BoxColor> colors = <BoxColor>[];

  void addStyle(BoxStyle style) {
    final BoxColor? background = style.backgroundColor;
    final BoxBorder? border = style.border;
    final List<BoxShadow>? shadows = style.shadows;
    final BoxTextStyle? typography = style.textStyle;
    final BoxColor? text = typography?.color;
    final BoxColor? line = typography?.decorationColor;

    if (background != null) colors.add(background);
    if (border != null) colors.add(border.color);
    if (shadows != null) {
      colors.addAll(shadows.map((BoxShadow shadow) => shadow.color));
    }
    if (text != null) colors.add(text);
    if (line != null) colors.add(line);
  }

  if (node is Box) {
    addStyle(node.computedStyle);

    for (final BoxStyle style
        in node.stateStyles?.values ?? const <BoxStyle>[]) {
      addStyle(style);
    }
  } else if (node is TextNode) {
    final BoxColor? color = node.computedStyle.color;
    final BoxColor? line = node.computedStyle.decorationColor;

    if (color != null) {
      colors.add(color);
    }

    if (line != null) {
      colors.add(line);
    }
  }

  return colors.where((BoxColor color) => color.isRole);
}

/// Records the decoration tokens of [style] that cannot draw a line on [node].
///
/// A decoration colour or a thickness on its own says how a line would look
/// without saying there is one, so no renderer draws anything; a thickness of
/// zero or less is not a line either — CSS rejects the length and falls back to
/// the font's own, while Flutter asserts. Neither is a difference a rendering can
/// show, so both are reported instead.
void _validateDecoration(
  UINode node,
  BoxTextStyle style, {
  required bool decoratedAbove,
  required List<TreeIssue> issues,
}) {
  final TextDecoration? decoration = style.decoration;
  final double? thickness = style.decorationThickness;

  if (decoration == null) {
    final List<String> tokens = <String>[
      if (style.decorationColor != null) 'a decoration color',
      if (thickness != null) 'a decoration thickness',
    ];

    if (tokens.isNotEmpty) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A ${node.runtimeType} states ${tokens.join(' and ')} without a '
              'decoration, so no line is drawn and the tokens do nothing. Name '
              'the line — TextDecoration.none, lineThrough or underline — or '
              'drop them.',
        ),
      );
    }

    return;
  }

  // A box's line reaches every text inside it on the web, and a descendant can
  // add a line to it but never remove one; in Flutter the inner style simply
  // replaces the outer. A tree that states a line twice would therefore be drawn
  // two different ways, so it is reported instead of painted.
  if (decoratedAbove) {
    issues.add(
      TreeIssue(
        node: node,
        severity: TreeIssueSeverity.error,
        message:
            'A ${node.runtimeType} states decoration: $decoration inside a box '
            'that already draws one. CSS propagates the line of a box to every '
            'text inside it and lets a descendant only add to it, so the web '
            'would draw both and Flutter only the inner one. State the line '
            'once — on the box that holds the run, or on the run itself.',
      ),
    );
  }

  if (thickness != null && thickness <= 0) {
    issues.add(
      TreeIssue(
        node: node,
        severity: TreeIssueSeverity.error,
        message:
            'A decoration $thickness thick cannot be drawn: a line is a length '
            'more than zero. Leave decorationThickness unset for the thickness '
            'the font asks for.',
      ),
    );
  }
}

/// Walks [node] and records every issue of the subtree into [issues].
void _validate(
  UINode node, {
  required UINode? parent,
  required bool inLink,
  required UniboxTheme? theme,
  required bool inGrid,
  required double? definiteHeight,
  required bool decoratedAbove,
  required List<TreeIssue> issues,
}) {
  _validateRoles(node, theme, issues);

  if (node is PositionedNode &&
      node.alignment != null &&
      (node.top != null ||
          node.right != null ||
          node.bottom != null ||
          node.left != null)) {
    issues.add(
      TreeIssue(
        node: node,
        message:
            'A PositionedNode is placed by an alignment or by offsets, not by both: '
            'the child fills the stack when it is aligned, so an offset has nothing '
            'left to move.',
      ),
    );
  }

  if (node is PositionedNode && parent is! StackNode) {
    issues.add(
      TreeIssue(
        node: node,
        message:
            'A PositionedNode is only placed by a StackNode, but its parent is '
            '${parent?.runtimeType ?? 'the root'}. Its offsets are ignored and '
            'the child renders at its natural position.',
      ),
    );
  }

  if (node is Box) {
    final BoxStyle style = node.computedStyle;

    // A snap on a box that cannot scroll is a token that can do nothing: the renderers
    // write it and no gesture ever reads it.
    if (style.snap != null &&
        style.snap != ScrollSnap.none &&
        style.overflow != Overflow.scroll) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A box snaps (snap: ScrollSnap.${style.snap!.name}) without '
              'overflow: Overflow.scroll, so nothing scrolls and nothing settles. '
              'Set overflow, or drop the snap.',
        ),
      );
    }

    // A page is a position in a pager, so it needs one: a box that settles nowhere has no pages to
    // be on, and a reader's swipe is the only thing that could have moved it.
    if (style.page != null && style.snap != ScrollSnap.page) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A box states page: ${style.page} without snap: ScrollSnap.page, so '
              'nothing tells it where its pages begin. Set the snap, or drop the page.',
        ),
      );
    }

    if (style.page != null && style.page! < 0) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A box states page: ${style.page}, and a page cannot be before the '
              'first one.',
        ),
      );
    }

    // A span is a statement about the grid around the box: outside one there are no
    // tracks, so the token can only do nothing.
    final int? gridSpan = style.gridSpan;

    if (gridSpan != null && gridSpan < 1) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A box states gridSpan: $gridSpan, and a cell is one track or more. '
              'Use 1 for the ordinary case, or a larger number for a card that '
              'interrupts the row.',
        ),
      );
    } else if (gridSpan != null && parent is! GridNode) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A box states gridSpan: $gridSpan but its parent is '
              '${parent?.runtimeType ?? 'the root'}, so there is no grid to span. '
              'Put the box in a GridNode, or drop the span.',
        ),
      );
    }

    // A ratio divides one side by the other, so it needs one side to divide. A box
    // that states both has already answered, and the ratio would be a third statement
    // about a box that has two.
    final double? aspectRatio = style.aspectRatio;

    if (aspectRatio != null) {
      final bool dividesAWidth =
          style.width != null || style.widthFraction != null;
      final bool dividesAHeight =
          style.height != null || style.heightFraction != null;

      if (aspectRatio <= 0) {
        issues.add(
          TreeIssue(
            node: node,
            severity: TreeIssueSeverity.error,
            message:
                'A box states aspectRatio: $aspectRatio, and a ratio is one '
                'positive number divided by another: `1.5` is three across for '
                'every two down. Use a positive ratio, or leave it out.',
          ),
        );
      } else if (dividesAWidth && dividesAHeight) {
        issues.add(
          TreeIssue(
            node: node,
            message:
                'A box states aspectRatio: $aspectRatio as well as a width and a '
                'height, so the ratio has nothing left to decide: both targets '
                'keep the two sizes and ignore it. Drop the ratio, or drop one '
                'of the two sides.',
          ),
        );
      }
    }

    if (style.borderRadius != null && style.corners != null) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A box declares both borderRadius and corners, and a box has one '
              'shape: keep corners when the four differ.',
        ),
      );
    }

    final BoxShape? shape = style.shape;

    if (shape != null) {
      if (style.borderRadius != null || style.corners != null) {
        issues.add(
          TreeIssue(
            node: node,
            message:
                'A box declares both a shape and a corner radius, and a box has '
                'one outline: a shape is the outline, so drop borderRadius and '
                'corners.',
          ),
        );
      }

      if (style.shadows?.isNotEmpty ?? false) {
        issues.add(
          TreeIssue(
            node: node,
            message:
                'A shaped box cannot cast a shadow: the model has no shadow of a '
                'shape. Put the shadow on the box around it.',
          ),
        );
      }

      if (shape.isEmpty) {
        issues.add(
          TreeIssue(
            node: node,
            message: 'A shape with no command paints nothing: give it at least a move.',
          ),
        );
      }

      if (shape.viewBoxWidth <= 0 || shape.viewBoxHeight <= 0) {
        issues.add(
          TreeIssue(
            node: node,
            message:
                'A shape is drawn in a ${shape.viewBoxWidth} by '
                '${shape.viewBoxHeight} view box, and both sides have to be more '
                'than zero for the outline to have a size.',
          ),
        );
      }
    }

    // A cap is where an outline ends, which only a shape has: a rectangle's border
    // meets itself at four corners and no target paints a cap there.
    final BoxBorder? border = style.border;

    if (shape == null && border != null && border.cap != BoxStrokeCap.butt) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A border cap is drawn where an outline has ends, and a rectangular '
              'border has none: give the box a shape, or leave the cap at butt.',
        ),
      );
    }

    for (final double radius in style.corners?.radii ?? const <double>[]) {
      if (radius >= 0) continue;

      issues.add(
        TreeIssue(
          node: node,
          message:
              'A corner radius of $radius cannot be drawn: a corner is round by a '
              'length that is zero or more.',
        ),
      );
    }

    final double? from = style.visibleFrom;
    final double? until = style.visibleUntil;

    if ((from != null && from < 0) || (until != null && until < 0)) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A Box declares a visibility threshold below zero, which no width '
              'can satisfy. Thresholds are logical pixels.',
        ),
      );
    }

    if (!style.isVisibleEverywhere && parent is! Box) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A Box names a width threshold but is not inside another box, so '
              'there is no layout box for it to measure. Put it in the box whose '
              'width decides whether it is drawn.',
        ),
      );
    }

    if (from != null && until != null && from >= until) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A Box is drawn from $from up to $until, which is empty: the range '
              'is half open, so visibleFrom has to be smaller than visibleUntil.',
        ),
      );
    }
  }

  if (node is TextNode || node is Box) {
    final BoxTextStyle? typography = switch (node) {
      final TextNode text => text.computedStyle,
      final Box box => box.computedStyle.textStyle,
      _ => null,
    };

    if (typography != null) {
      _validateDecoration(
        node,
        typography,
        decoratedAbove: decoratedAbove,
        issues: issues,
      );
    }
  }

  if (node is ImageNode) {
    for (final int width in node.srcSet.keys) {
      if (width <= 0) {
        issues.add(
          TreeIssue(
            node: node,
            severity: TreeIssueSeverity.error,
            message:
                'An ImageNode srcSet entry names a width of $width. A browser '
                'picks a candidate by the width it declares, so every entry '
                'needs a positive one.',
          ),
        );
      }
    }

    if (inGrid) {
      final double? height = node.height;
      final bool ownHeight = height != null && height.isFinite;
      final bool determinedAbove = definiteHeight != null;

      if (!ownHeight && !determinedAbove) {
        issues.add(
          TreeIssue(
            node: node,
            severity: TreeIssueSeverity.error,
            message:
                'An ImageNode inside a GridNode needs a height that is known '
                'before the file arrives: a finite height, both dimensions, or '
                'an ancestor with a definite height (a fixed-height box, and a '
                'ratio box once the model has one). Otherwise the height of its '
                'row depends on the loaded image, and the two targets reserve '
                'different space while the columns change.',
          ),
        );
      }
    }

    if (node.srcSet.isEmpty && node.sizes != null) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'An ImageNode declares sizes without a srcSet. A browser reads '
              'the layout width only to choose between candidates, so this one '
              'names nothing: give the node a srcSet, or drop the sizes.',
        ),
      );
    }
  }

  if (node is GridNode) {
    if (node.minItemWidth <= 0) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A GridNode declares a minItemWidth of ${node.minItemWidth}. '
              'No column can be that narrow, so the count is undefined: give '
              'the grid a positive minimum.',
        ),
      );
    }

    if (node.gap < 0) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A GridNode declares a gap of ${node.gap}. A negative gutter '
              'overlaps the cards and neither target can honour it.',
        ),
      );
    }

    if (node.maxColumns != null && node.maxColumns! < 1) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A GridNode declares maxColumns: ${node.maxColumns}. A grid with '
              'no columns draws nothing: use null for no cap or at least 1.',
        ),
      );
    }

    for (final UINode child in node.children) {
      if (child is! Box) {
        continue;
      }

      final BoxStyle style = child.computedStyle;

      if (style.flex != null) {
        issues.add(
          TreeIssue(
            node: child,
            severity: TreeIssueSeverity.error,
            message:
                'A box inside a GridNode declares flex: ${style.flex}. The '
                'track fixes the width, and a flexing child would stretch the '
                'empty slots of a short last row in Flutter and not in CSS.',
          ),
        );
      }

      final double? width = style.width;

      if (width != null && width.isFinite) {
        issues.add(
          TreeIssue(
            node: child,
            severity: TreeIssueSeverity.error,
            message:
                'A box inside a GridNode declares a width of $width. The track '
                'fixes the width of every card, and a tight cell in Flutter '
                'would ignore this number where CSS would honour it. Give the '
                'grid a minItemWidth instead.',
          ),
        );
      }

      if (style.height == double.infinity) {
        issues.add(
          TreeIssue(
            node: child,
            severity: TreeIssueSeverity.error,
            message:
                'A box inside a GridNode declares height: double.infinity. The '
                'row is as tall as its tallest card, so an infinite height has '
                'nothing to resolve against: give the card a finite height, or '
                'none.',
          ),
        );
      }
    }
  }

  if (node is OverlayNode &&
      node.barrierDismissible &&
      node.onDismiss == null) {
    issues.add(
      TreeIssue(
        node: node,
        message:
            'An OverlayNode with a dismissible barrier has no onDismiss, so the '
            'barrier cannot dismiss anything. Give the node an onDismiss, or set '
            'barrierDismissible to false.',
      ),
    );
  }

  var nestedInLink = inLink;

  if (node is LinkNode) {
    if (inLink) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A LinkNode cannot contain another LinkNode: HTML forbids nested '
              '<a> elements, and the double navigation is not something either '
              'target can undo. Move the inner link out of the outer one.',
        ),
      );
    }
    nestedInLink = true;
  }

  if (node is Box) {
    final BoxStyle style = node.computedStyle;
    final MainAlign? mainAlign = style.mainAlign;

    if (style.overflow == Overflow.scroll &&
        mainAlign != null &&
        mainAlign != MainAlign.start) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A box that scrolls along its main axis cannot distribute its '
              'children with mainAlign: ${mainAlign.name}. The children that '
              'overflow are pushed out of reach in CSS and out of the viewport '
              'in Flutter. Use MainAlign.start and let the children scroll.',
        ),
      );
    }

    // A baseline is a horizontal line, so it aligns the children of a row and
    // describes nothing about a column: Flutter lays a column out as if the value
    // were `start`, while a browser shifts the children sideways to line their
    // baselines up. The same tree would then be laid out two ways.
    if (style.crossAlign == CrossAlign.baseline &&
        style.resolvedDirection != Axis.horizontal) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A box aligns its children on the baseline (crossAlign: '
              'CrossAlign.baseline) without direction: Axis.horizontal. Only a '
              'row has a baseline, because a baseline is a horizontal line: '
              'Flutter treats the value as start on a column and a browser '
              'aligns the children sideways. Set the direction, or align on an '
              'edge.',
        ),
      );
    }

    // A wrap breaks the children into lines, and neither target does anything else the
    // flex layout used to do across the whole box: `stretch` and `baseline` are stated per
    // line by a browser and not at all by a Flutter `Wrap`, and a wrapping box cannot
    // scroll along the axis its lines occupy.
    if (style.wrap ?? false) {
      final CrossAlign? crossAlignForWrap = style.crossAlign;

      if (crossAlignForWrap == CrossAlign.stretch ||
          crossAlignForWrap == CrossAlign.baseline) {
        issues.add(
          TreeIssue(
            node: node,
            severity: TreeIssueSeverity.error,
            message:
                'A box that wraps its children (wrap: true) cannot align them '
                'with crossAlign: CrossAlign.${crossAlignForWrap!.name}: a '
                'browser stretches or aligns the children of one line, while a '
                'Flutter `Wrap` only starts, centres or ends them. Use start, '
                'center or end.',
          ),
        );
      }

      if (style.overflow == Overflow.scroll) {
        issues.add(
          TreeIssue(
            node: node,
            severity: TreeIssueSeverity.error,
            message:
                'A box both wraps its children and scrolls along its main axis. '
                'A browser wraps them inside the box, and Flutter hands a '
                'wrapping box in a scroll view all the width it asks for, so it '
                'never wraps and scrolls instead. Keep one of the two.',
          ),
        );
      }
    }

    // A wrapping box is the one flex container whose children cannot share it: a
    // `Wrap` lays every child out at its own size, so `flex` grows nothing on one
    // target, and CSS grows the child across its line.
    if (parent is Box &&
        (parent.computedStyle.wrap ?? false) &&
        (style.flex ?? 0) > 0) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A box inside a wrapping box (wrap: true) states flex: '
              '${style.flex}, and nothing can share a line that has not been '
              'measured yet: a browser grows the child across its line and '
              "Flutter's `Wrap` lays it out at its own size. Give the box a "
              'width, or take it out of the wrap.',
        ),
      );
    }
  }

  if (node is Box && node.semantics?.element == BoxElement.figcaption) {
    final BoxElement? parentElement = parent is Box
        ? parent.semantics?.element
        : null;

    if (parentElement != BoxElement.figure) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A box with BoxElement.figcaption has to be a child of a box with '
              'BoxElement.figure, but its parent is '
              '${parent?.runtimeType ?? 'the root'}. A <figcaption> anywhere else '
              'is invalid HTML and names nothing.',
        ),
      );
    }
  }

  if (node is Box && node.semantics?.element == BoxElement.li) {
    final BoxElement? parentElement = parent is Box
        ? parent.semantics?.element
        : null;

    if (parentElement != BoxElement.ul && parentElement != BoxElement.ol) {
      issues.add(
        TreeIssue(
          node: node,
          severity: TreeIssueSeverity.error,
          message:
              'A box with BoxElement.li has to be a child of a box with '
              'BoxElement.ul or BoxElement.ol, but its parent is '
              '${parent?.runtimeType ?? 'the root'}. An <li> anywhere else is '
              'invalid HTML and is not announced as an item of a list.',
        ),
      );
    }
  }

  if (node is Box) {
    final BoxTransition? transition = node.computedStyle.transition;
    final double? opacity = node.computedStyle.opacity;

    if (opacity != null && (opacity < 0 || opacity > 1)) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A box declares an opacity of $opacity, which is outside the 0 to 1 '
              'range both targets accept. Below 0 paints nothing visible and '
              'above 1 is the same as solid.',
        ),
      );
    }

    for (final TreeIssue issue in _transitionIssues(node, transition)) {
      issues.add(issue);
    }

    if (transition != null && transition.duration <= Duration.zero) {
      issues.add(
        TreeIssue(
          node: node,
          message:
              'A box declares a transition of ${transition.duration}, which '
              'changes nothing: a transition needs a positive duration.',
        ),
      );
    }

    for (final BoxState state in BoxState.values) {
      if (node.stateStyle(state)?.transition != null) {
        issues.add(
          TreeIssue(
            node: node,
            message:
                'A box declares its transition in the ${state.name} style instead '
                'of the resting one, so no renderer applies it: a transition says '
                'how a change eases, and the change belongs to the state, not the '
                'duration.',
          ),
        );
      }
    }
  }

  if (node is EmbedNode && node.implementations.isEmpty) {
    issues.add(
      TreeIssue(
        node: node,
        severity: TreeIssueSeverity.error,
        message:
            'An ${node.runtimeType} carries no implementation, so no renderer can '
            'draw it and every target reports it. Give the node one payload per '
            'renderer that has to render the tree.',
      ),
    );
  }

  var childDefiniteHeight = definiteHeight;

  if (node is Box) {
    final double? height = node.computedStyle.height;

    if (height != null && height.isFinite) {
      childDefiniteHeight = height;
    } else if (height != double.infinity) {
      childDefiniteHeight = null;
    }
  }

  for (final UINode child in node.children) {
    _validate(
      child,
      parent: node,
      inLink: nestedInLink,
      theme: theme,
      inGrid: inGrid || node is GridNode,
      definiteHeight: node is GridNode ? null : childDefiniteHeight,
      decoratedAbove: decoratedAbove || _drawsDecoration(node),
      issues: issues,
    );
  }
}

/// Whether [node] states a line across the text it holds.
///
/// A box states one for the texts inside it, a text for itself; every other node
/// passes what it was given on, because a grid, a stack or a link neither draws
/// text nor undoes a line.
bool _drawsDecoration(UINode node) => switch (node) {
  final TextNode text => text.computedStyle.decoration != null,
  final Box box => box.computedStyle.textStyle?.decoration != null,
  _ => false,
};

/// The issues of the transition parts of [box], if it declares any.
///
/// A part has to name a look, no look may be named twice, and the four things a
/// box paints have to share one timing: a single `BoxDecoration` interpolates as a
/// unit on Flutter, so paint properties that ease at different speeds would need
/// layered decorations — which the tree expresses by nesting a box, and which the
/// renderer must not approximate silently.
List<TreeIssue> _transitionIssues(Box box, BoxTransition? transition) {
  if (transition == null || transition.parts.isEmpty) {
    return const <TreeIssue>[];
  }

  final List<TreeIssue> issues = <TreeIssue>[];
  final Map<BoxProperty, BoxTransitionPart> named =
      <BoxProperty, BoxTransitionPart>{};

  for (final BoxTransitionPart part in transition.parts) {
    if (part.properties.isEmpty) {
      issues.add(
        TreeIssue(
          node: box,
          severity: TreeIssueSeverity.error,
          message:
              'A BoxTransitionPart names no look, so it eases nothing. Name the '
              'looks it should cover, e.g. {BoxProperty.transform}.',
        ),
      );
    }

    if (part.duration <= Duration.zero) {
      issues.add(
        TreeIssue(
          node: box,
          message:
              'A BoxTransitionPart eases ${part.properties.map((BoxProperty l) => l.name)} '
              'over ${part.duration}, which changes nothing.',
        ),
      );
    }

    for (final BoxProperty look in part.properties) {
      if (named.containsKey(look)) {
        issues.add(
          TreeIssue(
            node: box,
            severity: TreeIssueSeverity.error,
            message:
                'Two BoxTransitionParts ease ${look.name}, so it is ambiguous '
                'which one applies. Name each look once.',
          ),
        );
      }
      named[look] = part;
    }
  }

  const Set<BoxProperty> paint = <BoxProperty>{
    BoxProperty.backgroundColor,
    BoxProperty.borderColor,
    BoxProperty.borderRadius,
    BoxProperty.shadows,
  };
  final Set<BoxTransitionTiming> paintTimings = <BoxTransitionTiming>{
    for (final BoxProperty look in paint) transition.timingOf(look),
  };

  if (paintTimings.length > 1) {
    issues.add(
      TreeIssue(
        node: box,
        severity: TreeIssueSeverity.error,
        message:
            'The paint of a box (background, border colour, radius, shadow) eases '
            'as one on Flutter, so its looks have to share a timing. Give them one '
            'part, or nest a box and let each one ease its own paint.',
      ),
    );
  }

  return issues;
}
