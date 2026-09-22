# Saagar Audit App — Daily Audit Screens S01–S11 (Spec Section 5 Part 1)
> **Source**: Saagar_P1_App_Spec_v1.docx (Section 5: Screens S01–S11)  
> **Master**: [rain/SPEC_APP.md](../SPEC_APP.md)  
> **Index**: [rain/spec/INDEX.md](INDEX.md)

---

# Section 5 — Screen-by-Screen Specification

*विभाग ५ — स्क्रीन-दर-स्क्रीन तपशील*

## How to read this section

*हा विभाग कसा वाचायचा*

Each screen below is documented with: a screen number, the purpose, who sees it, the layout (described top-to-bottom), every interactive element with its behaviour, the data it reads and writes, what happens on each button tap, the error states, the offline behaviour, and the cross-reference to the Workbook. Claude Code should build screens in the order numbered here.

खाली प्रत्येक स्क्रीन याच्यासह नोंदवलेला आहे: स्क्रीन क्रमांक, हेतू, कोण पाहतो, मांडणी (वर-खाली वर्णन केलेली), प्रत्येक इंटरॲक्टिव्ह घटक त्याच्या वर्तनासह, तो वाचणारा आणि लिहिणारा डेटा, प्रत्येक बटण टॅपवर काय होते, त्रुटी स्थिती, ऑफलाइन वर्तन, आणि पुस्तिकेचा संदर्भ. क्लॉड कोडने इथे क्रमांकित केलेल्या क्रमाने स्क्रीन बांधावेत.

## Screen catalogue (Phase 1)

*स्क्रीन कॅटलॉग (टप्पा १)*


| # | Screen \| स्क्रीन | Roles \| भूमिका |
| --- | --- | --- |
| S1 | Splash / Loading | All |
| S2 | Language Selection (first launch only) | All |
| S3 | First-Time Setup (first launch only) | Owner |
| S4 | Login | All |
| S5 | Home / Dashboard | All |
| S6 | Start Daily Audit | SM |
| S7 | Daily Audit — Checkpoint Screen | SM |
| S8 | Daily Audit — Fail Detail | SM |
| S9 | Daily Audit — Photo Capture | SM |
| S10 | Daily Audit — Review & Submit | SM |
| S11 | Daily Audit — Submitted Confirmation | SM |
| S12 | Audit History (own / all) | All |
| S13 | Audit Detail (read-only view) | All |
| S14 | CAP List | All |
| S15 | CAP Create | SM, GM, Owner |
| S16 | CAP Detail | All |
| S17 | CAP Action — Mark Done | Responsible user |
| S18 | CAP Verify | GM, Owner |
| S19 | CAP Close | GM, Owner |
| S20 | Reports List | GM, Owner |
| S21 | Report Detail | GM, Owner |
| S22 | Reference Tab — Index | All |
| S23 | Reference — Rating Scale | All |
| S24 | Reference — Escalation Triggers | All |
| S25 | Reference — Evidence Reference | All |
| S26 | Reference — Bilingual Glossary | All |
| S27 | Settings | All |
| S28 | Settings — Manage CROs | SM, GM, Owner |
| S29 | Settings — Manage Users | Owner |
| S30 | Settings — Change PIN | All |
| S31 | Settings — Language | All |
| S32 | Settings — Backup & Export | All |


**Screen S1 —** **Splash / Loading**

*स्क्रीन S1 — स्प्लॅश / लोडिंग*

Purpose: Show the brand for 1–2 seconds while the app initializes (loads DB, checks sync state, checks login state).

हेतू: अॅप सुरू होत असताना (DB लोड, समक्रमण स्थिती तपासणे, लॉगिन स्थिती तपासणे) १-२ सेकंदांसाठी ब्रँड दाखवा.

### Layout (top to bottom)

*मांडणी*

- Saagar Traders logo, centered.
*मध्यभागी सागर ट्रेडर्स लोगो.*

- "Priority 1 SOP Audit" tagline below logo.
*लोगोखाली "प्राधान्य १ एसओपी ऑडिट".*

- Indeterminate progress indicator at bottom.
*तळाशी अनिश्चित प्रगती सूचक.*

