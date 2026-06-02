// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get emailRequired => 'Required';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordRequired => 'Required';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get offlineBannerLogin =>
      'Offline Mode — Login requires internet connection';

  @override
  String get activationAccount => 'Account Activation';

  @override
  String get invitationTitle => 'Enter Invitation Link';

  @override
  String get invitationDescription =>
      'Paste the link you received from your Admin to activate your account.';

  @override
  String get invitationHint => 'https://...';

  @override
  String get proceed => 'Continue';

  @override
  String get welcomeTitle => 'Easily Manage Your Career';

  @override
  String get welcomeSubtitle =>
      'HR management that\'s simpler,\nefficient, and transparent.';

  @override
  String get startNow => 'Get Started Now';

  @override
  String get homeTitle => 'Home';

  @override
  String get attendance => 'Attendance';

  @override
  String get history => 'History';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get myProfile => 'My Profile';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileDesc => 'Update your personal information';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordDesc => 'Update your password';

  @override
  String get application => 'Application';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get helpCenterDesc => 'FAQ and user guide';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get sendFeedbackDesc => 'Help us improve';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyDesc => 'Your data protection';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get termsConditionsDesc => 'App usage terms';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get madeWithLove => 'Developed by Tech Team of SRT';

  @override
  String get welcome => 'Welcome';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get greetingHello => 'Hello,';

  @override
  String get clockInNow => 'Clock In';

  @override
  String get clockOutNow => 'Clock Out';

  @override
  String get attendanceDone => 'Done';

  @override
  String get waitingApproval => 'Awaiting Approval';

  @override
  String get attendanceRejected => 'Rejected';

  @override
  String get dayOff => 'Day Off';

  @override
  String get workDuration => 'Work Duration';

  @override
  String get shiftLabel => 'Shift';

  @override
  String get leaveBalance => 'Leave Balance';

  @override
  String get salary => 'Salary';

  @override
  String get thr => 'THR Bonus';

  @override
  String get faceEnrollTitle => 'Face Registration Required';

  @override
  String get faceEnrollDesc =>
      'To perform attendance, you need to register your face first.';

  @override
  String get faceEnrollLater => 'Later';

  @override
  String get faceEnrollNow => 'Register Now';

  @override
  String get attendanceCheckIn => 'Check In';

  @override
  String get attendanceCheckOut => 'Check Out';

  @override
  String attendanceCheckInDesc(Object time) {
    return 'You checked in at $time';
  }

  @override
  String attendanceCheckOutDesc(Object time) {
    return 'You checked out at $time';
  }

  @override
  String get payslipPublished => 'Payslip has been published.';

  @override
  String get submitted => 'Submitted';

  @override
  String get applyLeave => 'Apply Leave';

  @override
  String get applyOvertime => 'Apply Overtime';

  @override
  String get businessTrip => 'Business Trip';

  @override
  String submissionOf(Object type, Object date) {
    return 'Submission of $type on $date';
  }

  @override
  String salaryTitle(Object month) {
    return 'Salary for $month';
  }

  @override
  String leaveTotal(Object quota) {
    return 'Total quota: $quota days';
  }

  @override
  String get leaveBalanceLabel => 'Leave Balance';

  @override
  String durationHourMinute(Object hours, Object minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get leave => 'Leave';

  @override
  String get sick => 'Sick Leave';

  @override
  String get overtime => 'Overtime';

  @override
  String get reimbursement => 'Reimbursement';

  @override
  String get checkIn => 'Check In';

  @override
  String get checkOut => 'Check Out';

  @override
  String get viewHistory => 'View History';

  @override
  String get todayAttendance => 'Today\'s Attendance';

  @override
  String get notCheckedIn => 'Not Checked In Yet';

  @override
  String get checkedIn => 'Checked In';

  @override
  String get location => 'Location';

  @override
  String get time => 'Time';

  @override
  String get status => 'Status';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get submit => 'Submit';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get view => 'View';

  @override
  String get details => 'Details';

  @override
  String get date => 'Date';

  @override
  String get reason => 'Reason';

  @override
  String get notes => 'Notes';

  @override
  String get attachment => 'Attachment';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get submissions => 'Submissions';

  @override
  String get approvals => 'Approvals';

  @override
  String get mySubmissions => 'My Submissions';

  @override
  String get pendingApproval => 'Pending Approval';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get announcements => 'Announcements';

  @override
  String get notifications => 'Notifications';

  @override
  String get readAll => 'Read All';

  @override
  String get markAsRead => 'Mark as Read';

  @override
  String get payroll => 'Payroll';

  @override
  String get payslip => 'Payslip';

  @override
  String get viewPayslip => 'View Payslip';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get grossSalary => 'Gross Salary';

  @override
  String get netSalary => 'Net Salary';

  @override
  String get deductions => 'Deductions';

  @override
  String get allowances => 'Allowances';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get department => 'Department';

  @override
  String get position => 'Position';

  @override
  String get joinDate => 'Join Date';

  @override
  String get updateProfile => 'Update Profile';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordUpdated => 'Password Updated Successfully';

  @override
  String get enrollFace => 'Enroll Face';

  @override
  String get faceRecognition => 'Face Recognition';

  @override
  String get capturePhoto => 'Capture Photo';

  @override
  String get retake => 'Retake';

  @override
  String get confirm => 'Confirm';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get duration => 'Duration';

  @override
  String get days => 'Days';

  @override
  String get requestDate => 'Request Date';

  @override
  String get approvedBy => 'Approved By';

  @override
  String get rejectedBy => 'Rejected By';

  @override
  String get viewDetails => 'View Details';

  @override
  String get submissionType => 'Submission Type';

  @override
  String get amount => 'Amount';

  @override
  String get description => 'Description';

  @override
  String get receipt => 'Receipt';

  @override
  String get submittedOn => 'Submitted On';

  @override
  String get noData => 'No Data Available';

  @override
  String get loading => 'Loading...';

  @override
  String get refresh => 'Refresh';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get required => 'Required';

  @override
  String get optional => 'Optional';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get featureComingSoon => 'This feature will be available soon!';

  @override
  String get onboardingWelcomeTitle => 'Welcome to SOBAT HR';

  @override
  String get onboardingWelcomeDesc =>
      'Smart Operations & Business Administrative Tool for seamless workforce management';

  @override
  String get onboardingAttendanceTitle => 'Face Recognition Attendance';

  @override
  String get onboardingAttendanceDesc =>
      'Clock in/out securely with facial recognition and GPS verification - no more manual cards!';

  @override
  String get onboardingSubmissionsTitle => 'Digital Approvals';

  @override
  String get onboardingSubmissionsDesc =>
      'Submit leave, sick days, overtime, and reimbursements with real-time approval tracking';

  @override
  String get onboardingConnectedTitle => 'Your Payslip, Anytime';

  @override
  String get onboardingConnectedDesc =>
      'Access and download monthly payslips instantly, plus stay updated with company announcements';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get feedbackSubject => 'Subject';

  @override
  String get feedbackCategory => 'Category';

  @override
  String get feedbackDescription => 'Description';

  @override
  String get feedbackScreenshot => 'Attach Screenshot (Optional)';

  @override
  String get feedbackSubmit => 'Submit Feedback';

  @override
  String get feedbackSuccess => 'Feedback submitted successfully!';

  @override
  String get feedbackBug => 'Bug Report';

  @override
  String get feedbackFeature => 'Feature Request';

  @override
  String get feedbackComplaint => 'Complaint';

  @override
  String get feedbackQuestion => 'Question';

  @override
  String get feedbackOther => 'Other';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get errorLoadData => 'Failed to load data:';

  @override
  String get errorDownload => 'Failed to download:';

  @override
  String get slipDownloaded => 'Payslip successfully downloaded and opened';

  @override
  String get slipThrDownloaded => 'THR slip successfully downloaded';

  @override
  String get signFirst => 'Please sign first';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get downloadPayslip => 'Download Payslip';

  @override
  String get scanQrCodeTitle => 'Scan Attendance QR Code';

  @override
  String get permissionBlocked => 'Permission Blocked';

  @override
  String get workHourConfirmation => 'Work Hour Confirmation';

  @override
  String get noImLate => 'No, I\'m Late';

  @override
  String get yesImShifting => 'Yes, I\'m Shifting';

  @override
  String get startAttendance => 'Start Attendance';

  @override
  String get shiftStartTime => 'Shift Start Time';

  @override
  String get shiftEndTime => 'Shift End Time';

  @override
  String get continueScanQr => 'Continue Scan QR';

  @override
  String get confirmApproval => 'Confirm Approval';

  @override
  String get yesApprove => 'Yes, Approve';

  @override
  String get approvalSuccess => 'Submission successfully approved';

  @override
  String get confirmRejection => 'Confirm Rejection';

  @override
  String get provideRejectionReason => 'Provide rejection reason:';

  @override
  String get rejectionSuccess => 'Submission rejected';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get selfiePhoto => 'Selfie Photo';

  @override
  String get holdPhoneSteady => 'Hold phone steady (blurry image)';

  @override
  String get validUntilDec => 'Valid until Dec';

  @override
  String get notEligible => 'Not Eligible';

  @override
  String get leaveType => 'Leave';

  @override
  String get latestInformation => 'Latest Information';

  @override
  String get seeAll => 'See All';

  @override
  String get noLatestAnnouncement => 'No latest announcements';

  @override
  String get newsLabel => 'News';

  @override
  String get importantLabel => 'Important';

  @override
  String get announcementLabel => 'Announcement';

  @override
  String get readMore => 'Read more';

  @override
  String get viewPayslipShort => 'View slip';

  @override
  String get businessTripShort => 'Business Trip';

  @override
  String get approvalLabel => 'Approval';

  @override
  String get approvalSubtitle => 'Approval';

  @override
  String get quickMenu => 'Quick Menu';

  @override
  String get allLabel => 'All';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noRecentActivity => 'No recent activities.';

  @override
  String get doneLabel => 'Done';

  @override
  String contractExpiringIn(Object days, Object date) {
    return 'Your employment contract will expire in $days days ($date). Please contact HRD.';
  }

  @override
  String contractExpiringUrgent(Object days) {
    return 'URGENT: Contract expires in $days days!';
  }

  @override
  String contractExpired(Object date) {
    return 'Your employment contract has expired on $date. Please contact HRD.';
  }

  @override
  String get contractExpiredToday => 'YOUR EMPLOYMENT CONTRACT EXPIRES TODAY!';

  @override
  String pendingCountText(Object count) {
    return '$count pending';
  }

  @override
  String get lastPayslip => 'LAST PAYSLIP';

  @override
  String get dataNotAvailable => 'No data yet';

  @override
  String get dataAvailable => 'Data available';

  @override
  String get basicSalary => 'Basic Salary';

  @override
  String get allowance => 'Allowance';

  @override
  String get totalAmount => 'Total';

  @override
  String get statusProcess => 'Processing';

  @override
  String get statusNotAvailable => 'Not available';

  @override
  String get updatedAt => 'Updated';

  @override
  String get thrBonusTitle => 'THR BONUS';

  @override
  String get yearPrefix => 'Year';

  @override
  String get checkThrSlip => 'Check THR Slip';

  @override
  String get tapToViewHistory => '*Tap to view history';

  @override
  String get annualBonus => 'Annual Bonus';

  @override
  String get available => 'Available';
}
