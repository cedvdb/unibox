# unibox_example_html

The server-side documents for the example and site. The same pure Dart region
declarations are rendered as HTML/CSS here and as native widgets by the Flutter host.

The site and component catalogue are readable documents with ordinary links.
The takeover example opts into the shared handover bridge and waits for explicit
Flutter host readiness. No browser application client is compiled or shipped.

Build with `tool/site.sh` from the repository root. Verify the built documents
with `python3 tool/doc_check.py build/site` and actual handover/replay with
`tool/boot_check.sh build/site`.
