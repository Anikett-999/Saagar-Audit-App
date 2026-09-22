# Saagar Audit App — Architecture & Data Model (Spec Sections 1–4)
> **Source**: Saagar_P1_App_Spec_v1.docx (Sections 1–4)  
> **Master**: [rain/SPEC_APP.md](../SPEC_APP.md)  
> **Index**: [rain/spec/INDEX.md](INDEX.md)

---

# Section 1 — Purpose & How to Use This Document

*विभाग १ — हेतू आणि हा दस्तऐवज कसा वापरायचा*

## Why this document exists

*हा दस्तऐवज का अस्तित्वात आहे*

Most app projects fail because the specification is written after coding starts, or is written in fragments, or is written so loosely that the developer (human or AI) makes a hundred small assumptions that compound into bugs. The result is a six-month bug-chase where every fix breaks two things. This document exists to prevent that for the Saagar Traders audit app.

बहुतेक अॅप प्रकल्प अपयशी होतात कारण तपशील कोडिंग सुरू झाल्यानंतर लिहिली जाते, किंवा तुकड्या-तुकड्यात लिहिली जाते, किंवा इतकी ढिली असते की डेव्हलपर (माणूस किंवा AI) शेकडो छोटी गृहीतके करतो जी बग्समध्ये जमतात. सहा महिन्यांची बग-शिकार होते जिथे प्रत्येक दुरुस्तीने दोन गोष्टी मोडतात. सागर ट्रेडर्स ऑडिट अॅपसाठी हे टाळण्यासाठी हा दस्तऐवज अस्तित्वात आहे.

The principle: write everything down before coding starts. Every screen. Every button. Every field in every database table. Every calculation. Every error case. Every Marathi translation. Every behaviour when offline. Every cross-reference to the operational Workbook. Once written, this document does not change during the build — if Claude Code thinks a change is needed, the change comes to this document first, gets reviewed, and then gets coded. The document leads, the code follows.

तत्व: कोडिंग सुरू होण्यापूर्वी सर्व काही लिहून ठेवा. प्रत्येक स्क्रीन. प्रत्येक बटण. प्रत्येक डेटाबेस टेबलमधले प्रत्येक क्षेत्र. प्रत्येक गणना. प्रत्येक त्रुटी प्रकरण. प्रत्येक मराठी अनुवाद. ऑफलाइन प्रत्येक वर्तन. कार्यवाहक पुस्तिकेचा प्रत्येक संदर्भ. एकदा लिहिले की हा दस्तऐवज बांधणीदरम्यान बदलत नाही — क्लॉड कोडला बदल हवा वाटला तर बदल आधी या दस्तऐवजात येतो, पुनरावलोकन होते, मग कोड होतो. दस्तऐवज नेतो, कोड अनुसरतो.

## Who this document is for

*हा दस्तऐवज कोणासाठी आहे*

- Sagar (Owner) — to verify that the app the developer builds matches what you specified. To recover the project if a developer disappears mid-build.
*सागर (मालक) — डेव्हलपरने बांधलेले अॅप तुम्ही ठरवलेल्याशी जुळते का याची पडताळणी करण्यासाठी. डेव्हलपर मध्येच गायब झाला तर प्रकल्प पुनर्प्राप्त करण्यासाठी.*

- Claude Code — the primary builder. Reads this document plus the Workbook and produces all source code. Should never be asked to write code without these two documents loaded.
*क्लॉड कोड — मुख्य बांधकाम करणारा. हा दस्तऐवज अधिक पुस्तिका वाचून सर्व सोर्स कोड तयार करतो. हे दोन दस्तऐवज लोड केल्याशिवाय कधीही कोड लिहायला सांगू नये.*

- Any future developer — if you ever hand the project to a freelance Flutter developer, this document is what you give them. They should be able to start coding from this without a single clarification call.
*कोणताही भविष्यातील डेव्हलपर — फ्रीलान्स Flutter डेव्हलपरला प्रकल्प सोपवायचा झाला तर त्यांना हाच दस्तऐवज द्या. एकाही स्पष्टीकरण कॉलशिवाय या वरून कोडिंग सुरू करता आले पाहिजे.*

- GM and Store Manager — to understand exactly what the app will do before it is built, and to flag in advance anything that does not match how they actually work.
*जीएम आणि स्टोअर मॅनेजर — अॅप बांधण्यापूर्वी ते नेमके काय करणार आहे हे समजून घेण्यासाठी, आणि ते प्रत्यक्ष कसे काम करतात त्याशी न जुळणारे काही आगाऊ झेंडे लावण्यासाठी.*

## The 8 design decisions locked at the start

*सुरुवातीला पक्के केलेले ८ डिझाइन निर्णय*

These eight decisions were locked before this document was written. Every other decision in this Spec flows from them. If any of these change, the Spec must be revised before any code change is made.

हे आठ निर्णय हा दस्तऐवज लिहिण्याआधी पक्के झाले. या तपशीलातला इतर प्रत्येक निर्णय यांतून येतो. यापैकी काही बदलले तर कोड बदलण्यापूर्वी तपशील सुधारली पाहिजे.


| # | Decision \| निर्णय | Locked answer \| पक्के उत्तर |
| --- | --- | --- |
| 1 | Roles in the app | Store Manager, GM, Owner login. CRO is a dropdown selection only, no login. |
| 2 | Login method | Name + 4-digit PIN. No email, no OTP. |
| 3 | Data storage | On-device SQLite + Firebase free tier (cloud sync, ₹0/month) |
| 4 | Photo evidence | Mandatory for Cash and Inventory Fails. Optional for all other SOPs. |
| 5 | CAPs | Built into Phase 1. Every Fail produces a CAP. |
| 6 | Bilingual UI | Toggle: user picks EN or MR at login. One language shown at a time. |
| 7 | Phasing | 4 phases over 13 weeks. Phase 1 daily audit + CAPs; Phase 2 weekly audit; Phase 3 monthly + escalation; Phase 4 polish & release. |
| 8 | Reference content | Workbook Appendices A.4 / A.5 / A.6 / A.7 built into app as Reference tab. |



