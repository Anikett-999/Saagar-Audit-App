# Saagar Audit App — Score Calculation & Escalation Engine (Spec Sections 6 & 7)
> **Source**: Saagar_P1_App_Spec_v1.docx (Sections 6 & 7)  
> **Master**: [rain/SPEC_APP.md](../SPEC_APP.md)  
> **Index**: [rain/spec/INDEX.md](INDEX.md)

---

# Section 6 — Score Calculation Logic

*विभाग ६ — गुण मोजणी तर्क*

## Why this section exists

*हा विभाग का*

This is the most error-prone area in any audit app. Get the math wrong by even 0.1 points and the audit programme loses credibility — auditors will see a Pass when the workbook says Fail, or a Fair band when the math gave Good. This section spells out every calculation Claude Code must implement, with worked examples that the app must reproduce exactly. The simulated audits in Workbook Day 5 Sections 5.1 and 5.2 serve as the canonical test cases — if your code produces a different answer from the workbook, your code is wrong, not the workbook.

कोणत्याही ऑडिट अॅपमधले सर्वात त्रुटी-प्रवण क्षेत्र हे आहे. गणित ०.१ गुणानेही चुकले — ऑडिट कार्यक्रमाची विश्वासार्हता जाते — पुस्तिका नापास म्हणते तेव्हा ऑडिटर पास पाहतात, किंवा गणिताने चांगले दिले तरी बरे पट्टी. हा विभाग क्लॉड कोडने अंमलात आणायची प्रत्येक गणना स्पष्ट करतो, अॅपने अचूक पुनरुत्पादन करायच्या उदाहरणांसह. पुस्तिका दिवस ५ विभाग ५.१ आणि ५.२ मधल्या अनुकरण ऑडिट अधिकृत चाचणी प्रकरणे — तुमचा कोड पुस्तिकेपेक्षा वेगळे उत्तर देत असेल, तुमचा कोड चुकीचा, पुस्तिका नाही.

## 6.1 — Daily audit score formula

*६.१ — दैनंदिन ऑडिट गुण सूत्र*

// Pseudocode — implement exactly this

computeDailyScore(audit_id):

results = SELECT * FROM audit_results WHERE audit_id = audit_id

raw_score = 0

max_score = 0

pass_count = 0; fail_count = 0; na_count = 0

for each r in results:

cp = SELECT * FROM checkpoints WHERE id = r.checkpoint_id

if r.result == 'P':

raw_score  += cp.weight

max_score  += cp.weight

pass_count += 1

elif r.result == 'F':

raw_score  += 0

max_score  += cp.weight

fail_count += 1

elif r.result == 'NA':

// NA excluded from BOTH numerator and denominator

na_count   += 1

// do not touch raw_score or max_score

compliance_pct = round(raw_score / max_score * 100, 1)  // 1 decimal

band           = bandFromCompliance(compliance_pct)

UPDATE audits SET raw_score, max_score, compliance_pct, band,

pass_count, fail_count, na_count WHERE id = audit_id

### 6.2 — Compliance band function

*६.२ — अनुपालन पट्टी कार्य*

bandFromCompliance(pct):

if pct >= 95.0:   return 'excellent'

if pct >= 90.0:   return 'good'

if pct >= 85.0:   return 'fair'

if pct >= 80.0:   return 'poor'

return 'critical'


| WARNING \| सूचना<br>BOUNDARIES ARE STRICT. 89.9 is FAIR, not Good. 84.9 is POOR, not Fair. 79.9 is CRITICAL. The most common bug in audit programmes is auditors (or code) rounding 89.7 up to 90 and calling it Good. Claude Code: always store and display ONE DECIMAL place. Never round before band calculation.<br>मर्यादा कठोर आहेत. ८९.९ "बरे" आहे, "चांगले" नाही. ८४.९ "वाईट" आहे, "बरे" नाही. ७९.९ "क्रिटिकल". ऑडिट कार्यक्रमातला सर्वात सामान्य बग म्हणजे ऑडिटर (किंवा कोड) ८९.७ ला ९० पर्यंत गोलाकार करून "चांगले" म्हणणे. क्लॉड कोड: नेहमी एक दशांश स्थानात साठवा आणि दाखवा. पट्टी गणनेपूर्वी गोलाकार करू नका. |
| --- |


## 6.3 — Worked example: Workbook Day 5 Section 5.1

*६.३ — उदाहरण: पुस्तिका दिवस ५ विभाग ५.१*

