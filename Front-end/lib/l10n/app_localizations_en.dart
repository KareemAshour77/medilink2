// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MediLink';

  @override
  String get tagline => 'Your Link to Doctors';

  @override
  String get splashTagline => 'Your Link to Doctors';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboarding1Title => 'AI Chat Bot';

  @override
  String get onboarding1Desc => 'AI chatbot analyzes your records and guides your care';

  @override
  String get onboarding2Title => 'Near By';

  @override
  String get onboarding2Desc => 'Find the nearest doctors, pharmacies and labs around you';

  @override
  String get onboarding3Title => 'Reminder';

  @override
  String get onboarding3Desc => 'Smart notifications for medications, appointments and tests';

  @override
  String get onboarding4Title => 'Medical Records';

  @override
  String get onboarding4Desc => 'Store all medical documents digitally scans, reports, prescriptions';

  @override
  String get welcomeCompanion => 'Your Everyday Medical Companion';

  @override
  String get welcomeDesc => 'Find doctors, buy medications, and keep all your medical records in one place.';

  @override
  String get signUp => 'Sign Up';

  @override
  String get logIn => 'Log In';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signIn => 'Sign In';

  @override
  String get helloThere => 'Hello there!';

  @override
  String get loginToContinue => 'Login to continue';

  @override
  String get emailOrPhone => 'Email';

  @override
  String get enterEmailOrPhone => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get login => 'Login';

  @override
  String get orSignInWith => 'or sign in with';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get completeProfile => 'Complete your Profile';

  @override
  String get onlyYouCanSee => 'Only you can see your personal info.';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'Full name';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get registerAs => 'Register as';

  @override
  String get patient => 'Patient';

  @override
  String get doctor => 'Doctor';

  @override
  String get pharmacy => 'Pharmacy';

  @override
  String get scan => 'Radiology Center';

  @override
  String get nationalId => 'National ID';

  @override
  String get nationalIdHint => 'National ID';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Email address';

  @override
  String get createPassword => 'Create a Password';

  @override
  String get newPasswordHint => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneVerificationDesc => 'We need your number for verification.';

  @override
  String get phoneHint => 'Phone number';

  @override
  String get fullNameReq => '*Full name is required';

  @override
  String get nationalIdReq => '*National ID is required';

  @override
  String get nationalIdMiss => '*National ID must be 14 digits';

  @override
  String get emailReq => '*Email is required';

  @override
  String get emailMissAt => '*Email must contain @';

  @override
  String get emailMissDot => '*Email must contain .com';

  @override
  String get newPasswordReq => 'Password is required';

  @override
  String get newPasswordUpp => 'Password must contain uppercase letter';

  @override
  String get newPasswordNum => 'Password must contain number';

  @override
  String get newPasswordSym => 'Password must contain symbol';

  @override
  String get confirmPasswordMatch => 'Password does not match';

  @override
  String hiUser(Object name) {
    return 'Hi, $name ';
  }

  @override
  String get howAreYou => 'How are you today?';

  @override
  String get searchHint => 'Search doctor, pharmacy...';

  @override
  String get doctors => 'Doctors';

  @override
  String get pharmacy2 => 'Pharmacy';

  @override
  String get labs => 'Labs';

  @override
  String get scans => 'Radiology Centers';

  @override
  String get seeAll => 'See All';

  @override
  String get aiAssistantTitle => 'AI Health Assistant';

  @override
  String get aiAssistantDesc => 'Ask anything about your\nhealth, records or doctors';

  @override
  String get chatNow => 'Chat Now  →';

  @override
  String get upcomingSchedule => 'Upcoming Schedule';

  @override
  String get topDoctors => 'Top Nearest Doctors';

  @override
  String get topPharmacy => 'Top Nearest Pharmacy';

  @override
  String get topLabs => 'Top Nearest Labs';

  @override
  String get topScans => 'Top Nearest Radiology Centers';

  @override
  String get take => 'Take';

  @override
  String get reviews => 'reviews';

  @override
  String get reminders => 'Reminders';

  @override
  String get todaySchedule => 'Today\'s schedule';

  @override
  String takenToday(Object taken, Object total) {
    return '$taken of $total taken today';
  }

  @override
  String get newReminder => 'New Reminder';

  @override
  String get editReminder => 'Edit Reminder';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get docicon => 'Doctor 🩺';

  @override
  String get type => 'Type';

  @override
  String get medicine => '💊 Medicine';

  @override
  String get nameMedi => 'Medicine Name';

  @override
  String get form => 'Form';

  @override
  String get dosePerIntake => 'Dose per intake';

  @override
  String get takeIt => 'Take it';

  @override
  String get beforeMeal => '🍽️  Before meal';

  @override
  String get afterMeal => '🍽️  After meal';

  @override
  String get withFood => '🥗  With food';

  @override
  String get anytime => '⏱️  Anytime';

  @override
  String get priority => 'Priority';

  @override
  String get high => '🔴  High';

  @override
  String get normal => '🟡  Normal';

  @override
  String get low => '🟢  Low';

  @override
  String get pickAColor => 'Pick a color';

  @override
  String get color => 'Color';

  @override
  String get tapToChangeColor => 'Tap to change color';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get repeatOn => 'Repeat on';

  @override
  String get duration => 'Duration';

  @override
  String get noEndDate => 'No end date';

  @override
  String get holdToEdit => 'Hold to edit  •  Swipe left to delete';

  @override
  String get ateAlready => 'Ate already';

  @override
  String get noRemindersYet => 'No reminders yet';

  @override
  String get tapToAddOne => 'Tap + to add one';

  @override
  String get doneTick => 'Done ✓';

  @override
  String get medicalRecords => 'Medical Records';

  @override
  String documentsStored(Object count) {
    return '$count documents stored';
  }

  @override
  String get menu => 'Menu';

  @override
  String get nearBy => 'Near By';

  @override
  String get myProfile => 'My Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get aiChatBot => 'AI Chat Bot';

  @override
  String get askAnything => 'Ask anything about your health';

  @override
  String get open => 'Open';

  @override
  String get logOut => 'Log Out';

  @override
  String get home => 'Home';

  @override
  String get reminder => 'Reminder';

  @override
  String get records => 'Records';

  @override
  String get medibot => 'MediBot';

  @override
  String get online => 'Online';

  @override
  String get typingHint => 'Type a message...';

  @override
  String get medibotGreeting => 'Hello! I\'m MediBot 👋\nHow can I help you today?';

  @override
  String get medibotTyping => 'MediBot is typing...';

  @override
  String get quickReply1 => 'Show my records';

  @override
  String get quickReply2 => 'Book appointment';

  @override
  String get quickReply3 => 'Medication schedule';

  @override
  String get quickReply4 => 'Nearby pharmacy';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get tablets => 'Tablets';

  @override
  String get capsules => 'Capsules';

  @override
  String get powders => 'Powders';

  @override
  String get lozenges => 'Lozenges';

  @override
  String get syrups => 'Syrups';

  @override
  String get dropsEye => 'Drops Eye';

  @override
  String get dropsEar => 'Drops Ear';

  @override
  String get dropsNasal => 'Drops Nasal';

  @override
  String get injections => 'Injections';

  @override
  String get creamsOintmentsGel => 'Creams & Ointments & Gel';

  @override
  String get inhalers => 'Inhalers';

  @override
  String get suppositories => 'Suppositories';

  @override
  String get sublingualTablets => 'Sublingual Tablets';

  @override
  String get themes => 'Appearance';

  @override
  String get chooseTheme => 'Choose your preferred appearance';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemDefault => 'System default';

  @override
  String get followsDeviceSetting => 'Follows your device setting';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose your preferred language';

  @override
  String get labTest => 'Lab Tests';

  @override
  String get imaging => 'Imaging';

  @override
  String get prescriptions => 'Prescriptions';

  @override
  String get diagnosisTab => 'Diagnosis';

  @override
  String get allRecords => 'All Records';

  @override
  String get stableStatus => 'Stable';

  @override
  String get critical => 'Critical';

  @override
  String get pending => 'Pending';

  @override
  String get bloodTestResults => 'Blood Test Results';

  @override
  String get drAhmedHassanLab => 'Dr. Ahmed Hassan — Cairo Lab';

  @override
  String get bloodTestDiagnosis => 'Normal Blood Count with Slight Iron Deficiency';

  @override
  String get recheckNote => 'Recheck in 3 months. Patient responding well to diet changes.';

  @override
  String get ironDeficiency => 'Iron Deficiency';

  @override
  String get xRayChest => 'X-Ray Chest';

  @override
  String get radiologyCenterMaadi => 'Radiology Center — Maadi';

  @override
  String get clearLungsNote => 'Clear lungs, no abnormalities detected.';

  @override
  String get chestClearNote => 'Chest clear. Cough likely viral. Recommend rest and fluids.';

  @override
  String get viralCough => 'Viral Cough';

  @override
  String get drSaraClinic => 'Dr. Sara Mahmoud — Clinic';

  @override
  String get viralFluNote => 'Viral flu. Should resolve in 5-7 days with rest and fluids.';

  @override
  String get flu => 'Flu';

  @override
  String get cardiologyReport => 'Cardiology Report';

  @override
  String get drOmarClinic => 'Dr. Omar Khalil — Heart Clinic';

  @override
  String get arrhythmiaNote => 'Mild arrhythmia detected. Requires monitoring.';

  @override
  String get holterNote => 'Holter monitor for 24hrs scheduled. Avoid strenuous exercise until cleared';

  @override
  String get arrhythmia => 'Arrhythmia';

  @override
  String get mRIBrainScan => 'MRI Brain Scan';

  @override
  String get scanCenterHel => 'Scan Center — Heliopolis';

  @override
  String get migraineScanNote => 'No structural abnormalities. Migraine-related changes noted.';

  @override
  String get mriDoctorNote => 'MRI confirms migraine pattern. No tumors or lesions. Annual scan recommended.';

  @override
  String get migraine => 'Migraine';

  @override
  String get diabetesCheckup => 'Diabetes Checkup';

  @override
  String get drLaylaCenter => 'Dr. Layla Nour — Diabetes Center';

  @override
  String get diabetesDiagnosis => 'HbA1c elevated at 8.2%. Diabetes management required.';

  @override
  String get diabetesDoctorNote => 'HbA1c must drop below 7 in next 3 months. Dietitian referral given.';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get fluDiagnosis => 'Flu Diagnosis';

  @override
  String get drAhmedClinic => 'Dr. AhmedHassan — Clinic 3';

  @override
  String get fluDiagnosisText => 'Seasonal Influenza Type A';

  @override
  String get fluDoctorNote => 'Patient advised to stay home. Flu shot recommended next season.';

  @override
  String get verification => 'Verification';

  @override
  String get phoneVerification => 'Phone Verification';

  @override
  String get codeSentMessage => 'We sent a 4-digit code to your phone number.';

  @override
  String get didntReceiveCode => 'Didn\'t receive a code? ';

  @override
  String get resend => 'Resend code';

  @override
  String get verify => 'Verify';

  @override
  String get titleIsRequired => 'Title is required';

  @override
  String get doctorFacilityIsRequired => 'Doctor / Facility is required';

  @override
  String get diagnosisIsRequired => 'Diagnosis is required';

  @override
  String get selectAttachment => 'Select Attachment';

  @override
  String get addNewRecord => 'Add New Record';

  @override
  String get recordType => 'Record Type';

  @override
  String get recordTitle => 'Record Title';

  @override
  String get egBloodTest => 'e.g. Blood Test Results';

  @override
  String get doctorFacility => 'Doctor / Facility';

  @override
  String get egDoctorFacility => 'e.g. Dr. Ahmed Hassan — Cairo Lab';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get stable => 'Stable';

  @override
  String get diagnosisDescription => 'Diagnosis / Description';

  @override
  String get diagnosisHint => 'Describe the diagnosis or findings…';

  @override
  String get doctorNotes => 'Doctor Notes (optional)';

  @override
  String get doctorNotesHint => 'Any additional notes from the doctor…';

  @override
  String get attachments => 'Attachments';

  @override
  String get addFile => 'Add File';

  @override
  String get noAttachmentsYet => 'No attachments yet';

  @override
  String get saveRecord => 'Save Record';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get may => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String get prescription => 'Prescription';

  @override
  String get diagnosis => 'Diagnosis';

  @override
  String get drYoussef => 'Dr. Youssef Mohammed';

  @override
  String get gynecologist => 'Gynecologist';

  @override
  String get yrsExp14 => '14 yrs exp';

  @override
  String get drJana => 'Dr. Jana Wael';

  @override
  String get cardiology => 'Cardiology';

  @override
  String get yrsExp17 => '17 yrs exp';

  @override
  String get drAmr => 'Dr. Amr Adel';

  @override
  String get orthopedics => 'Orthopedics';

  @override
  String get yrsExp19 => '19 yrs exp';

  @override
  String get drMaya => 'Dr. Maya Tamer';

  @override
  String get pediatrics => 'Pediatrics';

  @override
  String get yrsExp21 => '21 yrs exp';

  @override
  String get drKareem => 'Dr. Kareem Ashour';

  @override
  String get generalPractitioner => 'General Practitioner';

  @override
  String get yrsExp15 => '15 yrs exp';

  @override
  String get drAya => 'Dr. Aya Bassem';

  @override
  String get internalMedicine => 'Internal Medicine';

  @override
  String get yrsExp10 => '10 yrs exp';

  @override
  String get drEhab => 'Dr. Ehab Hesham';

  @override
  String get pediatrician => 'Pediatrician';

  @override
  String get yrsExp12 => '12 yrs exp';

  @override
  String get drMohamed => 'Dr. Mohamed Hany';

  @override
  String get oncologist => 'Oncologist';

  @override
  String get yrsExp9 => '9 yrs exp';

  @override
  String get drSeif => 'Dr. Seif Mohamed';

  @override
  String get pulmonology => 'Pulmonology';

  @override
  String get yrsExp8 => '8 yrs exp';

  @override
  String get drAhmed => 'Dr. Ahmed Samy';

  @override
  String get cardiologist => 'Cardiologist';

  @override
  String get yrsExp20 => '20 yrs exp';

  @override
  String get drSara => 'Dr. Sara Hassan';

  @override
  String get dermatologist => 'Dermatologist';

  @override
  String get yrsExp7 => '7 yrs exp';

  @override
  String get drOmar => 'Dr. Omar Farouk';

  @override
  String get neurologist => 'Neurologist';

  @override
  String get yrsExp18 => '18 yrs exp';

  @override
  String get drMona => 'Dr. Mona Ali';

  @override
  String get neurosurgery => 'Neurosurgery';

  @override
  String get yrsExp22 => '22 yrs exp';

  @override
  String get book => 'view details';

  @override
  String get alNahda => 'Al Nahdi Pharmacy';

  @override
  String get kmAwayZeroThree => '0.3 km away';

  @override
  String get time1 => '8AM - 12AM';

  @override
  String get dawaa => 'Dawaa Pharmacy';

  @override
  String get kmAwayZeroSeven => '0.7 km away';

  @override
  String get time2 => '24 Hours';

  @override
  String get seif => 'Seif Pharmacy';

  @override
  String get kmAwayOneOne => '1.1 km away';

  @override
  String get time3 => '9AM - 11PM';

  @override
  String get cairo => 'Cairo Pharmacy';

  @override
  String get kmAwayOneEight => '1.8 km away';

  @override
  String get time4 => '8AM - 10PM';

  @override
  String get elEzaby => 'El Ezaby Pharmacy';

  @override
  String get kmAwayTwoTwo => '2.2 km away';

  @override
  String get time5 => '24 Hours';

  @override
  String get alphaMedical => 'Alpha Medical Lab';

  @override
  String get kmAwayZeroFive => '0.5 km away';

  @override
  String get time6 => '7AM - 9PM';

  @override
  String get nileDiagnostics => 'Nile Diagnostics';

  @override
  String get kmAwayOneZero => '1.0 km away';

  @override
  String get time7 => '8AM - 8PM';

  @override
  String get cairoCenter => 'Cairo Lab Center';

  @override
  String get kmAwayOneFour => '1.4 km away';

  @override
  String get time8 => '7AM - 10PM';

  @override
  String get elite => 'Elite Lab';

  @override
  String get kmAwayTwoZero => '2.0 km away';

  @override
  String get time9 => '8AM - 6PM';

  @override
  String get radiologyPlus => 'Radiology Plus';

  @override
  String get kmAwayZeroSix => '0.6 km away';

  @override
  String get time10 => '8AM - 10PM';

  @override
  String get mriScanCenter => 'MRI & Scan Center';

  @override
  String get kmAwayOneTwoo => '1.2 km away';

  @override
  String get time11 => '9AM - 9PM';

  @override
  String get cairoRadiology => 'Cairo Radiology';

  @override
  String get kmAwayOneSix => '1.6 km away';

  @override
  String get time12 => '8AM - 8PM';

  @override
  String get advancedImaging => 'Advanced Imaging';

  @override
  String get kmAwayTwoFive => '2.5 km away';

  @override
  String get time13 => '7AM - 7PM';

  @override
  String start(Object date) {
    return 'Start: $date';
  }
}
