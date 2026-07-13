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

## Workflow rules

- **Never commit directly to `main`.**
- Every task gets its own feature branch, clear commit messages, and a PR opened via the `gh` CLI.
- After opening a PR, wait ~2 min for CodeRabbit's review, fetch its comments (`gh api repos/{owner}/{repo}/pulls/{n}/comments` + issue comments), and fix anything actionable before asking the user to merge.
- Keep PRs small — one feature or fix per PR.

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

## Device & pipeline verification (2026-07-13, Galaxy phone via wireless adb)

- **Health Connect accuracy — verified end-to-end.** Steps matched Samsung Health exactly (single data origin: Samsung Health dedupes watch+phone before writing to HC, so no double-counting). Sleep (3h30m session) and SpO₂ (95%) verified matching by the user after enabling Samsung Health's **write** sync. Learnings: HC "App access" READ toggles are not enough — Samsung Health's own sync list / HC **"Allowed to write"** section controls what it exports; Samsung Health does **not backfill** pre-existing data (only sessions recorded after enabling sync); sleep/SpO₂ sync after the next completed sleep.
- **Bugs found on-device and fixed:** release builds missing INTERNET permission (debug injects it — emulator testing never caught it); cold-start hang when a Supabase session refresh stalls on mobile data (router redirect now times out at 8s; repository reads 15s); HR-card sparkline overflow (4.9px) on Galaxy text metrics; raw TimeoutException shown to users (now a friendly pull-to-refresh hint).
- **CI:** web build OOM'd (`dart2js` SIGTERM at -O4) on 7 GB private-repo runners — root cause of the "operation was canceled" failure, NOT billing. Fixed by repo going public (16 GB standard runners) + workflow split into independent `build-and-distribute` and `deploy-web` jobs with timeouts and Gradle caching. If the repo ever goes private again, expect the web job to OOM: build with `-O2` or use a larger runner.
- **Workflow:** all changes now flow through feature branches + PRs with CodeRabbit review (config in `.coderabbit.yaml`); three PRs merged clean through this process.

## Status / decisions log

- Phase 0: env audit clean (Flutter 3.44.5, Android SDK 36.1). gh/firebase/vercel CLIs deferred to Phases 5–6.
- Phase 1 ✅: scaffold + design system + native splash → Lottie intro → 3-page onboarding, verified end-to-end on the Pixel_7 emulator (Android 16). Onboarding-complete flag in SharedPreferences. Riverpod codegen deliberately deferred until Phase 2 (auth) — manual providers so far. Core library desugaring enabled (flutter_local_notifications). Widget tests cover the first-run flow.
- Phase 2 ✅: Supabase project `vitapulse` (mbmpooadpqyelxzfwlbe, eu-central-1) wired via env.json + `--dart-define-from-file`. Schema migration applied (also in `supabase/migrations/`); RLS verified via app writes; security advisors clean. Auth (sign up w/ confirm-email flow, sign in, forgot/reset via `vitapulse://auth-callback` deep link), riverpod codegen providers, async go_router guards (onboarding → auth → profile setup → home), session persistence — all verified on emulator against the live backend. Uses `publishableKey` (anonKey deprecated in supabase_flutter 2.15) — noted deviation from the original prompt.
- ⚠️ Supabase built-in email sender is rate-limited (~2/hour): real signups may hit "email rate limit exceeded". Recommend custom SMTP in dashboard for production. Test user vptest1@heinendez.dev was created via SQL (pre-confirmed).
- ⚠️ User dashboard TODO: add `vitapulse://auth-callback` to Auth → URL Configuration → Redirect URLs (MCP cannot change auth config).
- Phase 4 ✅: full dashboard (steps ring w/ sweep+count-up, 7 accent-washed metric cards, HR sparkline, weight trend), fl_chart detail screens (D/W/M, min-avg-max, history, BP paired series + 90–120 normal band), manual entry sheets (water/weight/BP → Supabase + HC hydration), reminders (daily zonedSchedule, inexact alarms, Android 13+ permission — verified live on emulator incl. permission dialog), settings with editable goals. Light+dark verified. 10 widget tests green. Note: flutter_local_notifications 22 uses named params (settings:/id:/scheduledDate:/notificationDetails:); flutter_timezone 5 returns TimezoneInfo (.identifier).
- Phase 5 ✅: web dashboard live at **https://vitapulse-vert.vercel.app** (Vercel project `vitapulse`, scope `heinendez`). Deploy: `flutter build web --release --dart-define-from-file=env.json` then `vercel deploy --prod` from repo root (root `vercel.json` serves prebuilt `build/web`, `.vercelignore` whitelists only the bundle; `web/vercel.json` ships the SPA rewrite inside the bundle). Verified live: sign-in + dashboard rendering synced data, sidebar rail, 4-col grid. Vercel CLI authenticated via email-link login on this machine.
- Phase 6 ✅: repo **github.com/AtangaHeinendez/vitapulse** (private at the time; made public 2026-07-13 — see verification section), release signing (upload-keystore.jks + key.properties, debug fallback — keystore MUST be backed up), 11 Actions secrets set via gh CLI (ENV_JSON, ANDROID_KEYSTORE_BASE64, KEYSTORE/KEY passwords+alias, FIREBASE_APP_ID/SERVICE_ACCOUNT/TESTERS, VERCEL_TOKEN/ORG_ID/PROJECT_ID). Firebase project vitapulse-8fbdd, App ID 1:364416149584:android:73a17a88918e410e5ac955. CI green end-to-end (run 28906069632): push to main → analyze+test → signed APK → Firebase App Distribution (direct tester emails via FIREBASE_TESTERS — the `groups: testers` alias 404'd) → web build → Vercel prod. Gotchas: set multiline/binary secrets from Windows via `cmd /c type file | gh secret set` (PS 5.1 pipes append CRLF that breaks `base64 -d` on Linux; `--body` mangles embedded JSON quotes). Local SA key in gitignored `firebase_service-account_key/` folder.
- Phase 3 ✅: Health Connect wired per health 13.3.1 README (manifest permissions, rationale filters, FlutterFragmentActivity). HealthSource abstraction with HealthConnectSource + MockHealthSource (`--dart-define=MOCK_HEALTH=true`); pedometer fallback (midnight-baseline, fixed-timestamp upsert row, source='pedometer'). Sync verified on emulator with mock data: 1059 samples → health_metrics (all 9 types) → recompute_daily_summaries RPC → 30 daily_summaries rows with correct aggregates. Physical-device HC test pending until a phone is plugged in (user must enable Samsung Health → Settings → Health Connect data sync).
