# Saagar Audit App — Bilingual Strings, CAP State Machine & Notifications (Spec Sections 8–10)
> **Source**: Saagar_P1_App_Spec_v1.docx (Sections 8, 9, 10)  
> **Master**: [rain/SPEC_APP.md](../SPEC_APP.md)  
> **Index**: [rain/spec/INDEX.md](INDEX.md)

---

# Section 8 — Bilingual String Table

*विभाग ८ — द्विभाषी मजकूर तक्ता*

## How strings are organized in Flutter

*Flutter मध्ये मजकूर कसा संघटित*

Use flutter_localizations + the intl package. Two files: assets/translations/app_en.arb and assets/translations/app_mr.arb. Each ARB file is JSON. Every user-facing string in the entire app exists in both files keyed by the same identifier. Code references strings as AppLocalizations.of(context).key — never hardcode user-facing text. The language is selected at login (S31) and stored in users.language_pref. App restart applies the change.

flutter_localizations + intl पॅकेज वापरा. दोन फाइल्स: assets/translations/app_en.arb आणि assets/translations/app_mr.arb. प्रत्येक ARB फाइल JSON. संपूर्ण अॅपमधला प्रत्येक वापरकर्ता-तोंडी मजकूर त्याच ओळखकर्त्याने की केलेला दोन्ही फाइलमध्ये अस्तित्वात आहे. कोड AppLocalizations.of(context).key म्हणून संदर्भ देतो — वापरकर्ता-तोंडी मजकूर कधीही हार्डकोड करू नका. भाषा लॉगिनवर निवडली जाते (S31) आणि users.language_pref मध्ये साठवली. अॅप पुन्हा सुरू केल्याने बदल अंमलात येतो.

## Critical strings by category

*वर्गानुसार मुख्य मजकूर*

### Navigation & nav-bar labels

*नेव्हिगेशन व नेव्ह-बार लेबल*


| Key | EN | MR |
| --- | --- | --- |
| nav.home | Home | मुख्यपृष्ठ |
| nav.audits | Audits | ऑडिट |
| nav.caps | CAPs | CAPs |
| nav.reference | Reference | संदर्भ |
| nav.settings | Settings | सेटिंग्ज |
| nav.reports | Reports | अहवाल |


### Buttons & actions

*बटणे व कृती*


| Key | EN | MR |
| --- | --- | --- |
| btn.start_audit | Start Audit | ऑडिट सुरू करा |
| btn.submit | Submit | सादर करा |
| btn.save_draft | Save Draft | ड्राफ्ट जतन करा |
| btn.cancel | Cancel | रद्द |
| btn.continue | Continue | पुढे |
| btn.back | Back | मागे |
| btn.next | Next | पुढे |
| btn.previous | Previous | मागे |
| btn.pass | Pass | पास |
| btn.fail | Fail | नापास |
| btn.na | NA | NA |
| btn.add_photo | Add Photo | फोटो जोडा |
| btn.retake | Retake | पुन्हा घ्या |
| btn.use_photo | Use | वापरा |
| btn.create_cap | Create CAP | CAP तयार करा |
| btn.mark_done | Mark Done | पूर्ण म्हणून खूण |
| btn.verify | Verify | पडताळा |
| btn.close_cap | Close CAP | CAP बंद करा |
| btn.reopen | Reopen | पुन्हा उघडा |
| btn.extend | Extend Deadline | मुदतवाढ |
| btn.escalate | Escalate | एस्केलेट |
| btn.export_pdf | Export PDF | PDF निर्यात |
| btn.share_whatsapp | Share to WhatsApp | WhatsApp ला शेअर |
| btn.login | Login | लॉगिन |
| btn.logout | Logout | लॉगआउट |
| btn.change_pin | Change PIN | PIN बदला |
| btn.add | Add | जोडा |
| btn.edit | Edit | संपादन |
| btn.delete | Delete | हटवा |
| btn.deactivate | Deactivate | निष्क्रिय करा |


### Status & bands

*स्थिती व पट्ट्या*


| Key | EN | MR |
| --- | --- | --- |
| band.excellent | Excellent | उत्कृष्ट |
| band.good | Good | चांगले |
| band.fair | Fair | बरे |
| band.poor | Poor | वाईट |
| band.critical | Critical | अत्यावश्यक |
| cap.status.open | Open | उघडे |
| cap.status.done | Done | पूर्ण |
| cap.status.verified | Verified | पडताळलेले |
| cap.status.closed | Closed | बंद |
| cap.status.aged | Aged | जुने |
| cap.status.reopened | Reopened | पुन्हा उघडलेले |
| audit.status.draft | Draft | ड्राफ्ट |
| audit.status.submitted | Submitted | सादर |
| audit.status.verified | Verified | पडताळलेले |
| audit.status.hidden | Hidden | लपवलेले |


