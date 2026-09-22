# Tech Stack & Inviolable Architectural Rules

## 1. Locked Tech Stack (Spec §2)
- **Framework**: Flutter ≥ 3.16 · Dart ≥ 3.2
- **State Management**: `flutter_riverpod: ^2.6.1` (NOT Provider / Bloc / GetX)
- **Navigation**: `go_router: ^17.3.0` (NOT auto_route / standard Navigator)
- **Local Database**: `sqflite: ^2.3.0` (NOT drift / isar / hive)
- **Authentication**: Local 4-digit PIN with `bcrypt: ^1.1.3` (NOT Firebase Auth)
- **Media & Files**: `image_picker`, `flutter_image_compress`, `pdf: ^3.10.7`, `printing: ^5.11.1`
- **Typography**: Google Fonts (`DM Serif Display` for headings, `DM Sans` for body/labels)
- **Charts**: `fl_chart: ^1.2.0`
- **Notifications & External**: `flutter_local_notifications`, `url_launcher` (WhatsApp share)
- **Target Platform**: Android API 24+ (No iOS, No Tablet, No Web)

## 2. Inviolable Operational Rules (Spec §14.1)
1. **Workbook is Ground Truth**: On any conflict between spec wording and workbook sheets, the workbook wins.
2. **Tech Stack is Locked**: Do NOT introduce alternate state management or database packages.
3. **Offline-First**: SQLite is the source of truth. The app must boot, authenticate, audit, and function 100% without internet. Cloud (Firestore/Storage) is purely an asynchronous mirror.
4. **PIN Security**: Bcrypt only (cost 10). PINs are never stored in plaintext and never logged. 5 failed attempts within 60s triggers a strict 60s lockout.
5. **Score Engine Invariance**: Daily audits must produce canonical scores exactly matching `81 / 90 = 90.0% Good`.
6. **Audit Immutability**: Once an audit is marked `submitted`, it is strictly read-only. Mistakes are corrected by supersession, never in-place edits. Only the Owner can mark an audit `hidden`.
7. **Mandatory Photo on Cash & Inventory Fails**: Checkpoints in SOP 6 (Cash) and SOP 7 (Inventory) with `requires_photo_on_fail = 1` MUST require at least 1 photo before the failure can be saved.
8. **Dual-Language Parity**: ARB localization files (`app_en.arb` and `app_mr.arb`) must be kept in lock-step.

## 3. PDF Generation Architecture Rules
- Use `import 'package:pdf/widgets.dart' as pw;` strictly to prevent namespace clashes with Flutter widgets.
- Marathi / Devanagari text MUST be rendered with a bundled TTF font (e.g. `NotoSansDevanagari`), loaded via root bundle and registered with `pw.ThemeData.withFont(base: font)`.
- Use `pw.MultiPage` for all tabular/checkpoint reports to prevent `TooManyPagesException`.
- Strict margins (0.5 inch / 36pt or 0.75 inch / 54pt) and exact point sizing.
