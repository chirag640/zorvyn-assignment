$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$policyPath = Join-Path $repoRoot '.github/ai/flutter-enterprise-policy.md'

if (-not (Test-Path $policyPath)) {
  throw "Policy source not found: $policyPath"
}

$policy = Get-Content $policyPath -Raw

$copilotPath = Join-Path $repoRoot '.github/copilot-instructions.md'
$copilotContent = @"
# Enterprise Flutter AI Rules (Synced)

This file is generated from .github/ai/flutter-enterprise-policy.md.
Do not edit manually. Run scripts/sync_ai_rules.ps1.

$policy
"@
Set-Content -Path $copilotPath -Value $copilotContent -Encoding utf8

$cursorPath = Join-Path $repoRoot '.cursor/rules/flutter-enterprise.mdc'
$cursorContent = @"
---
description: Enterprise Flutter rules for architecture, security, testing, and quality
globs:
  - "**/*.dart"
  - "**/*.yaml"
  - "**/*.yml"
  - "**/*.md"
  - "pubspec.yaml"
  - "analysis_options.yaml"
alwaysApply: true
---

This file is generated from .github/ai/flutter-enterprise-policy.md.
Do not edit manually. Run scripts/sync_ai_rules.ps1.

$policy
"@
Set-Content -Path $cursorPath -Value $cursorContent -Encoding utf8

$dartInstructionPath = Join-Path $repoRoot '.github/instructions/flutter-enterprise.instructions.md'
$dartInstructionContent = @"
---
applyTo: "**/*.dart"
---

This file is generated from .github/ai/flutter-enterprise-policy.md.
Do not edit manually. Run scripts/sync_ai_rules.ps1.

## Dart Execution Rules

- Follow clean architecture boundaries strictly.
- Use the stack selected by blueprint config; do not force alternate stacks.
- Prefer guard clauses and pure helper functions.
- Add/update tests for any behavior change.
- Keep code analyzer-clean and formatted.
- CI mode for this template: mixed.

$policy
"@
Set-Content -Path $dartInstructionPath -Value $dartInstructionContent -Encoding utf8

$governanceInstructionPath = Join-Path $repoRoot '.github/instructions/repo-governance.instructions.md'
$governanceInstructionContent = @"
---
applyTo: "**/*.{md,yaml,yml}"
---

This file is generated from .github/ai/flutter-enterprise-policy.md.
Do not edit manually. Run scripts/sync_ai_rules.ps1.

# Repository Governance Rules

- Keep docs and workflows consistent with canonical policy.
- Avoid policy drift; sync generated files from source policy.
- Keep CI deterministic and security-safe.
- Require validation evidence in PR descriptions.
- Current CI mode: mixed.

$policy

## CI and Build Rules

- CI changes must preserve static analysis and test execution.
- Keep workflow changes deterministic and security-safe.
"@
Set-Content -Path $governanceInstructionPath -Value $governanceInstructionContent -Encoding utf8

Write-Output 'AI rule files synchronized from canonical policy source.'

