$ErrorActionPreference = 'Stop'

Write-Output '[1/4] Getting dependencies'
dart pub get

Write-Output '[2/4] Static analysis'
dart analyze

Write-Output '[3/4] Tests'
flutter test

Write-Output '[4/4] Doctor checks'
flutter_blueprint doctor --strict

Write-Output 'Pre-release checks passed.'