| WARNING \| सूचना<br>If any decision above ever needs revisiting during the build, STOP coding. Revise this document first, get Sagar's sign-off, then resume coding. Do not let Claude Code change one of these decisions inside its own session.<br>बांधणीदरम्यान वरील कोणताही निर्णय पुन्हा तपासण्याची गरज पडली, तर कोडिंग थांबवा. आधी हा दस्तऐवज सुधारा, सागरची मान्यता घ्या, मग कोडिंग पुन्हा सुरू करा. क्लॉड कोडला त्याच्या स्वतःच्या सत्रात यापैकी एक निर्णय बदलू देऊ नका. |
| --- |


# Section 2 — System Architecture & Technology Stack

*विभाग २ — सिस्टम आर्किटेक्चर आणि तंत्रज्ञान*

## Architecture in one paragraph

*एका परिच्छेदात आर्किटेक्चर*

A Flutter Android application reads and writes to a local SQLite database on each device. Whenever the device has internet, the local database syncs bidirectionally with Firebase Firestore (a cloud database). All three users (Store Manager, GM, Owner) share the same Firestore project. The app works fully offline; data captured offline syncs the next time the device sees the internet. Photos are stored in Firebase Storage (cloud) and cached locally on the device. There is no custom server, no DevOps, no monthly hosting cost.

Flutter Android अॅप्लिकेशन प्रत्येक डिव्हाइसवर लोकल SQLite डेटाबेसमधून वाचतो आणि लिहितो. डिव्हाइसला इंटरनेट असेल तेव्हा लोकल डेटाबेस Firebase Firestore (क्लाउड डेटाबेस) सोबत द्विदिश समक्रमित होतो. तिन्ही वापरकर्ते (स्टोअर मॅनेजर, जीएम, मालक) तोच Firestore प्रकल्प वापरतात. अॅप पूर्णतः ऑफलाइन काम करते; ऑफलाइन घेतलेला डेटा डिव्हाइसला इंटरनेट दिसताच समक्रमित होतो. फोटो Firebase Storage (क्लाउड) मध्ये साठवले जातात आणि डिव्हाइसवर कॅशे केले जातात. कस्टम सर्व्हर नाही, DevOps नाही, मासिक होस्टिंग खर्च नाही.

## Technology stack — locked

*तंत्रज्ञान स्टॅक — पक्के*


| Layer \| थर | Technology \| तंत्रज्ञान | Version \| आवृत्ती | Why this choice \| का |
| --- | --- | --- | --- |
| UI framework | Flutter | >= 3.16 | Single codebase, Android first, iPhone-ready, Marathi rendering |
| Language | Dart | >= 3.2 | Flutter's native language |
| Local DB | SQLite via sqflite | Latest | Industry standard for offline storage on mobile |
| Cloud DB | Firebase Firestore | Latest | Free tier sufficient for 3 users, automatic sync |
| Cloud storage | Firebase Storage | Latest | Photos / PDF attachments; free tier 5 GB |
| Auth | Local PIN (custom impl) | — | No Firebase Auth needed — 3-user PIN is simpler |
| State mgmt | Riverpod | >= 2.4 | Most maintainable Flutter state library in 2026 |
| Routing | go_router | >= 12.0 | Standard Flutter routing |
| i18n | flutter_localizations + intl | Latest | Standard Flutter bilingual support |
| PDF generation | pdf package | >= 3.10 | For exporting audit reports |
| Photo capture | image_picker + camera | Latest | Cross-platform camera access |
| Notifications | flutter_local_notifications + url_launcher | Latest | In-app + WhatsApp deep links |
| Charts/graphs | fl_chart | >= 0.65 | For trend analysis on Owner dashboard |
| Build target | Android API 24+ (Android 7.0+) | — | Covers >99% of devices in India in 2026 |



| WARNING \| सूचना<br>Do NOT swap any of these for alternatives during the build. "sqflite" not "drift" or "isar". "Riverpod" not "Provider" or "Bloc". "go_router" not "auto_route". Every alternative is good in its own right, but mixing creates bugs. The Master Prompt in Section 14 will explicitly forbid Claude Code from suggesting alternatives.<br>बांधणीदरम्यान यापैकी कोणतेही पर्यायाने बदलू नका. "sqflite" — "drift" किंवा "isar" नव्हे. "Riverpod" — "Provider" किंवा "Bloc" नव्हे. "go_router" — "auto_route" नव्हे. प्रत्येक पर्याय स्वतःमध्ये चांगला, पण मिसळल्याने बग्स तयार होतात. विभाग १४ मधला मास्टर प्रॉम्प्ट क्लॉड कोडला पर्याय सुचवण्यास स्पष्टपणे प्रतिबंध करतो. |
| --- |


## Offline behaviour — the contract

*ऑफलाइन वर्तन — करार*

The app must be fully usable when offline. Specifically:

ऑफलाइन असताना अॅप पूर्णतः वापरण्यायोग्य असले पाहिजे. विशेषतः:

- User can log in offline (PIN check is local against last-known device PIN hash).
*वापरकर्ता ऑफलाइन लॉग इन करू शकतो (PIN तपासणी डिव्हाइसवरच्या शेवटच्या-ज्ञात PIN हॅशशी लोकल होते).*

- User can run a full daily audit offline; data saves to local SQLite.
*वापरकर्ता ऑफलाइन पूर्ण दैनंदिन ऑडिट चालवू शकतो; डेटा लोकल SQLite मध्ये जतन होतो.*

- User can attach photos offline; photos save locally, queued for upload on next connection.
*वापरकर्ता ऑफलाइन फोटो जोडू शकतो; फोटो लोकल जतन होतात, पुढच्या कनेक्शनवर अपलोडसाठी रांगेत.*

- User can create CAPs offline; CAPs save locally, sync on next connection.
*वापरकर्ता ऑफलाइन CAP तयार करू शकतो; CAP लोकल जतन होतात, पुढच्या कनेक्शनवर समक्रमित.*

- User can view PAST audits (those already synced to device) offline. Audits created on OTHER devices that have not yet synced to this device are not visible offline.
*वापरकर्ता मागच्या ऑडिट पाहू शकतो (आधीच डिव्हाइसवर समक्रमित झालेल्या) ऑफलाइन. इतर डिव्हाइसवर तयार झालेल्या आणि अजून या डिव्हाइसवर समक्रमित न झालेल्या ऑडिट ऑफलाइन दिसत नाहीत.*