The simulated daily audit in the Workbook produced 90.0% (Good, just barely). The app MUST reproduce this exactly. If you give the app the same 12 observations and 56 implied passes, it must compute 81 / 90 = 90.0% Good. Test this every time score logic changes.

पुस्तिकेतल्या अनुकरण दैनंदिन ऑडिटने ९०.०% (काठावर चांगले) दिले. अॅपने हे अचूक पुनरुत्पादन करावे. अॅपला त्याच १२ निरीक्षणे आणि ५६ गृहीत पास दिल्यास, ते ८१ / ९० = ९०.०% चांगले मोजले पाहिजे. गुण तर्क बदलला की दर वेळी हे तपासा.


| F# | Checkpoint | Result | Weight | Earned |
| --- | --- | --- | --- | --- |
| F1 | 1.4 | F | 1 | 0 |
| F2 | 2.1 + 2.2 | P (both) | 1+1 | 2 |
| F3 | 3.x | F | 1 | 0 |
| F4 | 4.x | P | 1 | 1 |
| F5 | 5.x | F | 1 | 0 |
| F6 | 6.5 | P (with note) | 2 | 2 |
| F7 | 6.11 | F | 2 | 0 |
| F8 | 6.9 | F | 2 | 0 |
| F9 | 7.1 | P | 2 | 2 |
| F10 | 7.3 | P | 2 | 2 |
| F11 | 7.8 | F | 2 | 0 |
| F12 | 8.x | P | 1 | 1 |
| Other 56 implied | various | P | — | 56 |
| TOTAL | 68 checkpoints, 0 NAs | — | 90 | 81 |


compliance_pct = round(81 / 90 * 100, 1) = 90.0

band = 'good'  // 90.0 >= 90.0

## 6.4 — Daily audit with NAs

*६.४ — NA सह दैनंदिन ऑडिट*

Example: 5 checkpoints marked NA, all weighted 2 (e.g. it was a Cash holiday — no GRN, no service intake, no high-value movement). Sum of NA weights = 10. So max_score is 90 − 10 = 80, not 90.

उदाहरण: ५ तपासणी बिंदू NA, सर्व वजन २ (उदा. रोख सुट्टी — GRN नाही, सर्व्हिस इनटेक नाही, उच्च-मूल्य हालचाल नाही). NA वजनांची बेरीज = १०. म्हणून max_score ९० नसून ९० − १० = ८०.

// Suppose results: 58 P (weighted), 5 F (weighted), 5 NA (weighted)

// Pass weighted points: 58 × avg(weight) = let's say 70

// Fail weighted points: 5 × avg(weight) = let's say 10

// raw_score = 70  (only passes count toward numerator)

// max_score = 70 + 10 = 80  (NAs excluded from denominator)

// compliance_pct = 70/80 * 100 = 87.5  ->  band = 'fair'

## 6.5 — Weekly audit score formula (Phase 2)

*६.५ — साप्ताहिक ऑडिट गुण सूत्र (टप्पा २)*

computeWeeklyScore(weekly_audit_id):

// 1. Daily-audit-average contribution (out of 68)

week_dates = 7 dates of the week being audited

daily_pcts = []

for each date in week_dates:

daily = SELECT * FROM audits WHERE audit_type='daily' AND audit_date=date

if daily exists AND status='submitted':

daily_pcts.push(daily.compliance_pct)

else:

daily_pcts.push(0.0)  // missing day = 0%

avg_daily = sum(daily_pcts) / 7

daily_contribution = round(avg_daily / 100 * 68, 1)

// 2. Weekly-only checkpoints (max 56 weighted)

weekly_results = SELECT * FROM audit_results WHERE audit_id = weekly_audit_id

weekly_raw = sum of weighted_points where result='P'

weekly_max = sum of cp.weight where result IN ('P', 'F')  // NA excluded

// 3. Combine

total_raw = daily_contribution + weekly_raw

total_max = 68 + weekly_max  // 124 if no weekly NAs

compliance_pct = round(total_raw / total_max * 100, 1)

## 6.6 — Worked example: Workbook Day 5 Section 5.2

*६.६ — उदाहरण: पुस्तिका दिवस ५ विभाग ५.२*

Daily percentages: 92.2, 91.1, 90.0, 88.8, 93.3, 89.7, 91.4. Sum = 636.5. Average = 90.93%. Daily contribution = 90.93 × 0.68 = 61.8 (rounded to 1 decimal).

