# Instruction File Design for Vibe Coders

Use one canonical policy source and generate tool-specific adapters.

## Why this works

- Single source of truth prevents rule conflicts.
- Tool-specific adapters optimize behavior for Copilot/Cursor/instructions.
- Fast onboarding: one playbook, many surfaces.

## Recommended Flow

1. Read task card and restate intent.
2. Identify architecture layers touched.
3. Implement minimal safe change.
4. Add tests for all behavior changes.
5. Run analyzer and tests.
6. Sync generated instruction files.
7. Publish compliance summary in PR.

## Golden Rule

If source policy changes, regenerate adapters before merge.

