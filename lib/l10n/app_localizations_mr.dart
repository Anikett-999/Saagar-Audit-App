// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'सागर ऑडिट';

  @override
  String get navHome => 'मुख्यपृष्ठ';

  @override
  String get navAudits => 'ऑडिट्स';

  @override
  String get navCaps => 'सीएपी (CAPs)';

  @override
  String get navReference => 'संदर्भ';

  @override
  String get navSettings => 'सेटिंग्ज';

  @override
  String get navReports => 'अहवाल';

  @override
  String get btnStartAudit => 'ऑडिट सुरू करा';

  @override
  String get btnSubmit => 'सादर करा';

  @override
  String get btnSaveDraft => 'मसुदा जतन करा';

  @override
  String get btnCancel => 'रद्द करा';

  @override
  String get btnContinue => 'पुढे चालू ठेवा';

  @override
  String get btnBack => 'मागे';

  @override
  String get btnNext => 'पुढे';

  @override
  String get btnPrevious => 'मागील';

  @override
  String get btnPass => 'पास';

  @override
  String get btnFail => 'नापास';

  @override
  String get btnNa => 'लागू नाही';

  @override
  String get btnAddPhoto => 'फोटो जोडा';

  @override
  String get btnRetake => 'पुन्हा फोटो घ्या';

  @override
  String get btnUsePhoto => 'फोटो वापरा';

  @override
  String get btnCreateCap => 'CAP तयार करा';

  @override
  String get btnMarkDone => 'पूर्ण झाले';

  @override
  String get btnVerify => 'पडताळणी करा';

  @override
  String get btnCloseCap => 'CAP बंद करा';

  @override
  String get btnReopen => 'पुन्हा उघडा';

  @override
  String get btnExtend => 'मुदत वाढवा';

  @override
  String get btnEscalate => 'वरिष्ठांकडे पाठवा';

  @override
  String get btnExportPdf => 'PDF एक्सपोर्ट करा';

  @override
  String get btnShareWhatsapp => 'व्हॉट्सॲपवर पाठवा';

  @override
  String get btnLogin => 'लॉगिन';

  @override
  String get btnLogout => 'लॉगआउट';

  @override
  String get btnChangePin => 'पिन बदला';

  @override
  String get btnAdd => 'जोडा';

  @override
  String get btnEdit => 'संपादित करा';

  @override
  String get btnDelete => 'हटवा';

  @override
  String get btnDeactivate => 'निष्क्रिय करा';

  @override
  String get bandExcellent => 'उत्कृष्ट';

  @override
  String get bandGood => 'चांगले';

  @override
  String get bandFair => 'समाधानकारक';

  @override
  String get bandPoor => 'खराब';

  @override
  String get bandCritical => 'गंभीर';

  @override
  String get capStatusOpen => 'उघडे';

  @override
  String get capStatusDone => 'पूर्ण';

  @override
  String get capStatusVerified => 'पडताळलेले';

  @override
  String get capStatusClosed => 'बंद';

  @override
  String get capStatusAged => 'मुदत संपलेले';

  @override
  String get capStatusReopened => 'पुन्हा उघडलेले';

  @override
  String get auditStatusDraft => 'मसुदा';

  @override
  String get auditStatusSubmitted => 'सादर केले';

  @override
  String get auditStatusVerified => 'पडताळलेले';

  @override
  String get auditStatusHidden => 'लपवलेले';

  @override
  String get errWrongPin => 'चुकीचा पिन. कृपया पुन्हा प्रयत्न करा.';

  @override
  String errLocked(int seconds) {
    return 'अनेक चुकीचे प्रयत्न. $seconds सेकंदात पुन्हा प्रयत्न करा.';
  }

  @override
  String get errRequiredField => 'हे भरणे अनिवार्य आहे.';

  @override
  String get errFutureDate => 'ऑडिट तारीख भविष्यातील असू शकत नाही.';

  @override
  String get errPhotoRequired =>
      'कॅश आणि इन्व्हेंटरी दोषांसाठी फोटो पुरावा अनिवार्य आहे.';

  @override
  String get errFindingRequired => 'कृपया दोषाचे वर्णन करा (कमाल २०० अक्षरे).';

  @override
  String get errNoInternet =>
      'इंटरनेट नाही — स्थानिक पातळीवर जतन केले. पुन्हा कनेक्ट झाल्यावर सिंक होईल.';

  @override
  String get errCapDeadlinePassed => 'CAP ची मुदत संपली आहे. वाढवता येत नाही.';

  @override
  String get errCannotEditSubmitted =>
      'सादर केलेले ऑडिट संपादित करता येत नाही.';

  @override
  String get okAuditSubmitted => 'ऑडिट यशस्वीरित्या सादर केले.';

  @override
  String get okCapCreated => 'CAP तयार केले.';

  @override
  String get okCapMarkedDone => 'CAP पूर्ण म्हणून चिन्हांकित केले.';

  @override
  String get okCapVerified => 'CAP पडताळले गेले.';

  @override
  String get okCapClosed => 'CAP बंद केले.';

  @override
  String get okPinChanged => 'पिन बदलला गेला.';

  @override
  String get okSynced => 'क्लाउडसह सिंक झाले.';

  @override
  String get s02Title => 'तुमची भाषा निवडा';

  @override
  String get s02ChooseEnglish => 'English';

  @override
  String get s02ChooseMarathi => 'मराठी';

  @override
  String get s02Note => 'तुम्ही हे नंतर सेटिंग्जमधून बदलू शकता.';

  @override
  String get s03Title => 'पहिली वेळ सेटअप';

  @override
  String get s03Subtitle => 'स्वागत आहे. चला तुमचे ओनर खाते तयार करूया.';

  @override
  String get s03OwnerName => 'ओनरचे नाव';

  @override
  String get s03OwnerPin => '४-अंकी पिन निवडा';

  @override
  String get s03ReenterPin => 'तुमचा पिन पुन्हा टाका';

  @override
  String get s03ConfirmPin => 'पिन पुष्टी करा';

  @override
  String get s03PinsMismatch => 'पिन जुळत नाहीत. नवीन पिन निवडा.';

  @override
  String get s03NameTooShort => 'कृपया तुमचे नाव प्रविष्ट करा (२+ अक्षरे).';

  @override
  String get s03AddTeamLater => 'मी माझी टीम नंतर जोडेन';

  @override
  String get s04SelectName => 'तुमचे नाव निवडा';

  @override
  String get s04EnterPin => 'तुमचा ४-अंकी पिन टाका';

  @override
  String get s04ForgotPin => 'पिन विसरलात?';

  @override
  String get s04ForgotPinHelp =>
      'ओनरला सेटिंग्ज → वापरकर्ते मधून तुमचा पिन रीसेट करण्यास सांगा.';

  @override
  String s04LockedCountdown(int seconds) {
    return 'खाते लॉक झाले. $seconds सेकंदात पुन्हा प्रयत्न करा.';
  }

  @override
  String s04WrongPinAttemptsLeft(int attempts) {
    return 'चुकीचा पिन. $attempts प्रयत्न शिल्लक आहेत.';
  }

  @override
  String s04TooManyAttempts(int seconds) {
    return 'अनेक चुकीचे प्रयत्न. $seconds सेकंदात पुन्हा प्रयत्न करा.';
  }

  @override
  String s05Hello(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get s05RoleOwner => 'ओनर (OWNER)';

  @override
  String get s05RoleSm => 'स्टोअर मॅनेजर (SM)';

  @override
  String get s05RoleGm => 'जनरल मॅनेजर (GM)';

  @override
  String get s05TodayDailyAudit => 'आजचे दैनिक ऑडिट';

  @override
  String get s05NotStartedYet => 'तुम्ही आजचे ऑडिट अद्याप सुरू केलेले नाही.';

  @override
  String get s05NotStartedAdmin => 'आजचे दैनिक ऑडिट अद्याप सुरू झालेले नाही.';

  @override
  String get s05StartDailyAudit => 'दैनिक ऑडिट सुरू करा';

  @override
  String get s05ResumeDraft => 'मसुदा पुन्हा सुरू करा';

  @override
  String get s05DraftInProgress =>
      'मसुदा ऑडिट सुरू आहे. तपासणी पुढे चालू ठेवण्यासाठी पुन्हा सुरू करा.';

  @override
  String get s05SubmittedStatus => 'सादर केले';

  @override
  String get s05DailyAuditsRunBySm =>
      'दैनिक ऑडिट स्टोअर मॅनेजरद्वारे केले जाते.';

  @override
  String get s05StatusNotStarted => 'सुरू नाही';

  @override
  String get s05StatusInProgress => 'प्रगतीपथावर';

  @override
  String get s05StatusSubmitted => 'सादर केले';

  @override
  String get s05AuditHistoryTitle => 'ऑडिट इतिहास';

  @override
  String get s05AuditHistorySubtitle => 'मागील दैनिक ऑडिट पहा';

  @override
  String get s05CapsTitle => 'सीएपी (CAPs)';

  @override
  String get s05CapsSubtitle => 'सुधारात्मक कृती योजना';

  @override
  String get s05ReferenceTitle => 'संदर्भ माहिती';

  @override
  String get s05ReferenceSubtitle =>
      'रेटिंग स्केल, एस्केलेशन ट्रिगर्स, शब्दकोश';

  @override
  String get s05SettingsTitle => 'सेटिंग्ज';

  @override
  String get s05SettingsSubtitle => 'कर्मचारी, वापरकर्ते, भाषा, बॅकअप';

  @override
  String s05ComingSoon(String feature) {
    return '$feature ही सुविधा टप्पा १ आठवडा ३+ साठी नियोजित आहे. सध्या दैनिक ऑडिट (S06–S11) सक्रिय आहे.';
  }

  @override
  String get s06Title => 'दैनिक ऑडिट सुरू करा';

  @override
  String get s06AuditDate => 'ऑडिट तारीख';

  @override
  String get s06StoreLabel => 'स्टोअर';

  @override
  String get s06CrosOnDuty => 'ड्युटीवरील कर्मचारी (CRO)';

  @override
  String get s06SelectAtLeastOneCro =>
      'कृपया किमान एक ड्युटीवरील कर्मचारी निवडा.';

  @override
  String get s06BeginAudit => 'ऑडिट सुरू करा';

  @override
  String s07CheckpointNumber(int current, int total) {
    return 'चेकपॉइंट $current / $total';
  }

  @override
  String get s07Pass => 'पास';

  @override
  String get s07Fail => 'नापास';

  @override
  String get s07Na => 'लागू नाही';

  @override
  String get s07NaReasonPrompt => 'हा चेकपॉइंट का लागू नाही?';

  @override
  String get s07NaReasonHint => 'कारण प्रविष्ट करा (किमान ३ अक्षरे)...';

  @override
  String get s07Previous => 'मागे';

  @override
  String get s07Next => 'पुढे';

  @override
  String get s07FinishReview => 'पूर्ण करा आणि पुनरावलोकन';

  @override
  String get s08Title => 'नापास तपशील';

  @override
  String get s08FindingLabel => 'दोषाचे वर्णन';

  @override
  String get s08FindingHint => 'दोष किंवा त्रुटीचे वर्णन करा...';

  @override
  String get s08CroInvolved => 'संबंधित कर्मचारी (ऐच्छिक)';

  @override
  String get s08PhotoEvidence => 'फोटो पुरावा';

  @override
  String get s08PhotoRequiredNotice => 'या चेकपॉइंटसाठी फोटो अनिवार्य आहे.';

  @override
  String get s08SaveFail => 'दोष जतन करा';

  @override
  String get s10Title => 'पुनरावलोकन आणि सादर करा';

  @override
  String get s10ScoreCard => 'ऑडिट गुण';

  @override
  String get s10SopBreakdown => 'एसओपी (SOP) तपशील';

  @override
  String s10FailsTitle(int count) {
    return 'आढळलेले दोष ($count)';
  }

  @override
  String get s10NotesLabel => 'सामान्य टिप्पण्या (ऐच्छिक)';

  @override
  String get s10IncompleteWarning =>
      'सादर करण्यापूर्वी सर्व ६८ चेकपॉइंट तपासणे आवश्यक आहे.';

  @override
  String get s10SubmitButton => 'ऑडिट सादर करा';

  @override
  String get s10MissingPhotoWarning =>
      'अनिवार्य दोषांसाठी फोटो पुरावा जोडलेला नाही.';

  @override
  String get s11Title => 'ऑडिट सादर केले';

  @override
  String get s11ConfirmationMessage =>
      'आजचे दैनिक ऑडिट यशस्वीरित्या नोंदवले गेले आहे.';

  @override
  String get s11ScoreLabel => 'अंतिम गुण';

  @override
  String get s11BandLabel => 'श्रेणी';

  @override
  String get s11OfflineSyncNotice => 'ऑनलाइन आल्यावर सिंक होईल';

  @override
  String get s11ReturnHome => 'मुख्यपृष्ठावर परत जा';

  @override
  String get s27Title => 'सेटिंग्ज';

  @override
  String get s27AccountSection => 'खाते';

  @override
  String get s27ManagementSection => 'व्यवस्थापन';

  @override
  String get s27PreferencesSection => 'प्राधान्ये आणि डेटा';

  @override
  String get s27ManageCrosTitle => 'सीआरओ व्यवस्थापन';

  @override
  String get s27ManageCrosSubtitle =>
      'कर्मचारी पाहा, जोडा, संपादित करा आणि निष्क्रिय करा';

  @override
  String get s27ManageUsersTitle => 'वापरकर्ता व्यवस्थापन';

  @override
  String get s27ManageUsersSubtitle =>
      'SM/GM जोडा, PIN रीसेट करा, प्रवेश नियंत्रित करा';

  @override
  String get s27ChangePinTitle => 'PIN बदला';

  @override
  String get s27ChangePinSubtitle => 'तुमचा ४-अंकी सुरक्षा PIN बदला';

  @override
  String get s27LanguageTitle => 'भाषा / Language';

  @override
  String get s27LanguageSubtitle => 'इंग्रजी किंवा मराठी निवडा';

  @override
  String get s27BackupExportTitle => 'बॅकअप व निर्यात';

  @override
  String get s27BackupExportSubtitle =>
      'डेटाबेस JSON निर्यात आणि समक्रमण स्थिती';

  @override
  String get s27AboutTitle => 'अॅपबद्दल माहिती';

  @override
  String get s27AboutSubtitle => 'आवृत्ती, स्टोअर माहिती आणि एसओपी तपशील';

  @override
  String get s27AboutDialogTitle => 'प्राधान्य १ ऑडिटबद्दल';

  @override
  String get s27AboutDialogBody =>
      'सागर ट्रेडर्स एसओपी ऑडिट अॅप्लिकेशन\nटायटन वर्ल्ड (WLMHW) आणि हेलिओस (HEMW)\nलातूर, महाराष्ट्र\nआवृत्ती १.०.० (टप्पा १)';

  @override
  String get s27CloseDialog => 'बंद करा';

  @override
  String get s27OwnerBadge => 'मालक';

  @override
  String get s27GmBadge => 'महाव्यवस्थापक';

  @override
  String get s27SmBadge => 'स्टोअर व्यवस्थापक';

  @override
  String get s28Title => 'सीआरओ व्यवस्थापन';

  @override
  String get s28EmptyState =>
      'कोणतेही सीआरओ आढळले नाहीत. पहिला सीआरओ जोडण्यासाठी + टॅप करा.';

  @override
  String get s28StatusActive => 'सक्रिय';

  @override
  String get s28StatusInactive => 'निष्क्रिय';

  @override
  String get s28CounterLabel => 'काउंटर';

  @override
  String get s28CounterTitan => 'टायटन';

  @override
  String get s28CounterHelios => 'हेलिओस';

  @override
  String get s28ShiftLabel => 'शिफ्ट';

  @override
  String get s28ShiftMorning => 'सकाळ';

  @override
  String get s28ShiftAfternoon => 'दुपार';

  @override
  String get s28ShiftFlexible => 'लवचिक';

  @override
  String get s28AddCroTitle => 'नवीन सीआरओ जोडा';

  @override
  String get s28EditCroTitle => 'सीआरओ संपादित करा';

  @override
  String get s28NameLabel => 'सीआरओचे पूर्ण नाव';

  @override
  String get s28NameHint => 'उदा. राहुल शिंदे';

  @override
  String get s28NameRequired => 'कृपया वैध नाव प्रविष्ट करा (किमान २ अक्षरे)';

  @override
  String get s28StatusLabel => 'सक्रिय स्थिती';

  @override
  String get s28ActiveHelp => 'सक्रिय सीआरओ ऑडिट ड्रॉपडाउनमध्ये दिसतील';

  @override
  String get s28SaveButton => 'जतन करा';

  @override
  String get s28CancelButton => 'रद्द करा';

  @override
  String get s28EditAction => 'संपादित करा';

  @override
  String get s28DeactivateAction => 'निष्क्रिय करा';

  @override
  String get s28ReactivateAction => 'पुन्हा सक्रिय करा';

  @override
  String get s28DeactivateConfirmTitle => 'सीआरओ निष्क्रिय करायचा का?';

  @override
  String get s28DeactivateConfirmBody =>
      'हा सीआरओ नवीन ऑडिटमधून लपवला जाईल, परंतु मागील ऑडिट नोंदी सुरक्षित राहतील.';

  @override
  String get s28CroAddedSuccess => 'सीआरओ यशस्वीरित्या जोडला';

  @override
  String get s28CroUpdatedSuccess => 'सीआरओ यशस्वीरित्या अद्यतनित केला';

  @override
  String get s28CroDeactivatedSuccess => 'सीआरओ निष्क्रिय केला';

  @override
  String get s28CroReactivatedSuccess => 'सीआरओ पुन्हा सक्रिय केला';

  @override
  String get s29Title => 'वापरकर्ता व्यवस्थापन';

  @override
  String get s29EmptyState => 'कोणतेही वापरकर्ते आढळले नाहीत.';

  @override
  String get s29AddUserTitle => 'नवीन वापरकर्ता जोडा';

  @override
  String get s29NameLabel => 'पूर्ण नाव';

  @override
  String get s29NameHint => 'उदा. सचिन जाधव';

  @override
  String get s29NameRequired => 'कृपया वैध नाव प्रविष्ट करा (२–५० अक्षरे)';

  @override
  String get s29RoleLabel => 'भूमिका';

  @override
  String get s29RoleSm => 'स्टोअर व्यवस्थापक (SM)';

  @override
  String get s29RoleGm => 'महाव्यवस्थापक (GM)';

  @override
  String get s29PhoneLabel => 'फोन नंबर (ऐच्छिक)';

  @override
  String get s29PhoneHint => '१०-अंकी मोबाइल नंबर';

  @override
  String get s29PinLabel => '४-अंकी PIN';

  @override
  String get s29PinConfirmLabel => '४-अंकी PIN ची पुष्टी करा';

  @override
  String get s29PinRequired => 'कृपया ४-अंकी संख्यात्मक PIN प्रविष्ट करा';

  @override
  String get s29PinMismatch => 'PIN जुळत नाहीत';

  @override
  String get s29SaveButton => 'जतन करा';

  @override
  String get s29CancelButton => 'रद्द करा';

  @override
  String get s29UserAddedSuccess => 'वापरकर्ता यशस्वीरित्या तयार केला';

  @override
  String get s29ResetPinAction => 'PIN रीसेट करा';

  @override
  String s29ResetPinTitle(String name) {
    return '$name साठी PIN रीसेट करा';
  }

  @override
  String get s29NewPinLabel => 'नवीन ४-अंकी PIN';

  @override
  String get s29ConfirmNewPinLabel => 'नवीन PIN ची पुष्टी करा';

  @override
  String get s29ResetPinSuccess => 'PIN यशस्वीरित्या रीसेट केला';

  @override
  String get s29DeactivateAction => 'निष्क्रिय करा';

  @override
  String get s29ReactivateAction => 'पुन्हा सक्रिय करा';

  @override
  String get s29DeactivateConfirmTitle => 'वापरकर्ता निष्क्रिय करायचा का?';

  @override
  String get s29DeactivateConfirmBody =>
      'हा वापरकर्ता आता लॉग इन करू शकणार नाही, परंतु सर्व मागील ऑडिट नोंदी सुरक्षित राहतील.';

  @override
  String get s29CannotDeactivateOwner =>
      'तपशील §S29 नुसार मालक खाते निष्क्रिय केले जाऊ शकत नाही.';

  @override
  String get s29UserDeactivatedSuccess => 'वापरकर्ता निष्क्रिय केला';

  @override
  String get s29UserReactivatedSuccess => 'वापरकर्ता पुन्हा सक्रिय केला';

  @override
  String get s29OwnerRestrictedAccess => 'फक्त मालकासाठी प्रवेश मर्यादित आहे.';

  @override
  String get s29StatusActive => 'सक्रिय';

  @override
  String get s29StatusInactive => 'निष्क्रिय';

  @override
  String get s30Title => 'PIN बदला';

  @override
  String get s30InstructionText =>
      'तुमची ओळख पडताळण्यासाठी तुमचा सध्याचा PIN प्रविष्ट करा, नंतर तुमचा नवीन ४-अंकी सुरक्षा PIN प्रविष्ट करा आणि पुष्टी करा.';

  @override
  String get s30CurrentPinLabel => 'सध्याचा ४-अंकी PIN';

  @override
  String get s30CurrentPinHint => 'तुमचा सध्याचा PIN प्रविष्ट करा';

  @override
  String get s30CurrentPinRequired =>
      'कृपया तुमचा सध्याचा ४-अंकी PIN प्रविष्ट करा';

  @override
  String get s30CurrentPinIncorrect => 'सध्याचा PIN चुकीचा आहे';

  @override
  String get s30NewPinLabel => 'नवीन ४-अंकी PIN';

  @override
  String get s30NewPinHint => 'नवीन ४-अंकी PIN प्रविष्ट करा';

  @override
  String get s30NewPinRequired => 'कृपया ४-अंकी संख्यात्मक PIN प्रविष्ट करा';

  @override
  String get s30NewPinSameAsCurrent =>
      'नवीन PIN सध्याच्या PIN पेक्षा वेगळा असावा';

  @override
  String get s30ConfirmPinLabel => 'नवीन ४-अंकी PIN ची पुष्टी करा';

  @override
  String get s30ConfirmPinHint => 'नवीन ४-अंकी PIN पुन्हा प्रविष्ट करा';

  @override
  String get s30PinMismatch => 'नवीन PIN आणि पुष्टी जुळत नाहीत';

  @override
  String get s30SaveButton => 'PIN अपडेट करा';

  @override
  String get s30PinChangedSuccess => 'PIN यशस्वीरित्या बदलला';

  @override
  String get s31Title => 'भाषा / Language';

  @override
  String get s31Subtitle => 'तुमची पसंतीची अॅप भाषा निवडा';

  @override
  String get s31Instruction =>
      'संपूर्ण अनुप्रयोगात वापरण्यासाठी भाषा निवडा. बदल त्वरित लागू होतात आणि तुमच्या प्रोफाइलवर जतन केले जातात.';

  @override
  String get s31EnglishTitle => 'English';

  @override
  String get s31EnglishSubtitle => 'डीफॉल्ट सिस्टम भाषा';

  @override
  String get s31MarathiTitle => 'मराठी (Marathi)';

  @override
  String get s31MarathiSubtitle => 'स्थानिक भाषा (प्रादेशिक भाषा)';

  @override
  String get s31CurrentLanguageBadge => 'सध्याची';

  @override
  String get s31LanguageUpdatedSuccess => 'भाषा पसंती जतन केली';

  @override
  String get s32Title => 'बॅकअप व निर्यात';

  @override
  String get s32Subtitle => 'स्थानिक SQLite डेटाबेस निर्यात आणि क्लाउड समक्रमण';

  @override
  String get s32ExportCardTitle => 'स्थानिक डेटाबेस निर्यात करा (JSON)';

  @override
  String get s32ExportCardDesc =>
      'तुमच्या डिव्हाइसच्या Downloads डिरेक्टरीमध्ये सर्व १४ SQLite टेबल्स टाइमस्टॅम्प केलेल्या JSON फाईलमध्ये निर्यात करा. अॅप अपडेटपूर्वी मॅन्युअल बॅकअपसाठी उपयुक्त.';

  @override
  String get s32ExportSecurityNotice =>
      'सुरक्षा सूचना: निर्यात केलेल्या बॅकअपमध्ये ऑडिट ट्रेल, निरीक्षणे आणि bcrypt सुरक्षा हॅशेस असतात. ही फाईल सुरक्षितपणे साठवा आणि ट्रान्सफर करा.';

  @override
  String get s32ExportButton => 'डेटाबेस JSON निर्यात करा';

  @override
  String get s32Exporting => 'डेटाबेस निर्यात होत आहे...';

  @override
  String get s32ExportSuccessTitle => 'निर्यात यशस्वी झाली';

  @override
  String s32ExportSuccessMessage(
      int records, int tables, String fileName, String path) {
    return 'बॅकअप यशस्वीरित्या जतन केला ($tables टेबल्समध्ये $records नोंदी).\n\nफाईल: $fileName\nमार्ग:\n$path';
  }

  @override
  String s32ExportFailed(String error) {
    return 'डेटाबेस निर्यात अयशस्वी: $error';
  }

  @override
  String get s32CloudSyncTitle => 'क्लाउड समक्रमण (Firestore)';

  @override
  String get s32CloudSyncDesc =>
      'Google Cloud Firestore द्वारे स्वयंचलित मल्टी-डिव्हाइस समक्रमण आणि क्लाउड डेटा संचयन.';

  @override
  String get s32CloudSyncStatusLabel =>
      'स्थिती: ऑफलाइन-फर्स्ट मोड (स्थानिक SQLite)';

  @override
  String get s32CloudSyncPhase4Notice =>
      'फेज ४ मध्ये उपलब्ध होईल. सर्व ऑर्डिट्स आणि सेटिंग्ज या डिव्हाइसवर सुरक्षितपणे स्थानिकरित्या साठवल्या आहेत.';

  @override
  String get s32CloudSyncComingSoonBadge => 'फेज ४ मध्ये येत आहे';

  @override
  String get s32ForceSyncButton => 'क्लाउड सिंक करा';

  @override
  String get s32AboutCardTitle => 'सागर ऑडिट अॅपबद्दल';

  @override
  String get s32AboutVersion => 'आवृत्ती: 0.1.0+1 (फेज १ बेसलाइन)';

  @override
  String get s32AboutStore =>
      'दुकाने: टायटन वर्ल्ड (WLMHW) आणि हेलिओस (HEMW), लातूर';

  @override
  String get s32AboutSpec => 'तपशील: सागर P1 रिटेल ऑडिट स्पेक v1';

  @override
  String get s32OkButton => 'ठीक आहे';

  @override
  String get s32CopyPath => 'पाथ कॉपी करा';

  @override
  String get s32PathCopied => 'बॅकअप पाथ क्लिपबोर्डवर कॉपी केला';

  @override
  String get s32ShareFile => 'फाईल शेअर / जतन करा';

  @override
  String get s14Title => 'सुधारात्मक कृती योजना (CAP)';

  @override
  String get s14Subtitle => 'ऑडिट निष्कर्षांचा मागोवा आणि निराकरण';

  @override
  String get s14SearchHint => 'समस्या किंवा CAP आयडी शोधा...';

  @override
  String get s14FilterAll => 'सर्व';

  @override
  String get s14FilterOpen => 'उघडे';

  @override
  String get s14FilterDone => 'पूर्ण (पडताळणी प्रलंबित)';

  @override
  String get s14FilterAged => 'जुनी ⚠';

  @override
  String get s14FilterClosed => 'बंद';

  @override
  String get s14EmptyTitle => 'कोणतेही CAP सापडले नाही';

  @override
  String get s14EmptyDesc =>
      'निवडलेल्या फिल्टरशी जुळणारी कोणतीही सुधारात्मक कृती नाही.';

  @override
  String get s14NewCapButton => 'नवीन CAP';

  @override
  String get s14StatusOpen => 'उघडे';

  @override
  String get s14StatusDone => 'पूर्ण';

  @override
  String get s14StatusVerified => 'पडताळलेले';

  @override
  String get s14StatusClosed => 'बंद';

  @override
  String get s14StatusAged => 'जुने';

  @override
  String get s14StatusReopened => 'पुन्हा उघडलेले';

  @override
  String s14DeadlineOverdue(String date) {
    return 'मुदत संपली ($date)';
  }

  @override
  String s14DeadlineDueSoon(String date) {
    return 'लवकरच मुदत ($date)';
  }

  @override
  String s14DeadlineOk(String date) {
    return 'मुदत: $date';
  }

  @override
  String s14ResponsiblePrefix(String name) {
    return 'जबाबदार: $name';
  }

  @override
  String get s15Title => 'नवीन सुधारात्मक कृती योजना';

  @override
  String get s15Subtitle => '१०-फील्ड मूळ कारण आणि कृती टेम्पलेट';

  @override
  String get s15CapIdPreview => 'CAP आयडी (आपोआप तयार)';

  @override
  String get s15SectionOrigin => '१. मूळ निष्कर्ष';

  @override
  String get s15OriginAudit => 'मूळ ऑडिट';

  @override
  String get s15OriginCheckpoint => 'नापास तपासणी बिंदू';

  @override
  String get s15SelectAudit => 'ऑडिट निवडा';

  @override
  String get s15SelectCheckpoint => 'तपासणी बिंदू निवडा';

  @override
  String get s15NoAuditsFound =>
      'कोणतेही ऑडिट सापडले नाही. प्रथम ऑडिट पूर्ण करा.';

  @override
  String get s15SectionProblem => '२. समस्या आणि ५-का? विश्लेषण';

  @override
  String get s15ProblemStatement => 'समस्या विधान';

  @override
  String get s15ProblemStatementHint => 'काय नापास झाले ते वर्णन करा (१ वाक्य)';

  @override
  String get s15ProblemRequired => 'समस्या विधान आवश्यक आहे';

  @override
  String get s15Why1 => 'का? १ (प्राथमिक कारण)';

  @override
  String get s15Why1Hint => 'ही परिस्थिती का घडली?';

  @override
  String get s15Why1Required => 'का? १ आवश्यक आहे';

  @override
  String get s15Why2 => 'का? २ (पर्यायी)';

  @override
  String get s15Why2Hint => 'असे का घडले?';

  @override
  String get s15Why3 => 'का? ३ (पर्यायी)';

  @override
  String get s15Why3Hint => 'असे का घडले?';

  @override
  String get s15Why4 => 'का? ४ (पर्यायी)';

  @override
  String get s15Why4Hint => 'असे का घडले?';

  @override
  String get s15Why5 => 'का? ५ (पर्यायी)';

  @override
  String get s15Why5Hint => 'असे का घडले?';

  @override
  String get s15RootCause => 'मूळ कारण';

  @override
  String get s15RootCauseHint => 'पद्धतशीर मूळ कारण (१-२ वाक्ये)';

  @override
  String get s15RootCauseRequired => 'मूळ कारण आवश्यक आहे';

  @override
  String get s15SectionActions => '३. कृती पावले (३ ते ५ पावले)';

  @override
  String s15StepLabel(int number) {
    return 'पाऊल $number';
  }

  @override
  String get s15StepHint => 'कृती पावलाचे वर्णन';

  @override
  String get s15StepRequired => 'कृती पाऊल रिक्त असू शकत नाही';

  @override
  String get s15AddStep => 'पाऊल जोडा';

  @override
  String get s15MinStepsNotice => 'किमान ३ पावले आवश्यक आहेत';

  @override
  String get s15MaxStepsReached => 'जास्तीत जास्त ५ पावले गाठली';

  @override
  String get s15SectionOwnership => '४. मालकी आणि पडताळणी';

  @override
  String get s15ResponsibleUser => 'जबाबदार (CAP मालक)';

  @override
  String get s15SelectResponsible => 'जबाबदार वापरकर्ता निवडा (SM, GM, मालक)';

  @override
  String get s15ResponsibleRequired => 'जबाबदार वापरकर्ता आवश्यक आहे';

  @override
  String get s15Deadline => 'मुदत (लक्ष्य पूर्णता तारीख)';

  @override
  String get s15SelectDate => 'तारीख निवडा';

  @override
  String get s15VerificationMethod => 'पडताळणी पद्धत';

  @override
  String get s15VerificationMethodHint => 'पूर्णतेची पडताळणी कशी केली जाईल?';

  @override
  String get s15VerificationRequired => 'पडताळणी पद्धत आवश्यक आहे';

  @override
  String get s15CreateButton => 'CAP तयार करा';

  @override
  String get s15Creating => 'CAP तयार करत आहे...';

  @override
  String get s15CreatedSuccess => 'CAP यशस्वीरित्या तयार केली';

  @override
  String s15AuditDropdownItem(String date, String type) {
    return 'ऑडिट $date ($type)';
  }

  @override
  String s15ErrorPrefix(String message) {
    return 'त्रुटी: $message';
  }

  @override
  String get s16Title => 'CAP तपशील';

  @override
  String get s16Subtitle => 'सुधारात्मक कृती योजना';

  @override
  String get s16NotFound => 'CAP सापडली नाही';

  @override
  String get s16BackToCaps => 'CAP यादीकडे परत';

  @override
  String get s16StatusOpen => 'उघडे';

  @override
  String get s16StatusDone => 'पूर्ण (पडताळणी प्रलंबित)';

  @override
  String get s16StatusVerified => 'पडताळलेले';

  @override
  String get s16StatusClosed => 'बंद';

  @override
  String get s16StatusAged => 'जुने';

  @override
  String get s16StatusReopened => 'पुन्हा उघडलेले';

  @override
  String s16OverdueByDays(int days) {
    return '$days दिवस मुदत संपली';
  }

  @override
  String get s16DueToday => 'आज मुदत आहे';

  @override
  String get s16DueTomorrow => '१ दिवस उरला (उद्या मुदत)';

  @override
  String s16DaysRemaining(int days) {
    return '$days दिवस उरले';
  }

  @override
  String s16CompletedOn(String date) {
    return '$date रोजी पूर्ण';
  }

  @override
  String s16DeadlineLabel(String date) {
    return 'मुदत: $date';
  }

  @override
  String get s16SectionOrigin => '१. मूळ माहिती';

  @override
  String get s16OriginAudit => 'मूळ ऑडिट';

  @override
  String get s16OriginCheckpoint => 'मूळ तपासणी बिंदू';

  @override
  String get s16PatternBadge => 'वारंवार समस्या (पॅटर्न)';

  @override
  String get s16SectionAnalysis => '२. समस्या आणि ५-का? विश्लेषण';

  @override
  String get s16ProblemStatement => 'समस्या विधान';

  @override
  String s16WhyLabel(int number) {
    return 'का? $number';
  }

  @override
  String get s16RootCause => 'मूळ कारण';

  @override
  String get s16SectionOwnership => '३. मालकी आणि पडताळणी';

  @override
  String get s16ResponsibleUser => 'जबाबदार (CAP मालक)';

  @override
  String get s16CreatedBy => 'निर्मिती केली';

  @override
  String s16OpenedAt(String date) {
    return 'उघडले: $date';
  }

  @override
  String get s16VerificationMethod => 'पडताळणी पद्धत';

  @override
  String s16AgedCount(int count) {
    return 'जुने: $count वेळा';
  }

  @override
  String s16ExtensionCount(int count) {
    return 'मुदतवाढ: $count';
  }

  @override
  String s16LatestExtensionReason(String reason) {
    return 'कारण: $reason';
  }

  @override
  String s16SectionActionSteps(int done, int total) {
    return '४. कृती पावले ($done/$total)';
  }

  @override
  String s16StepLabel(int number) {
    return 'पाऊल $number';
  }

  @override
  String s16ActionDoneBy(String user, String date) {
    return '$user द्वारे $date रोजी पूर्ण';
  }

  @override
  String get s16OnlyResponsibleCanToggle =>
      'केवळ नेमलेला जबाबदार वापरकर्ता कृती पावले तपासू शकतो.';

  @override
  String get s16CapAlreadyDoneNotice =>
      'CAP आधीच पूर्ण म्हणून चिन्हांकित आहे. कृती पावले संपादित करता येत नाहीत.';

  @override
  String get s16MarkDoneButton => 'CAP पूर्ण म्हणून खूण करा';

  @override
  String get s16CompleteAllStepsToMarkDone =>
      'पूर्ण म्हणून खूण करण्यासाठी सर्व कृती पावले पूर्ण करा';

  @override
  String get s16VerifyButton => 'CAP पडताळा';

  @override
  String get s16CloseButton => 'CAP बंद करा';

  @override
  String get s16RequestExtensionButton => 'मुदतवाढ विनंती';

  @override
  String get s16ReopenButton => 'CAP पुन्हा उघडा';

  @override
  String get s16Phase2Notice => 'टप्पा २ (लवकरच येत आहे)';

  @override
  String get s16SectionTimeline => '५. घटना टाइमलाइन';

  @override
  String get s16EventCreated => 'CAP तयार केली';

  @override
  String get s16EventActionDone => 'कृती पाऊल पूर्ण केले';

  @override
  String get s16EventActionUndone => 'कृती पाऊल पुन्हा उघडले';

  @override
  String get s16EventMarkedDone => 'पूर्ण म्हणून खूण केली (पडताळणी प्रलंबित)';

  @override
  String get s16EventVerified => 'व्यवस्थापनाने पडताळले';

  @override
  String get s16EventClosed => 'CAP बंद केली';

  @override
  String get s16EventExtended => 'मुदत वाढवली';

  @override
  String get s16EventAged => 'जुने म्हणून नोंदवले';

  @override
  String get s16EventReopened => 'CAP पुन्हा उघडली';

  @override
  String get s16ActorSystem => 'प्रणाली';

  @override
  String s16ActorPrefix(String user) {
    return '$user द्वारे';
  }

  @override
  String s16ActionToggleFailed(String error) {
    return 'कृती पाऊल अद्यतनित करण्यात अयशस्वी: $error';
  }

  @override
  String get s16RefreshTooltip => 'रिफ्रेश करा';

  @override
  String get s16WhysSubheader => '५ का? (५ व्हाय)';

  @override
  String get s16NoTimelineEntries => 'कोणत्याही टाइमलाइन नोंदी नाहीत';

  @override
  String get s17Title => 'CAP पूर्ण म्हणून खूण करा';

  @override
  String get s17Subtitle => 'पूर्ण झाल्याची पुष्टी करा आणि पडताळणीसाठी पाठवा';

  @override
  String get s17ProblemStatement => 'समस्या विधान';

  @override
  String get s17Responsible => 'जबाबदार';

  @override
  String get s17SectionCompletedSteps => 'पूर्ण झालेली कृती पावले';

  @override
  String s17AllStepsCompletedNotice(int count) {
    return 'सर्व $count कृती पावले पूर्ण झाली आहेत.';
  }

  @override
  String get s17IncompleteStepsWarning =>
      'चेतावणी: अपूर्ण कृती पावले शिल्लक आहेत. ही CAP पूर्ण चिन्हांकित करण्यापूर्वी सर्व कृती पावले पूर्ण केली पाहिजेत.';

  @override
  String get s17SectionDoneNotes => 'पूर्ण नोंदी / शेरे (ऐच्छिक)';

  @override
  String get s17DoneNotesHint =>
      'समस्या कशी सोडवली गेली याचे वर्णन किंवा पडताळणीसाठी नोंदी...';

  @override
  String get s17SectionEvidencePhoto => 'पूर्णता पुरावा फोटो (ऐच्छिक)';

  @override
  String get s17TakePhoto => 'फोटो काढा';

  @override
  String get s17RetakePhoto => 'पुन्हा फोटो काढा';

  @override
  String get s17RemovePhoto => 'फोटो काढून टाका';

  @override
  String get s17PhotoAttached => '१ फोटो जोडला';

  @override
  String get s17AdvisoryCard =>
      'ही CAP पूर्ण म्हणून खूण केल्यावर तिची स्थिती \'पूर्ण (पडताळणी प्रलंबित)\' मध्ये बदलेल. व्यवस्थापनाला (GM/मालक) याचे पुनरावलोकन व पडताळणी करण्यासाठी सूचित केले जाईल.';

  @override
  String get s17ConfirmButton => 'पुष्टी करा आणि पूर्ण खूण करा';

  @override
  String get s17CancelButton => 'रद्द करा';

  @override
  String get s17Submitting => 'पूर्ण म्हणून खूण करत आहे...';

  @override
  String s17SuccessSnackbar(String id) {
    return 'CAP $id पूर्ण म्हणून खूण केली (पडताळणी प्रलंबित)';
  }

  @override
  String s17ErrorSnackbar(String error) {
    return 'CAP पूर्ण म्हणून चिन्हांकित करण्यात अयशस्वी: $error';
  }

  @override
  String s17StepNumber(int number) {
    return 'पाऊल $number';
  }

  @override
  String get s17CapNotFound => 'CAP आढळली नाही';

  @override
  String get s17Loading => 'CAP तपशील लोड होत आहेत...';

  @override
  String get s17CapAlreadyDoneNotice =>
      'ही CAP आधीच पूर्ण किंवा बंद म्हणून चिन्हांकित आहे.';

  @override
  String get s12Title => 'ऑडिट इतिहास';

  @override
  String get s12Subtitle => 'मागील ऑडिट आणि अनुपालन नोंदी पहा';

  @override
  String get s12FilterAll => 'सर्व';

  @override
  String get s12FilterDaily => 'दैनंदिन';

  @override
  String get s12FilterUnverified => 'अपडताळलेले';

  @override
  String get s12FilterWeekly => 'साप्ताहिक (टप्पा २)';

  @override
  String get s12FilterMonthly => 'मासिक (टप्पा ३)';

  @override
  String get s12NoAuditsFound => 'कोणतेही ऑडिट आढळले नाही';

  @override
  String get s12NoAuditsMatchFilter =>
      'निवडलेल्या फिल्टरशी जुळणारे कोणतेही ऑडिट आढळले नाही.';

  @override
  String get s12CompleteAuditPrompt =>
      'येथे इतिहास पाहण्यासाठी दैनंदिन ऑडिट पूर्ण करा आणि सबमिट करा.';

  @override
  String s12Auditor(String name) {
    return 'ऑडिटर: $name';
  }

  @override
  String s12Date(String date) {
    return 'तारीख: $date';
  }

  @override
  String s12ComplianceScore(String score) {
    return '$score%';
  }

  @override
  String s12FailsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नापास',
      one: '१ नापास',
      zero: '० नापास',
    );
    return '$_temp0';
  }

  @override
  String get s12StatusSubmitted => 'सादर केले';

  @override
  String get s12StatusVerified => 'पडताळले';

  @override
  String get s12Loading => 'ऑडिट इतिहास लोड होत आहे...';

  @override
  String get s12TypeDaily => 'दैनंदिन';

  @override
  String get s12TypeWeekly => 'साप्ताहिक';

  @override
  String get s12TypeMonthly => 'मासिक';

  @override
  String get s12BandExcellent => 'उत्कृष्ट';

  @override
  String get s12BandGood => 'चांगले';

  @override
  String get s12BandFair => 'साधारण';

  @override
  String get s12BandPoor => 'खराब';

  @override
  String get s12BandCritical => 'गंभीर';

  @override
  String get s12BandPending => 'प्रलंबित';

  @override
  String get s12RefreshTooltip => 'ऑडिट इतिहास रिफ्रेश करा';

  @override
  String get s12FilterWeeklyTooltip =>
      'साप्ताहिक ऑडिट टप्पा २ साठी नियोजित आहे';

  @override
  String get s12FilterMonthlyTooltip => 'मासिक ऑडिट टप्पा ३ साठी नियोजित आहे';

  @override
  String get s13Title => 'ऑडिट तपशील';

  @override
  String get s13ReadOnlyBanner => 'सादर केलेले ऑडिट — फक्त-वाचन संग्रहण';

  @override
  String s13Auditor(String name) {
    return 'ऑडिटर: $name';
  }

  @override
  String s13Date(String date) {
    return 'तारीख: $date';
  }

  @override
  String s13SubmittedAt(String time) {
    return 'सादर केले: $time';
  }

  @override
  String s13AuditType(String type) {
    return 'प्रकार: $type';
  }

  @override
  String get s13ScoreCard => 'ऑडिट गुण';

  @override
  String get s13SopBreakdown => 'एसओपी (SOP) तपशील';

  @override
  String get s13ExpandSopTooltip => 'चेकपॉईंट्स पाहण्यासाठी टॅप करा';

  @override
  String get s13Points => 'गुण';

  @override
  String s13FailsTitle(int count) {
    return 'आढळलेले दोष ($count)';
  }

  @override
  String get s13NoFails => 'या ऑडिटमध्ये कोणतेही दोष आढळले नाहीत!';

  @override
  String s13Finding(String finding) {
    return 'निष्कर्ष: $finding';
  }

  @override
  String s13Cro(String name) {
    return 'सीआरओ: $name';
  }

  @override
  String get s13LinkedCap => 'जोडलेली CAP';

  @override
  String get s13CreateCap => '+ CAP तयार करा';

  @override
  String get s13NotesTitle => 'ऑडिटरच्या टिप्पण्या';

  @override
  String get s13ExportPdf => 'PDF निर्यात';

  @override
  String get s13ExportPdfTooltip => 'PDF निर्यात टप्पा २ साठी नियोजित आहे';

  @override
  String get s13ShareWhatsApp => 'WhatsApp ला शेअर करा';

  @override
  String get s13ShareWhatsAppTooltip =>
      'WhatsApp शेअर टप्पा २ साठी नियोजित आहे';

  @override
  String get s13VerifyAudit => 'ऑडिट पडताळा';

  @override
  String get s13VerifyAuditTooltip => 'ऑडिट पडताळणी टप्पा २ साठी नियोजित आहे';

  @override
  String get s13NotFound => 'ऑडिट आढळले नाही';

  @override
  String get s13BackToHistory => 'ऑडिट इतिहासावर परत जा';

  @override
  String get s13RefreshTooltip => 'ऑडिट तपशील रिफ्रेश करा';

  @override
  String get s13ViewPhoto => 'पुरावा फोटो';

  @override
  String get s13Close => 'बंद करा';

  @override
  String get s13Loading => 'ऑडिट तपशील लोड होत आहे...';

  @override
  String get s22Title => 'संदर्भ माहिती';

  @override
  String get s22HeaderTitle => 'स्टोअर ऑडिट कार्यपुस्तिका';

  @override
  String get s22HeaderSubtitle =>
      'पुस्तिका परिशिष्टे A.४–A.७. स्टोअर कामकाजासाठी अंतर्निहित अनुपालन मानके आणि एस्केलेशन नियम.';

  @override
  String get s22RatingScaleTitle => 'रेटिंग स्केल आणि लक्ष्ये';

  @override
  String get s22RatingScaleSubtitle =>
      '५ अनुपालन पट्ट्या, स्तर लक्ष्ये, दशांश अचूकता नियम (परिशिष्ट A.४)';

  @override
  String get s22EscalationTitle => 'एस्केलेशन ट्रिगर';

  @override
  String get s22EscalationSubtitle =>
      '७ अनिवार्य ट्रिगर, ४-भाग संदेश स्वरूप, ३ उदाहरणे (परिशिष्ट A.५)';

  @override
  String get s22EvidenceTitle => 'मजबूत वि. दुर्बल पुरावा';

  @override
  String get s22EvidenceSubtitle =>
      '८ मजबूत वि. ८ दुर्बल पुरावा प्रकार, ऑडिट मानके (परिशिष्ट A.६)';

  @override
  String get s22GlossaryTitle => 'द्विभाषी शब्दकोश';

  @override
  String get s22GlossarySubtitle =>
      'इंग्रजी आणि मराठीतील ६५ रिटेल व ऑडिट संज्ञा, थेट शोधासह (परिशिष्ट A.७)';

  @override
  String get s23Title => 'रेटिंग स्केल';

  @override
  String get s24Title => 'एस्केलेशन ट्रिगर';

  @override
  String get s25Title => 'पुरावा मार्गदर्शिका';

  @override
  String get s26Title => 'द्विभाषी शब्दकोश';

  @override
  String s22CardBadgeAppendix(String code) {
    return 'परिशिष्ट $code';
  }

  @override
  String get s23HeaderSubtitle =>
      'पुस्तिका परिशिष्ट A.४ • ५ अनुपालन पट्ट्या आणि स्तर लक्ष्ये';

  @override
  String get s23SectionBandsTitle => '५ अनुपालन पट्ट्या';

  @override
  String get s23SectionBandsSubtitle =>
      'अनिवार्य कार्यवाहक कृतींसह ५ कार्यप्रदर्शन स्तर';

  @override
  String get s23SectionTargetsTitle => 'स्तर लक्ष्ये';

  @override
  String get s23SectionTargetsSubtitle =>
      'भूमिकेनुसार ऑडिट वारंवारता, लक्ष्य गुण आणि उत्तीर्ण मर्यादा';

  @override
  String get s23ActionLabel => 'आवश्यक कृती';

  @override
  String get s23WhoActsLabel => 'कोणाकडून कृती';

  @override
  String get s23AuditorLabel => 'ऑडिटर';

  @override
  String get s23TargetLabel => 'लक्ष्य';

  @override
  String get s23PassPointsLabel => 'उत्तीर्ण गुण';

  @override
  String get s23TotalPointsLabel => 'एकूण वजन';

  @override
  String get s23Loading => 'रेटिंग स्केल लोड होत आहे...';

  @override
  String get s23Error => 'रेटिंग स्केल लोड करण्यात अयशस्वी';

  @override
  String get s23Retry => 'पुन्हा प्रयत्न करा';

  @override
  String get s24HeaderSubtitle =>
      'पुस्तिका परिशिष्ट A.५ • ७ अनिवार्य एस्केलेशन ट्रिगर्स आणि नियम';

  @override
  String get s24SectionTriggersTitle => '७ अनिवार्य एस्केलेशन ट्रिगर्स';

  @override
  String get s24SectionTriggersSubtitle =>
      'तातडीने स्तर वाढवणे आवश्यक असणाऱ्या विशिष्ट मर्यादा';

  @override
  String get s24ThresholdLabel => 'मर्यादा';

  @override
  String get s24EscalateToLabel => 'कोणाकडे';

  @override
  String get s24WhenLabel => 'कधी';

  @override
  String get s24SectionMessageFormatTitle => 'एस्केलेशन संदेश स्वरूप (४ भाग)';

  @override
  String get s24SectionMessageFormatSubtitle =>
      'एस्केलेशन संप्रेषणासाठी प्रमाणित ४-भागांची रचना';

  @override
  String s24PartBadge(int number) {
    return 'भाग $number';
  }

  @override
  String get s24SectionNeverEscalatesTitle => 'काय कधीच एस्केलेट होत नाही';

  @override
  String get s24SectionNeverEscalatesSubtitle =>
      'स्थानिक पातळीवर सोडवल्या जाणाऱ्या बाबी ज्या ऑडिटद्वारे एस्केलेट करू नयेत';

  @override
  String get s24SectionExamplesTitle => 'तयार उदाहरण संदेश';

  @override
  String get s24SectionExamplesSubtitle =>
      'सामान्य ट्रिगर्ससाठी वापरण्यास तयार संदेश नमुने';

  @override
  String get s24WhatHappenedLabel => '१. काय झाले';

  @override
  String get s24EvidenceLabel => '२. पुरावा';

  @override
  String get s24ImpactLabel => '३. कार्यवाहक परिणाम';

  @override
  String get s24ActionLabel => '४. मागितलेली कृती';

  @override
  String get s24CopyButton => 'संदेश कॉपी करा';

  @override
  String get s24CopiedSnackbar => 'एस्केलेशन संदेश क्लिपबोर्डवर कॉपी केला';

  @override
  String get s24Loading => 'एस्केलेशन ट्रिगर्स लोड होत आहेत...';

  @override
  String get s24Error => 'एस्केलेशन ट्रिगर्स लोड करण्यात अयशस्वी';

  @override
  String get s24Retry => 'पुन्हा प्रयत्न करा';

  @override
  String get s25HeaderSubtitle =>
      'पुस्तिका परिशिष्ट A.६ • ८ मजबूत वि. दुर्बल पुरावा मानके';

  @override
  String get s25SectionPairsTitle => '८ पुरावा मानके';

  @override
  String get s25SectionPairsSubtitle =>
      'प्रत्येक ऑडिट निष्कर्षाला मजबूत पुराव्याचा आधार हवा';

  @override
  String get s25StrongEvidenceLabel => 'मजबूत पुरावा';

  @override
  String get s25WeakEvidenceLabel => 'दुर्बल पुरावा (अस्वीकार्य)';

  @override
  String get s25WarningTitle => 'ऑडिट वि. रिपोर्टिंग नियम';

  @override
  String get s25Loading => 'पुरावा मार्गदर्शिका लोड होत आहे...';

  @override
  String get s25Error => 'पुरावा मार्गदर्शिका लोड करण्यात अयशस्वी';

  @override
  String get s25Retry => 'पुन्हा प्रयत्न करा';

  @override
  String get s26HeaderSubtitle =>
      'पुस्तिका परिशिष्ट A.७ • व्याख्यांसह ६५ द्विभाषी रिटेल आणि ऑडिट संज्ञा';

  @override
  String get s26SearchHint => 'संज्ञा किंवा व्याख्या शोधा (English / मराठी)...';

  @override
  String s26ShowingCount(int count, int total) {
    return '$total पैकी $count संज्ञा दर्शवत आहे';
  }

  @override
  String get s26ClearSearch => 'शोध साफ करा';

  @override
  String get s26EmptyTitle => 'कोणतीही जुळणारी संज्ञा सापडली नाही';

  @override
  String get s26EmptySubtitle =>
      'वेगळ्या इंग्रजी किंवा मराठी कीवर्डने शोधून पहा';

  @override
  String get s26Loading => 'शब्दकोश लोड होत आहे...';

  @override
  String get s26Error => 'शब्दकोश लोड करण्यात अयशस्वी';

  @override
  String get s26Retry => 'पुन्हा प्रयत्न करा';

  @override
  String get s26EnglishLabel => 'EN';

  @override
  String get s26MarathiLabel => 'मराठी';
}
