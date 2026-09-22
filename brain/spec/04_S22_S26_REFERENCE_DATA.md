# Saagar Audit App — Reference Data Screens S22–S26 & Content (Spec Sections 5 & 11)
> **Source**: Saagar_P1_App_Spec_v1.docx (Section 5: Screens S22–S26 & Section 11: Reference Content)  
> **Master**: [rain/SPEC_APP.md](../SPEC_APP.md)  
> **Index**: [rain/spec/INDEX.md](INDEX.md)

---

## Part 1: Screen Specifications (S22–S26)

**Screen S22 —** **Reference Tab — Index**

*स्क्रीन S22 — संदर्भ टॅब — अनुक्रमणिका*

Simple list of reference content sections, each linking to its own screen.

संदर्भ सामग्री विभागांची साधी यादी, प्रत्येक स्वतःच्या स्क्रीनला लिंक.

- 4 cards: Rating Scale (S23), Escalation Triggers (S24), Strong vs Weak Evidence (S25), Bilingual Glossary (S26).
*४ कार्ड: रेटिंग स्केल (S23), एस्केलेशन ट्रिगर (S24), मजबूत वि. दुर्बल पुरावा (S25), द्विभाषी शब्दकोश (S26).*

**Screen S23 —** **Reference — Rating Scale**

*स्क्रीन S23 — संदर्भ — रेटिंग स्केल*

- Renders the 5-band table from Workbook Appendix A.4.
*पुस्तिका परिशिष्ट A.४ मधला ५-पट्टी तक्ता रेंडर करते.*

- Tier-specific targets table.
*स्तर-विशिष्ट लक्ष्य तक्ता.*

**Screen S24 —** **Reference — Escalation Triggers**

*स्क्रीन S24 — संदर्भ — एस्केलेशन ट्रिगर*

- Renders the 7-trigger table from Workbook Appendix A.5.
*पुस्तिका परिशिष्ट A.५ मधला ७-ट्रिगर तक्ता रेंडर करते.*

- Escalation message format (4 parts).
*एस्केलेशन संदेश स्वरूप (४ भाग).*

**Screen S25 —** **Reference — Evidence**

*स्क्रीन S25 — संदर्भ — पुरावा*

- Strong vs Weak evidence two-column table from Workbook Appendix A.6.
*पुस्तिका परिशिष्ट A.६ मधला मजबूत वि. दुर्बल दोन-स्तंभ तक्ता.*

**Screen S26 —** **Reference — Glossary**

*स्क्रीन S26 — संदर्भ — शब्दकोश*

- Searchable table of 65 EN-MR-Meaning rows from Workbook Appendix A.7.
*पुस्तिका परिशिष्ट A.७ मधल्या ६५ EN-MR-अर्थ ओळींचा शोधण्यायोग्य तक्ता.*

- Live search filter on top.
*वर लाइव्ह सर्च फिल्टर.*



---

## Part 2: Reference Tab Full Content (Section 11)

# Section 11 — Reference Tab Content

*विभाग ११ — संदर्भ टॅब सामग्री*

## What this section is

*हा विभाग काय*

The Reference tab is the app's built-in version of Workbook Appendices A.4 through A.7. The Store Manager needs these at 9:15 PM when paper cards have been lost or are unreachable. The four screens (S23–S26) render four reference sub-modules. The content for these screens comes from JSON files shipped with the app, so they can be updated in future versions without code changes.

संदर्भ टॅब म्हणजे अॅपची पुस्तिकेच्या परिशिष्ट A.४ ते A.७ ची अंतर्निहित आवृत्ती. कागदी कार्ड हरवलेली किंवा पोचण्यायोग्य नसताना ९:१५ ला स्टोअर मॅनेजरला हे लागतात. चार स्क्रीन (S23–S26) चार संदर्भ उप-मॉड्यूल रेंडर करतात. या स्क्रीनसाठी सामग्री अॅपसोबत आलेल्या JSON फाइलमधून येते, त्यामुळे कोड बदलाशिवाय भविष्यातील आवृत्त्यांत अद्ययावत करता येतात.

## 11.1 — S23 Rating Scale content

*११.१ — S23 रेटिंग स्केल सामग्री*

Source: Workbook Appendix A.4. Render as two stacked sections.

स्रोत: पुस्तिका परिशिष्ट A.४. दोन स्टॅक केलेले विभाग म्हणून रेंडर.

### Section 1: 5 Compliance Bands table

*विभाग १: ५ अनुपालन पट्ट्या तक्ता*

- Columns: Band (color), Range, Action.
*स्तंभ: पट्टी (रंग), श्रेणी, कृती.*

- Rows: Excellent (≥95%), Good (90–94.9%), Fair (85–89.9%), Poor (80–84.9%), Critical (<80%).
*ओळी: उत्कृष्ट (≥९५%), चांगले (९०–९४.९%), बरे (८५–८९.९%), वाईट (८०–८४.९%), क्रिटिकल (<८०%).*

- Each band is color-coded matching the workbook: Green / Navy / Amber / Red / Red.
*प्रत्येक पट्टी पुस्तिकेशी जुळणारी रंग-कोडित: हिरवा / नेव्ही / पिवळा / लाल / लाल.*

### Section 2: Tier Targets table

*विभाग २: स्तर लक्ष्ये तक्ता*

- Rows: Tier 1 daily (SM, 90%+, 81/90), Tier 2 weekly (GM, 92%+, 114/124), Tier 3 monthly (Owner, 95%+, qualitative).
*ओळी: टियर १ दैनंदिन (SM, ९०%+, ८१/९०), टियर २ साप्ताहिक (GM, ९२%+, ११४/१२४), टियर ३ मासिक (मालक, ९५%+, गुणात्मक).*

