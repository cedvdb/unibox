# unibox_example_shared

Pure Dart declarations shared by the example's server HTML and Flutter host.
The application sample owns its form state through the optional region adapter;
the Material catalogue contains only the small supported native vocabulary.

The server reads a snapshot. Flutter installs the native Material map and the host
signals handover readiness after the intended layout exists. No DOM application
runtime, custom path token, ink store or progress-ring component is required.

See [the examples](../README.md) and [handover](../../docs/takeover.md).