- When the device reconnects to the internet, sync runs automatically in the background. A small status icon at the top of the screen shows sync state: green dot (synced), amber dot (syncing), red dot (sync failed).
*डिव्हाइस इंटरनेटला पुन्हा जोडले की समक्रमण पार्श्वभूमीत आपोआप चालते. स्क्रीनच्या वर एक छोटा स्थिती चिन्ह समक्रमण स्थिती दाखवतो: हिरवा ठिपका (समक्रमित), पिवळा (समक्रमण होत आहे), लाल (समक्रमण अयशस्वी).*

## Conflict resolution — when two devices edit the same thing

*संघर्ष निरसन — दोन डिव्हाइस एकच गोष्ट संपादित करतात तेव्हा*

It is rare but possible: GM marks a CAP as Verified on her tablet offline, Store Manager marks the same CAP as Done on his phone offline. Both sync later. Rule: last-write-wins by Firestore server timestamp, BUT every write also appends an entry to a CAP audit_log table with the device ID, user ID, and timestamp. So even if a write is overwritten, the history shows both writes and who made each. The app must never silently lose data; it must always show the history.

क्वचित पण शक्य: जीएम तिच्या टॅबलेटवर CAP Verified म्हणून ऑफलाइन खूण करते, स्टोअर मॅनेजर त्याच्या फोनवर तीच CAP Done म्हणून ऑफलाइन खूण करतो. दोघे नंतर समक्रमित होतात. नियम: Firestore सर्व्हर वेळ-शिक्क्यानुसार शेवटचे-लिहिणे-जिंकते, पण प्रत्येक लेखन CAP audit_log टेबलमध्ये डिव्हाइस आयडी, वापरकर्ता आयडी, आणि वेळ-शिक्क्यासह नोंद जोडते. म्हणून लेखन ओव्हरराइट झाले तरी इतिहास दोन्ही लेखने आणि कोणी केली ते दाखवतो. अॅपने डेटा शांतपणे कधीही गमावू नये; इतिहास नेहमी दाखवला पाहिजे.

## Cost projection over 12 months

*१२ महिन्यांचा खर्च अंदाज*


| Item \| आयटम | Cost \| खर्च | Note \| टीप |
| --- | --- | --- |
| Firebase Firestore (free tier) | ₹0 | 50K reads + 20K writes per day free; we will use < 5K of each |
| Firebase Storage (free tier) | ₹0 | 5 GB free; we will use < 1 GB |
| Google Play Developer account (one-time) | ₹2,000 | Optional — only if publishing publicly on Play Store |
| Domain for support email (optional) | ₹800/year | Optional |
| Apple Developer (if iPhone in future) | ₹8,000/year | Phase 5+ only, not in current scope |
| TOTAL — Year 1 (Android only, Play Store) | ~₹2,800 / year | Effectively zero per month after one-time setup |


# Section 3 — Roles, Permissions & Capabilities Matrix

*विभाग ३ — भूमिका, परवानग्या आणि क्षमता मॅट्रिक्स*

## The four roles

*चार भूमिका*

### 3.1 — Store Manager (SM)

*३.१ — स्टोअर मॅनेजर*

The Store Manager is the primary day-to-day user. The app exists first for the SM. SM logs into the app every evening, runs the daily audit, creates CAPs for Fails, and submits the audit to the GM. The SM also marks Done on CAPs assigned to him as they are completed.

स्टोअर मॅनेजर हा प्राथमिक दैनंदिन वापरकर्ता. अॅप पहिल्यांदा SM साठीच अस्तित्वात आहे. SM दर संध्याकाळी अॅपमध्ये लॉग इन करतो, दैनंदिन ऑडिट चालवतो, नापासांसाठी CAP तयार करतो, आणि ऑडिट जीएमला सादर करतो. SM त्याला नेमलेल्या CAP पूर्ण झाल्यावर Done म्हणूनही खूण करतो.

### 3.2 — General Manager (GM)

*३.२ — जनरल मॅनेजर*

The GM is the verifier. The GM logs in twice a week (typically Saturday afternoon and Monday morning). On Saturday/Monday, the GM runs the weekly audit — reviews the seven daily audits from the past week, conducts spot checks, scores the weekly-only checkpoints, and submits the weekly report to the Owner. The GM also verifies CAPs that the SM has marked Done.

जीएम पडताळणी करणारा. जीएम आठवड्यातून दोनदा लॉग इन करते (साधारणपणे शनिवारी दुपारी आणि सोमवारी सकाळी). शनि/सोमवारी जीएम साप्ताहिक ऑडिट चालवते — मागच्या आठवड्याची सात दैनंदिन ऑडिट पुनरावलोकन करते, स्पॉट चेक करते, साप्ताहिक-केवळ तपासणी बिंदू स्कोअर करते, आणि साप्ताहिक अहवाल मालकाला सादर करते. SM ने Done म्हणून खूण केलेल्या CAP जीएम पडताळते.

### 3.3 — Owner (Sagar)

*३.३ — मालक (सागर)*

The Owner is the strategic user. The Owner logs in approximately weekly — Sunday morning is the typical time. The Owner reads the weekly report submitted by the GM, conducts a monthly audit on the first Sunday of each month, reviews trend dashboards, and responds to escalations. The Owner has full read-and-write access to everything in the system.

मालक हा सामरिक वापरकर्ता. मालक साधारणपणे साप्ताहिक लॉग इन करतो — रविवारी सकाळी सामान्य वेळ. मालक जीएमने सादर केलेला साप्ताहिक अहवाल वाचतो, दर महिन्याच्या पहिल्या रविवारी मासिक ऑडिट करतो, कल डॅशबोर्ड पुनरावलोकन करतो, आणि एस्केलेशनला प्रतिसाद देतो. मालकाला सिस्टममधल्या सर्व गोष्टींना पूर्ण वाचन-लेखन प्रवेश आहे.

### 3.4 — CRO (Not a logged-in user)

*३.४ — सीआरओ (लॉग-इन वापरकर्ता नाही)*

CROs do not log into the app. CRO names exist in the system as a dropdown list maintained by the Store Manager (Settings → Manage CROs). When an audit Fail is logged that involves a specific CRO, the SM selects the CRO from the dropdown. The CRO never sees the app; if the CRO needs to know about a Fail, the SM tells the CRO in person.

