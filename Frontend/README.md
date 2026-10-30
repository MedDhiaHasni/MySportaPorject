# Sporta

## Night Match design system

The app uses a dark-first Night Match theme with a system-following light mode.
It bundles Sora for headlines and prices, Inter for body text, and Noto Sans
Arabic as a fallback for Arabic. Shared tokens and components live in
`lib/Core/Theme/` and `lib/Widgets/`.

### Mapbox configuration

On Android, Explore uses the access token already configured in the native
Android manifest when no Dart define is provided. For other platforms, or to
override the Android token for local development, provide a Mapbox public
access token at build or run time:

```shell
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_PUBLIC_TOKEN
flutter build apk --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_PUBLIC_TOKEN
```

Replace `YOUR_MAPBOX_PUBLIC_TOKEN` locally with your own token; do not commit it.
If neither the native SDK nor the Dart define has a token, the app shows a
notice with a way back to the venue list instead of opening a nonfunctional map.

### Design-system preview

In a debug build, launch the component preview with:

```shell
flutter run --dart-define=SPORTA_DESIGN_SYSTEM_PREVIEW=true
```

The preview flag is ignored in release builds.