### Behaviour

*वर्तन*

- If first launch ever (no users in DB) → navigate to S2 (Language Selection).
*कधीही प्रथम लॉन्च (DB मध्ये वापरकर्ते नाहीत) → S2 (भाषा निवड) कडे जा.*

- Else if no active session → navigate to S4 (Login).
*अन्यथा सक्रिय सत्र नसेल → S4 (लॉगिन) कडे जा.*

- Else (session active and not expired) → navigate to S5 (Home).
*अन्यथा (सत्र सक्रिय आणि कालबाह्य नाही) → S5 (होम) कडे जा.*

### Data read/write

*डेटा वाचन/लेखन*

- Read: users.count, current session token (stored in secure storage).
*वाचन: users.count, सध्याचा सत्र टोकन (सुरक्षित संचयनात साठवलेला).*

### Workbook reference

*पुस्तिका संदर्भ*

- None.
*काही नाही.*

**Screen S4 —** **Login**

*स्क्रीन S4 — लॉगिन*

Purpose: Authenticate the user via name dropdown + 4-digit PIN.

हेतू: नाव ड्रॉपडाउन + ४-अंकी PIN द्वारे वापरकर्त्याची पडताळणी.

### Layout (top to bottom)

*मांडणी*

- App logo (top center, smaller than splash).
*अॅप लोगो (वर मध्यभागी, स्प्लॅशपेक्षा लहान).*

- Title: "Welcome / स्वागत" depending on user's last language pref (default English on cold device).
*शीर्षक: वापरकर्त्याच्या शेवटच्या भाषा प्राधान्यानुसार "Welcome / स्वागत" (थंड डिव्हाइसवर डीफॉल्ट इंग्रजी).*

- Name dropdown — populated from users WHERE is_active=1, sorted by role (Owner first, GM second, SMs last). Selected name persists across launches.
*नाव ड्रॉपडाउन — users WHERE is_active=1 मधून भरले जाते, भूमिकेनुसार क्रमवारी (मालक प्रथम, GM दुसरा, SM शेवटी). निवडलेले नाव लॉन्चमध्ये टिकते.*

- 4 PIN input boxes (large, tap-friendly).
*४ PIN इनपुट बॉक्स (मोठे, टॅप-अनुकूल).*

- Number pad (custom, in-app — do not use OS keyboard; PIN security).
*नंबर पॅड (कस्टम, अॅपमध्ये — OS कीबोर्ड वापरू नका; PIN सुरक्षा).*

- "Forgot PIN?" link below PIN.
*PIN खाली "PIN विसरलात?" दुवा.*

- Language toggle (EN | MR) at top-right corner.
*वर-उजव्या कोपऱ्यात भाषा टॉगल (EN | MR).*

### Behaviour

*वर्तन*

- User selects name → PIN boxes get focus.
*वापरकर्ता नाव निवडतो → PIN बॉक्सना फोकस मिळतो.*

- User enters 4 digits → auto-submit on 4th digit.
*वापरकर्ता ४ अंक टाकतो → ४थ्या अंकावर आपोआप सादर.*

- PIN hash is computed via bcrypt and compared to users.pin_hash for selected user.
*PIN हॅश bcrypt द्वारे मोजला जातो आणि निवडलेल्या वापरकर्त्याच्या users.pin_hash शी तुलना केली जाते.*

- On match: update users.last_login_at, create session token (8-hour TTL), navigate to S5 (Home).
*जुळल्यावर: users.last_login_at अद्यतनित करा, सत्र टोकन तयार करा (८-तासांचा TTL), S5 (होम) कडे जा.*

- On mismatch: shake animation on PIN boxes, clear PIN, error toast "Wrong PIN / चुकीचा PIN". After 5 wrong attempts in 60 seconds, lock for 60 seconds with countdown.
*जुळले नाही तर: PIN बॉक्सवर शेक अॅनिमेशन, PIN साफ, त्रुटी टोस्ट "चुकीचा PIN". ६० सेकंदांत ५ चुकीच्या प्रयत्नांनंतर, काउंटडाउनसह ६० सेकंद लॉक.*

