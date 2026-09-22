# Saagar Audit App — Audits, CAPs & Reports Screens S12–S21 (Spec Section 5 Part 2)
> **Source**: Saagar_P1_App_Spec_v1.docx (Section 5: Screens S12–S21)  
> **Master**: [rain/SPEC_APP.md](../SPEC_APP.md)  
> **Index**: [rain/spec/INDEX.md](INDEX.md)

---

**Screen S14 —** **CAP List**

*स्क्रीन S14 — CAP यादी*

Purpose: List all CAPs visible to the user. SM sees own + assigned. GM and Owner see all.

हेतू: वापरकर्त्याला दिसणाऱ्या सर्व CAPs ची यादी. SM स्वतःचे + नेमलेले पाहतो. GM आणि मालक सर्व पाहतात.

### Layout

*मांडणी*

- Top: filter chips — "All", "Open", "Done (pending verify)", "Aged ⚠", "Closed".
*वर: फिल्टर चिप्स — "सर्व", "उघडे", "पूर्ण (पडताळणी प्रलंबित)", "जुनी ⚠", "बंद".*

- Search box.
*शोध पेटी.*

- List of CAPs sorted by deadline ascending (aged first, then nearest deadline).
*मुदतीनुसार चढत्या क्रमाने CAPs ची यादी (जुन्या प्रथम, मग सर्वात जवळची मुदत).*

- Each list item shows: CAP ID, problem statement (truncated), responsible user, deadline (color-coded: red if past, amber if today/tomorrow, green if 3+ days away), status badge.
*प्रत्येक यादी आयटम दाखवते: CAP आयडी, समस्या विधान (कापलेले), जबाबदार वापरकर्ता, मुदत (रंग-कोडित: लाल मागे, पिवळा आज/उद्या, हिरवा ३+ दिवस दूर), स्थिती बॅज.*

- FAB (floating action button) bottom-right: "+ New CAP".
*FAB (फ्लोटिंग अॅक्शन बटण) तळ-उजवीकडे: "+ नवीन CAP".*

### Behaviour

*वर्तन*

- Tap on list item → S16 (CAP Detail).
*यादी आयटमवर टॅप → S16 (CAP तपशील).*

- Tap on FAB → S15 (CAP Create).
*FAB वर टॅप → S15 (CAP तयार करा).*

- Auto-refresh every time the user enters this screen — query refreshes from local DB.
*वापरकर्ता या स्क्रीनवर येताच प्रत्येक वेळी आपोआप ताजे — लोकल DB मधून क्वेरी ताजी.*

**Screen S15 —** **CAP Create**

*स्क्रीन S15 — CAP तयार करा*

Purpose: Walk the user through creating a new CAP using the 10-field template from Workbook Appendix A.3.

हेतू: पुस्तिकेच्या परिशिष्ट A.३ मधले १०-फील्ड टेम्पलेट वापरून वापरकर्त्याला नवीन CAP तयार करण्यात मदत.

### Layout (vertical scroll, all fields visible)

*मांडणी (वर्टिकल स्क्रोल, सर्व फील्ड दिसतात)*

- CAP ID — auto-generated, read-only (e.g. "CAP-2026-W22-03").
*CAP आयडी — आपोआप तयार, फक्त-वाचन (उदा. "CAP-2026-W22-03").*

- Originating finding — auto-populated if launched from a Fail; editable otherwise.
*मूळ निष्कर्ष — नापासातून सुरू केले असेल आपोआप भरलेले; अन्यथा संपादनयोग्य.*

- Problem statement (1 sentence) — required text input.
*समस्या विधान (१ वाक्य) — आवश्यक मजकूर इनपुट.*

- 5 Whys — 5 separate text inputs, labeled Why 1 to Why 5. Why 1 required; Why 2-5 strongly recommended but not enforced.
*पाच का? — ५ वेगळे मजकूर इनपुट, का? १ ते का? ५ लेबल. का? १ आवश्यक; का? २-५ जोरदार शिफारस पण सक्ती नाही.*

- Root cause (1-2 sentences) — required text input.
*मूळ कारण (१-२ वाक्ये) — आवश्यक मजकूर इनपुट.*

