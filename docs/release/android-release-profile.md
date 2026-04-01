# Android Release Profile (Secure Defaults)

## Build command

```bash
bash scripts/release/build_secure_android.sh
```

## Default hardening flags

- `--release`
- `--obfuscate`
- `--split-debug-info=build/symbols/android`

## Pre-release checklist

- [ ] `flutter test` passes.
- [ ] `flutter analyze` passes.
- [ ] `bash scripts/release/pre_release_checks.sh` passes.
- [ ] Symbol bundle archived with release metadata.
- [ ] Store changelog includes notable migration notes.