- "Forgot PIN" link → shows message: "Contact Sagar (Owner) to reset your PIN. Owner can reset from Settings → Manage Users."
*"PIN विसरलात" दुवा → संदेश दाखवा: "तुमचा PIN रीसेट करण्यासाठी सागर (मालक) यांच्याशी संपर्क साधा. मालक सेटिंग्ज → वापरकर्ता व्यवस्थापन वरून रीसेट करू शकतो."*

### Offline behaviour

*ऑफलाइन वर्तन*

- Works fully offline. PIN check is local against the cached pin_hash from the last sync.
*पूर्णतः ऑफलाइन चालते. PIN तपासणी शेवटच्या समक्रमणातून कॅशे केलेल्या pin_hash शी लोकल.*

### Edge cases

*एज प्रकरणे*

- No active users in DB → show "Setup required" screen routing to S3.
*DB मध्ये सक्रिय वापरकर्ते नाहीत → "सेटअप आवश्यक" स्क्रीन S3 कडे राउटिंगसह दाखवा.*

- User exists but is_active=0 → name does not appear in dropdown.
*वापरकर्ता अस्तित्वात पण is_active=0 → नाव ड्रॉपडाउनमध्ये दिसत नाही.*

**Screen S5 —** **Home / Dashboard**

*स्क्रीन S5 — होम / डॅशबोर्ड*

Purpose: Single launchpad for all user actions. Different sections shown based on role.

हेतू: सर्व वापरकर्ता क्रियांसाठी एकमेव लॉन्चपॅड. भूमिकेनुसार वेगवेगळे विभाग दाखवले जातात.

### Layout (top to bottom)

*मांडणी*

- Top bar: user's name + role badge (left), sync state dot (right), language toggle (far right).
*वरचा बार: वापरकर्त्याचे नाव + भूमिका बॅज (डावीकडे), समक्रमण स्थिती ठिपका (उजवीकडे), भाषा टॉगल (अगदी उजवीकडे).*

- Greeting card: "Good evening, [name]" or appropriate time-of-day greeting.
*अभिवादन कार्ड: "शुभ संध्याकाळ, [नाव]" किंवा वेळेनुसार योग्य अभिवादन.*

- Quick-stat row (3 cards): "Open CAPs assigned to me", "Pending audits", "Latest compliance %" — only those relevant to the user's role.
*जलद-आकडे ओळ (३ कार्ड): "मला नेमलेल्या उघड्या CAPs", "प्रलंबित ऑडिट", "शेवटची अनुपालन %" — फक्त वापरकर्त्याच्या भूमिकेशी संबंधित.*

### Primary action card (large, gold) — varies by role

*प्राथमिक कृती कार्ड (मोठे, सोनेरी) — भूमिकेनुसार बदलते*

- SM: "Start Today's Daily Audit" → S6. If already submitted today, shows "View Today's Audit" → S13.
*SM: "आजची दैनंदिन ऑडिट सुरू करा" → S6. आज आधीच सादर झाली असेल, तर "आजची ऑडिट पाहा" → S13.*

- GM: Saturdays/Mondays: "Start Weekly Audit" (Phase 2) → S-weekly. Other days: "Verify Daily Audits" → audit history filtered to unverified.
*GM: शनि/सोम: "साप्ताहिक ऑडिट सुरू करा" (टप्पा २) → S-weekly. इतर दिवस: "दैनंदिन ऑडिट पडताळा" → ऑडिट इतिहास अपडतडवळलेल्यांना फिल्टर.*

- Owner: Sundays: "Read This Week's Report" → S21. First Sunday of month: "Start Monthly Audit" (Phase 3). Other days: "Trend Dashboard" (Phase 3).
*मालक: रवि: "या आठवड्याचा अहवाल वाचा" → S21. महिन्याचा पहिला रवि: "मासिक ऑडिट सुरू करा" (टप्पा ३). इतर दिवस: "कल डॅशबोर्ड" (टप्पा ३).*

### Bottom navigation tabs (sticky)

*तळ नेव्हिगेशन टॅब (चिकट)*

