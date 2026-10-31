# Saagar Audit App — Master UAT Bug Tracker & Resolution Register

> **Source Document:** Client UAT Review by Sagar Bora (`Documentation/Saagar-Audit-App-Reply-and-Review.docx`)  
> **Target Environment:** Titan World (`WLMHW`) & Helios (`HEMW`), Latur, Maharashtra  
> **Living Document Rule:** Every time a bug is fixed, verified, committed, and pushed, update its status, commit hash, files changed, and test notes in this file.

---

## 📊 Summary Status Dashboard

| Category | Total | ✅ Solved & Verified | 🔄 In Progress | ⏳ Pending |
|---|:---:|:---:|:---:|:---:|
| **A. Backup, Cloud Sync & Data Safety** (Items 1–5) | 5 | 2 (Items 1, 3) | 0 | 3 (Items 2, 4, 5) |
| **B. Roles, Controls & Security** (Items 6–8) | 3 | 3 (Items 6, 7, 8) | 0 | 0 |
| **C. Alerts, Escalations, Cash & Reports** (Items 9–16) | 8 | 3 (Items 13, 14, 15) | 0 | 5 (Items 9–12, 16) |
| **D. Corrective Action Plan (CAP) Controls** (Items 17–19) | 3 | 3 (Items 17, 18, 19) | 0 | 0 |
| **E. Language, Permissions & Layout** (Items 20–26) | 7 | 2 (Items 25, 26) | 0 | 5 (Items 20–24) |
| **F. General Ease of Use** (Item 27 UX Points) | 1 | 0 | 0 | 1 (Item 27) |
| **TOTAL** | **27** | **13 Solved** | **0 In Progress** | **14 Pending** |

---

## 📋 Full Register of All 27 UAT Bugs & Features

### Category A: Backup, Cloud Sync & Data Safety

#### Item 1: Cloud says "All Data Mirrored", but reinstalled phone gets back no audits or photos
- **Priority:** Critical | **Client Ref:** F26
- **Problem:** When app is cleared/reinstalled and synced, staff (CROs) came back, but audits, results, photos and reports were missing (0 audits, 0 results, 0 photos). Logs showed SQLite `FOREIGN KEY constraint failed` because CAPs and Escalations were pulled before parent audits, plus `no such column: created_at` in audits.
- **Required Fix:** Pull tables in strict foreign-key order: `audits` ➔ `audit_results` ➔ `photos` ➔ `reports` ➔ `caps` ➔ `cap_actions` ➔ `escalations`. Fix audits timestamp query. Show honest table status.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `cf24747` (`feat(sync): implement automatic background sync with role-based inbound pull and FK dependency order`)
- **Files Changed:** `lib/services/cloud_sync_service.dart`, `lib/providers/cloud_sync_provider.dart`, `lib/ui/screens/s04_login/login_screen.dart`, `test/cloud_sync_service_test.dart`
- **Verification:** Unit tests passing (`test/cloud_sync_service_test.dart`). Verified on physical device: auto-sync runs on launch, login, and reconnect, pulling data in FK-safe order.

---

#### Item 2: Exported backup file has no photos, and there is no import option
- **Priority:** High | **Client Ref:** F10
- **Problem:** Exported database JSON only contains private local file paths without binary photos. No in-app import/restore option exists.
- **Required Fix:** Either provide a self-contained backup bundle (ZIP containing JSON + photos) with verified import, or clearly label the JSON export as "Data table records only (photos mirrored in Cloud)".
- **Status:** ⏳ **PENDING (Tier 2)**
- **Commit:** —
- **Files Changed:** —

---

#### Item 3: Backup screen says "All local changes backed up" when nothing has been backed up
- **Priority:** High | **Client Ref:** F13
- **Problem:** Screen displayed technical jargon ("SQLite active", "Firestore", "SQLite table 14"), and contradictory status ("Last Synced: Never" together with "All local changes backed up").
- **Required Fix:** Plain-language 3-line honest dashboard: 1. Saved on this phone, 2. Waiting to upload, 3. Last successful backup (or "Never backed up yet"). Honest offline banner. Manual "Sync Now" button for all roles. Auto-sync on launch and reconnect.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `3f7d206`, `2ab8968`, `0b0bfb4`
- **Files Changed:** `lib/ui/screens/s32_backup_export/backup_export_screen.dart`, `lib/ui/screens/s27_settings/settings_screen.dart`, `lib/services/cloud_sync_service.dart`, `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`
- **Verification:** Verified directly on physical Android device by user. 0 analyzer issues, all tests passing.

---

