import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_flutter/unibox_flutter.dart';

/// The offsets a page recorded, read where a page exists.
///
/// A test runs on the VM, so it exercises the stub — which is the point: the same call has to
/// return nothing here and a record in a browser, and a build that cannot run JavaScript must
/// never see the JavaScript. The browser half is `page_scroll_web.dart`, chosen by the
/// conditional export and exercised by the exported site.
void main() {
  test('answers with nothing where there is no page to read', () {
    expect(scrollOffsetsFromPage(), isEmpty);
  });

  test('is the type the scope takes, so a host wires two names and no glue', () {
    // The signature is the contract between the reader and `UniboxScrollScope`.
    final List<core.BoxScrollOffset> offsets = scrollOffsetsFromPage();

    expect(offsets, isA<List<core.BoxScrollOffset>>());
  });
}
