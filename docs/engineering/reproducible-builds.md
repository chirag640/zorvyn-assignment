# Reproducible Builds and Dependency Hygiene

This project includes defaults intended to reduce dependency drift and improve reproducibility.

## Baseline

- Commit `pubspec.lock` for application repositories.
- Run `dart pub get` in CI before analysis/tests.
- Keep SDK constraints explicit in `pubspec.yaml`.

## Update Workflow

1. Run `dart pub outdated`.
2. Upgrade intentionally (small batches preferred).
3. Run analyzer/tests and smoke-build release artifacts.
4. Commit lockfile updates with changelog notes.

## Guardrails

- CI can fail when dependency drift is detected.
- Dependabot should manage both Dart packages and GitHub actions references.

## Recommended cadence

- Weekly: review Dependabot PRs.
- Monthly: run major version review and risk assessment.

