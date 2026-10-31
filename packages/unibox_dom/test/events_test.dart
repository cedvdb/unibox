@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:web/web.dart' as web;

import 'support/document.dart';

web.Element firstIn(web.Element root) => root.children.item(0)!;

void main() {
  _pageTests();

  group('a long press', () {
    test(
      'fires after the threshold, and swallows the click that follows',
      () async {
        // A press held down is a long press on both targets; the release that ends it is not also a
        // press, or a context menu opened by holding would be dismissed by letting go.
        int longPressed = 0;
        int tapped = 0;
        final DomView view = DomView.mount(
          core.Box(
            onLongPress: () => longPressed++,
            onTap: () => tapped++,
            children: <core.UINode>[const core.TextNode('Hold')],
          ),
          host(),
        );
        final web.Element box = view.element;

        box.dispatchEvent(
          web.PointerEvent('pointerdown', web.PointerEventInit(bubbles: true)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(longPressed, 1, reason: 'the hold passed the threshold');

        box.dispatchEvent(
          web.PointerEvent('pointerup', web.PointerEventInit(bubbles: true)),
        );
        box.dispatchEvent(
          web.MouseEvent(
            'click',
            web.MouseEventInit(bubbles: true, cancelable: true),
          ),
        );

        expect(
          tapped,
          0,
          reason: 'the release that ends a hold is not a press',
        );

        view.dispose();
      },
    );

    test('does not fire when the pointer leaves first', () async {
      int longPressed = 0;
      final DomView view = DomView.mount(
        core.Box(
          onLongPress: () => longPressed++,
          children: <core.UINode>[const core.TextNode('Hold')],
        ),
        host(),
      );

      view.element.dispatchEvent(
        web.PointerEvent('pointerdown', web.PointerEventInit(bubbles: true)),
      );
      view.element.dispatchEvent(
        web.PointerEvent('pointerleave', web.PointerEventInit(bubbles: true)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(longPressed, 0);

      view.dispose();
    });
  });

  group('Enter in a field', () {
    test('submits the text, and Shift+Enter does not', () {
      final List<String> submitted = <String>[];
      final DomView view = DomView.mount(
        core.TextInputNode(
          key: 'field',
          onSubmitted: submitted.add,
          maxLines: 3,
        ),
        host(),
      );
      final web.HTMLTextAreaElement field =
          firstIn(view.element.parentElement!) as web.HTMLTextAreaElement;

      field.value = 'two rooms';
      field.dispatchEvent(
        web.KeyboardEvent(
          'keydown',
          web.KeyboardEventInit(key: 'Enter', shiftKey: true, bubbles: true),
        ),
      );
      expect(
        submitted,
        isEmpty,
        reason: 'Shift+Enter is a newline in a multi-line field',
      );

      field.dispatchEvent(
        web.KeyboardEvent(
          'keydown',
          web.KeyboardEventInit(key: 'Enter', bubbles: true),
        ),
      );

      expect(submitted, <String>['two rooms']);

      view.dispose();
    });
  });

  group('a box that navigates', () {
    test(
      'cancels a plain click and answers it, so the page does not load twice',
      () {
        int pressed = 0;
        final DomView view = DomView.mount(
          core.LinkNode(
            '/?category=meetingRoom',
            onTap: () => pressed++,
            children: <core.UINode>[const core.TextNode('Meeting room')],
          ),
          host(),
        );

        // The element the box became, not the one inside it: the anchor is the box.
        expect(view.element.tagName.toLowerCase(), 'a');

        final web.Event plain = web.MouseEvent(
          'click',
          web.MouseEventInit(bubbles: true, cancelable: true),
        );
        view.element.dispatchEvent(plain);

        expect(pressed, 1);
        expect(plain.defaultPrevented, isTrue);

        view.dispose();
      },
    );

    test('leaves a modified click and a new tab to the browser', () {
      int pressed = 0;
      final DomView view = DomView.mount(
        core.Box(
          children: <core.UINode>[
            core.LinkNode(
              '/a',
              key: 'modified',
              onTap: () => pressed++,
              children: <core.UINode>[const core.TextNode('A')],
            ),
            core.LinkNode(
              '/b',
              key: 'newtab',
              newTab: true,
              onTap: () => pressed++,
              children: <core.UINode>[const core.TextNode('B')],
            ),
          ],
        ),
        host(),
      );

      web.Element anchorFor(String key) =>
          view.element.querySelector('[data-unibox-key="$key"]')!;

      // Neither press may be acted on by the browser: a click it keeps is a document it loads,
      // and this document is the suite. The destination is what neither assertion is about — the
      // modifier and the target are — so it is taken off for the length of the two presses.
      final web.Event meta = web.MouseEvent(
        'click',
        web.MouseEventInit(bubbles: true, cancelable: true, metaKey: true),
      );
      anchorFor('modified')
        ..removeAttribute('href')
        ..dispatchEvent(meta);

      expect(meta.defaultPrevented, isFalse);
      expect(
        pressed,
        0,
        reason: 'a meta-click opens a tab and stays the browser\u2019s',
      );

      final web.Event tabbed = web.MouseEvent(
        'click',
        web.MouseEventInit(bubbles: true, cancelable: true),
      );
      anchorFor('newtab')
        ..removeAttribute('href')
        ..dispatchEvent(tabbed);

      expect(tabbed.defaultPrevented, isFalse);
      expect(
        pressed,
        0,
        reason: 'a link that opens a tab cannot also be cancelled',
      );

      view.dispose();
    });

    test('answers no press it has no handler for, so the press stays the browser’s', () {
      // A destination with no callback is the browser’s: the listener must not swallow the
      // click it cannot answer, or the link would be dead on the one target that has one.
      final DomView view = DomView.mount(
        core.LinkNode(
          '/?category=meetingRoom',
          children: <core.UINode>[const core.TextNode('Meeting room')],
        ),
        host(),
      );

      expect(view.element.tagName.toLowerCase(), 'a');
      expect(view.element.getAttribute('href'), '/?category=meetingRoom');

      // What the renderer decided is read from the event itself, from one listener further
      // up the page — never by letting the browser act on it. An unanswered click on a link
      // is a click the browser *follows*, and a suite runs in an iframe of the runner's own
      // page: following it navigates the suite away, so `dart test` waits for a result that
      // can no longer arrive. That is not a failure anybody can read — the step sat there for
      // six hours once. The destination is taken off the element for the length of the press
      // so the follow cannot happen anywhere, and it is asserted above, where it belongs.
      bool? swallowed;
      final web.EventListener watch = ((web.Event event) {
        swallowed = event.defaultPrevented;
      }).toJS;

      web.document.addEventListener('click', watch);
      try {
        view.element.removeAttribute('href');
        view.element.dispatchEvent(
          web.MouseEvent(
            'click',
            web.MouseEventInit(bubbles: true, cancelable: true),
          ),
        );
      } finally {
        web.document.removeEventListener('click', watch);
      }

      expect(
        swallowed,
        isFalse,
        reason: 'a press the tree cannot answer stays the browser’s',
      );

      view.dispose();
    });
  });
}

void _pageTests() {
  // A pager on the web: the same rule as Flutter's, applied to `scrollLeft` once per change.
  web.Element pagerHost(int page) {
    final web.HTMLDivElement element = host();
    DomView.mount(
      core.Box(
        key: 'pager',
        width: 120,
        height: 80,
        direction: core.Axis.horizontal,
        overflow: core.Overflow.scroll,
        snap: core.ScrollSnap.page,
        page: page,
        children: <core.UINode>[
          for (int index = 0; index < 3; index++)
            core.Box(
              key: 'page-$index',
              width: 120,
              height: 80,
              children: <core.UINode>[core.TextNode('$index')],
            ),
        ],
      ),
      element,
    );

    return element;
  }

  test('a pager starts on the page the tree names, without sliding there', () {
    // The first application is a jump, so the box is already on its page when the view returns — a
    // pager that slid into place as it appeared would be a flash nobody asked for.
    final web.Element pager = pagerHost(1).children.item(0)!;

    expect(pager.scrollLeft, 120);

    // And the box is a scroller with three pages, so the offset is reachable at all.
    expect(pager.getAttribute('data-unibox-key'), 'pager');
    expect(pager.className, startsWith('unibox-box-'));
  });
}