- Home (this screen).
*होम (हा स्क्रीन).*

- Audits (S12 — audit history).
*ऑडिट (S12 — ऑडिट इतिहास).*

- CAPs (S14 — CAP list).
*CAPs (S14 — CAP यादी).*

- Reference (S22 — reference tab index).
*संदर्भ (S22 — संदर्भ टॅब अनुक्रमणिका).*

- Settings (S27).
*सेटिंग्ज (S27).*

### Data read/write

*डेटा वाचन/लेखन*

- Read: caps WHERE responsible_user_id = me AND status IN ('open','aged'), audits WHERE auditor_id = me ORDER BY submitted_at DESC LIMIT 1
*वाचन: caps WHERE responsible_user_id = me AND status IN ('open','aged'), audits WHERE auditor_id = me ORDER BY submitted_at DESC LIMIT 1*

- Write: none.
*लेखन: काही नाही.*

**Screen S6 —** **Start Daily Audit**

*स्क्रीन S6 — दैनंदिन ऑडिट सुरू करा*

Purpose: Confirm audit date, capture pre-audit info, then proceed to checkpoint screens.

हेतू: ऑडिट तारीख पक्की करा, पूर्व-ऑडिट माहिती कॅप्चर करा, मग तपासणी बिंदू स्क्रीनकडे जा.

### Layout

*मांडणी*

- Audit date field — defaults to today; user can change to past date if backfilling missed audit. Cannot be future date.
*ऑडिट तारीख फील्ड — आज डीफॉल्ट; गहाळ ऑडिट बॅकफिल करत असेल तर वापरकर्ता पूर्वीच्या तारखेला बदलू शकतो. भविष्यातील तारीख नाही.*

- CROs on duty multi-select — choose from active CRO list. At least one must be selected.
*ड्युटीवरील सीआरओ बहु-निवड — सक्रिय सीआरओ यादीतून निवडा. किमान एक निवडले पाहिजे.*

- Optional pre-audit notes — free text, 200 chars max.
*ऐच्छिक पूर्व-ऑडिट नोंदी — मुक्त मजकूर, २०० वर्ण कमाल.*

- Big "Start Audit" button at bottom.
*तळाशी मोठे "ऑडिट सुरू करा" बटण.*

### Behaviour on Start Audit tap

*ऑडिट सुरू करा टॅपवर वर्तन*

- Check if an audit with audit_type='daily' AND audit_date=this date already exists by this auditor. If yes, show dialog: "An audit already exists for this date. Open it?" with View/Cancel buttons.
*या तारखेसाठी audit_type='daily' AND audit_date=ही तारीख असलेली ऑडिट या ऑडिटरकडून आधीच अस्तित्वात आहे का तपासा. हो असेल, तर डायलॉग दाखवा: "या तारखेसाठी ऑडिट आधीच अस्तित्वात आहे. उघडायची?" View/Cancel बटणांसह.*

- If no: INSERT new row into audits with status='draft', draft_started_at=now, all counts=0.
*नसेल तर: status='draft', draft_started_at=now, सर्व counts=0 सह audits मध्ये नवीन ओळ INSERT.*

- Navigate to S7 (Checkpoint Screen).
*S7 (तपासणी बिंदू स्क्रीन) कडे जा.*

### Workbook reference

*पुस्तिका संदर्भ*

- Workbook Day 2, Section 2.10 — Time blocks. The app implements the same block sequence visually in S7.
*पुस्तिका दिवस २, विभाग २.१० — वेळ खंड. अॅप S7 मध्ये त्याच खंड क्रमाची दृश्यपणे अंमलबजावणी करते.*

**Screen S7 —** **Daily Audit — Checkpoint Screen**

*स्क्रीन S7 — दैनंदिन ऑडिट — तपासणी बिंदू स्क्रीन*

Purpose: Walk the SM through all 68 daily checkpoints, one at a time. This is the screen the SM uses most.

हेतू: SM ला सर्व ६८ दैनंदिन तपासणी बिंदूंमधून एका वेळी एक चालवा. SM सर्वात जास्त वापरतो तो हाच स्क्रीन.

