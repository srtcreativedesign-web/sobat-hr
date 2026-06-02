import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

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
    Locale('id'),
  ];

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get passwordRequired;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @offlineBannerLogin.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode — Login requires internet connection'**
  String get offlineBannerLogin;

  /// No description provided for @activationAccount.
  ///
  /// In en, this message translates to:
  /// **'Account Activation'**
  String get activationAccount;

  /// No description provided for @invitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Invitation Link'**
  String get invitationTitle;

  /// No description provided for @invitationDescription.
  ///
  /// In en, this message translates to:
  /// **'Paste the link you received from your Admin to activate your account.'**
  String get invitationDescription;

  /// No description provided for @invitationHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get invitationHint;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get proceed;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Easily Manage Your Career'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'HR management that\'s simpler,\nefficient, and transparent.'**
  String get welcomeSubtitle;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Get Started Now'**
  String get startNow;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get editProfileDesc;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get changePasswordDesc;

  /// No description provided for @application.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get application;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @helpCenterDesc.
  ///
  /// In en, this message translates to:
  /// **'FAQ and user guide'**
  String get helpCenterDesc;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Help us improve'**
  String get sendFeedbackDesc;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data protection'**
  String get privacyPolicyDesc;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @termsConditionsDesc.
  ///
  /// In en, this message translates to:
  /// **'App usage terms'**
  String get termsConditionsDesc;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Developed by Tech Team of SRT'**
  String get madeWithLove;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @greetingHello.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get greetingHello;

  /// No description provided for @clockInNow.
  ///
  /// In en, this message translates to:
  /// **'Clock In'**
  String get clockInNow;

  /// No description provided for @clockOutNow.
  ///
  /// In en, this message translates to:
  /// **'Clock Out'**
  String get clockOutNow;

  /// No description provided for @attendanceDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get attendanceDone;

  /// No description provided for @waitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Approval'**
  String get waitingApproval;

  /// No description provided for @attendanceRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get attendanceRejected;

  /// No description provided for @dayOff.
  ///
  /// In en, this message translates to:
  /// **'Day Off'**
  String get dayOff;

  /// No description provided for @workDuration.
  ///
  /// In en, this message translates to:
  /// **'Work Duration'**
  String get workDuration;

  /// No description provided for @shiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shiftLabel;

  /// No description provided for @leaveBalance.
  ///
  /// In en, this message translates to:
  /// **'Leave Balance'**
  String get leaveBalance;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @thr.
  ///
  /// In en, this message translates to:
  /// **'THR Bonus'**
  String get thr;

  /// No description provided for @faceEnrollTitle.
  ///
  /// In en, this message translates to:
  /// **'Face Registration Required'**
  String get faceEnrollTitle;

  /// No description provided for @faceEnrollDesc.
  ///
  /// In en, this message translates to:
  /// **'To perform attendance, you need to register your face first.'**
  String get faceEnrollDesc;

  /// No description provided for @faceEnrollLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get faceEnrollLater;

  /// No description provided for @faceEnrollNow.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get faceEnrollNow;

  /// No description provided for @attendanceCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get attendanceCheckIn;

  /// No description provided for @attendanceCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get attendanceCheckOut;

  /// No description provided for @attendanceCheckInDesc.
  ///
  /// In en, this message translates to:
  /// **'You checked in at {time}'**
  String attendanceCheckInDesc(Object time);

  /// No description provided for @attendanceCheckOutDesc.
  ///
  /// In en, this message translates to:
  /// **'You checked out at {time}'**
  String attendanceCheckOutDesc(Object time);

  /// No description provided for @payslipPublished.
  ///
  /// In en, this message translates to:
  /// **'Payslip has been published.'**
  String get payslipPublished;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @applyLeave.
  ///
  /// In en, this message translates to:
  /// **'Apply Leave'**
  String get applyLeave;

  /// No description provided for @applyOvertime.
  ///
  /// In en, this message translates to:
  /// **'Apply Overtime'**
  String get applyOvertime;

  /// No description provided for @businessTrip.
  ///
  /// In en, this message translates to:
  /// **'Business Trip'**
  String get businessTrip;

  /// No description provided for @submissionOf.
  ///
  /// In en, this message translates to:
  /// **'Submission of {type} on {date}'**
  String submissionOf(Object type, Object date);

  /// No description provided for @salaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Salary for {month}'**
  String salaryTitle(Object month);

  /// No description provided for @leaveTotal.
  ///
  /// In en, this message translates to:
  /// **'Total quota: {quota} days'**
  String leaveTotal(Object quota);

  /// No description provided for @leaveBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave Balance'**
  String get leaveBalanceLabel;

  /// No description provided for @durationHourMinute.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHourMinute(Object hours, Object minutes);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @sick.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave'**
  String get sick;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @reimbursement.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement'**
  String get reimbursement;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @todayAttendance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Attendance'**
  String get todayAttendance;

  /// No description provided for @notCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not Checked In Yet'**
  String get notCheckedIn;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked In'**
  String get checkedIn;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// No description provided for @submissions.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get submissions;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @mySubmissions.
  ///
  /// In en, this message translates to:
  /// **'My Submissions'**
  String get mySubmissions;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApproval;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read All'**
  String get readAll;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @payslip.
  ///
  /// In en, this message translates to:
  /// **'Payslip'**
  String get payslip;

  /// No description provided for @viewPayslip.
  ///
  /// In en, this message translates to:
  /// **'View Payslip'**
  String get viewPayslip;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @grossSalary.
  ///
  /// In en, this message translates to:
  /// **'Gross Salary'**
  String get grossSalary;

  /// No description provided for @netSalary.
  ///
  /// In en, this message translates to:
  /// **'Net Salary'**
  String get netSalary;

  /// No description provided for @deductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get deductions;

  /// No description provided for @allowances.
  ///
  /// In en, this message translates to:
  /// **'Allowances'**
  String get allowances;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @joinDate.
  ///
  /// In en, this message translates to:
  /// **'Join Date'**
  String get joinDate;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password Updated Successfully'**
  String get passwordUpdated;

  /// No description provided for @enrollFace.
  ///
  /// In en, this message translates to:
  /// **'Enroll Face'**
  String get enrollFace;

  /// No description provided for @faceRecognition.
  ///
  /// In en, this message translates to:
  /// **'Face Recognition'**
  String get faceRecognition;

  /// No description provided for @capturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture Photo'**
  String get capturePhoto;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @requestDate.
  ///
  /// In en, this message translates to:
  /// **'Request Date'**
  String get requestDate;

  /// No description provided for @approvedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved By'**
  String get approvedBy;

  /// No description provided for @rejectedBy.
  ///
  /// In en, this message translates to:
  /// **'Rejected By'**
  String get rejectedBy;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @submissionType.
  ///
  /// In en, this message translates to:
  /// **'Submission Type'**
  String get submissionType;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted On'**
  String get submittedOn;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data Available'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available soon!'**
  String get featureComingSoon;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SOBAT HR'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart Operations & Business Administrative Tool for seamless workforce management'**
  String get onboardingWelcomeDesc;

  /// No description provided for @onboardingAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Face Recognition Attendance'**
  String get onboardingAttendanceTitle;

  /// No description provided for @onboardingAttendanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Clock in/out securely with facial recognition and GPS verification - no more manual cards!'**
  String get onboardingAttendanceDesc;

  /// No description provided for @onboardingSubmissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Approvals'**
  String get onboardingSubmissionsTitle;

  /// No description provided for @onboardingSubmissionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit leave, sick days, overtime, and reimbursements with real-time approval tracking'**
  String get onboardingSubmissionsDesc;

  /// No description provided for @onboardingConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Payslip, Anytime'**
  String get onboardingConnectedTitle;

  /// No description provided for @onboardingConnectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Access and download monthly payslips instantly, plus stay updated with company announcements'**
  String get onboardingConnectedDesc;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @feedbackSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get feedbackSubject;

  /// No description provided for @feedbackCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get feedbackCategory;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get feedbackDescription;

  /// No description provided for @feedbackScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Attach Screenshot (Optional)'**
  String get feedbackScreenshot;

  /// No description provided for @feedbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get feedbackSubmit;

  /// No description provided for @feedbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted successfully!'**
  String get feedbackSuccess;

  /// No description provided for @feedbackBug.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get feedbackBug;

  /// No description provided for @feedbackFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get feedbackFeature;

  /// No description provided for @feedbackComplaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get feedbackComplaint;

  /// No description provided for @feedbackQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get feedbackQuestion;

  /// No description provided for @feedbackOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackOther;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @errorLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data:'**
  String get errorLoadData;

  /// No description provided for @errorDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to download:'**
  String get errorDownload;

  /// No description provided for @slipDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Payslip successfully downloaded and opened'**
  String get slipDownloaded;

  /// No description provided for @slipThrDownloaded.
  ///
  /// In en, this message translates to:
  /// **'THR slip successfully downloaded'**
  String get slipThrDownloaded;

  /// No description provided for @signFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign first'**
  String get signFirst;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @downloadPayslip.
  ///
  /// In en, this message translates to:
  /// **'Download Payslip'**
  String get downloadPayslip;

  /// No description provided for @scanQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Attendance QR Code'**
  String get scanQrCodeTitle;

  /// No description provided for @permissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Permission Blocked'**
  String get permissionBlocked;

  /// No description provided for @workHourConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Work Hour Confirmation'**
  String get workHourConfirmation;

  /// No description provided for @noImLate.
  ///
  /// In en, this message translates to:
  /// **'No, I\'m Late'**
  String get noImLate;

  /// No description provided for @yesImShifting.
  ///
  /// In en, this message translates to:
  /// **'Yes, I\'m Shifting'**
  String get yesImShifting;

  /// No description provided for @startAttendance.
  ///
  /// In en, this message translates to:
  /// **'Start Attendance'**
  String get startAttendance;

  /// No description provided for @shiftStartTime.
  ///
  /// In en, this message translates to:
  /// **'Shift Start Time'**
  String get shiftStartTime;

  /// No description provided for @shiftEndTime.
  ///
  /// In en, this message translates to:
  /// **'Shift End Time'**
  String get shiftEndTime;

  /// No description provided for @continueScanQr.
  ///
  /// In en, this message translates to:
  /// **'Continue Scan QR'**
  String get continueScanQr;

  /// No description provided for @confirmApproval.
  ///
  /// In en, this message translates to:
  /// **'Confirm Approval'**
  String get confirmApproval;

  /// No description provided for @yesApprove.
  ///
  /// In en, this message translates to:
  /// **'Yes, Approve'**
  String get yesApprove;

  /// No description provided for @approvalSuccess.
  ///
  /// In en, this message translates to:
  /// **'Submission successfully approved'**
  String get approvalSuccess;

  /// No description provided for @confirmRejection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Rejection'**
  String get confirmRejection;

  /// No description provided for @provideRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Provide rejection reason:'**
  String get provideRejectionReason;

  /// No description provided for @rejectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Submission rejected'**
  String get rejectionSuccess;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @selfiePhoto.
  ///
  /// In en, this message translates to:
  /// **'Selfie Photo'**
  String get selfiePhoto;

  /// No description provided for @holdPhoneSteady.
  ///
  /// In en, this message translates to:
  /// **'Hold phone steady (blurry image)'**
  String get holdPhoneSteady;

  /// No description provided for @validUntilDec.
  ///
  /// In en, this message translates to:
  /// **'Valid until Dec'**
  String get validUntilDec;

  /// No description provided for @notEligible.
  ///
  /// In en, this message translates to:
  /// **'Not Eligible'**
  String get notEligible;

  /// No description provided for @leaveType.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveType;

  /// No description provided for @latestInformation.
  ///
  /// In en, this message translates to:
  /// **'Latest Information'**
  String get latestInformation;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @noLatestAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'No latest announcements'**
  String get noLatestAnnouncement;

  /// No description provided for @newsLabel.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get newsLabel;

  /// No description provided for @importantLabel.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get importantLabel;

  /// No description provided for @announcementLabel.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcementLabel;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @viewPayslipShort.
  ///
  /// In en, this message translates to:
  /// **'View slip'**
  String get viewPayslipShort;

  /// No description provided for @businessTripShort.
  ///
  /// In en, this message translates to:
  /// **'Business Trip'**
  String get businessTripShort;

  /// No description provided for @approvalLabel.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get approvalLabel;

  /// No description provided for @approvalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get approvalSubtitle;

  /// No description provided for @quickMenu.
  ///
  /// In en, this message translates to:
  /// **'Quick Menu'**
  String get quickMenu;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activities.'**
  String get noRecentActivity;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @contractExpiringIn.
  ///
  /// In en, this message translates to:
  /// **'Your employment contract will expire in {days} days ({date}). Please contact HRD.'**
  String contractExpiringIn(Object days, Object date);

  /// No description provided for @contractExpiringUrgent.
  ///
  /// In en, this message translates to:
  /// **'URGENT: Contract expires in {days} days!'**
  String contractExpiringUrgent(Object days);

  /// No description provided for @contractExpired.
  ///
  /// In en, this message translates to:
  /// **'Your employment contract has expired on {date}. Please contact HRD.'**
  String contractExpired(Object date);

  /// No description provided for @contractExpiredToday.
  ///
  /// In en, this message translates to:
  /// **'YOUR EMPLOYMENT CONTRACT EXPIRES TODAY!'**
  String get contractExpiredToday;

  /// No description provided for @pendingCountText.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCountText(Object count);

  /// No description provided for @lastPayslip.
  ///
  /// In en, this message translates to:
  /// **'LAST PAYSLIP'**
  String get lastPayslip;

  /// No description provided for @dataNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get dataNotAvailable;

  /// No description provided for @dataAvailable.
  ///
  /// In en, this message translates to:
  /// **'Data available'**
  String get dataAvailable;

  /// No description provided for @basicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic Salary'**
  String get basicSalary;

  /// No description provided for @allowance.
  ///
  /// In en, this message translates to:
  /// **'Allowance'**
  String get allowance;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalAmount;

  /// No description provided for @statusProcess.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcess;

  /// No description provided for @statusNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get statusNotAvailable;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedAt;

  /// No description provided for @thrBonusTitle.
  ///
  /// In en, this message translates to:
  /// **'THR BONUS'**
  String get thrBonusTitle;

  /// No description provided for @yearPrefix.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearPrefix;

  /// No description provided for @checkThrSlip.
  ///
  /// In en, this message translates to:
  /// **'Check THR Slip'**
  String get checkThrSlip;

  /// No description provided for @tapToViewHistory.
  ///
  /// In en, this message translates to:
  /// **'*Tap to view history'**
  String get tapToViewHistory;

  /// No description provided for @annualBonus.
  ///
  /// In en, this message translates to:
  /// **'Annual Bonus'**
  String get annualBonus;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @selfService.
  ///
  /// In en, this message translates to:
  /// **'SELF SERVICE'**
  String get selfService;

  /// No description provided for @manageWorkNeeds.
  ///
  /// In en, this message translates to:
  /// **'Manage your\nwork needs'**
  String get manageWorkNeeds;

  /// No description provided for @servicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} services'**
  String servicesCount(Object count);

  /// No description provided for @attendanceAndTime.
  ///
  /// In en, this message translates to:
  /// **'Attendance & Time'**
  String get attendanceAndTime;

  /// No description provided for @alignment.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get alignment;

  /// No description provided for @administration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @leaveMenuDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit annual leave or permit'**
  String get leaveMenuDesc;

  /// No description provided for @sickMenuDesc.
  ///
  /// In en, this message translates to:
  /// **'Sick leave'**
  String get sickMenuDesc;

  /// No description provided for @overtimeMenuDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit overtime'**
  String get overtimeMenuDesc;

  /// No description provided for @historyMenuDesc.
  ///
  /// In en, this message translates to:
  /// **'Submission history'**
  String get historyMenuDesc;

  /// No description provided for @thrMenuDesc.
  ///
  /// In en, this message translates to:
  /// **'Religious Holiday Allowance'**
  String get thrMenuDesc;

  /// No description provided for @businessTripMenuDesc.
  ///
  /// In en, this message translates to:
  /// **'Business Trip'**
  String get businessTripMenuDesc;

  /// No description provided for @reimbursementMenuDesc.
  ///
  /// In en, this message translates to:
  /// **'Claim expenses'**
  String get reimbursementMenuDesc;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(Object count);

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @noSubmissionWithStatus.
  ///
  /// In en, this message translates to:
  /// **'No submissions with status {status}'**
  String noSubmissionWithStatus(Object status);

  /// No description provided for @submissionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Submission Type'**
  String get submissionTypeLabel;

  /// No description provided for @permitLabel.
  ///
  /// In en, this message translates to:
  /// **'Permit'**
  String get permitLabel;

  /// No description provided for @resignationLabel.
  ///
  /// In en, this message translates to:
  /// **'Resignation'**
  String get resignationLabel;

  /// No description provided for @activeSubmissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get activeSubmissionTitle;

  /// No description provided for @dateRangeSeparator.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get dateRangeSeparator;

  /// No description provided for @photoSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo Source'**
  String get photoSourceTitle;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @signatureDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital Signature'**
  String get signatureDigital;

  /// No description provided for @uploadProofLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Proof / Receipt'**
  String get uploadProofLabel;

  /// No description provided for @doctorCertificate.
  ///
  /// In en, this message translates to:
  /// **'Doctor\'s Certificate'**
  String get doctorCertificate;

  /// No description provided for @photoDoctorCertificate.
  ///
  /// In en, this message translates to:
  /// **'Photo of Doctor\'s Certificate'**
  String get photoDoctorCertificate;

  /// No description provided for @photoItemOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo of Item (Optional)'**
  String get photoItemOptional;

  /// No description provided for @pleaseUploadDoctorCert.
  ///
  /// In en, this message translates to:
  /// **'Please upload doctor\'s certificate.'**
  String get pleaseUploadDoctorCert;

  /// No description provided for @pleaseSignSubmission.
  ///
  /// In en, this message translates to:
  /// **'Please sign the submission before sending.'**
  String get pleaseSignSubmission;

  /// No description provided for @submissionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Submission sent successfully'**
  String get submissionSuccess;

  /// No description provided for @submissionFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send submission: {error}'**
  String submissionFail(Object error);

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @overtimeHours.
  ///
  /// In en, this message translates to:
  /// **'Overtime Hours'**
  String get overtimeHours;

  /// No description provided for @startOvertime.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startOvertime;

  /// No description provided for @endOvertime.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endOvertime;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @brandOrMake.
  ///
  /// In en, this message translates to:
  /// **'Item / Brand'**
  String get brandOrMake;

  /// No description provided for @specification.
  ///
  /// In en, this message translates to:
  /// **'Specification'**
  String get specification;

  /// No description provided for @urgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgency;

  /// No description provided for @urgentCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Urgent / Pressing'**
  String get urgentCheckbox;

  /// No description provided for @urgentDesc.
  ///
  /// In en, this message translates to:
  /// **'Check if item is needed immediately'**
  String get urgentDesc;

  /// No description provided for @ineligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Eligible'**
  String get ineligibilityTitle;

  /// No description provided for @ineligibilityReasonDefault.
  ///
  /// In en, this message translates to:
  /// **'You are not eligible for leave.'**
  String get ineligibilityReasonDefault;

  /// No description provided for @ineligibilityCantSubmit.
  ///
  /// In en, this message translates to:
  /// **'You cannot submit leave.'**
  String get ineligibilityCantSubmit;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get iUnderstand;

  /// No description provided for @writeSubmissionDetail.
  ///
  /// In en, this message translates to:
  /// **'Write submission details here...'**
  String get writeSubmissionDetail;

  /// No description provided for @photoUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture image: {error}'**
  String photoUploadError(Object error);

  /// No description provided for @fileUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to select file: {error}'**
  String fileUploadError(Object error);

  /// No description provided for @resignationType.
  ///
  /// In en, this message translates to:
  /// **'Resignation Type'**
  String get resignationType;

  /// No description provided for @lastWorkingDate.
  ///
  /// In en, this message translates to:
  /// **'Last Working Date'**
  String get lastWorkingDate;

  /// No description provided for @nominalLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (Rp)'**
  String get nominalLabel;

  /// No description provided for @downloadProofButton.
  ///
  /// In en, this message translates to:
  /// **'Download Approval Proof'**
  String get downloadProofButton;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download: {error}'**
  String downloadFailed(Object error);

  /// No description provided for @approvalHistory.
  ///
  /// In en, this message translates to:
  /// **'Approval History'**
  String get approvalHistory;

  /// No description provided for @urgencyUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgencyUrgent;

  /// No description provided for @urgencyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get urgencyNormal;

  /// No description provided for @resignationDefaultType.
  ///
  /// In en, this message translates to:
  /// **'Normal One Month Notice'**
  String get resignationDefaultType;

  /// No description provided for @cutiDesc.
  ///
  /// In en, this message translates to:
  /// **'Apply for annual leave or special leave.'**
  String get cutiDesc;

  /// No description provided for @sakitDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload doctor\'s certificate for sick leave.'**
  String get sakitDesc;

  /// No description provided for @reimburseDesc.
  ///
  /// In en, this message translates to:
  /// **'Claim medical expenses, glasses, etc.'**
  String get reimburseDesc;

  /// No description provided for @lemburDesc.
  ///
  /// In en, this message translates to:
  /// **'Record overtime hours for approval.'**
  String get lemburDesc;

  /// No description provided for @dinasDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit out-of-town business travel request.'**
  String get dinasDesc;

  /// No description provided for @asetDesc.
  ///
  /// In en, this message translates to:
  /// **'Request office equipment or assets procurement.'**
  String get asetDesc;

  /// No description provided for @resignDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit resignation request.'**
  String get resignDesc;

  /// No description provided for @sisaCutiLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave Balance: {balance} Days'**
  String sisaCutiLabel(Object balance);

  /// No description provided for @reimbursementLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit: Rp 5,000,000'**
  String get reimbursementLimit;

  /// No description provided for @reimbursementTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Glasses, Client Lunch, etc.'**
  String get reimbursementTitleHint;

  /// No description provided for @brandHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Macbook, Dell, Logitech'**
  String get brandHint;

  /// No description provided for @specHint.
  ///
  /// In en, this message translates to:
  /// **'Explain required specifications...'**
  String get specHint;

  /// No description provided for @purposeLabel.
  ///
  /// In en, this message translates to:
  /// **'Purpose / Need'**
  String get purposeLabel;

  /// No description provided for @assetLabel.
  ///
  /// In en, this message translates to:
  /// **'Asset Request'**
  String get assetLabel;

  /// No description provided for @submissionDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission Detail'**
  String get submissionDetailTitle;

  /// No description provided for @onTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'On Time'**
  String get onTimeLabel;

  /// No description provided for @earlyLeaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Early Leave'**
  String get earlyLeaveLabel;

  /// No description provided for @lateLabel.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get lateLabel;

  /// No description provided for @absentLabel.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absentLabel;

  /// No description provided for @inProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgressLabel;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeTitle;

  /// No description provided for @featureUnderDevelopmentPart1.
  ///
  /// In en, this message translates to:
  /// **'Feature Under '**
  String get featureUnderDevelopmentPart1;

  /// No description provided for @featureUnderDevelopmentPart2.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get featureUnderDevelopmentPart2;

  /// No description provided for @featureUnderDevelopmentDesc.
  ///
  /// In en, this message translates to:
  /// **'We are designing future features to improve your productivity. Coming soon to your hands.'**
  String get featureUnderDevelopmentDesc;

  /// No description provided for @systemReadiness.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM READINESS'**
  String get systemReadiness;

  /// No description provided for @createSubmission.
  ///
  /// In en, this message translates to:
  /// **'Create Submission'**
  String get createSubmission;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
