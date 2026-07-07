# VitaPulse

Health tracking app (Samsung Health–inspired): Flutter Android app reading **Health Connect** data (synced from a Samsung Galaxy Watch via Samsung Health) and syncing it to **Supabase**, plus a Flutter **web dashboard** (same codebase) deployed to Vercel that reads only from Supabase.

**Data flow:** Galaxy Watch → Samsung Health → Health Connect → app (`health` package) → upsert to Supabase → web dashboard.

## Stack (locked — do not substitute)

- Flutter stable, Material 3; state: **riverpod** (flutter_riverpod 3.x + riverpod_annotation); nav: **go_router** with auth redirect guards
- Backend: **supabase_flutter** (email + password auth, Postgres with RLS)
- Health data: **health** package → Health Connect; step fallback: **pedometer** + permission_handler
- Charts: **fl_chart**; motion: **flutter_animate** + **lottie**; splash: flutter_native_splash
- Notifications: flutter_local_notifications (hydration + BP reminders)
- Secrets: `--dart-define-from-file=env.json` (gitignored — never hardcode or commit secrets)
- CI/CD: GitHub Actions → Firebase App Distribution (APK) + Vercel (web)

## Structure

Feature-first:

```
lib/
  core/{theme,router,widgets,services,utils}
  features/{auth,onboarding,dashboard,metrics,water,reminders,profile}/
    presentation/  (+ data/, domain/ as features grow)
```

- `core/theme/app_colors.dart` — brand palette + per-metric accent colors (steps green, HR pink, sleep purple, BP amber, SpO₂/water blue, calories orange, weight lime)
- `core/theme/app_theme.dart` — Material 3 light/dark themes; Outfit (headings/numbers) + Inter (body) via google_fonts
- `core/router/app_router.dart` — all routes in `Routes`; fade page transitions
- Brand assets in `assets/branding/` are **generated** by a GDI+ PowerShell script (heart + ECG mark); Lottie intro in `assets/lottie/pulse.json` (hand-authored JSON)

## Conventions

- Conventional commits (`feat:`, `fix:`, `chore:`), small commits per feature
- `flutter analyze` must be clean before every commit; run `flutter test` too
- Respect reduced motion (`MediaQuery.disableAnimations`) for every animation
- Web (`kIsWeb`): no Health Connect / pedometer / notifications code paths — Supabase reads + manual entry only
- Personal health data: RLS on every table, no analytics/tracking SDKs
- Android `minSdk = 26` (Health Connect requirement), package id `com.heinendez.vitapulse`

## Commands

```
flutter run -d <device>                                 # dev run (add --dart-define-from-file=env.json from Phase 2)
flutter analyze && flutter test                         # must pass before commit
dart run build_runner build --delete-conflicting-outputs # riverpod codegen (from Phase 2)
dart run flutter_native_splash:create                   # regen splash after config change
dart run flutter_launcher_icons                         # regen icons after config change
flutter build web --release                             # web bundle (deployed to Vercel)
```

## Machine-specific build workarounds (this dev machine)

1. **Flutter SDK path has a space** (`C:\Users\Atanga Heinendez\develop\flutter`) which breaks Dart native-assets hooks (health→jni/objective_c). Always invoke Flutter via the junction: `C:\dev\flutter\bin\flutter.bat` (or put `C:\dev\flutter\bin` first in PATH).
2. **AF_UNIX `connect` is broken on this Windows build** (26200.8737) — every JDK ≥16 `Selector.open()` dies, killing Gradle ("Unable to establish loopback connection"). Fixed via user env var `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=<path longer than 108 bytes>` which forces the JDK's TCP-loopback pipe fallback. Delete the env var if a Windows update fixes AF_UNIX.
3. **NDK pinned to 29.0.14206865** (root + app build.gradle.kts) because it's already installed; `flutter.ndkVersion` (28.2) triggers a multi-GB download that keeps failing on this connection. Don't "clean up" the pin.

## Status / decisions log

- Phase 0: env audit clean (Flutter 3.44.5, Android SDK 36.1). gh/firebase/vercel CLIs deferred to Phases 5–6.
- Phase 1 ✅: scaffold + design system + native splash → Lottie intro → 3-page onboarding, verified end-to-end on the Pixel_7 emulator (Android 16). Onboarding-complete flag in SharedPreferences. Riverpod codegen deliberately deferred until Phase 2 (auth) — manual providers so far. Core library desugaring enabled (flutter_local_notifications). Widget tests cover the first-run flow.
- Phase 2 ✅: Supabase project `vitapulse` (mbmpooadpqyelxzfwlbe, eu-central-1) wired via env.json + `--dart-define-from-file`. Schema migration applied (also in `supabase/migrations/`); RLS verified via app writes; security advisors clean. Auth (sign up w/ confirm-email flow, sign in, forgot/reset via `vitapulse://auth-callback` deep link), riverpod codegen providers, async go_router guards (onboarding → auth → profile setup → home), session persistence — all verified on emulator against the live backend. Uses `publishableKey` (anonKey deprecated in supabase_flutter 2.15) — noted deviation from the original prompt.
- ⚠️ Supabase built-in email sender is rate-limited (~2/hour): real signups may hit "email rate limit exceeded". Recommend custom SMTP in dashboard for production. Test user vptest1@heinendez.dev was created via SQL (pre-confirmed).
- ⚠️ User dashboard TODO: add `vitapulse://auth-callback` to Auth → URL Configuration → Redirect URLs (MCP cannot change auth config).
- Phase 3 ✅: Health Connect wired per health 13.3.1 README (manifest permissions, rationale filters, FlutterFragmentActivity). HealthSource abstraction with HealthConnectSource + MockHealthSource (`--dart-define=MOCK_HEALTH=true`); pedometer fallback (midnight-baseline, fixed-timestamp upsert row, source='pedometer'). Sync verified on emulator with mock data: 1059 samples → health_metrics (all 9 types) → recompute_daily_summaries RPC → 30 daily_summaries rows with correct aggregates. Physical-device HC test pending until a phone is plugged in (user must enable Samsung Health → Settings → Health Connect data sync).
