{{flutter_js}}
{{flutter_build_config}}

// The application's base url, read from where *this file* is served.
//
// `document.currentScript` is only set while a classic script is executing, so it is read here
// rather than in a callback. The result is absolute, which is what makes one artefact work at any
// depth: `/flutter/`, `/flutter/listings/`, and a takeover document two directories below the
// build all ask for the same file and get their own paths back.
var base = new URL('.', document.currentScript.src).href;

_flutter.loader.load({
  config: {
    entrypointBaseUrl: base,
    canvasKitBaseUrl: new URL('canvaskit/', base).href,
    assetBase: base
  }
});