### Errors & validation

*त्रुटी आणि पडताळणी*


| Key | EN | MR |
| --- | --- | --- |
| err.wrong_pin | Wrong PIN | चुकीचा PIN |
| err.locked | Too many attempts. Locked for {seconds}s. | बरेच प्रयत्न. {seconds}s लॉक. |
| err.required_field | This field is required. | हे क्षेत्र आवश्यक. |
| err.future_date | Future date not allowed. | भविष्यातील तारीख स्वीकारली जात नाही. |
| err.photo_required | Photo required for Cash/Inventory Fails. | रोख/स्टॉक नापासांना फोटो आवश्यक. |
| err.finding_required | Please write a one-sentence finding. | कृपया एका वाक्याचा निष्कर्ष लिहा. |
| err.no_internet | No internet — will sync later. | इंटरनेट नाही — नंतर समक्रमित होईल. |
| err.cap_deadline_passed | Cannot extend — deadline already passed. | वाढवू शकत नाही — मुदत आधीच संपली. |
| err.cannot_edit_submitted | Submitted audits cannot be edited. | सादर ऑडिट संपादित करता येत नाहीत. |


### Success & confirmations

*यश व पुष्ट्या*


| Key | EN | MR |
| --- | --- | --- |
| ok.audit_submitted | Audit submitted successfully | ऑडिट यशस्वीरीत्या सादर |
| ok.cap_created | CAP created | CAP तयार |
| ok.cap_marked_done | CAP marked done | CAP पूर्ण म्हणून खूण |
| ok.cap_verified | CAP verified | CAP पडताळलेले |
| ok.cap_closed | CAP closed | CAP बंद |
| ok.pin_changed | PIN changed | PIN बदलला |
| ok.synced | Synced to cloud | क्लाउडशी समक्रमित |



| WARNING \| सूचना<br>The full ARB files (250+ keys) live in assets/translations/. The tables above are the most critical sample. Claude Code: as you build each screen, every string you write must immediately be added to BOTH app_en.arb and app_mr.arb. Never leave a TODO for translation. If you are unsure of a Marathi translation, ask Sagar in chat — do not guess.<br>पूर्ण ARB फाइल्स (२५०+ की) assets/translations/ मध्ये राहतात. वरचे तक्ते सर्वात मुख्य नमुना. क्लॉड कोड: प्रत्येक स्क्रीन बांधताना तुम्ही लिहिलेला प्रत्येक मजकूर लगेच app_en.arb आणि app_mr.arb दोघांत जोडला पाहिजे. भाषांतरासाठी TODO सोडू नका. मराठी भाषांतराची खात्री नसेल, चॅटमध्ये सागरला विचारा — अंदाज करू नका. |
| --- |


# Section 9 — CAP Workflow — State Machine

*विभाग ९ — CAP कार्यप्रवाह — स्थिती यंत्र*

## The state diagram in plain text

*स्पष्ट मजकुरात स्थिती आकृती*

A CAP moves through six possible states. Allowed transitions are strictly enforced — Claude Code MUST validate every state change against this table before writing to the database. An invalid transition (e.g., open → closed without going through done and verified) is a code bug and must throw.

एक CAP सहा शक्य स्थितींमधून फिरते. परवानगी असलेले संक्रमण कठोरपणे अंमलात आणले जातात — क्लॉड कोडने डेटाबेसवर लिहिण्यापूर्वी प्रत्येक स्थिती बदलाची या तक्त्याशी पडताळणी करावी. अवैध संक्रमण (उदा. पूर्ण आणि पडताळलेले न जाता open → closed) हा कोड बग आणि throw करावा.


| From \| पासून | Event \| घटना | To \| कडे | Allowed by \| परवानगी | Side effects \| दुष्परिणाम |
| --- | --- | --- | --- | --- |
| (new) | create | open | SM, GM, Owner | INSERT cap_log 'created'; push notification to responsible |
| open | mark_done | done | Responsible user | INSERT cap_log; notify GM |
| open | extend_deadline | open | GM, Owner (before deadline only) | UPDATE deadline, INSERT cap_log 'extended' |
| open | auto-age | aged | system (deadline passed without verify) | INSERT cap_log 'aged'; escalate to next tier |
| done | verify | verified | GM, Owner | INSERT cap_log; notify responsible |
| done | verify_failed | open (back to plan) | GM, Owner | Re-open at plan phase — new 5 Whys required |
| verified | close | closed | GM, Owner | INSERT cap_log; final |
| aged | mark_done | done | Responsible user | Same as open→done; aged_count increment |
| aged | auto-age (again) | aged | system (still no verify) | INSERT cap_log; escalate further |
| closed | reopen | open (Plan phase) | Owner only | INSERT cap_log 'reopened'; aged_count carried over |


