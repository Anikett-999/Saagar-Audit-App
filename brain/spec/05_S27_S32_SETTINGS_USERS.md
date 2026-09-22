# Saagar Audit App — Settings & User/CRO Management Screens S27–S32
> **Source**: Saagar_P1_App_Spec_v1.docx (Section 5: Screens S27–S32 + Schema Excerpts)  
> **Master**: [rain/SPEC_APP.md](../SPEC_APP.md)  
> **Index**: [rain/spec/INDEX.md](INDEX.md)  
> **Status**: Priority for upcoming Admin / Settings sprint (Claude & Antigravity)

---

## Part 1: Screen Specifications (S27–S32)

**Screen S27 —** **Settings**

*स्क्रीन S27 — सेटिंग्ज*

- List of settings sections, role-filtered: Manage CROs (all roles), Manage Users (Owner only), Change PIN, Language, Backup & Export, About.
*सेटिंग्ज विभागांची यादी, भूमिकेनुसार फिल्टर: सीआरओ व्यवस्थापन (सर्व), वापरकर्ता व्यवस्थापन (फक्त मालक), PIN बदला, भाषा, बॅकअप व निर्यात, बद्दल.*

**Screen S28 —** **Settings — Manage CROs**

*स्क्रीन S28 — सेटिंग्ज — सीआरओ व्यवस्थापन*

- Table of CROs with edit/delete actions. "+ Add CRO" button.
*संपादन/हटवण्याच्या कृतींसह सीआरओचा तक्ता. "+ सीआरओ जोडा" बटण.*

- Form fields: name, counter, shift, is_active toggle.
*फॉर्म फील्ड: नाव, काउंटर, शिफ्ट, is_active टॉगल.*

- Deactivating a CRO retains them in history but removes from dropdowns.
*सीआरओ निष्क्रिय केल्याने त्यांना इतिहासात ठेवते पण ड्रॉपडाउनमधून काढते.*

**Screen S29 —** **Settings — Manage Users (Owner only)**

*स्क्रीन S29 — सेटिंग्ज — वापरकर्ता व्यवस्थापन (फक्त मालक)*

- Table of users with role badge. Owner can: add new SM/GM, deactivate users, reset PINs.
*भूमिका बॅजसह वापरकर्त्यांचा तक्ता. मालक करू शकतो: नवीन SM/GM जोडणे, वापरकर्ते निष्क्रिय करणे, PIN रीसेट करणे.*

- Cannot delete users (audit trail integrity). Only deactivate.
*वापरकर्ते हटवू शकत नाही (ऑडिट ट्रेल अखंडता). फक्त निष्क्रिय.*

- Cannot have more than 1 Owner.
*१ पेक्षा जास्त मालक असू शकत नाही.*

**Screen S30 —** **Settings — Change PIN**

*स्क्रीन S30 — सेटिंग्ज — PIN बदला*

- 3 fields: current PIN, new PIN, confirm new PIN. All bcrypt-hashed on submit.
*३ फील्ड: सध्याचा PIN, नवीन PIN, नवीन PIN पुष्टी. सादरीकरणावर सर्व bcrypt-हॅश्ड.*

**Screen S31 —** **Settings — Language**

*स्क्रीन S31 — सेटिंग्ज — भाषा*

- Toggle: English / मराठी. UPDATE users.language_pref. App restarts to apply.
*टॉगल: इंग्रजी / मराठी. users.language_pref UPDATE. अंमलात आणण्यासाठी अॅप पुन्हा सुरू.*

**Screen S32 —** **Settings — Backup & Export**

*स्क्रीन S32 — सेटिंग्ज — बॅकअप व निर्यात*

- Export entire database as JSON to Downloads folder. Useful for manual backups before app upgrade.
*संपूर्ण डेटाबेस Downloads फोल्डरमध्ये JSON म्हणून निर्यात करा. अॅप अपग्रेडपूर्वी मॅन्युअल बॅकअपसाठी उपयुक्त.*

- Owner-only: View Firestore sync status, manual force-sync trigger.
*फक्त-मालक: Firestore समक्रमण स्थिती पाहा, मॅन्युअल फोर्स-समक्रमण ट्रिगर.*

- "About" sub-screen: app version, contact info, link to this Specification document.
*"बद्दल" उप-स्क्रीन: अॅप आवृत्ती, संपर्क माहिती, या तपशील दस्तऐवजाचा दुवा.*



---

## Part 2: Related Data Model & Rules for Settings & User Management

### Table 4.1 — users
## Table 4.1 — users

*तक्ता ४.१ — वापरकर्ते*

One row per app login. Three rows total: Store Manager, GM, Owner.

