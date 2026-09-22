# Saagar Audit App — Phasing Roadmap, Tests, Prompts & Conventions (Spec Sections 12–18)
> **Source**: Saagar_P1_App_Spec_v1.docx (Sections 12–18)  
> **Master**: [rain/SPEC_APP.md](../SPEC_APP.md)  
> **Index**: [rain/spec/INDEX.md](INDEX.md)

---

# Section 12 — Phasing Roadmap — Week by Week

*विभाग १२ — टप्पे — आठवडा-दर-आठवडा*

## Phasing principle

*टप्पा तत्व*

Build one phase at a time. Use the actual app for two weeks at the store between phases. Do not start the next phase until the current phase is signed off using the Definition of Done in Section 16. The point of phasing is to find what does not work in real use BEFORE adding more features on top.

एका वेळी एक टप्पा बांधा. टप्प्यांमध्ये स्टोअरमध्ये दोन आठवडे प्रत्यक्ष अॅप वापरा. विभाग १६ मधल्या Definition of Done वापरून सध्याचा टप्पा साइन-ऑफ होईपर्यंत पुढचा टप्पा सुरू करू नका. टप्प्यांचा मुद्दा हाच — अधिक फीचर्स वर जोडण्यापूर्वी प्रत्यक्ष वापरात काय काम करत नाही ते शोधणे.

## Phase 1 — Daily Audit Foundation (Weeks 1–4)

*टप्पा १ — दैनंदिन ऑडिट पाया (आठवडे १–४)*

### Goal

*ध्येय*

Store Manager can log in, run a complete daily audit, capture photos for Cash/Inventory Fails, create CAPs from Fails, view audit history, and send the audit PDF to GM via WhatsApp. GM and Owner can log in but mostly read-only at this phase.

स्टोअर मॅनेजर लॉग इन करू शकतो, संपूर्ण दैनंदिन ऑडिट चालवू शकतो, रोख/स्टॉक नापासांसाठी फोटो काढू शकतो, नापासांपासून CAP तयार करू शकतो, ऑडिट इतिहास पाहू शकतो, आणि WhatsApp द्वारे GM ला ऑडिट PDF पाठवू शकतो. GM आणि मालक लॉग इन करू शकतात पण या टप्प्यावर बहुतेक फक्त-वाचन.

### Week-by-week deliverables

*आठवडा-दर-आठवडा वितरण*


