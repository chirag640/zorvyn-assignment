# Secure Release Preset

This project was generated with the production build-security preset enabled.

## Goals

- Obfuscate release binaries.
- Export split debug symbols for crash symbolication.
- Keep deterministic pre-release checks before publishing.

## Standard Android Release Command

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/android \
  --dart-define=APP_ENV=production \
  --dart-define=APP_RELEASE=1.0.0+1
```

## Standard iOS Release Command

```bash
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols/ios \
  --dart-define=APP_ENV=production \
  --dart-define=APP_RELEASE=1.0.0+1
```

## Pre-release Checks

Run one of:

- `bash scripts/release/pre_release_checks.sh`
- `pwsh scripts/release/pre_release_checks.ps1`

## Notes

- Keep symbol bundles private and retained for every published build.
- `APP_RELEASE` should match your store version/build identifier.
- `APP_ENV` should be `production` for publishable builds.