सीआरओ अॅपमध्ये लॉग इन करत नाहीत. सीआरओ नावे स्टोअर मॅनेजरने सांभाळलेल्या ड्रॉपडाउन यादी म्हणून सिस्टममध्ये अस्तित्वात आहेत (सेटिंग्ज → सीआरओ व्यवस्थापन). विशिष्ट सीआरओचा समावेश असलेला ऑडिट नापास नोंदवला की SM ड्रॉपडाउनमधून सीआरओ निवडतो. सीआरओ अॅप कधीही पाहत नाही; नापासाबद्दल सीआरओला सांगायचे झाले तर SM सीआरओला प्रत्यक्ष सांगतो.

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

# Section 4 — Complete Data Model

*विभाग ४ — संपूर्ण डेटा मॉडेल*

## How to read this section

*हा विभाग कसा वाचायचा*

The data model is the foundation. Every screen reads or writes data; if the data model is wrong, every screen built on top of it will be wrong. Each table below has: a name, a one-line purpose, every field with its type and constraints, the relationships to other tables, and worked example rows. Field types use SQLite types for the local DB; Firestore stores the same data as documents in collections of the same names.

डेटा मॉडेल हे पाया आहे. प्रत्येक स्क्रीन डेटा वाचतो किंवा लिहितो; डेटा मॉडेल चुकीचे असेल तर त्यावर बांधलेला प्रत्येक स्क्रीन चुकीचा असेल. खालच्या प्रत्येक टेबलला आहे: नाव, एका-ओळीचा हेतू, प्रत्येक क्षेत्र त्याच्या प्रकार व मर्यादांसह, इतर टेबलांशी संबंध, आणि उदाहरण ओळी. क्षेत्र प्रकार लोकल DB साठी SQLite प्रकार वापरतात; Firestore त्याच नावांच्या कलेक्शनमध्ये दस्तऐवज म्हणून तोच डेटा साठवतो.

## Entity-relationship overview

*घटक-संबंध आढावा*

There are 14 tables. They cluster into four groups: identity (users, devices), structure (sops, checkpoints, cros), operations (audits, audit_results, photos, caps, cap_actions, cap_log), and reporting (reports, escalations, audit_log). The diagram below describes their relationships in plain text — when implementing in code, you may draw it visually.

१४ टेबल आहेत. ते चार गटांत येतात: ओळख (वापरकर्ते, डिव्हाइसेस), रचना (एसओपी, तपासणी बिंदू, सीआरओ), कार्यवाही (ऑडिट, ऑडिट निकाल, फोटो, CAPs, CAP कृती, CAP लॉग), आणि अहवाल (अहवाल, एस्केलेशन, ऑडिट लॉग). खालचे आकृती साध्या मजकुरात त्यांचे संबंध वर्णन करते — कोडमध्ये अंमलात आणताना तुम्ही ते दृश्यपणे काढू शकता.

### Relationship summary

*संबंध सारांश*

- users 1 → many audits (an SM has many daily audits)
*वापरकर्ते १ → अनेक ऑडिट (एका SM ला अनेक दैनंदिन ऑडिट)*

- audits 1 → many audit_results (each audit has 68 results for daily, 124 for weekly)
*ऑडिट १ → अनेक ऑडिट निकाल (प्रत्येक दैनंदिन ऑडिटला ६८ निकाल, साप्ताहिकला १२४)*

- audit_results 1 → many photos (a Fail can have multiple photo evidence)
*ऑडिट निकाल १ → अनेक फोटो (एका नापासाला अनेक फोटो पुरावे असू शकतात)*

- audit_results 1 → 0 or 1 cap (a Fail produces exactly one CAP)
*ऑडिट निकाल १ → ० किंवा १ CAP (एक नापास नेमकी एक CAP तयार करतो)*

- caps 1 → many cap_actions (a CAP has 3-5 action steps)
*CAP १ → अनेक CAP कृती (एका CAP ला ३-५ कृती पावले)*

- caps 1 → many cap_log entries (every status change appends to log)
*CAP १ → अनेक CAP लॉग नोंदी (प्रत्येक स्थिती बदल लॉगला जोडतो)*

- audits 1 → 0 or 1 report (a weekly or monthly audit produces a single report document)
*ऑडिट १ → ० किंवा १ अहवाल (एक साप्ताहिक किंवा मासिक ऑडिट एक अहवाल दस्तऐवज तयार करते)*

- audits or caps → 0 or many escalations (escalations cite the source)
*ऑडिट किंवा CAP → ० किंवा अनेक एस्केलेशन (एस्केलेशन स्रोत उद्धृत करते)*

- ANY write → 1 audit_log entry (every database write is logged for traceability)
*कोणतेही लेखन → १ audit_log नोंद (शोधनीयतेसाठी प्रत्येक डेटाबेस लेखन लॉग केले जाते)*

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


## Table 4.3 — sops

*तक्ता ४.३ — एसओपी*

The 8 Priority 1 SOPs. Seeded once at app install; can be modified only by Owner via JSON edit (Section 4.15 below).

८ प्राधान्य १ एसओपी. अॅप इन्स्टॉल झाल्यावर एकदा सीड केले जातात; फक्त मालक JSON संपादनाद्वारे (विभाग ४.१५ खाली) बदलू शकतो.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | Short code, e.g. "SOP1", "SOP6" |
| number | INTEGER | 1 to 8 |
| name_en | TEXT | "Grooming & Personal Standards" |
| name_mr | TEXT | "ग्रूमिंग आणि वैयक्तिक मानक" |
| weight | INTEGER | 1 or 2 (Cash and Inventory are 2x) |
| is_critical | INTEGER | 0 or 1 (1 for Cash, Inventory) |
| display_order | INTEGER | 1-8, controls UI sort order |


### All 8 SOPs as seed data

*सर्व ८ एसओपी सीड डेटा म्हणून*


| id | Name (EN) | Name (MR) | Wt |
| --- | --- | --- | --- |
| SOP1 | Grooming & Personal Standards | ग्रूमिंग आणि वैयक्तिक मानक | 1 |
| SOP2 | Sales Buddy Photo Compliance | सेल्स बडी फोटो अनुपालन | 1 |
| SOP3 | NPS Calling | एनपीएस कॉलिंग | 1 |
| SOP4 | Customer Data Capture | ग्राहक डेटा कॅप्चर | 1 |
| SOP5 | Display & Planogram | डिस्प्ले आणि प्लानोग्राम | 1 |
| SOP6 | Cash Management ★ | रोख व्यवस्थापन ★ | 2 |
| SOP7 | Inventory Management ★ | स्टॉक व्यवस्थापन ★ | 2 |
| SOP8 | Watch Service Intake | घड्याळ सर्व्हिस इनटेक | 1 |


