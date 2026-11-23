# unibox_material_flutter

The native Flutter rendering of the small `unibox_material` vocabulary.

```dart
renderFlutter(
  region,
  scope: UniboxScope(theme: theme),
  substitutions: materialComponents(icons: const <IconData>[Icons.search]),
);
```

The map draws cards, buttons, chips, segmented controls, icons and icon buttons
with native Material widgets. The application supplies selection, actions,
fonts and theme. A missing required map or unregistered icon is reported rather
than silently falling back to a custom control or glyph renderer.

Destinations use `FlutterLinkScope` unless an action overrides navigation.
Disabled components do not invoke actions. Native components preserve declared
content and selection; native paint and text scaling can differ from CSS.

`uniboxThemeOf` converts a Flutter colour scheme to Unibox roles.
`materialThemeData` constructs a Flutter theme from the shared palette.
Neither core nor the generic renderers depend on this optional package.
