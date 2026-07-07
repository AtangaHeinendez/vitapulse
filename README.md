# VitaPulse

A friendly, colorful health tracker for Android + web. VitaPulse reads your Galaxy Watch data (steps, heart rate, sleep, SpO₂, and more) from **Health Connect**, syncs it to **Supabase**, and shows it on a beautiful Material 3 dashboard — with a companion web dashboard deployed to Vercel.

**Data flow:** Galaxy Watch → Samsung Health → Health Connect → VitaPulse app → Supabase → web dashboard.

## Getting started

```sh
flutter pub get
flutter run --dart-define-from-file=env.json   # env.json holds Supabase keys (gitignored)
```

See [CLAUDE.md](CLAUDE.md) for the full stack, conventions, project structure, and common commands.
