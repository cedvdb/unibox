/// Pure Dart server helpers for an optional HTML-to-Flutter handover.
///
/// Kept in the HTML package so a server never needs a Flutter SDK dependency.
library;

export 'src/client/boot.dart' show BootPolicy, RevealPolicy, bootScript;
export 'src/client/all.dart' show uniboxClientScript;
export 'src/takeover.dart' show Takeover;
