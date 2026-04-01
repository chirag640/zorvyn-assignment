#!/usr/bin/env bash
set -euo pipefail

APP_ENV="${APP_ENV:-production}"
APP_RELEASE="${APP_RELEASE:-1.0.0+1}"

mkdir -p build/symbols/android

flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/android \
  --dart-define=APP_ENV=${APP_ENV} \
  --dart-define=APP_RELEASE=${APP_RELEASE}

echo "Secure Android build completed with APP_ENV=${APP_ENV} APP_RELEASE=${APP_RELEASE}"