## 9.1 — Aging logic — runs daily at midnight

*९.१ — जुने होणे तर्क — दर मध्यरात्री चालते*

// Scheduled via flutter_workmanager — runs once per day at 00:05 local time

ageCheck():

today = today's date

open_caps = SELECT * FROM caps WHERE status IN ('open', 'done')

for each cap in open_caps:

if cap.deadline < today AND cap.status == 'open':

UPDATE caps SET status='aged', aged_count = aged_count + 1

INSERT cap_log: event='aged', from='open', to='aged'

escalate_one_tier_up(cap)  // SM-owned → GM; GM-owned → Owner

elif cap.deadline < today AND cap.status == 'done' AND days_since_done > 3:

// Verification is overdue, not just the CAP

escalate('verify_pending', target=cap.verifier_or_GM, urgency='same_day')

## 9.2 — Extension rules

*९.२ — मुदतवाढ नियम*

- Only GM or Owner can extend a deadline.
*फक्त GM किंवा मालक मुदत वाढवू शकतो.*

- Must be done BEFORE the original deadline expires. Cannot extend a CAP that is already aged.
*मूळ मुदत संपण्यापूर्वी केले पाहिजे. आधीच जुनी झालेली CAP वाढवू शकत नाही.*

- Extension requires a written reason (stored in caps.latest_extension_reason and appended to cap_log).
*मुदतवाढीला लेखी कारण लागते (caps.latest_extension_reason मध्ये साठवले आणि cap_log ला जोडले).*

- Maximum 2 extensions per CAP. After 2 extensions, further extension requests are rejected — the CAP must be re-planned with a new 5 Whys instead.
*प्रति CAP जास्तीत जास्त २ मुदतवाढ. २ नंतर, पुढच्या मुदतवाढ विनंत्या नाकारल्या जातात — त्याऐवजी नवीन पाच का? सह CAP पुन्हा नियोजित करावी.*

# Section 10 — Notifications & Alerts

*विभाग १० — सूचना व अॅलर्ट*

## Two channels

*दोन मार्ग*

Channel A — in-app local notifications via flutter_local_notifications. These appear in the Android notification tray. Required for every notification triggered by the app.

मार्ग अ — flutter_local_notifications द्वारे अॅप-अंतर्गत लोकल सूचना. Android सूचना ट्रेमध्ये दिसतात. अॅपने सुरू केलेल्या प्रत्येक सूचनेसाठी आवश्यक.

Channel B — WhatsApp deep link via url_launcher. Used only for high-urgency escalations where the recipient must act outside the app. Opens WhatsApp with the recipient's number pre-selected and the escalation message pre-filled. The user still has to tap Send manually — we never auto-send.

मार्ग ब — url_launcher द्वारे WhatsApp डीप लिंक. प्राप्तकर्त्याने अॅपच्या बाहेर कृती करायचीच अशा उच्च-तातडीच्या एस्केलेशनसाठीच वापरला जातो. प्राप्तकर्त्याचा नंबर पूर्व-निवडलेला आणि एस्केलेशन संदेश पूर्व-भरलेला असलेले WhatsApp उघडते. वापरकर्त्याला तरीही पाठवा हाताने टॅप करावे लागते — आम्ही आपोआप पाठवत नाही.

## Notification matrix — what fires when

*सूचना मॅट्रिक्स — कधी काय सुरू होते*