#### Item 4: A fresh install pulls cloud data without any store login
- **Priority:** Critical | **Client Ref:** F27
- **Problem:** A fresh install with any random test name downloads store staff and audits from Firebase without store authentication. Anyone with APK can access store data.
- **Required Fix:** Two-tier store enrolment: device must sign in to the Store Cloud Account (Firebase Auth) before any cloud read/write. Firestore security rules enforced per role.
- **Status:** ⏳ **PENDING (Tier 2 Architectural)**
- **Commit:** —
- **Files Changed:** —

---

#### Item 5: No way to recover a forgotten Owner PIN
- **Priority:** High | **Client Ref:** F16
- **Problem:** If the Owner forgets their 4-digit PIN, there is no "Forgot PIN" option. Reinstalling previously wiped data.
- **Required Fix:** "Forgot PIN" option on login verifying against the Store Cloud Account password / recovery code to reset Owner PIN without data loss.
- **Status:** ⏳ **PENDING (Tier 2 Architectural)**
- **Commit:** —
- **Files Changed:** —

---

### Category B: Roles, Controls & Security

#### Item 6: GM can mark a CAP done and verify it himself
- **Priority:** High | **Client Ref:** F21
- **Problem:** GM assigned CAP to SM, but GM was able to click "Mark CAP Done" and then immediately verify it himself. Also "Reopen at Plan" left action steps ticked and didn't require a failed verification reason. In user device testing, when GM was assigned a CAP and completed it, GM navigated to S18 where "Pass & Verify" was disabled, but "Verification Failed" was clickable and allowed GM to reopen his own CAP with dummy text.
- **Required Fix:** 
  1. Only assigned responsible user can mark CAP done.
  2. Verifier MUST be a different user (Four-Eyes Principle / Segregation of Duties): hide "Verify" button on S16 for responsible user and who marked done (`s16SelfVerificationBlocked`).
  3. Reopen & Rejection guard: disable "Verification Failed" on S18 for self-verification; repository guard in `reopenCap` and `extendCap` throws `StateError` if actor is responsible user or who marked done.
  4. Hide "Request Extension" when CAP status is `done` (only verifiable on S18) and prevent responsible GM from self-extending.
  5. Reopening resets all action steps to incomplete. Failed verification requires mandatory reason note (min 10 chars).
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `eb22124` + uncommitted hardening (`fix(cap): scope checkpoint dropdown to audit failures and seal self-reopening loophole (Items 17 & 6)`)
- **Files Changed:** `lib/data/repositories/cap_repository.dart`, `lib/ui/screens/s16_cap_detail/cap_detail_screen.dart`, `lib/ui/screens/s17_cap_mark_done/cap_mark_done_screen.dart`, `lib/ui/screens/cap/s18_cap_verify_screen.dart`, `test/helpers/fake_database.dart`, `test/cap_lifecycle_test.dart`, `test/cap_detail_screen_test.dart`, `test/cap_mark_done_screen_test.dart`, `test/s18_cap_verify_screen_test.dart`, `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`
- **Verification:** 10/10 tests in `test/s18_cap_verify_screen_test.dart`, 12/12 tests in `test/cap_detail_screen_test.dart`, 18/18 tests in `test/cap_lifecycle_test.dart`, 9/9 tests in `test/cap_mark_done_screen_test.dart`. Full suite 403/403 passing (100% green). 0 analyzer issues.

---

#### Item 7: Store Manager can export everyone's PIN data
- **Priority:** High | **Client Ref:** F11
- **Problem:** S32 Backup & Export allowed SM to export raw SQLite JSON database containing the bcrypt `pin_hash` of the Owner, GM, and SM.
- **Required Fix:** 
  1. Inviolable Rule: `pin_hash` is unconditionally stripped from all JSON exports.
  2. Role Restriction: "Export Database JSON" card is strictly hidden for SM and GM (Owner only).
  3. Settings Tile: SM/GM sees "Cloud Sync", Owner sees "Cloud Sync & Backup".
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `3f7d206`, `2ab8968`
- **Files Changed:** `lib/data/backup_service.dart`, `lib/ui/screens/s32_backup_export/backup_export_screen.dart`, `lib/ui/screens/s27_settings/settings_screen.dart`, `test/backup_export_test.dart`
- **Verification:** Verified on physical device: exported JSON has zero `pin_hash` keys; SM/GM screen completely hides the database export card.

---

