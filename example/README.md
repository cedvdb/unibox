# Examples

The shared pure Dart package declares the example's content and site sections. The
HTML host writes documents; the Flutter host supplies its theme, navigation, native
Material mappings and handover readiness. The site is a document, not a DOM application.

The Material section demonstrates only cards, buttons, chips and segmented choices,
with palette and typography. Broader application controls belong to the Flutter host.

Build with `tool/site.sh`. Check HTML with `python3 tool/doc_check.py build/site`
and the HTML-to-Flutter transition with `tool/boot_check.sh build/site`.

See [the repository guide](../README.md) and [handover contract](../docs/takeover.md).