दैनंदिन टक्केवारी: ९२.२, ९१.१, ९०.०, ८८.८, ९३.३, ८९.७, ९१.४. बेरीज = ६३६.५. सरासरी = ९०.९३%. दैनंदिन योगदान = ९०.९३ × ०.६८ = ६१.८ (एक दशांशात गोलाकार).

Weekly-only: Operations 7/10, Cash 10/16, R&S 4/6, Inventory 22/24. Sum: 43/56. Total: 61.8 + 43 = 104.8 / 124 = 84.5%. Band: Poor.

साप्ताहिक-केवळ: ऑपरेशन्स ७/१०, रोख १०/१६, R&S ४/६, स्टॉक २२/२४. बेरीज: ४३/५६. एकूण: ६१.८ + ४३ = १०४.८ / १२४ = ८४.५%. पट्टी: वाईट.


| WARNING \| सूचना<br>Test scenario: Feed the app the exact Day 5 Section 5.2 data. The app MUST produce 84.5% Poor. If it produces anything else (84.4, 84.6, 85.0 because of rounding), the math is broken. This is the canonical regression test for the score engine.<br>चाचणी परिस्थिती: अॅपला दिवस ५ विभाग ५.२ चा अचूक डेटा द्या. अॅपने ८४.५% वाईट दिलेच पाहिजे. इतर काही दिले (गोलाकारामुळे ८४.४, ८४.६, ८५.०) — गणित मोडले. गुण इंजिनसाठी ही अधिकृत regression test आहे. |
| --- |


## 6.7 — Cumulative weekly cash variance check (CW.7)

*६.७ — एकत्रित साप्ताहिक रोख तफावत तपासणी (CW.७)*

computeCumulativeWeeklyVariance(week_dates):

variances = []  // signed: + over, - short

for each date in week_dates:

daily = SELECT * FROM audits WHERE audit_type='daily' AND audit_date=date

// Stored as separate field on audit (parsed from cash result finding text

//   OR captured explicitly during S7 cash checkpoint)

if daily:

variances.push(daily.cash_variance_rupees)

cumulative = sum(variances)

return |cumulative|  // absolute value for comparison

CW.7 result:

if |cumulative| <= 200: Pass

else: Fail (with cumulative value shown in finding)

To support CW.7, the cash checkpoint 6.5 in the daily audit captures an additional field cash_variance_rupees (positive if over, negative if short). This is stored on the audit row directly. The weekly audit reads these 7 numbers and sums.

CW.७ साठी, दैनंदिन ऑडिटमधला रोख तपासणी बिंदू ६.५ एक अतिरिक्त फील्ड cash_variance_rupees पकडतो (जास्त असेल पॉझिटिव्ह, कमी असेल निगेटिव्ह). हा थेट audit ओळीवर साठवला जातो. साप्ताहिक ऑडिट या ७ संख्या वाचते आणि बेरीज करते.

# Section 7 — Escalation Rules — Decision Engine

*विभाग ७ — एस्केलेशन नियम — निर्णय इंजिन*

## Where the engine runs

*इंजिन कुठे चालते*

After every audit submission (S10 → submit), and after certain CAP state changes, the escalation engine evaluates the seven mandatory triggers from Workbook Day 4 Section 4.6. For every trigger that fires, an entry is inserted into the escalations table, an in-app notification is shown to the target user, and (for urgent triggers) WhatsApp is opened with a pre-filled message.

प्रत्येक ऑडिट सादरीकरणानंतर (S10 → सादर), आणि काही CAP स्थिती बदलांनंतर, एस्केलेशन इंजिन पुस्तिका दिवस ४ विभाग ४.६ मधले ७ अनिवार्य ट्रिगर मूल्यांकन करते. सुरू होणाऱ्या प्रत्येक ट्रिगरसाठी, escalations तक्त्यात नोंद INSERT होते, लक्ष्य वापरकर्त्याला अॅप-अंतर्गत सूचना दाखवली जाते, आणि (तातडीच्या ट्रिगरसाठी) पूर्व-भरलेल्या संदेशासह WhatsApp उघडले जाते.

## The 7 triggers as code logic

*७ ट्रिगर कोड तर्क म्हणून*

runEscalationEngine(audit_id):

a = SELECT * FROM audits WHERE id = audit_id

// Trigger 1: Daily Critical band (< 80%)

if a.audit_type == 'daily' AND a.band == 'critical':

cash_cause = any 6.x checkpoint failed

