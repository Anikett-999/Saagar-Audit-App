# Saagar Audit App — Modular Specification Index

> **Master Specifications**:
> - Full App Spec: [`brain/SPEC_APP.md`](../SPEC_APP.md) (285 KB, 4,256 lines)
> - Full Operational Audit Workbook: [`brain/SPEC_WORKBOOK.md`](../SPEC_WORKBOOK.md) (725 KB, 13,000+ lines)
> - Quick Reference Cards: [`brain/SPEC_QUICKREF.md`](../SPEC_QUICKREF.md) (15 KB, 381 lines)

This directory breaks the 285 KB app specification into modular, self-contained Markdown documents. This ensures Claude (Senior Developer & Team Lead) and Antigravity (Developer) can read individual screens, data models, or workflows directly in-session without hitting file-view or LLM context limits.

---

## 📚 Specification Modules

| Module File | Contents | Spec Sections |
|---|---|---|
| [`01_ARCHITECTURE_AND_DATA_MODEL.md`](01_ARCHITECTURE_AND_DATA_MODEL.md) | System Architecture, Tech Stack (locked), 4 User Roles & Permissions Matrix, Immutability Rules, Complete Data Model (Tables 4.1–4.15), Migrations & Seed Data | Sections 1, 2, 3, 4 |
| [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) | Screen Catalogue, S01 (Splash), S02 (Language Selection), S03 (First-Time Setup), S04 (Login), S05 (Home/Dashboard), S06 (Start Audit), S07 (Checkpoints), S08 (Fail Detail), S09 (Photo Capture), S10 (Review & Submit), S11 (Submitted Confirmation) | Section 5 (Part 1) |
| [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) | S12 (Audit History), S13 (Audit Detail), S14 (CAP List), S15 (CAP Create), S16 (CAP Detail), S17 (Mark Done), S18 (Verify), S19 (Close), S20 (Reports List), S21 (Report Detail) | Section 5 (Part 2) |
| [`04_S22_S26_REFERENCE_DATA.md`](04_S22_S26_REFERENCE_DATA.md) | S22 (Reference Index), S23 (Rating Scale), S24 (Escalation Triggers), S25 (Evidence Reference), S26 (Bilingual Glossary), plus full reference tables from Section 11 | Sections 5 & 11 |
| [`05_S27_S32_SETTINGS_USERS.md`](05_S27_S32_SETTINGS_USERS.md) | **Sprint Priority**: S27 (Settings), S28 (Manage CROs), S29 (Manage Users), S30 (Change PIN), S31 (Language), S32 (Backup & Export) + relevant schemas (Tables 4.1, 4.2, 4.5) | Section 5 (Part 3) & Schemas |
| [`06_SCORING_AND_ESCALATION.md`](06_SCORING_AND_ESCALATION.md) | Score Calculation Formulas (Daily & Weekly), Weighted Sections, NA Handling, Worked Examples, CW.7 Cumulative Cash Variance, Escalation Engine (7 Triggers, `raise()` logic, 4-part message format) | Sections 6 & 7 |
| [`07_WORKFLOWS_AND_NOTIFICATIONS.md`](07_WORKFLOWS_AND_NOTIFICATIONS.md) | Bilingual String Table (EN/MR), CAP Workflow State Machine, Midnight Aging Logic, Extension Rules, In-App Notifications, WhatsApp Deep Links | Sections 8, 9, 10 |
| [`08_PHASING_TESTS_AND_CONVENTIONS.md`](08_PHASING_TESTS_AND_CONVENTIONS.md) | Phasing Roadmap (Weeks 1–13), Test Scenarios (Phases 1–3), Master Claude Prompts, Coding Conventions, Folder Structure, Definition of Done, Recovery Patterns & Rollbacks | Sections 12–18 |

---

## 🗺️ Complete Screen Catalogue (S01–S32)