प्रत्येक अॅप लॉगिनसाठी एक ओळ. एकूण तीन ओळी: स्टोअर मॅनेजर, जीएम, मालक.


| Field \| क्षेत्र | Type \| प्रकार | Constraints \| मर्यादा | Description \| वर्णन |
| --- | --- | --- | --- |
| id | TEXT | PRIMARY KEY, UUID | Unique user identifier |
| name | TEXT | NOT NULL, length 2-50 | Display name e.g. "Suresh Patil" |
| role | TEXT | NOT NULL, IN ('SM','GM','OWNER') | User's role |
| pin_hash | TEXT | NOT NULL | bcrypt hash of 4-digit PIN |
| language_pref | TEXT | NOT NULL, IN ('en','mr'), default 'en' | UI language for this user |
| phone | TEXT | Optional, +91 format | For WhatsApp escalations |
| is_active | INTEGER | NOT NULL, default 1 | 0 = deactivated, retained for history |
| created_at | TEXT | ISO-8601 datetime | When user was created |
| last_login_at | TEXT | ISO-8601 datetime | When user last logged in |
| created_by | TEXT | FK → users.id, nullable | Owner ID who created this user (null for first Owner) |


### Example rows

*उदाहरण ओळी*

id: "u_owner_001"  name: "Sagar"  role: "OWNER"  pin_hash: "$2b$10$..."  language_pref: "en"  phone: "+91XXXXXXXXXX"  is_active: 1

id: "u_gm_001"     name: "Anita Joshi"  role: "GM"   pin_hash: "$2b$10$..."  language_pref: "en"  phone: "+91XXXXXXXXXX"  is_active: 1

id: "u_sm_001"     name: "Rahul Deshmukh"  role: "SM"  pin_hash: "$2b$10$..."  language_pref: "mr"  phone: "+91XXXXXXXXXX"  is_active: 1


| WARNING \| सूचना<br>PINs are never stored in plaintext. The PIN entered at login is hashed using bcrypt (cost factor 10) and compared to pin_hash. On PIN change, generate a fresh bcrypt hash. Never log PINs or hashes anywhere — not to console, not to crash reports, not to audit_log.<br>PIN प्लेन-टेक्स्टमध्ये कधीही साठवू नका. लॉगिनवर टाकलेला PIN bcrypt (कॉस्ट फॅक्टर १०) ने हॅश केला जातो आणि pin_hash शी तुलना केली जाते. PIN बदलावर ताजे bcrypt हॅश तयार करा. PIN किंवा हॅश कुठेही लॉग करू नका — कन्सोलवर नाही, क्रॅश रिपोर्टवर नाही, audit_log वर नाही. |
| --- |




### Table 4.2 — devices
## Table 4.2 — devices

*तक्ता ४.२ — डिव्हाइसेस*

One row per physical device that has logged in. Useful for conflict resolution and "who edited what from where".

लॉग इन केलेल्या प्रत्येक प्रत्यक्ष डिव्हाइससाठी एक ओळ. संघर्ष निरसन आणि "कोणी कुठून संपादित केले" साठी उपयुक्त.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | Device-generated UUID; persists across app reinstalls |
| model | TEXT | e.g. "Samsung Galaxy A54" |
| os_version | TEXT | e.g. "Android 14" |
| app_version | TEXT | e.g. "1.0.3" |
| last_user_id | TEXT FK → users.id | Who logged in last on this device |
| last_seen_at | TEXT ISO-8601 | Last time the app was opened |
| sync_state | TEXT | "synced", "syncing", "failed" |
| last_sync_at | TEXT ISO-8601 | Last successful sync to Firestore |




### Table 4.5 — cros
## Table 4.5 — cros

*तक्ता ४.५ — सीआरओ*

The CRO dropdown list. Maintained by SM/GM/Owner via Settings → Manage CROs. CROs do not log into the app; they are just selectable references in audits and CAPs.

सीआरओ ड्रॉपडाउन यादी. सेटिंग्ज → सीआरओ व्यवस्थापन द्वारे SM/GM/मालक सांभाळतो. सीआरओ अॅपमध्ये लॉग इन करत नाहीत; ते ऑडिट आणि CAP मध्ये फक्त निवडण्यायोग्य संदर्भ आहेत.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | UUID |
| name | TEXT NOT NULL | Display name e.g. "Priya Kulkarni" |
| counter | TEXT | "Titan" or "Helios" — which counter they staff |
| shift | TEXT | "morning", "afternoon", "flexible" |
| is_active | INTEGER default 1 | 0 = no longer with the store, kept for history |
| joined_at | TEXT ISO-8601 date | Optional, for tenure tracking |




### Role Capabilities for Settings & Admin (from Section 3)
## Capabilities matrix

*क्षमता मॅट्रिक्स*

