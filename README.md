# Frontend

Generated with flutter_blueprint using **Riverpod** state management.

## Getting Started

```bash
flutter pub get
flutter run
```

## Environment Setup

Create a local env file before running:

```bash
cp .env.example .env
```

Set these keys in `.env`:

- `SUPABASE_URL=https://<your-project-ref>.supabase.co`
- `SUPABASE_ANON_KEY=<your-anon-key>` or `SUPABASE_PUBLISHABLE_KEY=<your-publishable-key>`

The app now uses a startup guard screen and will not show auth screens until
Supabase initializes successfully.

## Supabase Backend Setup

1. Install Supabase CLI and login.
2. Link your project from `frontend` directory.
3. Apply SQL migrations from:
   - `supabase/migrations/20260401000001_init_profiles_finance.sql`
   - `supabase/migrations/20260401000002_user_settings.sql`

Example commands:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```

Current integration status:

- Supabase auth is wired (sign in/sign up/sign out).
- Profile reads/updates use Supabase when configured.
- Finance transactions and goals perform optional Supabase sync with local fallback.
- Finance sync now uses a local dirty queue with retry/backoff and timestamp conflict resolution.
- Settings (theme, language, notifications, biometrics) sync to Supabase with local cache fallback.

- State management: riverpod
- Platform target: mobile

## Riverpod Features

- ✅ Compile-time safety
- ✅ Better testability (no BuildContext required)
- ✅ StateNotifier pattern for complex state
- ✅ Automatic disposal and memory management

## Assignment Execution Docs

Use these files as the primary working system for the Personal Finance Companion assignment:

- Deep research and product brief: `docs/ai/personal-finance-companion-research-brief.md`
- Full sprint TODO backlog: `docs/ai/personal-finance-companion-sprint-todo.md`
- Session-to-session context tracking: `docs/ai/personal-finance-context-log.md`
- Requirement traceability matrix: `docs/ai/personal-finance-requirements-traceability.md`
- Design system implementation guide: `docs/engineering/finance-design-system-guide.md`

Recommended flow:

1. Read the research brief.
2. Execute tasks from the sprint TODO file.
3. Update the context log at the end of every session.
4. Keep UI and component work aligned with the design system guide.

Current visual direction:

- Premium Playful Finance style (strict iOS utility + playful ring gamification) is locked in `docs/engineering/finance-design-system-guide.md`.