| Screen # | Screen Name | Marathi Title | Allowed Roles | Target Module |
|---|---|---|---|---|
| **S01** | Splash / Loading | स्प्लॅश / लोडिंग | All | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S02** | Language Selection (First Launch) | भाषा निवड | All | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S03** | First-Time Setup (First Launch) | प्रथम सेटअप | Owner | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S04** | Login (4-digit PIN) | लॉगिन | All | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S05** | Home / Dashboard | मुख्यपृष्ठ / डॅशबोर्ड | All | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S06** | Start Daily Audit | दैनिक ऑडिट सुरू करा | SM | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S07** | Daily Audit Checkpoint Screen | चेकपॉइंट स्क्रीन | SM | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S08** | Daily Audit Fail Detail | त्रुटी तपशील | SM | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S09** | Daily Audit Photo Capture | फोटो कॅप्चर | SM | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S10** | Daily Audit Review & Submit | पुनरावलोकन व सादर | SM | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S11** | Daily Audit Submitted Confirmation | सादरीकरण पुष्टी | SM | [`02_S01_S11_DAILY_AUDIT.md`](02_S01_S11_DAILY_AUDIT.md) |
| **S12** | Audit History (own / all) | ऑडिट इतिहास | All (role-filtered) | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S13** | Audit Detail (read-only immutable) | ऑडिट तपशील | All | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S14** | CAP List | सुधारात्मक कृती यादी | All | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S15** | CAP Create | कृती योजना तयार करा | SM, GM, Owner | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S16** | CAP Detail | कृती योजना तपशील | All | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S17** | CAP Action — Mark Done | पूर्ण म्हणून खूण करा | Responsible user | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S18** | CAP Verify | पडताळणी | GM, Owner | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S19** | CAP Close | बंद करा | GM, Owner | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S20** | Reports List | अहवाल यादी | GM, Owner | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S21** | Report Detail | अहवाल तपशील | GM, Owner | [`03_S12_S21_AUDITS_CAPS_REPORTS.md`](03_S12_S21_AUDITS_CAPS_REPORTS.md) |
| **S22** | Reference Tab — Index | संदर्भ अनुक्रमणिका | All | [`04_S22_S26_REFERENCE_DATA.md`](04_S22_S26_REFERENCE_DATA.md) |
| **S23** | Reference — Rating Scale | रेटिंग स्केल | All | [`04_S22_S26_REFERENCE_DATA.md`](04_S22_S26_REFERENCE_DATA.md) |
| **S24** | Reference — Escalation Triggers | एस्केलेशन ट्रिगर्स | All | [`04_S22_S26_REFERENCE_DATA.md`](04_S22_S26_REFERENCE_DATA.md) |
| **S25** | Reference — Evidence Reference | पुरावा संदर्भ | All | [`04_S22_S26_REFERENCE_DATA.md`](04_S22_S26_REFERENCE_DATA.md) |
| **S26** | Reference — Bilingual Glossary | द्विभाषिक शब्दकोश | All | [`04_S22_S26_REFERENCE_DATA.md`](04_S22_S26_REFERENCE_DATA.md) |
| **S27** | Settings | सेटिंग्ज | All | [`05_S27_S32_SETTINGS_USERS.md`](05_S27_S32_SETTINGS_USERS.md) |
| **S28** | Settings — Manage CROs | सीआरओ व्यवस्थापन | SM, GM, Owner | [`05_S27_S32_SETTINGS_USERS.md`](05_S27_S32_SETTINGS_USERS.md) |
| **S29** | Settings — Manage Users | वापरकर्ता व्यवस्थापन | Owner | [`05_S27_S32_SETTINGS_USERS.md`](05_S27_S32_SETTINGS_USERS.md) |
| **S30** | Settings — Change PIN | PIN बदला | All | [`05_S27_S32_SETTINGS_USERS.md`](05_S27_S32_SETTINGS_USERS.md) |
| **S31** | Settings — Language | भाषा | All | [`05_S27_S32_SETTINGS_USERS.md`](05_S27_S32_SETTINGS_USERS.md) |
| **S32** | Settings — Backup & Export | बॅकअप व निर्यात | All (sync Owner-only) | [`05_S27_S32_SETTINGS_USERS.md`](05_S27_S32_SETTINGS_USERS.md) |

---

## 👥 How to Use This Specification

1. **For Claude (Senior Developer & Team Lead)**:
   - When designing feature implementations, open the specific module (e.g. [`05_S27_S32_SETTINGS_USERS.md`](05_S27_S32_SETTINGS_USERS.md)).
   - For database schema questions, check [`01_ARCHITECTURE_AND_DATA_MODEL.md`](01_ARCHITECTURE_AND_DATA_MODEL.md).
   - For scoring or escalation engine logic, consult [`06_SCORING_AND_ESCALATION.md`](06_SCORING_AND_ESCALATION.md).

2. **For Antigravity (Developer)**:
   - Implement according to the technical direction and design specified by Claude.
   - Run tests, check database migrations against [`01_ARCHITECTURE_AND_DATA_MODEL.md`](01_ARCHITECTURE_AND_DATA_MODEL.md).
   - Keep `brain/SESSION_HANDOFF.md` updated with exact test logs and screen completion status.
