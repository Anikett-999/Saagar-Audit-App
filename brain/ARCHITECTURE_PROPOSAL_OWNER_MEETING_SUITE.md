# Architecture Proposal: Integration of Executive Meeting & Personal Suite into Saagar Audit App

**Document Version:** 1.1.0 (Post-Review Revision)  
**Date:** October 6, 2026  
**Status:** APPROVED FOR MVP IMPLEMENTATION  
**Author:** AI Engineering & Architecture Team (Antigravity & Claude)  
**Target Systems:**  
- **Host App:** `E:\projects\Saagar Audit App` (Production Retail Compliance Suite)  
- **Source Module:** `E:\projects\sagar_meeting_app` ("RECALL" Executive Meeting & Notes App)  

---

## 1. Executive Summary & Verdict

Following architectural peer review, this proposal is signed off with **CONDITIONAL GO** refinements. The architecture integrates the executive calendar, meetings, people directory, and private notes from `sagar_meeting_app` into `Saagar Audit App` as a strictly **Owner-Only Personal Module**.

### Core Invariants
1. **Host App Integrity:** Zero breaking changes to the retail audit app. All 365 existing tests must remain green.
2. **Access Control:** Available exclusively to users with `role == 'OWNER'`. Store Managers (SM) and General Managers (GM) have zero UI visibility, zero navigation routes, and zero repository access.
3. **Database Unification:** Single `saagar_audit.db` via `sqflite` (Schema v4). Drift and `build_runner` are discarded.
4. **Cloud Isolation:** Dual Firebase projects. Operational retail audits live in `saagar-audit-app-latur`; Owner personal data syncs to `sagar-meeting-app-v2`.
5. **Client-Side Cryptography:** Sensitive at-rest data encrypted with AES-256-GCM using hardware-backed keys.

---

## 2. Table of Architectural Decisions

| Area | Decision | Implementation Details |
| :--- | :--- | :--- |
| **Database** | Unified SQLite (`saagar_audit.db`) | Schema v4 with dedicated `owner_*` prefix tables. |
| **ORM / Drivers** | Standard `sqflite` | Drift discarded. Zero `build_runner` or dual-C library bloat. |
| **Authentication** | Local 4-Digit Owner PIN | No external OAuth / Google Sign-In. Frictionless offline UX. |
| **Key Management** | Hardware-Backed Keystore | Cryptographically random 256-bit AES key stored in Android Keystore via `flutter_secure_storage`. Decoupled from the 4-digit PIN to prevent brute-force cracking. |
| **Cloud Project** | Secondary Firebase Project B | `sagar-meeting-app-v2` initialized on demand via secondary `FirebaseApp`. |
| **Cloud Sync** | WorkManager + Outbox Pattern | Atomic `owner_sync_outbox` table in SQLite; WorkManager handles reliable background execution. |
| **Device Control** | Owner Device Management | Unique `device_id` tracking with the ability to revoke/block unauthorized devices from syncing. |
| **S32 Export** | Strict Whitelist | S32 only exports explicit store audit tables. All `owner_*` tables are excluded by design. |

---

## 3. Database Architecture: Schema v4

The v3 $\rightarrow$ v4 migration runs inside a single atomic transaction:

