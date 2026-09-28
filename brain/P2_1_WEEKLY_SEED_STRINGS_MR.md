# P2-1 Weekly Seed Strings — EN + MR (CANONICAL: Appendix A.2)

**Author**: Claude · **Date**: 2026-09-27 · **REVISED** (see R1 note below)
**Source of truth**: Workbook **Appendix A.2 — Weekly Audit Score Sheet** (lines 6081–6159). This is the set used in the §5.2 / T2.1 canonical 84.5% simulation, and is confirmed by the Spec's own §4.4 sample rows (CW.7 = "Cumulative weekly variance within ±₹200", IW.1 = "Full storage area count — two signatures" both match A.2). **Seed EXACTLY this set. This is Antigravity's Option 1.**

> **R1 CONTRADICTION FLAGGED & RESOLVED (2026-09-27):** The Workbook defines the 36 weekly checkpoints TWICE with different wording — Appendix A.2 (score sheet) vs the Day-3 narrative tables §3.3–3.6. They diverge (e.g. A.2 O.1 = "Weekly training session"; §3.3 O.1 = "Next week's staff schedule"). **Canonical = Appendix A.2**, because the Spec §4.4 sample rows align with A.2. The §3.3–3.6 narrative is a divergent/earlier variant — do NOT seed from it. (A prior version of this file mistakenly used the §3.3 wording; corrected here.) Recommend annotating §3.3–3.6 as "see Appendix A.2 for canonical scoring wording" during the Workbook cleanup.

> **Evidence note:** Appendix A.2 is a checkbox sheet with NO evidence column. The `evidence_mr` below is concise Claude-authored helper text (guidance shown to the auditor), flagged as such — owner may refine later; it is not a scoring input. Checkpoint `text_*` is the canonical, load-bearing string.

## New SOP folder
| id | name_en | name_mr | weight | is_critical |
|---|---|---|---|---|
| SOP9 | Operations | कार्यात्मक कामकाज | 1 | 0 |

## Operations Weekly → SOP9 (O.1–O.10, weight 1, requires_photo_on_fail=0)
| id | text_en | text_mr | evidence_mr (helper) |
|---|---|---|---|
| O.1 | Weekly training session conducted (≥ 30 min) | साप्ताहिक प्रशिक्षण सत्र घेतले (≥ ३० मिनिटे) | प्रशिक्षण लॉग — विषय, कालावधी, सीआरओ स्वाक्षऱ्या |
| O.2 | All POS terminals, printers, scanners working | सर्व पीओएस टर्मिनल, प्रिंटर, स्कॅनर कार्यरत | प्रत्येक टर्मिनल/प्रिंटर/स्कॅनरची प्रत्यक्ष चाचणी |
| O.3 | AC, lighting, security cameras operational | एसी, प्रकाशयोजना, सुरक्षा कॅमेरे कार्यरत | दृश्य तपासणी — एसी, दिवे, सर्व कॅमेरे सुरू |
| O.4 | First-aid kit stocked and expiries valid | प्रथमोपचार पेटी भरलेली आणि मुदती वैध | प्रथमोपचार पेटी तपासणी — वस्तू व मुदती |
| O.5 | Fire safety AMC current | अग्निसुरक्षा एएमसी चालू (अद्ययावत) | अग्निसुरक्षा एएमसी प्रमाणपत्र/पावती — वैध तारीख |
| O.6 | Consumables stocked for next week | पुढील आठवड्यासाठी उपभोग्य वस्तूंचा साठा | उपभोग्य साठा यादी — पुढील आठवड्यासाठी पुरेसा |
| O.7 | Vendor invoices reconciled — no overdues > 15 days | विक्रेता बिले ताळमेळ — १५ दिवसांहून जास्त थकबाकी नाही | विक्रेता बिल नोंदवही — १५ दिवसांवरील थकबाकी नाही |
| O.8 | Premises rent, utilities, statutory dues current | जागेचे भाडे, सुविधा देयके, वैधानिक देणी चालू | भाडे/सुविधा/वैधानिक देयकांच्या पावत्या — चालू |
| O.9 | Attendance register reconciled with biometric | हजेरी नोंदवही बायोमेट्रिकशी ताळमेळ | हजेरी वि. बायोमेट्रिक — बाजूबाजूने तुलना |
| O.10 | Customer feedback box opened, entries logged | ग्राहक अभिप्राय पेटी उघडली, नोंदी नोंदवल्या | अभिप्राय पेटी उघडली; नोंदी नोंदवहीत |

