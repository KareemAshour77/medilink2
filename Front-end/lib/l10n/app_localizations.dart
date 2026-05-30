import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ru'),
    Locale('tr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MediLink'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your Link to Doctors'**
  String get tagline;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Link to Doctors'**
  String get splashTagline;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'AI Chat Bot'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Desc.
  ///
  /// In en, this message translates to:
  /// **'AI chatbot analyzes your records and guides your care'**
  String get onboarding1Desc;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Near By'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Desc.
  ///
  /// In en, this message translates to:
  /// **'Find the nearest doctors, pharmacies and labs around you'**
  String get onboarding2Desc;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Desc.
  ///
  /// In en, this message translates to:
  /// **'Smart notifications for medications, appointments and tests'**
  String get onboarding3Desc;

  /// No description provided for @onboarding4Title.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get onboarding4Title;

  /// No description provided for @onboarding4Desc.
  ///
  /// In en, this message translates to:
  /// **'Store all medical documents digitally scans, reports, prescriptions'**
  String get onboarding4Desc;

  /// No description provided for @welcomeCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your Everyday Medical Companion'**
  String get welcomeCompanion;

  /// No description provided for @welcomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Find doctors, buy medications, and keep all your medical records in one place.'**
  String get welcomeDesc;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @helloThere.
  ///
  /// In en, this message translates to:
  /// **'Hello there!'**
  String get helloThere;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Login to continue'**
  String get loginToContinue;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailOrPhone;

  /// No description provided for @enterEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmailOrPhone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @orSignInWith.
  ///
  /// In en, this message translates to:
  /// **'or sign in with'**
  String get orSignInWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpTitle;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your Profile'**
  String get completeProfile;

  /// No description provided for @onlyYouCanSee.
  ///
  /// In en, this message translates to:
  /// **'Only you can see your personal info.'**
  String get onlyYouCanSee;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameHint;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @registerAs.
  ///
  /// In en, this message translates to:
  /// **'Register as'**
  String get registerAs;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @pharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacy;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Radiology Center'**
  String get scan;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @nationalIdHint.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalIdHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailHint;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a Password'**
  String get createPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'We need your number for verification.'**
  String get phoneVerificationDesc;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneHint;

  /// No description provided for @fullNameReq.
  ///
  /// In en, this message translates to:
  /// **'*Full name is required'**
  String get fullNameReq;

  /// No description provided for @nationalIdReq.
  ///
  /// In en, this message translates to:
  /// **'*National ID is required'**
  String get nationalIdReq;

  /// No description provided for @nationalIdMiss.
  ///
  /// In en, this message translates to:
  /// **'*National ID must be 14 digits'**
  String get nationalIdMiss;

  /// No description provided for @emailReq.
  ///
  /// In en, this message translates to:
  /// **'*Email is required'**
  String get emailReq;

  /// No description provided for @emailMissAt.
  ///
  /// In en, this message translates to:
  /// **'*Email must contain @'**
  String get emailMissAt;

  /// No description provided for @emailMissDot.
  ///
  /// In en, this message translates to:
  /// **'*Email must contain .com'**
  String get emailMissDot;

  /// No description provided for @newPasswordReq.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get newPasswordReq;

  /// No description provided for @newPasswordUpp.
  ///
  /// In en, this message translates to:
  /// **'Password must contain uppercase letter'**
  String get newPasswordUpp;

  /// No description provided for @newPasswordNum.
  ///
  /// In en, this message translates to:
  /// **'Password must contain number'**
  String get newPasswordNum;

  /// No description provided for @newPasswordSym.
  ///
  /// In en, this message translates to:
  /// **'Password must contain symbol'**
  String get newPasswordSym;

  /// No description provided for @confirmPasswordMatch.
  ///
  /// In en, this message translates to:
  /// **'Password does not match'**
  String get confirmPasswordMatch;

  /// No description provided for @hiUser.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} '**
  String hiUser(Object name);

  /// No description provided for @howAreYou.
  ///
  /// In en, this message translates to:
  /// **'How are you today?'**
  String get howAreYou;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search doctor, pharmacy...'**
  String get searchHint;

  /// No description provided for @doctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctors;

  /// No description provided for @pharmacy2.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacy2;

  /// No description provided for @labs.
  ///
  /// In en, this message translates to:
  /// **'Labs'**
  String get labs;

  /// No description provided for @scans.
  ///
  /// In en, this message translates to:
  /// **'Radiology Centers'**
  String get scans;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Health Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your\nhealth, records or doctors'**
  String get aiAssistantDesc;

  /// No description provided for @chatNow.
  ///
  /// In en, this message translates to:
  /// **'Chat Now  →'**
  String get chatNow;

  /// No description provided for @upcomingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Schedule'**
  String get upcomingSchedule;

  /// No description provided for @topDoctors.
  ///
  /// In en, this message translates to:
  /// **'Top Nearest Doctors'**
  String get topDoctors;

  /// No description provided for @topPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Top Nearest Pharmacy'**
  String get topPharmacy;

  /// No description provided for @topLabs.
  ///
  /// In en, this message translates to:
  /// **'Top Nearest Labs'**
  String get topLabs;

  /// No description provided for @topScans.
  ///
  /// In en, this message translates to:
  /// **'Top Nearest Radiology Centers'**
  String get topScans;

  /// No description provided for @take.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get take;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviews;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get todaySchedule;

  /// No description provided for @takenToday.
  ///
  /// In en, this message translates to:
  /// **'{taken} of {total} taken today'**
  String takenToday(Object taken, Object total);

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get newReminder;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @docicon.
  ///
  /// In en, this message translates to:
  /// **'Doctor 🩺'**
  String get docicon;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @medicine.
  ///
  /// In en, this message translates to:
  /// **'💊 Medicine'**
  String get medicine;

  /// No description provided for @nameMedi.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get nameMedi;

  /// No description provided for @form.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get form;

  /// No description provided for @dosePerIntake.
  ///
  /// In en, this message translates to:
  /// **'Dose per intake'**
  String get dosePerIntake;

  /// No description provided for @takeIt.
  ///
  /// In en, this message translates to:
  /// **'Take it'**
  String get takeIt;

  /// No description provided for @beforeMeal.
  ///
  /// In en, this message translates to:
  /// **'🍽️  Before meal'**
  String get beforeMeal;

  /// No description provided for @afterMeal.
  ///
  /// In en, this message translates to:
  /// **'🍽️  After meal'**
  String get afterMeal;

  /// No description provided for @withFood.
  ///
  /// In en, this message translates to:
  /// **'🥗  With food'**
  String get withFood;

  /// No description provided for @anytime.
  ///
  /// In en, this message translates to:
  /// **'⏱️  Anytime'**
  String get anytime;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'🔴  High'**
  String get high;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'🟡  Normal'**
  String get normal;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'🟢  Low'**
  String get low;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickAColor;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @tapToChangeColor.
  ///
  /// In en, this message translates to:
  /// **'Tap to change color'**
  String get tapToChangeColor;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @repeatOn.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get repeatOn;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @noEndDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get noEndDate;

  /// No description provided for @holdToEdit.
  ///
  /// In en, this message translates to:
  /// **'Hold to edit  •  Swipe left to delete'**
  String get holdToEdit;

  /// No description provided for @ateAlready.
  ///
  /// In en, this message translates to:
  /// **'Ate already'**
  String get ateAlready;

  /// No description provided for @noRemindersYet.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get noRemindersYet;

  /// No description provided for @tapToAddOne.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one'**
  String get tapToAddOne;

  /// No description provided for @doneTick.
  ///
  /// In en, this message translates to:
  /// **'Done ✓'**
  String get doneTick;

  /// No description provided for @medicalRecords.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get medicalRecords;

  /// No description provided for @documentsStored.
  ///
  /// In en, this message translates to:
  /// **'{count} documents stored'**
  String documentsStored(Object count);

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @nearBy.
  ///
  /// In en, this message translates to:
  /// **'Near By'**
  String get nearBy;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @aiChatBot.
  ///
  /// In en, this message translates to:
  /// **'AI Chat Bot'**
  String get aiChatBot;

  /// No description provided for @askAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your health'**
  String get askAnything;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @medibot.
  ///
  /// In en, this message translates to:
  /// **'MediBot'**
  String get medibot;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @typingHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typingHint;

  /// No description provided for @medibotGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m MediBot 👋\nHow can I help you today?'**
  String get medibotGreeting;

  /// No description provided for @medibotTyping.
  ///
  /// In en, this message translates to:
  /// **'MediBot is typing...'**
  String get medibotTyping;

  /// No description provided for @quickReply1.
  ///
  /// In en, this message translates to:
  /// **'Show my records'**
  String get quickReply1;

  /// No description provided for @quickReply2.
  ///
  /// In en, this message translates to:
  /// **'Book appointment'**
  String get quickReply2;

  /// No description provided for @quickReply3.
  ///
  /// In en, this message translates to:
  /// **'Medication schedule'**
  String get quickReply3;

  /// No description provided for @quickReply4.
  ///
  /// In en, this message translates to:
  /// **'Nearby pharmacy'**
  String get quickReply4;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @tablets.
  ///
  /// In en, this message translates to:
  /// **'Tablets'**
  String get tablets;

  /// No description provided for @capsules.
  ///
  /// In en, this message translates to:
  /// **'Capsules'**
  String get capsules;

  /// No description provided for @powders.
  ///
  /// In en, this message translates to:
  /// **'Powders'**
  String get powders;

  /// No description provided for @lozenges.
  ///
  /// In en, this message translates to:
  /// **'Lozenges'**
  String get lozenges;

  /// No description provided for @syrups.
  ///
  /// In en, this message translates to:
  /// **'Syrups'**
  String get syrups;

  /// No description provided for @dropsEye.
  ///
  /// In en, this message translates to:
  /// **'Drops Eye'**
  String get dropsEye;

  /// No description provided for @dropsEar.
  ///
  /// In en, this message translates to:
  /// **'Drops Ear'**
  String get dropsEar;

  /// No description provided for @dropsNasal.
  ///
  /// In en, this message translates to:
  /// **'Drops Nasal'**
  String get dropsNasal;

  /// No description provided for @injections.
  ///
  /// In en, this message translates to:
  /// **'Injections'**
  String get injections;

  /// No description provided for @creamsOintmentsGel.
  ///
  /// In en, this message translates to:
  /// **'Creams & Ointments & Gel'**
  String get creamsOintmentsGel;

  /// No description provided for @inhalers.
  ///
  /// In en, this message translates to:
  /// **'Inhalers'**
  String get inhalers;

  /// No description provided for @suppositories.
  ///
  /// In en, this message translates to:
  /// **'Suppositories'**
  String get suppositories;

  /// No description provided for @sublingualTablets.
  ///
  /// In en, this message translates to:
  /// **'Sublingual Tablets'**
  String get sublingualTablets;

  /// No description provided for @themes.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themes;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred appearance'**
  String get chooseTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @followsDeviceSetting.
  ///
  /// In en, this message translates to:
  /// **'Follows your device setting'**
  String get followsDeviceSetting;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseLanguage;

  /// No description provided for @labTest.
  ///
  /// In en, this message translates to:
  /// **'Lab Tests'**
  String get labTest;

  /// No description provided for @imaging.
  ///
  /// In en, this message translates to:
  /// **'Imaging'**
  String get imaging;

  /// No description provided for @prescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptions;

  /// No description provided for @diagnosisTab.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosisTab;

  /// No description provided for @allRecords.
  ///
  /// In en, this message translates to:
  /// **'All Records'**
  String get allRecords;

  /// No description provided for @stableStatus.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stableStatus;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @bloodTestResults.
  ///
  /// In en, this message translates to:
  /// **'Blood Test Results'**
  String get bloodTestResults;

  /// No description provided for @drAhmedHassanLab.
  ///
  /// In en, this message translates to:
  /// **'Dr. Ahmed Hassan — Cairo Lab'**
  String get drAhmedHassanLab;

  /// No description provided for @bloodTestDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Normal Blood Count with Slight Iron Deficiency'**
  String get bloodTestDiagnosis;

  /// No description provided for @recheckNote.
  ///
  /// In en, this message translates to:
  /// **'Recheck in 3 months. Patient responding well to diet changes.'**
  String get recheckNote;

  /// No description provided for @ironDeficiency.
  ///
  /// In en, this message translates to:
  /// **'Iron Deficiency'**
  String get ironDeficiency;

  /// No description provided for @xRayChest.
  ///
  /// In en, this message translates to:
  /// **'X-Ray Chest'**
  String get xRayChest;

  /// No description provided for @radiologyCenterMaadi.
  ///
  /// In en, this message translates to:
  /// **'Radiology Center — Maadi'**
  String get radiologyCenterMaadi;

  /// No description provided for @clearLungsNote.
  ///
  /// In en, this message translates to:
  /// **'Clear lungs, no abnormalities detected.'**
  String get clearLungsNote;

  /// No description provided for @chestClearNote.
  ///
  /// In en, this message translates to:
  /// **'Chest clear. Cough likely viral. Recommend rest and fluids.'**
  String get chestClearNote;

  /// No description provided for @viralCough.
  ///
  /// In en, this message translates to:
  /// **'Viral Cough'**
  String get viralCough;

  /// No description provided for @drSaraClinic.
  ///
  /// In en, this message translates to:
  /// **'Dr. Sara Mahmoud — Clinic'**
  String get drSaraClinic;

  /// No description provided for @viralFluNote.
  ///
  /// In en, this message translates to:
  /// **'Viral flu. Should resolve in 5-7 days with rest and fluids.'**
  String get viralFluNote;

  /// No description provided for @flu.
  ///
  /// In en, this message translates to:
  /// **'Flu'**
  String get flu;

  /// No description provided for @cardiologyReport.
  ///
  /// In en, this message translates to:
  /// **'Cardiology Report'**
  String get cardiologyReport;

  /// No description provided for @drOmarClinic.
  ///
  /// In en, this message translates to:
  /// **'Dr. Omar Khalil — Heart Clinic'**
  String get drOmarClinic;

  /// No description provided for @arrhythmiaNote.
  ///
  /// In en, this message translates to:
  /// **'Mild arrhythmia detected. Requires monitoring.'**
  String get arrhythmiaNote;

  /// No description provided for @holterNote.
  ///
  /// In en, this message translates to:
  /// **'Holter monitor for 24hrs scheduled. Avoid strenuous exercise until cleared'**
  String get holterNote;

  /// No description provided for @arrhythmia.
  ///
  /// In en, this message translates to:
  /// **'Arrhythmia'**
  String get arrhythmia;

  /// No description provided for @mRIBrainScan.
  ///
  /// In en, this message translates to:
  /// **'MRI Brain Scan'**
  String get mRIBrainScan;

  /// No description provided for @scanCenterHel.
  ///
  /// In en, this message translates to:
  /// **'Scan Center — Heliopolis'**
  String get scanCenterHel;

  /// No description provided for @migraineScanNote.
  ///
  /// In en, this message translates to:
  /// **'No structural abnormalities. Migraine-related changes noted.'**
  String get migraineScanNote;

  /// No description provided for @mriDoctorNote.
  ///
  /// In en, this message translates to:
  /// **'MRI confirms migraine pattern. No tumors or lesions. Annual scan recommended.'**
  String get mriDoctorNote;

  /// No description provided for @migraine.
  ///
  /// In en, this message translates to:
  /// **'Migraine'**
  String get migraine;

  /// No description provided for @diabetesCheckup.
  ///
  /// In en, this message translates to:
  /// **'Diabetes Checkup'**
  String get diabetesCheckup;

  /// No description provided for @drLaylaCenter.
  ///
  /// In en, this message translates to:
  /// **'Dr. Layla Nour — Diabetes Center'**
  String get drLaylaCenter;

  /// No description provided for @diabetesDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'HbA1c elevated at 8.2%. Diabetes management required.'**
  String get diabetesDiagnosis;

  /// No description provided for @diabetesDoctorNote.
  ///
  /// In en, this message translates to:
  /// **'HbA1c must drop below 7 in next 3 months. Dietitian referral given.'**
  String get diabetesDoctorNote;

  /// No description provided for @diabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get diabetes;

  /// No description provided for @fluDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Flu Diagnosis'**
  String get fluDiagnosis;

  /// No description provided for @drAhmedClinic.
  ///
  /// In en, this message translates to:
  /// **'Dr. AhmedHassan — Clinic 3'**
  String get drAhmedClinic;

  /// No description provided for @fluDiagnosisText.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Influenza Type A'**
  String get fluDiagnosisText;

  /// No description provided for @fluDoctorNote.
  ///
  /// In en, this message translates to:
  /// **'Patient advised to stay home. Flu shot recommended next season.'**
  String get fluDoctorNote;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @phoneVerification.
  ///
  /// In en, this message translates to:
  /// **'Phone Verification'**
  String get phoneVerification;

  /// No description provided for @codeSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We sent a 4-digit code to your phone number.'**
  String get codeSentMessage;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive a code? '**
  String get didntReceiveCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resend;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @titleIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleIsRequired;

  /// No description provided for @doctorFacilityIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Doctor / Facility is required'**
  String get doctorFacilityIsRequired;

  /// No description provided for @diagnosisIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis is required'**
  String get diagnosisIsRequired;

  /// No description provided for @selectAttachment.
  ///
  /// In en, this message translates to:
  /// **'Select Attachment'**
  String get selectAttachment;

  /// No description provided for @addNewRecord.
  ///
  /// In en, this message translates to:
  /// **'Add New Record'**
  String get addNewRecord;

  /// No description provided for @recordType.
  ///
  /// In en, this message translates to:
  /// **'Record Type'**
  String get recordType;

  /// No description provided for @recordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Title'**
  String get recordTitle;

  /// No description provided for @egBloodTest.
  ///
  /// In en, this message translates to:
  /// **'e.g. Blood Test Results'**
  String get egBloodTest;

  /// No description provided for @doctorFacility.
  ///
  /// In en, this message translates to:
  /// **'Doctor / Facility'**
  String get doctorFacility;

  /// No description provided for @egDoctorFacility.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dr. Ahmed Hassan — Cairo Lab'**
  String get egDoctorFacility;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @diagnosisDescription.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis / Description'**
  String get diagnosisDescription;

  /// No description provided for @diagnosisHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the diagnosis or findings…'**
  String get diagnosisHint;

  /// No description provided for @doctorNotes.
  ///
  /// In en, this message translates to:
  /// **'Doctor Notes (optional)'**
  String get doctorNotes;

  /// No description provided for @doctorNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes from the doctor…'**
  String get doctorNotesHint;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @addFile.
  ///
  /// In en, this message translates to:
  /// **'Add File'**
  String get addFile;

  /// No description provided for @noAttachmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet'**
  String get noAttachmentsYet;

  /// No description provided for @saveRecord.
  ///
  /// In en, this message translates to:
  /// **'Save Record'**
  String get saveRecord;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosis;

  /// No description provided for @drYoussef.
  ///
  /// In en, this message translates to:
  /// **'Dr. Youssef Mohammed'**
  String get drYoussef;

  /// No description provided for @gynecologist.
  ///
  /// In en, this message translates to:
  /// **'Gynecologist'**
  String get gynecologist;

  /// No description provided for @yrsExp14.
  ///
  /// In en, this message translates to:
  /// **'14 yrs exp'**
  String get yrsExp14;

  /// No description provided for @drJana.
  ///
  /// In en, this message translates to:
  /// **'Dr. Jana Wael'**
  String get drJana;

  /// No description provided for @cardiology.
  ///
  /// In en, this message translates to:
  /// **'Cardiology'**
  String get cardiology;

  /// No description provided for @yrsExp17.
  ///
  /// In en, this message translates to:
  /// **'17 yrs exp'**
  String get yrsExp17;

  /// No description provided for @drAmr.
  ///
  /// In en, this message translates to:
  /// **'Dr. Amr Adel'**
  String get drAmr;

  /// No description provided for @orthopedics.
  ///
  /// In en, this message translates to:
  /// **'Orthopedics'**
  String get orthopedics;

  /// No description provided for @yrsExp19.
  ///
  /// In en, this message translates to:
  /// **'19 yrs exp'**
  String get yrsExp19;

  /// No description provided for @drMaya.
  ///
  /// In en, this message translates to:
  /// **'Dr. Maya Tamer'**
  String get drMaya;

  /// No description provided for @pediatrics.
  ///
  /// In en, this message translates to:
  /// **'Pediatrics'**
  String get pediatrics;

  /// No description provided for @yrsExp21.
  ///
  /// In en, this message translates to:
  /// **'21 yrs exp'**
  String get yrsExp21;

  /// No description provided for @drKareem.
  ///
  /// In en, this message translates to:
  /// **'Dr. Kareem Ashour'**
  String get drKareem;

  /// No description provided for @generalPractitioner.
  ///
  /// In en, this message translates to:
  /// **'General Practitioner'**
  String get generalPractitioner;

  /// No description provided for @yrsExp15.
  ///
  /// In en, this message translates to:
  /// **'15 yrs exp'**
  String get yrsExp15;

  /// No description provided for @drAya.
  ///
  /// In en, this message translates to:
  /// **'Dr. Aya Bassem'**
  String get drAya;

  /// No description provided for @internalMedicine.
  ///
  /// In en, this message translates to:
  /// **'Internal Medicine'**
  String get internalMedicine;

  /// No description provided for @yrsExp10.
  ///
  /// In en, this message translates to:
  /// **'10 yrs exp'**
  String get yrsExp10;

  /// No description provided for @drEhab.
  ///
  /// In en, this message translates to:
  /// **'Dr. Ehab Hesham'**
  String get drEhab;

  /// No description provided for @pediatrician.
  ///
  /// In en, this message translates to:
  /// **'Pediatrician'**
  String get pediatrician;

  /// No description provided for @yrsExp12.
  ///
  /// In en, this message translates to:
  /// **'12 yrs exp'**
  String get yrsExp12;

  /// No description provided for @drMohamed.
  ///
  /// In en, this message translates to:
  /// **'Dr. Mohamed Hany'**
  String get drMohamed;

  /// No description provided for @oncologist.
  ///
  /// In en, this message translates to:
  /// **'Oncologist'**
  String get oncologist;

  /// No description provided for @yrsExp9.
  ///
  /// In en, this message translates to:
  /// **'9 yrs exp'**
  String get yrsExp9;

  /// No description provided for @drSeif.
  ///
  /// In en, this message translates to:
  /// **'Dr. Seif Mohamed'**
  String get drSeif;

  /// No description provided for @pulmonology.
  ///
  /// In en, this message translates to:
  /// **'Pulmonology'**
  String get pulmonology;

  /// No description provided for @yrsExp8.
  ///
  /// In en, this message translates to:
  /// **'8 yrs exp'**
  String get yrsExp8;

  /// No description provided for @drAhmed.
  ///
  /// In en, this message translates to:
  /// **'Dr. Ahmed Samy'**
  String get drAhmed;

  /// No description provided for @cardiologist.
  ///
  /// In en, this message translates to:
  /// **'Cardiologist'**
  String get cardiologist;

  /// No description provided for @yrsExp20.
  ///
  /// In en, this message translates to:
  /// **'20 yrs exp'**
  String get yrsExp20;

  /// No description provided for @drSara.
  ///
  /// In en, this message translates to:
  /// **'Dr. Sara Hassan'**
  String get drSara;

  /// No description provided for @dermatologist.
  ///
  /// In en, this message translates to:
  /// **'Dermatologist'**
  String get dermatologist;

  /// No description provided for @yrsExp7.
  ///
  /// In en, this message translates to:
  /// **'7 yrs exp'**
  String get yrsExp7;

  /// No description provided for @drOmar.
  ///
  /// In en, this message translates to:
  /// **'Dr. Omar Farouk'**
  String get drOmar;

  /// No description provided for @neurologist.
  ///
  /// In en, this message translates to:
  /// **'Neurologist'**
  String get neurologist;

  /// No description provided for @yrsExp18.
  ///
  /// In en, this message translates to:
  /// **'18 yrs exp'**
  String get yrsExp18;

  /// No description provided for @drMona.
  ///
  /// In en, this message translates to:
  /// **'Dr. Mona Ali'**
  String get drMona;

  /// No description provided for @neurosurgery.
  ///
  /// In en, this message translates to:
  /// **'Neurosurgery'**
  String get neurosurgery;

  /// No description provided for @yrsExp22.
  ///
  /// In en, this message translates to:
  /// **'22 yrs exp'**
  String get yrsExp22;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'view details'**
  String get book;

  /// No description provided for @alNahda.
  ///
  /// In en, this message translates to:
  /// **'Al Nahdi Pharmacy'**
  String get alNahda;

  /// No description provided for @kmAwayZeroThree.
  ///
  /// In en, this message translates to:
  /// **'0.3 km away'**
  String get kmAwayZeroThree;

  /// No description provided for @time1.
  ///
  /// In en, this message translates to:
  /// **'8AM - 12AM'**
  String get time1;

  /// No description provided for @dawaa.
  ///
  /// In en, this message translates to:
  /// **'Dawaa Pharmacy'**
  String get dawaa;

  /// No description provided for @kmAwayZeroSeven.
  ///
  /// In en, this message translates to:
  /// **'0.7 km away'**
  String get kmAwayZeroSeven;

  /// No description provided for @time2.
  ///
  /// In en, this message translates to:
  /// **'24 Hours'**
  String get time2;

  /// No description provided for @seif.
  ///
  /// In en, this message translates to:
  /// **'Seif Pharmacy'**
  String get seif;

  /// No description provided for @kmAwayOneOne.
  ///
  /// In en, this message translates to:
  /// **'1.1 km away'**
  String get kmAwayOneOne;

  /// No description provided for @time3.
  ///
  /// In en, this message translates to:
  /// **'9AM - 11PM'**
  String get time3;

  /// No description provided for @cairo.
  ///
  /// In en, this message translates to:
  /// **'Cairo Pharmacy'**
  String get cairo;

  /// No description provided for @kmAwayOneEight.
  ///
  /// In en, this message translates to:
  /// **'1.8 km away'**
  String get kmAwayOneEight;

  /// No description provided for @time4.
  ///
  /// In en, this message translates to:
  /// **'8AM - 10PM'**
  String get time4;

  /// No description provided for @elEzaby.
  ///
  /// In en, this message translates to:
  /// **'El Ezaby Pharmacy'**
  String get elEzaby;

  /// No description provided for @kmAwayTwoTwo.
  ///
  /// In en, this message translates to:
  /// **'2.2 km away'**
  String get kmAwayTwoTwo;

  /// No description provided for @time5.
  ///
  /// In en, this message translates to:
  /// **'24 Hours'**
  String get time5;

  /// No description provided for @alphaMedical.
  ///
  /// In en, this message translates to:
  /// **'Alpha Medical Lab'**
  String get alphaMedical;

  /// No description provided for @kmAwayZeroFive.
  ///
  /// In en, this message translates to:
  /// **'0.5 km away'**
  String get kmAwayZeroFive;

  /// No description provided for @time6.
  ///
  /// In en, this message translates to:
  /// **'7AM - 9PM'**
  String get time6;

  /// No description provided for @nileDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Nile Diagnostics'**
  String get nileDiagnostics;

  /// No description provided for @kmAwayOneZero.
  ///
  /// In en, this message translates to:
  /// **'1.0 km away'**
  String get kmAwayOneZero;

  /// No description provided for @time7.
  ///
  /// In en, this message translates to:
  /// **'8AM - 8PM'**
  String get time7;

  /// No description provided for @cairoCenter.
  ///
  /// In en, this message translates to:
  /// **'Cairo Lab Center'**
  String get cairoCenter;

  /// No description provided for @kmAwayOneFour.
  ///
  /// In en, this message translates to:
  /// **'1.4 km away'**
  String get kmAwayOneFour;

  /// No description provided for @time8.
  ///
  /// In en, this message translates to:
  /// **'7AM - 10PM'**
  String get time8;

  /// No description provided for @elite.
  ///
  /// In en, this message translates to:
  /// **'Elite Lab'**
  String get elite;

  /// No description provided for @kmAwayTwoZero.
  ///
  /// In en, this message translates to:
  /// **'2.0 km away'**
  String get kmAwayTwoZero;

  /// No description provided for @time9.
  ///
  /// In en, this message translates to:
  /// **'8AM - 6PM'**
  String get time9;

  /// No description provided for @radiologyPlus.
  ///
  /// In en, this message translates to:
  /// **'Radiology Plus'**
  String get radiologyPlus;

  /// No description provided for @kmAwayZeroSix.
  ///
  /// In en, this message translates to:
  /// **'0.6 km away'**
  String get kmAwayZeroSix;

  /// No description provided for @time10.
  ///
  /// In en, this message translates to:
  /// **'8AM - 10PM'**
  String get time10;

  /// No description provided for @mriScanCenter.
  ///
  /// In en, this message translates to:
  /// **'MRI & Scan Center'**
  String get mriScanCenter;

  /// No description provided for @kmAwayOneTwoo.
  ///
  /// In en, this message translates to:
  /// **'1.2 km away'**
  String get kmAwayOneTwoo;

  /// No description provided for @time11.
  ///
  /// In en, this message translates to:
  /// **'9AM - 9PM'**
  String get time11;

  /// No description provided for @cairoRadiology.
  ///
  /// In en, this message translates to:
  /// **'Cairo Radiology'**
  String get cairoRadiology;

  /// No description provided for @kmAwayOneSix.
  ///
  /// In en, this message translates to:
  /// **'1.6 km away'**
  String get kmAwayOneSix;

  /// No description provided for @time12.
  ///
  /// In en, this message translates to:
  /// **'8AM - 8PM'**
  String get time12;

  /// No description provided for @advancedImaging.
  ///
  /// In en, this message translates to:
  /// **'Advanced Imaging'**
  String get advancedImaging;

  /// No description provided for @kmAwayTwoFive.
  ///
  /// In en, this message translates to:
  /// **'2.5 km away'**
  String get kmAwayTwoFive;

  /// No description provided for @time13.
  ///
  /// In en, this message translates to:
  /// **'7AM - 7PM'**
  String get time13;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start: {date}'**
  String start(Object date);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'es', 'fr', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'ru': return AppLocalizationsRu();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