## Table 4.4 — checkpoints

*तक्ता ४.४ — तपासणी बिंदू*

The individual checkpoint definitions. Daily has 68 checkpoints; weekly has an additional 36; monthly has its own set (defined in Phase 3). Seeded at install from a JSON file shipped with the app. Total expected: 68 daily + 36 weekly = 104 checkpoints at end of Phase 2.

वैयक्तिक तपासणी बिंदू व्याख्या. दैनंदिनला ६८; साप्ताहिकला अतिरिक्त ३६; मासिकला स्वतःचा संच (टप्पा ३ मध्ये परिभाषित). अॅपसोबत आलेल्या JSON फाइलमधून इन्स्टॉलवर सीड केले जातात. एकूण अपेक्षित: ६८ दैनंदिन + ३६ साप्ताहिक = टप्पा २ अखेरीस १०४ तपासणी बिंदू.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | "1.1", "6.5", "CW.7", "IW.11" |
| sop_id | TEXT FK → sops.id | Parent SOP |
| frequency | TEXT | "daily", "weekly", "monthly" |
| sequence | INTEGER | Order within SOP (1.1, 1.2, ...) |
| text_en | TEXT | "Uniform clean and pressed" |
| text_mr | TEXT | "गणवेश स्वच्छ आणि इस्त्री केलेला" |
| evidence_en | TEXT | "Photo with timestamp" |
| evidence_mr | TEXT | "वेळ-शिक्क्यासह फोटो" |
| weight | INTEGER | 1 or 2 (matches parent SOP) |
| allows_na | INTEGER | 0 or 1 (some checkpoints cannot be NA) |
| requires_photo_on_fail | INTEGER | 0 or 1 (Cash/Inv = 1) |


### Sample checkpoint rows

*नमुना तपासणी बिंदू ओळी*

id: "1.1"   sop_id: "SOP1"  frequency: "daily"  sequence: 1   text_en: "Uniform clean and pressed"  weight: 1  allows_na: 1  requires_photo_on_fail: 0

id: "6.5"   sop_id: "SOP6"  frequency: "daily"  sequence: 5   text_en: "Closing cash variance within ±₹50 (or explained)"  weight: 2  allows_na: 0  requires_photo_on_fail: 1

id: "7.1"   sop_id: "SOP7"  frequency: "daily"  sequence: 1   text_en: "Daily cycle count for rotation tray"  weight: 2  allows_na: 0  requires_photo_on_fail: 1

id: "CW.7"  sop_id: "SOP6"  frequency: "weekly" sequence: 7   text_en: "Cumulative weekly variance within ±₹200"  weight: 2  allows_na: 0  requires_photo_on_fail: 1

id: "IW.1"  sop_id: "SOP7"  frequency: "weekly" sequence: 1   text_en: "Full storage area count — two signatures"  weight: 2  allows_na: 0  requires_photo_on_fail: 1


| WARNING \| सूचना<br>The seed JSON file (assets/seed/checkpoints.json) is shipped with the app and contains all 104 checkpoints with their full EN+MR text, evidence requirements, weights, and flags. The contents of this JSON are drawn DIRECTLY from the Workbook — Day 2 Section 2.9 for daily, Day 3 Section 3.4 for weekly. Any change to a checkpoint requires (a) updating the Workbook, (b) updating this Spec, (c) updating the JSON, (d) versioned migration of any in-flight audits. Never change the JSON without all four.<br>सीड JSON फाइल (assets/seed/checkpoints.json) अॅपसोबत येते आणि सर्व १०४ तपासणी बिंदू त्यांच्या पूर्ण EN+MR मजकूर, पुरावा आवश्यकता, वजने, आणि झेंडे यासह आहेत. या JSON ची सामग्री पुस्तिकेतून थेट काढलेली — दैनंदिनसाठी दिवस २ विभाग २.९, साप्ताहिकसाठी दिवस ३ विभाग ३.४. तपासणी बिंदूत कोणताही बदल आवश्यक करतो (अ) पुस्तिका सुधारणे, (ब) ही तपशील सुधारणे, (क) JSON सुधारणे, (ड) चालू असलेल्या ऑडिटचे व्हर्जन माइग्रेशन. चारही नसताना JSON कधीही बदलू नका. |
| --- |


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


## Table 4.6 — audits

*तक्ता ४.६ — ऑडिट*

The single most important table. One row per submitted audit — daily, weekly, or monthly. Once submitted, the row becomes immutable (see Section 3 — Audit immutability rule).

एकमेव सर्वात महत्त्वाचा तक्ता. प्रत्येक सादर केलेल्या ऑडिटसाठी एक ओळ — दैनंदिन, साप्ताहिक, किंवा मासिक. सादर झाल्यानंतर ओळ अपरिवर्तनीय होते (विभाग ३ — ऑडिट अपरिवर्तनीयता नियम पाहा).


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | UUID |
| audit_type | TEXT NOT NULL | "daily", "weekly", "monthly" |
| audit_date | TEXT NOT NULL | ISO date the audit COVERS (not when submitted) |
| week_number | INTEGER | Calendar week 1-53 (for weekly/monthly) |
| month_number | INTEGER | 1-12 (for monthly only) |
| year | INTEGER NOT NULL | e.g. 2026 |
| auditor_id | TEXT FK → users.id | Who conducted the audit |
| device_id | TEXT FK → devices.id | Which device created it |
| status | TEXT NOT NULL | "draft", "submitted", "verified", "hidden" |
| raw_score | REAL | Raw weighted points earned |
| max_score | REAL | Max possible (after NA adjustments) |
| compliance_pct | REAL | raw_score / max_score × 100, 1 decimal |
| band | TEXT | "excellent", "good", "fair", "poor", "critical" |
| fail_count | INTEGER | Total Fails in this audit |
| pass_count | INTEGER | Total Passes in this audit |
| na_count | INTEGER | Total NAs in this audit |
| draft_started_at | TEXT ISO-8601 | When SM/GM/Owner started the audit |
| submitted_at | TEXT ISO-8601 | When the audit was submitted |
| verified_at | TEXT ISO-8601 nullable | When GM/Owner verified it (daily only) |
| verifier_id | TEXT FK → users.id nullable | Who verified it |
| supersedes_audit_id | TEXT FK → audits.id nullable | If this audit replaces a hidden one |
| hidden_at | TEXT nullable | If status='hidden', when |
| hidden_by | TEXT FK → users.id nullable | Who hid it (Owner only) |
| hidden_reason | TEXT nullable | Why it was hidden |
| notes | TEXT | Free-text notes from auditor |


