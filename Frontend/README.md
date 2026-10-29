# Sporta

## Matchday design system

The app bundles Barlow Condensed for headlines and numbers, Inter for body text,
and Noto Sans Arabic as a fallback for Arabic. Theme mode follows the device
setting. Shared design tokens and components live in `lib/Core/Theme/` and
`lib/Widgets/`.

### Mapbox configuration

Provide a Mapbox public access token at build or run time rather than storing it
in Dart source:

```shell
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_PUBLIC_TOKEN
flutter build apk --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_PUBLIC_TOKEN
```

Replace `YOUR_MAPBOX_PUBLIC_TOKEN` locally with your own token; do not commit it.
Without the define, the app continues to work and shows a notice with a way back
to the venue list instead of opening a nonfunctional map.

### Design-system preview

In a debug build, launch the component preview with:

```shell
flutter run --dart-define=SPORTA_DESIGN_SYSTEM_PREVIEW=true
```

The preview flag is ignored in release builds.