```sql
BEGIN TRANSACTION;

-- 1. Executive Meetings & Events
CREATE TABLE IF NOT EXISTS owner_events (
  id                TEXT PRIMARY KEY,
  owner_id          TEXT NOT NULL REFERENCES users(id),
  category          TEXT NOT NULL,
  title             TEXT NOT NULL, -- Encrypted AES-256
  start_time        INTEGER NOT NULL,
  end_time          INTEGER,
  location          TEXT,          -- Encrypted AES-256
  meeting_link      TEXT,          -- Encrypted AES-256
  description       TEXT,          -- Encrypted AES-256
  status            TEXT NOT NULL DEFAULT 'upcoming',
  reschedule_count  INTEGER NOT NULL DEFAULT 0,
  reminder_type     TEXT NOT NULL DEFAULT 'notification',
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL
);

-- 2. Executive Contacts & People Directory
CREATE TABLE IF NOT EXISTS owner_people (
  id                TEXT PRIMARY KEY,
  owner_id          TEXT NOT NULL REFERENCES users(id),
  first_name        TEXT NOT NULL, -- Encrypted AES-256
  last_name         TEXT NOT NULL, -- Encrypted AES-256
  phone             TEXT,          -- Encrypted AES-256
  company           TEXT,          -- Encrypted AES-256
  dedup_key         TEXT NOT NULL,
  last_meeting_at   INTEGER,
  meeting_count     INTEGER NOT NULL DEFAULT 0,
  is_deleted        INTEGER NOT NULL DEFAULT 0,
  deleted_at        INTEGER,
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL
);

-- 3. Meeting Attendees
CREATE TABLE IF NOT EXISTS owner_meeting_attendees (
  id                TEXT PRIMARY KEY,
  event_id          TEXT NOT NULL REFERENCES owner_events(id) ON DELETE CASCADE,
  person_id         TEXT NOT NULL REFERENCES owner_people(id),
  name_snapshot     TEXT NOT NULL,
  company_snapshot  TEXT,
  added_at          INTEGER NOT NULL
);

-- 4. Event Reminders & Notification Triggers
CREATE TABLE IF NOT EXISTS owner_event_reminders (
  id                TEXT PRIMARY KEY,
  event_id          TEXT NOT NULL REFERENCES owner_events(id) ON DELETE CASCADE,
  offset_value      INTEGER NOT NULL,
  offset_unit       TEXT NOT NULL,
  scheduled_at      INTEGER NOT NULL,
  notification_id   INTEGER NOT NULL,
  is_fired          INTEGER NOT NULL DEFAULT 0,
  created_at        INTEGER NOT NULL
);

-- 5. Reschedule History
CREATE TABLE IF NOT EXISTS owner_event_history (
  id                TEXT PRIMARY KEY,
  event_id          TEXT NOT NULL REFERENCES owner_events(id) ON DELETE CASCADE,
  change_type       TEXT NOT NULL,
  previous_start_time INTEGER,
  new_start_time    INTEGER,
  rescheduled_at    INTEGER NOT NULL,
  reschedule_count  INTEGER NOT NULL
);

-- 6. Private Executive Notes
CREATE TABLE IF NOT EXISTS owner_notes (
  id                TEXT PRIMARY KEY,
  owner_id          TEXT NOT NULL REFERENCES users(id),
  note_type         TEXT NOT NULL,
  event_id          TEXT REFERENCES owner_events(id) ON DELETE CASCADE,
  person_id         TEXT REFERENCES owner_people(id) ON DELETE CASCADE,
  title             TEXT,          -- Encrypted AES-256
  body              TEXT NOT NULL, -- Encrypted AES-256
  is_deleted        INTEGER NOT NULL DEFAULT 0,
  deleted_at        INTEGER,
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL
);

-- 7. Guaranteed Sync Outbox
CREATE TABLE IF NOT EXISTS owner_sync_outbox (
  id                TEXT PRIMARY KEY,
  entity_type       TEXT NOT NULL, -- event, person, note
  entity_id         TEXT NOT NULL,
  operation         TEXT NOT NULL, -- upsert, delete
  payload_json      TEXT NOT NULL, -- Encrypted ciphertext payload
  created_at        INTEGER NOT NULL,
  retry_count       INTEGER NOT NULL DEFAULT 0,
  status            TEXT NOT NULL DEFAULT 'pending' -- pending, syncing, synced, failed
);

COMMIT;
```

---

## 4. Cryptographic Security Architecture

### 4.1 Decoupled Key Hierarchy
```text
Owner enters 4-digit PIN
       ↓
Verified via bcrypt hash in SQLite users table
       ↓
Local Owner Session Authenticated
       ↓
Android Keystore (Hardware Security Module)
       ↓
Unlocks random 256-bit AES Master Key (flutter_secure_storage)
       ↓
AES-256-GCM Encryption / Decryption of sensitive fields
```

1. **No Brute-Force Vulnerability:** The 4-digit PIN is **never** used as the mathematical root for the encryption key. Brute-forcing the 4-digit PIN gives an attacker zero cryptographic progress against the AES-256 ciphertext.
2. **Random IV / Nonce:** Every encryption call uses a cryptographically secure 96-bit random nonce (`IV`). Nonces are never reused.
3. **Format:** Ciphertext is persisted as: `v1:<nonce_base64>:<ciphertext_base64>:<auth_tag_base64>`.