### Example daily audit row

*उदाहरण दैनंदिन ऑडिट ओळ*

id: "a_20260527_sm"  audit_type: "daily"  audit_date: "2026-05-27"  year: 2026  auditor_id: "u_sm_001"

status: "submitted"  raw_score: 82.0  max_score: 90.0  compliance_pct: 91.1  band: "good"

fail_count: 5  pass_count: 60  na_count: 3  submitted_at: "2026-05-27T21:28:14+05:30"

## Table 4.7 — audit_results

*तक्ता ४.७ — ऑडिट निकाल*

The per-checkpoint result of an audit. A daily audit produces 68 rows here (one per checkpoint). A weekly audit produces up to 104 (68 daily-equivalent + 36 weekly-only).

ऑडिटचा प्रति-तपासणी बिंदू निकाल. एक दैनंदिन ऑडिट इथे ६८ ओळी तयार करते (प्रत्येक तपासणी बिंदूसाठी एक). एक साप्ताहिक ऑडिट १०४ पर्यंत तयार करते (६८ दैनंदिन-समकक्ष + ३६ साप्ताहिक-केवळ).


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | UUID |
| audit_id | TEXT FK → audits.id | Parent audit |
| checkpoint_id | TEXT FK → checkpoints.id | Which checkpoint |
| result | TEXT NOT NULL | "P", "F", "NA" |
| weighted_points | REAL | What this result contributes to raw_score |
| finding_text | TEXT | One-sentence finding for Fails; NA reason for NAs |
| cro_id | TEXT FK → cros.id nullable | Which CRO if relevant |
| created_at | TEXT ISO-8601 | When this result was marked |


### Scoring rule for weighted_points

*weighted_points साठी स्कोअरिंग नियम*

if result = "P":   weighted_points = checkpoint.weight  (1 or 2)

if result = "F":   weighted_points = 0

if result = "NA":  weighted_points = NULL  (excluded from both numerator and denominator)


| WARNING \| सूचना<br>NA is critical to handle correctly. NA rows do not count in either the numerator (raw_score) or the denominator (max_score). A daily audit with 5 NAs has a max_score of 90 - sum(weights of those 5 checkpoints), not 90. This is why max_score is stored on the audit row — it's computed at submission time from the actual results. See Section 6 for full formulas.<br>NA योग्य प्रकारे हाताळणे महत्त्वाचे. NA ओळी अंकगणितात (raw_score) किंवा भागकात (max_score) दोन्ही मोजल्या जात नाहीत. ५ NA असलेल्या दैनंदिन ऑडिटचा max_score ९० नसून ९० - त्या ५ तपासणी बिंदूंच्या वजनांची बेरीज. म्हणूनच max_score ऑडिट ओळीवर साठवला जातो — सादरीकरणाच्या वेळी प्रत्यक्ष निकालांवरून मोजला जातो. पूर्ण सूत्रांसाठी विभाग ६ पाहा. |
| --- |


## Table 4.8 — photos

*तक्ता ४.८ — फोटो*

Every photo attached as evidence. Linked to audit_results (for Fails) or to caps (for CAP progress evidence) or to caps verification.

पुरावा म्हणून जोडलेला प्रत्येक फोटो. ऑडिट निकालांशी (नापासांसाठी) किंवा CAPs शी (CAP प्रगती पुराव्यासाठी) किंवा CAPs पडताळणीशी जोडलेला.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | UUID |
| audit_result_id | TEXT FK nullable | If photo is for an audit Fail |
| cap_id | TEXT FK nullable | If photo is for a CAP step/verification |
| context | TEXT NOT NULL | "fail_evidence", "cap_progress", "cap_verification" |
| local_path | TEXT | On-device path (e.g. /storage/.../IMG_xxx.jpg) |
| cloud_url | TEXT nullable | Firebase Storage URL once uploaded |
| upload_status | TEXT | "pending", "uploading", "uploaded", "failed" |
| thumb_local_path | TEXT | 150x150 thumbnail for list view |
| captured_at | TEXT ISO-8601 | When photo was taken (from EXIF if available) |
| captured_lat | REAL nullable | GPS latitude (optional, for Sales Buddy parity) |
| captured_lng | REAL nullable | GPS longitude |
| uploaded_by | TEXT FK → users.id | Who took the photo |
| file_size_bytes | INTEGER | For storage tracking |



| NOTE \| टीप<br>Photos are taken in-app via the camera. Maximum 5 photos per Fail. Each photo is automatically compressed to max 1280px on the long edge, JPEG quality 80%, before upload. Original is kept on-device temporarily then deleted after upload succeeds. This keeps Firebase Storage usage under 5 GB free tier for at least 18 months.<br>फोटो अॅपमध्ये कॅमेऱ्याद्वारे घेतले जातात. प्रति नापास जास्तीत जास्त ५ फोटो. प्रत्येक फोटो अपलोडपूर्वी आपोआप जास्तीत जास्त १२८० पिक्सेल लांब बाजूवर, JPEG गुणवत्ता ८०% पर्यंत संकुचित केला जातो. मूळ डिव्हाइसवर तात्पुरते ठेवले जातात आणि अपलोड यशस्वी झाल्यानंतर हटवले जातात. यामुळे Firebase Storage वापर किमान १८ महिने ५ GB मोफत मर्यादेखाली राहतो. |
| --- |


## Table 4.9 — caps (Corrective Action Plans)

*तक्ता ४.९ — caps (कृती योजना)*

One CAP per Fail (or per Pattern when multiple Fails of the same checkpoint cluster). Maps directly to the CAP template in Workbook Appendix A.3.

