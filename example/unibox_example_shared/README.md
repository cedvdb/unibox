# unibox_example_shared

Pure Dart data and stateless declarations: an apartment card, a listing grid and
sections of the documentation site. `buildListingRegion` accepts a supplied list
and an optional save callback. It owns no search state, navigation or dialogs.

The server renders the region into its document. The Flutter app renders it
among native widgets with `materialComponents()`. The separate Material section
shows the optional supported vocabulary.

See [the worked examples](../README.md).