---

## 5. Cloud Backup & Device Management

### 5.1 Multi-Firebase Project Setup
* **Store Audits:** `saagar-audit-app-latur` (Default Firebase app via `google-services.json`).
* **Owner Personal Module:** `sagar-meeting-app-v2` (Secondary named `FirebaseApp` instance).

```dart
final ownerApp = await Firebase.initializeApp(
  name: 'OwnerPersonalSuite',
  options: const FirebaseOptions(
    apiKey: 'AIzaSyAERwRJ7DPOCmgve8Pst_t8Zi1LbSjnUzs',
    appId: '1:525800878718:android:4a91c5aab53ff404125e2f',
    messagingSenderId: '525800878718',
    projectId: 'sagar-meeting-app-v2',
    storageBucket: 'sagar-meeting-app-v2.firebasestorage.app',
  ),
);
final ownerFirestore = FirebaseFirestore.instanceFor(app: ownerApp);
```

### 5.2 Device Registry & Revocation
* Every installation records its `device_id` (UUID from the `devices` table).
* In Firestore Project B under `/owner_vault/metadata/authorized_devices`, each active device is logged with its device name and last sync timestamp.
* Inside the Owner Module settings, the Owner can view all synced devices and click **"Revoke Device"**.
* Revoked devices are permanently blocked from uploading or pulling personal data.

### 5.3 Reliable Background Sync (WorkManager + Outbox)
1. Any insert/update/delete in `owner_events`, `owner_people`, or `owner_notes` simultaneously inserts a record into `owner_sync_outbox` inside the **same SQLite transaction**.
2. Android `WorkManager` triggers `OwnerSyncWorker`.
3. The worker queries pending outbox records, connects to `sagar-meeting-app-v2`, uploads the ciphertext payloads, and marks outbox records as `synced`.
4. If network is unavailable or the app is killed, WorkManager automatically retries with exponential backoff.

---

## 6. S32 Backup Whitelist Protection

Screen S32 (`Backup & Export`) strictly whitelists store operational tables:

```dart
static const List<String> allowedStoreAuditTables = [
  'audits',
  'audit_results',
  'photos',
  'caps',
  'cap_actions',
  'cap_log',
  'cros',
  'sops',
  'checkpoints',
  'weekly_reports',
  'escalations',
  'sync_queue',
];
```
No `owner_*` table can ever be included in general store exports.

---

## 7. UI Integration & Navigation

### 7.1 Owner-Only Gating
* Module routes are prefixed: `/owner/meetings`, `/owner/calendar`, `/owner/notes`, `/owner/people`.
* `GoRouter` redirect blocks non-Owner access:
  ```dart
  if (state.matchedLocation.startsWith('/owner/') && authState.user?.role != 'OWNER') {
    return '/home';
  }
  ```

### 7.2 Entry Point on Screen S05 (Owner Dashboard)
* Rendered **strictly** when `currentUser.role == 'OWNER'`.
* A luxury gold-bordered card: **"Executive Hub / संचालक कक्ष"**.
* Quick-launch buttons:
  - `[ 📅 Calendar / बैठक ]`
  - `[ 📝 Notes / टिप्पण्या ]`
  - `[ 👥 Directory / संपर्क ]`

---

## 8. MVP Phasing & Execution Plan

```mermaid
graph TD
    A[Phase 1: DB Schema v4 Migration & Outbox] --> B[Phase 2: AES-256 Crypto & Keystore Service]
    B --> C[Phase 3: Repositories & Data Layer]
    C --> D[Phase 4: UI Migration to lib/ui/owner_suite/]
    D --> E[Phase 5: GoRouter Guards & S05 Hub Card]
    E --> F[Phase 6: WorkManager Sync & Firebase Project B]
    F --> G[Phase 7: Full Test Suite Verification]
```

### Sign-off Status
* Core Architecture: **APPROVED**
* Security Hardening: **REVISED & LOCKED**
* Execution: **Ready to proceed on Owner's call.**
