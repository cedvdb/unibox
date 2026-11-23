# unibox_example_flutter

The native Flutter host for the shared declarations. It supplies the surface,
fonts, link policy and required Material substitution map. It does not define a
second copy of the shared regions.

The handover example explicitly completes a `FlutterHandover` after its initial
layout and disposes the coordinator with its host. The component catalogue uses
native widgets only. The bootstrap can use an existing host supplied by the bridge.

See [the examples](../README.md) and [handover](../../docs/takeover.md).