प्रत्येक नापासासाठी एक CAP (किंवा एकाच तपासणी बिंदूचे अनेक नापास एकत्र असतील तर प्रति पॅटर्न). पुस्तिकेच्या परिशिष्ट A.३ मधल्या CAP टेम्पलेटशी थेट जुळते.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | Human-readable: "CAP-2026-W22-03" (auto-gen) |
| origin_audit_id | TEXT FK → audits.id | Which audit produced this CAP |
| origin_result_id | TEXT FK → audit_results.id nullable | Specific result (or null if pattern CAP) |
| origin_checkpoint_id | TEXT FK → checkpoints.id | Which checkpoint |
| is_pattern | INTEGER | 0 = single Fail; 1 = pattern (3+ days same checkpoint) |
| problem_statement | TEXT NOT NULL | 1 sentence — what failed |
| why_1 | TEXT | 5 Whys answer 1 |
| why_2 | TEXT | 5 Whys answer 2 |
| why_3 | TEXT | 5 Whys answer 3 |
| why_4 | TEXT | 5 Whys answer 4 |
| why_5 | TEXT | 5 Whys answer 5 |
| root_cause | TEXT NOT NULL | Distilled root cause from 5 Whys |
| responsible_user_id | TEXT FK → users.id | CAP Owner |
| deadline | TEXT ISO-8601 date | Default = origin audit date + 7 days |
| verification_method | TEXT | Which checkpoint will be re-run |
| status | TEXT NOT NULL | "open", "done", "verified", "closed", "aged", "reopened" |
| opened_at | TEXT ISO-8601 | When CAP was created |
| done_at | TEXT nullable | When responsible marked Done |
| verified_at | TEXT nullable | When verifier confirmed |
| closed_at | TEXT nullable | When formally closed |
| verified_by | TEXT FK → users.id nullable | Who verified |
| closed_by | TEXT FK → users.id nullable | Who closed |
| aged_count | INTEGER default 0 | How many times this CAP has aged |
| extension_count | INTEGER default 0 | How many extensions granted |
| latest_extension_reason | TEXT nullable | Why deadline was extended |


## Table 4.10 — cap_actions

*तक्ता ४.१० — CAP कृती*

The 3 to 5 numbered action steps inside a CAP. Each is its own row so it can be marked done independently.

एका CAP मधली ३ ते ५ क्रमांकित कृती पावले. प्रत्येकाची स्वतःची ओळ जेणेकरून ते स्वतंत्रपणे पूर्ण म्हणून खूण करता येतील.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | UUID |
| cap_id | TEXT FK → caps.id | Parent CAP |
| sequence | INTEGER NOT NULL | 1, 2, 3, 4, 5 within the CAP |
| action_text | TEXT NOT NULL | "Update Cash override SOP to include..." |
| is_done | INTEGER default 0 | 0 = not done, 1 = done |
| done_at | TEXT nullable | When marked done |
| done_by | TEXT FK → users.id nullable | Who marked done |
| done_notes | TEXT | Free text — what was actually done |


## Table 4.11 — cap_log

*तक्ता ४.११ — CAP लॉग*

Every status change to a CAP appends a row here. This is what makes the CAP history visible and conflict-resolvable.

CAP च्या प्रत्येक स्थिती बदलाने इथे एक ओळ जोडली जाते. यामुळेच CAP इतिहास दृश्य आणि संघर्ष-निरसनयोग्य होतो.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | UUID |
| cap_id | TEXT FK → caps.id | Parent CAP |
| event | TEXT NOT NULL | "created", "action_done", "marked_done", "verified", "closed", "extended", "aged", "reopened" |
| from_status | TEXT | Previous status (nullable for created) |
| to_status | TEXT NOT NULL | Resulting status |
| actor_user_id | TEXT FK → users.id | Who triggered the event |
| device_id | TEXT FK → devices.id | From which device |
| timestamp | TEXT ISO-8601 | When |
| note | TEXT | Optional context — e.g. reason for extension |


## Table 4.12 — reports

*तक्ता ४.१२ — अहवाल*

Generated weekly and monthly reports. Each report is a structured document that the user can view in-app and export as PDF.

तयार झालेले साप्ताहिक आणि मासिक अहवाल. प्रत्येक अहवाल हा एक संरचित दस्तऐवज जो वापरकर्ता अॅपमध्ये पाहू शकतो आणि PDF म्हणून निर्यात करू शकतो.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | UUID |
| audit_id | TEXT FK → audits.id | The audit that produced this report |
| report_type | TEXT | "weekly", "monthly" |
| headline | TEXT | 1-line summary, e.g. "Week 22: 91.3% GOOD, on target" |
| compliance_table_json | TEXT | JSON: 5-row component breakdown |
| trend_block_json | TEXT | JSON: this week vs last vs 4wk avg |
| findings_json | TEXT | JSON: up to 6 findings, one sentence each |
| patterns_json | TEXT | JSON: up to 3 patterns |
| caps_opened_json | TEXT | JSON: list of new CAPs this period |
| caps_closed_json | TEXT | JSON: list of CAPs closed this period |
| caps_aged_json | TEXT | JSON: list of CAPs that aged |
| escalations_json | TEXT | JSON: up to 3 escalations needed |
| author_user_id | TEXT FK → users.id | Who wrote the report |
| submitted_at | TEXT ISO-8601 | When submitted |
| read_by_owner_at | TEXT nullable | When Owner opened it |
| pdf_local_path | TEXT | Cached PDF path |
| pdf_cloud_url | TEXT | Firebase Storage URL |


## Table 4.13 — escalations

*तक्ता ४.१३ — एस्केलेशन*

An escalation event. Triggered automatically when any of the 7 mandatory triggers fires (see Section 7). Also can be manually created by SM or GM in exceptional cases.