### Layout (top to bottom)

*मांडणी*

- Top progress bar — "Checkpoint 12 of 68 / तपासणी बिंदू ६८ पैकी १२".
*वर प्रगती बार — "तपासणी बिंदू ६८ पैकी १२".*

- SOP context — small chip showing current SOP number and name (e.g. "SOP 6 — Cash ★" with critical icon).
*एसओपी संदर्भ — सध्याचा एसओपी क्रमांक आणि नाव दर्शवणारा छोटा चिप (उदा. "SOP 6 — रोख ★" अत्यावश्यक चिन्हासह).*

- Checkpoint number + text (large, readable). E.g. "6.5 — Closing cash variance within ±₹50 (or explained)". Toggle button shows MR translation.
*तपासणी बिंदू क्रमांक + मजकूर (मोठा, वाचनीय). उदा. "6.5 — बंद रोख तफावत ±₹५० च्या आत (किंवा स्पष्टीकरणासह)". टॉगल बटण MR अनुवाद दाखवते.*

- Evidence reminder — small italic text "Evidence: cash register entry + countersignature".
*पुरावा स्मरण — छोटा इटॅलिक मजकूर "पुरावा: रोख रजिस्टर नोंद + काऊंटर सही".*

- Three big buttons: PASS (green), FAIL (red), NA (gray). Single tap selects.
*तीन मोठी बटणे: पास (हिरवा), नापास (लाल), NA (राखाडी). एक टॅप निवडते.*

- If checkpoint.allows_na = 0, the NA button is grayed and tap shows toast "This checkpoint cannot be NA / हा बिंदू NA असू शकत नाही".
*checkpoint.allows_na = 0 असेल, NA बटण राखाडी आणि टॅपवर टोस्ट "हा बिंदू NA असू शकत नाही".*

- Bottom: "Previous" arrow and "Next" arrow. Next is disabled until result is selected.
*तळ: "मागे" बाण आणि "पुढे" बाण. निकाल निवडल्याशिवाय पुढे अक्षम.*

### Behaviour on PASS tap

*पास टॅपवर वर्तन*

- INSERT row in audit_results: result='P', weighted_points=checkpoint.weight.
*audit_results मध्ये ओळ INSERT: result='P', weighted_points=checkpoint.weight.*

- Auto-advance to next checkpoint after 200ms (gives haptic feedback time).
*२०० ms नंतर पुढच्या तपासणी बिंदूला आपोआप पुढे (हॅप्टिक फीडबॅक वेळ देते).*

### Behaviour on FAIL tap

*नापास टॅपवर वर्तन*

- Navigate to S8 (Fail Detail) — does NOT auto-advance. Fail requires a finding text and possibly a photo.
*S8 (नापास तपशील) कडे जा — आपोआप पुढे जात नाही. नापासाला निष्कर्ष मजकूर आणि शक्यतो फोटो लागतो.*

### Behaviour on NA tap

*NA टॅपवर वर्तन*

- Show modal: "Why NA? (one line required) / NA का? (एक ओळ आवश्यक)". On submit, INSERT audit_results with result='NA', weighted_points=NULL, finding_text=NA reason. Auto-advance.
*मोडल दाखवा: "NA का? (एक ओळ आवश्यक)". सादरीकरणावर, audit_results INSERT result='NA', weighted_points=NULL, finding_text=NA कारण. आपोआप पुढे.*

### Save behaviour

*जतन वर्तन*

- Every tap writes immediately to local SQLite. No "save" button needed. If app crashes mid-audit, on next open the SM resumes from where left off (draft is in DB).
*प्रत्येक टॅप लगेच लोकल SQLite वर लिहितो. "जतन" बटण आवश्यक नाही. अॅप मध्येच क्रॅश झाले, तर पुढच्या उघडण्यावर SM जिथे सोडले तिथून सुरू ठेवतो (DB मध्ये ड्राफ्ट).*

### Order of checkpoints

*तपासणी बिंदूंचा क्रम*

