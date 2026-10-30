# Sporta

## Night Match design system

The app uses a dark-first Night Match theme with a system-following light mode.
It bundles Sora for headlines and prices, Inter for body text, and Noto Sans
Arabic as a fallback for Arabic. Shared tokens and components live in
`lib/Core/Theme/` and `lib/Widgets/`.

### Mapbox configuration

Explore includes the app's Mapbox public access token as a client-side fallback.
To override it for local development or a different environment, provide a
Mapbox public access token at build or run time:

```shell
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_PUBLIC_TOKEN
flutter build apk --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_PUBLIC_TOKEN
```

Replace `YOUR_MAPBOX_PUBLIC_TOKEN` locally with your own token. Mapbox public
tokens are included in client apps; restrict allowed URLs and scopes in the
Mapbox account. Without a configured token, the app shows a notice with a way
back to the venue list instead of opening a nonfunctional map.

### Design-system preview

In a debug build, launch the component preview with:

```shell
flutter run --dart-define=SPORTA_DESIGN_SYSTEM_PREVIEW=true
```

The preview flag is ignored in release builds.
