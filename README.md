# Saagar Audit App

Production-grade, offline-first Android application for daily, weekly, and monthly retail compliance audits at Saagar Traders' Titan World (`WLMHW`) and Helios (`HEMW`) stores, Latur.

Built per the specification in [`Documentation/Saagar_P1_App_Spec_v1.docx`](Documentation/Saagar_P1_App_Spec_v1.docx) and operational ground truth in [`Documentation/Saagar_P1_Audit_Workbook_v1.docx`](Documentation/Saagar_P1_Audit_Workbook_v1.docx).

---

## Delivery Status

**ALL 4 PHASES ARE 100% COMPLETE, VERIFIED & SIGNED OFF.**

| Phase | Scope | Status | Verification |
|---|---|---|---|
| **Phase 1** | Daily audit foundation (S01–S17, S22–S32), 10-field CAP create & mark done, SQLite schema, score engine | ✅ Complete & Signed Off | 214/214 tests green · Claude approved · POCO device UAT |
| **Phase 2** | Weekly audit (36 checkpoints), CAP verify (S18) & close (S19), GM dashboard, 7-day review & spot-checks, 1-page PDF | ✅ Complete & Signed Off | 279/279 tests green · Claude approved · POCO device UAT |
| **Phase 3** | Monthly strategic audit (MC.1–MC.3), pure 7-trigger escalation engine & WhatsApp dispatch, CAP auto-aging & WorkManager, multi-week trend analytics & `fl_chart`, monthly PDF | ✅ Complete & Signed Off | 355/355 tests green · Claude approved · POCO device UAT |
| **Phase 4** | Cloud mirror sync (Firestore & Firebase Storage), S32 live sync controls, TalkBack semantics & WCAG AA accessibility, image memory optimization, production release signing | ✅ Complete & Signed Off | 365/365 tests green · Clean analyze (0 issues) · Release builds |

---

## Inviolable Architectural Rules (Spec §14.1)

1. **Workbook is Ground Truth**: Operational definitions, weights, and scoring rules in the workbook strictly supersede all other docs.
2. **Offline-First Remains Supreme (Rule 3)**: SQLite (`saagar_audit.db`) is the local single source of truth. Audits, CAPs, and reports operate 100% offline without network reliance.
3. **Deterministic Cloud Mirror**: Google Cloud Firestore (`saagar-audit-app-latur`) and Firebase Storage are strictly asynchronous read/write mirrors.
4. **PIN Security Invariant (Rule 4)**: PINs are strictly hashed with local bcrypt (cost factor 12). `pin_hash` is NEVER transmitted to Firestore or logged.
5. **Submitted Audits are Immutable (Rule 6)**: Once submitted, audits cannot be edited or modified (throws `StateError`).
6. **Mandatory Photo Evidence (Rule 7)**: Cash and Inventory non-compliances strictly require photo evidence before submission.
7. **Dual-Language Parity (Rule 8)**: 100% 1:1 string parity between English (`app_en.arb`) and authentic Marathi Devanagari (`app_mr.arb`).
8. **Canonical Score Invariants**:
   - Daily canonical: 81 / 90 = **90.0% Good**
   - Weekly canonical: 104.8 / 124 = **84.5% Poor**
   - Monthly canonical: 5 / 5 = **100.0% Excellent**

---

## Tech Stack (Locked — Spec §2)

- **Framework**: Flutter ≥ 3.16 · Dart ≥ 3.2
- **State Management**: Riverpod (`flutter_riverpod`)
- **Navigation**: GoRouter (`go_router`)
- **Persistence**: SQLite (`sqflite`) · SharedPreferences (lockout defense)
- **Cloud Mirror**: Cloud Firestore (`cloud_firestore`) · Firebase Storage (`firebase_storage`)
- **Security**: Local BCrypt (`bcrypt`)
- **Localization**: Flutter gen-l10n (`app_en.arb`, `app_mr.arb`)
- **Background Jobs**: Android WorkManager (`workmanager`)
- **Reporting & Charts**: PDF (`pdf`) · Printing (`printing`) · Charts (`fl_chart`)
- **Design System**: Saagar Luxury Palette (Navy `#1A2B4C`, Gold `#B8922A`, Cream `#FAF8F3`, DM Serif Display, DM Sans)

---

## Local Development & Testing

```powershell
# 1. Fetch dependencies
flutter pub get

# 2. Run static analyzer (must be 0 issues)
flutter analyze

# 3. Run full automated test suite (365 tests)
flutter test

# 4. Run canonical score engine test
flutter test test/score_engine_test.dart
```

---

## Building Production Releases

### 1. Release Keystore Setup
Copy `android/key.properties.example` to `android/key.properties` and fill in your signing credentials:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=saagar_release_key
storeFile=saagar_release.jks
```
*(If `android/key.properties` is absent, the build automatically and safely falls back to debug signing for testing).*

### 2. Build Release Artifacts
```powershell
# Build standalone signed release APK
flutter build apk --release

# Build Google Play release App Bundle
flutter build appbundle --release
```

- **Release APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Release App Bundle**: `build/app/outputs/bundle/release/app-release.aab`

---

## Operations & Disaster Recovery Runbook

For complete operational procedures including database backup/restoration, user provisioning, PIN resets, cloud synchronization, and escalation routing, refer to [`docs/ops-runbook.md`](docs/ops-runbook.md).