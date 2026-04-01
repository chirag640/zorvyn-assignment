$ErrorActionPreference = 'Stop'

if (-not $env:APP_ENV) {
  $env:APP_ENV = 'production'
}
if (-not $env:APP_RELEASE) {
  $env:APP_RELEASE = '1.0.0+1'
}

New-Item -ItemType Directory -Path 'build/symbols/android' -Force | Out-Null

flutter build appbundle --release `
  --obfuscate `
  --split-debug-info=build/symbols/android `
  --dart-define=APP_ENV=$env:APP_ENV `
  --dart-define=APP_RELEASE=$env:APP_RELEASE

Write-Output "Secure Android build completed with APP_ENV=$env:APP_ENV APP_RELEASE=$env:APP_RELEASE"