एक एस्केलेशन घटना. ७ अनिवार्य ट्रिगरपैकी कोणताही सुरू झाल्यावर आपोआप चालू (विभाग ७ पाहा). अपवादात्मक प्रकरणांमध्ये SM किंवा GM ने हाताने तयार केलेलीही.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | TEXT PRIMARY KEY | UUID |
| trigger_number | INTEGER | 1-7, or 0 for manual |
| trigger_label | TEXT | "Daily Critical", "Cash > ₹500", etc. |
| source_type | TEXT | "audit", "cap", "trend", "manual" |
| source_audit_id | TEXT FK nullable | If linked to an audit |
| source_cap_id | TEXT FK nullable | If linked to a CAP |
| raised_by_user_id | TEXT FK → users.id | Who/what raised it |
| raised_to_user_id | TEXT FK → users.id | Whom it goes to (GM or Owner) |
| urgency | TEXT | "immediate", "same_day", "same_night", "next_audit" |
| what_happened | TEXT | 1 sentence |
| evidence | TEXT | What evidence proves it |
| impact | TEXT | Operational impact |
| requested_action | TEXT | What recipient should do |
| status | TEXT | "open", "acknowledged", "resolved" |
| raised_at | TEXT ISO-8601 | When |
| acknowledged_at | TEXT nullable | When recipient opened it |
| resolved_at | TEXT nullable | When marked resolved |
| resolution_notes | TEXT | How it was resolved |
| whatsapp_sent | INTEGER default 0 | Did we open WhatsApp deeplink? |


## Table 4.14 — audit_log (system audit trail)

*तक्ता ४.१४ — audit_log (सिस्टम ऑडिट ट्रेल)*

Not to be confused with the "audits" table. This is a system-level log of every database write (insert/update/delete attempt). Used for debugging, conflict resolution, and forensic review.

"audits" तक्त्याशी गोंधळून जाऊ नका. हा प्रत्येक डेटाबेस लेखनाचा (insert/update/delete प्रयत्न) सिस्टम-स्तरीय लॉग आहे. डीबगिंग, संघर्ष निरसन, आणि न्यायवैद्यक पुनरावलोकनासाठी वापरला जातो.


| Field \| क्षेत्र | Type \| प्रकार | Description \| वर्णन |
| --- | --- | --- |
| id | INTEGER AUTOINCREMENT | Local-only PK |
| table_name | TEXT | Which table was written |
| row_id | TEXT | PK of the affected row |
| operation | TEXT | "insert", "update", "delete_attempt" |
| actor_user_id | TEXT | Who did it |
| device_id | TEXT | From which device |
| timestamp | TEXT ISO-8601 | When |
| before_json | TEXT nullable | Row state before (for updates) |
| after_json | TEXT | Row state after |
| sync_state | TEXT | "local", "pushed_to_cloud" |



| NOTE \| टीप<br>audit_log entries are NEVER deleted, even when their source rows are deleted/hidden. It is the system's permanent record. The audit_log can grow large — implement a 90-day retention policy on this table only (oldest entries can be archived to Firestore cold storage).<br>audit_log नोंदी कधीही हटवल्या जात नाहीत, त्यांच्या स्रोत ओळी हटवल्या/लपवल्या तरीही. हा सिस्टमचा कायमचा रेकॉर्ड. audit_log मोठा होऊ शकतो — फक्त या तक्त्यावर ९०-दिवस धारणा धोरण अंमलात आणा (जुन्या नोंदी Firestore कोल्ड स्टोरेजमध्ये संग्रहित करता येतात). |
| --- |


## Section 4.15 — Seed data & schema migrations

*विभाग ४.१५ — सीड डेटा आणि स्कीमा माइग्रेशन*

### On first app install

*अॅप पहिल्या इन्स्टॉलवर*

- App creates the SQLite database with all 14 tables (schema from Section 4).
*अॅप १४ तक्त्यांसह SQLite डेटाबेस तयार करते (विभाग ४ मधले स्कीमा).*

- App reads assets/seed/sops.json — populates the sops table (8 rows).
*अॅप assets/seed/sops.json वाचते — sops तक्ता भरते (८ ओळी).*

- App reads assets/seed/checkpoints.json — populates the checkpoints table (104 rows in Phase 1+2; +monthly in Phase 3).
*अॅप assets/seed/checkpoints.json वाचते — checkpoints तक्ता भरते (टप्पा १+२ मध्ये १०४ ओळी; टप्पा ३ मध्ये +मासिक).*

- App shows the "first time setup" screen — Owner creates the first user (themselves) with role=OWNER. The Owner then creates GM and SM users.
*अॅप "पहिल्यांदा सेटअप" स्क्रीन दाखवते — मालक role=OWNER सह पहिला वापरकर्ता (स्वतः) तयार करतो. मग मालक GM आणि SM वापरकर्ते तयार करतो.*

- Owner adds initial CRO names via Settings → Manage CROs.
*मालक सेटिंग्ज → सीआरओ व्यवस्थापन द्वारे प्रारंभिक सीआरओ नावे जोडतो.*

- App ready for daily operations.
*अॅप दैनंदिन कार्यांसाठी तयार.*

### Schema migrations between app versions

*अॅप आवृत्त्यांमधील स्कीमा माइग्रेशन*

Use sqflite_migration_plan package. Every schema change ships as a numbered migration script (assets/migrations/v2.sql, v3.sql, etc.). On app upgrade, the app detects current schema version and runs migrations in sequence. Each migration is idempotent — running it twice has the same effect as running it once.

sqflite_migration_plan पॅकेज वापरा. प्रत्येक स्कीमा बदल क्रमांकित माइग्रेशन स्क्रिप्ट म्हणून पाठवला जातो (assets/migrations/v2.sql, v3.sql, इ.). अॅप अपग्रेडवर अॅप सध्याची स्कीमा आवृत्ती ओळखते आणि क्रमाने माइग्रेशन चालवते. प्रत्येक माइग्रेशन आइडेम्पोटेंट — दोनदा चालवण्याचा परिणाम एकदा चालवण्याइतकाच.

### Backup & restore

*बॅकअप आणि पुनर्संचयन*

Phase 1: Local SQLite is backed up to the device's Android backup system automatically. Owner can also tap Settings → Export → Backup to JSON, which writes a complete data dump to Downloads folder for manual archival. Phase 2 adds: scheduled daily Firestore export to Firebase Storage cold tier — kept for 1 year minimum.

टप्पा १: लोकल SQLite आपोआप डिव्हाइसच्या Android बॅकअप सिस्टममध्ये बॅकअप होतो. मालक सेटिंग्ज → निर्यात → JSON बॅकअप वर टॅप करूनही पूर्ण डेटा डंप Downloads फोल्डरमध्ये लिहू शकतो — स्वतः संग्रहित करण्यासाठी. टप्पा २ जोडतो: नियोजित दैनंदिन Firestore निर्यात Firebase Storage कोल्ड टियरमध्ये — किमान १ वर्षासाठी ठेवले.

