import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_html/unibox_html.dart';

void main() {
  group('a text', () {
    test('is a span, so it flows inline like a Flutter Text in a Row', () {
      expect(toHtml(const core.TextNode('Hi')), contains('<span'));
      expect(toHtml(const core.TextNode('Hi')), contains('>Hi</span>'));
    });

    test('is a heading at the level it states', () {
      // A crawler reads structure, not a font size.
      expect(
        toHtml(const core.TextNode('Flats', headingLevel: 1)),
        contains('<h1'),
      );
      expect(
        toHtml(const core.TextNode('Flats', headingLevel: 3)),
        contains('<h3'),
      );
    });

    test('cannot smuggle markup into the page', () {
      expect(
        toHtml(const core.TextNode('<script>alert(1)</script>')),
        contains('&lt;script&gt;'),
      );
    });

    test('carries the name of its node, and its key when it has one', () {
      final String html = toHtml(const core.TextNode('Hi', key: 'greeting'));

      expect(html, contains('data-unibox-node="text"'));
      expect(html, contains('data-unibox-key="greeting"'));
    });
  });

  group('a box', () {
    test('is a flex container with one class for its look', () {
      final String html = toHtml(const core.Box());

      expect(html, contains('<div'));
      expect(html, contains('class="unibox-box-'));
      expect(html, contains('data-unibox-node="box"'));
    });

    test('writes the look once, so six elements cost one rule', () {
      final String html = toHtml(
        const core.Box(
          children: <core.UINode>[
            core.Box(backgroundColor: core.BoxColor.white),
            core.Box(backgroundColor: core.BoxColor.white),
          ],
        ),
      );
      final Iterable<RegExpMatch> classes = RegExp(r'unibox-box-[0-9a-f]{8}')
          .allMatches(html);

      // The two white boxes share a class; the root has its own.
      expect(
        classes.map((RegExpMatch match) => match[0]).toSet(),
        hasLength(2),
      );
    });

    test('renders the element its semantics name', () {
      expect(
        toHtml(
          const core.Box(
            semantics: core.BoxSemantics(element: core.BoxElement.main),
          ),
        ),
        contains('<main'),
      );
    });

    test('writes the role the box asks for, keeping the element it names', () {
      // A `<nav>` is a navigation landmark by itself; `role="link"` is the box saying
      // something else about it.
      final String html = toHtml(
        const core.Box(
          semantics: core.BoxSemantics(
            element: core.BoxElement.nav,
            role: core.BoxRole.link,
          ),
        ),
      );

      expect(html, contains('<nav'));
      expect(html, contains('role="link"'));
    });

    test('announces a disabled box and keeps its layout', () {
      final String html = toHtml(
        const core.Box(
          enabled: false,
          onTap: noop,
          semantics: core.BoxSemantics(role: core.BoxRole.button),
        ),
      );

      expect(html, contains('aria-disabled="true"'));
      expect(html, isNot(contains('tabindex')));
    });

    test('writes the state rules of its look', () {
      final String html = toHtml(
        const core.Box(hoverStyle: core.BoxStyle(opacity: 0.9)),
      );

      // A hover only applies where a pointer can hover, so a phone cannot get stuck in
      // a hovered look after a tap.
      expect(html, contains('@media (hover: hover)'));
      expect(html, contains(':hover'));
    });

    test('lets a decoration keep the pointer off itself', () {
      // A badge over a control holds a child, so the browser would aim a press at the badge
      // and the control would never see the corner a thumb lands on. `pointer-events: none`
      // is the same statement `IgnorePointer` makes in Flutter.
      expect(
        toHtml(
          const core.Box(
            capturesPointer: false,
            children: <core.UINode>[core.TextNode('3')],
          ),
        ),
        contains('pointer-events:none'),
      );

      // A leaf is not a target on either side unless it says so.
      expect(
        toHtml(const core.Box(width: 16, height: 16)),
        contains('pointer-events:none'),
      );
      expect(
        toHtml(const core.Box(width: 16, height: 16, capturesPointer: true)),
        contains('pointer-events:auto'),
      );
    });

    test('starts hidden when it only appears above a width', () {
      // Mobile first: a browser without container queries draws the narrow layout rather
      // than a broken wide one.
      final String html = toHtml(const core.Box(visibleFrom: 600));

      expect(html, contains('display:none'));
      expect(html, contains('@container (min-width: 600px)'));
    });

    test('holds the width its children measure themselves against', () {
      // A container query asks the parent, not the window: a card in a narrow column is
      // narrow whatever the window is.
      final String html = toHtml(
        const core.Box(children: <core.UINode>[core.Box(visibleUntil: 900)]),
      );

      expect(html, contains('container-type:inline-size'));
      expect(html, contains('@container (min-width: 900px)'));
    });

    test('draws a band between two widths', () {
      final String html = toHtml(
        const core.Box(
          children: <core.UINode>[
            core.Box(visibleFrom: 600, visibleUntil: 900),
          ],
        ),
      );

      expect(html, contains('@container (min-width: 600px)'));
      expect(html, contains('@container (min-width: 900px)'));
    });
  });

  group('an image', () {
    test('reserves its box before the picture arrives', () {
      // The difference between a page that settles and one that shifts.
      final String html = toHtml(
        const core.ImageNode('a.png', alt: 'A flat', width: 200, height: 100),
      );

      expect(html, contains('width="200"'));
      expect(html, contains('height="100"'));
      expect(html, contains('alt="A flat"'));
    });

    test('writes the loading hints the node states', () {
      final String html = toHtml(
        const core.ImageNode(
          'a.png',
          alt: 'A flat',
          loading: core.ImageLoading.lazy,
          fetchPriority: core.ImageFetchPriority.high,
        ),
      );

      expect(html, contains('loading="lazy"'));
      expect(html, contains('fetchpriority="high"'));
    });

    test('says nothing a browser would have done anyway', () {
      // `eager` and `auto` are the defaults, and a document states what it wants.
      final String html = toHtml(const core.ImageNode('a.png', alt: 'A flat'));

      expect(html, isNot(contains('loading=')));
      expect(html, isNot(contains('fetchpriority=')));
    });

    test('cannot point at a script', () {
      expect(
        toHtml(const core.ImageNode('javascript:alert(1)', alt: 'A')),
        contains('src="#"'),
      );
    });
  });

  group('a link', () {
    test('is an anchor a crawler follows, with real text inside it', () {
      final String html = toHtml(
        const core.LinkNode(
          '/listings',
          children: <core.UINode>[core.TextNode('Listings')],
        ),
      );

      expect(html, contains('<a'));
      expect(html, contains('href="/listings"'));
      expect(html, contains('>Listings</span>'));
    });

    test('hands no opener to the page it opens in a new tab', () {
      final String html = toHtml(
        const core.LinkNode(
          'https://example.com',
          newTab: true,
          children: <core.UINode>[core.TextNode('Elsewhere')],
        ),
      );

      expect(html, contains('target="_blank"'));
      expect(html, contains('rel="noopener noreferrer"'));
    });

    test('inherits the look of the text around it', () {
      // A browser paints every link blue and underlined, which the Flutter renderer
      // cannot draw.
      final String html = toHtml(
        const core.LinkNode('/x', children: <core.UINode>[core.TextNode('Go')]),
      );

      expect(html, contains('color:inherit'));
      expect(html, contains('text-decoration:none'));
    });
  });

  group('a grid', () {
    test('counts its tracks from the width it is given', () {
      final String html = toHtml(
        const core.GridNode(
          minItemWidth: 200,
          children: <core.UINode>[core.TextNode('One')],
        ),
      );

      expect(html, contains('display:grid'));
      expect(
        html,
        contains('repeat(auto-fill, minmax(min(100%, 200px), 1fr))'),
      );
      expect(html, contains('>One</span>'));
    });
  });

  group('a stack', () {
    core.UINode stackOf(List<core.UINode> children) =>
        core.StackNode(children: children);

    test('puts every child in a cell, and the cell is not a node', () {
      final String html = toHtml(
        stackOf(<core.UINode>[const core.TextNode('Over')]),
      );

      expect(html, contains('grid-template-rows:100%'));
      // The wrapper is the renderer's: no node drew it, so it carries no name.
      final Iterable<RegExpMatch> named = RegExp(
        r'data-unibox-node="([a-z-]+)"',
      ).allMatches(html);

      expect(named.map((RegExpMatch match) => match[1]), <String>[
        'stack',
        'text',
      ]);
    });

    test('places a positioned child by its offsets', () {
      final String html = toHtml(
        stackOf(<core.UINode>[
          core.PositionedNode(
            top: 8,
            left: 16,
            child: const core.TextNode('Pin'),
          ),
        ]),
      );

      expect(html, contains('position:absolute'));
      expect(html, contains('top:8px'));
    });

    test('fills a cell for a child placed by an alignment', () {
      final String html = toHtml(
        stackOf(<core.UINode>[
          core.PositionedNode(
            alignment: core.BoxAlignment.bottomCenter,
            child: const core.TextNode('Float'),
          ),
        ]),
      );

      expect(html, contains('inset:0'));
      expect(html, contains('justify-content:center'));
    });

    test('reports a positioned node that has no stack to be placed in', () {
      // `validateTree` reports it too; a renderer should not quietly draw it at its
      // natural position.
      expect(
        () => toHtml(
          const core.PositionedNode(top: 1, child: core.TextNode('Lost')),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('a text input', () {
    test('is an input of the type the node states', () {
      expect(
        toHtml(const core.TextInputNode(inputType: core.InputType.email)),
        contains('type="email"'),
      );
      expect(
        toHtml(const core.TextInputNode(inputType: core.InputType.phone)),
        contains('type="tel"'),
      );
    });

    test('hides what is typed when it is a password', () {
      expect(
        toHtml(const core.TextInputNode(obscureText: true)),
        contains('type="password"'),
      );
    });

    test('hands a password manager the kind of entry it is', () {
      expect(
        toHtml(const core.TextInputNode(inputType: core.InputType.email)),
        contains('autocomplete="email"'),
      );
      // A plain text field says nothing a browser could act on.
      expect(
        toHtml(const core.TextInputNode()),
        isNot(contains('autocomplete')),
      );
    });

    test('is a text area of the rows it states when it is multiline', () {
      final String html = toHtml(
        const core.TextInputNode(
          multiline: true,
          maxLines: 4,
          value: 'Two bedrooms',
        ),
      );

      expect(html, contains('<textarea'));
      expect(html, contains('rows="4"'));
      expect(html, contains('>Two bedrooms</textarea>'));
    });

    test('announces what a field is required to say', () {
      final String html = toHtml(
        const core.TextInputNode(
          required: true,
          invalid: true,
          semanticsLabel: 'Email',
          description: 'We never share it',
        ),
      );

      expect(html, contains('aria-required="true"'));
      expect(html, contains('aria-invalid="true"'));
      expect(html, contains('aria-label="Email"'));
      expect(html, contains('aria-description="We never share it"'));
    });

    test('writes the hint as a rule of its own', () {
      // `::placeholder` is not a declaration the field carries, so it is a rule beside
      // its class — and it is part of the class key, or two fields that differ only in
      // their hint would share a class.
      final String html = toHtml(
        const core.TextInputNode(
          placeholder: 'you@example.com',
          placeholderStyle: core.BoxTextStyle(color: core.BoxColor(0xFF999999)),
        ),
      );

      expect(html, contains('placeholder="you@example.com"'));
      expect(html, contains('::placeholder{color:#999999}'));
    });

    test('is disabled the way everything else is', () {
      expect(
        toHtml(const core.TextInputNode(enabled: false)),
        contains('disabled'),
      );
    });
  });

  group('an overlay', () {
    test('is a fixed layer with a dialog over a scrim', () {
      final String html = toHtml(
        const core.OverlayNode(child: core.TextNode('Sign up')),
      );

      expect(html, contains('position:fixed'));
      expect(html, contains('role="dialog"'));
      expect(html, contains('aria-modal="true"'));
      expect(html, contains('>Sign up</span>'));
    });

    test('is hidden, because a document has no one to ask for it', () {
      // The node exists for a state a client renderer draws. Nothing in a static page can
      // open it, so painting it would show a state nobody is in.
      final String html = toHtml(
        const core.OverlayNode(child: core.TextNode('Hello')),
      );

      expect(html, contains('hidden'));
    });

    test('is drawn when the page exists to show it', () {
      // `/signup`, whose whole purpose is the dialog, says so: the state is published at
      // its own url, and the node means the same thing either way.
      final String html = toHtml(
        const core.OverlayNode(child: core.TextNode('Hello')),
        showOverlays: true,
      );

      expect(html, isNot(contains('hidden')));
      expect(html, contains('role="dialog"'));
    });

    test('is never in the flow of its parent', () {
      // Taken out of the flow by the element, not by a second slot on a parent.
      expect(
        toHtml(const core.OverlayNode(child: core.TextNode('Hi'))),
        contains('inset:0'),
      );
    });

    test('scrims the page with the colour the node states', () {
      expect(
        toHtml(
          const core.OverlayNode(
            barrierColor: core.BoxColor(0xFF112233),
            child: core.TextNode('Hi'),
          ),
        ),
        contains('background-color:#112233'),
      );
    });
  });

  group('a stateful node', () {
    test('draws the state its store starts in', () {
      final String html = toHtml(_CounterNode());

      expect(html, contains('0'));
    });

    test('carries the options of the rendering into its view', () {
      // The state's tree is planned like any other, so a choice made for the document —
      // showing an overlay, say — has to reach a node the view drew.
      final String html = toHtml(_OverlayNode(), showOverlays: true);

      expect(html, isNot(contains('hidden')));
    });

    test('does not start the work an application would', () {
      // The store's contract: a server render reads the state without calling
      // `onMount`, so a request or a timer the application starts never runs here.
      _CountingStore.mounts = 0;

      toHtml(_CounterNode());

      expect(_CountingStore.mounts, 0);
    });
  });

  group('a shaped box', () {
    // The appearance table reads tokens a value can describe, and an outline is not one of them:
    // this is pinned here instead, at the renderer that writes it.
    const core.BoxShape triangle = core.BoxShape(
      viewBoxWidth: 10,
      viewBoxHeight: 10,
      commands: <core.BoxPathCommand>[
        core.BoxPathMoveTo(0, 0),
        core.BoxPathLineTo(10, 0),
        core.BoxPathLineTo(5, 10),
        core.BoxPathClose(),
      ],
    );

    test('paints its outline in a layer over the box', () {
      final String html = toHtml(const core.Box(shape: triangle));

      expect(html, contains('<svg'));
      expect(html, contains('viewBox="0 0 10 10"'));
      expect(html, contains('preserveAspectRatio="none"'));
      expect(html, contains('d="M0 0 L10 0 L5 10 Z"'));
    });

    test('sends the fill to the path, not to the element', () {
      final String html = toHtml(
        const core.Box(
          shape: triangle,
          backgroundColor: core.BoxColor(0xFF112233),
        ),
      );

      expect(html, contains('--unibox-shape-fill:#112233'));
      expect(html, contains('fill:var(--unibox-shape-fill'));
      expect(html, isNot(contains('background-color:#112233')));
    });

    test('clips its content to the outline when it says to', () {
      final String html = toHtml(
        const core.Box(shape: triangle, overflow: core.Overflow.hidden),
      );

      expect(html, contains('clip-path:url(#unibox-shape-'));
      expect(html, contains('clipPathUnits="objectBoundingBox"'));
    });
  });

  group('the toHtml shorthand', () {
    test('writes the fragment the function writes, for the same arguments', () {
      // The spelling the Flutter target uses for a widget, so a reader who has written
      // `page.toWidget()` finds `page.toHtml()` where they look for it — and it has to be
      // the same rendering, down to the class hashes, or the two spellings would be two
      // renderers.
      const core.Box box = core.Box(
        width: 40,
        backgroundColor: core.BoxColor.white,
      );

      expect(box.toHtml(), toHtml(box));
      expect(box.toHtml(showOverlays: true), toHtml(box, showOverlays: true));
      expect(
        box.toHtml(
          theme: const core.UniboxTheme(colors: <Enum, core.BoxColor>{}),
        ),
        toHtml(
          box,
          theme: const core.UniboxTheme(colors: <Enum, core.BoxColor>{}),
        ),
      );
    });

    test('carries the theme into the sheet the function writes', () {
      // On this target a role is not resolved while the tree is walked: the theme writes the
      // custom property in `:root` and the rule points at it with `var()`. So the shorthand
      // has only to pass the theme on, and the page has to be the one the function writes.
      const core.UniboxTheme theme = core.UniboxTheme(
        colors: <Enum, core.BoxColor>{_Role.ink: core.BoxColor.black},
      );
      const core.Box box = core.Box(
        backgroundColor: core.BoxColor.role(_Role.ink),
      );

      expect(box.toHtml(theme: theme), toHtml(box, theme: theme));
      expect(box.toHtml(theme: theme), contains('--unibox-color-ink:#000000'));
      expect(
        box.toHtml(theme: theme),
        contains('background-color:var(--unibox-color-ink)'),
      );
    });
  });

  group('a node this renderer cannot draw', () {
    test('is reported instead of skipped', () {
      // A tree built for another target fails loudly rather than shipping a page with a
      // piece missing.
      expect(
        () => toHtml(const _UnembeddableNode()),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('the sheet', () {
    test('states the scheme the theme draws in', () {
      // What the browser needs to paint its own chrome — scrollbars, the caret, the canvas
      // before this sheet applies — to match the page rather than the reader's operating
      // system. Without it a light page in a dark-mode browser gets dark scrollbars.
      const core.UniboxTheme light = core.UniboxTheme(
        colors: <Enum, core.BoxColor>{_Role.ink: core.BoxColor.black},
      );
      const core.UniboxTheme dark = core.UniboxTheme(
        colors: <Enum, core.BoxColor>{_Role.ink: core.BoxColor.white},
        colorScheme: core.BoxColorScheme.dark,
      );

      expect(
        toHtml(const core.Box(), theme: light),
        contains('color-scheme:light'),
      );
      expect(
        toHtml(const core.Box(), theme: dark),
        contains('color-scheme:dark'),
      );
      // A tree with no theme makes no claim about a scheme either.
      expect(toHtml(const core.Box()), isNot(contains('color-scheme')));
    });

    test('starts from the typography of the model', () {
      final String html = toHtml(const core.Box());

      expect(html, startsWith('<style>'));
      expect(html, contains(':root{'));
      expect(html, contains('font-size:16px'));
    });

    test('switches off the tap highlight a touch browser paints', () {
      // A blue flash over the control a finger pressed is browser chrome, and the tree
      // already answers a press with its own ink; the root is where the property inherits
      // to every element from.
      expect(
        toHtml(const core.Box()),
        contains('-webkit-tap-highlight-color:transparent'),
      );
    });
  });
}

/// A page whose view is a dialog.
final class _OverlayNode extends core.StatefulNode<int, _CountingStore> {
  _OverlayNode() : super(create: _CountingStore.new, view: _overlayView);
}

core.UINode _overlayView(int state, _CountingStore store) =>
    const core.OverlayNode(child: core.TextNode('Sign up'));

/// A node this renderer has no branch for.
final class _UnembeddableNode extends core.UINode {
  const _UnembeddableNode();
}

/// A page with one store and no interactivity beyond a count.
final class _CounterNode extends core.StatefulNode<int, _CountingStore> {
  _CounterNode() : super(create: _CountingStore.new, view: _counterView);
}

core.UINode _counterView(int state, _CountingStore store) =>
    core.TextNode('$state');

/// A store that records whether a renderer started it.
final class _CountingStore extends core.StateStore<int> {
  _CountingStore() : super(0);

  static int mounts = 0;

  @override
  void onMount() {
    mounts++;
    super.onMount();
  }
}

/// A callback a box can carry; a document writes no listener for it.
void noop() {}

/// The one role these tests give a theme.
enum _Role { ink }