- Action steps — dynamic list, 3 to 5 items, each a one-line text input. Add/remove rows.
*कृती पावले — डायनॅमिक यादी, ३ ते ५ आयटम, प्रत्येक एक-ओळ मजकूर इनपुट. ओळी जोडा/काढा.*

- Responsible (CAP Owner) — dropdown of users (SM, GM, Owner only; CROs not selectable).
*जबाबदार (CAP मालक) — वापरकर्त्यांचा ड्रॉपडाउन (फक्त SM, GM, मालक; सीआरओ निवडण्यायोग्य नाहीत).*

- Deadline — date picker, default origin_audit.audit_date + 7 days.
*मुदत — तारीख निवडक, डीफॉल्ट origin_audit.audit_date + ७ दिवस.*

- Verification method — dropdown of checkpoints (typically the same one that originally failed).
*पडताळणी पद्धत — तपासणी बिंदूंचा ड्रॉपडाउन (सहसा मूळ नापास झालेलाच).*

- "Create CAP / CAP तयार करा" button at bottom — disabled until required fields filled.
*तळाशी "CAP तयार करा" बटण — आवश्यक फील्ड भरल्याशिवाय अक्षम.*

### Behaviour on Create tap

*तयार करा टॅपवर वर्तन*

- Generate next CAP ID using format CAP-{year}-W{ISO_week}-{nn} where nn is the next sequence for that week.
*CAP-{year}-W{ISO_week}-{nn} स्वरूप वापरून पुढची CAP आयडी तयार करा, जिथे nn त्या आठवड्याची पुढची संख्या.*

- INSERT caps row with all fields and status='open', opened_at=now.
*सर्व फील्ड आणि status='open', opened_at=now सह caps ओळ INSERT.*

- INSERT cap_actions rows for each step.
*प्रत्येक पावलासाठी cap_actions ओळी INSERT.*

- INSERT cap_log entry: event='created', from_status=NULL, to_status='open'.
*cap_log नोंद INSERT: event='created', from_status=NULL, to_status='open'.*

- Push notification to responsible user (if not the creator) — "New CAP assigned: [problem statement]".
*जबाबदार वापरकर्त्याला पुश सूचना (निर्मात्या नसेल तर) — "नवीन CAP नेमली: [समस्या विधान]".*

- Navigate to S16 (CAP Detail) showing the newly created CAP.
*नव्याने तयार झालेली CAP दाखवणाऱ्या S16 (CAP तपशील) कडे जा.*

### Workbook reference

*पुस्तिका संदर्भ*

- Workbook Day 4 Section 4.4 (CAP template) and Section 4.2 (5 Whys). App enforces both.
*पुस्तिका दिवस ४ विभाग ४.४ (CAP टेम्पलेट) आणि विभाग ४.२ (५ का?). अॅप दोघांची अंमलबजावणी करते.*

**Screen S12 —** **Audit History**

*स्क्रीन S12 — ऑडिट इतिहास*

List of audits visible to the user (SM sees own; GM and Owner see all).

वापरकर्त्याला दिसणाऱ्या ऑडिटची यादी (SM स्वतःचे पाहतो; GM आणि मालक सर्व).

- Filter chips: All, Daily, Weekly (Phase 2), Monthly (Phase 3), Unverified, By date range.
*फिल्टर चिप्स: सर्व, दैनंदिन, साप्ताहिक (टप्पा २), मासिक (टप्पा ३), अपडताळलेले, तारीख श्रेणीनुसार.*

- Each item: date, type, auditor, compliance %, band (color), fail count, status.
*प्रत्येक आयटम: तारीख, प्रकार, ऑडिटर, अनुपालन %, पट्टी (रंग), नापास संख्या, स्थिती.*

- Tap → S13 (Audit Detail).
*टॅप → S13 (ऑडिट तपशील).*

- Sort by date desc (most recent first). Show 30 per page, infinite scroll.
*तारखेनुसार उतरत्या क्रमाने (सर्वात अलीकडचे प्रथम). दर पानाला ३० दाखवा, अनंत स्क्रोल.*

**Screen S13 —** **Audit Detail**

*स्क्रीन S13 — ऑडिट तपशील*