### Section 3: Critical reminder banner

*विभाग ३: क्रिटिकल स्मरण बॅनर*

- Warning callout: "Always score with one decimal. 89.9 is FAIR, not Good."
*इशारा कॉलआउट: "नेहमी एका दशांशासह गुण द्या. ८९.९ बरे आहे, चांगले नाही."*

## 11.2 — S24 Escalation Triggers content

*११.२ — S24 एस्केलेशन ट्रिगर सामग्री*

Source: Workbook Appendix A.5. Render as three sections.

स्रोत: पुस्तिका परिशिष्ट A.५. तीन विभाग म्हणून रेंडर.

### Section 1: 7 Triggers table

*विभाग १: ७ ट्रिगर तक्ता*

- Columns: #, Trigger, Threshold, Escalate to, When.
*स्तंभ: #, ट्रिगर, मर्यादा, कोणाकडे, कधी.*

- 7 rows: Daily Critical (<80%, GM→Owner if Cash/Inv, same night), Same checkpoint 5+ days (GM, weekly audit), Cash > ₹500 (GM, same day), Inventory > 2% (Owner, same day), Theft/security/legal (Owner, immediate), Customer complaint not store-resolvable (Owner, same day), 3+ weeks declining (Owner, week 3 audit).
*७ ओळी: दैनंदिन क्रिटिकल (<८०%, रोख/स्टॉक असेल GM→मालक, त्याच रात्री), एकच तपासणी बिंदू ५+ दिवस (GM, साप्ताहिक ऑडिट), रोख > ₹५०० (GM, त्याच दिवशी), स्टॉक > २% (मालक, त्याच दिवशी), चोरी/सुरक्षा/कायदेशीर (मालक, तातडीने), स्टोअर-न-सुटणारी ग्राहक तक्रार (मालक, त्याच दिवशी), ३+ आठवडे घसरता कल (मालक, आठवडा ३ ऑडिट).*

### Section 2: 4-Part Message Format

*विभाग २: ४-भाग संदेश स्वरूप*

- (1) What happened — 1 sentence. (2) Evidence. (3) Operational impact. (4) Requested action.
*(१) काय झाले — १ वाक्य. (२) पुरावा. (३) कार्यवाहक परिणाम. (४) मागितलेली कृती.*

### Section 3: Examples

*विभाग ३: उदाहरणे*

- 3 worked example messages — one for each common trigger (1, 3, 5).
*३ उदाहरण संदेश — प्रत्येक सामान्य ट्रिगरसाठी एक (१, ३, ५).*

## 11.3 — S25 Evidence content

*११.३ — S25 पुरावा सामग्री*

Source: Workbook Appendix A.6. Two-column comparison table.

स्रोत: पुस्तिका परिशिष्ट A.६. दोन-स्तंभ तुलना तक्ता.

- Left column: 8 Strong evidence types (timestamped photo, signed register, POS report, Sales Buddy upload, physical count, two-signature, bank slip, email trail).
*डावा स्तंभ: ८ मजबूत पुरावा प्रकार (वेळ-शिक्क्यासह फोटो, सही केलेले रजिस्टर, POS रिपोर्ट, सेल्स बडी अपलोड, प्रत्यक्ष मोजणी, दोन-सही, बँक स्लिप, ईमेल ट्रेल).*

- Right column: 8 Weak evidence types (verbal, "manager confirmed", memory, photo without timestamp, unsigned doc, second-hand, deferred verification, assumption).
*उजवा स्तंभ: ८ दुर्बल पुरावा प्रकार (तोंडी, "मॅनेजरने सांगितले", स्मरण, वेळ-शिक्का नसलेला फोटो, सही नसलेले दस्त, दुसर्‍याकडून, पुढे ढकललेली पडताळणी, गृहीतक).*

- Bottom warning: "Every finding must rest on the left column. Findings supported only by right-column items are reporting, not auditing."
*तळ इशारा: "प्रत्येक निष्कर्ष डाव्या स्तंभावर विसावला पाहिजे. फक्त उजव्या स्तंभातील आयटमने आधारित निष्कर्ष म्हणजे रिपोर्टिंग, ऑडिट नव्हे."*

## 11.4 — S26 Glossary content

*११.४ — S26 शब्दकोश सामग्री*

Source: Workbook Appendix A.7. 65 EN-MR-Meaning rows. Live-searchable.

स्रोत: पुस्तिका परिशिष्ट A.७. ६५ EN-MR-अर्थ ओळी. लाइव्ह-शोधण्यायोग्य.

### Search behaviour

*शोध वर्तन*

- Search box at top. As user types, filter rows where EN, MR, or Meaning contains the query (case-insensitive).
*वर शोध पेटी. वापरकर्ता टाइप करतो, EN, MR, किंवा अर्थ क्वेरी असलेल्या ओळी फिल्टर करा (केस-इन्सेन्सिटिव्ह).*

- Empty search shows all 65 rows.
*रिकामा शोध सर्व ६५ ओळी दाखवतो.*

- If user has Marathi UI, the search input accepts both Latin and Devanagari characters.
*वापरकर्त्याकडे मराठी UI असेल, शोध इनपुट लॅटिन आणि देवनागरी दोन्ही वर्ण स्वीकारतो.*

### Storage

*साठवण*

- assets/reference/glossary.json — array of objects {en, mr, meaning_en, meaning_mr}.
*assets/reference/glossary.json — ऑब्जेक्टचा अॅरे {en, mr, meaning_en, meaning_mr}.*

- Updatable via app update (drop new JSON, ship new APK).
*अॅप अद्यतनाद्वारे अद्ययावत करण्यायोग्य (नवीन JSON टाका, नवीन APK पाठवा).*

