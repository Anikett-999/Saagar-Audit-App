// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Saagar Audit';

  @override
  String get navHome => 'Home';

  @override
  String get navAudits => 'Audits';

  @override
  String get navCaps => 'CAPs';

  @override
  String get navReference => 'Reference';

  @override
  String get navSettings => 'Settings';

  @override
  String get navReports => 'Reports';

  @override
  String get btnStartAudit => 'Start Audit';

  @override
  String get btnSubmit => 'Submit';

  @override
  String get btnSaveDraft => 'Save Draft';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnContinue => 'Continue';

  @override
  String get btnBack => 'Back';

  @override
  String get btnNext => 'Next';

  @override
  String get btnPrevious => 'Previous';

  @override
  String get btnPass => 'Pass';

  @override
  String get btnFail => 'Fail';

  @override
  String get btnNa => 'N/A';

  @override
  String get btnAddPhoto => 'Add Photo';

  @override
  String get btnRetake => 'Retake';

  @override
  String get btnUsePhoto => 'Use Photo';

  @override
  String get btnCreateCap => 'Create CAP';

  @override
  String get btnMarkDone => 'Mark Done';

  @override
  String get btnVerify => 'Verify';

  @override
  String get btnCloseCap => 'Close CAP';

  @override
  String get btnReopen => 'Reopen';

  @override
  String get btnExtend => 'Extend';

  @override
  String get btnEscalate => 'Escalate';

  @override
  String get btnExportPdf => 'Export PDF';

  @override
  String get btnShareWhatsapp => 'Share on WhatsApp';

  @override
  String get btnLogin => 'Login';

  @override
  String get btnLogout => 'Logout';

  @override
  String get btnChangePin => 'Change PIN';

  @override
  String get btnAdd => 'Add';

  @override
  String get btnEdit => 'Edit';

  @override
  String get btnDelete => 'Delete';

  @override
  String get btnDeactivate => 'Deactivate';

  @override
  String get bandExcellent => 'Excellent';

  @override
  String get bandGood => 'Good';

  @override
  String get bandFair => 'Fair';

  @override
  String get bandPoor => 'Poor';

  @override
  String get bandCritical => 'Critical';

  @override
  String get capStatusOpen => 'Open';

  @override
  String get capStatusDone => 'Done';

  @override
  String get capStatusVerified => 'Verified';

  @override
  String get capStatusClosed => 'Closed';

  @override
  String get capStatusAged => 'Aged';

  @override
  String get capStatusReopened => 'Reopened';

  @override
  String get auditStatusDraft => 'Draft';

  @override
  String get auditStatusSubmitted => 'Submitted';

  @override
  String get auditStatusVerified => 'Verified';

  @override
  String get auditStatusHidden => 'Hidden';

  @override
  String get errWrongPin => 'Wrong PIN. Please try again.';

  @override
  String errLocked(int seconds) {
    return 'Too many wrong attempts. Try again in $seconds seconds.';
  }

  @override
  String get errRequiredField => 'This field is required.';

  @override
  String get errFutureDate => 'Audit date cannot be in the future.';

  @override
  String get errPhotoRequired =>
      'Photo evidence is required for Cash and Inventory Fails.';

  @override
  String get errFindingRequired =>
      'Please describe the finding (up to 200 characters).';

  @override
  String get errNoInternet =>
      'No internet — saving locally. Will sync when reconnected.';

  @override
  String get errCapDeadlinePassed => 'CAP deadline has passed. Cannot extend.';

  @override
  String get errCannotEditSubmitted => 'Submitted audits cannot be edited.';

  @override
  String get okAuditSubmitted => 'Audit submitted.';

  @override
  String get okCapCreated => 'CAP created.';

  @override
  String get okCapMarkedDone => 'CAP marked done.';

  @override
  String get okCapVerified => 'CAP verified.';

  @override
  String get okCapClosed => 'CAP closed.';

  @override
  String get okPinChanged => 'PIN changed.';

  @override
  String get okSynced => 'Synced with cloud.';

  @override
  String get s02Title => 'Choose your language';

  @override
  String get s02ChooseEnglish => 'English';

  @override
  String get s02ChooseMarathi => 'मराठी';

  @override
  String get s02Note => 'You can change this later from Settings.';

  @override
  String get s03Title => 'First-time setup';

  @override
  String get s03Subtitle => 'Welcome. Let\'s create your Owner account.';

  @override
  String get s03OwnerName => 'Owner name';

  @override
  String get s03OwnerPin => 'Choose a 4-digit PIN';

  @override
  String get s03ReenterPin => 'Re-enter your PIN';

  @override
  String get s03ConfirmPin => 'Confirm PIN';

  @override
  String get s03PinsMismatch => 'PINs do not match. Choose a new PIN.';

  @override
  String get s03NameTooShort => 'Please enter your name (2+ characters).';

  @override
  String get s03AddTeamLater => 'I\'ll add my team later';

  @override
  String get s04SelectName => 'Select your name';

  @override
  String get s04EnterPin => 'Enter your 4-digit PIN';

  @override
  String get s04ForgotPin => 'Forgot PIN?';

  @override
  String get s04ForgotPinHelp =>
      'Ask the Owner to reset your PIN from Settings → Manage Users.';

  @override
  String s04LockedCountdown(int seconds) {
    return 'Locked. Try again in ${seconds}s.';
  }

  @override
  String s04WrongPinAttemptsLeft(int attempts) {
    return 'Wrong PIN. $attempts attempts left.';
  }

  @override
  String s04TooManyAttempts(int seconds) {
    return 'Too many wrong attempts. Try again in ${seconds}s.';
  }

  @override
  String s05Hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get s05RoleOwner => 'OWNER';

  @override
  String get s05RoleSm => 'STORE MANAGER';

  @override
  String get s05RoleGm => 'GENERAL MANAGER';

  @override
  String get s05TodayDailyAudit => 'Today\'s daily audit';

  @override
  String get s05NotStartedYet => 'You haven\'t started today\'s audit yet.';

  @override
  String get s05NotStartedAdmin =>
      'Today\'s daily audit has not been started yet.';

  @override
  String get s05StartDailyAudit => 'Start daily audit';

  @override
  String get s05ResumeDraft => 'Resume draft';

  @override
  String get s05DraftInProgress =>
      'A draft audit is in progress. Resume to continue marking checkpoints.';

  @override
  String get s05SubmittedStatus => 'Submitted';

  @override
  String get s05DailyAuditsRunBySm =>
      'Daily audits are run by the Store Manager.';

  @override
  String get s05StatusNotStarted => 'Not started';

  @override
  String get s05StatusInProgress => 'In progress';

  @override
  String get s05StatusSubmitted => 'Submitted';

  @override
  String get s05AuditHistoryTitle => 'Audit history';

  @override
  String get s05AuditHistorySubtitle => 'View past daily audits';

  @override
  String get s05CapsTitle => 'CAPs';

  @override
  String get s05CapsSubtitle => 'Corrective Action Plans';

  @override
  String get s05ReferenceTitle => 'Reference';

  @override
  String get s05ReferenceSubtitle =>
      'Rating scale, escalation triggers, glossary';

  @override
  String get s05SettingsTitle => 'Settings';

  @override
  String get s05SettingsSubtitle => 'CROs, users, language, backup';

  @override
  String s05ComingSoon(String feature) {
    return '$feature is scheduled for Phase 1 Week 3+. Daily Audit flow (S06–S11) is currently active.';
  }

  @override
  String get s06Title => 'Start Daily Audit';

  @override
  String get s06AuditDate => 'Audit Date';

  @override
  String get s06StoreLabel => 'Store';

  @override
  String get s06CrosOnDuty => 'CROs on Duty';

  @override
  String get s06SelectAtLeastOneCro =>
      'Please select at least one CRO on duty.';

  @override
  String get s06BeginAudit => 'Begin Audit';

  @override
  String s07CheckpointNumber(int current, int total) {
    return 'Checkpoint $current of $total';
  }

  @override
  String get s07Pass => 'PASS';

  @override
  String get s07Fail => 'FAIL';

  @override
  String get s07Na => 'NA';

  @override
  String get s07NaReasonPrompt => 'Why is this checkpoint Not Applicable?';

  @override
  String get s07NaReasonHint => 'Enter reason (minimum 3 characters)...';

  @override
  String get s07Previous => 'Previous';

  @override
  String get s07Next => 'Next';

  @override
  String get s07FinishReview => 'Finish & Review';

  @override
  String get s08Title => 'Fail Detail';

  @override
  String get s08FindingLabel => 'Finding description';

  @override
  String get s08FindingHint => 'Describe the non-compliance...';

  @override
  String get s08CroInvolved => 'CRO involved (optional)';

  @override
  String get s08PhotoEvidence => 'Photo evidence';

  @override
  String get s08PhotoRequiredNotice =>
      'Photo is mandatory for this checkpoint.';

  @override
  String get s08SaveFail => 'Save Finding';

  @override
  String get s10Title => 'Review & Submit';

  @override
  String get s10ScoreCard => 'Audit Score';

  @override
  String get s10SopBreakdown => 'SOP Breakdown';

  @override
  String s10FailsTitle(int count) {
    return 'Non-Compliances ($count)';
  }

  @override
  String get s10NotesLabel => 'General notes (optional)';

  @override
  String get s10IncompleteWarning =>
      'All 68 checkpoints must be marked before submitting.';

  @override
  String get s10SubmitButton => 'Submit Audit';

  @override
  String get s10MissingPhotoWarning =>
      'Photo evidence is missing for one or more mandatory fail items.';

  @override
  String get s11Title => 'Audit Submitted';

  @override
  String get s11ConfirmationMessage =>
      'Today\'s daily audit has been successfully recorded.';

  @override
  String get s11ScoreLabel => 'Final Score';

  @override
  String get s11BandLabel => 'Band';

  @override
  String get s11OfflineSyncNotice => 'Will sync when online';

  @override
  String get s11ReturnHome => 'Return to Home';

  @override
  String get s27Title => 'Settings';

  @override
  String get s27AccountSection => 'Account';

  @override
  String get s27ManagementSection => 'Management';

  @override
  String get s27PreferencesSection => 'Preferences & Data';

  @override
  String get s27ManageCrosTitle => 'Manage CROs';

  @override
  String get s27ManageCrosSubtitle =>
      'View, add, edit, and deactivate retail staff';

  @override
  String get s27ManageUsersTitle => 'Manage Users';

  @override
  String get s27ManageUsersSubtitle =>
      'Add SM/GM staff, reset PINs, manage access';

  @override
  String get s27ChangePinTitle => 'Change PIN';

  @override
  String get s27ChangePinSubtitle => 'Update your 4-digit security PIN';

  @override
  String get s27LanguageTitle => 'Language / भाषा';

  @override
  String get s27LanguageSubtitle => 'Select English or मराठी';

  @override
  String get s27BackupExportTitle => 'Backup & Export';

  @override
  String get s27BackupExportSubtitle => 'Export database JSON and sync status';

  @override
  String get s27AboutTitle => 'About Saagar Audit';

  @override
  String get s27AboutSubtitle =>
      'Version, store information, and SOP specification';

  @override
  String get s27AboutDialogTitle => 'About Priority 1 Audit';

  @override
  String get s27AboutDialogBody =>
      'Saagar Traders SOP Audit Application\nTitan World (WLMHW) & Helios (HEMW)\nLatur, Maharashtra\nv1.0.0 (Phase 1)';

  @override
  String get s27CloseDialog => 'Close';

  @override
  String get s27OwnerBadge => 'Owner';

  @override
  String get s27GmBadge => 'General Manager';

  @override
  String get s27SmBadge => 'Store Manager';

  @override
  String get s28Title => 'Manage CROs';

  @override
  String get s28EmptyState => 'No CROs found. Tap + to add the first CRO.';

  @override
  String get s28StatusActive => 'Active';

  @override
  String get s28StatusInactive => 'Inactive';

  @override
  String get s28CounterLabel => 'Counter';

  @override
  String get s28CounterTitan => 'Titan';

  @override
  String get s28CounterHelios => 'Helios';

  @override
  String get s28ShiftLabel => 'Shift';

  @override
  String get s28ShiftMorning => 'Morning';

  @override
  String get s28ShiftAfternoon => 'Afternoon';

  @override
  String get s28ShiftFlexible => 'Flexible';

  @override
  String get s28AddCroTitle => 'Add CRO';

  @override
  String get s28EditCroTitle => 'Edit CRO';

  @override
  String get s28NameLabel => 'CRO Full Name';

  @override
  String get s28NameHint => 'e.g. Rahul Shinde';

  @override
  String get s28NameRequired =>
      'Please enter a valid name (minimum 2 characters)';

  @override
  String get s28StatusLabel => 'Active Status';

  @override
  String get s28ActiveHelp => 'Active CROs appear in audit dropdowns';

  @override
  String get s28SaveButton => 'Save';

  @override
  String get s28CancelButton => 'Cancel';

  @override
  String get s28EditAction => 'Edit';

  @override
  String get s28DeactivateAction => 'Deactivate';

  @override
  String get s28ReactivateAction => 'Reactivate';

  @override
  String get s28DeactivateConfirmTitle => 'Deactivate CRO?';

  @override
  String get s28DeactivateConfirmBody =>
      'This CRO will be hidden from new audits, but past audit records remain untouched.';

  @override
  String get s28CroAddedSuccess => 'CRO added successfully';

  @override
  String get s28CroUpdatedSuccess => 'CRO updated successfully';

  @override
  String get s28CroDeactivatedSuccess => 'CRO deactivated';

  @override
  String get s28CroReactivatedSuccess => 'CRO reactivated';

  @override
  String get s29Title => 'Manage Users';

  @override
  String get s29EmptyState => 'No users found.';

  @override
  String get s29AddUserTitle => 'Add User';

  @override
  String get s29NameLabel => 'Full Name';

  @override
  String get s29NameHint => 'e.g. Sachin Jadhav';

  @override
  String get s29NameRequired => 'Please enter a valid name (2–50 characters)';

  @override
  String get s29RoleLabel => 'Role';

  @override
  String get s29RoleSm => 'Store Manager (SM)';

  @override
  String get s29RoleGm => 'General Manager (GM)';

  @override
  String get s29PhoneLabel => 'Phone Number (Optional)';

  @override
  String get s29PhoneHint => '10-digit mobile number';

  @override
  String get s29PinLabel => '4-Digit PIN';

  @override
  String get s29PinConfirmLabel => 'Confirm 4-Digit PIN';

  @override
  String get s29PinRequired => 'Please enter a 4-digit numeric PIN';

  @override
  String get s29PinMismatch => 'PINs do not match';

  @override
  String get s29SaveButton => 'Save';

  @override
  String get s29CancelButton => 'Cancel';

  @override
  String get s29UserAddedSuccess => 'User created successfully';

  @override
  String get s29ResetPinAction => 'Reset PIN';

  @override
  String s29ResetPinTitle(String name) {
    return 'Reset PIN for $name';
  }

  @override
  String get s29NewPinLabel => 'New 4-Digit PIN';

  @override
  String get s29ConfirmNewPinLabel => 'Confirm New PIN';

  @override
  String get s29ResetPinSuccess => 'PIN reset successfully';

  @override
  String get s29DeactivateAction => 'Deactivate';

  @override
  String get s29ReactivateAction => 'Reactivate';

  @override
  String get s29DeactivateConfirmTitle => 'Deactivate User?';

  @override
  String get s29DeactivateConfirmBody =>
      'This user will no longer be able to log in, but all historical audit records remain untouched.';

  @override
  String get s29CannotDeactivateOwner =>
      'The Owner account cannot be deactivated per Spec §S29.';

  @override
  String get s29UserDeactivatedSuccess => 'User deactivated';

  @override
  String get s29UserReactivatedSuccess => 'User reactivated';

  @override
  String get s29OwnerRestrictedAccess => 'Access restricted to Owner only.';

  @override
  String get s29StatusActive => 'Active';

  @override
  String get s29StatusInactive => 'Inactive';

  @override
  String get s30Title => 'Change PIN';

  @override
  String get s30InstructionText =>
      'Enter your current PIN to verify your identity, then enter and confirm your new 4-digit security PIN.';

  @override
  String get s30CurrentPinLabel => 'Current 4-Digit PIN';

  @override
  String get s30CurrentPinHint => 'Enter your existing PIN';

  @override
  String get s30CurrentPinRequired => 'Please enter your current 4-digit PIN';

  @override
  String get s30CurrentPinIncorrect => 'Current PIN is incorrect';

  @override
  String get s30NewPinLabel => 'New 4-Digit PIN';

  @override
  String get s30NewPinHint => 'Enter new 4-digit PIN';

  @override
  String get s30NewPinRequired => 'Please enter a 4-digit numeric PIN';

  @override
  String get s30NewPinSameAsCurrent =>
      'New PIN must be different from current PIN';

  @override
  String get s30ConfirmPinLabel => 'Confirm New 4-Digit PIN';

  @override
  String get s30ConfirmPinHint => 'Re-enter new 4-digit PIN';

  @override
  String get s30PinMismatch => 'New PIN and confirmation do not match';

  @override
  String get s30SaveButton => 'Update PIN';

  @override
  String get s30PinChangedSuccess => 'PIN changed successfully';

  @override
  String get s31Title => 'Language / भाषा';

  @override
  String get s31Subtitle => 'Choose your preferred app language';

  @override
  String get s31Instruction =>
      'Select the language you want to use throughout the application. Changes apply immediately and are saved to your profile.';

  @override
  String get s31EnglishTitle => 'English';

  @override
  String get s31EnglishSubtitle => 'Default system language';

  @override
  String get s31MarathiTitle => 'मराठी (Marathi)';

  @override
  String get s31MarathiSubtitle => 'स्थानिक भाषा (Regional Language)';

  @override
  String get s31CurrentLanguageBadge => 'Current';

  @override
  String get s31LanguageUpdatedSuccess => 'Language preference saved';

  @override
  String get s32Title => 'Backup & Export';

  @override
  String get s32Subtitle => 'Local SQLite Database Export & Cloud Sync';

  @override
  String get s32ExportCardTitle => 'Export Local Database (JSON)';

  @override
  String get s32ExportCardDesc =>
      'Export all 14 SQLite tables into a timestamped JSON file in your device Downloads directory. Ideal for manual backups before app updates.';

  @override
  String get s32ExportSecurityNotice =>
      'Security Notice: Exported backup contains audit trails, findings, and bcrypt security hashes. Store and transfer this file securely.';

  @override
  String get s32ExportButton => 'Export Database JSON';

  @override
  String get s32Exporting => 'Exporting database...';

  @override
  String get s32ExportSuccessTitle => 'Export Successful';

  @override
  String s32ExportSuccessMessage(
      int records, int tables, String fileName, String path) {
    return 'Backup saved successfully ($records records across $tables tables).\n\nFile: $fileName\nPath:\n$path';
  }

  @override
  String s32ExportFailed(String error) {
    return 'Failed to export database: $error';
  }

  @override
  String get s32CloudSyncTitle => 'Cloud Synchronization (Firestore)';

  @override
  String get s32CloudSyncDesc =>
      'Automatic multi-device synchronization and cloud data storage via Google Cloud Firestore.';

  @override
  String get s32CloudSyncStatusLabel =>
      'Status: Offline-First Mode (Local SQLite)';

  @override
  String get s32CloudSyncPhase4Notice =>
      'Coming in Phase 4. All audits and settings are safely stored locally on this device.';

  @override
  String get s32CloudSyncComingSoonBadge => 'Coming in Phase 4';

  @override
  String get s32ForceSyncButton => 'Force Cloud Sync';

  @override
  String get s32AboutCardTitle => 'About Saagar Audit App';

  @override
  String get s32AboutVersion => 'Version: 0.1.0+1 (Phase 1 Baseline)';

  @override
  String get s32AboutStore =>
      'Stores: Titan World (WLMHW) & Helios (HEMW), Latur';

  @override
  String get s32AboutSpec => 'Specification: Saagar P1 Retail Audit Spec v1';

  @override
  String get s32OkButton => 'OK';

  @override
  String get s32CopyPath => 'Copy Path';

  @override
  String get s32PathCopied => 'Backup path copied to clipboard';

  @override
  String get s32ShareFile => 'Share / Save File';

  @override
  String get s14Title => 'Corrective Action Plans';

  @override
  String get s14Subtitle => 'Track and resolve audit findings';

  @override
  String get s14SearchHint => 'Search by problem statement or CAP ID...';

  @override
  String get s14FilterAll => 'All';

  @override
  String get s14FilterOpen => 'Open';

  @override
  String get s14FilterDone => 'Done (pending verify)';

  @override
  String get s14FilterAged => 'Aged ⚠';

  @override
  String get s14FilterClosed => 'Closed';

  @override
  String get s14EmptyTitle => 'No CAPs Found';

  @override
  String get s14EmptyDesc => 'No corrective actions match the selected filter.';

  @override
  String get s14NewCapButton => 'New CAP';

  @override
  String get s14StatusOpen => 'Open';

  @override
  String get s14StatusDone => 'Done';

  @override
  String get s14StatusVerified => 'Verified';

  @override
  String get s14StatusClosed => 'Closed';

  @override
  String get s14StatusAged => 'Aged';

  @override
  String get s14StatusReopened => 'Reopened';

  @override
  String s14DeadlineOverdue(String date) {
    return 'Overdue ($date)';
  }

  @override
  String s14DeadlineDueSoon(String date) {
    return 'Due Soon ($date)';
  }

  @override
  String s14DeadlineOk(String date) {
    return 'Due: $date';
  }

  @override
  String s14ResponsiblePrefix(String name) {
    return 'Responsible: $name';
  }

  @override
  String get s15Title => 'New Corrective Action Plan';

  @override
  String get s15Subtitle => '10-field root cause & action template';

  @override
  String get s15CapIdPreview => 'CAP ID (Auto-Generated)';

  @override
  String get s15SectionOrigin => '1. Originating Finding';

  @override
  String get s15OriginAudit => 'Origin Audit';

  @override
  String get s15OriginCheckpoint => 'Failed Checkpoint';

  @override
  String get s15SelectAudit => 'Select Audit';

  @override
  String get s15SelectCheckpoint => 'Select Checkpoint';

  @override
  String get s15NoAuditsFound => 'No audits found. Complete an audit first.';

  @override
  String get s15SectionProblem => '2. Problem & 5-Whys Analysis';

  @override
  String get s15ProblemStatement => 'Problem Statement';

  @override
  String get s15ProblemStatementHint => 'Describe what failed (1 sentence)';

  @override
  String get s15ProblemRequired => 'Problem statement is required';

  @override
  String get s15Why1 => 'Why 1 (Primary Cause)';

  @override
  String get s15Why1Hint => 'Why did this condition occur?';

  @override
  String get s15Why1Required => 'Why 1 is required';

  @override
  String get s15Why2 => 'Why 2 (optional)';

  @override
  String get s15Why2Hint => 'Why did that happen?';

  @override
  String get s15Why3 => 'Why 3 (optional)';

  @override
  String get s15Why3Hint => 'Why did that happen?';

  @override
  String get s15Why4 => 'Why 4 (optional)';

  @override
  String get s15Why4Hint => 'Why did that happen?';

  @override
  String get s15Why5 => 'Why 5 (optional)';

  @override
  String get s15Why5Hint => 'Why did that happen?';

  @override
  String get s15RootCause => 'Root Cause';

  @override
  String get s15RootCauseHint => 'Systemic root cause (1-2 sentences)';

  @override
  String get s15RootCauseRequired => 'Root cause is required';

  @override
  String get s15SectionActions => '3. Action Steps (3 to 5 steps)';

  @override
  String s15StepLabel(int number) {
    return 'Step $number';
  }

  @override
  String get s15StepHint => 'Action step description';

  @override
  String get s15StepRequired => 'Action step cannot be empty';

  @override
  String get s15AddStep => 'Add Step';

  @override
  String get s15MinStepsNotice => 'At least 3 steps required';

  @override
  String get s15MaxStepsReached => 'Maximum 5 steps reached';

  @override
  String get s15SectionOwnership => '4. Ownership & Verification';

  @override
  String get s15ResponsibleUser => 'Responsible (CAP Owner)';

  @override
  String get s15SelectResponsible => 'Select responsible user (SM, GM, Owner)';

  @override
  String get s15ResponsibleRequired => 'Responsible user is required';

  @override
  String get s15Deadline => 'Deadline (Target Completion Date)';

  @override
  String get s15SelectDate => 'Select Date';

  @override
  String get s15VerificationMethod => 'Verification Method';

  @override
  String get s15VerificationMethodHint => 'How will completion be verified?';

  @override
  String get s15VerificationRequired => 'Verification method is required';

  @override
  String get s15CreateButton => 'Create CAP';

  @override
  String get s15Creating => 'Creating CAP...';

  @override
  String get s15CreatedSuccess => 'CAP created successfully';

  @override
  String s15AuditDropdownItem(String date, String type) {
    return 'Audit $date ($type)';
  }

  @override
  String s15ErrorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get s16Title => 'CAP Detail';

  @override
  String get s16Subtitle => 'Corrective Action Plan';

  @override
  String get s16NotFound => 'CAP not found';

  @override
  String get s16BackToCaps => 'Back to CAP List';

  @override
  String get s16StatusOpen => 'Open';

  @override
  String get s16StatusDone => 'Done (Pending Verify)';

  @override
  String get s16StatusVerified => 'Verified';

  @override
  String get s16StatusClosed => 'Closed';

  @override
  String get s16StatusAged => 'Aged';

  @override
  String get s16StatusReopened => 'Reopened';

  @override
  String s16OverdueByDays(int days) {
    return 'Overdue by $days days';
  }

  @override
  String get s16DueToday => 'Due today';

  @override
  String get s16DueTomorrow => '1 day left (Due tomorrow)';

  @override
  String s16DaysRemaining(int days) {
    return '$days days left';
  }

  @override
  String s16CompletedOn(String date) {
    return 'Completed on $date';
  }

  @override
  String s16DeadlineLabel(String date) {
    return 'Deadline: $date';
  }

  @override
  String get s16SectionOrigin => '1. Origin Information';

  @override
  String get s16OriginAudit => 'Origin Audit';

  @override
  String get s16OriginCheckpoint => 'Origin Checkpoint';

  @override
  String get s16PatternBadge => 'Recurring Issue (Pattern)';

  @override
  String get s16SectionAnalysis => '2. Problem & 5-Whys Analysis';

  @override
  String get s16ProblemStatement => 'Problem Statement';

  @override
  String s16WhyLabel(int number) {
    return 'Why $number';
  }

  @override
  String get s16RootCause => 'Root Cause';

  @override
  String get s16SectionOwnership => '3. Ownership & Verification';

  @override
  String get s16ResponsibleUser => 'Responsible (CAP Owner)';

  @override
  String get s16CreatedBy => 'Created By';

  @override
  String s16OpenedAt(String date) {
    return 'Opened: $date';
  }

  @override
  String get s16VerificationMethod => 'Verification Method';

  @override
  String s16AgedCount(int count) {
    return 'Aged: $count times';
  }

  @override
  String s16ExtensionCount(int count) {
    return 'Extensions: $count';
  }

  @override
  String s16LatestExtensionReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String s16SectionActionSteps(int done, int total) {
    return '4. Action Steps ($done/$total)';
  }

  @override
  String s16StepLabel(int number) {
    return 'Step $number';
  }

  @override
  String s16ActionDoneBy(String user, String date) {
    return 'Done by $user on $date';
  }

  @override
  String get s16OnlyResponsibleCanToggle =>
      'Only the assigned responsible user can check off action steps.';

  @override
  String get s16CapAlreadyDoneNotice =>
      'CAP is already marked done. Action steps cannot be edited.';

  @override
  String get s16MarkDoneButton => 'Mark CAP Done';

  @override
  String get s16CompleteAllStepsToMarkDone =>
      'Complete all action steps to enable Mark Done';

  @override
  String get s16VerifyButton => 'Verify CAP';

  @override
  String get s16CloseButton => 'Close CAP';

  @override
  String get s16RequestExtensionButton => 'Request Extension';

  @override
  String get s16ReopenButton => 'Reopen CAP';

  @override
  String get s16Phase2Notice => 'Phase 2 (Coming Soon)';

  @override
  String get s16SectionTimeline => '5. Event Timeline';

  @override
  String get s16EventCreated => 'CAP Created';

  @override
  String get s16EventActionDone => 'Action Step Completed';

  @override
  String get s16EventActionUndone => 'Action Step Reopened';

  @override
  String get s16EventMarkedDone => 'Marked Done (Pending Verification)';

  @override
  String get s16EventVerified => 'Verified by Management';

  @override
  String get s16EventClosed => 'CAP Closed';

  @override
  String get s16EventExtended => 'Deadline Extended';

  @override
  String get s16EventAged => 'Marked Aged';

  @override
  String get s16EventReopened => 'CAP Reopened';

  @override
  String get s16ActorSystem => 'System';

  @override
  String s16ActorPrefix(String user) {
    return 'By $user';
  }

  @override
  String s16ActionToggleFailed(String error) {
    return 'Failed to update action step: $error';
  }

  @override
  String get s16RefreshTooltip => 'Refresh';

  @override
  String get s16WhysSubheader => '5 Whys';

  @override
  String get s16NoTimelineEntries => 'No timeline entries';

  @override
  String get s17Title => 'Mark CAP Done';

  @override
  String get s17Subtitle => 'Confirm completion & submit for verification';

  @override
  String get s17ProblemStatement => 'Problem Statement';

  @override
  String get s17Responsible => 'Responsible';

  @override
  String get s17SectionCompletedSteps => 'Completed Action Steps';

  @override
  String s17AllStepsCompletedNotice(int count) {
    return 'All $count action steps have been completed.';
  }

  @override
  String get s17IncompleteStepsWarning =>
      'Warning: Incomplete action steps remain. You must complete all action steps before marking this CAP done.';

  @override
  String get s17SectionDoneNotes => 'Done Notes / Reflection (optional)';

  @override
  String get s17DoneNotesHint =>
      'Describe how the issue was resolved or notes for verification...';

  @override
  String get s17SectionEvidencePhoto => 'Completion Evidence Photo (optional)';

  @override
  String get s17TakePhoto => 'Take Photo';

  @override
  String get s17RetakePhoto => 'Retake Photo';

  @override
  String get s17RemovePhoto => 'Remove Photo';

  @override
  String get s17PhotoAttached => '1 photo attached';

  @override
  String get s17AdvisoryCard =>
      'Marking this CAP done will transition its status to \'Done (Pending Verification)\'. Management (GM/Owner) will be notified to review and verify this corrective action.';

  @override
  String get s17ConfirmButton => 'Confirm & Mark Done';

  @override
  String get s17CancelButton => 'Cancel';

  @override
  String get s17Submitting => 'Marking Done...';

  @override
  String s17SuccessSnackbar(String id) {
    return 'CAP $id marked done (Pending Verification)';
  }

  @override
  String s17ErrorSnackbar(String error) {
    return 'Failed to mark CAP done: $error';
  }

  @override
  String s17StepNumber(int number) {
    return 'Step $number';
  }

  @override
  String get s17CapNotFound => 'CAP not found';

  @override
  String get s17Loading => 'Loading CAP details...';

  @override
  String get s17CapAlreadyDoneNotice =>
      'This CAP is already marked done or closed.';

  @override
  String get s12Title => 'Audit History';

  @override
  String get s12Subtitle => 'View past audits and compliance records';

  @override
  String get s12FilterAll => 'All';

  @override
  String get s12FilterDaily => 'Daily';

  @override
  String get s12FilterUnverified => 'Unverified';

  @override
  String get s12FilterWeekly => 'Weekly (Phase 2)';

  @override
  String get s12FilterMonthly => 'Monthly (Phase 3)';

  @override
  String get s12NoAuditsFound => 'No audits found';

  @override
  String get s12NoAuditsMatchFilter => 'No audits match the selected filter.';

  @override
  String get s12CompleteAuditPrompt =>
      'Complete and submit a daily audit to view history here.';

  @override
  String s12Auditor(String name) {
    return 'Auditor: $name';
  }

  @override
  String s12Date(String date) {
    return 'Date: $date';
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
      other: '$count Fails',
      one: '1 Fail',
      zero: '0 Fails',
    );
    return '$_temp0';
  }

  @override
  String get s12StatusSubmitted => 'Submitted';

  @override
  String get s12StatusVerified => 'Verified';

  @override
  String get s12Loading => 'Loading audit history...';

  @override
  String get s12TypeDaily => 'Daily';

  @override
  String get s12TypeWeekly => 'Weekly';

  @override
  String get s12TypeMonthly => 'Monthly';

  @override
  String get s12BandExcellent => 'Excellent';

  @override
  String get s12BandGood => 'Good';

  @override
  String get s12BandFair => 'Fair';

  @override
  String get s12BandPoor => 'Poor';

  @override
  String get s12BandCritical => 'Critical';

  @override
  String get s12BandPending => 'Pending';

  @override
  String get s12RefreshTooltip => 'Refresh audit history';

  @override
  String get s12FilterWeeklyTooltip => 'Weekly Audit is scheduled for Phase 2';

  @override
  String get s12FilterMonthlyTooltip =>
      'Monthly Audit is scheduled for Phase 3';
}