Read-only view of a submitted audit. Identical layout to S10 (Review) but no edit, no submit.

सादर केलेल्या ऑडिटचे फक्त-वाचन दृश्य. S10 (पुनरावलोकन) सारखीच मांडणी पण संपादन नाही, सादरीकरण नाही.

- Header shows audit type, date, auditor, submission time.
*हेडर ऑडिट प्रकार, तारीख, ऑडिटर, सादरीकरण वेळ दाखवते.*

- Score card.
*गुण कार्ड.*

- SOP breakdown table.
*एसओपी विभागणी तक्ता.*

- All Pass/Fail/NA results expandable per SOP.
*एसओपीनुसार सर्व Pass/Fail/NA निकाल विस्तारणारे.*

- All Fails with finding text, photos (tap to view full), and linked CAP.
*सर्व नापास निष्कर्ष मजकूर, फोटो (पूर्ण पाहण्यासाठी टॅप), आणि जोडलेल्या CAP सह.*

- GM/Owner sees additional "Verify" button if audit is unverified (Phase 2+).
*GM/मालकाला ऑडिट अपडताळलेली असेल अतिरिक्त "पडताळा" बटण दिसते (टप्पा २+).*

- "Export PDF / PDF निर्यात" button at bottom — generates audit PDF, opens share sheet.
*तळाशी "PDF निर्यात" बटण — ऑडिट PDF तयार करते, शेअर शीट उघडते.*

- "Share to WhatsApp" button (Phase 1) — opens WhatsApp with PDF attached.
*"WhatsApp ला शेअर" बटण (टप्पा १) — PDF जोडून WhatsApp उघडते.*

**Screen S16 —** **CAP Detail**

*स्क्रीन S16 — CAP तपशील*

Full CAP view with all 10 fields, action checklist, log timeline, and role-appropriate action buttons.

सर्व १० फील्ड, कृती चेकलिस्ट, लॉग टाइमलाइन, आणि भूमिकेला योग्य कृती बटणांसह पूर्ण CAP दृश्य.

- Status badge prominent at top: Open / Done / Verified / Closed / Aged / Reopened.
*वर ठळक स्थिती बॅज: उघडे / पूर्ण / पडताळलेले / बंद / जुने / पुन्हा उघडलेले.*

- Deadline countdown: "3 days left" / "Overdue by 2 days".
*मुदत काउंटडाउन: "३ दिवस उरले" / "२ दिवस मुदत संपली".*

- All 10 fields displayed read-only except where the current user can act.
*सर्व १० फील्ड फक्त-वाचन दिसतात — सध्याचा वापरकर्ता कृती करू शकतो तिथे वगळून.*

- Action steps: checklist with checkboxes; checkable only by responsible user.
*कृती पावले: चेकबॉक्ससह चेकलिस्ट; फक्त जबाबदार वापरकर्त्याकडून तपासण्यायोग्य.*

- Timeline section at bottom: every cap_log entry as a row with timestamp, actor, event.
*तळाशी टाइमलाइन विभाग: प्रत्येक cap_log नोंद वेळ-शिक्का, अभिनेता, घटना सह ओळ म्हणून.*

- Action buttons (visible by role and state):
*कृती बटणे (भूमिका आणि स्थितीनुसार दिसतात):*

- • Responsible user, status=open, all actions done → "Mark CAP Done" → S17.
*• जबाबदार वापरकर्ता, status=open, सर्व कृती पूर्ण → "CAP पूर्ण म्हणून खूण करा" → S17.*

- • GM/Owner, status=done → "Verify CAP" → S18.
*• GM/मालक, status=done → "CAP पडताळा" → S18.*

- • GM/Owner, status=verified → "Close CAP" → S19.
*• GM/मालक, status=verified → "CAP बंद करा" → S19.*

- • Anyone, status=open and deadline approaching → "Request Extension" (GM/Owner approves).
*• कोणीही, status=open आणि मुदत जवळ → "मुदतवाढ विनंती" (GM/मालक मंजूर).*

- • Owner, any closed CAP → "Reopen CAP".
*• मालक, कोणतीही बंद CAP → "CAP पुन्हा उघडा".*

