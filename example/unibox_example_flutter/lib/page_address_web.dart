import 'package:web/web.dart' as web;

/// The address of the document, as the browser holds it.
///
/// `window.location` is the page that was opened; the `<base href>` the build writes is a
/// different fact, and the one `Uri.base` would answer with.
Uri get pageAddress => Uri.parse(web.window.location.href);

/// The browser follows the same destination its document link names.
bool navigateTo(String url) {
  web.window.location.assign(url);
  return true;
}