- Follow the time-block sequence from Workbook Day 2 Section 2.10: SOP 2 → SOP 4 → SOP 5 → SOP 1 → SOP 6 → SOP 7 → SOP 3 → SOP 8. NOT numeric order. Configurable in checkpoints.display_order field.
*पुस्तिका दिवस २ विभाग २.१० मधल्या वेळ-खंड क्रमाचे पालन करा: SOP 2 → SOP 4 → SOP 5 → SOP 1 → SOP 6 → SOP 7 → SOP 3 → SOP 8. संख्यात्मक क्रम नव्हे. checkpoints.display_order फील्डमध्ये कॉन्फिगर करण्यायोग्य.*

### Workbook reference

*पुस्तिका संदर्भ*

- Workbook Day 2 Section 2.9 (the 8 SOPs) and Section 2.10 (the 9 time blocks).
*पुस्तिका दिवस २ विभाग २.९ (८ एसओपी) आणि विभाग २.१० (९ वेळ खंड).*

**Screen S8 —** **Daily Audit — Fail Detail**

*स्क्रीन S8 — दैनंदिन ऑडिट — नापास तपशील*

Purpose: Capture the finding text and optionally a photo for a Fail. Photo is mandatory if checkpoint.requires_photo_on_fail = 1.

हेतू: निष्कर्ष मजकूर आणि नापासासाठी ऐच्छिक फोटो कॅप्चर करा. checkpoint.requires_photo_on_fail = 1 असेल फोटो अनिवार्य.

### Layout

*मांडणी*

- Checkpoint context at top (same as S7).
*वर तपासणी बिंदू संदर्भ (S7 सारखाच).*

- "Finding (one sentence) / निष्कर्ष (एक वाक्य)" text input — max 200 chars, required.
*"निष्कर्ष (एक वाक्य)" मजकूर इनपुट — कमाल २०० वर्ण, आवश्यक.*

- CRO involved (optional) — dropdown of active CROs.
*समाविष्ट सीआरओ (ऐच्छिक) — सक्रिय सीआरओचा ड्रॉपडाउन.*

- Photo section: if requires_photo_on_fail=1, header is red "Photo required". Else "Photo (optional)". Shows photo thumbnails (up to 5). "+ Add Photo" button opens S9.
*फोटो विभाग: requires_photo_on_fail=1 असेल, हेडर लाल "फोटो आवश्यक". अन्यथा "फोटो (ऐच्छिक)". फोटो थंबनेल दाखवते (कमाल ५). "+ फोटो जोडा" बटण S9 उघडते.*

- "Save and Continue / जतन आणि पुढे" button — disabled until required fields filled.
*"जतन आणि पुढे" बटण — आवश्यक फील्ड भरल्याशिवाय अक्षम.*

### Behaviour on Save

*जतनवर वर्तन*

- INSERT audit_results row: result='F', weighted_points=0, finding_text, cro_id.
*audit_results ओळ INSERT: result='F', weighted_points=0, finding_text, cro_id.*

- INSERT photos rows for each attached photo, linked to this audit_result.
*जोडलेल्या प्रत्येक फोटोसाठी photos ओळी INSERT, या audit_result शी जोडलेल्या.*

- Navigate back to S7 for next checkpoint.
*पुढच्या तपासणी बिंदूसाठी S7 कडे परत.*

- CAP creation is deferred to the Review screen (S10) so SM is not interrupted mid-audit.
*CAP तयार करणे पुनरावलोकन स्क्रीन (S10) पर्यंत पुढे ढकलले जाते जेणेकरून SM ला ऑडिट मध्ये अडथळा नाही.*

### Workbook reference

*पुस्तिका संदर्भ*

- Workbook Day 2 Section 2.11 — "When you find a Fail, write the finding immediately in two sentences". App enforces this with the required field.
*पुस्तिका दिवस २ विभाग २.११ — "नापास सापडले की लगेच दोन वाक्यांत निष्कर्ष लिहा". अॅप आवश्यक फील्डद्वारे याची अंमलबजावणी करते.*

**Screen S9 —** **Daily Audit — Photo Capture**

*स्क्रीन S9 — दैनंदिन ऑडिट — फोटो कॅप्चर*

Purpose: Capture or pick a photo as evidence. Camera-first; gallery is secondary.