**Screen S17 —** **CAP — Mark Done**

*स्क्रीन S17 — CAP — पूर्ण म्हणून खूण*

Quick modal. Confirms all action steps are checked. Asks for optional "done notes". Optional photo of completion evidence.

जलद मोडल. सर्व कृती पावले तपासली आहेत याची पुष्टी. ऐच्छिक "पूर्ण नोंदी" मागते. पूर्णता पुराव्याचा ऐच्छिक फोटो.

- On confirm: UPDATE caps.status='done', done_at=now, done_by=current user. INSERT cap_log: event='marked_done'.
*पुष्टीवर: caps.status='done', done_at=now, done_by=सध्याचा वापरकर्ता UPDATE. cap_log INSERT: event='marked_done'.*

- Push notification to GM: "CAP [id] marked done by [SM] — awaiting verification."
*GM ला पुश सूचना: "CAP [id] [SM] ने पूर्ण म्हणून खूण केली — पडताळणीची वाट."*

**Screen S18 —** **CAP — Verify**

*स्क्रीन S18 — CAP — पडताळणी*

GM/Owner re-runs the verification_method checkpoint and confirms it now passes. Mandatory photo if requires_photo_on_fail=1 on that checkpoint.

GM/मालक verification_method तपासणी बिंदू पुन्हा चालवतो आणि आता पास झाला याची पुष्टी करतो. त्या तपासणी बिंदूवर requires_photo_on_fail=1 असेल अनिवार्य फोटो.

- If verification passes: UPDATE caps.status='verified', verified_at=now, verified_by. cap_log: 'verified'.
*पडताळणी पास झाली: caps.status='verified', verified_at=now, verified_by UPDATE. cap_log: 'verified'.*

- If verification fails: prompt to either extend the CAP or re-open at Plan phase (see Workbook Day 4 Section 4.3).
*पडताळणी अयशस्वी: एकतर CAP वाढवा किंवा योजना टप्प्यावर पुन्हा उघडा (पुस्तिका दिवस ४ विभाग ४.३ पाहा).*

**Screen S19 —** **CAP — Close**

*स्क्रीन S19 — CAP — बंद करा*

Final close after verification. Quick confirmation dialog. Updates status to 'closed', closed_at=now, closed_by.

पडताळणीनंतर अंतिम बंद. जलद पुष्टी डायलॉग. status 'closed' अद्यतनित, closed_at=now, closed_by.

**Screen S20 —** **Reports List**

*स्क्रीन S20 — अहवाल यादी*

Phase 2+ feature. List of weekly reports. Phase 3 adds monthly reports.

टप्पा २+ फीचर. साप्ताहिक अहवालांची यादी. टप्पा ३ मासिक अहवाल जोडतो.

- Filter by type, year, month. Each item shows: week ending date, compliance %, band, headline.
*प्रकार, वर्ष, महिन्यानुसार फिल्टर. प्रत्येक आयटम दाखवते: आठवडा संपण्याची तारीख, अनुपालन %, पट्टी, शीर्षक.*

- Owner-only: green dot if read by Owner, gray dot if unread.
*फक्त-मालक: मालकाने वाचले असेल हिरवा ठिपका, अवाचलेले असेल राखाडी ठिपका.*

**Screen S21 —** **Report Detail**

*स्क्रीन S21 — अहवाल तपशील*

Read-view of a weekly/monthly report. Matches the structure in Workbook Day 3 Section 3.6 exactly.

साप्ताहिक/मासिक अहवालाचे वाचन दृश्य. पुस्तिकेच्या दिवस ३ विभाग ३.६ मधल्या रचनेशी अचूक जुळते.

- Sections: headline, compliance table, trend block, findings, patterns, CAPs, escalations, signature.
*विभाग: शीर्षक, अनुपालन तक्ता, कल खंड, निष्कर्ष, पॅटर्न, CAPs, एस्केलेशन, सही.*

- PDF export button at bottom.
*तळाशी PDF निर्यात बटण.*

- "Mark as Read" updates reports.read_by_owner_at if user is Owner.
*वापरकर्ता मालक असेल "वाचले म्हणून खूण" reports.read_by_owner_at अद्यतनित.*

