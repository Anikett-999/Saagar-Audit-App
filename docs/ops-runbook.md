# Saagar Audit App — Production Operations Runbook

**Version**: 1.0 (Production Release Candidate)  
**Target Stores**: Saagar Footwear Latur (`WLMHW` — Wholesale & Main Retail; `HEMW` — Premium High-End)  
**Primary Database**: SQLite `saagar_audit.db` (Local Offline-First Single Source of Truth)  
**Cloud Mirror**: Google Cloud Firestore & Firebase Storage (`saagar-audit-app-latur`)  

---

## 1. System Architecture & Offline Invariants

1. **Rule 3 — Offline-First Supreme**:
   - The Android tablet/phone operates 100% autonomously without active internet connectivity.
   - All audit conduct (Daily, Weekly, Monthly), CAP lifecycle management, 7-day reviews, score calculations, PDF generation, and PIN authentication run against local SQLite.
   - Network disruption must never block, freeze, or discard auditor actions.

2. **Deterministic Cloud Mirror**:
   - Cloud Firestore and Firebase Storage are strictly asynchronous read/write mirrors.
   - Synchronization is orchestrated via `SyncService` and `WorkManager`:
     - **Push sync**: Unsynced mutations in SQLite are batched and pushed to Firestore collections (`audits`, `audit_results`, `caps`, `cros`, `users`, etc.).
     - **Pull sync**: Remote updates are merged locally using last-write-wins timestamps.
     - **Photo mirror**: Photos are uploaded to `photos/{photoId}.jpg` in Firebase Storage; local path remains cached on disk.

3. **Rule 4 — PIN Security Invariant**:
   - `pin_hash` (bcrypt) is NEVER pushed to Firestore or cloud storage under any circumstance.
   - Remote `users` documents contain strictly `id`, `name`, `role`, `status`, and `language_pref`.

4. **Rule 6 — Audit Immutability**:
   - Once an audit is submitted (`status = 'submitted'`), its scores, checkpoints, notes, and photos are strictly immutable. Any modification attempt throws a `StateError`.

---

## 2. Backup & Disaster Recovery Procedures

### 2.1 Automated Cloud Mirroring
- **Periodic Background Sync**: Runs every 6 hours via Android WorkManager when connected to an unmetered/metered network.
- **Immediate Post-Submit Sync**: Tapping "Submit Audit" automatically enqueues an asynchronous background sync job.

### 2.2 Manual Full Database JSON Export (Screen S32)
1. On the store tablet, navigate to **Settings Hub** (Screen S27) $\rightarrow$ **Backup / Export Data** (Screen S32).
2. Tap **"Export All Data (JSON)"**.
3. All 14 SQLite database tables (`stores`, `departments`, `users`, `cros`, `checkpoints`, `audits`, `audit_results`, `photos`, `caps`, `cap_actions`, `cap_log`, `escalations`, `reports`, `audit_log`) are serialized into a timestamped file:
   `/storage/emulated/0/Download/saagar_audit_backup_YYYYMMDD_HHMMSS.json`
4. Copy this JSON file to a secure off-device USB drive or Google Drive weekly.

### 2.3 Device Replacement & Disaster Recovery
If the primary store tablet is lost, damaged, or wiped:
1. Provision a new Android tablet running Android 10+ (API 29+).
2. Install the production signed release APK (`app-release.apk`).
3. Place `google-services.json` in the build configuration or launch with active internet connectivity.
4. On first launch, the app connects to Cloud Firestore (`saagar-audit-app-latur`) and pulls the latest store configuration, active users, CRO roster, historical audits, and active CAPs.
5. The Owner logs in with their established credentials and verifies data integrity on Screen S12 (History) and Screen S14 (CAPs).

---

## 3. User Administration & Access Control

### 3.1 Role Hierarchy
- **OWNER**: Full system authority. Conducts Daily, Weekly, and Monthly audits; manages users (S29); triggers cloud sync (S32); marks reports as read (S21); can reopen closed CAPs.
- **GM (General Manager)**: Oversees store operations. Conducts Daily and Weekly audits; performs 7-day reviews (T2.3); verifies CAPs (S18) and closes verified CAPs (S19); reviews escalations (S33).
- **SM (Store Manager)**: Conducts Daily audits; opens CAPs (S15); marks action steps complete and marks CAPs as Done (S17); views own audit history.

### 3.2 PIN Reset Procedure
1. Only the **Owner** can reset a user's PIN via Screen S29 (**Manage Users**).
2. Select the user $\rightarrow$ Tap **"Reset PIN"** $\rightarrow$ Enter the new 4-digit PIN.
3. The new PIN is immediately hashed using local bcrypt with a cost factor of 12 and committed to SQLite.

### 3.3 Account Lockout Defense (DEF-01)
- If 3 consecutive incorrect PINs are entered within 60 seconds, the account is locked for 60 seconds.
- The lockout duration is persisted to `SharedPreferences` and survives app restarts and process kills.
- To clear an accidental lockout immediately in an emergency, the Owner can restart the tablet or wait out the 60-second ticker on Screen S04.

---

## 4. Operational Incident & Escalation Routing

### 4.1 7 Mandatory Escalation Triggers (Appendix A.5)
- **Trigger 1 (Daily Critical < 80%)**: Dispatched immediately. GM receives alert. If cause is Cash or Inventory, Owner receives dual dispatch.
- **Trigger 2 (Repeated Checkpoint Failure)**: Checkpoint failing $\ge 5$ of last 7 daily audits triggers automated escalation on weekly audit submission.
- **Trigger 3 (Cash Variance > ₹500)**: Consecutive days breach triggers direct Owner alert.
- **Trigger 4 (Weekly Inventory Variance > 2.0%)**: Dispatched on weekly audit submission to Owner.
- **Trigger 5 (Security Concern Flag)**: Auditor flags security switch on any checkpoint $\rightarrow$ instant dispatch to Owner.
- **Trigger 6 (Manual Escalation)**: Raised by SM/GM via Screen S33 for urgent store floor incidents.
- **Trigger 7 (3-Week Declining Trend)**: Multi-week trend analytics detects monotonic score decline $\rightarrow$ dispatched to GM & Owner.

### 4.2 Standard 4-Part Escalation Message
All alerts generated by `EscalationEngine` strictly adhere to the 4-part structure (Spec §7.2):
```text
🚨 [ESCALATION T1: Daily Critical Score]
Store: Saagar Footwear Latur (WLMHW)
Date: YYYY-MM-DD

1. What Happened: Daily audit scored 76.5% (Critical band <80%).
2. Evidence: 4 non-compliances logged across Cash and Inventory SOPs with photos attached.
3. Impact: High risk of inventory shrinkage and cash discrepancy.
4. Requested Action: Immediate GM floor review and mandatory CAP opening within 24 hours.
```

---

## 5. Release Signing & Production Distribution

### 5.1 Keystore Security
- The production signing keystore (`saagar_release.jks`) is private to Saagar Footwear.
- Signing properties are stored locally in `android/key.properties`:
  ```properties
  storePassword=<SECRET>
  keyPassword=<SECRET>
  keyAlias=saagar_release_key
  storeFile=saagar_release.jks
  ```
- **Never commit `key.properties` or `*.jks` to GitHub.**

### 5.2 Building Release Artifacts
```bash
# Build standalone release APK
flutter build apk --release

# Build Google Play release App Bundle
flutter build appbundle --release
```
- Output APK location: `build/app/outputs/flutter-apk/app-release.apk`
- Output AAB location: `build/app/outputs/bundle/release/app-release.aab`
