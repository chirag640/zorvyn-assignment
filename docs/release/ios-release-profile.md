# iOS Release Profile (Secure Defaults)

## Build command

```bash
bash scripts/release/build_secure_ios.sh
```

## Default hardening flags

- `--release`
- `--obfuscate`
- `--split-debug-info=build/symbols/ios`

## Pre-release checklist

- [ ] `flutter test` passes.
- [ ] `flutter analyze` passes.
- [ ] `bash scripts/release/pre_release_checks.sh` passes.
- [ ] Symbol bundle archived with release metadata.
- [ ] Signing/codesign credentials validated in CI.