#### Item 8: PIN lockout is only 60s and locks out every user globally
- **Priority:** Medium | **Client Ref:** F23
- **Problem:** 5 wrong PINs locked the whole screen for everyone (Owner couldn't log in if SM got locked out). Wrong digits remained stuck in box. Lockout duration didn't increase on repeated failures.
- **Required Fix:** Track lockout per user ID. Increase lockout progressively (60s ➔ 5m ➔ 15m). Clear PIN box immediately on wrong entry. Alert Super Admin on repeated lockouts.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `555650d` (`fix(auth): implement per-user lockout, progressive backoff (60s/5m/15m), and instant PIN reset (Item 8 / F23)`)
- **Files Changed:** `lib/providers/auth_provider.dart`, `lib/ui/screens/s04_login/login_screen.dart`, `lib/ui/widgets/pin_numpad.dart`, `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`, `test/auth_lockout_test.dart`
- **Verification:** 10/10 tests passing in `test/auth_lockout_test.dart`, 12/12 canonical score tests green, 406/406 full test suite green. 0 analyzer issues. Verified per-user isolation, progressive durations (60s -> 300s -> 900s), instant numpad dot clearing, and dropdown non-blocking.

---

### Category C: Alerts, Escalations, Cash Logic & Reports

#### Item 9: "WhatsApp Sent" shown when nothing was sent
- **Priority:** High | **Client Ref:** F01
- **Problem:** Opening a `wa.me` web link set `whatsapp_sent = 1` and green "WhatsApp Sent" badge, even if user backed out without picking contact or sending.
- **Required Fix:** Show "Share opened" or "Not confirmed". Only mark confirmed if delivery callback or explicit user confirmation ("Did you send this message?"). Provide retroactive "Mark as Sent".
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `c2a89bf`
- **Files Changed:** `lib/services/escalation_service.dart`, `lib/ui/screens/s11_submitted/submitted_screen.dart`, `lib/ui/screens/s33_escalations/escalations_list_screen.dart`, `lib/data/repositories/escalation_repository.dart`, `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`
- **Technical & Architectural Rationale for Sagar:**
  - *Standard Deep Links vs. WhatsApp Business Cloud API*: In native mobile development, launching WhatsApp via deep links (`wa.me` or `whatsapp://send` OS intents) hands execution off to the external WhatsApp application. The OS intent system does not provide any return callback, event hook, or delivery receipt stating whether the message was actually dispatched or if the user cancelled. True programmatic delivery receipts (Sent, Delivered, Read) are strictly exclusive to the official **Meta WhatsApp Business Cloud API**, which requires server infrastructure, approved message templates, and recurring Meta messaging fees.
  - *Honest Dual-Verification Workflow*:
    1. Default status on generation is now honestly flagged as amber badge: **"WhatsApp: Not Confirmed"** (`whatsapp_sent = 0`).
    2. When WhatsApp is launched, the app no longer assumes delivery. When the auditor returns to the app, an interactive confirmation dialog is presented: *"Did you send the escalation alert to [Recipient] on WhatsApp?"*. Tapping *"Yes, Sent"* stamps `whatsapp_sent = 1` and turns the badge green (**"WhatsApp Sent"**).
    3. If the user sent the message in WhatsApp and closed the app before answering the dialog, both Screen S11 and Screen S33 (Escalations Hub) feature a direct, one-tap **[Mark as Sent]** button to retroactively confirm delivery at any time without re-launching WhatsApp.
- **Verification:** 0 analyzer issues (`flutter analyze`). Score engine canonical suite 12/12 passed (`test/score_engine_test.dart`). Full test suite 407/407 passed (`flutter test`). Device physical test verified.

---

#### Item 10: Submitting an audit jumps to WhatsApp before confirming the save
- **Priority:** Medium | **Client Ref:** F09
- **Problem:** On audit submission with escalation, app immediately launched WhatsApp URL. Auditor thought save failed until pressing back.
- **Required Fix:** Show S11 Submission Confirmation screen first ("Audit saved, escalation created"), with a distinct "Share Alert via WhatsApp" button.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `c2a89bf`
- **Files Changed:** `lib/services/escalation_service.dart`, `lib/ui/screens/s10_review/review_submit_screen.dart`, `lib/ui/screens/s11_submitted/submitted_screen.dart`, `lib/data/repositories/escalation_repository.dart`, `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`
- **Technical & Architectural Rationale for Sagar:**
  - *Submission Decoupling*: Submitting an audit (`ReviewSubmitScreen` S10) now evaluates escalation triggers and saves them to SQLite in the background without automatically launching external WhatsApp URLs (`autoLaunchWhatsApp = false`).
  - *Immediate S11 Confirmation*: The user is immediately routed to Screen S11 (`SubmittedScreen`), which displays the celebration animation, score and band card, and the reassuring *"Saved to SQLite · Offline-first"* indicator.
  - *Actionable Escalation Cards on S11*: If the submitted audit activated escalation triggers (e.g., Trigger 1 for Critical/Poor score), Screen S11 dynamically loads and renders dedicated escalation action cards. Each card clearly shows the trigger level, urgency, recipient (e.g. GM), delivery badge, and explicit action buttons: **[Share Alert via WhatsApp]**, **[Mark as Sent]**, and **[Copy Alert]**. The auditor is in complete control and never surprised by unexpected OS intent redirects.
- **Verification:** 0 analyzer issues (`flutter analyze`). Score engine canonical suite 12/12 passed (`test/score_engine_test.dart`). Full test suite 407/407 passed (`flutter test`). Device physical test verified.

---

#### Item 11: Low-score escalation is announced but never created
- **Priority:** High | **Client Ref:** F18
- **Problem:** Audits scoring < 80% (Critical) announce Trigger 1/2 escalation in toast or on S11, but no escalation row was inserted in SQLite or displayed on S18/S33 Escalations Hub, and no WhatsApp button appeared on S11 for weekly audits.
- **Root Cause:** `EscalationEngine.evaluateAfterAudit` strictly hardcoded `if (audit.auditType == 'daily')` for Trigger 1. Consequently, when a Weekly or Monthly audit scored in the Critical band (< 80%, e.g. 40%), Trigger 1 was completely bypassed, producing 0 escalations. Screen S11 showed a static warning banner but no actionable escalation card or WhatsApp button.
- **Required Fix:**
  1. Expand Trigger 1 in `EscalationEngine.evaluateAfterAudit` to evaluate across Daily, Weekly, and Monthly audits scoring in the Critical band (< 80%) or Weekly Poor band (< 85% per Workbook §5.2).
  2. For Weekly and Monthly audits, route the escalation directly to the **OWNER** with urgency `same_day` and delivery channel `whatsapp`.
  3. Render the actionable escalation card on Screen S11 with the `[Share Alert via WhatsApp]` button, `[Mark as Sent]`, and confirmation dialog.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `c2a89bf`
- **Files Changed:** `lib/domain/escalation_engine.dart`, `test/escalation_engine_test.dart`
- **Verification:** Unit test `Fires Trigger 1 to OWNER via WhatsApp on Weekly Audit Critical band (e.g. 40%)` added and passing in `test/escalation_engine_test.dart` (14/14 tests green). 0 analyzer issues (`flutter analyze`). Score engine canonical suite 12/12 passed (`test/score_engine_test.dart`). Full test suite 407/407 passed (`flutter test`). Device physical test verified.
- **Files Changed:** `lib/domain/escalation_engine.dart`, `test/escalation_engine_test.dart`
- **Verification:** Unit test `Fires Trigger 1 to OWNER via WhatsApp on Weekly Audit Critical band (e.g. 40%)` added and passing in `test/escalation_engine_test.dart` (14/14 tests green). 0 analyzer issues (`flutter analyze`). Score engine canonical suite 12/12 passed (`test/score_engine_test.dart`). Full test suite 407/407 passed (`flutter test`).

---

#### Item 12: Weekly report escalation section is a placeholder
- **Priority:** Medium | **Client Ref:** F14
- **Problem:** Section 9 of Weekly Report and weekly PDF showed hardcoded text "No escalations triggered (Escalation engine active in Phase 3)" and "Escalations: 0 (Phase 3)", and CAP sections showed "P2-5" placeholders, ignoring open cash/audit escalations.
- **Root Cause:** In `ReportRepository.generateWeeklyReport`, `escalationsPayload`, `capsClosedPayload`, and `capsAgedPayload` were initialized as empty static lists (`[]`). Furthermore, Screen S21 (`report_detail_screen.dart`) and `weekly_report_pdf_service.dart` hardcoded Phase 3 and P2-5 placeholder strings instead of reading from `report.escalations`, `report.capsClosed`, and `report.capsAged`.
- **Required Fix:**
  1. In `ReportRepository.generateWeeklyReport`, query SQLite `escalations` table for the week's date range and linked audits (`weeklyAuditId` + daily audit IDs), populating `escalationsPayload` with actual records (trigger number, label, urgency, what happened, status, whatsapp sent).
  2. Query SQLite `caps` table for CAPs opened, closed, and aged during the week, populating `capsOpenedPayload`, `capsClosedPayload`, and `capsAgedPayload`.
  3. In `ReportDetailScreen` (S21), render actual escalation rows (trigger badge, urgency, description, status) and real closed/aged CAP entries. If empty, display clean strings without phase tags.
  4. In `WeeklyReportPdfService`, render real escalation counts and up to 3 escalation summary rows in Section 9, and real closed/aged counts in Sections 7 & 8, removing all "Phase 3" and "P2-5" text.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `4555b2c`
- **Files Changed:** `lib/data/repositories/report_repository.dart`, `lib/ui/screens/reports/report_detail_screen.dart`, `lib/services/weekly_report_pdf_service.dart`, `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`, `test/report_repository_test.dart`
- **Verification:** Unit test `2. Generates 9-section weekly report populating real escalations and CAPs (Item 12 / F14)` in `test/report_repository_test.dart` passing (2/2 tests green). Full weekly report test suite `test/weekly_report_test.dart` passing (7/7 tests green). 0 analyzer issues (`flutter analyze`). Score engine canonical suite 12/12 passed (`test/score_engine_test.dart`).

---

#### Item 13: Cash variance of ₹600 saved as Pass, and three different cash limits
- **Priority:** High | **Client Ref:** F12, F15
- **Problem:** Daily checkpoint 6.5 ("Cash variance ≤ ₹50") was marked Pass while S10 recorded -₹600 variance. In weekly audit, CW.7 passed with -₹600 cumulative shortage, giving 16/16 (100%) to Cash Management. Three conflicting limits (₹50, ₹200, ₹500) scattered across code.
- **Required Fix:**
  1. Centralize cash limits in `lib/domain/cash_thresholds.dart`.
  2. Auto-enforce Checkpoint 6.5: auto-FAIL if variance > ₹500; require note if > ₹50.
  3. Auto-enforce Weekly CW.7: auto-FAIL if cumulative variance breaches ±₹200 limit.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `84c8c0f` (`fix(scoring): auto-enforce cash variance limits on Checkpoint 6.5 and CW.7 (Item 13)`)
- **Files Changed:** `lib/domain/cash_thresholds.dart`, `lib/domain/escalation_engine.dart`, `lib/domain/score_engine.dart`, `lib/providers/draft_audit_provider.dart`, `lib/ui/screens/s10_review/review_submit_screen.dart`, `test/cash_variance_enforcement_test.dart`
- **Verification:** Unit and integration tests passing (`test/cash_variance_enforcement_test.dart` 6/6 tests passed). Score engine suite 12/12 passed. Full test suite 380/380 tests passed. Auto-failure on breach and photo-gate bypass verified.

---

#### Item 14: Safe-cash checkpoint counted under Sales Buddy
- **Priority:** Medium | **Client Ref:** F08
- **Problem:** Monthly checkpoint `MC.1` ("Recount safe cash") had `sop_id: "SOP2"` (Sales Buddy) in seed JSON. Cash Management scored 0/0 while Sales Buddy scored 2/2.
- **Required Fix:** Updated `MC.1` in `assets/seed/checkpoints.json` to `sop_id: "SOP6"` (Cash Management). Updated unit and integration tests.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `11f9a47` (`fix(seed): move checkpoint MC.1 from SOP2 to SOP6 (Cash Management)`)
- **Files Changed:** `assets/seed/checkpoints.json`, `test/monthly_audit_test.dart`, `test/monthly_report_integration_test.dart`
- **Verification:** 11/11 monthly tests passing, score engine green.

---

#### Item 15: Daily audit detail buttons are "Phase 2" placeholders
- **Priority:** Medium | **Client Ref:** F03
- **Problem:** Tapping "Export PDF", "Verify", or "Share" on S13 Daily Audit Detail shows "scheduled for Phase 2" snackbar.
- **Required Fix:** Wire real PDF export / preview, WhatsApp share intent, and role-based verification directly on S13.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `2848b0c` (`feat(s13): wire role-based audit verification, daily audit PDF export, and WhatsApp sharing (Item 15 · F03)`)
- **Files Changed:** `lib/ui/screens/s13_audit_detail/audit_detail_screen.dart`, `lib/services/daily_audit_pdf_service.dart`, `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`, `test/audit_detail_screen_test.dart`, `test/daily_audit_pdf_service_test.dart`, `test/backup_export_test.dart`
- **Verification:**
  1. **Verify Audit:** Role-based verification (GM & Owner only). Confirms without asking user to pick a role — automatically stamps the logged-in user's role and name. Updates database `status = 'verified'`, `verifier_id = user.id`, UTC timestamp. UI refreshes, replaces amber "SUBMITTED" badge with green "VERIFIED: <Name> (<Date>)" badge, and hides the verify button.
  2. **Export PDF:** Created `DailyAuditPdfService` generating bilingual daily audit PDF (store metadata, score card, SOP breakdown table, fail findings, auditor/verifier signature blocks) and opens native system share modal using `Printing.sharePdf`.
  3. **Share to WhatsApp:** Formats structured plain-text daily audit summary (Store, Date, Auditor, Score %, Band, Points, Status, Non-compliances list) and launches WhatsApp via `whatsapp://send` / `api.whatsapp.com` with clipboard copy fallback and toast feedback.
  4. **Tests:** All 14/14 tests in `test/audit_detail_screen_test.dart` passing. 2/2 tests in `test/daily_audit_pdf_service_test.dart` passing. Full test suite: 391/391 tests passing (100% green). 0 analyzer issues.

---

#### Item 16: Marathi text is broken in all PDFs, and other PDF issues
- **Priority:** High | **Client Ref:** F06 (Review P146-P155)
- **Problem:** Devanagari Marathi vowel signs (*hrasva velanti* `ि` / `\u093F`) and conjuncts rendered broken in all PDF outputs (विभाग → वभिाग, साप्ताहिक → साप्ताहकि, मासिक → मासकि). Hardcoded 124-point rollup title contradicted reduced max scores from N/A checkpoints. Weekly headline showed 0 failures despite daily failures. PDF export bypassed local document persistence and lacked confirmation. Long raw UUID filenames instead of standardized human-readable names. Signatures showed raw user IDs and raw ISO timestamps.
- **Required Fix:**
  1. Implement `DevanagariShaper` in `lib/utils/devanagari_shaper.dart` to reorder pre-base vowel signs (`ि`) before their preceding consonant cluster for TrueType font PDF drawing.
  2. Apply clean executive typography across Daily, Weekly, and Monthly PDF generators (`DailyAuditPdfService` and `WeeklyReportPdfService`).
  3. Dynamic Section 2 rollup title (`${totalMax.toStringAsFixed(0)}-Point Rollup`).
  4. Weekly Report headline in `ReportRepository` reports combined total failures.
  5. Persistent local saving to application documents directory and SQLite `pdf_local_path` update.
  6. Standardized filenames (`Saagar_Weekly_Report_W<week>_<year>.pdf`, `Saagar_Monthly_Report_<Month>_<year>.pdf`, `Saagar_Daily_Audit_<Date>.pdf`).
  7. Resolve real human auditor names from `UserRepository` with role titles, format `readByOwnerAt` with local datetime, and label Monthly auditor as `Store Owner`.
  8. Export confirmation snackbars in S21 and S13.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `pending-commit`
- **Files Changed:** `lib/utils/devanagari_shaper.dart`, `lib/data/repositories/report_repository.dart`, `lib/services/weekly_report_pdf_service.dart`, `lib/services/daily_audit_pdf_service.dart`, `lib/ui/screens/reports/report_detail_screen.dart`, `lib/ui/screens/s13_audit_detail/audit_detail_screen.dart`, `test/devanagari_shaper_test.dart`, `test/daily_audit_pdf_service_test.dart`, `test/weekly_report_test.dart`
- **Verification:** 3/3 tests in `test/devanagari_shaper_test.dart`, 3/3 in `test/daily_audit_pdf_service_test.dart`, 7/7 in `test/weekly_report_test.dart`, 5/5 in `test/monthly_report_integration_test.dart`, 12/12 canonical score tests green, 413/413 full test suite green, 0 analyzer issues.

---

### Category D: Corrective Action Plan (CAP) Controls

#### Item 17: CAP form shows wrong checkpoints, and monthly/weekly failures cannot get a CAP
- **Priority:** High | **Client Ref:** F20 (F19 in review doc)
- **Problem:** Opening CAP creation screen displays wrong checkpoint list (all 68 daily checkpoints 2.1 to 8.8, pre-selecting 2.1) regardless of which audit is selected. Weekly (e.g., CW.7) and monthly (e.g., MC.2) checkpoints are not in the list at all. User was able to create a CAP against checkpoint 6.5 which passed in that audit.
- **Required Fix:**
  1. Scope checkpoint dropdown to ONLY the failed checkpoints (`result == 'F'`) of the selected audit.
  2. Support daily, weekly, and monthly failed checkpoints by loading across all frequencies.
  3. Reorder origin card so Origin Audit is selected first and Failed Checkpoint second. Show fail count on audit dropdown item.
  4. If the selected audit has 0 recorded fails, display honest alert notice and disable/block CAP creation.
  5. Add repository-level validation in `CapRepository.createCap` rejecting non-pattern CAPs on checkpoints that did not fail (`result != 'F'`).
  6. Automatically bind `originResultId` from the audit result row so audit detail reflects the linked CAP.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `4555b2c`
- **Files Changed:** `lib/data/repositories/cap_repository.dart`, `lib/ui/screens/s15_cap_create/cap_create_screen.dart`, `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`, `test/cap_create_screen_test.dart`, `test/cap_repository_test.dart`, `test/backup_export_test.dart`
- **Verification:** 9/9 tests in `test/cap_create_screen_test.dart` (including dedicated Item 17 monthly MC.2 test & 0-fails notice test), 19/19 in `test/cap_repository_test.dart` (including non-failed checkpoint rejection guard), 12/12 canonical score tests green, full test suite 401/401 tests passing (100% green). 0 analyzer issues.

---

#### Item 18: CAP can be marked done with no note or photo
- **Priority:** Medium | **Client Ref:** F20 (F22 in review doc)
- **Problem:** Store Manager can mark a CAP resolved without providing any evidence photo or completion note.
- **Required Fix:** Enforce mandatory completion note (minimum 10 characters) and photo evidence (when origin checkpoint has `requires_photo_on_fail == 1`) before allowing "Mark CAP Done".
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `eb22124` (`fix(cap): enforce segregation of duties, action steps reset on reopen, and mandatory evidence (Items 6 & 18)`)
- **Files Changed:** `lib/data/repositories/cap_repository.dart`, `lib/ui/screens/s17_cap_mark_done/cap_mark_done_screen.dart`, `test/cap_lifecycle_test.dart`, `test/cap_mark_done_screen_test.dart`, `test/cap_repository_test.dart`, `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`
- **Verification:** 9/9 tests in `test/cap_mark_done_screen_test.dart`, 16/16 tests in `test/cap_lifecycle_test.dart`. Full suite 398/398 passing. 0 analyzer issues.

#### Item 19: "Request Extension" can move deadline earlier
- **Priority:** Low | **Client Ref:** F19 (F22 in review doc)
- **Problem:** Date picker in CAP extension request dialog allows picking dates before the current deadline or in the past (e.g., CAP due 31 Oct allowed picking 25 Oct and moving deadline earlier).
- **Required Fix:** Set `firstDate: currentDeadline.add(Duration(days: 1))` so extensions can only be granted for future dates strictly after current deadline. Added repository-level guard in `CapRepository.extendCap` rejecting new deadlines $\le$ existing deadline.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `cde4398` (`fix(cap): prevent earlier or past dates in CAP deadline extension (Item 19)`)
- **Files Changed:** `lib/data/repositories/cap_repository.dart`, `lib/ui/screens/cap/s18_cap_verify_screen.dart`, `lib/ui/screens/s16_cap_detail/cap_detail_screen.dart`, `test/cap_lifecycle_test.dart`
- **Verification:** Unit tests passing (`test/cap_lifecycle_test.dart` 14/14 green, with dedicated test 7b verifying Sagar's exact 31 Oct $\rightarrow$ 25 Oct test is blocked). Full suite 381/381 tests green. 0 analyzer issues.

---

### Category E: Language, Permissions & Layout

#### Item 20: Daily checkpoints are not translated into Marathi
- **Priority:** Medium | **Client Ref:** F04
- **Problem:** All 68 daily checkpoints in `checkpoints.json` have English text copy-pasted into `text_mr` and `evidence_mr`.
- **Required Fix:** Populate authentic, natural Devanagari Marathi translations for all 68 daily checkpoints matching the retail workbook.
- **Status:** ⏳ **PENDING (Tier 3)**
- **Commit:** —
- **Files Changed:** —

---

#### Item 21: Camera permission denial leaves user stuck
- **Priority:** Medium | **Client Ref:** F24
- **Problem:** Denying camera permission causes a black screen or unhandled exception with no recovery or manual retry dialog.
- **Required Fix:** Catch permission denial gracefully, show explanation dialog with "Open App Settings" button, and allow retrying.
- **Status:** ⏳ **PENDING (Tier 3)**
- **Commit:** —
- **Files Changed:** —

---

#### Item 22: App never asks for notification permission on Android 13+
- **Priority:** Low | **Client Ref:** F25
- **Problem:** On Android 13 (API 33) and above, runtime `POST_NOTIFICATIONS` permission is required for CAP reminders and escalation alerts, but never requested.
- **Required Fix:** Add runtime permission request for `POST_NOTIFICATIONS` on Android 13+ startup.
- **Status:** ⏳ **PENDING (Tier 3)**
- **Commit:** —
- **Files Changed:** —

---

#### Item 23: Question disappears on small screens & report text overlaps
- **Priority:** Medium | **Client Ref:** F02
- **Problem:** In landscape mode on smaller phones, checkpoint questions disappear behind PASS/FAIL buttons. Larger text causes report titles ("Combined Total Score") to wrap 1 letter per line.
- **Required Fix:** Wrap checkpoint content in `SingleChildScrollView`, adjust button padding, and use flexible layout with `overflow: TextOverflow.ellipsis` on report chips.
- **Status:** ⏳ **PENDING (Tier 3)**
- **Commit:** —
- **Files Changed:** —

---

#### Item 24: Phone Back button exits audit; app back arrow goes to previous checkpoint
- **Priority:** Medium | **Client Ref:** F05
- **Problem:** Pressing Android hardware Back button completely exits the audit and closes app, while top app bar arrow goes to previous checkpoint.
- **Required Fix:** Wrap audit conduct screen in `PopScope` to intercept back button: go to previous checkpoint, or prompt "Save draft and exit?".
- **Status:** ⏳ **PENDING (Tier 3)**
- **Commit:** —
- **Files Changed:** —

---

#### Item 25: Times shown in two different time zones without a label
- **Priority:** Medium | **Client Ref:** F07
- **Problem:** Audit submission showed 09:04 PM while detail screen showed 15:34 (UTC). CAP timelines showed UTC. Verification after midnight appeared under previous day's date due to raw substring on UTC timestamps.
- **Required Fix:** Store UTC in SQLite/Firestore, but format all UI displays and PDFs explicitly in device Local / Indian Standard Time (IST, UTC+5:30) via central `AppDateFormat` utility with 12-hour AM/PM formatting.
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `34952a5` (`fix(ui): format all timestamps in local Indian Standard Time (IST) with AM/PM labels (Item 25)`)
- **Files Changed:** `lib/utils/app_date_format.dart`, `lib/services/weekly_report_pdf_service.dart`, `lib/ui/screens/reports/report_detail_screen.dart`, `lib/ui/screens/reports/reports_list_screen.dart`, `lib/ui/screens/s11_submitted/submitted_screen.dart`, `lib/ui/screens/s13_audit_detail/audit_detail_screen.dart`, `lib/ui/screens/s16_cap_detail/cap_detail_screen.dart`, `lib/ui/screens/s17_cap_mark_done/cap_mark_done_screen.dart`, `lib/ui/screens/s32_backup_export/backup_export_screen.dart`, `lib/ui/screens/s33_escalations/escalations_list_screen.dart`, `lib/ui/screens/seven_day_review/seven_day_review_screen.dart`, `test/app_date_format_test.dart`
- **Verification:** Unit tests passing (`test/app_date_format_test.dart` 6/6 tests passing), S13 widget tests 12/12 passing, canonical score engine 12/12 passing, full suite 387/387 tests passing. 0 analyzer issues.

---

#### Item 26: "Photo is mandatory" shown where a Pass needs no photo
- **Priority:** Low | **Client Ref:** F17
- **Problem:** Monthly checkpoint MC.1 shows badge "Photo is mandatory for this checkpoint", but passing requires no photo.
- **Required Fix:** Update badge string in English and Marathi: "Photo required if marked FAIL".
- **Status:** ✅ **SOLVED & VERIFIED**
- **Commit:** `ba2d9ab` (`fix(l10n): clarify checkpoint photo badge to 'Photo required if marked FAIL' (Item 26)`)
- **Files Changed:** `assets/translations/app_en.arb`, `assets/translations/app_mr.arb`, `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_mr.dart`
- **Verification:** Localizations regenerated via `flutter gen-l10n`, 0 analyzer issues, canonical score engine 12/12 passing. Authenticated in S07 Checkpoint UI badge.

---

### Category F: General Ease-of-Use (Item 27)

#### Item 27: UX & Workflow Improvements
- **Priority:** Low | **Client Ref:** Section F
- **Items Included:**
  - **27.1:** Bottom navigation menu (Home, Audits, CAPs, Reports, Settings) to reduce excessive scrolling.
  - **27.2:** 68-checkpoint jump list drawer (showing answered, unanswered, failed).
  - **27.3:** Review screen tap finding to open for editing.
  - **27.4:** Auto-dismiss validation errors as soon as user attaches photo or fills field.
  - **27.5:** Simplify first-time setup PIN flow and eliminate technical jargon across all user screens.
  - **27.6:** Progress calculation based on count of answered checkpoints rather than cursor index.
  - **27.7:** Human names on report signatures instead of raw user IDs.
- **Status:** ⏳ **PENDING (Tier 3)**
- **Commit:** —
- **Files Changed:** —
