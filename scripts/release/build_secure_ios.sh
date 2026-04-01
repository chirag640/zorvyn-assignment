#!/usr/bin/env bash
set -euo pipefail

APP_ENV="${APP_ENV:-production}"
APP_RELEASE="${APP_RELEASE:-1.0.0+1}"

mkdir -p build/symbols/ios

flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols/ios \
  --dart-define=APP_ENV=${APP_ENV} \
  --dart-define=APP_RELEASE=${APP_RELEASE}

echo "Secure iOS build completed with APP_ENV=${APP_ENV} APP_RELEASE=${APP_RELEASE}"

