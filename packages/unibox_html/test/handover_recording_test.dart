import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:unibox_html/unibox_html.dart';

void main() {
  test('recording intercepts only eligible actions and consumes the latest intent once', () {
    final String program =
        '''
const listeners = {};
let elements = [];
const root = { getAttribute: () => 'booting' };
global.window = { unibox: { takeover: true } };
global.document = {
  documentElement: root,
  addEventListener: (name, callback) => listeners[name] = callback,
  removeEventListener: (name) => delete listeners[name],
  querySelectorAll: () => elements
};
function node(key, attributes = {}, parentNode = null, tagName = 'DIV') {
  const values = { ...attributes };
  if (key !== null) values['data-unibox-key'] = key;
  return { nodeType: 1, tagName, parentNode,
    hasAttribute: (name) => name in values,
    getAttribute: (name) => values[name] ?? null,
    getBoundingClientRect: () => ({ left: 0, top: 0 }) };
}
function click(target, changes = {}) {
  const event = { target, button: 0, clientX: 4, clientY: 8,
    preventDefault() { this.prevented = true; },
    stopImmediatePropagation() {}, ...changes };
  listeners.click(event);
  return event;
}
function assert(value, message) { if (!value) throw Error(message); }
eval(${jsonEncode(pressScript)});
const action = node('save', { 'data-unibox-action': '' });
elements = [action];
assert(click(action).prevented, 'action was not intercepted');
assert(!click(action, { ctrlKey: true }).prevented, 'modified click was intercepted');
const link = node('link', { href: '/next', 'data-unibox-action': '' }, null, 'A');
elements = [link];
assert(!click(link).prevented, 'browser link was intercepted');
const disabled = node('disabled', { 'aria-disabled': 'true', 'data-unibox-action': '' });
elements = [disabled];
assert(!click(disabled).prevented, 'disabled control was intercepted');
const picture = node('picture');
elements = [picture];
assert(!click(picture).prevented, 'non-action was intercepted');
elements = [action, node('save')];
assert(!click(action).prevented, 'ambiguous identity was intercepted');
const latest = node('latest', { 'data-unibox-action': '' });
elements = [latest];
click(latest);
assert(window.unibox.takePressed()[0].key === 'latest', 'latest intent was not retained');
assert(window.unibox.takePressed().length === 0, 'intent was consumed twice');
assert(!listeners.click, 'recorder listener was not released');
''';
    final ProcessResult result = Process.runSync('node', <String>[
      '-e',
      program,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('reads a marked page scroller, and the window when none is marked', () {
    final String program =
        '''
const listeners = {};
const state = { value: 'booting' };
let marked = { isConnected: true, scrollLeft: 4, scrollTop: 320 };
global.window = { scrollX: 12, scrollY: 240, addEventListener() {} };
global.document = {
  documentElement: { getAttribute: () => state.value },
  querySelector: () => marked,
  querySelectorAll: () => [],
  addEventListener: (name, callback) => listeners[name] = callback
};
eval(${jsonEncode(scrollScript)});
if (window.unibox.documentScroll().dy !== 320) throw Error('the marked scroller');
window.scrollY = 620;
listeners.scroll();
if (window.unibox.documentScroll().dy !== 320) throw Error('the window moved a marked page');
marked.isConnected = false;
marked = { isConnected: true, scrollLeft: 0, scrollTop: 480 };
if (window.unibox.documentScroll().dy !== 480) throw Error('a replaced scroller');
marked.isConnected = false;
marked = null;
if (window.unibox.documentScroll().dy !== 620) throw Error('the window fallback');
state.value = 'app';
window.scrollY = 900;
if (window.unibox.documentScroll().dy !== 620) throw Error('frozen after the reveal');
''';
    final ProcessResult result = Process.runSync('node', <String>[
      '-e',
      program,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\\n${result.stderr}');
  });

  test('document position follows continued scrolling and keyed offsets are consumed once', () {
    final String program =
        '''
const listeners = {};
global.window = { scrollX: 12, scrollY: 240, addEventListener() {} };
global.document = {
  documentElement: { getAttribute: () => 'booting' },
  querySelector: () => null,
  querySelectorAll: () => [],
  addEventListener: (name, callback) => listeners[name] = callback
};
eval(${jsonEncode(scrollScript)});
if (window.unibox.documentScroll().dy !== 240) throw Error('initial position');
window.scrollY = 620;
listeners.scroll();
if (window.unibox.documentScroll().dy !== 620) throw Error('latest position');
window.unibox.takeScroll();
if (window.unibox.takeScroll().length !== 0) throw Error('duplicate region restoration');
''';
    final ProcessResult result = Process.runSync('node', <String>[
      '-e',
      program,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}
