$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Test-Path '.githooks')) {
  throw 'Missing .githooks directory'
}

git config core.hooksPath .githooks

if (Get-Command bash -ErrorAction SilentlyContinue) {
  bash -lc "chmod +x .githooks/pre-commit" | Out-Null
}

Write-Output "Git hooks installed."