हेतू: पुरावा म्हणून फोटो कॅप्चर किंवा निवडा. कॅमेरा-प्रथम; गॅलरी दुय्यम.

### Layout

*मांडणी*

- Camera preview takes most of the screen.
*स्क्रीनचा बहुतेक भाग कॅमेरा प्रीव्ह्यू.*

- Shutter button at bottom center.
*तळ मध्यभागी शटर बटण.*

- Toggle flash icon top-right.
*वर-उजवीकडे फ्लॅश चिन्ह टॉगल.*

- Switch front/back camera icon top-left.
*वर-डावीकडे पुढे/मागे कॅमेरा स्विच चिन्ह.*

- Gallery icon bottom-left — opens device gallery picker.
*तळ-डावीकडे गॅलरी चिन्ह — डिव्हाइस गॅलरी पिकर उघडते.*

- "Cancel" button top-right.
*वर-उजवीकडे "रद्द" बटण.*

### Behaviour

*वर्तन*

- On shutter tap: capture photo, show preview with "Use" and "Retake" buttons.
*शटर टॅपवर: फोटो कॅप्चर, "वापरा" आणि "पुन्हा घ्या" बटणांसह प्रीव्ह्यू दाखवा.*

- On Use: compress to max 1280px long edge, JPEG quality 80%, save to app's documents folder with UUID name. Generate 150px thumbnail. Return to caller screen (S8 or CAP-related).
*वापरावर: कमाल १२८० पिक्सेल लांब बाजू, JPEG गुणवत्ता ८०% पर्यंत संकुचित करा, UUID नावासह अॅपच्या documents फोल्डरमध्ये जतन करा. १५० पिक्सेल थंबनेल तयार करा. कॉलर स्क्रीनकडे (S8 किंवा CAP-संबंधित) परत.*

- EXIF location is read if available and stored in photos.captured_lat/lng.
*उपलब्ध असल्यास EXIF स्थान वाचले जाते आणि photos.captured_lat/lng मध्ये साठवले जाते.*

### Permissions

*परवानग्या*

- On first use, request camera permission. If denied, show fallback: "Camera denied. You can pick from gallery or skip the photo."
*पहिल्या वापरावर, कॅमेरा परवानगी मागा. नकार असेल, फॉलबॅक दाखवा: "कॅमेरा नाकारला. तुम्ही गॅलरीतून निवडू शकता किंवा फोटो वगळू शकता."*

- Storage permission requested only on Android <10. On Android 11+, scoped storage handles it.
*Android <१० वरच स्टोरेज परवानगी मागितली. Android ११+ वर scoped storage हाताळते.*

**Screen S10 —** **Daily Audit — Review & Submit**

*स्क्रीन S10 — दैनंदिन ऑडिट — पुनरावलोकन व सादरीकरण*

Purpose: Show the SM a full preview of the audit, calculate the score, list all Fails for CAP creation, and submit.

हेतू: SM ला ऑडिटचे पूर्ण प्रीव्ह्यू दाखवा, गुण मोजा, CAP तयार करण्यासाठी सर्व नापासांची यादी द्या, आणि सादर करा.

### Layout

*मांडणी*

- Header: "Daily Audit — [date]".
*हेडर: "दैनंदिन ऑडिट — [तारीख]".*

- Score card (large, prominent): compliance percentage, band, raw_score / max_score. Color-coded by band.
*गुण कार्ड (मोठे, ठळक): अनुपालन टक्केवारी, पट्टी, raw_score / max_score. पट्टीनुसार रंग-कोडित.*

- Breakdown by SOP: small table showing each SOP's pass/fail/NA counts and weighted score.
*एसओपीनुसार विभागणी: प्रत्येक एसओपीच्या pass/fail/NA counts आणि वजनी गुण दाखवणारा छोटा तक्ता.*

- Fails list: each Fail with checkpoint number, finding text, photo thumbnails, and a "Create CAP" button (or "CAP Created" badge if already created).
*नापास यादी: प्रत्येक नापास तपासणी बिंदू क्रमांक, निष्कर्ष मजकूर, फोटो थंबनेल, आणि "CAP तयार करा" बटण (किंवा आधीच तयार असेल "CAP तयार" बॅज) सह.*

