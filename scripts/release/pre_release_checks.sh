#!/usr/bin/env bash
set -euo pipefail

echo "[1/4] Getting dependencies"
dart pub get

echo "[2/4] Static analysis"
dart analyze

echo "[3/4] Tests"
flutter test

echo "[4/4] Doctor checks"
flutter_blueprint doctor --strict

echo "Pre-release checks passed."