| Event \| घटना | Recipient \| प्राप्तकर्ता | Channel \| मार्ग |
| --- | --- | --- |
| Daily audit submitted | GM | In-app |
| Daily audit in Critical band (Trigger 1) | GM | WhatsApp + in-app |
| Daily audit Critical + Cash/Inv cause | Owner | WhatsApp + in-app |
| Cash variance > ₹500 single day (Trigger 3) | GM | WhatsApp + in-app |
| Cash variance > ₹500 two days running | Owner | WhatsApp + in-app |
| Weekly audit submitted | Owner | In-app |
| Weekly audit shows pattern (Trigger 2) | GM | In-app |
| Inventory variance > 2% (Trigger 4) | Owner | WhatsApp + in-app |
| Security/legal concern flagged (Trigger 5) | Owner | WhatsApp + in-app |
| Customer complaint escalation (Trigger 6) | Owner | WhatsApp + in-app |
| 3-week declining trend (Trigger 7) | Owner | In-app |
| CAP assigned to me | Responsible user | In-app |
| CAP I assigned was marked Done | GM (the verifier) | In-app |
| CAP aged (deadline passed) | Responsible + next tier up | In-app |
| CAP verification failed → reopened | Original responsible | In-app |
| Sync failed 3 times in a row | Current device user | In-app silent |


## 10.1 — WhatsApp deep link format

*१०.१ — WhatsApp डीप लिंक स्वरूप*

// Per WhatsApp documentation — works on Android and iOS

url = 'https://wa.me/' + recipient_phone_e164 + '?text=' + urlencode(message)

// Example

recipient_phone_e164 = '91XXXXXXXXXX'  // no plus sign, no spaces

message = '[SAME_NIGHT] Trigger 1 — 2026-05-27\n\n1. What happened: ...'

launchExternalUrl(url, mode: LaunchMode.externalApplication)


| NOTE \| टीप<br>Phone numbers in users.phone MUST be stored in E.164 format without the leading +. The app's user-management screen (S29) validates this on input. If the phone field is empty for a recipient, the escalation falls back to in-app only and shows a warning to the sender: "Recipient has no WhatsApp number set. Tell them in person."<br>users.phone मधले फोन नंबर सुरुवातीच्या + शिवाय E.164 स्वरूपात साठवले पाहिजेत. अॅपची वापरकर्ता-व्यवस्थापन स्क्रीन (S29) इनपुटवर हे पडताळते. प्राप्तकर्त्यासाठी फोन फील्ड रिकामे असेल, एस्केलेशन फक्त-अॅप-अंतर्गत वर पडते आणि पाठवणाऱ्याला इशारा दाखवते: "प्राप्तकर्त्याकडे WhatsApp नंबर नाही. प्रत्यक्ष सांगा." |
| --- |


## 10.2 — In-app notification behaviour

*१०.२ — अॅप-अंतर्गत सूचना वर्तन*

- All notifications also create an entry in the in-app Notifications screen (a future Phase 3 screen) so the user can review what they missed.
*सर्व सूचना अॅप-अंतर्गत सूचना स्क्रीनमध्ये (भविष्यातील टप्पा ३ स्क्रीन) नोंदी तयार करतात जेणेकरून वापरकर्ता काय चुकले ते पुनरावलोकन करू शकतो.*

- Notifications never repeat — once an event is notified, the same event does not re-notify even if app is closed and reopened.
*सूचना कधीही पुनरावृत्ती होत नाहीत — एका घटनेची सूचना दिल्यानंतर, अॅप बंद करून पुन्हा उघडले तरी तीच घटना पुन्हा सूचना देत नाही.*

- Critical-band and Trigger 5 (security/legal) notifications use a distinct sound and the persistent notification flag — they remain in the tray until the user opens them.
*क्रिटिकल पट्टी आणि ट्रिगर ५ (सुरक्षा/कायदेशीर) सूचना वेगळा आवाज आणि कायमस्वरूपी सूचना झेंडा वापरतात — वापरकर्त्याने उघडेपर्यंत ट्रेमध्ये राहतात.*

- All other notifications use the default sound and auto-dismiss after the user taps them.
*इतर सर्व सूचना डीफॉल्ट आवाज वापरतात आणि वापरकर्त्याने टॅप केल्यावर आपोआप गायब.*

## 10.3 — Permission flow

*१०.३ — परवानगी प्रवाह*

On first launch after S3 (first-time setup), the app requests notification permission with the rationale: "The app needs to notify you when an audit needs your attention. Without this, urgent issues might be missed." If the user denies, the app continues to work, but a banner appears at the top of the Home screen recommending enabling notifications.

S3 (पहिल्यांदा सेटअप) नंतर पहिल्या लॉन्चवर, अॅप कारणासह सूचना परवानगी मागते: "ऑडिटला तुमचे लक्ष लागले की अॅपला सूचना द्यायची गरज. याशिवाय, तातडीच्या समस्या चुकू शकतात." वापरकर्त्याने नकार दिला, अॅप काम करत राहते, पण होम स्क्रीनच्या वर बॅनर दिसून सूचना सक्षम करण्याची शिफारस.

