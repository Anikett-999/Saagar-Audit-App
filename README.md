# Saagar Audit App

Android app for daily / weekly / monthly retail compliance audits at Saagar Traders' Titan World (`WLMHW`) and Helios (`HEMW`) stores, Latur.

Built per the spec in [`Documentation/Saagar_P1_App_Spec_v1.docx`](Documentation/Saagar_P1_App_Spec_v1.docx). The workbook in [`Documentation/Saagar_P1_Audit_Workbook_v1.docx`](Documentation/Saagar_P1_Audit_Workbook_v1.docx) is the operational ground truth — on any conflict, the workbook wins.

## Status

**Phase 1 — Complete & Signed Off.** All 28 Phase 1 screens (S01–S17, S22–S32) built, verified with 214/214 green tests and physical device UAT.

| Phase | Weeks | Scope | Status |
|---|---|---|---|
| P1 | 1–4 | Daily audit foundation: S1–S17, S22–S32, CAP create + mark done | ✅ Complete & Signed Off |
| P2 | 5–8 | Weekly audit, CAP verify + close, GM dashboard, PDF generation | Next |
| P3 | 9–11 | Monthly audit, escalation engine (7 triggers), trend analytics | Scheduled |
| P4 | 12–13 | Polish, signing, Firestore sync mirror, Play Store internal track | Scheduled |

## Tech stack (LOCKED — see spec §2)

Flutter ≥3.16 · Dart ≥3.2 · sqflite · Firestore · Firebase Storage · local PIN + bcrypt · Riverpod · go_router · ARB EN+MR · `pdf` · `image_picker`/`camera` · `flutter_local_notifications` · `url_launcher` · `fl_chart` · Android API 24+.

No: Firebase Auth · drift/isar · Provider/Bloc · auto_route · iOS · tablet · FCM push.

## How the build works

Every push to `main` triggers a GitHub Actions workflow (`.github/workflows/android-build.yml`) that:

1. Installs Java 17 + Flutter in a clean Ubuntu runner
2. Restores `android/` folder if missing (`flutter create . --platforms=android`)
3. Runs `flutter pub get`, then `flutter test` (canonical score test must pass)
4. Builds `app-debug.apk`
5. Uploads the APK as a workflow artifact

Download the APK from the latest green run → transfer to your Android phone → enable "Install from unknown sources" for the file manager → tap to install.

## If you want to develop locally (optional)

You'll need:

1. **Flutter SDK** — download from <https://docs.flutter.dev/get-started/install/windows>, extract to `C:\flutter`, add `C:\flutter\bin` to your PATH.
2. **Android Studio** — for the Android SDK + emulator. <https://developer.android.com/studio>
3. **Java 17** — bundled with recent Android Studio.

Then:

```powershell
flutter doctor          # fix any red items
flutter pub get
flutter test            # run score engine & widget tests
flutter run             # build & install to connected device or emulator
```

## Repository layout (Spec §15.2 / §15.4)

The Flutter app lives at the **repository root** (`lib/`, `test/`, `android/`, `assets/`, `pubspec.yaml`, etc. sit directly in the repo root). Phases (`phase-1`…`phase-4`) are Git branches, never directories.

```
saagar-audit-app/
├── lib/                          # All Dart source
│   ├── main.dart                 # App entry
│   ├── app.dart                  # MaterialApp + go_router root
│   ├── data/                     # Models, DB, repositories, seed loaders
│   ├── domain/                   # Score engine, escalation engine, CAP state machine, PDF generator
│   ├── providers/                # Riverpod providers
│   ├── ui/
│   │   ├── theme/                # Saagar design system (navy + gold + DM Serif + DM Sans)
│   │   ├── screens/sNN_name/     # One folder per screen
│   │   └── widgets/              # Shared widgets (numpad, score pill, etc.)
│   └── utils/
├── assets/
│   ├── seed/                     # sops.json, checkpoints.json (loaded on first launch)
│   ├── translations/             # app_en.arb, app_mr.arb (kept in lock-step)
│   ├── reference/                # rating_scale.json, glossary.json, etc.
│   └── images/
├── test/                         # Unit tests; canonical score tests must pass
├── android/                      # Android project scaffolding
├── brain/                        # Shared brain, architecture docs, specs & handoffs
├── Documentation/                # Original .docx source documents
└── .github/workflows/            # GitHub Actions APK build (android-build.yml)
```

## Canonical correctness checks

The score engine **must** produce these exact values (Workbook §5.1, §5.2):

- Daily canonical: 81 / 90 = **90.0% Good**
- Weekly canonical (P2): 104.8 / 124 = **84.5% Poor**

These are encoded in [`test/score_engine_test.dart`](test/score_engine_test.dart). If those tests ever go red, the engine is wrong.

## Hard rules (spec §14.1)

1. Workbook is ground truth.
2. Tech stack is locked.
3. Both ARB files updated together.
4. Score must match canonical tests.
5. Submitted audits are immutable (only Owner can HIDE).
6. PIN security: bcrypt only, never plaintext, never logged.
7. Mandatory photos on Cash & Inventory Fails.
8. Offline-first — SQLite is source of truth, Firestore is mirror.
9. No out-of-phase features.
10. Commit after every change.