# Frontend

Personal Finance Companion mobile app built with Flutter and Riverpod.

Generated baseline: flutter_blueprint (Riverpod mode)

## Quick Start

Prerequisites:

- Flutter SDK 3.41.x
- Dart SDK (bundled with Flutter)
- Android Studio emulator or physical Android device

Install dependencies:

```bash
flutter pub get
```

Create local environment file:

```bash
cp .env.example .env
```

Windows PowerShell alternative:

```powershell
Copy-Item .env.example .env
```

Set these keys in `.env`:

- `SUPABASE_URL=https://<your-project-ref>.supabase.co`
- `SUPABASE_ANON_KEY=<your-anon-key>` or `SUPABASE_PUBLISHABLE_KEY=<your-publishable-key>`

Run app:

```bash
flutter run
```

## Supabase Setup (Optional but Recommended)

1. Install Supabase CLI and login.
2. Link project from `frontend` folder.
3. Apply migrations:
   - `supabase/migrations/20260401000001_init_profiles_finance.sql`
   - `supabase/migrations/20260401000002_user_settings.sql`

Example:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```

## Architecture Overview

Feature-first structure with clear boundaries:

```text
lib/
  app/                # Root app wiring, route startup decisions
  core/               # Cross-cutting concerns (providers, theme, utils, storage, api)
  features/
    auth/             # Auth flow, startup guard, biometric unlock gate
    finance/          # Dashboard, transactions, goals, insights
    profile/          # Profile view/edit
    settings/         # Theme/language/currency/biometric controls
```

State management:

- Riverpod `StateNotifier` for feature state
- Derived providers for summaries/filters
- Local-first persistence with optional remote sync

Data strategy:

- Local storage remains source of continuity for demo reliability
- Supabase sync is queued with retry/backoff and timestamp conflict resolution
- Settings and finance records can sync when backend is configured

## Implemented Assignment Scope

- Dashboard with balance, income, expenses, savings, and trend visualization
- Transaction CRUD with search, filters, edit, delete, and undo
- Goal and challenge system with animated rings
- Insights view with category and trend summaries
- Settings for theme, language, currency, and biometric gate
- Profile read/edit flow

## Assumptions and Constraints

- Mobile-first scope (Android primary verification path)
- Categories are fixed for v1 (not user-configurable yet)
- No direct bank integrations; manual transaction input only
- Offline/local behavior prioritized over hard realtime sync guarantees
- Supabase setup may be skipped for evaluator demo; app still runs locally

## Demo Flow (Evaluator Script Summary)

For complete script, use:

- `docs/ai/personal-finance-companion-demo-script.md`

Short flow:

1. Launch app and pass startup guard.
2. Add transaction via center FAB bottom sheet.
3. Show dashboard updates and sparkline/metric changes.
4. Edit/delete transaction and demonstrate undo.
5. Open Goals tab and adjust target values.
6. Open Insights tab and explain trend cards.
7. Open Settings and toggle theme/currency/biometric options.
8. Open Profile and demonstrate edit/save flow.

## Quality Status (Current)

- `flutter analyze`: pass
- `flutter test`: pass (19 tests)
- Security logging hygiene: sensitive key/value redaction enabled in HTTP logger

## Known Limitations

- Manual Android smoke checklist is still pending final capture.
- Accessibility verification at large text scales needs final sign-off pass.
- No CSV/PDF export in current assignment build.
- No push notification reminders in current assignment build.
- Multi-currency conversion rates are not implemented (display currency only).

## Future Improvements

- Complete accessibility audit with captured evidence artifacts.
- Add transaction export and import tooling.
- Add budgeting notifications and habit nudges.
- Expand test coverage for end-to-end shell navigation scenarios.
- Add optional short demo video artifact for submission package.

## Assignment Execution Docs

Primary assignment artifacts:

- Deep research brief: `docs/ai/personal-finance-companion-research-brief.md`
- Sprint backlog: `docs/ai/personal-finance-companion-sprint-todo.md`
- Session context log: `docs/ai/personal-finance-context-log.md`
- Requirements traceability matrix: `docs/ai/personal-finance-requirements-traceability.md`
- Demo script: `docs/ai/personal-finance-companion-demo-script.md`
- Design system guide: `docs/engineering/finance-design-system-guide.md`