inv_cause  = any 7.x checkpoint failed

raise(trigger=1, to=GM, urgency='same_night',

via='whatsapp' if (cash_cause OR inv_cause) else 'in_app')

if cash_cause OR inv_cause:

raise(trigger=1, to=Owner, urgency='same_night', via='whatsapp')

// Trigger 2: Same checkpoint failing 5+ days in a week

// (evaluated only when weekly audit is submitted)

if a.audit_type == 'weekly':

for each cp where same checkpoint failed >= 5 of last 7 daily audits:

raise(trigger=2, to=GM, urgency='next_audit', via='in_app')

// Trigger 3: Cash variance > ₹500 single day

if a.audit_type == 'daily' AND abs(a.cash_variance_rupees) > 500:

raise(trigger=3, to=GM, urgency='same_day', via='whatsapp')

// Check yesterday — if also > 500, escalate to Owner

yest = SELECT FROM audits WHERE audit_date=a.audit_date-1day

if yest AND abs(yest.cash_variance_rupees) > 500:

raise(trigger=3, to=Owner, urgency='immediate', via='whatsapp')

// Trigger 4: Inventory variance > 2% of stock value

if a.audit_type == 'weekly' AND a.inventory_variance_pct > 2.0:

raise(trigger=4, to=Owner, urgency='same_day', via='whatsapp')

// Trigger 5: Theft / security / legal — manual flag from finding

for each result in audit_results:

if result.flag_security_concern == 1:

raise(trigger=5, to=Owner, urgency='immediate', via='whatsapp')

// Trigger 6: Customer complaint not store-resolvable — manual

// (raised from CAP detail or audit notes by user action, not auto)

// Trigger 7: Declining trend 3+ consecutive weeks

if a.audit_type == 'weekly':

last4 = SELECT compliance_pct FROM audits WHERE audit_type='weekly'

ORDER BY audit_date DESC LIMIT 4

if len(last4) >= 3 AND last4[0] < last4[1] < last4[2]:

raise(trigger=7, to=Owner, urgency='same_day', via='in_app')

## 7.1 — The raise() function — what it does

*७.१ — raise() कार्य — काय करते*

raise(trigger, to, urgency, via):

msg = buildEscalationMessage(trigger, audit, urgency)  // see 7.2

// 1. Insert escalation row

INSERT INTO escalations (trigger_number, raised_to_user_id,

urgency, what_happened, evidence, impact, requested_action,

raised_at, status='open', source_audit_id, source_cap_id)

// 2. Show in-app notification

showLocalNotification(to, msg.summary)

// 3. If via='whatsapp', open WhatsApp deep link

if via == 'whatsapp':

url = 'https://wa.me/' + to.phone + '?text=' + urlencode(msg.full)

launchExternalUrl(url)

## 7.2 — Escalation message format (4 parts, per Workbook A.5)

*७.२ — एस्केलेशन संदेश स्वरूप (४ भाग, पुस्तिका A.५ नुसार)*

buildEscalationMessage(trigger, audit, urgency):

return {

summary: '[' + urgency.upper() + '] Trigger ' + trigger + ' — ' + audit.audit_date,

full: ('

ESCALATION — ' + trigger_label_en[trigger] + '

1. What happened: ' + msg.what_en + '

2. Evidence: ' + msg.evidence_en + '

3. Impact: ' + msg.impact_en + '

4. Requested action: ' + msg.action_en + '

—

Saagar Traders audit app — auto-generated

Date: ' + audit.audit_date + ' • Tier: ' + audit.audit_type

')

}


| NOTE \| टीप<br>The escalation message must always be in English regardless of the recipient's UI language. Reason: it goes via WhatsApp and may be forwarded to people outside the immediate team (e.g., the bank, the police, Titan corporate) where English is the lingua franca. If the recipient wants to see it in Marathi, they read it in the app under Escalations.<br>प्राप्तकर्त्याच्या UI भाषेची पर्वा न करता एस्केलेशन संदेश नेहमी इंग्रजीत असला पाहिजे. कारण: WhatsApp द्वारे जातो आणि तातडीच्या टीमच्या बाहेरच्या लोकांना अग्रेषित होऊ शकतो (उदा. बँक, पोलिस, टायटन कॉर्पोरेट) जिथे इंग्रजी संपर्क भाषा. प्राप्तकर्त्याला मराठीत पाहायचे असेल, ते अॅपमध्ये एस्केलेशन अंतर्गत वाचतो. |
| --- |