- Optional notes — free text up to 500 chars.
*ऐच्छिक नोंदी — मुक्त मजकूर ५०० वर्णांपर्यंत.*

- Big "Submit Audit / ऑडिट सादर करा" button at bottom.
*तळाशी मोठे "ऑडिट सादर करा" बटण.*

- "Save Draft / ड्राफ्ट जतन करा" link at bottom.
*तळाशी "ड्राफ्ट जतन करा" दुवा.*

### Behaviour on Submit tap

*सादर करा टॅपवर वर्तन*

- Validate: every Fail with requires_photo_on_fail=1 has at least 1 photo. If not, show modal listing the offending Fails, blocking submission.
*पडताळा: requires_photo_on_fail=1 असलेल्या प्रत्येक नापासाला किमान १ फोटो आहे. नसेल, अपराधी नापासांची यादी देणारा मोडल दाखवा, सादरीकरण ब्लॉक करा.*

- Validate: every Fail must have a CAP either created or skipped explicitly via the "Defer CAP creation" option (default on, but warning shown).
*पडताळा: प्रत्येक नापासाला CAP एकतर तयार आहे किंवा "CAP तयार करणे पुढे ढकला" पर्यायाद्वारे (डीफॉल्ट चालू, पण इशारा) स्पष्टपणे वगळलेला आहे.*

- Compute final scores (Section 6 formulas) and write to audits row.
*अंतिम गुण मोजा (विभाग ६ सूत्रे) आणि audits ओळीवर लिहा.*

- UPDATE audits: status='submitted', submitted_at=now, raw_score, max_score, compliance_pct, band, fail_count, pass_count, na_count.
*audits UPDATE: status='submitted', submitted_at=now, raw_score, max_score, compliance_pct, band, fail_count, pass_count, na_count.*

- Run escalation engine (Section 7) on this audit — auto-create any escalations triggered.
*या ऑडिटवर एस्केलेशन इंजिन चालवा (विभाग ७) — सुरू झालेले कोणतेही एस्केलेशन आपोआप तयार करा.*

- Queue sync to Firestore.
*Firestore ला समक्रमणासाठी रांगेत.*

- Navigate to S11 (Submitted Confirmation).
*S11 (सादरीकरण पुष्टी) कडे जा.*

**Screen S11 —** **Daily Audit — Submitted Confirmation**

*स्क्रीन S11 — दैनंदिन ऑडिट — सादरीकरण पुष्टी*

Purpose: Celebrate the completion, show final score, offer next actions.

हेतू: पूर्णतेचा आनंद, अंतिम गुण, पुढच्या क्रिया.

### Layout

*मांडणी*

- Large checkmark icon at top, animated.
*वर मोठे चेकमार्क चिन्ह, अॅनिमेटेड.*

- "Submitted at [time]".
*"[वेळी] सादर."*

- Final compliance %, band, in color.
*अंतिम अनुपालन %, पट्टी, रंगात.*

- "Sent to GM" status (if synced) or "Will sync when online" (if offline).
*"GM ला पाठवले" स्थिती (समक्रमित असेल) किंवा "ऑनलाइन झाल्यावर समक्रमित होईल" (ऑफलाइन असेल).*

- Three buttons: "View Audit" → S13, "Open CAPs" → S14, "Home" → S5.
*तीन बटणे: "ऑडिट पाहा" → S13, "CAPs उघडा" → S14, "होम" → S5.*

### Behaviour on confirmation

*पुष्टीवर वर्तन*

- If band is FAIR or below, show banner suggesting CAPs to open immediately.
*पट्टी बरे किंवा खाली असेल, लगेच उघडायच्या CAPs सुचवणारा बॅनर दाखवा.*

- If band is POOR or CRITICAL, show banner that an escalation has been auto-created and sent.
*पट्टी वाईट किंवा क्रिटिकल असेल, एस्केलेशन आपोआप तयार आणि पाठवले गेले आहे असा बॅनर दाखवा.*

