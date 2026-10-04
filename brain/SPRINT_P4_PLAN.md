# Phase 4 Sprint Plan — Cloud Mirror, Polish, Performance & Release

**Phase**: 4 of 4 (Weeks 12–13)  
**Lead Architect**: Antigravity  
**Target Completion Date**: 2026-10-18  
**Pre-condition**: Phases 1, 2, and 3 100% complete, merged to `main` at `fa3d51b`.  
**Branch**: `phase-4` (feature branches off `phase-4`)

---

## 1. Executive Summary & Goals (Spec §12, §14.5, §16.4)
Phase 4 elevates the Saagar Audit App from a locally complete offline application into a cloud-mirrored, production-signed release candidate ready for the Google Play Store internal track.

### Inviolable Architectural Principles
1. **Offline-First Remains Supreme (Rule 3)**: SQLite (`saagar_audit.db`) is ALWAYS the single source of truth. The app must boot, authenticate with local bcrypt PIN, conduct daily/weekly/monthly audits, log CAPs, and generate reports 100% offline. Cloud (Firestore / Storage) is strictly an asynchronous mirror. A device with no network connectivity must never block, lag, or fail.
2. **Deterministic Conflict Resolution (Spec §1.3)**: Last-write-wins based on server timestamp, while every mutation is logged in SQLite `audit_log` with device ID and actor ID so no audit history is lost.
3. **Dual-Language Parity (Rule 8)**: Every new sync status, error message, and release label must have 100% identical English and authentic Marathi parity.
4. **Zero Regressions (Rule 5 & 6)**: The 355-test suite and score engine invariants must remain green throughout.

---

## 2. Sprint Breakdown

### Sprint P4-1: Cloud Mirror & Storage Sync Engine (Days 1–5)
- **Branch**: `feature/p4-cloud-mirror-sync`
- **Deliverables**:
  1. **Firebase Initialization & Safe Boot**:
     - Conditional, non-blocking `Firebase.initializeApp()` in `main.dart`.
     - Graceful degradation: if `google-services.json` is missing or device has no Play Services, app logs a warning and operates in pure offline mode.
  2. **`SyncService` & Firestore Data Sync**:
     - Map all 14 SQLite tables to Firestore collections: `audits`, `audit_results`, `caps`, `cap_actions`, `cap_log`, `escalations`, `reports`, `users`, `cros`, `stores`, `departments`, `checkpoints`, `rating_scale`, `glossary`.
     - **Push Sync**: Queries `audit_log` where `sync_state = 'pending'`. Batches documents into Firestore writes; upon success, sets `sync_state = 'synced'`.
     - **Pull Sync**: Queries Firestore for documents updated since `devices.last_sync_at`. Merges into SQLite without overwriting newer local edits. Updates `devices.last_sync_at`.
     - **Network Awareness**: Uses `connectivity_plus` to automatically trigger sync when connectivity is restored.
  3. **Photo Cloud Mirror (Firebase Storage)**:
     - Background upload worker for photos where `upload_status = 'pending'`.
     - Compresses and uploads to Firebase Storage path: `stores/{storeId}/photos/{photoId}.jpg`.
     - Updates SQLite `photos` row with `cloud_url` and `upload_status = 'uploaded'`.
  4. **S32 Backup & Export Sync Controls**:
     - Remove "Coming in Phase 4" badge.
     - Enable "Force Cloud Sync" button for Owner.
     - Real-time sync status tile: Last synced time, pending change count, and live sync progress indicator.
  5. **Auto-Trigger Wiring**:
     - Post-submit trigger on S10 (Review & Submit) — non-blocking async trigger.
     - Periodic background sync via WorkManager (every 6 hours when connected to network).
  6. **Testing**:
     - Mock Firestore / SQLite sync tests verifying delta sync, conflict resolution, offline queueing, and retry on failure.

---

### Sprint P4-2: Performance, Accessibility & Bug Triage Pass (Days 6–9)
- **Branch**: `feature/p4-performance-accessibility`
- **Deliverables**:
  1. **Performance Hardening (Spec §16.4)**:
     - Audit conduct tap latency profiling: ensure checkpoint selection and score calculation respond in <100ms.
     - ListView memory optimizations (`ListView.builder`, item extent caching).
     - Image caching optimization for photos and signatures.
     - Cold boot startup time profiling (<3s target).
  2. **Accessibility (TalkBack / WCAG AA)**:
     - Semantics labels on all IconButtons, custom Radio tiles, PIN numpad digits, and trend charts.
     - Color contrast verification: ensure all text meets ≥ 4.5:1 ratio against background cards.
     - Accessibility Scanner audit clean pass.
  3. **Comprehensive Edge-Case Gauntlet**:
     - Offline $\leftrightarrow$ Online transition stress testing.
     - Low-storage space warning check.
     - Clock drift / timezone validation.

---

### Sprint P4-3: Production APK Signing & Release Readiness (Days 10–13)
- **Branch**: `feature/p4-release-signing`
- **Deliverables**:
  1. **Keystore & Gradle Signing Configuration**:
     - Create release signing key properties template (`android/key.properties`).
     - Configure `android/app/build.gradle.kts` release signing block.
     - ProGuard / R8 rules optimization in `android/app/proguard-rules.pro`.
  2. **Production Builds**:
     - Build release APK: `flutter build apk --release`.
     - Build release App Bundle: `flutter build appbundle --release` (Play Store target).
  3. **Documentation & Runbook**:
     - `docs/ops-runbook.md`: Operations guide covering database backup restoration, user provisioning, and device recovery.
     - `README.md`: Complete build, run, and release instructions.
     - Final UAT verification checklist for Owner device.

---

## 3. Definition of Done for Phase 4 (Spec §16.4)
- [ ] Firestore sync mirrors all 14 tables asynchronously and accurately.
- [ ] Photos upload to Firebase Storage with local fallback always functional.
- [ ] S32 Force Cloud Sync button and live sync status operational for Owner.
- [ ] Tap response <100ms across all audit conduct screens.
- [ ] TalkBack labels and WCAG AA contrast verified.
- [ ] Release APK and App Bundle build cleanly with valid signing config.
- [ ] All 355+ tests passing with 0 analyze issues.