## Cash Weekly ★ → SOP6 (CW.1–CW.8, weight 2, requires_photo_on_fail=1)
| id | text_en | text_mr | evidence_mr (helper) |
|---|---|---|---|
| CW.1 | Bank passbook reconciled with system | बँक पासबुक प्रणालीशी ताळमेळ | बँक पासबुक वि. प्रणाली — रुपयापर्यंत ताळमेळ |
| CW.2 | Safe physical count matches system (GM) | तिजोरीची प्रत्यक्ष मोजणी प्रणालीशी जुळते (जीएम) | जीएमकडून तिजोरी प्रत्यक्ष मोजणी वि. प्रणाली |
| CW.3 | All deposits have stamped bank receipts | सर्व जमा रकमांवर बँकेच्या शिक्क्याच्या पावत्या | सर्व जमा पावत्यांवर बँक शिक्का |
| CW.4 | Petty cash reconciled month-to-date | किरकोळ रोख महिना-आजवर ताळमेळ | किरकोळ रोख महिना-आजवर ताळमेळ + मूळ पावत्या |
| CW.5 | POS user log / override audit trail reviewed | पीओएस वापरकर्ता लॉग / ओव्हरराइड ऑडिट ट्रेल तपासला | पीओएस ओव्हरराइड लॉग — प्रत्येकास ऑडिट ट्रेल |
| CW.6 | GST output/input reconciled | जीएसटी आउटपुट/इनपुट ताळमेळ | जीएसटी आउटपुट/इनपुट ताळमेळ पत्रक |
| CW.7 | Cumulative weekly variance within ±₹200 | संचयी साप्ताहिक तफावत ±₹२०० च्या आत | संचयी साप्ताहिक तफावत गणना — ±₹२०० च्या आत |
| CW.8 | No CRO refund rate > 5% | कोणत्याही सीआरओचा परतावा दर ५% पेक्षा जास्त नाही | सीआरओ-निहाय परतावा दर — ५% पेक्षा जास्त नाही |

## Reporting & Service Weekly → SOP8 (RS.1–RS.6, weight 1, requires_photo_on_fail=0)
| id | text_en | text_mr | evidence_mr (helper) |
|---|---|---|---|
| RS.1 | Sales Buddy report sent to Titan (Sun EOD) | सेल्स बडी अहवाल टायटनला पाठवला (रविवार दिवसअखेर) | टायटनला पाठवलेल्या सेल्स बडी अहवालाचा वेळ-शिक्का |
| RS.2 | Sales summary emailed to Owner (Mon 11 AM) | विक्री सारांश मालकाला ईमेल (सोमवार सकाळी ११) | मालकाला विक्री सारांश ईमेल — सोमवार सकाळी ११ पर्यंत |
| RS.3 | Service centre dispatch reconciled | सर्व्हिस सेंटर पाठवणी ताळमेळ | सर्व्हिस सेंटर पाठवणी यादी वि. दुकान नोंदी |
| RS.4 | Callbacks logged in CRM | कॉलबॅक सीआरएममध्ये नोंदवले | सीआरएममध्ये सर्व कॉलबॅक नोंदी |
| RS.5 | Complaints closure ≥ 80% | तक्रार निवारण ≥ ८०% | तक्रार नोंदवही — ७ दिवसांत बंद ≥ ८०% |
| RS.6 | NPS weekly trend reviewed | एनपीएस साप्ताहिक कल तपासला | एनपीएस साप्ताहिक कल अहवाल — मागील आठवड्याशी तुलना |

## Inventory Weekly ★ → SOP7 (IW.1–IW.12, weight 2, requires_photo_on_fail=1)
| id | text_en | text_mr | evidence_mr (helper) |
|---|---|---|---|
| IW.1 | Full storage area count — two signatures | संपूर्ण साठवण क्षेत्र मोजणी — दोन स्वाक्षऱ्या | संपूर्ण साठवण मोजणी पत्रक — दोन स्वाक्षऱ्या |
| IW.2 | GRNs reconciled | जीआरएन ताळमेळ | आठवड्यातील सर्व जीआरएन ताळमेळ नोंदी |
| IW.3 | Damage dispositioned | नुकसान निकाली काढले | नुकसान नोंदवही — प्रत्येक नोंद निकाली |
| IW.4 | Service intake reconciliation | सर्व्हिस इनटेक ताळमेळ | सर्व्हिस इनटेक — आवक व जावक संतुलित |
| IW.5 | Returns/refunds pattern — no CRO clustering | परतावा/परतफेड नमुना — सीआरओ-निहाय गठ्ठा नाही | परतावा नोंदवही — सीआरओ-निहाय गठ्ठा नाही |
| IW.6 | Slow-moving 90+ days flagged | ९०+ दिवसांची मंद वस्तू ध्वजांकित | एजिंग अहवाल — ९०+ दिवस वस्तू ध्वजांकित |
| IW.7 | High-value 60+ days flagged for Owner | उच्च-मूल्य ६०+ दिवस मालकासाठी ध्वजांकित | उच्च-मूल्य (६०+ दिवस) यादी — मालकासाठी |
| IW.8 | Write-offs GM-signed | निर्लेखनांवर जीएम स्वाक्षरी | आठवड्याचे निर्लेखन — जीएम स्वाक्षरी |
| IW.9 | Supplier debit notes tracked | पुरवठादार डेबिट नोट मागोवा | पुरवठादार डेबिट नोट नोंदवही — मागोवा |
| IW.10 | Brand-wise velocity reviewed | ब्रँड-निहाय विक्री गती तपासली | ब्रँड-निहाय विक्री गती अहवाल |
| IW.11 | Display rotation checked (fortnightly) | डिस्प्ले फेरबदल तपासले (पंधरवड्याने) | डिस्प्ले फेरबदल तपासणी पत्रक (पंधरवडा) |
| IW.12 | Stock takeout/return reconciled | स्टॉक बाहेर काढणे/परत ताळमेळ | स्टॉक बाहेर/परत नोंदी — ताळमेळ |

---
**Component totals (Appendix A.2, lines 6166–6173):** Operations 10 × 1 = 10 · Cash Weekly 8 × 2 = 16 ★ · Reporting & Service 6 × 1 = 6 · Inventory Weekly 12 × 2 = 24 ★ → **weekly-only weighted = 56**; + 68 daily-average = **124 max**. Matches T2.1.
