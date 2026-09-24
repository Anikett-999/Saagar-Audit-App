import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mr')
  ];

  /// App name in title bars and launcher
  ///
  /// In en, this message translates to:
  /// **'Saagar Audit'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAudits.
  ///
  /// In en, this message translates to:
  /// **'Audits'**
  String get navAudits;

  /// No description provided for @navCaps.
  ///
  /// In en, this message translates to:
  /// **'CAPs'**
  String get navCaps;

  /// No description provided for @navReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get navReference;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @btnStartAudit.
  ///
  /// In en, this message translates to:
  /// **'Start Audit'**
  String get btnStartAudit;

  /// No description provided for @btnSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get btnSubmit;

  /// No description provided for @btnSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get btnSaveDraft;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @btnBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get btnBack;

  /// No description provided for @btnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get btnNext;

  /// No description provided for @btnPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get btnPrevious;

  /// No description provided for @btnPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get btnPass;

  /// No description provided for @btnFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get btnFail;

  /// No description provided for @btnNa.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get btnNa;

  /// No description provided for @btnAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get btnAddPhoto;

  /// No description provided for @btnRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get btnRetake;

  /// No description provided for @btnUsePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use Photo'**
  String get btnUsePhoto;

  /// No description provided for @btnCreateCap.
  ///
  /// In en, this message translates to:
  /// **'Create CAP'**
  String get btnCreateCap;

  /// No description provided for @btnMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get btnMarkDone;

  /// No description provided for @btnVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get btnVerify;

  /// No description provided for @btnCloseCap.
  ///
  /// In en, this message translates to:
  /// **'Close CAP'**
  String get btnCloseCap;

  /// No description provided for @btnReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get btnReopen;

  /// No description provided for @btnExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get btnExtend;

  /// No description provided for @btnEscalate.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get btnEscalate;

  /// No description provided for @btnExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get btnExportPdf;

  /// No description provided for @btnShareWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get btnShareWhatsapp;

  /// No description provided for @btnLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get btnLogin;

  /// No description provided for @btnLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get btnLogout;

  /// No description provided for @btnChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get btnChangePin;

  /// No description provided for @btnAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get btnAdd;

  /// No description provided for @btnEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get btnEdit;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @btnDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get btnDeactivate;

  /// No description provided for @bandExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get bandExcellent;

  /// No description provided for @bandGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get bandGood;

  /// No description provided for @bandFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get bandFair;

  /// No description provided for @bandPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get bandPoor;

  /// No description provided for @bandCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get bandCritical;

  /// No description provided for @capStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get capStatusOpen;

  /// No description provided for @capStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get capStatusDone;

  /// No description provided for @capStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get capStatusVerified;

  /// No description provided for @capStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get capStatusClosed;

  /// No description provided for @capStatusAged.
  ///
  /// In en, this message translates to:
  /// **'Aged'**
  String get capStatusAged;

  /// No description provided for @capStatusReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get capStatusReopened;

  /// No description provided for @auditStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get auditStatusDraft;

  /// No description provided for @auditStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get auditStatusSubmitted;

  /// No description provided for @auditStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get auditStatusVerified;

  /// No description provided for @auditStatusHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get auditStatusHidden;

  /// No description provided for @errWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Please try again.'**
  String get errWrongPin;

  /// No description provided for @errLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Try again in {seconds} seconds.'**
  String errLocked(int seconds);

  /// No description provided for @errRequiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get errRequiredField;

  /// No description provided for @errFutureDate.
  ///
  /// In en, this message translates to:
  /// **'Audit date cannot be in the future.'**
  String get errFutureDate;

  /// No description provided for @errPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo evidence is required for Cash and Inventory Fails.'**
  String get errPhotoRequired;

  /// No description provided for @errFindingRequired.
  ///
  /// In en, this message translates to:
  /// **'Please describe the finding (up to 200 characters).'**
  String get errFindingRequired;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet — saving locally. Will sync when reconnected.'**
  String get errNoInternet;

  /// No description provided for @errCapDeadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'CAP deadline has passed. Cannot extend.'**
  String get errCapDeadlinePassed;

  /// No description provided for @errCannotEditSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted audits cannot be edited.'**
  String get errCannotEditSubmitted;

  /// No description provided for @okAuditSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Audit submitted.'**
  String get okAuditSubmitted;

  /// No description provided for @okCapCreated.
  ///
  /// In en, this message translates to:
  /// **'CAP created.'**
  String get okCapCreated;

  /// No description provided for @okCapMarkedDone.
  ///
  /// In en, this message translates to:
  /// **'CAP marked done.'**
  String get okCapMarkedDone;

  /// No description provided for @okCapVerified.
  ///
  /// In en, this message translates to:
  /// **'CAP verified.'**
  String get okCapVerified;

  /// No description provided for @okCapClosed.
  ///
  /// In en, this message translates to:
  /// **'CAP closed.'**
  String get okCapClosed;

  /// No description provided for @okPinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed.'**
  String get okPinChanged;

  /// No description provided for @okSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced with cloud.'**
  String get okSynced;

  /// No description provided for @s02Title.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get s02Title;

  /// No description provided for @s02ChooseEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get s02ChooseEnglish;

  /// No description provided for @s02ChooseMarathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get s02ChooseMarathi;

  /// No description provided for @s02Note.
  ///
  /// In en, this message translates to:
  /// **'You can change this later from Settings.'**
  String get s02Note;

  /// No description provided for @s03Title.
  ///
  /// In en, this message translates to:
  /// **'First-time setup'**
  String get s03Title;

  /// No description provided for @s03Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome. Let\'s create your Owner account.'**
  String get s03Subtitle;

  /// No description provided for @s03OwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get s03OwnerName;

  /// No description provided for @s03OwnerPin.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN'**
  String get s03OwnerPin;

  /// No description provided for @s03ReenterPin.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your PIN'**
  String get s03ReenterPin;

  /// No description provided for @s03ConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get s03ConfirmPin;

  /// No description provided for @s03PinsMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Choose a new PIN.'**
  String get s03PinsMismatch;

  /// No description provided for @s03NameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name (2+ characters).'**
  String get s03NameTooShort;

  /// No description provided for @s03AddTeamLater.
  ///
  /// In en, this message translates to:
  /// **'I\'ll add my team later'**
  String get s03AddTeamLater;

  /// No description provided for @s04SelectName.
  ///
  /// In en, this message translates to:
  /// **'Select your name'**
  String get s04SelectName;

  /// No description provided for @s04EnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN'**
  String get s04EnterPin;

  /// No description provided for @s04ForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get s04ForgotPin;

  /// No description provided for @s04ForgotPinHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask the Owner to reset your PIN from Settings → Manage Users.'**
  String get s04ForgotPinHelp;

  /// No description provided for @s04LockedCountdown.
  ///
  /// In en, this message translates to:
  /// **'Locked. Try again in {seconds}s.'**
  String s04LockedCountdown(int seconds);

  /// No description provided for @s04WrongPinAttemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. {attempts} attempts left.'**
  String s04WrongPinAttemptsLeft(int attempts);

  /// No description provided for @s04TooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Try again in {seconds}s.'**
  String s04TooManyAttempts(int seconds);

  /// No description provided for @s05Hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String s05Hello(String name);

  /// No description provided for @s05RoleOwner.
  ///
  /// In en, this message translates to:
  /// **'OWNER'**
  String get s05RoleOwner;

  /// No description provided for @s05RoleSm.
  ///
  /// In en, this message translates to:
  /// **'STORE MANAGER'**
  String get s05RoleSm;

  /// No description provided for @s05RoleGm.
  ///
  /// In en, this message translates to:
  /// **'GENERAL MANAGER'**
  String get s05RoleGm;

  /// No description provided for @s05TodayDailyAudit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s daily audit'**
  String get s05TodayDailyAudit;

  /// No description provided for @s05NotStartedYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t started today\'s audit yet.'**
  String get s05NotStartedYet;

  /// No description provided for @s05NotStartedAdmin.
  ///
  /// In en, this message translates to:
  /// **'Today\'s daily audit has not been started yet.'**
  String get s05NotStartedAdmin;

  /// No description provided for @s05StartDailyAudit.
  ///
  /// In en, this message translates to:
  /// **'Start daily audit'**
  String get s05StartDailyAudit;

  /// No description provided for @s05ResumeDraft.
  ///
  /// In en, this message translates to:
  /// **'Resume draft'**
  String get s05ResumeDraft;

  /// No description provided for @s05DraftInProgress.
  ///
  /// In en, this message translates to:
  /// **'A draft audit is in progress. Resume to continue marking checkpoints.'**
  String get s05DraftInProgress;

  /// No description provided for @s05SubmittedStatus.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get s05SubmittedStatus;

  /// No description provided for @s05DailyAuditsRunBySm.
  ///
  /// In en, this message translates to:
  /// **'Daily audits are run by the Store Manager.'**
  String get s05DailyAuditsRunBySm;

  /// No description provided for @s05StatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get s05StatusNotStarted;

  /// No description provided for @s05StatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get s05StatusInProgress;

  /// No description provided for @s05StatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get s05StatusSubmitted;

  /// No description provided for @s05AuditHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit history'**
  String get s05AuditHistoryTitle;

  /// No description provided for @s05AuditHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View past daily audits'**
  String get s05AuditHistorySubtitle;

  /// No description provided for @s05CapsTitle.
  ///
  /// In en, this message translates to:
  /// **'CAPs'**
  String get s05CapsTitle;

  /// No description provided for @s05CapsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Corrective Action Plans'**
  String get s05CapsSubtitle;

  /// No description provided for @s05ReferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get s05ReferenceTitle;

  /// No description provided for @s05ReferenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rating scale, escalation triggers, glossary'**
  String get s05ReferenceSubtitle;

  /// No description provided for @s05SettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get s05SettingsTitle;

  /// No description provided for @s05SettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'CROs, users, language, backup'**
  String get s05SettingsSubtitle;

  /// No description provided for @s05ComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} is scheduled for Phase 1 Week 3+. Daily Audit flow (S06–S11) is currently active.'**
  String s05ComingSoon(String feature);

  /// No description provided for @s06Title.
  ///
  /// In en, this message translates to:
  /// **'Start Daily Audit'**
  String get s06Title;

  /// No description provided for @s06AuditDate.
  ///
  /// In en, this message translates to:
  /// **'Audit Date'**
  String get s06AuditDate;

  /// No description provided for @s06StoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get s06StoreLabel;

  /// No description provided for @s06CrosOnDuty.
  ///
  /// In en, this message translates to:
  /// **'CROs on Duty'**
  String get s06CrosOnDuty;

  /// No description provided for @s06SelectAtLeastOneCro.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one CRO on duty.'**
  String get s06SelectAtLeastOneCro;

  /// No description provided for @s06BeginAudit.
  ///
  /// In en, this message translates to:
  /// **'Begin Audit'**
  String get s06BeginAudit;

  /// No description provided for @s07CheckpointNumber.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint {current} of {total}'**
  String s07CheckpointNumber(int current, int total);

  /// No description provided for @s07Pass.
  ///
  /// In en, this message translates to:
  /// **'PASS'**
  String get s07Pass;

  /// No description provided for @s07Fail.
  ///
  /// In en, this message translates to:
  /// **'FAIL'**
  String get s07Fail;

  /// No description provided for @s07Na.
  ///
  /// In en, this message translates to:
  /// **'NA'**
  String get s07Na;

  /// No description provided for @s07NaReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Why is this checkpoint Not Applicable?'**
  String get s07NaReasonPrompt;

  /// No description provided for @s07NaReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter reason (minimum 3 characters)...'**
  String get s07NaReasonHint;

  /// No description provided for @s07Previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get s07Previous;

  /// No description provided for @s07Next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get s07Next;

  /// No description provided for @s07FinishReview.
  ///
  /// In en, this message translates to:
  /// **'Finish & Review'**
  String get s07FinishReview;

  /// No description provided for @s08Title.
  ///
  /// In en, this message translates to:
  /// **'Fail Detail'**
  String get s08Title;

  /// No description provided for @s08FindingLabel.
  ///
  /// In en, this message translates to:
  /// **'Finding description'**
  String get s08FindingLabel;

  /// No description provided for @s08FindingHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the non-compliance...'**
  String get s08FindingHint;

  /// No description provided for @s08CroInvolved.
  ///
  /// In en, this message translates to:
  /// **'CRO involved (optional)'**
  String get s08CroInvolved;

  /// No description provided for @s08PhotoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Photo evidence'**
  String get s08PhotoEvidence;

  /// No description provided for @s08PhotoRequiredNotice.
  ///
  /// In en, this message translates to:
  /// **'Photo is mandatory for this checkpoint.'**
  String get s08PhotoRequiredNotice;

  /// No description provided for @s08SaveFail.
  ///
  /// In en, this message translates to:
  /// **'Save Finding'**
  String get s08SaveFail;

  /// No description provided for @s10Title.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get s10Title;

  /// No description provided for @s10ScoreCard.
  ///
  /// In en, this message translates to:
  /// **'Audit Score'**
  String get s10ScoreCard;

  /// No description provided for @s10SopBreakdown.
  ///
  /// In en, this message translates to:
  /// **'SOP Breakdown'**
  String get s10SopBreakdown;

  /// No description provided for @s10FailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Non-Compliances ({count})'**
  String s10FailsTitle(int count);

  /// No description provided for @s10NotesLabel.
  ///
  /// In en, this message translates to:
  /// **'General notes (optional)'**
  String get s10NotesLabel;

  /// No description provided for @s10IncompleteWarning.
  ///
  /// In en, this message translates to:
  /// **'All 68 checkpoints must be marked before submitting.'**
  String get s10IncompleteWarning;

  /// No description provided for @s10SubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Audit'**
  String get s10SubmitButton;

  /// No description provided for @s10MissingPhotoWarning.
  ///
  /// In en, this message translates to:
  /// **'Photo evidence is missing for one or more mandatory fail items.'**
  String get s10MissingPhotoWarning;

  /// No description provided for @s11Title.
  ///
  /// In en, this message translates to:
  /// **'Audit Submitted'**
  String get s11Title;

  /// No description provided for @s11ConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Today\'s daily audit has been successfully recorded.'**
  String get s11ConfirmationMessage;

  /// No description provided for @s11ScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Final Score'**
  String get s11ScoreLabel;

  /// No description provided for @s11BandLabel.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get s11BandLabel;

  /// No description provided for @s11OfflineSyncNotice.
  ///
  /// In en, this message translates to:
  /// **'Will sync when online'**
  String get s11OfflineSyncNotice;

  /// No description provided for @s11ReturnHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get s11ReturnHome;

  /// No description provided for @s27Title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get s27Title;

  /// No description provided for @s27AccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get s27AccountSection;

  /// No description provided for @s27ManagementSection.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get s27ManagementSection;

  /// No description provided for @s27PreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences & Data'**
  String get s27PreferencesSection;

  /// No description provided for @s27ManageCrosTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage CROs'**
  String get s27ManageCrosTitle;

  /// No description provided for @s27ManageCrosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View, add, edit, and deactivate retail staff'**
  String get s27ManageCrosSubtitle;

  /// No description provided for @s27ManageUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get s27ManageUsersTitle;

  /// No description provided for @s27ManageUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add SM/GM staff, reset PINs, manage access'**
  String get s27ManageUsersSubtitle;

  /// No description provided for @s27ChangePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get s27ChangePinTitle;

  /// No description provided for @s27ChangePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your 4-digit security PIN'**
  String get s27ChangePinSubtitle;

  /// No description provided for @s27LanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language / भाषा'**
  String get s27LanguageTitle;

  /// No description provided for @s27LanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select English or मराठी'**
  String get s27LanguageSubtitle;

  /// No description provided for @s27BackupExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Export'**
  String get s27BackupExportTitle;

  /// No description provided for @s27BackupExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export database JSON and sync status'**
  String get s27BackupExportSubtitle;

  /// No description provided for @s27AboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Saagar Audit'**
  String get s27AboutTitle;

  /// No description provided for @s27AboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, store information, and SOP specification'**
  String get s27AboutSubtitle;

  /// No description provided for @s27AboutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'About Priority 1 Audit'**
  String get s27AboutDialogTitle;

  /// No description provided for @s27AboutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Saagar Traders SOP Audit Application\nTitan World (WLMHW) & Helios (HEMW)\nLatur, Maharashtra\nv1.0.0 (Phase 1)'**
  String get s27AboutDialogBody;

  /// No description provided for @s27CloseDialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get s27CloseDialog;

  /// No description provided for @s27OwnerBadge.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get s27OwnerBadge;

  /// No description provided for @s27GmBadge.
  ///
  /// In en, this message translates to:
  /// **'General Manager'**
  String get s27GmBadge;

  /// No description provided for @s27SmBadge.
  ///
  /// In en, this message translates to:
  /// **'Store Manager'**
  String get s27SmBadge;

  /// No description provided for @s28Title.
  ///
  /// In en, this message translates to:
  /// **'Manage CROs'**
  String get s28Title;

  /// No description provided for @s28EmptyState.
  ///
  /// In en, this message translates to:
  /// **'No CROs found. Tap + to add the first CRO.'**
  String get s28EmptyState;

  /// No description provided for @s28StatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get s28StatusActive;

  /// No description provided for @s28StatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get s28StatusInactive;

  /// No description provided for @s28CounterLabel.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get s28CounterLabel;

  /// No description provided for @s28CounterTitan.
  ///
  /// In en, this message translates to:
  /// **'Titan'**
  String get s28CounterTitan;

  /// No description provided for @s28CounterHelios.
  ///
  /// In en, this message translates to:
  /// **'Helios'**
  String get s28CounterHelios;

  /// No description provided for @s28ShiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get s28ShiftLabel;

  /// No description provided for @s28ShiftMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get s28ShiftMorning;

  /// No description provided for @s28ShiftAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get s28ShiftAfternoon;

  /// No description provided for @s28ShiftFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get s28ShiftFlexible;

  /// No description provided for @s28AddCroTitle.
  ///
  /// In en, this message translates to:
  /// **'Add CRO'**
  String get s28AddCroTitle;

  /// No description provided for @s28EditCroTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit CRO'**
  String get s28EditCroTitle;

  /// No description provided for @s28NameLabel.
  ///
  /// In en, this message translates to:
  /// **'CRO Full Name'**
  String get s28NameLabel;

  /// No description provided for @s28NameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rahul Shinde'**
  String get s28NameHint;

  /// No description provided for @s28NameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name (minimum 2 characters)'**
  String get s28NameRequired;

  /// No description provided for @s28StatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get s28StatusLabel;

  /// No description provided for @s28ActiveHelp.
  ///
  /// In en, this message translates to:
  /// **'Active CROs appear in audit dropdowns'**
  String get s28ActiveHelp;

  /// No description provided for @s28SaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get s28SaveButton;

  /// No description provided for @s28CancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get s28CancelButton;

  /// No description provided for @s28EditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get s28EditAction;

  /// No description provided for @s28DeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get s28DeactivateAction;

  /// No description provided for @s28ReactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get s28ReactivateAction;

  /// No description provided for @s28DeactivateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate CRO?'**
  String get s28DeactivateConfirmTitle;

  /// No description provided for @s28DeactivateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This CRO will be hidden from new audits, but past audit records remain untouched.'**
  String get s28DeactivateConfirmBody;

  /// No description provided for @s28CroAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'CRO added successfully'**
  String get s28CroAddedSuccess;

  /// No description provided for @s28CroUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'CRO updated successfully'**
  String get s28CroUpdatedSuccess;

  /// No description provided for @s28CroDeactivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'CRO deactivated'**
  String get s28CroDeactivatedSuccess;

  /// No description provided for @s28CroReactivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'CRO reactivated'**
  String get s28CroReactivatedSuccess;

  /// No description provided for @s29Title.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get s29Title;

  /// No description provided for @s29EmptyState.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get s29EmptyState;

  /// No description provided for @s29AddUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get s29AddUserTitle;

  /// No description provided for @s29NameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get s29NameLabel;

  /// No description provided for @s29NameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sachin Jadhav'**
  String get s29NameHint;

  /// No description provided for @s29NameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name (2–50 characters)'**
  String get s29NameRequired;

  /// No description provided for @s29RoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get s29RoleLabel;

  /// No description provided for @s29RoleSm.
  ///
  /// In en, this message translates to:
  /// **'Store Manager (SM)'**
  String get s29RoleSm;

  /// No description provided for @s29RoleGm.
  ///
  /// In en, this message translates to:
  /// **'General Manager (GM)'**
  String get s29RoleGm;

  /// No description provided for @s29PhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get s29PhoneLabel;

  /// No description provided for @s29PhoneHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get s29PhoneHint;

  /// No description provided for @s29PinLabel.
  ///
  /// In en, this message translates to:
  /// **'4-Digit PIN'**
  String get s29PinLabel;

  /// No description provided for @s29PinConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm 4-Digit PIN'**
  String get s29PinConfirmLabel;

  /// No description provided for @s29PinRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 4-digit numeric PIN'**
  String get s29PinRequired;

  /// No description provided for @s29PinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get s29PinMismatch;

  /// No description provided for @s29SaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get s29SaveButton;

  /// No description provided for @s29CancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get s29CancelButton;

  /// No description provided for @s29UserAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get s29UserAddedSuccess;

  /// No description provided for @s29ResetPinAction.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get s29ResetPinAction;

  /// No description provided for @s29ResetPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN for {name}'**
  String s29ResetPinTitle(String name);

  /// No description provided for @s29NewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'New 4-Digit PIN'**
  String get s29NewPinLabel;

  /// No description provided for @s29ConfirmNewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New PIN'**
  String get s29ConfirmNewPinLabel;

  /// No description provided for @s29ResetPinSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN reset successfully'**
  String get s29ResetPinSuccess;

  /// No description provided for @s29DeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get s29DeactivateAction;

  /// No description provided for @s29ReactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get s29ReactivateAction;

  /// No description provided for @s29DeactivateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate User?'**
  String get s29DeactivateConfirmTitle;

  /// No description provided for @s29DeactivateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This user will no longer be able to log in, but all historical audit records remain untouched.'**
  String get s29DeactivateConfirmBody;

  /// No description provided for @s29CannotDeactivateOwner.
  ///
  /// In en, this message translates to:
  /// **'The Owner account cannot be deactivated per Spec §S29.'**
  String get s29CannotDeactivateOwner;

  /// No description provided for @s29UserDeactivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User deactivated'**
  String get s29UserDeactivatedSuccess;

  /// No description provided for @s29UserReactivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User reactivated'**
  String get s29UserReactivatedSuccess;

  /// No description provided for @s29OwnerRestrictedAccess.
  ///
  /// In en, this message translates to:
  /// **'Access restricted to Owner only.'**
  String get s29OwnerRestrictedAccess;

  /// No description provided for @s29StatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get s29StatusActive;

  /// No description provided for @s29StatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get s29StatusInactive;

  /// No description provided for @s30Title.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get s30Title;

  /// No description provided for @s30InstructionText.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN to verify your identity, then enter and confirm your new 4-digit security PIN.'**
  String get s30InstructionText;

  /// No description provided for @s30CurrentPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Current 4-Digit PIN'**
  String get s30CurrentPinLabel;

  /// No description provided for @s30CurrentPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your existing PIN'**
  String get s30CurrentPinHint;

  /// No description provided for @s30CurrentPinRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current 4-digit PIN'**
  String get s30CurrentPinRequired;

  /// No description provided for @s30CurrentPinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current PIN is incorrect'**
  String get s30CurrentPinIncorrect;

  /// No description provided for @s30NewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'New 4-Digit PIN'**
  String get s30NewPinLabel;

  /// No description provided for @s30NewPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new 4-digit PIN'**
  String get s30NewPinHint;

  /// No description provided for @s30NewPinRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 4-digit numeric PIN'**
  String get s30NewPinRequired;

  /// No description provided for @s30NewPinSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'New PIN must be different from current PIN'**
  String get s30NewPinSameAsCurrent;

  /// No description provided for @s30ConfirmPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New 4-Digit PIN'**
  String get s30ConfirmPinLabel;

  /// No description provided for @s30ConfirmPinHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new 4-digit PIN'**
  String get s30ConfirmPinHint;

  /// No description provided for @s30PinMismatch.
  ///
  /// In en, this message translates to:
  /// **'New PIN and confirmation do not match'**
  String get s30PinMismatch;

  /// No description provided for @s30SaveButton.
  ///
  /// In en, this message translates to:
  /// **'Update PIN'**
  String get s30SaveButton;

  /// No description provided for @s30PinChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully'**
  String get s30PinChangedSuccess;

  /// No description provided for @s31Title.
  ///
  /// In en, this message translates to:
  /// **'Language / भाषा'**
  String get s31Title;

  /// No description provided for @s31Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred app language'**
  String get s31Subtitle;

  /// No description provided for @s31Instruction.
  ///
  /// In en, this message translates to:
  /// **'Select the language you want to use throughout the application. Changes apply immediately and are saved to your profile.'**
  String get s31Instruction;

  /// No description provided for @s31EnglishTitle.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get s31EnglishTitle;

  /// No description provided for @s31EnglishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default system language'**
  String get s31EnglishSubtitle;

  /// No description provided for @s31MarathiTitle.
  ///
  /// In en, this message translates to:
  /// **'मराठी (Marathi)'**
  String get s31MarathiTitle;

  /// No description provided for @s31MarathiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'स्थानिक भाषा (Regional Language)'**
  String get s31MarathiSubtitle;

  /// No description provided for @s31CurrentLanguageBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get s31CurrentLanguageBadge;

  /// No description provided for @s31LanguageUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Language preference saved'**
  String get s31LanguageUpdatedSuccess;

  /// No description provided for @s32Title.
  ///
  /// In en, this message translates to:
  /// **'Backup & Export'**
  String get s32Title;

  /// No description provided for @s32Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Local SQLite Database Export & Cloud Sync'**
  String get s32Subtitle;

  /// No description provided for @s32ExportCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Local Database (JSON)'**
  String get s32ExportCardTitle;

  /// No description provided for @s32ExportCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Export all 14 SQLite tables into a timestamped JSON file in your device Downloads directory. Ideal for manual backups before app updates.'**
  String get s32ExportCardDesc;

  /// No description provided for @s32ExportSecurityNotice.
  ///
  /// In en, this message translates to:
  /// **'Security Notice: Exported backup contains audit trails, findings, and bcrypt security hashes. Store and transfer this file securely.'**
  String get s32ExportSecurityNotice;

  /// No description provided for @s32ExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export Database JSON'**
  String get s32ExportButton;

  /// No description provided for @s32Exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting database...'**
  String get s32Exporting;

  /// No description provided for @s32ExportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Successful'**
  String get s32ExportSuccessTitle;

  /// No description provided for @s32ExportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup saved successfully ({records} records across {tables} tables).\n\nFile: {fileName}\nPath:\n{path}'**
  String s32ExportSuccessMessage(
      int records, int tables, String fileName, String path);

  /// No description provided for @s32ExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export database: {error}'**
  String s32ExportFailed(String error);

  /// No description provided for @s32CloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Synchronization (Firestore)'**
  String get s32CloudSyncTitle;

  /// No description provided for @s32CloudSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatic multi-device synchronization and cloud data storage via Google Cloud Firestore.'**
  String get s32CloudSyncDesc;

  /// No description provided for @s32CloudSyncStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: Offline-First Mode (Local SQLite)'**
  String get s32CloudSyncStatusLabel;

  /// No description provided for @s32CloudSyncPhase4Notice.
  ///
  /// In en, this message translates to:
  /// **'Coming in Phase 4. All audits and settings are safely stored locally on this device.'**
  String get s32CloudSyncPhase4Notice;

  /// No description provided for @s32CloudSyncComingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Coming in Phase 4'**
  String get s32CloudSyncComingSoonBadge;

  /// No description provided for @s32ForceSyncButton.
  ///
  /// In en, this message translates to:
  /// **'Force Cloud Sync'**
  String get s32ForceSyncButton;

  /// No description provided for @s32AboutCardTitle.
  ///
  /// In en, this message translates to:
  /// **'About Saagar Audit App'**
  String get s32AboutCardTitle;

  /// No description provided for @s32AboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version: 0.1.0+1 (Phase 1 Baseline)'**
  String get s32AboutVersion;

  /// No description provided for @s32AboutStore.
  ///
  /// In en, this message translates to:
  /// **'Stores: Titan World (WLMHW) & Helios (HEMW), Latur'**
  String get s32AboutStore;

  /// No description provided for @s32AboutSpec.
  ///
  /// In en, this message translates to:
  /// **'Specification: Saagar P1 Retail Audit Spec v1'**
  String get s32AboutSpec;

  /// No description provided for @s32OkButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get s32OkButton;

  /// No description provided for @s32CopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Path'**
  String get s32CopyPath;

  /// No description provided for @s32PathCopied.
  ///
  /// In en, this message translates to:
  /// **'Backup path copied to clipboard'**
  String get s32PathCopied;

  /// No description provided for @s32ShareFile.
  ///
  /// In en, this message translates to:
  /// **'Share / Save File'**
  String get s32ShareFile;

  /// No description provided for @s14Title.
  ///
  /// In en, this message translates to:
  /// **'Corrective Action Plans'**
  String get s14Title;

  /// No description provided for @s14Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track and resolve audit findings'**
  String get s14Subtitle;

  /// No description provided for @s14SearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by problem statement or CAP ID...'**
  String get s14SearchHint;

  /// No description provided for @s14FilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get s14FilterAll;

  /// No description provided for @s14FilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get s14FilterOpen;

  /// No description provided for @s14FilterDone.
  ///
  /// In en, this message translates to:
  /// **'Done (pending verify)'**
  String get s14FilterDone;

  /// No description provided for @s14FilterAged.
  ///
  /// In en, this message translates to:
  /// **'Aged ⚠'**
  String get s14FilterAged;

  /// No description provided for @s14FilterClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get s14FilterClosed;

  /// No description provided for @s14EmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No CAPs Found'**
  String get s14EmptyTitle;

  /// No description provided for @s14EmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'No corrective actions match the selected filter.'**
  String get s14EmptyDesc;

  /// No description provided for @s14NewCapButton.
  ///
  /// In en, this message translates to:
  /// **'New CAP'**
  String get s14NewCapButton;

  /// No description provided for @s14StatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get s14StatusOpen;

  /// No description provided for @s14StatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get s14StatusDone;

  /// No description provided for @s14StatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get s14StatusVerified;

  /// No description provided for @s14StatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get s14StatusClosed;

  /// No description provided for @s14StatusAged.
  ///
  /// In en, this message translates to:
  /// **'Aged'**
  String get s14StatusAged;

  /// No description provided for @s14StatusReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get s14StatusReopened;

  /// No description provided for @s14DeadlineOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue ({date})'**
  String s14DeadlineOverdue(String date);

  /// No description provided for @s14DeadlineDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due Soon ({date})'**
  String s14DeadlineDueSoon(String date);

  /// No description provided for @s14DeadlineOk.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String s14DeadlineOk(String date);

  /// No description provided for @s14ResponsiblePrefix.
  ///
  /// In en, this message translates to:
  /// **'Responsible: {name}'**
  String s14ResponsiblePrefix(String name);

  /// No description provided for @s15Title.
  ///
  /// In en, this message translates to:
  /// **'New Corrective Action Plan'**
  String get s15Title;

  /// No description provided for @s15Subtitle.
  ///
  /// In en, this message translates to:
  /// **'10-field root cause & action template'**
  String get s15Subtitle;

  /// No description provided for @s15CapIdPreview.
  ///
  /// In en, this message translates to:
  /// **'CAP ID (Auto-Generated)'**
  String get s15CapIdPreview;

  /// No description provided for @s15SectionOrigin.
  ///
  /// In en, this message translates to:
  /// **'1. Originating Finding'**
  String get s15SectionOrigin;

  /// No description provided for @s15OriginAudit.
  ///
  /// In en, this message translates to:
  /// **'Origin Audit'**
  String get s15OriginAudit;

  /// No description provided for @s15OriginCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Failed Checkpoint'**
  String get s15OriginCheckpoint;

  /// No description provided for @s15SelectAudit.
  ///
  /// In en, this message translates to:
  /// **'Select Audit'**
  String get s15SelectAudit;

  /// No description provided for @s15SelectCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Select Checkpoint'**
  String get s15SelectCheckpoint;

  /// No description provided for @s15NoAuditsFound.
  ///
  /// In en, this message translates to:
  /// **'No audits found. Complete an audit first.'**
  String get s15NoAuditsFound;

  /// No description provided for @s15SectionProblem.
  ///
  /// In en, this message translates to:
  /// **'2. Problem & 5-Whys Analysis'**
  String get s15SectionProblem;

  /// No description provided for @s15ProblemStatement.
  ///
  /// In en, this message translates to:
  /// **'Problem Statement'**
  String get s15ProblemStatement;

  /// No description provided for @s15ProblemStatementHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what failed (1 sentence)'**
  String get s15ProblemStatementHint;

  /// No description provided for @s15ProblemRequired.
  ///
  /// In en, this message translates to:
  /// **'Problem statement is required'**
  String get s15ProblemRequired;

  /// No description provided for @s15Why1.
  ///
  /// In en, this message translates to:
  /// **'Why 1 (Primary Cause)'**
  String get s15Why1;

  /// No description provided for @s15Why1Hint.
  ///
  /// In en, this message translates to:
  /// **'Why did this condition occur?'**
  String get s15Why1Hint;

  /// No description provided for @s15Why1Required.
  ///
  /// In en, this message translates to:
  /// **'Why 1 is required'**
  String get s15Why1Required;

  /// No description provided for @s15Why2.
  ///
  /// In en, this message translates to:
  /// **'Why 2 (optional)'**
  String get s15Why2;

  /// No description provided for @s15Why2Hint.
  ///
  /// In en, this message translates to:
  /// **'Why did that happen?'**
  String get s15Why2Hint;

  /// No description provided for @s15Why3.
  ///
  /// In en, this message translates to:
  /// **'Why 3 (optional)'**
  String get s15Why3;

  /// No description provided for @s15Why3Hint.
  ///
  /// In en, this message translates to:
  /// **'Why did that happen?'**
  String get s15Why3Hint;

  /// No description provided for @s15Why4.
  ///
  /// In en, this message translates to:
  /// **'Why 4 (optional)'**
  String get s15Why4;

  /// No description provided for @s15Why4Hint.
  ///
  /// In en, this message translates to:
  /// **'Why did that happen?'**
  String get s15Why4Hint;

  /// No description provided for @s15Why5.
  ///
  /// In en, this message translates to:
  /// **'Why 5 (optional)'**
  String get s15Why5;

  /// No description provided for @s15Why5Hint.
  ///
  /// In en, this message translates to:
  /// **'Why did that happen?'**
  String get s15Why5Hint;

  /// No description provided for @s15RootCause.
  ///
  /// In en, this message translates to:
  /// **'Root Cause'**
  String get s15RootCause;

  /// No description provided for @s15RootCauseHint.
  ///
  /// In en, this message translates to:
  /// **'Systemic root cause (1-2 sentences)'**
  String get s15RootCauseHint;

  /// No description provided for @s15RootCauseRequired.
  ///
  /// In en, this message translates to:
  /// **'Root cause is required'**
  String get s15RootCauseRequired;

  /// No description provided for @s15SectionActions.
  ///
  /// In en, this message translates to:
  /// **'3. Action Steps (3 to 5 steps)'**
  String get s15SectionActions;

  /// No description provided for @s15StepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String s15StepLabel(int number);

  /// No description provided for @s15StepHint.
  ///
  /// In en, this message translates to:
  /// **'Action step description'**
  String get s15StepHint;

  /// No description provided for @s15StepRequired.
  ///
  /// In en, this message translates to:
  /// **'Action step cannot be empty'**
  String get s15StepRequired;

  /// No description provided for @s15AddStep.
  ///
  /// In en, this message translates to:
  /// **'Add Step'**
  String get s15AddStep;

  /// No description provided for @s15MinStepsNotice.
  ///
  /// In en, this message translates to:
  /// **'At least 3 steps required'**
  String get s15MinStepsNotice;

  /// No description provided for @s15MaxStepsReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 steps reached'**
  String get s15MaxStepsReached;

  /// No description provided for @s15SectionOwnership.
  ///
  /// In en, this message translates to:
  /// **'4. Ownership & Verification'**
  String get s15SectionOwnership;

  /// No description provided for @s15ResponsibleUser.
  ///
  /// In en, this message translates to:
  /// **'Responsible (CAP Owner)'**
  String get s15ResponsibleUser;

  /// No description provided for @s15SelectResponsible.
  ///
  /// In en, this message translates to:
  /// **'Select responsible user (SM, GM, Owner)'**
  String get s15SelectResponsible;

  /// No description provided for @s15ResponsibleRequired.
  ///
  /// In en, this message translates to:
  /// **'Responsible user is required'**
  String get s15ResponsibleRequired;

  /// No description provided for @s15Deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline (Target Completion Date)'**
  String get s15Deadline;

  /// No description provided for @s15SelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get s15SelectDate;

  /// No description provided for @s15VerificationMethod.
  ///
  /// In en, this message translates to:
  /// **'Verification Method'**
  String get s15VerificationMethod;

  /// No description provided for @s15VerificationMethodHint.
  ///
  /// In en, this message translates to:
  /// **'How will completion be verified?'**
  String get s15VerificationMethodHint;

  /// No description provided for @s15VerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verification method is required'**
  String get s15VerificationRequired;

  /// No description provided for @s15CreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create CAP'**
  String get s15CreateButton;

  /// No description provided for @s15Creating.
  ///
  /// In en, this message translates to:
  /// **'Creating CAP...'**
  String get s15Creating;

  /// No description provided for @s15CreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'CAP created successfully'**
  String get s15CreatedSuccess;

  /// No description provided for @s15AuditDropdownItem.
  ///
  /// In en, this message translates to:
  /// **'Audit {date} ({type})'**
  String s15AuditDropdownItem(String date, String type);

  /// No description provided for @s15ErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String s15ErrorPrefix(String message);

  /// No description provided for @s16Title.
  ///
  /// In en, this message translates to:
  /// **'CAP Detail'**
  String get s16Title;

  /// No description provided for @s16Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Corrective Action Plan'**
  String get s16Subtitle;

  /// No description provided for @s16NotFound.
  ///
  /// In en, this message translates to:
  /// **'CAP not found'**
  String get s16NotFound;

  /// No description provided for @s16BackToCaps.
  ///
  /// In en, this message translates to:
  /// **'Back to CAP List'**
  String get s16BackToCaps;

  /// No description provided for @s16StatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get s16StatusOpen;

  /// No description provided for @s16StatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done (Pending Verify)'**
  String get s16StatusDone;

  /// No description provided for @s16StatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get s16StatusVerified;

  /// No description provided for @s16StatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get s16StatusClosed;

  /// No description provided for @s16StatusAged.
  ///
  /// In en, this message translates to:
  /// **'Aged'**
  String get s16StatusAged;

  /// No description provided for @s16StatusReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get s16StatusReopened;

  /// No description provided for @s16OverdueByDays.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} days'**
  String s16OverdueByDays(int days);

  /// No description provided for @s16DueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get s16DueToday;

  /// No description provided for @s16DueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'1 day left (Due tomorrow)'**
  String get s16DueTomorrow;

  /// No description provided for @s16DaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String s16DaysRemaining(int days);

  /// No description provided for @s16CompletedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed on {date}'**
  String s16CompletedOn(String date);

  /// No description provided for @s16DeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date}'**
  String s16DeadlineLabel(String date);

  /// No description provided for @s16SectionOrigin.
  ///
  /// In en, this message translates to:
  /// **'1. Origin Information'**
  String get s16SectionOrigin;

  /// No description provided for @s16OriginAudit.
  ///
  /// In en, this message translates to:
  /// **'Origin Audit'**
  String get s16OriginAudit;

  /// No description provided for @s16OriginCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Origin Checkpoint'**
  String get s16OriginCheckpoint;

  /// No description provided for @s16PatternBadge.
  ///
  /// In en, this message translates to:
  /// **'Recurring Issue (Pattern)'**
  String get s16PatternBadge;

  /// No description provided for @s16SectionAnalysis.
  ///
  /// In en, this message translates to:
  /// **'2. Problem & 5-Whys Analysis'**
  String get s16SectionAnalysis;

  /// No description provided for @s16ProblemStatement.
  ///
  /// In en, this message translates to:
  /// **'Problem Statement'**
  String get s16ProblemStatement;

  /// No description provided for @s16WhyLabel.
  ///
  /// In en, this message translates to:
  /// **'Why {number}'**
  String s16WhyLabel(int number);

  /// No description provided for @s16RootCause.
  ///
  /// In en, this message translates to:
  /// **'Root Cause'**
  String get s16RootCause;

  /// No description provided for @s16SectionOwnership.
  ///
  /// In en, this message translates to:
  /// **'3. Ownership & Verification'**
  String get s16SectionOwnership;

  /// No description provided for @s16ResponsibleUser.
  ///
  /// In en, this message translates to:
  /// **'Responsible (CAP Owner)'**
  String get s16ResponsibleUser;

  /// No description provided for @s16CreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get s16CreatedBy;

  /// No description provided for @s16OpenedAt.
  ///
  /// In en, this message translates to:
  /// **'Opened: {date}'**
  String s16OpenedAt(String date);

  /// No description provided for @s16VerificationMethod.
  ///
  /// In en, this message translates to:
  /// **'Verification Method'**
  String get s16VerificationMethod;

  /// No description provided for @s16AgedCount.
  ///
  /// In en, this message translates to:
  /// **'Aged: {count} times'**
  String s16AgedCount(int count);

  /// No description provided for @s16ExtensionCount.
  ///
  /// In en, this message translates to:
  /// **'Extensions: {count}'**
  String s16ExtensionCount(int count);

  /// No description provided for @s16LatestExtensionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String s16LatestExtensionReason(String reason);

  /// No description provided for @s16SectionActionSteps.
  ///
  /// In en, this message translates to:
  /// **'4. Action Steps ({done}/{total})'**
  String s16SectionActionSteps(int done, int total);

  /// No description provided for @s16StepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String s16StepLabel(int number);

  /// No description provided for @s16ActionDoneBy.
  ///
  /// In en, this message translates to:
  /// **'Done by {user} on {date}'**
  String s16ActionDoneBy(String user, String date);

  /// No description provided for @s16OnlyResponsibleCanToggle.
  ///
  /// In en, this message translates to:
  /// **'Only the assigned responsible user can check off action steps.'**
  String get s16OnlyResponsibleCanToggle;

  /// No description provided for @s16CapAlreadyDoneNotice.
  ///
  /// In en, this message translates to:
  /// **'CAP is already marked done. Action steps cannot be edited.'**
  String get s16CapAlreadyDoneNotice;

  /// No description provided for @s16MarkDoneButton.
  ///
  /// In en, this message translates to:
  /// **'Mark CAP Done'**
  String get s16MarkDoneButton;

  /// No description provided for @s16CompleteAllStepsToMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Complete all action steps to enable Mark Done'**
  String get s16CompleteAllStepsToMarkDone;

  /// No description provided for @s16VerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify CAP'**
  String get s16VerifyButton;

  /// No description provided for @s16CloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close CAP'**
  String get s16CloseButton;

  /// No description provided for @s16RequestExtensionButton.
  ///
  /// In en, this message translates to:
  /// **'Request Extension'**
  String get s16RequestExtensionButton;

  /// No description provided for @s16ReopenButton.
  ///
  /// In en, this message translates to:
  /// **'Reopen CAP'**
  String get s16ReopenButton;

  /// No description provided for @s16Phase2Notice.
  ///
  /// In en, this message translates to:
  /// **'Phase 2 (Coming Soon)'**
  String get s16Phase2Notice;

  /// No description provided for @s16SectionTimeline.
  ///
  /// In en, this message translates to:
  /// **'5. Event Timeline'**
  String get s16SectionTimeline;

  /// No description provided for @s16EventCreated.
  ///
  /// In en, this message translates to:
  /// **'CAP Created'**
  String get s16EventCreated;

  /// No description provided for @s16EventActionDone.
  ///
  /// In en, this message translates to:
  /// **'Action Step Completed'**
  String get s16EventActionDone;

  /// No description provided for @s16EventActionUndone.
  ///
  /// In en, this message translates to:
  /// **'Action Step Reopened'**
  String get s16EventActionUndone;

  /// No description provided for @s16EventMarkedDone.
  ///
  /// In en, this message translates to:
  /// **'Marked Done (Pending Verification)'**
  String get s16EventMarkedDone;

  /// No description provided for @s16EventVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified by Management'**
  String get s16EventVerified;

  /// No description provided for @s16EventClosed.
  ///
  /// In en, this message translates to:
  /// **'CAP Closed'**
  String get s16EventClosed;

  /// No description provided for @s16EventExtended.
  ///
  /// In en, this message translates to:
  /// **'Deadline Extended'**
  String get s16EventExtended;

  /// No description provided for @s16EventAged.
  ///
  /// In en, this message translates to:
  /// **'Marked Aged'**
  String get s16EventAged;

  /// No description provided for @s16EventReopened.
  ///
  /// In en, this message translates to:
  /// **'CAP Reopened'**
  String get s16EventReopened;

  /// No description provided for @s16ActorSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get s16ActorSystem;

  /// No description provided for @s16ActorPrefix.
  ///
  /// In en, this message translates to:
  /// **'By {user}'**
  String s16ActorPrefix(String user);

  /// No description provided for @s16ActionToggleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update action step: {error}'**
  String s16ActionToggleFailed(String error);

  /// No description provided for @s16RefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get s16RefreshTooltip;

  /// No description provided for @s16WhysSubheader.
  ///
  /// In en, this message translates to:
  /// **'5 Whys'**
  String get s16WhysSubheader;

  /// No description provided for @s16NoTimelineEntries.
  ///
  /// In en, this message translates to:
  /// **'No timeline entries'**
  String get s16NoTimelineEntries;

  /// No description provided for @s17Title.
  ///
  /// In en, this message translates to:
  /// **'Mark CAP Done'**
  String get s17Title;

  /// No description provided for @s17Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm completion & submit for verification'**
  String get s17Subtitle;

  /// No description provided for @s17ProblemStatement.
  ///
  /// In en, this message translates to:
  /// **'Problem Statement'**
  String get s17ProblemStatement;

  /// No description provided for @s17Responsible.
  ///
  /// In en, this message translates to:
  /// **'Responsible'**
  String get s17Responsible;

  /// No description provided for @s17SectionCompletedSteps.
  ///
  /// In en, this message translates to:
  /// **'Completed Action Steps'**
  String get s17SectionCompletedSteps;

  /// No description provided for @s17AllStepsCompletedNotice.
  ///
  /// In en, this message translates to:
  /// **'All {count} action steps have been completed.'**
  String s17AllStepsCompletedNotice(int count);

  /// No description provided for @s17IncompleteStepsWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: Incomplete action steps remain. You must complete all action steps before marking this CAP done.'**
  String get s17IncompleteStepsWarning;

  /// No description provided for @s17SectionDoneNotes.
  ///
  /// In en, this message translates to:
  /// **'Done Notes / Reflection (optional)'**
  String get s17SectionDoneNotes;

  /// No description provided for @s17DoneNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Describe how the issue was resolved or notes for verification...'**
  String get s17DoneNotesHint;

  /// No description provided for @s17SectionEvidencePhoto.
  ///
  /// In en, this message translates to:
  /// **'Completion Evidence Photo (optional)'**
  String get s17SectionEvidencePhoto;

  /// No description provided for @s17TakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get s17TakePhoto;

  /// No description provided for @s17RetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get s17RetakePhoto;

  /// No description provided for @s17RemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get s17RemovePhoto;

  /// No description provided for @s17PhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'1 photo attached'**
  String get s17PhotoAttached;

  /// No description provided for @s17AdvisoryCard.
  ///
  /// In en, this message translates to:
  /// **'Marking this CAP done will transition its status to \'Done (Pending Verification)\'. Management (GM/Owner) will be notified to review and verify this corrective action.'**
  String get s17AdvisoryCard;

  /// No description provided for @s17ConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Mark Done'**
  String get s17ConfirmButton;

  /// No description provided for @s17CancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get s17CancelButton;

  /// No description provided for @s17Submitting.
  ///
  /// In en, this message translates to:
  /// **'Marking Done...'**
  String get s17Submitting;

  /// No description provided for @s17SuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'CAP {id} marked done (Pending Verification)'**
  String s17SuccessSnackbar(String id);

  /// No description provided for @s17ErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark CAP done: {error}'**
  String s17ErrorSnackbar(String error);

  /// No description provided for @s17StepNumber.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String s17StepNumber(int number);

  /// No description provided for @s17CapNotFound.
  ///
  /// In en, this message translates to:
  /// **'CAP not found'**
  String get s17CapNotFound;

  /// No description provided for @s17Loading.
  ///
  /// In en, this message translates to:
  /// **'Loading CAP details...'**
  String get s17Loading;

  /// No description provided for @s17CapAlreadyDoneNotice.
  ///
  /// In en, this message translates to:
  /// **'This CAP is already marked done or closed.'**
  String get s17CapAlreadyDoneNotice;

  /// No description provided for @s12Title.
  ///
  /// In en, this message translates to:
  /// **'Audit History'**
  String get s12Title;

  /// No description provided for @s12Subtitle.
  ///
  /// In en, this message translates to:
  /// **'View past audits and compliance records'**
  String get s12Subtitle;

  /// No description provided for @s12FilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get s12FilterAll;

  /// No description provided for @s12FilterDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get s12FilterDaily;

  /// No description provided for @s12FilterUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get s12FilterUnverified;

  /// No description provided for @s12FilterWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly (Phase 2)'**
  String get s12FilterWeekly;

  /// No description provided for @s12FilterMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly (Phase 3)'**
  String get s12FilterMonthly;

  /// No description provided for @s12NoAuditsFound.
  ///
  /// In en, this message translates to:
  /// **'No audits found'**
  String get s12NoAuditsFound;

  /// No description provided for @s12NoAuditsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No audits match the selected filter.'**
  String get s12NoAuditsMatchFilter;

  /// No description provided for @s12CompleteAuditPrompt.
  ///
  /// In en, this message translates to:
  /// **'Complete and submit a daily audit to view history here.'**
  String get s12CompleteAuditPrompt;

  /// No description provided for @s12Auditor.
  ///
  /// In en, this message translates to:
  /// **'Auditor: {name}'**
  String s12Auditor(String name);

  /// No description provided for @s12Date.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String s12Date(String date);

  /// No description provided for @s12ComplianceScore.
  ///
  /// In en, this message translates to:
  /// **'{score}%'**
  String s12ComplianceScore(String score);

  /// No description provided for @s12FailsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 Fails} =1{1 Fail} other{{count} Fails}}'**
  String s12FailsCount(int count);

  /// No description provided for @s12StatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get s12StatusSubmitted;

  /// No description provided for @s12StatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get s12StatusVerified;

  /// No description provided for @s12Loading.
  ///
  /// In en, this message translates to:
  /// **'Loading audit history...'**
  String get s12Loading;

  /// No description provided for @s12TypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get s12TypeDaily;

  /// No description provided for @s12TypeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get s12TypeWeekly;

  /// No description provided for @s12TypeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get s12TypeMonthly;

  /// No description provided for @s12BandExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get s12BandExcellent;

  /// No description provided for @s12BandGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get s12BandGood;

  /// No description provided for @s12BandFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get s12BandFair;

  /// No description provided for @s12BandPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get s12BandPoor;

  /// No description provided for @s12BandCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get s12BandCritical;

  /// No description provided for @s12BandPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get s12BandPending;

  /// No description provided for @s12RefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh audit history'**
  String get s12RefreshTooltip;

  /// No description provided for @s12FilterWeeklyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Weekly Audit is scheduled for Phase 2'**
  String get s12FilterWeeklyTooltip;

  /// No description provided for @s12FilterMonthlyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Monthly Audit is scheduled for Phase 3'**
  String get s12FilterMonthlyTooltip;

  /// No description provided for @s13Title.
  ///
  /// In en, this message translates to:
  /// **'Audit Detail'**
  String get s13Title;

  /// No description provided for @s13ReadOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'Submitted audit — read-only archive'**
  String get s13ReadOnlyBanner;

  /// No description provided for @s13Auditor.
  ///
  /// In en, this message translates to:
  /// **'Auditor: {name}'**
  String s13Auditor(String name);

  /// No description provided for @s13Date.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String s13Date(String date);

  /// No description provided for @s13SubmittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted: {time}'**
  String s13SubmittedAt(String time);

  /// No description provided for @s13AuditType.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String s13AuditType(String type);

  /// No description provided for @s13ScoreCard.
  ///
  /// In en, this message translates to:
  /// **'Audit Score'**
  String get s13ScoreCard;

  /// No description provided for @s13SopBreakdown.
  ///
  /// In en, this message translates to:
  /// **'SOP Breakdown'**
  String get s13SopBreakdown;

  /// No description provided for @s13ExpandSopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tap to view checkpoints'**
  String get s13ExpandSopTooltip;

  /// No description provided for @s13Points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get s13Points;

  /// No description provided for @s13FailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Non-Compliances ({count})'**
  String s13FailsTitle(int count);

  /// No description provided for @s13NoFails.
  ///
  /// In en, this message translates to:
  /// **'No failures recorded in this audit!'**
  String get s13NoFails;

  /// No description provided for @s13Finding.
  ///
  /// In en, this message translates to:
  /// **'Finding: {finding}'**
  String s13Finding(String finding);

  /// No description provided for @s13Cro.
  ///
  /// In en, this message translates to:
  /// **'CRO: {name}'**
  String s13Cro(String name);

  /// No description provided for @s13LinkedCap.
  ///
  /// In en, this message translates to:
  /// **'Linked CAP'**
  String get s13LinkedCap;

  /// No description provided for @s13CreateCap.
  ///
  /// In en, this message translates to:
  /// **'+ Create CAP'**
  String get s13CreateCap;

  /// No description provided for @s13NotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Auditor Notes'**
  String get s13NotesTitle;

  /// No description provided for @s13ExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get s13ExportPdf;

  /// No description provided for @s13ExportPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'PDF export is scheduled for Phase 2'**
  String get s13ExportPdfTooltip;

  /// No description provided for @s13ShareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share to WhatsApp'**
  String get s13ShareWhatsApp;

  /// No description provided for @s13ShareWhatsAppTooltip.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp share is scheduled for Phase 2'**
  String get s13ShareWhatsAppTooltip;

  /// No description provided for @s13VerifyAudit.
  ///
  /// In en, this message translates to:
  /// **'Verify Audit'**
  String get s13VerifyAudit;

  /// No description provided for @s13VerifyAuditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Audit verification is scheduled for Phase 2'**
  String get s13VerifyAuditTooltip;

  /// No description provided for @s13NotFound.
  ///
  /// In en, this message translates to:
  /// **'Audit not found'**
  String get s13NotFound;

  /// No description provided for @s13BackToHistory.
  ///
  /// In en, this message translates to:
  /// **'Back to Audit History'**
  String get s13BackToHistory;

  /// No description provided for @s13RefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh audit detail'**
  String get s13RefreshTooltip;

  /// No description provided for @s13ViewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Evidence Photo'**
  String get s13ViewPhoto;

  /// No description provided for @s13Close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get s13Close;

  /// No description provided for @s13Loading.
  ///
  /// In en, this message translates to:
  /// **'Loading audit details...'**
  String get s13Loading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
