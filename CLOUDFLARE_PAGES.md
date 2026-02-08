# Cloudflare Pages – Momentra (Flutter Web)

## Project settings

In **Workers & Pages** → your project → **Settings** → **Builds & deployments**:

| Setting | Value |
|--------|--------|
| **Build command** | `bash build.sh` |
| **Build output directory** | `build/web` |
| **Root directory** | (leave blank) |

## What the build does

1. Installs the Flutter SDK (stable) if not present.
2. Runs `flutter pub get` and `flutter build web --release`.
3. Produces static files in `build/web/`, which Pages serves.

## Optional environment variables

- `FLUTTER_DIR` – Where to install/cache Flutter (default: `$HOME/flutter`).
- `FLUTTER_CHANNEL` – Flutter channel (default: `stable`).

## First build

The first run can take several minutes while Flutter is cloned and the Dart SDK is downloaded. Later builds may be faster if the environment reuses the same workspace.