The table below is the authoritative source for what each role can do. If Claude Code asks "can the GM delete a CAP?" — look at this table. If the action is not listed as YES for that role, the answer is NO.

खालचा तक्ता प्रत्येक भूमिका काय करू शकते याचा अधिकृत स्रोत आहे. क्लॉड कोडने विचारले "जीएम CAP हटवू शकते का?" — हा तक्ता पाहा. त्या भूमिकेसाठी कृती YES नसेल — उत्तर NO.


| Capability \| क्षमता | SM | GM | Owner |
| --- | --- | --- | --- |
| Log in to app | ✓ | ✓ | ✓ |
| Change own PIN | ✓ | ✓ | ✓ |
| Run daily audit | ✓ | — | View only |
| Submit daily audit | ✓ | — | — |
| Run weekly audit | — | ✓ | View only |
| Submit weekly audit | — | ✓ | — |
| Run monthly audit | — | — | ✓ |
| Verify daily audit (spot check, sign) | — | ✓ | ✓ |
| Create CAP | ✓ | ✓ | ✓ |
| Mark CAP Done (own CAPs only) | ✓ | ✓ | ✓ |
| Verify CAP (any CAP) | — | ✓ | ✓ |
| Close CAP (any CAP) | — | ✓ | ✓ |
| Re-open closed CAP | — | — | ✓ |
| Extend CAP deadline (before expiry) | — | ✓ | ✓ |
| View own audit history | ✓ | ✓ | ✓ |
| View all audits (any user) | — | ✓ | ✓ |
| View weekly reports | — | ✓ | ✓ |
| View monthly reports | — | — | ✓ |
| View trend dashboards | — | ✓ | ✓ |
| Receive escalation notifications | — | ✓ | ✓ |
| Send escalation (via app) | ✓ | ✓ | — |
| Manage CRO list (add/edit/remove names) | ✓ | ✓ | ✓ |
| Manage user list (create SM/GM logins) | — | — | ✓ |
| Reset another user's PIN | — | — | ✓ |
| Change app settings (language toggle, etc.) | ✓ own | ✓ own | ✓ all |
| Export data (PDF / CSV) | ✓ own | ✓ all | ✓ all |
| Delete an audit (cannot delete; only Owner can hide) | — | — | ✓ hide only |
| Modify checkpoint definitions (SOP changes) | — | — | ✓ via JSON edit |
| Access Reference tab | ✓ | ✓ | ✓ |
| Access Glossary | ✓ | ✓ | ✓ |



| NOTE \| टीप<br>When Claude Code is writing role-check code, it must consult this table for every screen. If a feature is shown for a role where the capability is — (dash), the app must either hide the UI element entirely or disable it with an explanation tooltip in the user's chosen language.<br>क्लॉड कोड रोल-चेक कोड लिहीत असेल तेव्हा प्रत्येक स्क्रीनसाठी हा तक्ता पाहावा. क्षमता — (डॅश) असलेल्या भूमिकेसाठी फीचर दाखवले जात असेल — अॅपने UI घटक एकतर पूर्णपणे लपवावा किंवा वापरकर्त्याच्या निवडलेल्या भाषेत स्पष्टीकरण टूलटिपसह अक्षम करावा. |
| --- |


## Audit immutability rule

*ऑडिट अपरिवर्तनीयता नियम*

Once a daily, weekly, or monthly audit is submitted, it cannot be edited. Not by the auditor, not by the GM, not by the Owner. This is a deliberate rule taken directly from Workbook Section 1.3 — an editable audit is not an audit. If a mistake is discovered after submission, the correct response is to file a new audit referencing the old one and explaining the correction, never to edit the old audit. The Owner alone has the power to HIDE an audit (mark it as superseded), but even hidden audits remain in the database and in the audit_log.

दैनंदिन, साप्ताहिक, किंवा मासिक ऑडिट सादर झाल्यावर ती संपादित करता येत नाही. ऑडिटरने नाही, जीएमने नाही, मालकाने नाही. हा पुस्तिकेच्या विभाग १.३ मधून थेट घेतलेला जाणीवपूर्वक नियम — संपादनयोग्य ऑडिट ऑडिट नाही. सादरीकरणानंतर चूक सापडली तर योग्य प्रतिसाद म्हणजे जुन्याचा संदर्भ देणारी आणि सुधारणा स्पष्ट करणारी नवीन ऑडिट दाखल करणे, जुनी ऑडिट कधीही संपादित न करणे. फक्त मालकाला ऑडिट लपवण्याची शक्ती (अधिक्रमित म्हणून खूण करणे), पण लपवलेल्या ऑडिटही डेटाबेस आणि audit_log मध्ये राहतात.

