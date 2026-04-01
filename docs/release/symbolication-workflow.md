# Symbolication Workflow

Use this workflow to triage obfuscated stack traces in production.

## 1) Build with split debug info

Store symbol output from:

- `build/symbols/android`
- `build/symbols/ios`

## 2) Archive symbols per release

Recommended archive key format:

- `<app-name>/<platform>/<version+build>/symbols.zip`

## 3) Symbolicate stack traces

```bash
flutter symbolize \
  --input=crash_stacktrace.txt \
  --debug-info=build/symbols/android/app.android-arm64.symbols
```

## 4) Incident checklist

- Confirm incoming crash metadata has platform + app release.
- Pull matching symbol archive.
- Symbolicate and attach decoded trace to incident ticket.
- Add remediation notes and regression test references.

