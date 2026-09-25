# Saagar Audit App — Project Overview

## 1. Objective
A production-grade Android compliance audit mobile application built for **Saagar Traders** to manage retail compliance audits across their two franchise stores in Latur, Maharashtra:
- **Titan World** (Store code: `WLMHW`)
- **Helios Watch Store** (Store code: `HEMW`)

Ground-truth documents:
- `phase-1/Documentation/Saagar_P1_App_Spec_v1.docx`
- `phase-1/Documentation/Saagar_P1_Audit_Workbook_v1.docx` (Operational ground truth)
- `phase-1/Documentation/Saagar_P1_QuickRef_v1.docx`

## 2. Business Hierarchy & Roles
- **OWNER**: Super-admin access. Creates accounts, changes user roles, can mark audits `hidden`, views executive reports, full system control.
- **GM (General Manager)**: Oversees both stores, reviews weekly/monthly reports, verifies & closes CAPs (Corrective Action Plans), monitors escalation triggers.
- **SM (Store Manager)**: Conducts daily audits (68 checkpoints), creates CAPs for non-compliances, attaches photo evidence.
- **CRO (Chief Retail Officer)**: Store floor sales staff (Titan / Helios counter, shifts: morning / afternoon / flexible). CROs are **not** app login users — they are staff evaluated during audits and attributed to findings.

## 3. Four-Phase Delivery Roadmap
| Phase | Weeks | Scope | Status |
|---|---|---|---|
| **Phase 1** | Weeks 1–4 | Daily audit foundation (S01–S17, S22–S32), SQLite schema, seed data, local PIN auth, scoring engine, CAP create + mark done | **Ready for Sign-Off** (All 28 screens built; 214 tests green [32 Daily/Integration, 74 CAPs, 59 Settings, 49 Reference]; TC1–TC9 full integration suite green) |
| **Phase 2** | Weeks 5–8 | Weekly audit, CAP verify + close, GM dashboard, PDF generation & export | Next |
| **Phase 3** | Weeks 9–11 | Monthly audit, 7-trigger Escalation Engine, Trend Analytics & Charts | Scheduled |
| **Phase 4** | Weeks 12–13 | Cloud mirror (Firestore / Storage), Play Store internal track release | Scheduled |