| Week | Deliverable \| वितरण |
| --- | --- |
| 1 | Project setup. Flutter scaffolding. SQLite schema. Firebase project created. assets/seed/*.json loaded. Screens S1, S2, S3, S4 (Splash, Language, First-Time Setup, Login). |
| 2 | Screens S5 (Home), S6 (Start Audit), S7 (Checkpoint), S8 (Fail Detail), S9 (Photo Capture). Score logic Section 6.1–6.4. Daily audit can be conducted end-to-end but no submit yet. |
| 3 | Screens S10 (Review & Submit), S11 (Confirmation), S12 (History), S13 (Audit Detail). PDF export. WhatsApp share. Auto-sync to Firestore. Photo upload to Firebase Storage. |
| 4 | Screens S14 (CAP List), S15 (CAP Create), S16 (CAP Detail), S17 (Mark Done). Screens S22-S26 (Reference tab). Screens S27-S32 (Settings). Phase 1 polish. |


### Phase 1 acceptance criteria

*टप्पा १ स्वीकृती निकष*

- SM can complete a full daily audit in under 45 minutes on a phone.
*SM फोनवर ४५ मिनिटांच्या आत पूर्ण दैनंदिन ऑडिट करू शकतो.*

- Score matches Workbook Day 5 Section 5.1 test case exactly (81/90 = 90.0% Good).
*गुण पुस्तिका दिवस ५ विभाग ५.१ चाचणी प्रकरणाशी अचूक जुळते (८१/९० = ९०.०% चांगले).*

- Photo capture works in low light (test at counter after 8 PM).
*कमी प्रकाशात फोटो कॅप्चर चालते (८ PM नंतर काउंटरवर चाचणी).*

- Offline mode works for 24 hours straight without sync.
*समक्रमणाशिवाय २४ तास सलग ऑफलाइन मोड चालतो.*

- PDF export opens in WhatsApp and shares to a contact.
*PDF निर्यात WhatsApp मध्ये उघडते आणि संपर्काकडे शेअर होते.*

- Both EN and MR work on every screen.
*प्रत्येक स्क्रीनवर EN आणि MR दोघे चालतात.*

- Used at the actual store for at least 10 closings without major bugs.
*मोठ्या बग्सशिवाय किमान १० बंदोबस्तांसाठी प्रत्यक्ष स्टोअरमध्ये वापरला जातो.*

## Phase 2 — Weekly Audit (Weeks 5–8)

*टप्पा २ — साप्ताहिक ऑडिट (आठवडे ५–८)*

### Goal

*ध्येय*

GM can run a full weekly audit. 7-day daily review with spot checks. 36 weekly-only checkpoints. Weekly report generation matching Workbook Day 3 Section 3.6 format. CAP verification flow.

GM संपूर्ण साप्ताहिक ऑडिट चालवू शकते. स्पॉट चेकसह ७-दिवस दैनंदिन पुनरावलोकन. ३६ साप्ताहिक-केवळ तपासणी बिंदू. पुस्तिका दिवस ३ विभाग ३.६ स्वरूपाशी जुळणारी साप्ताहिक अहवाल तयार करणे. CAP पडताळणी प्रवाह.


| Week | Deliverable \| वितरण |
| --- | --- |
| 5 | Weekly audit data model finalized. assets/seed/checkpoints.json updated with 36 weekly-only. Weekly audit screens (analogue to S6-S10 but weekly). |
| 6 | 7-day daily review screen — GM sees 7 daily audits as cards, opens each for spot check. Spot check validation against original photos/registers. GM signature. |
| 7 | Weekly score formula (Section 6.5–6.7). Weekly report generation (S20, S21). Daily-audit-average contribution math. Cumulative cash variance check (CW.7). |
| 8 | CAP verification (S18) and close (S19). GM dashboard with pending verifications. Phase 2 polish. |


### Phase 2 acceptance criteria

*टप्पा २ स्वीकृती निकष*

- GM can complete a weekly audit in 2–3 hours.
*GM २–३ तासांत साप्ताहिक ऑडिट पूर्ण करू शकते.*

- Weekly score matches Workbook Day 5 Section 5.2 test exactly (104.8/124 = 84.5% Poor).
*साप्ताहिक गुण पुस्तिका दिवस ५ विभाग ५.२ चाचणीशी अचूक जुळते (१०४.८/१२४ = ८४.५% वाईट).*

- Weekly report PDF is 1 page and follows the 9-section format from Workbook 3.6.
*साप्ताहिक अहवाल PDF १ पान आणि पुस्तिका ३.६ मधल्या ९-विभाग स्वरूपाचे पालन करतो.*

- Spot check workflow works — GM can mark verified or flag discrepancy.
*स्पॉट चेक प्रवाह चालतो — GM पडताळलेले म्हणून खूण करू शकते किंवा विसंगती झेंडा.*

- Used for at least 3 weekly audits with no major bugs.
*मोठ्या बग्सशिवाय किमान ३ साप्ताहिक ऑडिटसाठी वापरला.*

## Phase 3 — Monthly + Escalation + Trends (Weeks 9–11)

*टप्पा ३ — मासिक + एस्केलेशन + कल (आठवडे ९–११)*

### Goal

*ध्येय*

Owner can run a monthly audit. Escalation engine (Section 7) fully active. Trend analytics dashboard for Owner. Notifications (in-app + WhatsApp) live.

मालक मासिक ऑडिट चालवू शकतो. एस्केलेशन इंजिन (विभाग ७) पूर्णतः सक्रिय. मालकासाठी कल विश्लेषण डॅशबोर्ड. सूचना (अॅप-अंतर्गत + WhatsApp) जिवंत.


| Week | Deliverable \| वितरण |
| --- | --- |
| 9 | Monthly audit checkpoints added to seed JSON. Monthly audit screens (analogue to weekly). escalations table populated. |
| 10 | Escalation engine — all 7 triggers from Section 7. WhatsApp deep links. In-app notifications via flutter_local_notifications. |
| 11 | Trend analytics: 4-week rolling per-SOP graph, day-of-week heatmap (Pattern 3 detection), 12-week compliance trend chart. fl_chart integration. |


### Phase 3 acceptance criteria

*टप्पा ३ स्वीकृती निकष*

- All 7 escalation triggers fire correctly in the simulated audit scenarios.
*अनुकरण ऑडिट परिस्थितींमध्ये सर्व ७ एस्केलेशन ट्रिगर योग्यरीत्या सुरू होतात.*

- WhatsApp deep link opens with correct pre-filled message.
*WhatsApp डीप लिंक योग्य पूर्व-भरलेल्या संदेशासह उघडते.*

- Notifications appear in Android tray with sound for Critical triggers.
*क्रिटिकल ट्रिगरसाठी आवाजासह Android ट्रेमध्ये सूचना दिसतात.*

- Trend dashboard loads in under 2 seconds for 12 weeks of data.
*१२ आठवड्यांच्या डेटासाठी कल डॅशबोर्ड २ सेकंदांच्या आत लोड.*

- Day-of-week clustering pattern detected and shown when present.
*उपस्थित असेल आठवड्याच्या-दिवसाचा गठ्ठा पॅटर्न ओळखला आणि दाखवला.*

## Phase 4 — Polish, Test, Release (Weeks 12–13)

*टप्पा ४ — पॉलिश, चाचणी, रिलीज (आठवडे १२–१३)*

### Goal

*ध्येय*

Bug fixes from 8 weeks of real-store use. Performance pass. Accessibility pass. Play Store-ready APK with proper signing. 5-minute training video.

८ आठवड्यांच्या प्रत्यक्ष-स्टोअर वापरातील बग्स दुरुस्त. कामगिरी पास. प्रवेशयोग्यता पास. योग्य सहीसह Play Store-तयार APK. ५-मिनिटांचा प्रशिक्षण व्हिडिओ.


| Week | Deliverable \| वितरण |
| --- | --- |
| 12 | Bug triage from a list maintained across phases. Performance pass (audit screen must respond in <100ms per tap). Test on 3 different Android phones (low-end, mid-range, recent). Accessibility check (TalkBack labels, contrast). |
| 13 | Production APK build with signing key (kept in Sagar's secure vault). Optional: Play Store internal track upload. 5-min training video showing SM evening flow. Documentation: README, ops runbook, this Spec attached. |


### Phase 4 acceptance criteria

*टप्पा ४ स्वीकृती निकष*

- All bugs from open bug list resolved or explicitly deferred to v2.
*उघड्या बग यादीतले सर्व बग्स सोडवले किंवा स्पष्टपणे v२ कडे पुढे ढकलले.*

- APK installs cleanly on a fresh Android phone.
*APK ताज्या Android फोनवर स्वच्छपणे इन्स्टॉल होते.*

- Sagar's keystore backed up in 2 locations (separate from the dev machine).
*सागरचा keystore २ ठिकाणी बॅकअप (डेव्ह मशीनपासून वेगळा).*

- Training video covers the SM daily evening flow end-to-end.
*प्रशिक्षण व्हिडिओ SM दैनंदिन संध्याकाळचा प्रवाह सुरू-शेवटी कव्हर करतो.*

## 12.1 — What is explicitly OUT of scope for v1

*१२.१ — v१ साठी स्पष्टपणे व्याप्तीबाहेर*

These features are not part of v1. Anyone (including Claude Code) who suggests adding them mid-build should be politely refused and told to add them to a v2 wishlist file (docs/v2-wishlist.md). The point of phasing is to ship a complete v1; expanding scope mid-build is how 6-month projects become 18-month projects.

ही फीचर्स v१ चा भाग नाहीत. बांधणीदरम्यान कोणीही (क्लॉड कोडसह) ती जोडण्याचे सुचवले — सौजन्याने नकार द्या आणि v२ wishlist फाइलमध्ये (docs/v2-wishlist.md) जोडायला सांगा. टप्प्यांचा मुद्दा हाच — पूर्ण v१ शिप करणे; बांधणीदरम्यान व्याप्ती वाढवल्याने ६-महिन्यांचे प्रकल्प १८-महिन्यांचे होतात.

- iOS / iPhone build. Android-only for v1.
*iOS / iPhone बिल्ड. v१ साठी फक्त-Android.*

- Multi-store support. v1 is single combo store (WLMHW + HEMW share).
*बहु-स्टोअर समर्थन. v१ एकल कॉम्बो स्टोअर (WLMHW + HEMW शेअर).*

- Tablet-optimised layouts. Phone-first; tablet works but unoptimized.
*टॅबलेट-अनुकूल मांडणी. फोन-प्रथम; टॅबलेट चालते पण अनुकूल नाही.*

- Push notifications via Firebase Cloud Messaging. Local-only for v1.
*Firebase Cloud Messaging द्वारे पुश सूचना. v१ साठी फक्त-लोकल.*

- CSV import of historic audits.
*ऐतिहासिक ऑडिटची CSV आयात.*

- Custom checkpoint creation in-app (only seed JSON in v1).
*अॅप-अंतर्गत कस्टम तपासणी बिंदू तयार करणे (v१ मध्ये फक्त सीड JSON).*

- Integration with Titan corporate systems or POS.
*टायटन कॉर्पोरेट सिस्टम किंवा POS शी एकीकरण.*

- Voice-to-text for finding entry.
*निष्कर्ष नोंदीसाठी आवाज-ते-मजकूर.*

- AI-suggested root causes or CAPs.
*AI-सुचवलेली मूळ कारणे किंवा CAPs.*

# Section 13 — Test Scenarios

*विभाग १३ — चाचणी परिस्थिती*

## How to use these tests

*या चाचण्या कशा वापरायच्या*

Each test scenario below is a reproducible script. Run it after every meaningful code change. If any test fails, the change is broken — roll back via Git, fix, and try again. Tests are organized by phase. Phase 1 tests must all pass before Phase 2 begins; Phase 2 tests must include all Phase 1 tests still passing.

खाली प्रत्येक चाचणी परिस्थिती पुनरुत्पादक स्क्रिप्ट. प्रत्येक अर्थपूर्ण कोड बदलानंतर चालवा. कोणतीही चाचणी अयशस्वी झाली, बदल मोडला आहे — Git द्वारे मागे फिरा, दुरुस्ती करा, पुन्हा प्रयत्न करा. चाचण्या टप्प्यानुसार संघटित. टप्पा १ चाचण्या सर्व टप्पा २ सुरू होण्यापूर्वी पास झाल्या पाहिजेत; टप्पा २ चाचण्यांमध्ये सर्व टप्पा १ चाचण्या अजूनही पास होणे समाविष्ट.

## Phase 1 — Test Scenarios

*टप्पा १ — चाचणी परिस्थिती*

### T1.1 — First-time setup

*T१.१ — पहिल्यांदा सेटअप*

- Uninstall app. Reinstall. Launch.
*अॅप अनइन्स्टॉल करा. पुन्हा इन्स्टॉल करा. लॉन्च करा.*

- Expect: Splash → Language Selection → First-Time Setup → Owner creation form.
*अपेक्षित: स्प्लॅश → भाषा निवड → पहिल्यांदा सेटअप → मालक तयार करण्याचा फॉर्म.*

- Create Owner "Sagar" with PIN 1234. Expect navigation to Home.
*PIN १२३४ सह मालक "सागर" तयार करा. होमकडे जाणे अपेक्षित.*

- From Settings → Manage Users, create GM and SM. From Manage CROs, add 4 CROs.
*सेटिंग्ज → वापरकर्ता व्यवस्थापन मधून GM आणि SM तयार करा. सीआरओ व्यवस्थापन मधून ४ सीआरओ जोडा.*

- Expect: 3 users in DB (Owner, GM, SM), 4 CROs.
*अपेक्षित: DB मध्ये ३ वापरकर्ते (मालक, GM, SM), ४ सीआरओ.*

### T1.2 — Daily audit reproduces Workbook Day 5 Section 5.1

*T१.२ — दैनंदिन ऑडिट पुस्तिका दिवस ५ विभाग ५.१ पुनरुत्पादन*

- Log in as SM. Tap "Start Today's Daily Audit".
*SM म्हणून लॉग इन. "आजची दैनंदिन ऑडिट सुरू करा" टॅप.*

- Enter the 12 observations from Workbook Day 5 Section 5.1:
*पुस्तिका दिवस ५ विभाग ५.१ मधली १२ निरीक्षणे टाका:*

- F1 (1.4) → Fail, finding "Morning CRO Rohan without hand gloves at 11:20 AM"
*F१ (१.४) → नापास, निष्कर्ष "सकाळी ११:२० ला सीआरओ रोहन हात मोजे शिवाय"*

- F2 (2.1, 2.2) → Pass + Pass
*F२ (२.१, २.२) → पास + पास*

- F3 (3.x) → Fail
*F३ (३.x) → नापास*

- F4 (4.x) → Pass with note
*F४ (४.x) → शेरा-असलेला-पास*

- F5 (5.x) → Fail
*F५ (५.x) → नापास*

- F6 (6.5) → Pass (with note: ₹60 over, explanation)
*F६ (६.५) → पास (शेरा: ₹६० जास्त, स्पष्टीकरण)*

- F7 (6.11) → Fail (with photo)
*F७ (६.११) → नापास (फोटोसह)*

- F8 (6.9) → Fail (with photo)
*F८ (६.९) → नापास (फोटोसह)*

- F9 (7.1) → Pass
*F९ (७.१) → पास*

- F10 (7.3) → Pass
*F१० (७.३) → पास*

- F11 (7.8) → Fail (with photo)
*F११ (७.८) → नापास (फोटोसह)*

- F12 (8.x) → Pass
*F१२ (८.x) → पास*

- Mark remaining 56 checkpoints as Pass.
*उरलेले ५६ तपासणी बिंदू पास म्हणून खूण करा.*

- Tap Submit.
*सादर टॅप करा.*

- EXPECTED: compliance_pct = 90.0, band = 'good'. EXACT MATCH. If the app shows anything other than 90.0% Good, the score engine has a bug.
*अपेक्षित: compliance_pct = ९०.०, band = 'good'. अचूक जुळणी. अॅप ९०.०% चांगले व्यतिरिक्त काही दाखवत असेल, गुण इंजिनला बग आहे.*

### T1.3 — Critical SOP Fail forces photo

*T१.३ — क्रिटिकल एसओपी नापास फोटो सक्ती*

- Start a new daily audit.
*नवीन दैनंदिन ऑडिट सुरू करा.*

- Mark checkpoint 6.5 (Cash variance) as Fail. Skip the photo attachment. Try to Submit.
*तपासणी बिंदू ६.५ (रोख तफावत) नापास म्हणून खूण. फोटो जोडणी वगळा. सादर करण्याचा प्रयत्न करा.*

- EXPECTED: Submit blocked. Error message: "Photo required for Cash/Inventory Fails. Add photo to checkpoint 6.5."
*अपेक्षित: सादरीकरण ब्लॉक. त्रुटी संदेश: "रोख/स्टॉक नापासांना फोटो आवश्यक. तपासणी बिंदू ६.५ ला फोटो जोडा."*

### T1.4 — NA handling

*T१.४ — NA हाताळणी*

- Start a daily audit on a Sunday (closed-store scenario).
*रविवारी दैनंदिन ऑडिट सुरू करा (बंद-स्टोअर परिस्थिती).*

- Mark 5 checkpoints as NA, each with a one-line reason.
*५ तपासणी बिंदू NA म्हणून खूण, प्रत्येकाला एका-ओळीचे कारण.*

- Mark the remaining 63 as Pass.
*उरलेले ६३ पास म्हणून खूण.*

- Submit.
*सादर करा.*

- EXPECTED: max_score = 90 minus weights of the 5 NAs. compliance_pct calculated from new max_score, not 90. If NA weights sum to 10, max=80, compliance=63 weighted passes / 80 × 100.
*अपेक्षित: max_score = ९० वजा ५ NAs ची वजने. compliance_pct नवीन max_score वरून मोजली, ९० वरून नव्हे. NA वजने १० बेरीज असतील, max=८०, अनुपालन=६३ वजनी पास / ८० × १००.*

### T1.5 — Offline operation for 24 hours

*T१.५ — २४ तास ऑफलाइन कार्य*

- Enable airplane mode.
*विमान मोड सक्षम करा.*

- Conduct 2 complete daily audits across 2 days, with photos, with CAPs.
*२ दिवसांत २ संपूर्ण दैनंदिन ऑडिट करा, फोटो आणि CAP सह.*

- Verify all data is saved locally.
*सर्व डेटा लोकल जतन झाला याची पडताळणी करा.*

- Disable airplane mode.
*विमान मोड अक्षम करा.*

- EXPECTED: Sync state goes amber → green within 60 seconds. All audits, photos, CAPs appear in Firestore. Sync indicator shows green.
*अपेक्षित: समक्रमण स्थिती ६० सेकंदांत पिवळी → हिरवी. सर्व ऑडिट, फोटो, CAP Firestore मध्ये दिसतात. समक्रमण सूचक हिरवा.*

### T1.6 — PIN lockout

*T१.६ — PIN लॉकआउट*

- Enter wrong PIN 5 times within 60 seconds.
*६० सेकंदांत ५ वेळा चुकीचा PIN टाका.*

- EXPECTED: 60-second lockout with countdown. Cannot try again until countdown ends.
*अपेक्षित: काउंटडाउनसह ६०-सेकंद लॉकआउट. काउंटडाउन संपेपर्यंत पुन्हा प्रयत्न करता येत नाही.*

### T1.7 — Language toggle persists

*T१.७ — भाषा टॉगल टिकते*

- Log in as SM with EN. Go to Settings → Language. Switch to MR. App restarts.
*EN सह SM म्हणून लॉग इन. सेटिंग्ज → भाषा. MR वर स्विच. अॅप पुन्हा सुरू.*

- EXPECTED: All screens now in Marathi. Marathi persists across app close+reopen and across logout+login.
*अपेक्षित: सर्व स्क्रीन आता मराठीत. अॅप बंद+पुन्हा उघडा आणि लॉगआउट+लॉगिन मध्ये मराठी टिकते.*

## Phase 2 — Test Scenarios (in addition to all Phase 1)

*टप्पा २ — चाचणी परिस्थिती (सर्व टप्पा १ व्यतिरिक्त)*

### T2.1 — Weekly audit reproduces Workbook Day 5 Section 5.2

*T२.१ — साप्ताहिक ऑडिट पुस्तिका दिवस ५ विभाग ५.२ पुनरुत्पादन*

- Seed 7 daily audits with compliance percentages: 92.2, 91.1, 90.0, 88.8, 93.3, 89.7, 91.4.
*७ दैनंदिन ऑडिट सीड करा अनुपालन टक्केवारीसह: ९२.२, ९१.१, ९०.०, ८८.८, ९३.३, ८९.७, ९१.४.*

- Log in as GM. Start weekly audit.
*GM म्हणून लॉग इन. साप्ताहिक ऑडिट सुरू करा.*

- Enter weekly-only checkpoint results matching Workbook 5.2: Operations 7/10, Cash 10/16, R&S 4/6, Inventory 22/24.
*पुस्तिका ५.२ शी जुळणारे साप्ताहिक-केवळ तपासणी बिंदू निकाल टाका: ऑपरेशन्स ७/१०, रोख १०/१६, R&S ४/६, स्टॉक २२/२४.*

- Submit weekly audit.
*साप्ताहिक ऑडिट सादर.*

- EXPECTED: total_raw = 104.8, total_max = 124, compliance_pct = 84.5, band = 'poor'. EXACT MATCH.
*अपेक्षित: total_raw = १०४.८, total_max = १२४, compliance_pct = ८४.५, band = 'poor'. अचूक जुळणी.*

### T2.2 — Missing daily counts as 0%

*T२.२ — गहाळ दैनंदिन ०% म्हणून मोजला*

- Seed 6 daily audits with 90% average; skip day 3 (no audit row for that date).
*९०% सरासरीसह ६ दैनंदिन ऑडिट सीड; दिवस ३ वगळा (त्या तारखेसाठी ऑडिट ओळ नाही).*

- Run weekly audit.
*साप्ताहिक ऑडिट चालवा.*

- EXPECTED: daily-average treats day 3 as 0%, not as missing. Average = (90 × 6 + 0) / 7 = 77.1%. Contribution = 77.1 × 0.68 = 52.4.
*अपेक्षित: दैनंदिन-सरासरी दिवस ३ ला ०% म्हणून मानते, गहाळ नव्हे. सरासरी = (९० × ६ + ०) / ७ = ७७.१%. योगदान = ७७.१ × ०.६८ = ५२.४.*

### T2.3 — Spot check workflow

*T२.३ — स्पॉट चेक प्रवाह*

- GM opens weekly audit, taps Day 3.
*GM साप्ताहिक ऑडिट उघडते, दिवस ३ टॅप करते.*

- App shows 3 randomly-selected checkpoints from day 3 for spot check.
*स्पॉट चेकसाठी अॅप दिवस ३ मधून ३ यादृच्छिक-निवडलेले तपासणी बिंदू दाखवते.*

- GM marks all 3 as Verified.
*GM तिघांना पडताळलेले म्हणून खूण.*

- EXPECTED: Day 3 daily audit now shows GM-verified status. GM signature recorded.
*अपेक्षित: दिवस ३ दैनंदिन ऑडिट आता GM-पडताळलेले स्थिती. GM सही नोंदवली.*

### T2.4 — Pattern detection (same checkpoint 3+ days)

*T२.४ — पॅटर्न शोध (एकच तपासणी बिंदू ३+ दिवस)*

- Seed 5 daily audits where checkpoint 1.4 (hand gloves) fails on days 1, 2, 3.
*५ दैनंदिन ऑडिट सीड जिथे तपासणी बिंदू १.४ (हात मोजे) दिवस १, २, ३ नापास.*

- Run weekly audit.
*साप्ताहिक ऑडिट चालवा.*

- EXPECTED: Pattern section of weekly report includes: "Checkpoint 1.4 failed on 3 days (Mon, Tue, Wed) — pattern". A single Pattern CAP is auto-suggested, not three separate CAPs.
*अपेक्षित: साप्ताहिक अहवालाच्या पॅटर्न विभागात समावेश: "तपासणी बिंदू १.४ ३ दिवस नापास (सोम, मंगळ, बुध) — पॅटर्न". तीन वेगळ्या CAP नव्हे, एक पॅटर्न CAP आपोआप सुचवली.*

## Phase 3 — Test Scenarios

*टप्पा ३ — चाचणी परिस्थिती*

### T3.1 — Trigger 1 fires on Critical daily

*T३.१ — क्रिटिकल दैनंदिनवर ट्रिगर १ सुरू*

- As SM, submit a daily audit with compliance 78% (Critical band), with at least one Cash Fail.
*SM म्हणून, क्रिटिकल पट्टी ७८% अनुपालनासह दैनंदिन ऑडिट सादर, किमान एक रोख नापास.*

- EXPECTED:
*अपेक्षित:*

- escalations row created with trigger_number=1, raised_to=GM.
*escalations ओळ तयार trigger_number=१, raised_to=GM.*

- Second escalations row created with trigger_number=1, raised_to=Owner (because Cash cause).
*trigger_number=१, raised_to=मालक सह दुसरी escalations ओळ तयार (रोख कारण).*

- In-app notification visible to GM and Owner.
*GM आणि मालकाला अॅप-अंतर्गत सूचना दिसते.*

- WhatsApp opens with pre-filled escalation message.
*पूर्व-भरलेल्या एस्केलेशन संदेशासह WhatsApp उघडते.*

### T3.2 — Trigger 7 fires after 3 declining weeks

*T३.२ — ३ घसरत्या आठवड्यांनंतर ट्रिगर ७ सुरू*

- Seed 4 weekly audits with compliance: 93.4, 92.1, 91.5, 90.8.
*अनुपालनासह ४ साप्ताहिक ऑडिट सीड: ९३.४, ९२.१, ९१.५, ९०.८.*

- Submit the 4th weekly audit.
*४थी साप्ताहिक ऑडिट सादर.*

- EXPECTED: Trigger 7 fires (3 consecutive decreases). escalations row → Owner. In-app notification.
*अपेक्षित: ट्रिगर ७ सुरू (सलग ३ घसरण). escalations ओळ → मालक. अॅप-अंतर्गत सूचना.*

### T3.3 — CAP aging at midnight

*T३.३ — मध्यरात्री CAP जुनी होणे*

- Create a CAP with deadline = yesterday. Mark status=open.
*मुदत = काल असलेली CAP तयार करा. status=open खूण.*

- Manually run the aging job (in dev, exposed via Settings → Diagnostics).
*जुने होणे काम हाताने चालवा (डेव्हमध्ये, सेटिंग्ज → Diagnostics द्वारे उघड).*

- EXPECTED: CAP status → aged. aged_count incremented. Escalation row created targeting next tier up.
*अपेक्षित: CAP status → aged. aged_count वाढले. पुढच्या स्तर वरच्या लक्ष्यासह एस्केलेशन ओळ तयार.*

### T3.4 — Trend dashboard

*T३.४ — कल डॅशबोर्ड*

- Seed 12 weeks of weekly audits with varied compliance percentages.
*विविध अनुपालन टक्केवारीसह १२ आठवड्यांच्या साप्ताहिक ऑडिट सीड.*

- Owner opens trend dashboard.
*मालक कल डॅशबोर्ड उघडतो.*

- EXPECTED: 12-week line chart loads in <2 seconds. Per-SOP rolling 4-week average shown. Day-of-week heatmap rendered if data sufficient.
*अपेक्षित: १२-आठवडी रेषा चार्ट <२ सेकंदांत लोड. प्रति-एसओपी रोलिंग ४-आठवडी सरासरी दाखवली. डेटा पुरेसा असेल आठवड्याचा-दिवस हीटमॅप रेंडर.*

## 13.1 — Test execution policy

*१३.१ — चाचणी अंमलबजावणी धोरण*

- Run ALL Phase 1 tests before declaring Phase 1 done.
*टप्पा १ झाला घोषित करण्यापूर्वी सर्व टप्पा १ चाचण्या चालवा.*

- Run ALL Phase 1 + Phase 2 tests before declaring Phase 2 done. Regression check.
*टप्पा २ झाला घोषित करण्यापूर्वी सर्व टप्पा १ + टप्पा २ चाचण्या चालवा. Regression तपासणी.*

- Run ALL Phase 1 + 2 + 3 tests before Phase 4. By then there are 15+ test scenarios.
*टप्पा ४ पूर्वी सर्व टप्पा १ + २ + ३ चाचण्या चालवा. तोपर्यंत १५+ चाचणी परिस्थिती.*

- If any test fails, do not proceed to a new feature. Fix the regression first.
*कोणतीही चाचणी अयशस्वी, नवीन फीचरवर जाऊ नका. आधी regression दुरुस्त.*

- Document each test pass/fail in docs/test-log.md with date and tester.
*प्रत्येक चाचणी pass/fail docs/test-log.md मध्ये दिनांक आणि चाचणी घेणाऱ्यासह कागदपत्र.*

# Section 14 — The Master Claude Code Prompt

*विभाग १४ — मास्टर क्लॉड कोड प्रॉम्प्ट*

## How this section works

*हा विभाग कसा चालतो*

This section contains five prompts. The Session-Start Prompt is pasted at the start of EVERY Claude Code session — it sets the ground rules and tells Claude Code which documents to read first. The four Phase Prompts are pasted at the start of each phase to focus Claude Code on that phase's deliverables. Use them in order. Do not skip the Session-Start Prompt — it is what prevents Claude Code from wandering off-spec.

या विभागात पाच प्रॉम्प्ट आहेत. सत्र-सुरुवात प्रॉम्प्ट प्रत्येक क्लॉड कोड सत्राच्या सुरुवातीला पेस्ट केला जातो — तो जमिनीचे नियम सेट करतो आणि क्लॉड कोडला कोणते दस्तऐवज आधी वाचायचे ते सांगतो. चार टप्पा प्रॉम्प्ट प्रत्येक टप्प्याच्या सुरुवातीला पेस्ट केले जातात — त्या टप्प्याच्या वितरणावर क्लॉड कोडचे लक्ष केंद्रित करण्यासाठी. क्रमाने वापरा. सत्र-सुरुवात प्रॉम्प्ट वगळू नका — तेच क्लॉड कोडला तपशीलातून भटकू देत नाही.


| WARNING \| सूचना<br>Paste these prompts EXACTLY as written. Do not paraphrase. The wording — including the harsh "do not" lines — is calibrated to give Claude Code the right boundaries. Soft prompts produce soft code; precise prompts produce precise code.<br>हे प्रॉम्प्ट जसेच्या तसे पेस्ट करा. परिस्करण करू नका. शब्दरचना — कठोर "करू नका" ओळींसह — क्लॉड कोडला योग्य मर्यादा देण्यासाठी कॅलिब्रेट केलेली आहे. मऊ प्रॉम्प्ट मऊ कोड तयार करतात; अचूक प्रॉम्प्ट अचूक कोड तयार करतात. |
| --- |


## 14.1 — Session-Start Prompt (every session)

*१४.१ — सत्र-सुरुवात प्रॉम्प्ट (प्रत्येक सत्र)*

Paste this at the start of every Claude Code session, after uploading the two files. Wait for Claude Code to confirm it has read both before issuing any other instructions.

दोन फाइल अपलोड केल्यानंतर प्रत्येक क्लॉड कोड सत्राच्या सुरुवातीला हा पेस्ट करा. इतर कोणत्याही सूचना देण्यापूर्वी क्लॉड कोडने दोन्ही वाचले याची पुष्टी मिळेपर्यंत वाट पाहा.

### Prompt text — copy below verbatim

*प्रॉम्प्ट मजकूर — खालचा जसाच्या तसा कॉपी करा*

You are building the Saagar Traders Priority 1 SOP Audit mobile

application. I have uploaded two files:

1. Saagar_P1_Audit_Workbook_v1.docx — the operational truth.

This defines WHAT the audit programme is.

2. Saagar_P1_App_Spec_v1.docx — the build manual.

This defines HOW the app implements the Workbook.

BEFORE you write any code or answer any question:

STEP 1: Read the Specification document fully. It is the primary

source for everything you build.

STEP 2: Open the Workbook and confirm you can find Day 2 Section

2.9 (the 8 SOPs), Day 3 Section 3.4 (weekly checkpoints),

Day 4 Section 4.6 (escalation triggers), and Appendices A.1

through A.7. You will reference these specific sections from

inside your code's comments and from the Spec.

STEP 3: Tell me which Phase we are working on today (1, 2, 3,

or 4). Do not assume. If I have not told you, ask.

HARD RULES — these apply in every session, never overridden:

R1. The Workbook is the ground truth. If anything I say or

anything in the Spec contradicts the Workbook, stop and

flag it. Do not silently choose one over the other.

R2. The tech stack is LOCKED to what the Spec Section 2

specifies. Specifically: Flutter, Dart, sqflite (NOT drift

or isar), Firebase Firestore + Storage, custom PIN auth

(NOT Firebase Auth), Riverpod (NOT Provider or Bloc),

go_router (NOT auto_route). Do NOT suggest alternatives.

Do NOT silently swap libraries. Do NOT use deprecated APIs.

If you believe an alternative is genuinely necessary,

STOP and ask me. Do not implement first and explain later.

R3. Every user-facing string MUST exist in both app_en.arb

and app_mr.arb at the moment the string is added. Never

hardcode user-visible text. If you do not know the

Marathi translation, STOP and ask. Do not guess.

R4. Every score calculation must match the formulas in Spec

Section 6 EXACTLY. The two canonical test cases are

Workbook Day 5 Section 5.1 (must produce 90.0% Good)

and Day 5 Section 5.2 (must produce 84.5% Poor).

If your code produces any other answer, the code is wrong.

R5. Audit immutability — once status='submitted', the audits

row and its audit_results rows MUST NOT be UPDATEd or

DELETEd by any code path other than Owner-only "hide"

(which sets status='hidden' but leaves all fields

intact). Enforce this in the data access layer with

a guard.

R6. PINs are never stored, logged, or printed in plaintext.

bcrypt hash only. Never log to console, crash reports,

or audit_log.

R7. Photos for Cash (SOP 6) and Inventory (SOP 7) Fails are

MANDATORY. Submission validation must block until at

least one photo is attached to each such Fail.

R8. Offline-first. Every screen must function with airplane

mode on. Sync runs in the background and never blocks

the UI. If you write code that requires internet to

function, that is a bug.

R9. Do not add features not in the current Phase scope.

Spec Section 12 defines the four phases. If you think a

feature should be added, append it to docs/v2-wishlist.md

and continue with the current Phase.

R10. After every meaningful change, write a git commit with

a Conventional Commit message (Spec Section 15.5).

Never let a session end without committing.

WHEN YOU FINISH READING BOTH DOCUMENTS, reply with:

"Read both documents. Working on Phase ___. Ready."

Do not start coding until I confirm the Phase and give you the

Phase-specific prompt from Spec Section 14.2–14.5.

## 14.2 — Phase 1 Prompt (Weeks 1–4)

*१४.२ — टप्पा १ प्रॉम्प्ट (आठवडे १–४)*

Paste this after the Session-Start Prompt has been acknowledged. This focuses Claude Code on Phase 1 deliverables.

सत्र-सुरुवात प्रॉम्प्टची पुष्टी झाल्यानंतर हा पेस्ट करा. हा क्लॉड कोडचे लक्ष टप्पा १ वितरणांवर केंद्रित करतो.

PHASE 1 — DAILY AUDIT FOUNDATION (Weeks 1–4)

Phase 1 Goal (from Spec Section 12.1):

Store Manager can log in, run a complete daily audit, capture

photos for Cash/Inventory Fails, create CAPs from Fails, view

audit history, and send the audit PDF to GM via WhatsApp.

GM and Owner can log in but mostly read-only.

Screens to build (Spec Section 5):

S1 Splash, S2 Language Selection, S3 First-Time Setup,

S4 Login, S5 Home, S6 Start Daily Audit,

S7 Daily Audit Checkpoint, S8 Fail Detail, S9 Photo Capture,

S10 Review & Submit, S11 Submitted Confirmation,

S12 Audit History, S13 Audit Detail,

S14 CAP List, S15 CAP Create, S16 CAP Detail,

S17 CAP Mark Done, S22-S26 Reference tab, S27-S32 Settings.

Data model to implement (Spec Section 4):

All 14 tables. Seed sops.json (8 rows) and

checkpoints.json (68 daily rows). Weekly-only checkpoints

can be omitted until Phase 2.

Score logic to implement (Spec Section 6):

6.1 computeDailyScore, 6.2 bandFromCompliance,

6.3 worked example (Workbook 5.1 → 90.0% Good),

6.4 NA handling. Weekly score logic (6.5+) is Phase 2.

Notifications to implement (Spec Section 10):

Phase 1 has only basic in-app notifications. The 7-trigger

escalation engine is Phase 3. For Phase 1, the only

WhatsApp action is manual share of an audit PDF by the SM.

Phase 1 Definition of Done (Spec Section 16.1):

Run every test in Spec Section 13 Phase 1 (T1.1 through

T1.7). All must pass. Then use the app at the store for

at least 10 closings without major bugs. Then sign off.

Build order (start with week 1):

1. Create empty Flutter project. Set up Riverpod, go_router,

sqflite. Connect to Firebase project (Sagar provides

google-services.json).

2. Implement all 14 SQLite tables from Spec Section 4.

3. Write assets/seed/sops.json and

assets/seed/checkpoints.json (daily only).

4. Build S1, S2, S3, S4 (cold-launch flow).

5. Stop. Show me a working build. I'll test the cold launch.

DO NOT:

- Build all screens at once before showing me anything.

- Add features from Phase 2/3/4 "because they'll be needed.

anyway".

- Use any tech stack not in Spec Section 2.2.

- Hardcode any user-facing text in English. Use ARB.

- Skip writing a test for the score engine.

Confirm you understand and tell me what you'll build first.

## 14.3 — Phase 2 Prompt (Weeks 5–8)

*१४.३ — टप्पा २ प्रॉम्प्ट (आठवडे ५–८)*

PHASE 2 — WEEKLY AUDIT (Weeks 5–8)

PRE-CONDITION: Phase 1 is signed off using DoD in Spec

Section 16.1. All Phase 1 tests (T1.1–T1.7) pass.

If they don't, STOP and finish Phase 1 first.

Phase 2 Goal (from Spec Section 12.2):

GM can run a full weekly audit with 7-day daily review +

spot checks + 36 weekly-only checkpoints. Weekly report

generation matches Workbook Day 3 Section 3.6 format.

CAP verification flow active.

New screens to build (Spec Section 5):

S18 CAP Verify, S19 CAP Close, S20 Reports List,

S21 Report Detail. Plus new weekly-audit screens

(analogous to S6–S10 but for weekly audit type).

Data model additions:

Add 36 weekly-only checkpoint rows to checkpoints.json

(Workbook Day 3 Section 3.4). Add reports table

data layer.

Score logic to add (Spec Section 6.5–6.7):

computeWeeklyScore. Daily-audit-average contribution

(× 0.68). Cumulative weekly cash variance check (CW.7).

Missing-day-as-zero rule.

Workflow to implement:

7-day daily review screen — GM sees 7 daily audits as

cards, opens each, app picks 3 random checkpoints for

spot check, GM marks each Verified or Discrepancy.

After all 7 days reviewed, weekly-only checkpoints flow.

Phase 2 Definition of Done (Spec Section 16.2):

All Phase 1 tests STILL pass (regression). Plus all

Phase 2 tests (T2.1–T2.4). Used for at least 3 weekly

audits at the store.

Confirm and tell me the order you'll build in.

## 14.4 — Phase 3 Prompt (Weeks 9–11)

*१४.४ — टप्पा ३ प्रॉम्प्ट (आठवडे ९–११)*

PHASE 3 — MONTHLY + ESCALATION + TRENDS (Weeks 9–11)

PRE-CONDITION: Phases 1 and 2 signed off. All T1.x and

T2.x tests pass.

Phase 3 Goal (Spec Section 12.3):

Owner can run a monthly audit. Escalation engine fully

active (all 7 triggers). Trend analytics dashboard for

Owner. WhatsApp deep links + in-app notifications live.

New work:

- Monthly audit data + checkpoints + screens (analogous to

weekly).

- Escalation engine — Spec Section 7. All 7 triggers.

WhatsApp deep link format from Section 10.1.

- Trend dashboard — fl_chart for 12-week compliance line,

4-week rolling per-SOP, day-of-week heatmap.

- CAP aging job via flutter_workmanager (Spec Section 9.1).

Phase 3 Definition of Done (Spec Section 16.3):

All T1.x, T2.x, T3.x tests pass. WhatsApp deeplink tested

on a real device. Trend dashboard loads <2 seconds.

## 14.5 — Phase 4 Prompt (Weeks 12–13)

*१४.५ — टप्पा ४ प्रॉम्प्ट (आठवडे १२–१३)*

PHASE 4 — POLISH, TEST, RELEASE (Weeks 12–13)

PRE-CONDITION: Phases 1, 2, 3 all signed off.

Phase 4 work:

- Bug triage from open bug list (maintained in

docs/bug-log.md across all phases).

- Performance: every audit screen tap must respond

in <100ms. Profile and fix slow paths.

- Test on 3 Android phones: low-end (Android 7, 2GB RAM),

mid-range (Android 11, 4GB RAM), recent (Android 14, 6GB+).

- Accessibility: TalkBack labels on every interactive

element. Contrast ratios ≥ 4.5:1.

- Production APK signing. Keystore stored in Sagar's

password manager + backup location.

- README.md, ops runbook, training video script.

DoD (Spec Section 16.4): App is Play-Store-ready. Sagar

has the signed APK installed on his phone and uses it

daily for a week without bug reports.

# Section 15 — Coding Conventions & Repository Structure

*विभाग १५ — कोडिंग संमेलने आणि रिपॉझिटरी रचना*

## 15.1 — GitHub repository setup

*१५.१ — GitHub रिपॉझिटरी सेटअप*

- Create a private GitHub repository named saagar-audit-app under Sagar's account.
*सागरच्या खात्याअंतर्गत saagar-audit-app नावाची खाजगी GitHub रिपॉझिटरी तयार करा.*

- Initialize with .gitignore for Flutter (use GitHub's default template).
*Flutter साठी .gitignore सह सुरुवात करा (GitHub चे डीफॉल्ट टेम्पलेट वापरा).*

- Add Sagar as Owner (creator), and grant Claude Code session access via SSH key or fine-grained personal access token.
*सागरला मालक (निर्माता) जोडा, आणि SSH की किंवा fine-grained personal access token द्वारे क्लॉड कोड सत्र प्रवेश द्या.*

- Enable branch protection on main: require PR before merge, require 1 approval (Sagar).
*main वर शाखा संरक्षण सक्षम करा: merge करण्यापूर्वी PR आवश्यक, १ मंजुरी (सागर) आवश्यक.*

## 15.2 — Folder structure

*१५.२ — फोल्डर रचना*

saagar-audit-app/

├── README.md                       (project overview, how to build)

├── .gitignore

├── pubspec.yaml                    (Flutter dependencies)

├── docs/

│   ├── spec.md                     (link to this Spec docx)

│   ├── workbook.md                 (link to Workbook docx)

│   ├── data-model.md               (mirrors Spec Section 4)

│   ├── score-logic.md              (mirrors Spec Section 6)

│   ├── test-log.md                 (per-phase test results)

│   ├── bug-log.md                  (open + resolved bugs)

│   └── v2-wishlist.md              (deferred features)

├── lib/

│   ├── main.dart

│   ├── app.dart                    (MaterialApp setup, routing)

│   ├── data/

│   │   ├── models/                 (one file per table: user.dart, audit.dart, ...)

│   │   ├── db/

│   │   │   ├── database.dart       (sqflite setup, migrations)

│   │   │   ├── audit_dao.dart

│   │   │   ├── cap_dao.dart

│   │   │   └── ...                 (one DAO per table cluster)

│   │   ├── firestore/

│   │   │   ├── sync_service.dart

│   │   │   └── storage_service.dart

│   │   └── seed/

│   │       └── seed_loader.dart    (reads assets/seed/*.json)

│   ├── domain/

│   │   ├── score_engine.dart       (Section 6 implementation)

│   │   ├── escalation_engine.dart  (Section 7)

│   │   ├── cap_state_machine.dart  (Section 9)

│   │   └── pdf_generator.dart

│   ├── ui/

│   │   ├── screens/                (one folder per screen S1, S4, ...)

│   │   ├── widgets/                (reusable widgets)

│   │   └── theme/                  (navy/gold theme)

│   ├── providers/                  (Riverpod providers)

│   └── utils/

│       ├── i18n.dart               (localization helpers)

│       ├── date_utils.dart

│       └── logger.dart

├── test/                           (unit tests)

│   ├── score_engine_test.dart      (regression tests for 5.1, 5.2)

│   ├── escalation_engine_test.dart

│   └── cap_state_machine_test.dart

├── integration_test/               (end-to-end tests)

├── android/                        (Android build config)

├── assets/

│   ├── translations/

│   │   ├── app_en.arb

│   │   └── app_mr.arb

│   ├── seed/

│   │   ├── sops.json

│   │   └── checkpoints.json

│   ├── reference/

│   │   ├── rating_scale.json

│   │   ├── escalation_triggers.json

│   │   ├── evidence.json

│   │   └── glossary.json

│   ├── images/

│   └── migrations/                 (schema v2.sql, v3.sql ...)

└── builds/                         (compiled APKs, one per release)

## 15.3 — File naming

*१५.३ — फाइल नामकरण*

- Dart files: snake_case. Example: audit_result.dart, score_engine.dart.
*Dart फाइल्स: snake_case. उदाहरण: audit_result.dart, score_engine.dart.*

- Class names: PascalCase. Example: AuditResult, ScoreEngine.
*क्लास नावे: PascalCase. उदाहरण: AuditResult, ScoreEngine.*

- Variables and functions: camelCase. Example: computeDailyScore, currentUser.
*व्हेरिएबल आणि फंक्शन: camelCase. उदाहरण: computeDailyScore, currentUser.*

- Constants: SCREAMING_SNAKE_CASE. Example: MAX_PHOTOS_PER_FAIL.
*स्थिरांक: SCREAMING_SNAKE_CASE. उदाहरण: MAX_PHOTOS_PER_FAIL.*

- One screen per folder. lib/ui/screens/s07_checkpoint/ contains checkpoint_screen.dart, checkpoint_controller.dart, and any local widgets.
*प्रत्येक स्क्रीनसाठी एक फोल्डर. lib/ui/screens/s07_checkpoint/ मध्ये checkpoint_screen.dart, checkpoint_controller.dart, आणि कोणतेही लोकल विजेट्स.*

## 15.4 — Branch strategy

*१५.४ — शाखा धोरण*

- main — protected. Only Sagar's PR approvals merge here. Always a working build.
*main — संरक्षित. फक्त सागरच्या PR मंजुरीने इथे merge. नेहमी काम करणारी build.*

- phase-1, phase-2, phase-3, phase-4 — long-lived branches for each phase. Created off main.
*phase-1, phase-2, phase-3, phase-4 — प्रत्येक टप्प्यासाठी दीर्घजीवी शाखा. main वरून तयार.*

- feature/* — short-lived branches off the current phase branch. One per screen or feature. Merge back to the phase branch via PR.
*feature/* — सध्याच्या टप्पा शाखेवरून अल्पजीवी शाखा. प्रत्येक स्क्रीन किंवा फीचरसाठी एक. PR द्वारे टप्पा शाखेकडे परत merge.*

- Phase branches merge to main only when phase is signed off using DoD.
*DoD वापरून टप्पा साइन-ऑफ झाल्यावरच टप्पा शाखा main कडे merge.*

## 15.5 — Commit message format (Conventional Commits)

*१५.५ — कमिट संदेश स्वरूप (Conventional Commits)*

<type>(<scope>): <short description>

Examples:

feat(s07): add checkpoint screen with P/F/NA buttons

feat(score): implement computeDailyScore per Spec 6.1

fix(login): correct PIN lockout countdown logic

test(score): add Workbook 5.1 regression test

docs(readme): update build instructions

refactor(dao): split audit_dao into audit + audit_result

chore(deps): bump flutter to 3.18

Types: feat / fix / docs / test / refactor / chore / perf

Scope: short, lowercase, dash-separated. Optional but encouraged.

## 15.6 — When and what to commit

*१५.६ — कधी आणि काय कमिट करायचे*

- Commit every working chunk. Every screen rendering correctly = a commit. Every passing test = a commit.
*प्रत्येक काम करणारा भाग कमिट करा. प्रत्येक योग्य रेंडर होणारा स्क्रीन = कमिट. प्रत्येक पास होणारी चाचणी = कमिट.*

- Never commit broken code to main or to a phase branch. Use feature branches for in-progress work.
*तुटलेला कोड main किंवा टप्पा शाखेवर कधीही कमिट करू नका. प्रगतीच्या कामासाठी feature शाखा वापरा.*

- Never commit assets/seed/sops.json or checkpoints.json without also updating the Workbook reference comment.
*पुस्तिका संदर्भ टिप्पणी न अद्यतनित करता assets/seed/sops.json किंवा checkpoints.json कधीही कमिट करू नका.*

- Never commit Firebase service account keys or google-services.json secret values to a public repo. Use .gitignore. (Private repo is OK for google-services.json since it ships with the APK anyway.)
*Firebase service account की किंवा google-services.json गुप्त मूल्ये सार्वजनिक रिपोवर कधीही कमिट करू नका. .gitignore वापरा. (खाजगी रिपोसाठी google-services.json ठीक — कारण ते APK सोबत येते.)*

- Never commit the keystore file. Store it separately, password-protected.
*keystore फाइल कधीही कमिट करू नका. पासवर्ड-संरक्षित, वेगळी साठवा.*

## 15.7 — Code documentation rules

*१५.७ — कोड कागदपत्र नियम*

- Every domain function (score, escalation, CAP transitions) has a /// dartdoc comment with: purpose, parameters, return value, and a reference to the Spec section it implements.
*प्रत्येक domain फंक्शन (गुण, एस्केलेशन, CAP संक्रमण) ला /// dartdoc टिप्पणी: हेतू, पॅरामीटर्स, परतावा मूल्य, आणि अंमलात आणलेल्या Spec विभागाचा संदर्भ.*

- Example: /// Computes the weighted compliance score per Spec Section 6.1.
*उदाहरण: /// प्रति Spec विभाग ६.१ वजनी अनुपालन गुण मोजते.*

- Every screen file's header comment lists the screen number from Spec Section 5 and the user roles it serves.
*प्रत्येक स्क्रीन फाइलच्या हेडर टिप्पणीत Spec विभाग ५ मधला स्क्रीन क्रमांक आणि सेवा देणाऱ्या वापरकर्ता भूमिका.*

- Complex logic (>10 lines of branching) gets inline comments explaining WHY, not WHAT.
*जटिल तर्क (>१० ओळी शाखा) ला inline टिप्पण्या काय नव्हे, का स्पष्ट करत.*

# Section 16 — Definition of Done Per Phase

*विभाग १६ — टप्प्यानुसार पूर्णतेची व्याख्या*

## How to use this section

*हा विभाग कसा वापरायचा*

A phase is NOT done when the code compiles. A phase is NOT done when Claude Code says it is done. A phase is done when EVERY box in the checklist below is ticked, with evidence. Sagar personally walks each checklist before signing off. If any box is unticked, the phase continues. Skipping checklist items to "save time" is how 6-month projects become 18-month projects.

कोड कंपाइल झाला म्हणून टप्पा पूर्ण नाही. क्लॉड कोड म्हणतो म्हणून टप्पा पूर्ण नाही. खालच्या चेकलिस्टमधला प्रत्येक बॉक्स पुराव्यासह तपासला जाईल तेव्हाच टप्पा पूर्ण. साइन-ऑफ करण्यापूर्वी सागर वैयक्तिकरीत्या प्रत्येक चेकलिस्टमधून जातो. एखादा बॉक्स तपासला नसेल, टप्पा सुरू राहतो. "वेळ वाचवण्यासाठी" चेकलिस्ट आयटम वगळणे — ६-महिन्यांचे प्रकल्प १८-महिन्यांचे होण्याचे कारण.

## 16.1 — Phase 1 Definition of Done

*१६.१ — टप्पा १ पूर्णतेची व्याख्या*

### Functional checklist

*कार्यात्मक चेकलिस्ट*

- ☐ Fresh APK install on a fresh Android phone produces the cold-launch flow (S1 → S2 → S3) without errors.
*☐ ताज्या Android फोनवर ताजे APK इन्स्टॉल कोल्ड-लॉन्च प्रवाह (S1 → S2 → S3) त्रुटीशिवाय तयार करते.*

- ☐ Owner login works. Owner can create GM and SM users from S29.
*☐ मालक लॉगिन चालते. S29 वरून मालक GM आणि SM वापरकर्ते तयार करू शकतो.*

- ☐ SM can complete a 68-checkpoint daily audit in under 45 minutes on a phone.
*☐ SM फोनवर ४५ मिनिटांच्या आत ६८-तपासणी बिंदू दैनंदिन ऑडिट पूर्ण करू शकतो.*

- ☐ Test T1.2: scoring matches Workbook 5.1 exactly (81/90 = 90.0% Good). EVIDENCE: screenshot.
*☐ चाचणी T१.२: स्कोअरिंग पुस्तिका ५.१ शी अचूक जुळते (८१/९० = ९०.०% चांगले). पुरावा: स्क्रीनशॉट.*

- ☐ Test T1.3: photo mandatory enforcement works on Cash/Inv Fails.
*☐ चाचणी T१.३: रोख/स्टॉक नापासांवर फोटो अनिवार्य अंमलबजावणी चालते.*

- ☐ Test T1.4: NA handling math correct (NAs excluded from both numerator and denominator).
*☐ चाचणी T१.४: NA हाताळणी गणित बरोबर (NA दोघांतून वगळले — अंक आणि भागक).*

- ☐ Test T1.5: 24-hour airplane mode test. All data captured offline, syncs cleanly when reconnected.
*☐ चाचणी T१.५: २४-तास विमान मोड चाचणी. सर्व डेटा ऑफलाइन कॅप्चर, पुन्हा जोडल्यावर स्वच्छ समक्रमण.*

- ☐ Test T1.6: PIN lockout after 5 wrong attempts in 60s. Countdown visible.
*☐ चाचणी T१.६: ६० सेकंदांत ५ चुकीच्या प्रयत्नांनंतर PIN लॉकआउट. काउंटडाउन दिसते.*

- ☐ Test T1.7: language toggle. MR persists across logout/login/restart.
*☐ चाचणी T१.७: भाषा टॉगल. MR लॉगआउट/लॉगिन/पुनरारंभात टिकते.*

- ☐ Photo capture works in low light (test taken at counter after 8 PM with photo on file).
*☐ कमी प्रकाशात फोटो कॅप्चर चालते (८ PM नंतर काउंटरवर फायलीवर फोटोसह चाचणी).*

- ☐ PDF export opens in WhatsApp; PDF arrives readable on a contact's phone.
*☐ PDF निर्यात WhatsApp मध्ये उघडते; PDF संपर्काच्या फोनवर वाचनीय पोचते.*

- ☐ CAP can be created from a Fail; assigned to a user; marked Done by responsible.
*☐ नापासापासून CAP तयार करता येते; वापरकर्त्याला नेमता येते; जबाबदाराकडून Done म्हणून खूण.*

- ☐ Reference tab (S22–S26) renders all 4 sub-modules; glossary search works in EN and MR.
*☐ संदर्भ टॅब (S22–S26) सर्व ४ उप-मॉड्यूल रेंडर करतो; शब्दकोश शोध EN आणि MR मध्ये चालतो.*

### Quality checklist

*गुणवत्ता चेकलिस्ट*

- ☐ Every user-visible string is in both app_en.arb and app_mr.arb. NO hardcoded English text anywhere.
*☐ प्रत्येक वापरकर्ता-दृश्य मजकूर app_en.arb आणि app_mr.arb दोघांत आहे. कुठेही हार्डकोड इंग्रजी मजकूर नाही.*

- ☐ Score engine has a unit test that reproduces Workbook 5.1. Test runs green via `flutter test`.
*☐ गुण इंजिनकडे पुस्तिका ५.१ पुनरुत्पादन करणारी unit test आहे. `flutter test` द्वारे test हिरवी चालते.*

- ☐ All commits on phase-1 branch follow Conventional Commits format.
*☐ phase-1 शाखेवरील सर्व कमिट Conventional Commits स्वरूपाचे पालन करतात.*

- ☐ docs/bug-log.md exists with at least "none" entries per category; the log is real, not empty placeholders.
*☐ docs/bug-log.md अस्तित्वात — प्रत्येक श्रेणीसाठी किमान "none" नोंदी; लॉग खरा, रिकाम्या प्लेसहोल्डर्स नाही.*

- ☐ Phase 1 used at the actual store for 10 consecutive closings. SM signed-off list of bugs/observations in docs/phase-1-usage-log.md.
*☐ १० सलग बंदोबस्तांसाठी प्रत्यक्ष स्टोअरमध्ये टप्पा १ वापरला. docs/phase-1-usage-log.md मध्ये SM ने साइन-ऑफ केलेली बग्स/निरीक्षणे यादी.*

### Sign-off

*साइन-ऑफ*

- ☐ Sagar walks the checklist personally. Date and signature in docs/phase-1-signoff.md. Only when this file exists is Phase 1 done.
*☐ सागर वैयक्तिकरीत्या चेकलिस्टमधून जातो. docs/phase-1-signoff.md मध्ये दिनांक आणि सही. ही फाइल अस्तित्वात आल्यावरच टप्पा १ पूर्ण.*

## 16.2 — Phase 2 Definition of Done

*१६.२ — टप्पा २ पूर्णतेची व्याख्या*

### Functional checklist

*कार्यात्मक चेकलिस्ट*

- ☐ ALL Phase 1 DoD items still pass (regression). Re-walk the Phase 1 checklist before signing Phase 2.
*☐ सर्व टप्पा १ DoD आयटम अजूनही पास होतात (regression). टप्पा २ साइन करण्यापूर्वी टप्पा १ चेकलिस्ट पुन्हा चाला.*

- ☐ GM can complete a full weekly audit in 2 to 3 hours.
*☐ GM २ ते ३ तासांत पूर्ण साप्ताहिक ऑडिट करू शकते.*

- ☐ Test T2.1: Workbook 5.2 reproduction. 104.8/124 = 84.5% Poor. EXACT. EVIDENCE: screenshot.
*☐ चाचणी T२.१: पुस्तिका ५.२ पुनरुत्पादन. १०४.८/१२४ = ८४.५% वाईट. अचूक. पुरावा: स्क्रीनशॉट.*

- ☐ Test T2.2: missing daily counts as 0%. Confirmed via test data.
*☐ चाचणी T२.२: गहाळ दैनंदिन ०% म्हणून मोजला जातो. चाचणी डेटाद्वारे पुष्टी.*

- ☐ Test T2.3: spot check workflow — GM can mark verified or discrepancy.
*☐ चाचणी T२.३: स्पॉट चेक प्रवाह — GM पडताळलेले किंवा विसंगती खूण करू शकते.*

- ☐ Test T2.4: pattern detection — checkpoint failing 3+ days raises one Pattern CAP, not 3 individual CAPs.
*☐ चाचणी T२.४: पॅटर्न शोध — ३+ दिवस नापास होणारा तपासणी बिंदू ३ वैयक्तिक CAP नव्हे, एक पॅटर्न CAP तयार करतो.*

- ☐ Weekly report (S21) renders the 9-section format from Workbook 3.6. PDF export readable.
*☐ साप्ताहिक अहवाल (S21) पुस्तिका ३.६ मधले ९-विभाग स्वरूप रेंडर करते. PDF निर्यात वाचनीय.*

- ☐ Cumulative weekly cash variance check (CW.7) computes correctly across 7 days of varied variances.
*☐ ७ दिवसांच्या विविध तफावतांमध्ये एकत्रित साप्ताहिक रोख तफावत तपासणी (CW.७) योग्यरीत्या मोजते.*

- ☐ CAP verify (S18) re-runs the original checkpoint; verification failure correctly re-opens at Plan phase.
*☐ CAP पडताळणी (S18) मूळ तपासणी बिंदू पुन्हा चालवते; पडताळणी अपयश Plan टप्प्यावर योग्यरीत्या पुन्हा उघडते.*

- ☐ CAP close (S19) transitions correctly. Closed CAPs visible in CAP list under Closed filter.
*☐ CAP बंद (S19) योग्य संक्रमण. बंद CAP CAP यादीत Closed फिल्टरखाली दिसतात.*

### Quality checklist

*गुणवत्ता चेकलिस्ट*

- ☐ Weekly score engine has unit tests reproducing Workbook 5.2. `flutter test` green.
*☐ साप्ताहिक गुण इंजिनकडे पुस्तिका ५.२ पुनरुत्पादन करणाऱ्या unit tests. `flutter test` हिरवा.*

- ☐ At least 3 weekly audits conducted at the actual store. GM signed-off observations in docs/phase-2-usage-log.md.
*☐ प्रत्यक्ष स्टोअरमध्ये किमान ३ साप्ताहिक ऑडिट. docs/phase-2-usage-log.md मध्ये GM ने साइन-ऑफ केलेली निरीक्षणे.*

### Sign-off

*साइन-ऑफ*

- ☐ docs/phase-2-signoff.md by Sagar.
*☐ सागरकडून docs/phase-2-signoff.md.*

## 16.3 — Phase 3 Definition of Done

*१६.३ — टप्पा ३ पूर्णतेची व्याख्या*

### Functional checklist

*कार्यात्मक चेकलिस्ट*

- ☐ All Phase 1 + Phase 2 DoD items still pass.
*☐ सर्व टप्पा १ + टप्पा २ DoD आयटम अजूनही पास.*

- ☐ Test T3.1: Trigger 1 fires on Critical daily with Cash cause. Both GM and Owner escalations created, WhatsApp opens.
*☐ चाचणी T३.१: रोख कारणासह क्रिटिकल दैनंदिनवर ट्रिगर १ सुरू. GM आणि मालक दोघांचे एस्केलेशन तयार, WhatsApp उघडते.*

- ☐ Test T3.2: Trigger 7 fires after 3 declining weeks. Escalation to Owner, in-app notification.
*☐ चाचणी T३.२: ३ घसरत्या आठवड्यांनंतर ट्रिगर ७ सुरू. मालकाकडे एस्केलेशन, अॅप-अंतर्गत सूचना.*

- ☐ Test T3.3: CAP aging job fires at 00:05 local time. Open CAPs past deadline → status='aged', escalation raised.
*☐ चाचणी T३.३: CAP जुने काम ००:०५ लोकल वेळी सुरू. मुदत संपलेल्या open CAPs → status='aged', एस्केलेशन उभे.*

- ☐ Test T3.4: trend dashboard loads in <2 seconds with 12 weeks of seeded data.
*☐ चाचणी T३.४: १२ आठवडे सीड केलेल्या डेटासह कल डॅशबोर्ड <२ सेकंदांत लोड.*

- ☐ All 7 escalation triggers tested manually with seeded scenarios that match each trigger's threshold.
*☐ प्रत्येक ट्रिगरच्या मर्यादेशी जुळणाऱ्या सीड परिस्थितींसह सर्व ७ एस्केलेशन ट्रिगर हाताने चाचणी.*

- ☐ WhatsApp deep link tested on a real device with a real recipient phone number; the message arrives correctly formatted.
*☐ खऱ्या प्राप्तकर्त्याच्या फोन नंबरसह खऱ्या डिव्हाइसवर WhatsApp डीप लिंक चाचणी; संदेश योग्य स्वरूपात पोचतो.*

- ☐ Monthly audit (Owner role) submitted at least once during testing. Monthly report generated.
*☐ चाचणीदरम्यान किमान एकदा मासिक ऑडिट (मालक भूमिका) सादर. मासिक अहवाल तयार.*

- ☐ Day-of-week heatmap renders correctly when 12+ weeks of data exists.
*☐ १२+ आठवडे डेटा अस्तित्वात असेल आठवड्याच्या-दिवसाचा हीटमॅप योग्यरीत्या रेंडर.*

### Sign-off

*साइन-ऑफ*

- ☐ docs/phase-3-signoff.md by Sagar.
*☐ सागरकडून docs/phase-3-signoff.md.*

## 16.4 — Phase 4 Definition of Done (Release)

*१६.४ — टप्पा ४ पूर्णतेची व्याख्या (रिलीज)*

### Bug & performance checklist

*बग आणि कामगिरी चेकलिस्ट*

- ☐ docs/bug-log.md shows zero open Severity-1 bugs. Severity-2 and 3 explicitly deferred to v2 with reasoning.
*☐ docs/bug-log.md शून्य उघडे Severity-१ बग्स दाखवते. Severity-२ आणि ३ कारणासह v२ कडे स्पष्टपणे पुढे ढकलले.*

- ☐ Tap response time profiled on all audit screens. 95th percentile <100ms on a low-end Android 7 phone with 2GB RAM.
*☐ सर्व ऑडिट स्क्रीनवर टॅप प्रतिसाद वेळ profiled. २GB RAM असलेल्या Android ७ कमी-एंड फोनवर ९५ वा percentile <१००ms.*

- ☐ Cold start time <3 seconds on the same low-end device.
*☐ त्याच कमी-एंड डिव्हाइसवर कोल्ड स्टार्ट वेळ <३ सेकंद.*

- ☐ App tested on 3 different Android devices spanning OS versions. Test results in docs/device-test-matrix.md.
*☐ OS आवृत्त्या समाविष्ट ३ वेगवेगळ्या Android डिव्हाइसवर अॅप चाचणी. docs/device-test-matrix.md मध्ये चाचणी निकाल.*

- ☐ Accessibility: TalkBack reads every interactive element correctly. Tested with Android Accessibility Scanner — zero critical issues.
*☐ प्रवेशयोग्यता: TalkBack प्रत्येक इंटरॲक्टिव्ह घटक योग्यरीत्या वाचतो. Android Accessibility Scanner ने चाचणी — शून्य गंभीर समस्या.*

- ☐ Contrast ratios on all text ≥ 4.5:1 (WCAG AA).
*☐ सर्व मजकुरावर contrast गुणोत्तर ≥ ४.५:१ (WCAG AA).*

### Release checklist

*रिलीज चेकलिस्ट*

- ☐ Production APK signed with the release keystore. Keystore backed up in 2 locations (Sagar's password manager + offline encrypted drive).
*☐ रिलीज keystore ने प्रोडक्शन APK सही. २ ठिकाणी keystore बॅकअप (सागरचा पासवर्ड व्यवस्थापक + ऑफलाइन एनक्रिप्टेड ड्राइव्ह).*

- ☐ Keystore password documented securely (NOT in the repo). Sagar can recover the keystore without Claude Code's help.
*☐ keystore पासवर्ड सुरक्षितपणे कागदपत्रित (रिपोमध्ये नाही). क्लॉड कोडच्या मदतीशिवाय सागर keystore पुनर्प्राप्त करू शकतो.*

- ☐ APK installs cleanly on a fresh Android phone (no permissions errors, no missing dependencies).
*☐ ताज्या Android फोनवर APK स्वच्छपणे इन्स्टॉल (परवानगी त्रुटी नाहीत, गहाळ अवलंबित्व नाही).*

- ☐ Optional: Play Store internal track upload successful.
*☐ ऐच्छिक: Play Store इंटर्नल ट्रॅक अपलोड यशस्वी.*

- ☐ Sagar uses the signed APK on his personal phone daily for at least 7 consecutive days without raising new Severity-1 bugs.
*☐ नवीन Severity-१ बग्स न उठवता सागर त्याच्या वैयक्तिक फोनवर किमान ७ सलग दिवस सही केलेले APK वापरतो.*

### Documentation checklist

*कागदपत्र चेकलिस्ट*

- ☐ README.md updated with: project summary, how to build locally, how to release a new version, contact info.
*☐ README.md अद्यतनित: प्रकल्प सारांश, लोकल बिल्ड कसा करायचा, नवीन आवृत्ती कशी रिलीज करायची, संपर्क माहिती.*

- ☐ Ops runbook (docs/runbook.md) covers: how to reset a PIN, how to add a new SM, how to restore from backup, how to recover from a failed sync.
*☐ Ops runbook (docs/runbook.md) कव्हर करते: PIN कसा रीसेट करायचा, नवीन SM कसा जोडायचा, बॅकअप मधून कसे पुनर्संचयित करायचे, अयशस्वी समक्रमण पुनर्प्राप्त.*

- ☐ 5-minute training video recorded showing the SM evening daily-audit flow. Stored on Sagar's Google Drive.
*☐ SM संध्याकाळी दैनंदिन-ऑडिट प्रवाह दाखवणारा ५-मिनिटांचा प्रशिक्षण व्हिडिओ. सागरच्या Google Drive वर साठवला.*

### Sign-off — final release

*साइन-ऑफ — अंतिम रिलीज*

- ☐ docs/v1-release-signoff.md by Sagar. v1.0 tagged in Git. APK archived in builds/v1.0/.
*☐ सागरकडून docs/v1-release-signoff.md. Git मध्ये v१.० टॅग केले. builds/v१.०/ मध्ये APK संग्रहित.*

# Section 17 — Recovery Patterns — When Claude Code Goes Off-Track

*विभाग १७ — पुनर्प्राप्ती पॅटर्न — क्लॉड कोड भरकटला तर*

## Why this section exists

*हा विभाग का*

Claude Code is excellent but not infallible. Over a 13-week build, it will at some point: suggest swapping a locked library, add a feature you did not ask for, write code that doesn't match the Spec, or get stuck in a loop fixing one bug while introducing another. This section is the playbook for those moments. The single most important recovery skill is knowing when to roll back to the last known-good commit and try again, rather than trying to patch a broken state.

क्लॉड कोड उत्कृष्ट पण निर्दोष नाही. १३-आठवड्यांच्या बांधणीत, कधीतरी ते: लॉक केलेली लायब्ररी बदलण्याचे सुचवेल, तुम्ही न मागितलेले फीचर जोडेल, तपशीलाशी न जुळणारा कोड लिहेल, किंवा एक बग दुरुस्त करताना दुसरा आणणाऱ्या लूपमध्ये अडकेल. त्या क्षणांसाठी हा विभाग म्हणजे playbook आहे. एकमेव सर्वात महत्त्वाचे पुनर्प्राप्ती कौशल्य म्हणजे तुटलेली स्थिती patch करण्याचा प्रयत्न करण्याऐवजी कधी मागच्या ज्ञात-चांगल्या कमिटवर परत जायचे ते जाणणे.

## 17.1 — Anti-pattern detection — what to watch for

*१७.१ — विरुद्ध-पॅटर्न शोध — कशावर लक्ष ठेवायचे*

- Claude Code says "I'll just use Provider instead of Riverpod — it's simpler." → REJECT. Tech stack is locked. Reply: "Stay with Riverpod per Spec Section 2.2."
*क्लॉड कोड म्हणतो "मी फक्त Riverpod ऐवजी Provider वापरतो — सोपे आहे." → नकार द्या. Tech stack लॉक. उत्तर द्या: "Spec Section 2.2 नुसार Riverpod वर रहा."*

- Claude Code adds a new column to a table without updating the Spec or migration. → REJECT. Reply: "Add the column to the Spec Section 4 first. Show me the diff. Then write the migration."
*क्लॉड कोड Spec किंवा migration न अद्यतनित करता तक्त्यात नवीन स्तंभ जोडतो. → नकार. उत्तर: "आधी Spec Section 4 ला स्तंभ जोडा. diff दाखवा. मग migration लिहा."*

- Claude Code creates a screen not in Spec Section 5. → REJECT. Reply: "That screen is not in the Spec. If you think it should be, add it to docs/v2-wishlist.md. Continue with the current Phase scope."
*क्लॉड कोड Spec Section 5 मध्ये नसलेला स्क्रीन तयार करतो. → नकार. उत्तर: "तो स्क्रीन Spec मध्ये नाही. असावा वाटले — docs/v2-wishlist.md ला जोडा. सध्याच्या टप्पा व्याप्तीत राहा."*

- Claude Code says "the previous code was wrong, let me rewrite everything." → PAUSE. Reply: "Don't rewrite. Show me which file is wrong and explain why. We'll fix the one file."
*क्लॉड कोड म्हणतो "मागचा कोड चुकीचा होता, मी सर्व पुन्हा लिहितो." → थांबा. उत्तर: "पुन्हा लिहू नका. कोणती फाइल चुकीची आणि का स्पष्ट करा. आपण एकच फाइल दुरुस्त करू."*

- Claude Code makes multi-file changes without committing in between. → STOP. Reply: "Commit what you have first. Show me the diff. Then continue."
*क्लॉड कोड मध्ये कमिट न करता बहु-फाइल बदल करते. → थांबा. उत्तर: "आधी जे आहे ते कमिट करा. diff दाखवा. मग पुढे."*

- Claude Code's score engine produces 89.99 or 90.01 instead of 90.0. → STOP. Reply: "The math should produce 90.0 exactly. Re-read Spec Section 6 and find the rounding bug."
*क्लॉड कोडचे गुण इंजिन ९०.० ऐवजी ८९.९९ किंवा ९०.०१ तयार करते. → थांबा. उत्तर: "गणित अचूक ९०.० तयार करावे. Spec Section 6 पुन्हा वाचा आणि rounding बग शोधा."*

- Claude Code says "I'll add Firebase Auth — it's better than custom PIN." → REJECT. Reply: "PIN auth is locked decision #2 in Spec Section 1. Do not change."
*क्लॉड कोड म्हणते "मी Firebase Auth जोडतो — कस्टम PIN पेक्षा चांगले." → नकार. उत्तर: "PIN auth Spec Section 1 मध्ये निर्णय #२ लॉक. बदलू नका."*

## 17.2 — Git rollback procedures

*१७.२ — Git rollback प्रक्रिया*

### Soft rollback — undo last commit, keep changes

*मऊ rollback — मागचा कमिट पूर्ववत, बदल ठेवा*

git reset --soft HEAD~1

- Use when: the last commit message is wrong, or you want to bundle the last commit's changes with new work.
*वापर: मागच्या कमिटचा संदेश चुकीचा, किंवा मागच्या कमिटचे बदल नवीन कामासोबत बंडल करायचे.*

### Hard rollback — discard last commit and its changes

*कठोर rollback — मागचा कमिट आणि त्याचे बदल टाकून*

git reset --hard HEAD~1

- Use when: Claude Code wrote a wrong implementation and you want to start that change over.
*वापर: क्लॉड कोडने चुकीची अंमलबजावणी लिहिली आणि तो बदल नव्याने सुरू करायचा.*

- WARNING: uncommitted changes are lost. Stash first if needed: `git stash`.
*इशारा: कमिट न केलेले बदल गमावले जातात. गरज पडल्यास आधी stash करा: `git stash`.*

### Rollback to a specific known-good commit

*विशिष्ट ज्ञात-चांगल्या कमिटवर rollback*

git log --oneline                  # find the commit hash

git reset --hard <commit-hash>     # roll back to that point

- Use when: multiple commits are broken and you need to go back further.
*वापर: अनेक कमिट तुटलेले आणि आणखी मागे जायचे.*

### Branch-and-explore — try without breaking main

*शाखा-व-शोध — main न मोडता प्रयत्न*

git checkout -b experiment/<name>  # create a new branch

# ... try changes ...

git checkout main                  # return to main

git branch -D experiment/<name>    # delete experiment if bad

- Use when: you want to try a risky change without committing to it.
*वापर: कमिट न करता धोकादायक बदल वापरून पाहायचा.*

## 17.3 — The reset prompt — when to start a session fresh

*१७.३ — रीसेट प्रॉम्प्ट — सत्र नव्याने कधी सुरू करायचे*

If Claude Code has clearly lost the plot in a session — repeating the same mistake, making contradictory claims, or hallucinating about the codebase — close the session and start a new one. Paste the Session-Start Prompt again. Most session drift recovers from a fresh context.

क्लॉड कोडने सत्रात स्पष्टपणे कथानक गमावले — तीच चूक पुनरावृत्ती, परस्परविरोधी दावे, किंवा codebase बद्दल hallucinations — सत्र बंद करा आणि नवीन सुरू करा. सत्र-सुरुवात प्रॉम्प्ट पुन्हा पेस्ट करा. बहुतेक सत्र drift ताज्या context मधून पुनर्प्राप्त होते.

## 17.4 — When to escalate to a human Flutter developer

*१७.४ — मानवी Flutter डेव्हलपरकडे कधी एस्केलेट करायचे*

- Claude Code has been stuck on the same bug for 3+ sessions and progress has gone backward.
*क्लॉड कोड ३+ सत्रांसाठी त्याच बगवर अडकले आणि प्रगती मागे गेली.*

- A feature involves a Flutter or Firebase quirk that needs deep platform knowledge (e.g., Android background task limitations on specific OEMs).
*फीचरमध्ये खोल प्लॅटफॉर्म ज्ञान लागणारा Flutter किंवा Firebase quirk (उदा. विशिष्ट OEM वर Android background task मर्यादा).*

- Sagar wants to ship faster than the 13-week phasing allows.
*सागरला १३-आठवड्यांच्या टप्प्यांपेक्षा वेगाने शिप करायचे.*

- Approach: hand the Spec + Workbook + the GitHub repo to a freelance Flutter developer. They start from the same documents. No knowledge is lost in handover.
*दृष्टिकोन: Spec + Workbook + GitHub repo फ्रीलान्स Flutter डेव्हलपरला सोपवा. ते त्याच कागदपत्रांवरून सुरू करतात. हस्तांतरणात ज्ञान गमावले जात नाही.*

# Section 18 — Glossary — Flutter, Firebase, Git Terms

*विभाग १८ — शब्दकोश — Flutter, Firebase, Git संज्ञा*

## How to use this glossary

*हा शब्दकोश कसा वापरायचा*

This glossary is written for Sagar — owner-operator, not a developer. When Claude Code uses a term you do not recognize, look it up here. If a term is not in this glossary, ask Claude Code to explain it in plain language before letting it move on.

हा शब्दकोश सागरसाठी — मालक-संचालक, डेव्हलपर नव्हे — लिहिला आहे. क्लॉड कोड न ओळखलेली संज्ञा वापरते — इथे शोधा. संज्ञा या शब्दकोशात नसेल, पुढे जाण्याआधी क्लॉड कोडला सोप्या भाषेत स्पष्ट करायला सांगा.

### Flutter & Dart terms

*Flutter आणि Dart संज्ञा*


| Term | Meaning |
| --- | --- |
| Flutter | Google's framework for building mobile, web, and desktop apps from a single codebase. The thing we're using. |
| Dart | The programming language used by Flutter. Looks similar to Java/JavaScript. |
| Widget | A building block in Flutter. Everything you see — a button, a text field, a screen — is a widget. |
| State | Data inside a widget that can change (like the contents of a text field). |
| StatefulWidget | A widget whose state can change over time. Used for interactive parts of the UI. |
| StatelessWidget | A widget whose contents never change. Used for static parts. |
| BuildContext | An object Flutter passes to every widget so it can find its place in the widget tree. Don't worry about it; Claude Code handles this. |
| Riverpod | A library for managing state across the app. Acts as the glue between data and UI. |
| Provider (Riverpod) | A named piece of state that any widget can read from. Different from the older "Provider" library — we use Riverpod's. |
| Hot reload | Flutter's feature that lets you see code changes in the running app without restarting. Speeds up development hugely. |
| go_router | The library we use for navigating between screens. |
| Future / async | Dart's way of handling things that take time (like a network call). "await" pauses until done. |
| Stream | A series of values arriving over time. Used for data that updates live (like sync status). |
| pubspec.yaml | The file listing all the libraries ("packages") the app depends on. Like a shopping list. |
| Package / dependency | A reusable library written by someone else. We install them via pubspec.yaml. |
| pub get | The command that downloads all the packages listed in pubspec.yaml. |
| APK | Android Package — the .apk file that installs the app on an Android phone. |
| Keystore | A file containing the cryptographic key used to sign the APK. Loss = cannot release updates. |
| MainAxisAlignment / CrossAxisAlignment | How widgets are spaced in a row or column. Claude Code knows; you don't need to. |
| ARB file | JSON file containing translations. We have app_en.arb and app_mr.arb. |
| intl package | The package that handles dates, numbers, and translations in different locales. |
| sqflite | The Flutter package for using a SQLite database (local storage on the device). |
| DAO | Data Access Object. A class that reads and writes a specific table. Keeps SQL code in one place. |


### Firebase terms

*Firebase संज्ञा*


| Term | Meaning |
| --- | --- |
| Firebase | Google's cloud platform. We use it for the database (Firestore) and photo storage (Storage). Free for our scale. |
| Firestore | A NoSQL cloud database. Stores data as "documents" inside "collections". |
| Document (Firestore) | Equivalent to a row in a SQL table. Has a unique ID and a set of fields. |
| Collection (Firestore) | A group of documents. Similar to a SQL table. |
| Firebase Storage | Cloud storage for files like photos and PDFs. We store audit photos here. |
| google-services.json | The config file Firebase generates for our specific project. Ships with the APK. Identifies the app to Firebase. |
| Security Rules | Firebase's permission system. Defines who can read/write what. We'll write rules so only our 3 users can access the data. |
| Free tier | The amount of Firebase usage Google gives away for free. We stay well within: 50K reads + 20K writes per day, 5GB storage. |
| Cold tier (Storage) | Cheaper storage for files we rarely access. We use it for older backups. |
| Authentication (Firebase) | Firebase's built-in user-login system. We're NOT using it — we use custom PIN auth instead. Decision locked. |


### Git & GitHub terms

*Git आणि GitHub संज्ञा*


| Term | Meaning |
| --- | --- |
| Git | The version-control tool. Tracks every change to every file. Lets you roll back to any past state. |
| GitHub | A website hosting Git repositories. We host the project there. |
| Repository (repo) | A project folder under Git's control. Contains all the code, history, and branches. |
| Commit | A saved snapshot of the project at one point in time. Has a message describing what changed. |
| Commit hash | The unique ID of a commit, like a8f3b2c. Used to refer to a specific commit. |
| Branch | An independent line of development. main is the primary branch; we create other branches for in-progress work. |
| Main branch | The branch holding the canonical, working code. Protected — only PRs can merge here. |
| Feature branch | A short-lived branch for one new feature. Merged to main via PR when ready. |
| PR (Pull Request) | A request to merge changes from one branch into another. Sagar reviews and approves before merge. |
| Merge | Combining two branches into one. Done via PR for main. |
| Conflict (merge conflict) | When two branches changed the same line. Git asks a human to choose. Rare in solo development. |
| Stash | Temporarily set aside uncommitted changes. Use to switch branches without losing work. |
| Push | Send your local commits to GitHub. |
| Pull | Download new commits from GitHub to your local copy. |
| Clone | Download a fresh copy of a repo from GitHub. Done once at setup. |
| .gitignore | A file listing things Git should NOT track. We use it to skip the build folder, the keystore, secrets, etc. |
| Tag | A label attached to a specific commit. We tag the release commit as v1.0. |
| HEAD | Git's pointer to your current commit. HEAD~1 means "one commit before HEAD". |
| Reset --soft | Undo last commit but keep its changes ready to re-commit. |
| Reset --hard | Undo last commit AND discard its changes. Dangerous; use carefully. |
| Conventional Commits | A commit message convention: feat / fix / docs / test / refactor / chore. We use this — Section 15.5. |


### Audit-app-specific shorthand

*ऑडिट-अॅप-विशिष्ट संक्षेप*


| Term | Meaning |
| --- | --- |
| S1, S5, S7 … | Screen IDs. Defined in Spec Section 5. |
| SOP1 … SOP8 | The 8 Priority 1 SOPs. Defined in Workbook Day 2 Section 2.9. |
| CW.1, CW.7 … | Cash Weekly checkpoints. Workbook Day 3 Section 3.4. |
| IW.1, IW.11 … | Inventory Weekly checkpoints. Workbook Day 3 Section 3.4. |
| Trigger 1 … Trigger 7 | The 7 mandatory escalation triggers. Workbook Day 4 Section 4.6. |
| DoD | Definition of Done. Spec Section 16. Walked before signing off a phase. |
| CAP | Corrective Action Plan. Workbook Day 4 Section 4.3–4.4. |
| 5 Whys | Root-cause technique. Drill 5 levels deep. Workbook Day 4 Section 4.2. |
| RSO | Regional Service Outlet — Titan's term for a service-enabled franchise store. Our store IS one. |



| BEST PRACTICE \| उत्तम सराव<br>End of the Specification. Combined with Saagar_P1_Audit_Workbook_v1, this document gives Claude Code everything it needs to build the audit app without bugs from ambiguity. Read Section 14 once more before your first Claude Code session — that's the bit you'll actually paste.<br>तपशील समाप्त. Saagar_P1_Audit_Workbook_v1 सोबत, हा दस्तऐवज क्लॉड कोडला अस्पष्टतेच्या बग्सशिवाय ऑडिट अॅप बांधण्यासाठी सर्व आवश्यक देतो. तुमच्या पहिल्या क्लॉड कोड सत्रापूर्वी विभाग १४ पुन्हा एकदा वाचा — तेच तुम्ही प्रत्यक्ष पेस्ट कराल. |
| --- |

