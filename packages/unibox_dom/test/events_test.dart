@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_dom/unibox_dom.dart';
import 'package:web/web.dart' as web;

import 'support/document.dart';

web.Element firstIn(web.Element root) => root.children.item(0)!;

void main() {
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

  group('a link with a handler', () {
    test('cancels a plain click and answers it', () {
      bool followed = false;
      final DomView view = DomView.mount(
        core.LinkNode(
          '/listings',
          onTap: () => followed = true,
          child: const core.TextNode('Listings'),
        ),
        host(),
      );
      final web.Element link = view.element.tagName.toLowerCase() == 'a'
          ? view.element
          : view.element.querySelector('a')!;

      final web.Event plain = web.MouseEvent(
        'click',
        web.MouseEventInit(bubbles: true, cancelable: true),
      );
      link.dispatchEvent(plain);

      expect(followed, isTrue);
      expect(plain.defaultPrevented, isTrue);

      view.dispose();
    });

    test('leaves a modified click and a new tab to the browser', () {
      // A reader asking for another window is not asking this page to handle the press, and a link
      // that opened a tab would be broken by cancelling it.
      int followed = 0;
      final DomView view = DomView.mount(
        core.Box(
          children: <core.UINode>[
            core.LinkNode(
              '/a',
              key: 'modified',
              onTap: () => followed++,
              child: const core.TextNode('A'),
            ),
            core.LinkNode(
              '/b',
              key: 'newtab',
              newTab: true,
              onTap: () => followed++,
              child: const core.TextNode('B'),
            ),
          ],
        ),
        host(),
      );

      web.Element linkFor(String key) =>
          view.element.querySelector('[data-unibox-key="$key"]')!;

      final web.Event meta = web.MouseEvent(
        'click',
        web.MouseEventInit(bubbles: true, cancelable: true, metaKey: true),
      );
      linkFor('modified').dispatchEvent(meta);

      expect(meta.defaultPrevented, isFalse);
      expect(
        followed,
        0,
        reason: 'a meta-click opens a tab and stays the browser’s',
      );

      final web.Event tabbed = web.MouseEvent(
        'click',
        web.MouseEventInit(bubbles: true, cancelable: true),
      );
      linkFor('newtab').dispatchEvent(tabbed);

      expect(tabbed.defaultPrevented, isFalse);
      expect(
        followed,
        0,
        reason: 'a link that opens a tab cannot also be cancelled',
      );

      view.dispose();
    });
  });
}
