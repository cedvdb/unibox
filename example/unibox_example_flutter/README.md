# unibox_example_flutter

An ordinary Flutter host around the shared listing region. Native search and a
filter choose which apartments the declaration receives; its save callback opens
a native dialog. The host owns page composition, state and its scroll controller.

Direct entry works independently. Only the separate handover route completes a
`FlutterHandover` after layout, using that controller and the host's root context.
The Material page installs the native substitution map. Browser links navigate;
other platforms show a copyable destination without another plugin dependency.

Run `flutter run` here, or build the complete site with `tool/site.sh` from the
repository root. See [the example guide](../README.md).
