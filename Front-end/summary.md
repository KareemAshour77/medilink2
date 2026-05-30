MediLink — Flutter Mobile Application: Project Summary

1. Project Overview
   Project Title: MediLink — Your Link to Doctors
   Platform: Cross-platform mobile application built with Flutter, targeting Android (primary development device: Huawei MHA-L29) and iOS.
   Description: MediLink is a healthcare companion mobile application that connects patients with doctors, manages medical reminders, stores medical records, and provides an AI-powered health chatbot. The app features full Arabic/English localization and light/dark theme support.

2. Objectives

Build a complete, production-ready Flutter healthcare app from a PDF design specification
Implement full onboarding, authentication, and home dashboard flows
Provide medicine and appointment reminder scheduling with local push notifications
Support bilingual UI (Arabic and English) with RTL layout switching
Implement persistent dark/light theme toggling across all screens
Allow users to manage their profile with photo upload and editable fields

3. Features and Functionality
   Authentication

Splash screen and 4-slide onboarding tour
Sign Up (2-step: profile details → phone verification)
Login, Forgot Password (3-step: email → OTP → new password)
Form validation: email format, password rules (uppercase first character, number, symbol), National ID exactly 14 digits (numeric only)

Home App (4 tabs via bottom navigation)

Home Tab: Doctor listings, category filters, schedule cards, AI chatbot shortcut banner
Reminder Tab: Medicine and appointment reminders with local scheduled notifications
Records Tab: Medical records storage
Menu Tab: Profile card, AI chatbot access, settings items, logout

Notifications

Scheduled local notifications using flutter_local_notifications
Exact alarm scheduling with timezone-aware timing
Notifications persist across device reboots via boot receiver

AI Chatbot

Floating Action Button (FAB) centered in bottom navigation bar
Full chat UI with greeting, quick reply chips, keyword-based auto-replies
Accessible from home banner, menu tab, and FAB

Profile Edit Screen

Upload profile photo (camera or gallery via image_picker)
Edit full name, email, National ID, gender
Optional password change with validation
Data persisted locally using shared_preferences

Theming and Localization

Global ValueNotifier<ThemeMode> for instant theme switching without prop drilling
ThemeX extension on BuildContext for isDark, bg, card, text, divider
langNotifier for Arabic/English toggling with RTL support
ARB-based localization via flutter_gen

4. Technologies and Tools
   CategoryTechnologyFrameworkFlutter (Dart)IDEVisual Studio CodeTarget DeviceAndroid (Huawei MHA-L29), iPhone 14 Pro (simulator)FontsGoogle Fonts (Poppins)Localizationflutter_localizations, flutter_gen, ARB filesNotificationsflutter_local_notificationsStorageshared_preferencesImage Pickerimage_pickerUI Extrassmooth_page_indicator, pin_code_fields, font_awesome_flutter, flutter_colorpickerBuild ToolsGradle (Kotlin DSL), Android SDK, Java 17

5. System Architecture
   lib/
   ├── main.dart # App entry, theme/lang listeners, MaterialApp
   ├── theme/
   │ └── app_theme.dart # Global notifiers, color palette, ThemeX extension
   ├── l10n/
   │ ├── app_en.arb # English strings
   │ └── app_ar.arb # Arabic strings
   ├── screens/
   │ ├── auth/ # Splash, Onboarding, Welcome, Login, Signup,
   │ │ # PhoneVerification, ForgotPassword
   │ └── home/ # HomeScreen, HomeTab, ReminderTab, RecordsTab,
   │ # MenuTab, ChatbotScreen, ProfileEditScreen
   ├── models/
   │ └── reminder_model.dart # ReminderModel, ReminderType, MealRelation
   ├── services/
   │ └── notification_service.dart # Local notification scheduling and cancellation
   └── widgets/
   ├── theme_toggle_button.dart
   └── lang_toggle_button.dart
   Theme System: A single global ValueNotifier<ThemeMode> wraps the entire MaterialApp. Every widget reads theme via context.isDark — no props passed between widgets, eliminating dark mode bugs caused by manual prop drilling.

6. Implementation Challenges and Solutions
   ChallengeSolutionflutter_timezone Kotlin Registrar build error on all versionsRemoved the package entirely; replaced with manual UTC offset matching against the built-in timezone package databaseflutter_native_timezone missing Android namespace (AGP error)Abandoned both timezone packages; used Dart's DateTime.now().timeZoneOffset with the built-in tz databaseNotifications not firing on AndroidAdded missing ScheduledNotificationReceiver and ScheduledNotificationBootReceiver receivers to AndroidManifest.xml, plus SCHEDULE_EXACT_ALARM permissionDark mode not applying on some tabsReplaced manual themeMode prop drilling with global ValueNotifier — all widgets now rebuild automatically on togglestatic const map using localization stringsMoved \_mealLabels map from static const field into build() method where BuildContext is availableerrorText not accepted on TextFieldRemoved const keyword from affected TextField and InputDecoration widgetsLocalization import error (AppLocalizations undefined)Ran flutter gen-l10n to generate the file; corrected import path to match actual output directoryCorrupted Kotlin incremental build cacheRan flutter clean followed by flutter pub get — build succeeded despite cache warning messages

7. Android Configuration
   AndroidManifest.xml required entries:
   xml<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
   <uses-permission android:name="android.permission.VIBRATE"/>
   <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <!-- BOOT_COMPLETED, MY_PACKAGE_REPLACED, QUICKBOOT_POWERON -->
</receiver>
build.gradle.kts:

Java 17 source and target compatibility
Core library desugaring enabled (desugar_jdk_libs:2.0.4)
minSdk = 21

8. Current Status

Full app structure implemented across 13+ screens
Authentication flow complete with validation
Dark/light theme and Arabic/English localization fully working
Notification scheduling implemented with correct Android manifest configuration
Profile edit screen complete with photo upload and persistent storage
AI chatbot screen accessible from three entry points

9. Future Improvements

Connect authentication to a real backend (API integration)
Replace shared_preferences profile storage with a proper user database
Add real doctor search and appointment booking functionality
Implement actual AI/NLP model for the chatbot instead of keyword matching
Add biometric login (fingerprint/Face ID)
Publish to Google Play Store and Apple App Store

You worked on improving a Flutter-based medical app that includes an AI chat assistant, reminders, notifications, and modern UI/UX enhancements.
Main Work Completed

1. Attachment Section Improvements
   Enhanced the chat attachment system with ideas such as:

Merging repetitive attachment types

Multi-upload support

File preview before sending

Upload progress & feedback states

2. Flutter UI Architecture Improvements
   Focused on:

Creating reusable widgets instead of editing screens directly

Separating UI components into independent files

Improving maintainability and scalability

Using iterative refinement for cleaner UI development

3. Notification System UI
   Designed and improved:

Notification bell button replacing the theme toggle

Unread notification badge

Animated bottom sheet for notifications

Notification cards

Empty notification states

4. Actionable Notifications
   Implemented the concept of interactive notifications instead of static alerts.
   Examples:

“Time to take your medication”

✅ Taken

⏰ Snooze

5. NotificationBellButton Widget
   Built a reusable notification widget containing:

Bell animation

Badge counter

Animated notification sheet

Notification list items

Action buttons

“Clear all” functionality

Empty state UI

6. Notification Service
   Created a complete:
   notification_service.dart
   Including:

init()

showNow()

schedule()

cancel()

Using:

flutter_local_notifications

timezone

7. Reminder Integration
   Integrated reminders with notifications by updating:
   reminder_tab.dart
   Supporting:

Scheduling notifications

Cancelling notifications

Also fixed issues related to:

String → int conversion

TimeOfDay → DateTime conversion

ReminderModel integration

8. Notification Actions Refactor
   Solved issues related to:

Undefined NotificationActions

Missing handleNotificationAction

Incorrect NotificationResponse implementation

Refactored the architecture so:

UI sends actionId

NotificationService handles the business logic

9. UI/UX Enhancements
   Improved:

Bell shake animations

Animated badges

Smooth bottom-sheet transitions

Medical-themed color system

Reusable action buttons

Better empty states

10. Clean Architecture & Scalability
    Focused on:

Separation of concerns

Reusable widget architecture

Decoupled UI & business logic

Scalable notification handling

Cleaner Flutter project structure

You built and debugged a NestJS authentication and email verification system using PostgreSQL, Sequelize, and Gmail SMTP.

Key tasks completed:

Created two auth endpoints:
POST /auth/send-verification
POST /auth/verify-code
Configured email sending with Gmail SMTP using Nodemailer and NestJS MailerModule.
Fixed ECONNREFUSED 127.0.0.1:587 by replacing localhost SMTP with Gmail SMTP.
Added .env configuration for:
MAIL_HOST
MAIL_PORT
MAIL_USER
MAIL_PASS
Integrated @nestjs/config properly with:
ConfigModule.forRoot({ isGlobal: true })
Fixed incorrect placement of ConfigModule and MailModule inside SequelizeModule.forRoot.
Built a complete MailModule using MailerModule.forRootAsync.
Implemented:
verification code generation
10-minute expiration logic
email delivery
code verification
Resolved a circular dependency issue caused by:
export { MailService }
Corrected UUID-based delete handling:
removed Number(id) usage
used string UUIDs instead
Added user deletion support through:
NestJS DELETE endpoint
direct PostgreSQL query in pgAdmin

Technologies involved:

NestJS
Sequelize
PostgreSQL
Nodemailer
Gmail SMTP
Thunder Client
pgAdmin 4

Built and debugged a complete NestJS authentication and email verification system using PostgreSQL, Sequelize, and Gmail SMTP.
Implemented two authentication endpoints:

POST /auth/send-verification

POST /auth/verify-code

Configured email delivery using Nodemailer with NestJS MailerModule and Gmail SMTP.
Resolved SMTP connection issues:

Fixed ECONNREFUSED 127.0.0.1:587

Replaced localhost SMTP configuration with Gmail SMTP credentials

Configured environment variables with .env:

MAIL_HOST

MAIL_PORT

MAIL_USER

MAIL_PASS

Integrated NestJS ConfigModule correctly using:
ConfigModule.forRoot({ isGlobal: true })
Fixed incorrect module architecture:

Removed improper placement of ConfigModule and MailModule inside SequelizeModule.forRoot

Built a proper MailModule using MailerModule.forRootAsync

Implemented full email verification workflow:

verification code generation

email delivery

10-minute expiration logic

code validation and verification

Improved authentication security:

added OTP expiration handling

added invalid code validation

prepared structure for rate limiting and secure verification flow

Resolved a circular dependency issue caused by:
export { MailService }
Corrected UUID deletion handling:

removed incorrect Number(id) conversion

used UUID strings directly

Added user deletion support through:

NestJS DELETE endpoint

direct PostgreSQL deletion via pgAdmin 4

Technologies used:

NestJS

Sequelize

PostgreSQL

Nodemailer

Gmail SMTP

Thunder Client

pgAdmin 4

The current MediBot message UI contains too much information in one block, making it harder to scan quickly. Suggested improvements focus on better UX and readability for medical chatbot results.
Key recommendations:

Add a quick summary section at the top showing counts of normal, high, and low results.

Split results into separate cards instead of one long message.

Use consistent language formatting (Arabic with English medical terms only when needed).

Highlight important values visually using icons, colors, and larger typography.

Add short, simple explanations for abnormal results.

Include clear actions at the bottom such as consulting a doctor or asking for more details.

Reduce clutter by shortening text and simplifying ranges.

Optionally add visual indicators like progress bars or health ranges.

Several UI directions were explored:

Minimal clean design

Card-based medical layout

Visualization-focused dashboard

Chat-style medical response

Analytics/dashboard style

Friendly accessible UI

Dark mode futuristic style

Design style references:

Apple Health

Modern fintech UI

WhatsApp-style chat layout

Dribbble-quality mobile UI concepts

Main visual patterns:

Green for normal

Red for high

Blue for low

Rounded cards

Soft shadows

Clean spacing

Modern mobile healthcare aesthetics

You are building a Flutter app connected to a NestJS backend.
Current status:

The mobile app successfully connects to the backend server.

The issue was an Internal Server Error (500) during user registration.

The backend is running correctly on a real Android device using a local IP (http://<local-ip>:5000).

Flutter sends a POST request to /users with:

name

email

password

role

The backend expected an additional field: nationalId.

Backend stack:

NestJS

DTO validation using class-validator

Relevant backend files:

users/dto/create-user.dto.ts

users.service.ts

users.controller.ts

user.model.ts

Fix applied:

Added nationalId to CreateUserDto.

Example:
@IsString()@Length(14, 14)nationalId!: string;
Flutter request should include:
'nationalId': nationalId,
Additional notes:

Ensure user.model.ts also contains nationalId.

Restart the NestJS server after DTO changes:

npm run start:dev
VS Code tooling:

Discussed using the “Markdown Tree” extension to generate project file trees.

Alternative terminal command:

npx tree-cli -L 3

The Flutter Android app cannot connect to the FastAPI backend running on Windows.
The original error was:

ClientException with SocketException:
No route to host (OS Error: No route to host, errno = 113)

Backend URL being used:

http://192.168.1.20:8000/analyze?threshold=0.5

Environment:

Flutter app
Real Android device
FastAPI backend
Windows PC
Mobile connected via Wi-Fi
Backend IP identified as 192.168.1.20

Main findings:

The issue is network/backend connectivity, not Flutter UI.

Opening:

http://192.168.1.20:8000/docs

from the phone browser failed.

That confirms the phone cannot reach the FastAPI server.

Recommended fixes:

Run FastAPI with external binding:

uvicorn main:app --host 0.0.0.0 --port 8000

Verify current Windows IP using:

ipconfig

Open port 8000 in Windows Firewall:

netsh advfirewall firewall add rule name="FastAPI 8000" dir=in action=allow protocol=TCP localport=8000

Ensure Flutter uses:

http://192.168.1.20:8000

and not localhost/127.0.0.1.

Enable cleartext HTTP in AndroidManifest.xml:

android:usesCleartextTraffic="true"

Test locally on Windows:

http://127.0.0.1:8000/docs

Diagnosis conclusion:

Most likely causes are:
FastAPI not bound to 0.0.0.0
Windows Firewall blocking port 8000
Incorrect IP address
Devices not truly reachable on the same LAN/network configuration.

The project is a backend API built with NestJS using TypeScript, Sequelize, and PostgreSQL.
Initially, there was a TypeScript error:
TS5103: Invalid value for '--ignoreDeprecations'
The issue was resolved by updating the Nest CLI and TypeScript versions and removing unsupported compiler options.
After that, the server started successfully:

Backend connected correctly to PostgreSQL through Sequelize

Modules loaded successfully:

UsersModule

AuthModule

MedicalRecordsModule

API routes were mapped correctly

The server port was changed from 3000 to 8000 by updating main.ts or using an environment variable.
For hot reload:

npm run start:dev automatically reloads the app on code changes

Manual restart is only needed if watch mode fails

A mobile testing issue (cannot connect to server) was fixed by:

Running the server with:

await app.listen(8000, '0.0.0.0');

Using the local Wi-Fi IP:

172.20.10.5:8000
instead of localhost
Ngrok failed because the account was not verified and no auth token was configured.
Later, the mobile app successfully connected to the backend, but a 400 Bad Request appeared during signup. The likely causes were:

Weak password (D!1)

Invalid national ID length

Validation errors inside DTOs

Suggested valid test data:
Email: doctor22@test.comPassword: Doctor@123Role: doctorNational ID: 3080405010607
The login endpoint issue was then diagnosed:

/auth/login returned:

{ "message": "Cannot POST /auth/login", "statusCode": 404}
The server logs showed the actual mapped route:
POST /auth/signin
So the correct authentication endpoint became:
/auth/signin
The backend routes discovered from NestJS logs were:

POST /users

GET /users

GET /users/nearby

DELETE /users/:id

POST /medical-records

GET /medical-records

POST /auth/signin

This means registration is currently handled through:
/users
while login is:
/auth/signin
The project structure was explained:

main.ts → application bootstrap and server configuration

app.module.ts → root module importing all feature modules

auth.controller.ts → authentication routes

auth.service.ts → login/register logic and JWT handling

users.service.ts → database operations for users

user.model.ts → Sequelize model for the users table

DTO files → request validation

medical_records module → medical records APIs and models

Recommended development tools:

Visual Studio Code

Thunder Client

ESLint

Prettier

PostgreSQL

Thunder Client was used to test APIs directly from VS Code:

Sending POST requests

Testing login/register

Viewing validation errors

Testing JWT authorization headers

The project also needs role-based navigation in the Flutter frontend:

If role = doctor → open Doctor UI

If role = patient → open Patient UI

The backend should return the role in authentication responses so the frontend can redirect accordingly.
Finally, database inspection methods were explained:

Using DBeaver or pgAdmin

Viewing tables like:

users

medical_records

Running queries such as:

SELECT _ FROM users;
and:
SELECT _ FROM medical_records;

MediLink — Project Summary Report

1. Project Overview
   Project Title: MediLink — Your Link to Doctors
   Project Type: Cross-platform mobile application (Android & iOS)
   Development Framework: Flutter (Dart)
   Project Stage: Active development — core patient features complete, multi-role expansion in progress

2. Problem Statement
   Healthcare services are fragmented across multiple platforms and physical locations. Patients struggle to manage medical records, book appointments, track medications, and communicate with doctors in one place. Healthcare providers (doctors, pharmacies, labs) lack unified digital tools for managing their workflows. MediLink addresses this by providing a single ecosystem where all healthcare stakeholders interact through role-appropriate interfaces.

3. Objectives

Build a production-ready cross-platform healthcare mobile application
Support four distinct user roles: Patient, Doctor, Pharmacy, and Labs/Scan Centers
Dynamically render UI, navigation, and permissions based on the authenticated user's role
Provide patients with medication reminders, medical record storage, and AI health assistance
Provide doctors with patient management, appointment scheduling, and diagnosis tools
Provide pharmacies with order management, inventory control, and delivery tracking
Provide labs with booking management, test tracking, and result uploading
Support multiple languages (Arabic, English, German, French, Spanish, Russian, Turkish)
Support full dark/light mode theming

4. Features and Functionality
   4.1 Patient Features (Completed)

Onboarding flow (4-slide feature tour)
Authentication: Sign up (2-step), Login, Phone OTP verification, Forgot password
Home tab with category browsing (Doctors, Pharmacy, Labs, Scans)
Upcoming schedule section linked to real saved reminders
Top Doctors section with See All screen
Category screens for Pharmacy, Labs, and Scan Centers
AI ChatBot (MediBot) — text and image input, medical keyword responses
Medical Records tab — store lab tests, imaging, prescriptions, diagnoses
Reminder system — full CRUD with notifications, color picker, priority, medicine form, meal relation, dose, weekly repeat schedule
Menu tab with profile card, language toggle, dark mode toggle, logout

4.2 Reminder System (Detailed)

Add, edit, delete reminders with swipe-to-delete and long-press-to-edit
Medicine types: Tablet, Capsule, Liquid/Syrup, Eye/Ear/Nasal Drops, Injection, Inhaler, Patch/Cream, Powder, Suppository, Lozenge, Sublingual Tablet
Priority levels: High, Normal, Low (with color-coded dots)
Meal relation: Before meal, After meal, With food, Anytime
Dose selection: ½, 1, 1½, 2, 3
Time picker, start/end date picker, day-of-week repeat selector
Color picker per reminder
"Ate already" eaten checkbox on reminder cards
Reminder type: Medicine or Doctor appointment
Push notifications via flutter_local_notifications with exact alarm scheduling
Persistence via SharedPreferences
Upcoming Schedule on Home tab sorted by time, pending-only, with Take button that removes the card

4.3 Doctor Features (In Progress)

Dashboard: today's patients count, pending/urgent case stats, upcoming appointments list, urgent cases panel
Patients list with search
Appointments screen with Accept/Reject actions
Chat screen with patient message list and unread badge
Profile screen with logout

4.4 Pharmacy Features (In Progress)

Dashboard: order count, pending count, revenue stats, recent orders list
Orders screen with status filter tabs (All, Pending, Delivered, Cancelled)
Inventory management screen (stub)
Delivery tracking screen (stub)
Profile screen with logout

4.5 Labs Features (In Progress)

Dashboard: today's bookings, pending results, completed count, pending results list with Upload button
Bookings management screen (stub)
Tests management screen (stub)
Result upload screen (stub)
Profile screen with logout

4.6 AI ChatBot (MediBot)

Integrated with a real backend API via ChatService
Supports text and image/file input (camera and gallery)
Session-based conversation management
Themed UI with bubble chat design, fade-transition typing indicator, styled input bar
Arabic and English keyword response detection

4.7 Localization

7 languages supported: Arabic (ar), English (en), German (de), French (fr), Spanish (es), Russian (ru), Turkish (tr)
ARB-based Flutter localization with flutter gen-l10n
Language toggle button available on any screen via reusable LangToggleButton widget
RTL layout automatic for Arabic
Language cycles through all 7 options via toggleLang()
context.l extension for zero-boilerplate translation access

5. Technologies, Frameworks, and Tools
   CategoryTechnologyFrameworkFlutter (Dart), targeting Android and iOSLanguageDart 3.xState ManagementValueNotifier with ValueListenableBuilder (global theme + language)Local StorageSharedPreferencesPush Notificationsflutter_local_notifications + flutter_native_timezoneHTTP Clienthttp packageLocalizationFlutter ARB + flutter_localizations + flutter_genImage Handlingimage_pickerFontsgoogle_fonts (Poppins)UI Extrassmooth_page_indicator, pin_code_fields, flutter_colorpicker, font_awesome_flutterSplash Screenflutter_native_splashIDEVS CodeTarget DeviceAndroid (tested on MHA L29), Windows development machineBackendNestJS REST API (external, connected via ApiService)AI BackendCustom API endpoint via ChatService (ngrok-tunneled during development)

6. System Architecture
   6.1 Folder Structure
   lib/
   ├── core/
   │ ├── constants/
   │ ├── theme/ (app_theme.dart)
   │ ├── widgets/ (ThemeToggleButton, LangToggleButton)
   │ └── services/ (ApiService, NotificationService,
   │ SessionService, ChatService)
   ├── features/
   │ ├── auth/
   │ │ ├── models/ (UserModel)
   │ │ └── screens/ (Login, Signup, Welcome, Onboarding,
   │ PhoneVerification, ForgotPassword)
   │ ├── patient/
   │ │ ├── screens/ (HomeScreen, HomeTab, ReminderTab,
   │ │ │ RecordsTab, MenuTab, ChatbotScreen,
   │ │ │ AllDoctorsScreen, AllRemindersScreen,
   │ │ │ CategoryScreen, AddReminderSheet)
   │ │ └── models/ (ReminderModel)
   │ ├── doctor/
   │ │ └── screens/ (DoctorHome, Dashboard, Patients,
   │ │ Appointments, Chat, Profile)
   │ ├── pharmacy/
   │ │ └── screens/ (PharmacyHome, Dashboard, Orders,
   │ │ Inventory, Delivery, Profile)
   │ └── labs/
   │ └── screens/ (LabsHome, Dashboard, Bookings,
   │ Tests, Upload, Profile)
   ├── l10n/ (7 ARB files)
   └── main.dart
   6.2 Theme System

Global ValueNotifier<ThemeMode> themeNotifier — toggles light/dark app-wide
Global ValueNotifier<Locale> langNotifier — switches language app-wide
ThemeX extension on BuildContext provides isDark, bg, card, text, divider
L10nX extension provides context.l for translation access
RoleTheme class provides per-role accent colors: Doctor (Green), Pharmacy (Purple), Labs (Orange), Patient (Blue)

6.3 Authentication and Role Routing Flow
App Start
↓
SessionService.load() (restore saved user from SharedPreferences)
↓
SplashScreen → OnboardingScreen → WelcomeScreen
↓
LoginScreen → API returns { id, name, role, access_token }
↓
UserModel.fromJson() → SessionService.save()
↓
RoleRouter
├── role = patient → HomeScreen (existing patient UI)
├── role = doctor → DoctorHome (green nav, 5 tabs)
├── role = pharmacy → PharmacyHome (purple nav, 5 tabs)
└── role = labs → LabsHome (orange nav, 5 tabs)
6.4 Data Flow — Reminders
AddReminderSheet (user fills form)
↓
ReminderModel.toJson() → SharedPreferences.setStringList()
↓
NotificationService.schedule(reminder) → flutter_local_notifications
↓
ReminderTab loads from SharedPreferences → sorted by priority
HomeTab loads from SharedPreferences → sorted by time, pending only
AllRemindersScreen loads full list

7. Data Models
   UserModel
   id, name, email, role (enum: patient/doctor/pharmacy/labs), token
   ReminderModel
   id, name, type (medicine/doctor), form (9 medicine types),
   mealRelation (before/after/withFood/anytime), priority (high/normal/low),
   dose (0.5–3.0), color, time (TimeOfDay), startDate, endDate,
   weekDays (List<bool> × 7), eaten (bool), taken (bool)

8. API Integration

Base service: ApiService handles login (POST /auth/login) and signup (POST /auth/register)
Token storage: saved via SharedPreferences, restored on app start via SessionService
AI Chat service: ChatService sends multipart requests (text + optional file) to a medical AI backend, returns structured response with .response field
Signup roles sent to backend: patient, doctor, pharmacy, scans

9. Challenges and Solutions
   ChallengeSolutionflutter_timezone v1.0.8 incompatible with Kotlin versionReplaced with flutter_native_timezoneCore library desugaring error on AndroidAdded isCoreLibraryDesugaringEnabled = true and desugar_jdk_libs to build.gradle.ktscontext.l unavailable outside build()Added L10nX extension on BuildContext; moved all translated lists inside build()Dropdown crash on language switch (String values)Replaced String dropdown values with Int index — index never changes regardless of languageARB key names invalid (non-camelCase, starting with uppercase)Renamed all invalid keys to valid camelCase equivalents across all 7 ARB filesStatic list of menu items couldn't hold translated textConverted MenuTab from StatelessWidget to StatefulWidget, built items list inside build()Reminder form — multiple medicine forms sharing same enum caused wrong highlightAdded \_formIndex int for index-based selection alongside enum valueNotifications not firingFixed by: setting real device timezone, scheduling next-day if time already passed, adding Android 13+ runtime permission requestsRole-based UI routingRoleRouter widget reads SessionService.currentUser.role and returns correct home screen

10. Localization Coverage
    All 7 language files cover the following screen groups:

Onboarding and splash
Authentication (login, signup, phone verification, forgot password)
Home tab (search, categories, schedule, doctors)
Reminder system (all form labels, medicine types, meal relations, priorities)
Medical records (record types, statuses, form fields)
Menu tab (profile, settings, logout, AI chat)
ChatBot (greeting, typing indicator, quick replies)
Doctor/Pharmacy/Labs listings (names, specialties, distances, hours)
Months, days of the week

11. Future Improvements

Complete Doctor screens: full diagnosis writer, prescription generator, test request system
Complete Pharmacy screens: live inventory management, prescription scanning, delivery map
Complete Labs screens: result PDF/image upload, analytics dashboard
Real-time chat using WebSockets (Socket.IO) for Doctor–Patient messaging
Role switching — allow one account to hold multiple roles
Medicine alternative suggestion engine
Patient data permission system (patient controls which doctor sees which records)
Backend integration for reminders (sync across devices)
Google/Apple social login completion
Map integration for Near By feature (doctors, pharmacies, labs on map)
Appointment booking flow end-to-end
Payment integration for pharmacy orders
Biometric login (fingerprint/Face ID)

# Project Summary Report

## Chest X-Ray Disease Detection System with Mobile API Integration

---

## 1. Project Overview

**Project Title:** Chest X-Ray Multi-Label Disease Detection System

**Application Name (Mobile Client):** MediLink — _Your Link to Doctors_

This project involves the design and implementation of an end-to-end AI-powered medical imaging system capable of detecting multiple chest diseases from frontal X-ray images. The system consists of two tightly coupled components: a deep learning inference backend exposed as a RESTful API, and a Flutter-based mobile client application (MediLink) that consumes the API. The backend was originally implemented in Python using FastAPI and subsequently ported to Dart using the Shelf framework to align with the mobile development ecosystem.

---

## 2. Problem Statement

Chest X-ray interpretation requires significant clinical expertise and is time-consuming, particularly in resource-limited healthcare settings. Delayed or missed diagnoses of conditions such as pneumothorax, pleural effusion, or cardiomegaly can have severe consequences. There is a clear need for automated, reliable, and accessible tools that can assist clinicians and frontline healthcare workers in triaging and interpreting chest radiographs. This project addresses that need by deploying a trained deep learning model as a lightweight, mobile-accessible API service.

---

## 3. Objectives

- Train a high-performance multi-label classification model on a large-scale chest X-ray dataset.
- Expose the trained model as a secure, authenticated REST API suitable for mobile consumption.
- Implement the API backend in both Python (FastAPI) and Dart (Shelf) to support cross-platform deployment.
- Develop a Flutter mobile application (MediLink) that submits X-ray images to the API and displays diagnostic results to the user.
- Ensure production-readiness through API key authentication, CORS handling, input validation, and robust error management.

---

## 4. Dataset

| Attribute             | Details                                   |
| --------------------- | ----------------------------------------- |
| **Name**              | NIH Chest X-ray Dataset                   |
| **Source**            | National Institutes of Health (NIH), USA  |
| **Modality**          | Frontal-view chest radiographs            |
| **Task Type**         | Multi-label image classification          |
| **Number of Classes** | 11 pathological conditions + "No Finding" |

**Disease Labels (11 classes):**

- Atelectasis
- Cardiomegaly
- Consolidation
- Effusion
- Emphysema
- Infiltration
- Mass
- No Finding
- Nodule
- Pleural Thickening
- Pneumothorax

---

## 5. AI / ML Model

### 5.1 Architecture

| Attribute               | Details                                        |
| ----------------------- | ---------------------------------------------- |
| **Base Model**          | EfficientNet-B4                                |
| **Pre-trained Weights** | ImageNet (transfer learning)                   |
| **Classifier Head**     | `Dropout(p=0.4)` → `Linear(1792, 11)`          |
| **Output Activation**   | Sigmoid (per-label, independent probabilities) |
| **Task**                | Multi-label binary classification              |
| **Input Resolution**    | 380 × 380 pixels                               |
| **Framework**           | PyTorch (`torchvision.models`)                 |

### 5.2 Training Configuration

- The model was trained with a **balanced** training strategy, as indicated by the checkpoint filename (`best_bal_efficientnet_b4_model.pth`), addressing the class imbalance inherent in the NIH dataset.
- Model checkpoints store `epoch`, `model_state_dict`, and `val_auc` (validation AUC-ROC), indicating AUC-ROC was used as the primary evaluation metric.
- The best checkpoint is selected based on highest validation AUC.

### 5.3 Inference Pipeline

1. Raw image bytes are decoded and converted to RGB.
2. Image is resized to **380 × 380** pixels.
3. Pixel values are normalised using ImageNet statistics:
   - Mean: `[0.485, 0.456, 0.406]`
   - Std: `[0.229, 0.224, 0.225]`
4. Tensor is shaped to `[1, 3, 380, 380]` (NCHW format).
5. Model performs a forward pass; logits are passed through `sigmoid()`.
6. Probabilities are thresholded (default: **0.5**) to produce binary per-class predictions.

---

## 6. System Architecture

```
┌──────────────────────┐         HTTP Multipart POST /predict
│   MediLink           │  ──────────────────────────────────►  ┌─────────────────────────┐
│   Flutter Mobile App │                                        │  Inference API Backend  │
│   (Dart / Flutter)   │  ◄──────────────────────────────────  │  (Python / FastAPI  OR  │
└──────────────────────┘         JSON Prediction Response       │   Dart / Shelf)         │
                                                                └──────────┬──────────────┘
                                                                           │
                                                                           ▼
                                                                ┌─────────────────────────┐
                                                                │  EfficientNet-B4 Model  │
                                                                │  (PyTorch .pth weights) │
                                                                └─────────────────────────┘
```

### Component Breakdown

**Backend API (Python — FastAPI)**

- Startup model loading via `asynccontextmanager` lifespan.
- Routes: `GET /`, `GET /health`, `POST /predict`.
- CORS middleware allowing configurable origins.
- API key authentication via `X-API-Key` header.
- Pydantic response models for strict schema validation.

**Backend API (Dart — Shelf port)**

- Functionally identical to the Python version.
- Manual `multipart/form-data` parser (no third-party multipart library required).
- CORS and auth implemented as Shelf middleware.
- `ModelState` class with a stub `runInference()` method, ready for TFLite or ONNX Runtime integration.
- Image preprocessing (resize + ImageNet normalisation) using the `image` Dart package.

**Mobile Client (Flutter — MediLink)**

- Sends X-ray images to the API using `http` package multipart requests.
- Passes `X-API-Key` header for authentication.
- Supports adjustable confidence threshold as a query parameter.
- Displays per-disease probabilities and detected conditions.

---

## 7. API Specification

### Endpoints

| Method | Path       | Auth Required | Description                             |
| ------ | ---------- | ------------- | --------------------------------------- |
| `GET`  | `/`        | No            | Root health check message               |
| `GET`  | `/health`  | No            | Model load status and label list        |
| `POST` | `/predict` | Yes           | Submit X-ray image, receive predictions |

### `/predict` Request

| Parameter   | Type                  | Description                                      |
| ----------- | --------------------- | ------------------------------------------------ |
| `file`      | `multipart/form-data` | X-ray image (JPEG / PNG / WebP, max 20 MB)       |
| `threshold` | `float` (query param) | Confidence cutoff, default `0.5`, range `(0, 1]` |
| `X-API-Key` | Header                | Valid API key                                    |

### `/predict` Response (JSON)

```json
{
  "status": "success",
  "threshold_used": 0.5,
  "inference_time_ms": 142.3,
  "device": "cuda",
  "all_diseases": [
    { "disease": "Atelectasis", "probability": 0.823, "detected": true },
    ...
  ],
  "detected_diseases": [...],
  "no_finding": false
}
```

---

## 8. Technologies and Tools

### Backend (Python)

| Technology     | Purpose                              |
| -------------- | ------------------------------------ |
| Python 3.x     | Runtime                              |
| FastAPI        | REST API framework                   |
| PyTorch        | Deep learning inference              |
| TorchVision    | EfficientNet-B4 model definition     |
| Albumentations | Image augmentation and preprocessing |
| Pillow (PIL)   | Image I/O                            |
| NumPy          | Numerical operations                 |
| Pydantic       | Request/response schema validation   |
| Uvicorn        | ASGI server                          |

### Backend (Dart Port)

| Technology            | Purpose                               |
| --------------------- | ------------------------------------- |
| Dart SDK ≥ 2.17       | Runtime                               |
| shelf `^1.4.0`        | HTTP server framework                 |
| shelf_router `^1.1.3` | URL routing                           |
| image `^3.3.0`        | Image decode / resize / normalisation |
| mime `^1.0.4`         | MIME type detection                   |

### Mobile Client

| Technology                  | Purpose                            |
| --------------------------- | ---------------------------------- |
| Flutter (Dart)              | Cross-platform mobile UI framework |
| http `^1.2.1`               | HTTP client for API calls          |
| image_picker `^1.1.2`       | Camera / gallery image selection   |
| google_fonts `^6.1.0`       | Typography                         |
| shared_preferences `^2.3.2` | Local storage                      |
| flutter_local_notifications | In-app notifications               |
| flutter_native_splash       | Splash screen                      |
| intl `^0.20.2`              | Internationalisation               |

---

## 9. Security and Configuration

- **Authentication:** API key-based authentication via the `X-API-Key` HTTP header. Keys are loaded from environment variables (`API_KEY_MOBILE`, `API_KEY_ADMIN`) with insecure defaults for development.
- **CORS:** Configurable list of allowed origins; wildcard `*` permitted but discouraged in production.
- **File Validation:** Content-type checking, 20 MB file size limit, empty file guard.
- **Threshold Validation:** Threshold strictly in range `(0.0, 1.0]`; returns HTTP 422 otherwise.
- **Model Guard:** API starts even if model fails to load; `/predict` returns HTTP 503 until the model is available.

---

## 10. Challenges and Solutions

| Challenge                                                                 | Solution                                                                                                                    |
| ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Dart SDK version incompatibility (≤2.18 vs packages requiring ≥3.0)       | Pinned `image` to v3.x, `shelf` to v1.4.x, updated `pubspec.yaml` SDK constraint to `>=2.17.0 <3.0.0`                       |
| Name collision between logging function `_error` and HTTP helper `_error` | Renamed logging helpers to `_logInfo`, `_logWarn`, `_logError`; HTTP helper renamed to `httpError`                          |
| `shelf_multipart` package unavailable                                     | Replaced with a custom `_parseMultipart()` function using only `dart:core`, eliminating the dependency entirely             |
| `image` v4 API incompatibility in Dart 2.x                                | Reverted to `image` v3 API: replaced `pixel.r/g/b` property access with `img.getRed/getGreen/getBlue(pixel)` function calls |
| PyTorch `.pth` model not natively loadable in Dart                        | Architecture designed with a stub `runInference()` method; documented TFLite and ONNX Runtime as integration pathways       |

---

## 11. Evaluation Metrics

- **Primary metric:** AUC-ROC (Area Under the Receiver Operating Characteristic Curve) per class and aggregated.
- **Threshold-based metrics:** Precision, recall, and detection flag per class at a configurable threshold (default 0.5).
- **Inference latency:** Measured per request in milliseconds and returned in the API response (`inference_time_ms`).
- Model checkpoint selection based on highest `val_auc` on the validation split.

---

## 12. Future Improvements

- **Model export:** Convert the PyTorch EfficientNet-B4 model to TFLite or ONNX format to enable native Dart/Flutter on-device inference, eliminating the need for a remote server.
- **On-device inference:** Integrate `tflite_flutter` or `onnxruntime` Dart packages to support offline operation within the MediLink app.
- **Expanded label set:** Incorporate additional NIH labels (e.g., Edema, Fibrosis, Hernia, Pneumonia) currently excluded from the 11-class model.
- **DICOM support:** Add native DICOM image parsing on both the API and mobile client for direct integration with radiology workflows.
- **Grad-CAM visualisation:** Return class activation maps alongside predictions to highlight regions of interest in the X-ray, improving clinical interpretability.
- **Production hardening:** Replace wildcard CORS with domain-specific allowlists; rotate API keys; add rate limiting and request logging to a persistent store.
- **CI/CD pipeline:** Automate model retraining, evaluation, and API deployment when new labelled data becomes available.

You are designing and engineering a production-level Flutter healthcare application called “MediLink” for the Doctor role.
The app should feel like a real modern medical startup product with clean UX, strong visual hierarchy, smooth performance, and scalable architecture.
Main doctor goals:

manage patients efficiently

monitor urgent cases quickly

handle schedules and appointments

communicate with patients in real-time

Design style:

modern medical UI

clean and minimal

soft cards and shadows

rounded corners

strong spacing consistency

highly readable typography

responsive on Android phones and smaller screens

Theme:

primary color: medical green

background: soft off-white / light gray

urgent states: red accent

pending states: orange accent

confirmed states: green accent

Screens required:

Doctor Dashboard

Patients Screen

Patient Details Screen

Schedule Screen

Chat List Screen

Real-Time Chat Screen

Profile Screen

Dashboard requirements:

greeting header

doctor name

notification icon

profile avatar

summary cards:

Today’s Patients

Pending Appointments

Urgent Cases

urgent cases section must appear before appointments

urgent case cards should contain:

avatar

patient name

issue summary

urgency badge

quick actions (Call / Chat)

upcoming appointments should use compact cards with subtle actions instead of large buttons

Patients screen:

searchable patient list

filters

patient cards with:

avatar

age

medical condition

Patient details:

medical summary

medications

visit history

quick actions:

Start Chat

Schedule Appointment

Schedule screen:

rename Appointments to “Schedule”

appointment cards:

patient

time

type badge

status badge

support pending and confirmed states

compact accept/reject actions

Chat system:

real-time doctor/patient messaging UI

left/right message bubbles

timestamps

read status

typing indicator

smooth auto-scroll

attachment support placeholder

architecture ready for Firebase or WebSocket integration

use StreamBuilder or equivalent reactive approach

Bottom navigation:

Dashboard

Patients

Schedule

Chat

Profile

Flutter architecture requirements:

reusable widgets

modular structure

stateless widgets where possible

production-ready organization

Suggested components:

summary_card.dart

urgent_case_card.dart

appointment_card.dart

message_bubble.dart

doctor_bottom_nav.dart

Suggested screens:

doctor_dashboard_screen.dart

patients_screen.dart

patient_details_screen.dart

schedule_screen.dart

chat_list_screen.dart

chat_screen.dart

profile_screen.dart

Animation guidelines:

animations must be subtle, smooth, and functional

durations around 200–400ms

avoid flashy or distracting transitions

Required animations:

dashboard fade/slide load animation

staggered list appearance

card press scale interaction

urgent case pulse/highlight

animated bottom navigation transitions

animated chat message appearance

typing indicator animation

animated pending → confirmed transitions

hero animation between patient avatar screens

notification and unread badge micro-interactions

expanding search bar interaction

Use realistic healthcare dummy data with Arabic and English names and real medical conditions.
The final implementation should feel polished, scalable, modern, and production-ready rather than a student project.

Project Conversation Summary

The project is a NestJS backend application using TypeScript, Sequelize, and PostgreSQL.

Initial Issue

An error appeared when running the development server:

TS5103: Invalid value for '--ignoreDeprecations'
Resolution

The issue was resolved by:

Updating NestJS CLI and TypeScript dependencies
Removing unsupported or outdated TypeScript compiler options
Reinstalling dependencies and rebuilding the project

After fixing the issue:

The NestJS server started successfully
Sequelize connected correctly to PostgreSQL
Application modules loaded without errors
API routes were mapped successfully
Backend Configuration

The backend was configured to:

Run on port 5000
Use Sequelize with PostgreSQL
Support modules such as:
Users
Authentication
Medical Records
AI Model Configuration

A separate AI service was configured to run on:

Port 8000
Network Connectivity Issue

The mobile application displayed:

Cannot connect to server
Cause

The issue occurred because:

localhost only works on the same device
The mobile device could not access the backend using localhost
Solution

The backend and AI services were configured to use the machine’s local IP address:

172.20.10.5

Updated endpoints:

Backend:

http://172.20.10.5:5000

AI Model:

http://172.20.10.5:8000
Additional Configuration

The NestJS server was updated to listen on all network interfaces:

await app.listen(5000, '0.0.0.0');
Required Environment Conditions

To allow mobile access:

The laptop and phone must be connected to the same Wi-Fi network
Windows Firewall may need inbound rules for ports:
5000
8000
Testing Steps

Connectivity was tested by opening the following URLs from the mobile browser:

http://172.20.10.5:5000

and

http://172.20.10.5:8000
Development Workflow

The project uses:

npm run start:dev

which enables automatic recompilation and restart in watch mode whenever files change.

MediLink — Mobile Healthcare Application
Complete Project Technical Summary

1. Project Overview
   Project Title: MediLink
   Type: Cross-platform Mobile Healthcare Application
   Developer: Kareem Ashour
   Development Period: 2024 – 2025
   Platform: Android & iOS (single codebase via Flutter)

2. Problem Statement
   Patients in modern healthcare environments face a fragmented digital experience — separate applications for booking appointments, managing prescriptions, tracking medications, accessing medical records, and locating nearby facilities. This fragmentation results in missed medication doses, overlooked appointments, delayed diagnoses, and general healthcare inefficiency. There is a demonstrated need for a unified, intelligent, and accessible mobile platform that consolidates all patient-facing healthcare interactions into a single cohesive system.

3. Objectives

Build a cross-platform mobile application using Flutter serving four distinct user roles: Patient, Doctor, Pharmacy, and Scan Center
Implement role-based routing so each user type sees a tailored interface immediately after login
Provide intelligent medication and appointment reminders with local push notifications tied to device timezone
Integrate an AI-powered chatbot capable of answering health queries and receiving image and record attachments
Enable digital medical record storage, categorization, and retrieval
Support 7 languages with automatic RTL (Right-to-Left) layout for Arabic
Implement a persistent adaptive theming system (Light / Dark / System default)
Connect to a NestJS REST API backend for authentication, registration, and data persistence

4. Technology Stack
   Frontend
   Package / ToolPurposeFlutter 3.x + DartCross-platform UI framework and languageflutter_localizations + intlInternationalization, RTL layout, date formattingflutter_local_notificationsPush notification schedulingtimezone + flutter_timezoneDevice-local timezone for accurate notificationsshared_preferencesPersistent storage for reminders, session, preferencesflutter_colorpickerInteractive color picker in reminder creationimage_pickerCamera and gallery access for chatbot attachmentssmooth_page_indicatorAnimated page dots for onboarding carouselhttpREST API communication
   Backend
   TechnologyRoleNestJS (Node.js)REST API serverJWT AuthenticationSecure session management via access tokensPostgreSQL (inferred)Persistent database for users and health dataREST endpoints/users (signup), /auth/signin (login)
   Development Environment

IDE: Visual Studio Code with Flutter & Dart extensions
Test Device: Physical Android device (MHA L29) + Android Emulator
Build System: Gradle with Kotlin DSL (build.gradle.kts)
OS: Windows
Flutter Channel: Stable

5. System Architecture
   5.1 Folder Structure (Feature-First)
   lib/
   core/
   theme/ app_theme.dart — global theming, color tokens, context extensions
   services/ api_service.dart, session_service.dart, notification_service.dart
   router.dart RoleRouter — post-login role-based navigation
   features/
   auth/ login_screen, signup_screen, welcome_screen
   patient/ home_screen, home_tab, reminder_tab, records_tab, menu_tab
   doctor/ doctor_home.dart
   pharmacy/ pharmacy_home.dart
   labs/ labs_home.dart
   chatbot/ chatbot_screen.dart
   l10n/ 7 ARB translation files
   models/ reminder_model.dart, user_model.dart
   widgets/ theme_toggle_button.dart, lang_toggle_button.dart
   5.2 Global State Management

themeNotifier — ValueNotifier<ThemeMode> wrapping the entire MaterialApp; toggles Light / Dark / System without prop drilling
langNotifier — ValueNotifier<Locale> for instant app-wide language switching
ThemeX extension on BuildContext — exposes context.isDark, context.bg, context.card, context.text, context.divider
L10nX extension on BuildContext — exposes context.l as shorthand for AppLocalizations.of(context)!

5.3 Role-Based Routing Flow
Login → API returns { access_token, role }
→ UserModel.fromJson() parses role
→ SessionService.save(user) persists session
→ RoleRouter reads role →
patient → HomeScreen (4-tab dashboard)
doctor → DoctorHome
pharmacy → PharmacyHome
labs → LabsHome

6. Features and Functionality
   6.1 Authentication

Sign Up — two-step registration:

Step 1: Full name, National ID (14 digits, numeric only), email, password, confirm password — all with strict field-level validation
Step 2: Phone number with country code (+20)
Role selection dropdown: Patient / Doctor / Pharmacy / Scans

Validation Rules:

Email must contain @ and .
Password must start with uppercase + contain a number + contain a symbol
National ID enforced to exactly 14 digits via FilteringTextInputFormatter

Login — submits to /auth/signin; JWT token stored via SharedPreferences
Session persistence — SessionService.load() in main() restores session on relaunch
Logout — clears SharedPreferences and redirects to LoginScreen

6.2 Onboarding

4-slide animated carousel with PageView and SmoothPageIndicator
Slides cover: AI Chat Bot, Near By services, Reminders, Medical Records
Adaptive circle icon backgrounds; opacity differs in dark vs. light mode
Language and theme toggles accessible directly from the onboarding screen

6.3 Home Tab (Patient)

Personalized greeting, search bar, and 4 category icons (Doctors / Pharmacy / Labs / Scans)
Tapping a category highlights it and dynamically replaces the bottom list with matching items
"See All" on Doctors → AllDoctorsScreen; on others → CategoryScreen (themed list)
Upcoming Schedule — loads real saved reminders from SharedPreferences, filters to pending (not yet taken), sorts ascending by time, displays next 3
Tapping "Take" marks the reminder taken, saves to storage, and refreshes the list instantly
AI Health Assistant banner opens chatbot with a bottom-up slide transition

6.4 Reminder System

Full CRUD via AddReminderSheet modal bottom sheet
Swipe left to delete; long-press to edit
Reminder type: Medicine or Doctor appointment
Medicine form types: Tablet, Capsule, Liquid/Syrup, Eye Drops, Ear Drops, Nasal Drops, Injection, Inhaler, Patch/Cream, Powder, Suppository, Lozenges, Sublingual Tablets
Dose selection: ½, 1, 1½, 2, 3 — displayed with fraction labels; index-based selection prevents enum collision
Meal relation: Before meal, After meal, With food, Anytime
Priority: High (🔴) / Normal (🟡) / Low (🟢) — list auto-sorted by priority
Color picker: BlockPicker widget; color themes the entire reminder card
Time + date pickers: system dialog; AM/PM display format
Day-of-week toggles: 7 circular buttons (Mon–Sun)
Start/end date pickers for medication course duration
Meal eaten checkbox — user confirms eating before/after taking medicine
Cards fade and apply strikethrough when marked as taken
All data persisted as JSON list in SharedPreferences

6.5 Push Notification System

Initialized in main() before runApp() via NotificationService.init()
Device timezone resolved at startup via flutter_timezone → set as tz.local
Scheduled using zonedSchedule with matchDateTimeComponents: DateTimeComponents.time for daily recurrence
If scheduled time already passed today → automatically deferred to next day
Android channel: medilink_reminders, Importance.max, Priority.high, vibration + sound
Android 13+ runtime permissions: POST_NOTIFICATIONS, USE_EXACT_ALARM
Notifications cancelled by reminder ID on deletion

6.6 AI Chatbot (MediBot)

Full-screen chat UI with bot avatar and animated "Online" status
Greeting shown once on first open using localized strings
Keyword-based reply engine matching English and Arabic keywords simultaneously

Topics: medical records, appointment booking, medication schedule, nearby pharmacy, greetings

Quick reply chips visible for first 2 messages to guide new users
Animated typing indicator with fade animation while bot processes a response
Attach button (📎) opens a 3-option bottom sheet:

Camera — launches device camera; captured photo sent as rounded image bubble
Gallery — opens photo library; selected image sent as image bubble
Records — opens records picker showing saved medical documents; selection sent as a styled record bubble with icon and label

Three distinct message bubble types: text, image (ClipRRect), record (icon + label)
Bot responds contextually to all three attachment types
Accessible from: central FAB in bottom navigation, Home tab banner, and Menu tab card

6.7 Menu Tab

User profile card with gradient background (name + email)
Menu items: Near By, My Profile, Themes, Language, Notifications, Help & Support
Theme Picker Screen — visual preview cards for Light and Dark modes + System Default tile; animated radio selection; applies instantly via themeNotifier
Language Picker Screen — list of 7 languages with flag emoji, English name, native name, and animated selection; applies via langNotifier and auto-pops
Language toggle button (EN / AR / FR / etc.) always visible in header
Logout clears session and navigates to LoginScreen

6.8 Medical Records Tab

Displays categorized medical documents
Document count shown in header
Categories: Lab, Scan, Doctor, Prescription
Detail view via RecordDetailScreen
Records shareable directly into chatbot conversation

6.9 Category Screens

Pharmacy / Labs / Scans — list of nearby facilities with distance, operating hours, color-coded icons, and a navigate arrow
All Doctors — full doctor list with specialty, rating, review count, years of experience, and "Book" button
Header banner per category showing icon, title, and item count

7. Multilingual Support
   LanguageCodeDirectionEnglishenLTRArabicarRTL (automatic layout flip)FrenchfrLTRGermandeLTRSpanishesLTRRussianruLTRTurkishtrLTR

All strings externalized in ARB files under lib/l10n/
Code generation via flutter gen-l10n produces app_localizations.dart
context.l.keyName shorthand used throughout — zero per-file boilerplate
langNotifier triggers full MaterialApp rebuild on language change
Date/time pickers, number formats, and system widgets adapt automatically via GlobalMaterialLocalizations, GlobalWidgetsLocalizations, and GlobalCupertinoLocalizations delegates

8. Challenges and Solutions
   ChallengeSolution AppliedDark mode not applying across all screensReplaced manual prop-drilling of themeMode with a global ValueNotifier<ThemeMode> wrapping MaterialApp; every widget reads context.isDark automaticallycontext.l used outside build() causing compile errorsMoved all translated strings (dropdowns, lists) into build() as local variables; used index-based state instead of string-based state for dropdownsflutter_timezone 1.0.8 incompatible with newer KotlinUpgraded to flutter_timezone: ^1.1.0Notifications firing at wrong time or not at allAdded device timezone initialization + "past-time defer to tomorrow" logicAndroid 13+ notifications silently blockedAdded requestNotificationsPermission() and requestExactAlarmsPermission() at app initCore library desugaring build failureAdded isCoreLibraryDesugaringEnabled = true and coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") to build.gradle.ktsARB file generation path mismatchCreated l10n.yaml at project root with correct arb-dir and enabled generate: true in pubspec.yamlMedicine form chips not highlighting correctly (shared enum values)Switched from enum-based to index-based selection tracking (\_formIndex) for independent per-chip highlightingconst keyword blocking dynamic errorText on TextFieldsRemoved const from all TextFields using controllers or validation error state

9. AI / Intelligence Components

MediBot (Rule-Based NLP) — keyword matching engine supporting bilingual queries (English + Arabic); no external AI API used; reply logic embedded in \_reply() method within chatbot_screen.dart
Future intent: The chatbot architecture (message list, typing indicator, attachment handling) is designed to be upgradeable to a real LLM API (e.g., Anthropic, OpenAI) by replacing the \_reply() method with an async API call

10. Results and Achievements

Complete cross-platform mobile application running on physical Android device
4 distinct role-based interfaces from a single codebase
Fully functional reminder system with 13 medicine form types, priority sorting, and push notifications
End-to-end authentication flow connected to a live NestJS backend
Chatbot supporting image attachments (camera + gallery) and medical record sharing
Full 7-language support with automatic RTL switching for Arabic
Light / Dark / System theme switching with zero prop-drilling
Persistent session management — app remembers login and reminders across restarts

11. Future Improvements

Replace rule-based chatbot with a real LLM (e.g., Claude API via Anthropic) for intelligent medical dialogue
Connect medical records to a cloud storage backend (e.g., AWS S3 or Firebase Storage) for cross-device access
Implement real-time doctor booking with calendar availability
Add biometric authentication (fingerprint / Face ID)
Expand doctor and pharmacy data with a real geolocation API (Google Maps)
Build out the Doctor, Pharmacy, and Labs role interfaces with full functionality
Add OCR-based prescription scanning using the camera
Implement health metrics tracking (blood pressure, glucose, weight) with charts
Add appointment video consultation via WebRTC
Publish to Google Play Store and Apple App Store

MediLink — Project Summary

1. Project Title
   MediLink — A Flutter-based Medical Reminder & Notification Management Application

2. Problem Statement
   Patients managing chronic conditions or complex medication schedules frequently miss doses or appointments due to a lack of timely, actionable reminders. Generic notification systems do not allow users to confirm intake or defer a reminder from the notification itself, creating friction between the alert and the required action. MediLink addresses this by providing a smart, actionable notification system embedded in a mobile health application.

3. Objectives

Deliver scheduled, recurring medication and doctor appointment reminders on Android and iOS.
Enable users to act on a notification directly (mark as taken or snooze) without opening the app.
Provide an in-app notification centre accessible via a bell icon for reviewing and acting on pending reminders.
Maintain a clean, modular, production-ready codebase that is extensible for future notification types.

4. Features & Functionality
   4.1 Core Notification Scheduling (Existing — Preserved)

Schedules daily recurring reminders for two reminder types: Medicine and Doctor Appointment.
Automatically rolls the scheduled time to the next day if the time has already passed.
Cancels individual notifications by reminder ID.

4.2 Actionable Medication Notifications (New — Feature 1)

A dedicated scheduleMedicationNotification() method that attaches two interactive action buttons to every medication reminder:

✅ Taken — cancels the notification and triggers a callback to mark the dose as completed in the app layer.
⏰ Snooze — cancels the current notification and reschedules a one-off reminder 10 minutes later, preserving all original medication metadata.

A unified handleNotificationAction() dispatcher that processes both foreground and background/terminated-app notification responses.
Structured payload format (reminderId|medicationName|doseStr) embedded in each notification for stateless action handling.
Callback registration pattern (registerActionCallbacks) to keep the service decoupled from the database/domain layer.

4.3 Notification Bell Button Widget (New — Feature 2)

A reusable NotificationBellButton widget placed in the app bar.
Displays a red badge with the unread notification count; animates with ScaleTransition when the count changes.
Bell icon performs a rotation shake animation on tap for tactile feedback.

4.4 In-App Notification List UI (New — Feature 3)

Opens a modal bottom sheet with slide-up + fade-in animation on bell tap.
Lists all active (non-dismissed) in-app notifications.
Each notification card displays:

Contextual icon (medication 💊, doctor 🏥, general ℹ️) with colour-coded background.
Title, description, and a relative timestamp (e.g., "5m ago", "2h ago").

Medication notification cards include ✅ Taken and ⏰ Snooze action buttons rendered inline.
"Clear all" option dismisses all notifications at once.
Empty state illustration shown when no pending notifications exist.

5. Technologies & Frameworks
   LayerTechnologyMobile frameworkFlutter (Dart)Notification engineflutter_local_notificationsTimezone handlingtimezone / timezone/data/latest packagesPlatform targetsAndroid, iOSUI paradigmMaterial Design 3 with custom medical stylingState managementStatefulWidget + callbacks (no external state library)

6. System Architecture & Workflow
   App Bootstrap (main.dart)
   │
   ├── NotificationService.registerActionCallbacks(onTaken, onSnoozed)
   └── NotificationService.init()
   ├── Initialise timezone
   ├── Register iOS DarwinNotificationCategory (Taken + Snooze)
   ├── Initialise FlutterLocalNotificationsPlugin
   └── Request Android permissions (notifications + exact alarms)

Scheduling Flow
│
├── schedule(ReminderModel) → existing, unchanged (doctor/medicine, no actions)
└── scheduleMedicationNotification() → new (medication only, with action buttons)
└── Payload: "reminderId|medicationName|doseStr"

Notification Response Flow
│
├── User taps "✅ Taken"
│ ├── cancel(notificationId)
│ └── \_onTaken callback → app marks dose complete
│
├── User taps "⏰ Snooze"
│ ├── cancel(notificationId)
│ ├── \_scheduleSnooze() → one-off notification in 10 minutes
│ └── \_onSnoozed callback → app updates state
│
└── User taps notification body → navigation handled by app router via payload

In-App UI Flow
│
└── NotificationBellButton (AppBar)
└── tap → \_NotificationSheet (ModalBottomSheet)
└── \_NotificationItem cards
└── Action buttons → handleNotificationAction() (reused)

7. Key Implementation Details

Separate notification channels: medilink_reminders (original) and medilink_medication (new), ensuring existing reminders are never broken by the new feature.
\_FakeNotificationResponse: Implements the NotificationResponse interface to allow the in-app UI to invoke handleNotificationAction() without a real platform callback, eliminating code duplication between system and in-app action handling.
Snooze as one-off: The snooze notification is scheduled without matchDateTimeComponents, making it a single fire rather than a new recurring reminder, which correctly preserves the original daily schedule.
iOS category pre-registration: The DarwinNotificationCategory must be declared before initialize() is called; this constraint is respected in the implementation.
@pragma('vm:entry-point') applied to the background response handler to prevent tree-shaking in release builds.

8. Design Decisions & Rationale
   DecisionRationaleNotificationActions constants classPrevents string mismatch between scheduler and handlerregisterActionCallbacks() patternKeeps NotificationService stateless; app layer owns business logicInAppNotification model separate from ReminderModelUI layer remains decoupled from the domain/data layerPublic handleNotificationAction()Allows the bell sheet UI to reuse snooze scheduling logic without duplicationTwo distinct channelsPreserves backward compatibility; users' existing notification settings are unaffected

9. Future Improvements

Persistent notification history: Store dismissed notifications in a local database (e.g., sqflite or Hive) so the history survives app restarts.
Snooze count limiting: Prevent infinite snoozing by capping snooze attempts per reminder per day.
Rich media notifications: Add medication images or pill illustrations to Android notifications via BigPictureStyleInformation.
Notification grouping: Group multiple medication reminders into a summary notification on Android using InboxStyleInformation.
Wearable support: Extend action handling to Android Wear / watchOS via platform channels.
Analytics integration: Track taken/snoozed rates per medication to surface adherence insights to the user.
Multi-language support: Localise notification titles, body text, and action button labels using Flutter's intl package.

Project Summary: MediBot — AI-Powered Medical Chatbot (Flutter)

Project Title
MediBot — A Flutter-based AI medical chatbot with intelligent file analysis capabilities.

Problem Statement
The original ChatbotScreen implementation had grown into a 1,665-line monolithic StatefulWidget, mixing business logic, API calls, animation controllers, UI rendering, and state management in a single file. This made the codebase difficult to maintain, test, scale, or onboard new developers onto.

Objectives

Refactor the monolith into a clean, modular, reusable widget architecture without breaking any existing functionality
Apply a clear separation of concerns: state/logic in one place, UI rendering delegated to focused child widgets
Improve readability, maintainability, and scalability for a production-grade Flutter application
Preserve all existing animations, interactions, and business logic exactly as-is

Features & Functionality
Chat Core

Real-time messaging with a bot (MediBot)
Session-based conversation management using a timestamp-generated session ID
Optimistic UI: user messages appear immediately before the API responds
Greeting message injected on first render

Message Display

User vs. AI bubble styling (alignment, color, border radius)
Typewriter animation for bot responses (3 chars/tick, 18ms interval)
Expand / collapse for long messages (threshold: 320 characters)
Long-press to copy message text to clipboard
Delivery status indicator per user message: sending → sent → failed
Tap-to-retry on failed messages

AI Processing Cards

Contextual "thinking" cards injected while the AI processes files:

💊 Reading prescription...
🔬 Analyzing your X-ray...
📄 Processing your document...

Cards are removed and replaced by the AI reply once the API responds

Typing Indicator

Staggered 3-dot bounce animation (delays: 0.0, 0.15, 0.30)
Appears in the message list as a virtual slot while \_typing == true

File Attachments

Three medical document categories: Lab Results, X-Ray/Imaging, Prescription
Source options per category: Camera, Gallery, PDF/Files
Multi-file selection and queuing before sending
Animated thumbnail strip with per-file remove and re-take buttons
Files sent sequentially via \_sendPendingFiles()

Scroll Behavior

Auto-scroll to bottom on new messages
\_userScrolledUp guard: pauses auto-scroll when user has scrolled up > 80px
Force-scroll override when the user sends a message

Animations (all preserved)

Message entry: fade-in + upward slide (320ms, easeOutCubic)
Send button: scale down → back up (150ms) on tap
Attachment thumbnails: fade + scale with easeOutBack (260ms)
Thinking card: pulsing opacity repeat (900ms, easeInOut)
Empty state: pulsing opacity repeat (1600ms)
Typing dots: staggered Y-translation loop (900ms)

Technologies & Frameworks
LayerTechnologyUI FrameworkFlutter (Dart)Image Pickingimage_picker packageFile Pickingfile_picker packageHaptic Feedbackflutter/services.dartClipboardflutter/services.dartThemingCustom AppTheme / AppColorsLocalisationcontext.l (custom l10n extension)API LayerCustom ChatService (ngrok-tunnelled backend)AI ServicesChatService (text/file), XRayService (X-ray analysis)

System Architecture & Refactored File Structure
lib/features/chat/
├── chat_screen.dart ← State + all business logic
├── models/
│ └── chat_models.dart ← Pure data types (no UI imports)
└── widgets/
├── messages_list.dart ← ListView, empty state, scroll slot
├── message_bubble.dart ← Bubble rendering + typewriter + status
├── typing_indicator.dart ← 3-dot animation + shared BotAvatar
├── ai_thinking_card.dart ← Pulsing processing card
├── message_input_bar.dart ← Input strip + send animation
├── attachment_preview.dart ← Multi-file bottom sheet
├── \_attachment_sheet_widgets.dart ← Picker/source sheets (part file)
└── shared/
└── chat_animations.dart ← AnimatedMessageEntry, AnimatedThumbnail

Data Models
ChatMessage (immutable value object)

Fields: id, text, image, fileData, fileName, isBot, type, status
Factories: .text(), .image(), .file(), .thinking()
Immutable update: .withStatus(MsgStatus s)

PendingFile

Staged file not yet sent to chat: file, fileName, type, fromCamera

Enums

MsgStatus: sending, sent, failed
MsgType: text, image, file, thinking
AttachmentType: labResult, xray, prescription

Key Architectural Decisions

ChatScreen is the single source of truth — all setState calls live here; child widgets are stateless or locally stateful only for their own animations
\_sendScale animation lives in MessageInputBar — it's purely cosmetic, keeping ChatScreen free of unnecessary TickerProviderStateMixin overhead
\_attachment_sheet_widgets.dart uses part/part of — allows five small sheet sub-widgets to share types cleanly without requiring new public exports
BotAvatar is exported from typing_indicator.dart — reused by both TypingIndicator and AIThinkingCard, eliminating duplication
\_sendWithThinkingCard() helper — collapses three near-identical try/catch blocks (prescription, X-ray, document) into one parameterized method, making it trivial to add new file types
\_userScrolledUp owned by ChatScreen — MessagesList receives the ScrollController as a prop and never reads the guard flag directly

Implementation Highlights

Optimistic UI pattern: user messages are appended to the list immediately before the API call is made, then updated with withStatus() on success or failure
Thinking card lifecycle: injected into \_messages before the API call → removed via \_removeThinkingCard() in both success and error paths
Typewriter skip: animation is bypassed for strings ≤ 40 characters (e.g., short greetings) to avoid a jarring effect on brief responses
Sequential file sending: \_sendPendingFiles() awaits each \_handleSend() call in order, preserving message chronology in the chat

Outcome

Reduced the single monolithic file (~1,665 lines) into 11 focused files totalling ~2,044 lines, each with a single clear responsibility
Every widget is independently testable and composable
Zero existing functionality was broken — all animations, API flows, attachment handling, and scroll behaviour are fully preserved
The architecture now supports adding new message types, attachment categories, or AI services by touching only the relevant isolated file

You were integrating an AI chest X-ray classification model into your medical application.

Initially, the model checkpoint loaded incorrectly because of mismatched key prefixes in the saved state_dict.

After cleaning the checkpoint keys properly, the model loaded successfully with 0 missing keys and 0 unexpected keys.

The model runs on CPU and predicts among 10 chest disease classes.

A port conflict occurred because two services were trying to use port 8000 at the same time.

The solution was to run the AI model server on a different port (for example 8001) while keeping the main backend on 8000.

The mobile app later showed a 30-second timeout during X-ray analysis, indicating that the Flutter app could not get a response from the AI service in time.

This was likely related to network access or the mobile device not reaching the local server correctly.

You also adjusted the disease result display so that instead of listing all detected diseases, the app shows only the single disease with the highest probability.

During signup testing, the app displayed “Sign up failed.”

The backend response showed:
Cannot GET /signup

This indicated that the frontend was sending a GET request to /signup, while the backend expected a POST request.

The signup issue should be fixed by sending the request as POST with the correct JSON body and headers.

You are building a healthcare app called MediLink using Flutter for the frontend and NestJS for the backend.
The project uses a multi-role system where one app serves different users with different interfaces and permissions.
Roles in the system
Patient: medical records, doctor booking, medicine ordering, lab booking, AI chatbot.
Doctor: dashboard, patient list, appointments, diagnosis, prescriptions, chat.
Pharmacy: orders, prescriptions, inventory, delivery tracking.
Labs / Scan Centers: bookings, tests, scans, result uploads, reports.
Multi-role concept
After login, the backend returns the logged-in user’s role.
Based on the role, the app loads a different dashboard, navigation, and permissions.
This allows one shared backend and one mobile app instead of separate apps for each type of user.
Backend status
Your NestJS backend started successfully on port 3000.
PostgreSQL connection is working.
Main routes were mapped correctly.
Earlier backend issue
You had a connection problem in Flutter because the backend URL was not configured correctly.
The device should connect using your computer’s local network IP, not localhost.
TypeScript issue

You got this error:

TS5103: Invalid value for '--ignoreDeprecations'

The likely fix is removing ignoreDeprecations from tsconfig.json, or adjusting it based on the installed TypeScript version.
Doctor dashboard UI review

Your doctor dashboard already has a clean base design.

Suggested improvements:

Improve top spacing in the header.
Make the summary numbers more visually dominant.
Increase contrast slightly in the stat cards.
Move Urgent Cases above Upcoming Appointments.
Replace large repeated View buttons with smaller, subtler actions.
Change bottom navigation label from Appointments to Schedule to avoid wrapping.
Keep a consistent doctor-green theme across all doctor screens.
Current design direction

The goal is to make the doctor UI feel more like a real healthcare product:

clean
minimal
soft cards
clear visual hierarchy
fast scanning of urgent medical information
reusable Flutter widgets
scalable architecture for future screens

You are building a healthcare app called MediLink using Flutter for the frontend and NestJS for the backend.
The project uses a multi-role system where one app serves different users with different interfaces and permissions.
Roles in the system
Patient: medical records, doctor booking, medicine ordering, lab booking, AI chatbot.
Doctor: dashboard, patient list, appointments, diagnosis, prescriptions, chat.
Pharmacy: orders, prescriptions, inventory, delivery tracking.
Labs / Scan Centers: bookings, tests, scans, result uploads, reports.
Multi-role concept
After login, the backend returns the logged-in user’s role.
Based on the role, the app loads a different dashboard, navigation, and permissions.
This allows one shared backend and one mobile app instead of separate apps for each type of user.
Backend status
Your NestJS backend started successfully on port 3000.
PostgreSQL connection is working.
Main routes were mapped correctly.
Earlier backend issue
You had a connection problem in Flutter because the backend URL was not configured correctly.
The device should connect using your computer’s local network IP, not localhost.
TypeScript issue

You got this error:

TS5103: Invalid value for '--ignoreDeprecations'

The likely fix is removing ignoreDeprecations from tsconfig.json, or adjusting it based on the installed TypeScript version.
Doctor dashboard UI review

Your doctor dashboard already has a clean base design.

Suggested improvements:

Improve top spacing in the header.
Make the summary numbers more visually dominant.
Increase contrast slightly in the stat cards.
Move Urgent Cases above Upcoming Appointments.
Replace large repeated View buttons with smaller, subtler actions.
Change bottom navigation label from Appointments to Schedule to avoid wrapping.
Keep a consistent doctor-green theme across all doctor screens.
Current design direction

The goal is to make the doctor UI feel more like a real healthcare product:

clean
minimal
soft cards
clear visual hierarchy
fast scanning of urgent medical information
reusable Flutter widgets
scalable architecture for future screens

MediLink — Project Summary

1. Project Title
   MediLink — A Cross-Platform Mobile Healthcare Application
   "Your Link to Doctors"

2. Problem Statement
   Patients in developing regions face significant barriers to healthcare access — difficulty finding nearby doctors, pharmacies, and labs; poor medication adherence due to lack of reminders; fragmented medical records across multiple providers; and no intelligent triage tool to help assess symptoms before visiting a physician. MediLink addresses all of these in a single unified mobile application.

3. Objectives

Provide patients with a centralized digital health companion
Enable real-time discovery of nearby doctors, pharmacies, and laboratories
Digitize and organize personal medical records
Deliver smart medication and appointment reminders with push notifications
Offer AI-powered health chat assistance and X-ray diagnosis support
Support multiple user roles — Patient, Doctor, Pharmacy, and Lab
Support multiple languages and both light and dark UI themes

4. System Architecture
   ┌─────────────────────────────────────────────────┐
   │ Flutter Mobile App │
   │ (Patient / Doctor / Pharmacy / Lab interfaces) │
   └────────────────┬────────────────────────────────┘
   │ HTTP
   ┌────────┴─────────┐
   │ │
   ┌────▼─────┐ ┌──────▼──────────┐
   │ Node.js │ │ Python FastAPI │
   │ Backend │ │ (X-Ray Server) │
   │ REST API │ │ port 8000 │
   └────┬─────┘ └──────┬──────────┘
   │ │
   ┌────▼─────┐ ┌──────▼──────────┐
   │ Database │ │ EfficientNet-B4 │
   │ (Users, │ │ PyTorch Model │
   │ Records) │ │ (.pth file) │
   └──────────┘ └─────────────────┘

5. Features and Functionality
   5.1 Authentication & Onboarding

4-slide animated onboarding introducing core features
Multi-step sign-up form with full field validation:

Full name (required)
Gender and role selection (Patient / Doctor / Pharmacy / Lab)
National ID — digits only, exactly 14 characters
Email — must contain @ and .
Password — must start with uppercase, contain a number and a symbol
Confirm password match

Phone number entry with country code (+20)
OTP phone verification screen (4-digit pin input)
Login with email/password, loading state, and error handling
"Continue as Guest" option
Forgot password — 3-step flow: email → OTP → new password
Session persistence using SessionService — logged-in users skip login on relaunch
Role-based routing via RoleRouter — navigates to correct home screen per role

5.2 Home Dashboard (Patient)

Personalized greeting with theme toggle
Search bar for doctors, pharmacies, and labs
Category filter pills — Doctors, Pharmacy, Labs, Scans
AI Health Assistant banner linking to chatbot
Upcoming medication schedule with "Take" action buttons
Top doctors list with star ratings and specializations

5.3 Reminder System

Full CRUD — add, edit, delete reminders
Reminder types — Medicine or Doctor Appointment
Medicine form types — Tablet, Capsule, Liquid, Injection, Drops, Inhaler, Patch, Powder, Other
Dose selection — ½, 1, 1½, 2, 3
Meal relation — Before meal, After meal, With food, Anytime
Priority levels — High (🔴), Normal (🟡), Low (🟢), with color-coded dot indicator
Custom color picker per reminder using flutter_colorpicker
Time picker and day-of-week repeat selector
Start and end date pickers
"Ate already" checkbox for meal-dependent medicines
Push notifications via flutter_local_notifications + timezone
Reminders sorted by priority automatically
Persistent storage using shared_preferences
Swipe left to delete, long-press to edit
Live counter — "X of Y taken today"

5.4 Medical Records

Digital storage of lab reports, scans, prescriptions, diagnoses
Record types — Lab Report, Scan, Prescription, Report
Each record has title, doctor/facility, date, status, diagnosis, doctor notes, and attachments
Color-coded type badges
Download button per record
Add new record form with attachment support

5.5 AI Chatbot

Text messages routed to AI chat backend (ChatService)
Image (X-ray) uploads routed to Python model server (XRayService)
Single unified handler function routes automatically based on input type
Typing indicator animation while awaiting response
Quick reply chips for common health queries
Slide-up entry animation

5.6 X-Ray AI Diagnosis

User picks X-ray image from device
Image sent via multipart POST to Python FastAPI server
EfficientNet-B4 model runs inference and returns probabilities for 10 disease classes
Results displayed in chatbot as a structured message
Disease classes detected — Atelectasis, Cardiomegaly, Consolidation, Effusion, Emphysema, Infiltration, Mass, No Finding, Nodule, Pleural Thickening

5.7 Near By

Discover nearby doctors, pharmacies, and laboratories
Distance, hours, and booking information displayed

5.8 Menu & Profile

User profile card with gradient header
Featured AI chatbot shortcut
Navigation to Near By, My Profile, My Doctors, Pharmacy, Laboratories, Settings, Help
Theme toggle (light/dark)
Language toggle
Log Out

5.9 Theme System

Global ValueNotifier<ThemeMode> — rebuilds entire MaterialApp on toggle
No prop drilling — every widget reads context.isDark, context.bg, context.card, context.text via ThemeX extension on BuildContext
Light and dark themes both built from single \_base(Brightness) function

5.10 Multilingual Support

Localization using Flutter's AppLocalizations (app_en.arb and translations)
Languages supported — English, Arabic, German, French, Spanish, Russian, Turkish
Global ValueNotifier<Locale> (langNotifier) for runtime language switching
RTL layout support for Arabic
LangToggleButton widget for in-app switching

6. Technologies and Tools
   CategoryTechnologyMobile frameworkFlutter (Dart)State managementValueNotifier + ValueListenableBuilderRoutingCustom RoleRouter + MaterialPageRouteBackend APINode.js REST API (ApiService)AI model serverPython FastAPI (uvicorn, port 8000)ML frameworkPyTorch (torch, torchvision)ML modelEfficientNet-B4 (pretrained, fine-tuned)Notificationsflutter_local_notifications, timezoneStorageshared_preferencesColor pickerflutter_colorpickerOTP inputpin_code_fieldsFontsGoogle Fonts — PoppinsPage indicatorssmooth_page_indicatorSession managementSessionService (custom)LocalizationFlutter AppLocalizations + .arb filesImage processingPython PIL (Pillow), torchvision.transformsAPI communicationhttp package (Dart)

7. AI/ML Model Details
   Model

Architecture: EfficientNet-B4
File: best_bal_efficientnet_b4_model.pth (PyTorch)
Task: Multi-label chest X-ray disease classification
Number of output classes: 10 (auto-detected from checkpoint)
Activation: Sigmoid (multi-label, not softmax)
Input size: 380 × 380 pixels
Normalization: ImageNet mean [0.485, 0.456, 0.406], std [0.229, 0.224, 0.225]
Device: CPU (CUDA if available)
Inference time: ~123ms on CPU

Disease Classes
Atelectasis, Cardiomegaly, Consolidation, Effusion, Emphysema, Infiltration, Mass, No Finding, Nodule, Pleural Thickening
Python Server Endpoints
EndpointMethodDescription/GETServer status/healthGETModel load status, labels, device/analyzePOSTAccepts image, returns probabilities

8. User Roles
   RoleHome ScreenPatientHomeScreen (full patient dashboard)DoctorDoctorHomePharmacyPharmacyHomeLabLabsHome
   Role is parsed from API response, saved in SessionService, and RoleRouter navigates accordingly on login and app relaunch.

9. Challenges and Solutions
   ChallengeSolutionDark mode not updating on all screensReplaced prop-drilling with global ValueNotifier + ThemeX extension on BuildContextIcons.smart_toy_outlined missingReplaced with Icons.chat_bubble_outline_roundedFlutter cannot run .pth PyTorch modelBuilt Python FastAPI server; Flutter sends image via HTTPflutter_timezone Kotlin Registrar errorUpgraded to flutter_timezone: ^1.1.0Core library desugaring errorAdded isCoreLibraryDesugaringEnabled = true and desugar_jdk_libs dependency to build.gradle.ktsnumpy.\_core not found (Python 3.8 + numpy 1.x)Added numpy.\_core shim at top of server.pyModel class mismatch (10 vs 11 classes)Auto-detect num_classes from checkpoint's classifier weight shapeAll X-ray probabilities ~0.25 (uniform)Identified checkpoint key prefix mismatch — diagnostic logging added to expose real key namesPhone cannot reach Python serverConfigured correct PC local IP, opened port 8000 via Windows Firewall, tested via phone browserconst keyword blocking dynamic errorTextRemoved const from TextField and InputDecoration wherever controllers or error text are used

10. Project File Structure
    lib/
    ├── main.dart
    ├── core/
    │ ├── theme/
    │ │ └── app_theme.dart ← colors, themes, ThemeX extension
    │ ├── services/
    │ │ ├── api_service.dart ← Node.js backend calls
    │ │ ├── api_ai.dart ← ChatService + XRayService
    │ │ ├── session_service.dart ← login session persistence
    │ │ └── notification_service.dart
    │ └── router.dart ← RoleRouter
    ├── models/
    │ ├── reminder_model.dart
    │ └── user_model.dart
    ├── l10n/
    │ ├── app_en.arb
    │ ├── app_ar.arb
    │ ├── app_de.arb
    │ ├── app_fr.arb
    │ ├── app_es.arb
    │ ├── app_ru.arb
    │ └── app_tr.arb
    ├── widgets/
    │ ├── theme_toggle_button.dart
    │ └── lang_toggle_button.dart
    ├── screens/
    │ ├── splash_screen.dart
    │ ├── onboarding/
    │ ├── auth/
    │ │ ├── login_screen.dart
    │ │ ├── signup_screen.dart
    │ │ ├── phone_verification_screen.dart
    │ │ └── forgot_password_screen.dart
    │ └── home/
    │ ├── home_screen.dart
    │ ├── home_tab.dart
    │ ├── reminder_tab.dart
    │ ├── records_tab.dart
    │ ├── menu_tab.dart
    │ ├── chatbot_screen.dart
    │ └── add_reminder_sheet.dart
    └── features/
    ├── patient/
    ├── doctor/
    ├── pharmacy/
    └── labs/

xray_server/
├── server.py
├── best_bal_efficientnet_b4_model.pth
└── requirements.txt

11. Current Status and Pending Issues
    ItemStatusFlutter app UI — all screens✅ CompleteDark/light mode✅ CompleteMultilingual support✅ CompleteAuth flow with validation✅ CompleteReminder system with notifications✅ CompleteMedical records✅ CompleteRole-based routing✅ CompletePython X-ray server running✅ RunningX-ray model connected to Flutter✅ ConnectedX-ray model weights loading correctly⏳ Pending — checkpoint key prefix mismatch under investigationEmail OTP verification⏳ Pending — backend method not yet selectedNotification delivery on real device⏳ Pending — timezone package issue was resolved

12. Future Improvements

Complete email OTP verification flow with a real email provider
Fix EfficientNet-B4 checkpoint key prefix so model weights load correctly and produce accurate X-ray predictions
Deploy Python model server to cloud (Railway or Render) for production use
Add real-time doctor booking and appointment management
Implement Google and Apple social sign-in
Add patient health analytics dashboard with charts
Expand X-ray model to cover all 14 CheXNet disease classes
Add offline support for medical records using local database

The issue was that the user's name was not appearing after login because the JWT token returned from the backend only contained:

- sub
- email
- role
- iat
- exp

and did not include a `name` field.

The Flutter app was decoding the JWT and trying to read:

```dart
decoded['name']
```

which returned `null`, causing the `UserModel` to store an empty string for the name.

The solution discussed was:

1. Add a `getToken()` method inside `session_service.dart` to retrieve the saved access token from SharedPreferences.

2. Add a `getProfile()` API method inside `api_service.dart` that sends the token in the Authorization header and requests the authenticated user profile from the backend.

3. Modify the `_login()` method in `login_screen.dart`:
   - Decode the token
   - Temporarily save the token
   - Call `ApiService.getProfile()`
   - Read the real user name from the profile response
   - Create a complete `UserModel`
   - Save the final user session

4. Ensure the backend `/auth/me` endpoint returns user data including:
   - name
   - email
   - id

An alternative temporary workaround was suggested:
extracting a display name from the email using:

```dart
email.split('@')[0]
```

until the backend profile endpoint is available.

You were working on a NestJS backend project using TypeScript, Sequelize, and PostgreSQL.

At first, the project failed with this TypeScript error:

TS5103: Invalid value for '--ignoreDeprecations'

The issue was resolved by:

Updating Nest CLI and TypeScript
Removing unsupported TypeScript compiler options

After that, the backend started successfully:

PostgreSQL connected correctly through Sequelize
All modules loaded successfully
API routes were mapped correctly
The server started normally

Then the backend port was changed from 3000 to a custom port using:

await app.listen(process.env.PORT ?? 8000);

Later, the server was updated to allow mobile device access over the local network using:

await app.listen(process.env.PORT ?? 8000, '0.0.0.0');

The backend was tested from a real mobile device using the local IP address instead of localhost.

The correct local IP detected from ipconfig was:

172.20.10.5

The backend was running successfully on port 5000.

A connection issue (Cannot connect to server) was fixed by:

Using the correct local IP
Allowing external access with 0.0.0.0
Ensuring both devices were on the same hotspot network

After that, requests reached the server successfully, but the mobile app started receiving:

Internal server error

Investigation showed that:

The backend only implemented signIn
There was no signup/register implementation

Current AuthService only contains:

async signIn(body: SignInDto)

So the frontend signup requests were failing because no signup logic existed.

The recommended fix was:

Add a signup method to AuthService
Add a POST /auth/signup endpoint in AuthController
Hash passwords using bcrypt
Create users through UsersService
Ensure all required Sequelize model fields are provided

The backend setup, networking, and database connection are now working correctly; the remaining issue is implementing and debugging the signup flow.

MediLink — Project Summary Report

1. Project Overview
   Project Title: MediLink — Your Link to Doctors
   Type: Cross-platform mobile application
   Framework: Flutter (Dart)
   Target Platform: Android and iOS
   MediLink is a comprehensive medical companion mobile application designed to connect patients with healthcare services. The app provides a unified platform for finding doctors, managing medications, storing medical records, receiving health reminders, and interacting with an AI-powered health assistant.

2. Problem Statement
   Patients face fragmented access to healthcare services — doctor discovery, medication management, medical record storage, and health guidance are spread across multiple disconnected platforms. MediLink addresses this by consolidating all essential medical services into a single, intelligent, multilingual mobile application.

3. Objectives

Build a fully functional cross-platform medical app using Flutter
Provide role-based access for patients, doctors, pharmacies, and radiology centers
Implement smart medication and appointment reminders with push notifications
Enable AI-powered health chat and X-ray image analysis
Support multiple languages with full RTL support for Arabic
Connect to a NestJS backend with JWT authentication and role-based routing
Store medical records digitally with attachment support

4. System Architecture
   4.1 Frontend — Flutter App
   lib/
   ├── core/
   │ ├── theme/ → app_theme.dart (colors, dark/light, extensions)
   │ ├── services/ → api_service, notification_service,
   │ │ session_service, api_ai
   │ └── router.dart → RoleRouter (routes by user role)
   ├── features/
   │ ├── auth/ → splash, onboarding, welcome, login,
   │ │ signup, forgot password, phone OTP
   │ └── patient/
   │ └── screens/ → home, reminder, records, menu,
   │ chatbot, all_doctors, all_reminders,
   │ category screens
   ├── models/
   │ └── reminder_model.dart
   ├── widgets/
   │ ├── theme_toggle_button.dart
   │ └── lang_toggle_button.dart
   └── l10n/ → ARB translation files (7 languages)
   4.2 Backend — NestJS

REST API with JWT authentication
Role-based access control (patient, doctor, pharmacy, labs)
Endpoints for login, signup, user management
Connected via ApiService using HTTP package

4.3 AI Services

ChatService — connects to a custom AI chat backend via ngrok tunnel
XRayService — connects to a Python ML model server for X-ray image analysis

5. Features and Functionality
   5.1 Authentication

Multi-step signup (profile info → phone verification)
Login with email/password and JWT token
Role-based routing after login (patient → HomeScreen, doctor → DoctorHome, etc.)
Guest mode access
Forgot password flow
Social login UI (Google, Apple)
Form validation (email format, password strength, national ID 14 digits)
Session persistence using SharedPreferences

5.2 Home Screen

Personalized greeting
Search bar for doctors and pharmacies
Category navigation (Doctors, Pharmacy, Labs, Radiology)
AI ChatBot banner shortcut
Upcoming medication schedule (sorted by time, live from reminders)
Top doctors listing with ratings
Floating Action Button for chatbot (center of bottom nav)

5.3 Reminder System

Full CRUD — add, edit, delete reminders
Two reminder types: Medicine and Doctor appointment
Medicine form types: Tablet, Capsule, Liquid/Syrup, Drops (Eye/Ear/Nasal), Injection, Inhaler, Patch/Cream, Powder, Suppository, Sublingual, Lozenge
Dose selection: ½, 1, 1½, 2, 3
Meal relation: Before meal, After meal, With food, Anytime
Priority levels: High 🔴, Normal 🟡, Low 🟢 (with priority dot indicator)
Custom color picker per reminder
Time picker and day-of-week repeat selector
Start and end date range
"Ate already" checkbox for meal-dependent medicines
Push notifications using flutter_local_notifications with exact alarm scheduling
Timezone-aware scheduling (reschedules to next day if time has passed)
Swipe left to delete, long press to edit
Data persisted via SharedPreferences (JSON serialization)
Upcoming section on home tab shows only pending reminders sorted by time

5.4 Medical Records

List of stored medical documents
Record types: Lab Report, Scan, Prescription, Diagnosis, Report
Fields: title, doctor/facility, date, status, diagnosis, doctor notes
File attachments support
Status indicators: Stable, Pending, Critical
Add new record form with validation

5.5 AI ChatBot (MediBot)

Real-time AI chat via custom backend
X-ray image analysis via Python ML model
Attachment support: gallery photo, camera photo, PDF, DOC/DOCX
File preview bubble in chat (distinct UI for images vs documents)
Long press any message to copy text to clipboard
Paste from clipboard into text field (Flutter built-in)
Typing indicator animation
Session-based conversation context

5.6 Category Screens

Doctors: full list with specialization, rating, experience, book button
Pharmacy: nearby pharmacies with distance and hours
Labs: nearby laboratories
Radiology/Scan centers
Each category opens dedicated screen with header banner and item cards

5.7 Menu

Profile card with gradient
AI ChatBot featured banner
Navigation items: Near By, My Profile, Settings, Help & Support
Language toggle button (cycles through 7 languages)
Dark/Light mode toggle
Logout button

6. Technologies and Tools
   CategoryTechnologyFrontendFlutter 3.x, DartState ManagementValueNotifier, setStateBackendNestJS (Node.js)AuthenticationJWT tokensLocal StorageSharedPreferencesPush Notificationsflutter_local_notifications, timezoneHTTP Clienthttp packageAI ChatCustom backend via ngrokX-Ray AnalysisPython ML model serverImage Handlingimage_picker, file_pickerLocalizationflutter_gen, ARB filesFontsGoogle Fonts (Poppins)UI Extrasflutter_colorpicker, smooth_page_indicator, pin_code_fieldsNative Splashflutter_native_splashIDEVS CodeTest DeviceAndroid physical device (Huawei MHA-L29)

7. Localization
   The app supports 7 languages with full RTL support:
   CodeLanguagearArabic (default, RTL)enEnglishdeGermanesSpanishfrFrenchruRussiantrTurkish
   Implementation:

ARB files per language in lib/l10n/
flutter gen-l10n generates AppLocalizations
context.l extension shortcut via ThemeX extension in app_theme.dart
langNotifier (ValueNotifier) enables instant language switching without restart
toggleLang() cycles through all 7 languages
Language toggle button available on every major screen
Dropdown values use index-based selection to survive language switching without crashing

8. Theme System

Global: themeNotifier (ValueNotifier<ThemeMode>) — toggling rebuilds entire app
Extension: context.isDark, context.bg, context.card, context.text, context.divider
Light and dark themes defined in app_theme.dart using ThemeData
All widgets read theme from context — no manual prop drilling
Dark mode: subtle borders instead of shadows, opacity-adjusted icon backgrounds

9. Data Models
   ReminderModel
   id, name, type (medicine/doctor), form, mealRelation,
   priority, dose, color, time, startDate, endDate,
   weekDays[7], eaten, taken
   → toJson() / fromJson() for persistence
   UserModel
   id, name, email, role (patient/doctor/pharmacy/labs), token
   → parsed from API JWT response
   → role determines post-login screen via RoleRouter

10. Challenges and Solutions
    ChallengeSolutionDark mode not updating on all screensReplaced prop drilling with global ValueNotifier + context.isDark extensioncontext.l used outside build()Moved all translated lists inside build() methodDropdown crash on language switchReplaced String values with int index for dropdown stateTimezone notifications firing at wrong timeUsed device timezone offset matching from timezone packageAndroid 13 notifications silently blockedAdded requestNotificationsPermission() and requestExactAlarmsPermission()flutter_timezone incompatible with Kotlin versionReplaced with offset-matching approach using timezone package directlyCore library desugaring errorAdded isCoreLibraryDesugaringEnabled = true and desugar_jdk_libs in build.gradle.ktsARB keys with invalid Dart namesRenamed all keys to camelCase without special characters or numbers at startstatic const list can't hold translated textMoved lists inside build() as local final variables

11. Project Structure Notes

Role-based routing: after login, RoleRouter reads SessionService.currentUser.role and navigates to the correct home screen
Guest mode: patients can skip login and access HomeScreen directly
Session management: SessionService handles save/load/clear of user session using SharedPreferences
Development mode: SessionService.clear() in main() forces fresh start on every run; switch to SessionService.load() for production

12. Future Improvements

Complete doctor, pharmacy, and labs role dashboards
Real-time appointment booking system
Integration with map services for "Near By" feature
Telemedicine / video call with doctors
OCR for automatic extraction of data from uploaded medical documents
Wearable device integration for health monitoring
Offline mode with sync when connection is restored
Rating and review system for doctors
Medicine barcode scanner for quick reminder creation
Backend deployment to production server (replace ngrok tunnels)

MediLink — Project Summary

1. Project Title
   MediLink — An AI-Powered Medical Mobile Application

2. Project Overview
   MediLink is a production-ready cross-platform mobile healthcare application built with Flutter. It integrates two computer vision AI models and a conversational chatbot to assist patients and medical professionals. The app supports multiple user roles (patient, doctor, pharmacy, labs) and provides role-based UI experiences after authentication.

3. Problem Statement
   Patients and doctors often lack accessible tools that combine medical image analysis, prescription reading, and intelligent health conversations in a single unified platform. MediLink addresses this by embedding AI directly into a mobile app — enabling chest X-ray diagnosis, prescription medicine recognition, and symptom-based chat — without requiring users to visit separate services.

4. Objectives

Build a multi-role healthcare mobile app (patient, doctor, pharmacy, labs)
Integrate a chest X-ray analysis AI model for disease detection
Integrate a prescription photo reader AI model for medicine identification
Provide a conversational AI chatbot for symptom discussion and health guidance
Expose both CV models through a single unified FastAPI backend server
Deliver a production-quality doctor UI with real-time chat, appointments, and patient management

5. Features and Functionality
   Authentication

Login and signup with role-based routing
Roles: patient, doctor, pharmacy, scans/labs
Session persistence via SessionService
Guest mode (continue without login)
Forgot password screen

Chatbot Screen

Text-based medical conversation using an NLP backend
Image attachment support (gallery + camera)
X-ray mode: sends image to X-ray model, displays disease findings
Prescription mode: sends image to prescription model, displays detected medicines
Separate attachment picker section for "Prescription Reader" vs standard image upload
Session ID tracking per conversation

X-Ray Analysis

Accepts chest X-ray JPEG/PNG images
Returns list of detected diseases with probability scores
Labels: Atelectasis, Cardiomegaly, Consolidation, Effusion, Emphysema, Infiltration, Mass, No Finding, Nodule, Pleural Thickening, Pneumothorax, Edema, Fibrosis, Pneumonia (14 classes, auto-detected from checkpoint)
Configurable detection threshold (default 0.25)

Prescription Reader

Accepts prescription photos
Returns list of 78 detected medicine classes with confidence scores
Configurable detection threshold (default 0.5)
Protected by API key header

Doctor UI (fully redesigned)

Dashboard: staggered load animations, stat cards, urgent cases with pulsing border, upcoming appointments
Patients: animated search bar, filter chips (All / Active / Critical / Follow-up), Hero avatar transitions
Patient Details: Hero animation, medical info, prescriptions, notes, Call/Chat/Schedule actions
Appointments (Schedule): animated accept/reject with live status badge transition
Chat List: online indicators, pulsing unread badges, patient search
Chat Screen: real-time-ready chat UI, animated message bubbles, typing indicator (3-dot), auto-scroll, read receipts
Profile: stats, grouped settings, logout

6. Technologies and Tools
   LayerTechnologyMobile FrontendFlutter (Dart)Backend APIPython, FastAPI, UvicornCV Model FrameworkPyTorch, TorchVisionImage PreprocessingPIL (Pillow)HTTP Communicationhttp package (Dart), multipart/form-dataSession ManagementCustom SessionService (Dart)RoutingCustom RoleRouter based on UserRole enumLocalizationAppLocalizations (Flutter l10n)Tunneling (dev)ngrok (optional, replaced by LAN IP in production setup)

7. AI / ML Models
   Model 1 — Chest X-Ray Classifier

Architecture: EfficientNet-B4
Input size: 380×380 pixels
Output: 14-class multi-label classification (sigmoid activation)
File: best_bal_efficientnet_b4_model.pth
Format: Standard PyTorch .pth checkpoint
Auto-detects number of output classes from checkpoint at load time

Model 2 — Prescription Medicine Classifier

Architecture: EfficientNet-B0
Input size: 224×224 pixels
Output: 78-class multi-label classification (sigmoid activation)
File: best_model.pth (repackaged from best_model_pt.zip)
Format: PyTorch zip-format checkpoint, internally restructured from best_model/ root to archive/ root for Windows compatibility
Protected by x-api-key request header

8. System Architecture
   Flutter App
   │
   ├── Auth Layer (login / signup / session)
   │ └── RoleRouter → DoctorHome / HomeScreen / PharmacyHome / LabsHome
   │
   ├── Chatbot Screen
   │ ├── Text → ChatService → /chat (NLP backend, separate ngrok URL)
   │ ├── Image (X-ray) → XRayService → /analyze
   │ └── Image (Prescription) → PrescriptionService → /prescription/analyze
   │
   FastAPI Server (server.py — single unified server, port 8000)
   ├── POST /analyze → EfficientNet-B4 (X-ray, 14 classes)
   └── POST /prescription/analyze → EfficientNet-B0 (Prescription, 78 classes)

Both models load at server startup via lifespan context
Each model loads independently — if one fails, the other still serves
Server prints local LAN IP on startup for Flutter configuration
Single kServerBaseUrl constant in api_ai.dart controls both services

9. Implementation Details
   Backend (server.py)

Single merged FastAPI server replaces two separate servers
Auto-detects num_classes from classifier weight tensor shape
Handles multiple checkpoint formats: raw state_dict, model_state_dict, state_dict keys
Strips module., model., net. prefixes from keys (DataParallel compatibility)
Uses strict=False loading with missing/unexpected key reporting
numpy \_core shim included for older numpy compatibility
CORS middleware enabled for all origins

Flutter (api_ai.dart)

ChatService: multipart POST with message + session_id + optional file
XRayService: multipart POST to /analyze, no API key required
PrescriptionService: multipart POST to /prescription/analyze, sends x-api-key header
XRayResult.toSummary() and PrescriptionResult.toSummary() format chat bubble text
Single shared constant kServerBaseUrl — change one line to switch server IP

Model File Fix

The original best_model_pt.zip extracted to a folder (best_model/) with internal zip root best_model/
torch.load on Windows requires the internal root to be named archive/
Fix: repackaged the zip programmatically, renaming all entries from best_model/ → archive/, producing a valid best_model.pth loadable directly by PyTorch on all platforms

Flutter Routing Bug (investigated)

Symptom: doctor role always opened patient UI after login
Root cause identified as UserModel.fromJson potentially not receiving role field from API response
\_parseRole() correctly maps: 'doctor' → UserRole.doctor, 'scans' → UserRole.labs, etc.
Recommended debug: print result['role'] and user.role after login to confirm API response structure

10. Challenges and Solutions
    ChallengeSolutionTwo models requiring two serversMerged into single server.py with separate route prefixesPrescription model failing on Windows with "Permission denied"Root cause: torch.load cannot load a folder on Windows; fixed by repackaging zip with correct archive/ internal structurengrok dependency for mobile testingReplaced with LAN IP (0.0.0.0 binding); server prints IP on startupnumpy \_core missing on older environmentsAdded manual module shim at server startupRole-based routing not workingTraced to UserModel.fromJson / API response role field mismatchOld doctor_chat.dart split into two filesReplaced with doctor_chat_list.dart + doctor_chat_screen.dart

11. Project File Structure (relevant files)
    lib/
    ├── core/
    │ ├── services/
    │ │ ├── api_service.dart
    │ │ └── session_service.dart
    │ ├── theme/app_theme.dart
    │ └── router.dart
    ├── features/
    │ ├── auth/
    │ │ ├── model/user_model.dart
    │ │ └── screens/
    │ │ ├── login_screen.dart
    │ │ └── signup_screen.dart
    │ ├── doctor/
    │ │ └── screens/
    │ │ ├── doctor_home.dart
    │ │ ├── doctor_dashboard.dart
    │ │ ├── doctor_patients.dart
    │ │ ├── patient_details_screen.dart
    │ │ ├── doctor_appointments.dart
    │ │ ├── doctor_chat_list.dart
    │ │ ├── doctor_chat_screen.dart
    │ │ └── doctor_profile.dart
    │ └── patient/
    │ └── screens/
    │ ├── home_screen.dart
    │ └── chatbot_screen.dart
    └── core/services/
    └── api_ai.dart ← ChatService, XRayService, PrescriptionService

server/
├── server.py ← Unified FastAPI server (X-ray + Prescription)
├── best_bal_efficientnet_b4_model.pth ← X-ray model
└── best_model.pth ← Prescription model (repackaged)

12. Future Improvements

Replace LAN IP with a deployed cloud server (Railway, Render, or AWS EC2) for production access outside local network
Fill in the 78 real medicine class names in PRESCRIPTION_LABELS once training labels are available
Connect doctor chat screen to a real-time backend (Firebase Firestore or WebSocket)
Implement push notifications for urgent cases and new appointment requests
Add authentication to the X-ray endpoint (currently open, prescription endpoint is protected)
Build out pharmacy and labs role UIs following the same design system as the doctor UI
Add model confidence calibration and explainability (Grad-CAM heatmaps on X-ray results)
Implement offline mode with cached results for low-connectivity environments

Project Summary: Healthcare Proximity & Management Platform

1. Project Title
   Healthcare Proximity & Management Platform — a mobile + backend system connecting patients with nearby healthcare providers (doctors, pharmacies, labs, radiology centers).

2. Problem Statement
   Patients often struggle to find nearby, highly-rated healthcare providers quickly. There is no unified system that allows a patient to locate doctors by specialty, find pharmacies/labs/radiology centers by proximity, manage medical records, set reminders, and maintain an emergency profile — all in one place.

3. Objectives

Build a RESTful backend API to manage users, authentication, and healthcare provider discovery
Develop a Flutter mobile frontend that communicates with the backend
Implement proximity-based search with smart ranking (distance + rating)
Secure all sensitive endpoints using JWT authentication
Support multiple user roles with role-based access

4. Features & Functionality
   Authentication

User registration (POST /users) with hashed passwords
Login (POST /auth/signin) returning a JWT access token
Token stored securely on device via SharedPreferences
Protected routes guarded by JwtAuthGuard

User Roles

patient, doctor, pharmacy, lab, radiology

Proximity Search

Find nearby doctors — with optional specialty filter
Find nearby pharmacies, labs, and radiology centers
Smart ranking formula: score = distance - rating

Closer AND higher-rated providers rank first

Reviews System

Authenticated patients can post reviews for doctors (POST /reviews)
Rating must be between 1–5
Fetch all reviews for a specific doctor (GET /reviews/:doctorId)

User Management

List all users
Delete user by ID (protected)

Mobile App (Flutter)

Calls all backend endpoints via ApiService
Handles sign-up, login, token persistence, and logout
10-second timeout on all HTTP requests

Additional Modules (inferred from project structure)

Medical Records — storing and retrieving patient medical data
Reminders — medication or appointment reminders
Emergency Profile — critical patient info accessible in emergencies

5. Technologies & Tools
   LayerTechnologyBackend FrameworkNestJS (Node.js + TypeScript)ORMSequelize + sequelize-typescriptDatabasePostgreSQLAuthenticationJWT (@nestjs/jwt), JwtAuthGuardPassword HashingbcryptValidationclass-validator, DTOsTestingJest, ts-jest, SupertestMobile FrontendFlutter (Dart)HTTP Client (Flutter)package:httpLocal Storage (Flutter)shared_preferencesBuild ToolsWebpack, ts-node, TypeScript

6. System Architecture
   Flutter App (Mobile)
   │
   │ HTTP/REST (JSON)
   ▼
   NestJS REST API
   ├── AuthModule → signin, JWT issuing
   ├── UsersModule → register, proximity search, delete
   ├── ReviewsModule → post & fetch doctor reviews
   ├── MedicalRecord → patient records
   ├── Reminders → health reminders
   └── EmergencyProfile→ emergency data
   │
   ▼
   PostgreSQL Database (via Sequelize ORM)

7. Implementation Details
   Smart Proximity Ranking
   tsconst score = distance - user.rating;
   // Lower score = better result (closer + higher rated)
   Results are sorted ascending by score and limited (default: 10).
   JWT Guard Fix
   The original JwtAuthGuard verified the token but never attached the payload to req.user, causing all protected routes to crash when accessing req.user.sub. Fixed by:
   tsconst payload = await this.jwtService.verifyAsync(token);
   (request as any).user = payload;
   Import Path Bugs (Reviews Module)
   All three imports in reviews.module.ts and reviews.controller.ts pointed to a ./dto/ subdirectory that didn't exist:
   FileWrong PathCorrect Pathreviews.controller.ts./dto/reviews.service./reviews.servicereviews.module.ts./dto/review.model./review.modelreviews.module.ts./dto/reviews.service./reviews.servicereviews.module.ts./user.model../users/user.model
   Flutter API Service Fix
   Duplicate name key in signUp request body (first unconditional, then conditional) — the map literal silently dropped one. Fixed to only use the conditional entry:
   dartif (name != null && name.isNotEmpty) 'name': name,

8. Challenges & Solutions
   ChallengeSolutionreq.user was always undefined on protected routesFixed guard to assign verifyAsync payload to request.userReviews module failed to bootstrapCorrected all wrong ./dto/ import pathsDuplicate map key in Flutter sign-up bodyRemoved unconditional name key, kept conditional oneSilent errors in Flutter HTTP callsAdded print() logging inside all catch blocksRanking by distance alone ignores qualityCombined distance and rating into a single score metric

9. Database Models
   User
   FieldTypeNotesidUUIDPrimary key, auto-generatednameTEXTOptionalemailTEXTUnique, requiredpasswordTEXTHashed with bcryptroleENUMpatient / doctor / pharmacy / lab / radiologylatitudeDOUBLEFor proximity searchlongitudeDOUBLEFor proximity searchratingDOUBLEDefault 0, used in smart rankingspecialtyTEXTFor doctors

10. Future Improvements

Add real-time location updates from provider side
Implement pagination for proximity search results
Add push notifications for reminders
Build a rating aggregation system (auto-update User.rating from reviews)
Add role-based route guards (e.g., only patients can post reviews)
Switch from (request as any).user to a proper NestJS custom decorator
Add refresh token support alongside access tokens
Deploy backend to cloud (e.g., Railway, Render, or AWS)

Project Summary: Mobile Health App — Email Verification System

1. Project Overview
   A Flutter-based mobile health application with a NestJS backend, implementing a secure user registration and email verification flow. The project involved refactoring an existing phone verification screen into a fully functional email verification system integrated end-to-end between the mobile client and server.

2. Problem Statement
   The application had a phone verification screen that was non-functional and not connected to any backend logic. The goal was to replace it with a working email verification system that sends a real one-time code to the user's email upon registration, and only allows the user to proceed to login after entering the correct code.

3. Objectives

Replace the phone verification screen with an email verification screen
Generate a secure 6-digit OTP on the backend after successful signup
Send the OTP to the user's registered email automatically
Validate the entered code against the backend before allowing login
Support code resend with a fresh OTP and 10-minute expiry
Integrate everything cleanly into the existing NestJS auth module

4. Features & Functionality
   Registration Flow:

User fills in full name, gender, role, national ID, email, password, and confirm password
Client-side validation for all fields before submission
On successful signup API response, backend is immediately called to send a verification email

Email Verification Screen:

Displays the user's email address for confirmation
6-digit PIN input field using pin_code_fields package
Auto-submits when all 6 digits are entered
Red error highlight on incorrect code
Resend button that calls the backend to generate and email a fresh code
Loading indicators on both Verify and Resend actions
On success → navigates to Login screen

Backend OTP System:

Generates a cryptographically random 6-digit code
Stores code in memory with a 10-minute expiry (Map-based store, Redis-ready)
Sends a styled HTML email via Nodemailer / SMTP
Exposes two REST endpoints:

POST /auth/send-verification — generates and emails the code
POST /auth/verify-code — validates the submitted code

5. Technologies & Tools
   LayerTechnologyMobile frontendFlutter (Dart)Backend frameworkNestJS (Node.js / TypeScript)Email transportNodemailer via @nestjs-modules/mailerSMTP providerGmail (App Password authentication)Auth & tokensJWT (@nestjs/jwt)PIN input UIpin_code_fields Flutter packageEnvironment config.env with dotenv

6. System Architecture & Workflow
   User fills signup form
   ↓
   Flutter validates fields client-side
   ↓
   POST /auth/signup → NestJS AuthService
   ↓
   Success response (id or access_token)
   ↓
   Flutter calls POST /auth/send-verification
   ↓
   NestJS generates 6-digit code → stores with expiry → sends HTML email
   ↓
   Flutter navigates to EmailVerificationScreen
   ↓
   User enters code → Flutter calls POST /auth/verify-code
   ↓
   NestJS checks code & expiry → returns success or error
   ↓
   On success → Flutter navigates to LoginScreen

7. Implementation Details
   Flutter side:

signup_screen.dart — calls ApiService.sendVerificationCode(email) after signup, then pushes EmailVerificationScreen(email: email)
email_verification_screen.dart — stateful widget managing entered code, error state, loading state, and resend state; all verification logic delegated to backend
ApiService — two new methods: sendVerificationCode and verifyCode, both returning Map<String, dynamic> with error handling

NestJS side:

mail.module.ts — configures MailerModule with SMTP credentials from .env
mail.service.ts — sendVerificationCode(email, code) sends styled HTML email
verification.service.ts — manages code generation, in-memory storage with expiry, and validation logic
verification.controller.ts — exposes the two REST endpoints with DTO validation via class-validator
auth.module.ts — updated to import MailModule, and register VerificationService in providers and VerificationController in controllers; fixed incorrect import path from '../mail/' to './verification.service'

8. Challenges & Solutions
   ChallengeSolutionCode was being generated client-side in Flutter, making it insecureMoved code generation entirely to the NestJS backendNo email-sending infrastructure existedBuilt a dedicated MailModule + MailService using @nestjs-modules/mailer and NodemailerVerificationService had a wrong import path in auth.module.tsCorrected path from '../mail/' to './verification.service'VerificationController was missing from the module entirelyAdded to both controllers and ensured VerificationService was in providers

9. Future Improvements

Replace in-memory code storage (Map) with Redis for persistence across server restarts and horizontal scaling
Add rate limiting on /auth/send-verification to prevent email spam abuse
Mark the user's account as email-verified in the database upon successful verification
Add a countdown timer in the Flutter UI showing how long before the code expires
Support alternative SMTP providers (SendGrid, AWS SES) for production reliability

MediBot — Project Summary

1. Project Overview
   Project Title: MediBot — AI-Powered Medical Assistant Application
   Platform: Mobile Application (Flutter / Dart)
   Type: AI-integrated healthcare chatbot with document analysis capabilities
   Summary: MediBot is a mobile medical assistant that enables users to interact with an AI chatbot for health-related queries and upload medical documents — including lab results, X-rays, and prescriptions — for automated AI-powered analysis. The application communicates with a backend AI service and an X-ray analysis model, returning structured medical insights to the user in a conversational interface.

2. Problem Statement
   Patients frequently receive medical documents — lab reports, X-ray images, prescriptions — that they struggle to interpret without professional assistance. Access to doctors is not always immediate, and existing health apps offer limited document understanding. MediBot addresses this gap by providing an intelligent, always-available mobile assistant capable of reading, analyzing, and explaining medical documents in plain language.

3. Objectives

Build a cross-platform mobile chatbot interface for medical Q&A
Allow users to upload medical documents in multiple formats (PDF, image) for AI analysis
Provide specialized analysis pipelines for lab results, X-ray images, and prescriptions
Deliver a smooth, modern, and accessible UX suitable for healthcare contexts
Ensure the interface is production-ready with animations, feedback states, and error handling

4. Features & Functionality
   4.1 Core Chat Features

Real-time text messaging with an AI backend via a REST API
Session-based conversation management using a unique sessionId per session
Long-press to copy any message to clipboard
Expand / collapse for long AI responses ("Show more / Show less") — triggered at 320 characters
Message delivery status indicators: Sending → Sent → Failed (with retry)

4.2 Document Upload & Analysis

Unified attachment flow — single entry point per document type, eliminating split PDF/photo tiles
Three document categories, each routed to a dedicated analysis pipeline:

TypePipelineNotesLab ResultsChatService.sendMessagePDF, photo, or scanX-Ray / ImagingXRayService.analyze()Returns structured toSummary()PrescriptionChatService.sendMessage with fileType: 'prescription'Language-aware via langNotifier

Multi-file upload — users can queue multiple files before sending
File types supported: jpg, jpeg, png, gif, webp, pdf, doc, docx
Per-file thumbnail preview before sending, with remove (×) and retake (camera) options

4.3 UX & Animation Features

Animated message entry — every message fades in and slides up from below (320ms, easeOutCubic)
Typewriter effect — bot responses render character-by-character (3 chars per 18ms tick); skipped for short text ≤40 chars
3-dot typing indicator — staggered bouncing dots animation while AI is generating
Thinking card — contextual card shown during processing (e.g. "🔬 Analyzing your X-ray...") with pulsing fade animation; automatically replaced by the actual response
Send button animation — scale-down-then-back on tap (AnimationController, 150ms)
Thumbnail animation — new attachments appear with easeOutBack scale + fade
Empty state — pulsing placeholder shown before any user message is sent
Smart auto-scroll — automatically scrolls to latest message; pauses if user has manually scrolled up more than 80px; resumes on next send

4.4 Haptic Feedback

HapticFeedback.lightImpact() triggered on:

Sending a message
Picking an image or file for upload

5. Technologies & Frameworks
   LayerTechnologyFrontend / MobileFlutter (Dart)State managementsetState + StatefulWidget (local state)AnimationFlutter AnimationController, TweenSequence, CurvedAnimationImage pickingimage_picker packageFile pickingfile_picker packageHapticsflutter/services.dart — HapticFeedbackAI backendCustom REST API via ChatService (ngrok-tunneled endpoint)X-Ray modelXRayService.analyze() — separate ML inference serviceThemingCustom AppTheme / AppColors with dark mode supportLocalizationcontext.l localization + langNotifier for language-aware API calls

6. System Architecture & Workflow
   User Input (text / file)
   │
   ▼
   \_ChatbotScreenState
   │
   ├─── Text message ──────────────► ChatService.sendMessage()
   │ │
   ├─── Lab Result (image/PDF) ────► ChatService.sendMessage()
   │ │
   ├─── X-Ray (image) ─────────────► XRayService.analyze()
   │ │
   └─── Prescription (image) ──────► ChatService.sendMessage()
   (fileType: 'prescription',
   appLang: langNotifier)
   │
   ▼
   AI Response / Analysis Result
   │
   ▼
   \_Msg added to \_messages list
   │
   ▼
   \_AnimatedMessageEntry → \_Bubble → \_TypewriterText
   Message lifecycle:

User sends → message added with status sending, typing indicator appears
Thinking card inserted (for file uploads) while API call is in-flight
Thinking card replaced by bot response on success
On failure → last user message marked failed, retry callback exposed

7. Implementation Details
   Message Model (\_Msg)

Immutable model with unique id (microsecond timestamp + role suffix)
Types: text, image, file, thinking
Status field: \_MsgStatus { sending, sent, failed }
withStatus() method produces a new instance without mutating state

Animation Architecture

\_AnimatedMessageEntry — wraps every list item; self-contained StatefulWidget with its own AnimationController; forward-only, disposed on widget removal
\_TypewriterText — Timer.periodic at 18ms interval; reveals 3 chars per tick; resets cleanly on text change via didUpdateWidget
\_TypingIndicator — uses TweenSequence with Interval-based stagger (0.0, 0.15, 0.30 delay offsets) on a single repeating controller
\_ThinkingCard — pulsing FadeTransition (0.45→1.0) on a repeating controller
All controllers are disposed in their respective dispose() methods to prevent memory leaks

Scroll Behavior

ScrollController listener computes distance from bottom
If distFromBottom > 80px → \_userScrolledUp = true → auto-scroll suppressed
\_scrollDown(force: true) bypasses the guard (used on explicit send)
Smooth scroll uses animateTo with Curves.easeOutCubic, duration 350ms

Attachment Queue

\_pendingFiles: List<\_PendingFile> holds queued items before send
Each \_PendingFile carries: file, fileName, \_AttachmentType, fromCamera
\_sendPendingFiles() drains the queue sequentially, calling \_handleSend per file

8. UI/UX Design Decisions

Progressive disclosure — attachment picker shows document type first, source (camera/gallery/PDF) second; reduces cognitive load
Thinking card over generic typing indicator — contextual labels ("🔬 Analyzing your X-ray...") set accurate user expectations during potentially long API calls
Typewriter effect — reinforces the perception of AI "thinking" and producing a response in real-time rather than an instantaneous dump of text
Collapse for long messages — keeps the chat readable; threshold set at 320 characters which covers most short-to-medium responses while collapsing verbose ones
Failed state with retry — rather than silently dropping errors, the UI surfaces them inline with a one-tap retry, keeping the user in control

9. Challenges & Solutions
   ChallengeSolutionMultiple redundant pickers for the same document typeUnified into one \_AttachmentType enum with a shared \_showSourcePicker() bottom sheetBoolean flags (isPrescription) making routing fragileReplaced with typed enum + extension methods for color, routing, and labelAuto-scroll fighting user's manual scroll_userScrolledUp flag computed from scroll controller listener; force parameter overrides it on sendTypewriter causing UI jank on long responsesTimer.periodic with 3 chars/tick at 18ms keeps the main thread free; very short texts skip animation entirelyThinking card persisting on error_messages.removeLast() guarded by type check before inserting error messageAnimatedList key collisions across sessionsUnique id using DateTime.now().microsecondsSinceEpoch + role/type suffix

10. Future Improvements

Per-file upload progress — individual progress bars (uploading → processing → success → error) with retry per file rather than per message
Offline queue — buffer failed messages and retry when connectivity is restored
PDF first-page thumbnail — render actual PDF page preview using flutter_pdfview or syncfusion_flutter_pdfviewer instead of a generic icon
Streaming AI responses — switch from full-response to streamed token delivery for a more responsive feel on long answers
Push notifications — notify user when a long analysis (e.g. X-ray) completes if they navigated away
Medical history context — persist session history so the AI can reference prior uploads and conversations across app restarts
Role-based access — separate patient and doctor views with different analysis depth and terminology

MediBot — Project Summary

1. Project Overview
   Project Title: MediBot — AI-Powered Medical Assistant Application
   Platform: Mobile Application (Flutter / Dart)
   Type: AI-integrated healthcare chatbot with document analysis capabilities
   Summary: MediBot is a mobile medical assistant that enables users to interact with an AI chatbot for health-related queries and upload medical documents — including lab results, X-rays, and prescriptions — for automated AI-powered analysis. The application communicates with a backend AI service and an X-ray analysis model, returning structured medical insights to the user in a conversational interface.

2. Problem Statement
   Patients frequently receive medical documents — lab reports, X-ray images, prescriptions — that they struggle to interpret without professional assistance. Access to doctors is not always immediate, and existing health apps offer limited document understanding. MediBot addresses this gap by providing an intelligent, always-available mobile assistant capable of reading, analyzing, and explaining medical documents in plain language.

3. Objectives

Build a cross-platform mobile chatbot interface for medical Q&A
Allow users to upload medical documents in multiple formats (PDF, image) for AI analysis
Provide specialized analysis pipelines for lab results, X-ray images, and prescriptions
Deliver a smooth, modern, and accessible UX suitable for healthcare contexts
Ensure the interface is production-ready with animations, feedback states, and error handling

4. Features & Functionality
   4.1 Core Chat Features

Real-time text messaging with an AI backend via a REST API
Session-based conversation management using a unique sessionId per session
Long-press to copy any message to clipboard
Expand / collapse for long AI responses ("Show more / Show less") — triggered at 320 characters
Message delivery status indicators: Sending → Sent → Failed (with retry)

4.2 Document Upload & Analysis

Unified attachment flow — single entry point per document type, eliminating split PDF/photo tiles
Three document categories, each routed to a dedicated analysis pipeline:

TypePipelineNotesLab ResultsChatService.sendMessagePDF, photo, or scanX-Ray / ImagingXRayService.analyze()Returns structured toSummary()PrescriptionChatService.sendMessage with fileType: 'prescription'Language-aware via langNotifier

Multi-file upload — users can queue multiple files before sending
File types supported: jpg, jpeg, png, gif, webp, pdf, doc, docx
Per-file thumbnail preview before sending, with remove (×) and retake (camera) options

4.3 UX & Animation Features

Animated message entry — every message fades in and slides up from below (320ms, easeOutCubic)
Typewriter effect — bot responses render character-by-character (3 chars per 18ms tick); skipped for short text ≤40 chars
3-dot typing indicator — staggered bouncing dots animation while AI is generating
Thinking card — contextual card shown during processing (e.g. "🔬 Analyzing your X-ray...") with pulsing fade animation; automatically replaced by the actual response
Send button animation — scale-down-then-back on tap (AnimationController, 150ms)
Thumbnail animation — new attachments appear with easeOutBack scale + fade
Empty state — pulsing placeholder shown before any user message is sent
Smart auto-scroll — automatically scrolls to latest message; pauses if user has manually scrolled up more than 80px; resumes on next send

4.4 Haptic Feedback

HapticFeedback.lightImpact() triggered on:

Sending a message
Picking an image or file for upload

5. Technologies & Frameworks
   LayerTechnologyFrontend / MobileFlutter (Dart)State managementsetState + StatefulWidget (local state)AnimationFlutter AnimationController, TweenSequence, CurvedAnimationImage pickingimage_picker packageFile pickingfile_picker packageHapticsflutter/services.dart — HapticFeedbackAI backendCustom REST API via ChatService (ngrok-tunneled endpoint)X-Ray modelXRayService.analyze() — separate ML inference serviceThemingCustom AppTheme / AppColors with dark mode supportLocalizationcontext.l localization + langNotifier for language-aware API calls

6. System Architecture & Workflow
   User Input (text / file)
   │
   ▼
   \_ChatbotScreenState
   │
   ├─── Text message ──────────────► ChatService.sendMessage()
   │ │
   ├─── Lab Result (image/PDF) ────► ChatService.sendMessage()
   │ │
   ├─── X-Ray (image) ─────────────► XRayService.analyze()
   │ │
   └─── Prescription (image) ──────► ChatService.sendMessage()
   (fileType: 'prescription',
   appLang: langNotifier)
   │
   ▼
   AI Response / Analysis Result
   │
   ▼
   \_Msg added to \_messages list
   │
   ▼
   \_AnimatedMessageEntry → \_Bubble → \_TypewriterText
   Message lifecycle:

User sends → message added with status sending, typing indicator appears
Thinking card inserted (for file uploads) while API call is in-flight
Thinking card replaced by bot response on success
On failure → last user message marked failed, retry callback exposed

7. Implementation Details
   Message Model (\_Msg)

Immutable model with unique id (microsecond timestamp + role suffix)
Types: text, image, file, thinking
Status field: \_MsgStatus { sending, sent, failed }
withStatus() method produces a new instance without mutating state

Animation Architecture

\_AnimatedMessageEntry — wraps every list item; self-contained StatefulWidget with its own AnimationController; forward-only, disposed on widget removal
\_TypewriterText — Timer.periodic at 18ms interval; reveals 3 chars per tick; resets cleanly on text change via didUpdateWidget
\_TypingIndicator — uses TweenSequence with Interval-based stagger (0.0, 0.15, 0.30 delay offsets) on a single repeating controller
\_ThinkingCard — pulsing FadeTransition (0.45→1.0) on a repeating controller
All controllers are disposed in their respective dispose() methods to prevent memory leaks

Scroll Behavior

ScrollController listener computes distance from bottom
If distFromBottom > 80px → \_userScrolledUp = true → auto-scroll suppressed
\_scrollDown(force: true) bypasses the guard (used on explicit send)
Smooth scroll uses animateTo with Curves.easeOutCubic, duration 350ms

Attachment Queue

\_pendingFiles: List<\_PendingFile> holds queued items before send
Each \_PendingFile carries: file, fileName, \_AttachmentType, fromCamera
\_sendPendingFiles() drains the queue sequentially, calling \_handleSend per file

8. UI/UX Design Decisions

Progressive disclosure — attachment picker shows document type first, source (camera/gallery/PDF) second; reduces cognitive load
Thinking card over generic typing indicator — contextual labels ("🔬 Analyzing your X-ray...") set accurate user expectations during potentially long API calls
Typewriter effect — reinforces the perception of AI "thinking" and producing a response in real-time rather than an instantaneous dump of text
Collapse for long messages — keeps the chat readable; threshold set at 320 characters which covers most short-to-medium responses while collapsing verbose ones
Failed state with retry — rather than silently dropping errors, the UI surfaces them inline with a one-tap retry, keeping the user in control

9. Challenges & Solutions
   ChallengeSolutionMultiple redundant pickers for the same document typeUnified into one \_AttachmentType enum with a shared \_showSourcePicker() bottom sheetBoolean flags (isPrescription) making routing fragileReplaced with typed enum + extension methods for color, routing, and labelAuto-scroll fighting user's manual scroll_userScrolledUp flag computed from scroll controller listener; force parameter overrides it on sendTypewriter causing UI jank on long responsesTimer.periodic with 3 chars/tick at 18ms keeps the main thread free; very short texts skip animation entirelyThinking card persisting on error_messages.removeLast() guarded by type check before inserting error messageAnimatedList key collisions across sessionsUnique id using DateTime.now().microsecondsSinceEpoch + role/type suffix

10. Future Improvements

Per-file upload progress — individual progress bars (uploading → processing → success → error) with retry per file rather than per message
Offline queue — buffer failed messages and retry when connectivity is restored
PDF first-page thumbnail — render actual PDF page preview using flutter_pdfview or syncfusion_flutter_pdfviewer instead of a generic icon
Streaming AI responses — switch from full-response to streamed token delivery for a more responsive feel on long answers
Push notifications — notify user when a long analysis (e.g. X-ray) completes if they navigated away
Medical history context — persist session history so the AI can reference prior uploads and conversations across app restarts
Role-based access — separate patient and doctor views with different analysis depth and terminology
You updated the Flutter reminder screen with several UX and animation improvements:

Wrapped reminder list items with staggered animations using flutter_staggered_animations
Added animated “Take → Done” button transition:
AnimatedContainer for smooth color transition from primary color to success green
AnimatedSwitcher with ScaleTransition to switch from “Take” text to checkmark icon
Added fade + slide animation for the medicine name when strikethrough appears
Converted the add-reminder bottom sheet to DraggableScrollableSheet
snap points: 0.5 and 1.0
Added smooth list entrance animations using:
AnimationLimiter
AnimationConfiguration.staggeredList
SlideAnimation
FadeInAnimation
Fixed missing animation package/import issues by:
adding flutter_staggered_animations
importing:
package:flutter_staggered_animations/flutter_staggered_animations.dart
Kept support for:
reminder persistence
notification scheduling
taken/eaten toggles
swipe-to-delete
edit-on-long-press
dark/light theme handling

Flutter localization (context.l) cannot be used inside static const because localization values are runtime, not compile-time.

Replace static const collections with methods/functions that receive BuildContext.

Example pattern:

static List<\_Doctor> doctors(BuildContext context) => [ _Doctor(context.l.drYoussef, ...),];

Any widget using context.l must NOT be declared as const.

Keep const only for fully static values like colors/icons when possible.

For CategoryScreen.pharmacy, pass BuildContext into the method:

static CategoryScreen pharmacy(BuildContext context) => ...

Localization keys added/recommended:

appearance

allRecords

labTest

imaging

prescriptions

diagnosis

documentsStored

“Appearance” translations:

German: Erscheinungsbild

French: Apparence

Turkish: Görünüm

Russian: Внешний вид

Spanish: Apariencia

For strings with numbers/counts, use localization placeholders:

Text(context.l.documentsStored(\_records.length))

Main Flutter error cause:

dependOnInheritedWidgetOfExactType<\_LocalizationsScope>()called before initState completed

Root issue:
tabs(context) was called inside initState, which indirectly used context.l.

Problematic code:

\_tabCtrl = TabController(length: tabs(context).length, vsync: this);

Recommended fix:

\_tabCtrl = TabController(length: 5, vsync: this);

Alternative safe solution:
Initialize context-dependent values inside didChangeDependencies() instead of initState().

General rule:

❌ Do not use:

context.l

Theme.of(context)

inherited widgets
inside initState()

✅ Use them inside:

build()

didChangeDependencies()
MediLink — Project Summary

1. Project Title
   MediLink — A Cross-Platform Mobile Health Application

2. Problem Statement
   Patients in Egypt and the broader Arabic-speaking world face difficulties managing their healthcare needs in one place. There is no unified mobile solution that allows users to find nearby doctors and pharmacies, manage medication reminders, store medical records, and communicate with an AI health assistant — all while supporting Arabic language and RTL layout natively.

3. Objectives

Build a fully functional cross-platform mobile health app using Flutter
Connect the app to a real NestJS + PostgreSQL backend with JWT authentication
Support Arabic and English with full RTL/LTR switching
Provide medication reminder management with local push notifications
Allow users to find nearby doctors, pharmacies, labs, and scan centers
Store and display medical records digitally
Integrate an AI chatbot for health assistance

4. Features and Functionality
   Authentication

Sign up with name, email, password, gender, and role (patient, doctor, pharmacy, lab)
Login with JWT token saved to local storage via SharedPreferences
Guest mode — bypass login and go directly to home screen
Forgot password screen
Phone verification screen (UI built, backend not yet connected)
Role-based routing after login via RoleRouter
Form validation: email format, password uppercase + number + symbol rules, national ID 14 digits

Home Screen

Greeting with user name
Search bar for doctors and pharmacies
Category icons: Doctors, Pharmacy, Labs, Scans — each opens a dedicated screen
Upcoming Schedule section showing real reminders from SharedPreferences, sorted by time, with Take button that marks reminder as done
Top Doctors / Top Pharmacy / Labs / Scans section that switches dynamically based on selected category
AI Health Assistant banner linking to chatbot
Floating Action Button (FAB) in bottom nav center opens chatbot

Reminder Tab

Add, edit, delete reminders with full form
Fields: name, type (medicine or doctor), medicine form (tablet, capsule, liquid, injection, drops, inhaler, patch, powder, other), dose (½, 1, 1½, 2, 3), meal relation (before/after/with food/anytime), priority (high/normal/low), color picker, time, repeat days, start and end date
Reminders sorted by priority
Take button marks reminder as done, eaten checkbox for meal tracking
Swipe left to delete, long press to edit
Push notifications via flutter_local_notifications with exact alarm scheduling
Reminders persisted with SharedPreferences

Medical Records Tab

Displays count of stored documents
Placeholder for future document upload (scans, reports, prescriptions)

Menu Tab

Profile card with name and email
AI ChatBot banner with Open button
Navigation items: Near By, My Profile, Settings, Help & Support
Language toggle button (AR / EN)
Dark mode toggle button
Logout button

Chatbot Screen

MediBot AI chat interface
Greeting message on open
Quick reply chips (show records, book appointment, medication schedule, nearby pharmacy)
Keyword-based auto-replies in both Arabic and English
Typing indicator animation
Full dark mode support

Onboarding and Splash

Splash screen with logo and tagline
4-slide onboarding: AI Chat Bot, Near By, Reminder, Medical Records
Smooth page indicator, Next / Get Started buttons

Nearby / Category Screens

All Doctors Screen with full doctor list, ratings, experience, Book button
Category Screen for Pharmacy, Labs, Scan Centers — shows name, distance, hours
All Reminders Screen showing full reminder list with taken/pending status

5. Technologies, Frameworks, and Tools
   Frontend
   ToolPurposeFlutter (Dart)Cross-platform mobile UIshared_preferencesLocal data persistenceflutter_local_notificationsPush notification schedulingflutter_colorpickerColor picker in reminder formtimezone + flutter_timezoneCorrect local timezone for notificationssmooth_page_indicatorOnboarding page dotspin_code_fieldsOTP input screengoogle_fontsTypographyhttpREST API calls to backendflutter_localizations + ARB filesArabic/English localization
   Backend
   ToolPurposeNestJS (Node.js)REST API frameworkPostgreSQLRelational databaseSequelize (sequelize-typescript)ORM for database modelsJWT (@nestjs/jwt)Authentication tokensbcryptPassword hashingclass-validatorDTO validationPassport.jsAuth strategy (JWT guard)

6. System Architecture
   Flutter App
   │
   ├── api_service.dart ──────────► NestJS Backend (port 3000)
   │ │ │
   │ SharedPreferences PostgreSQL Database
   │ (token, reminders) │
   │ ┌───────┴────────┐
   ├── Auth Flow users table (future tables)
   │ signup → /users POST
   │ login → /auth/signin POST
   │ token saved → SessionService
   │ RoleRouter → correct home
   │
   ├── Home Screen
   │ └── reads reminders from SharedPreferences
   │
   └── Reminder Tab
   └── saves to SharedPreferences + schedules notifications
   Backend Endpoints
   MethodURLAuthPurposePOST/usersNoSign upPOST/auth/signinNoLoginGET/usersNoGet all usersGET/users/nearby?lat=X&lng=YNoNearby doctorsDELETE/users/:idYes (JWT)Delete user

7. Implementation Details
   Theme System

Global ValueNotifier<ThemeMode> in app_theme.dart
ThemeX extension adds context.isDark, context.bg, context.card, context.text to every widget
No props passed — any widget rebuilds automatically on theme change
toggleTheme() function accessible globally

Localization System

ARB files for 7 languages: English, Arabic, German, French, Spanish, Russian, Turkish
langNotifier ValueNotifier for live language switching
L10nX extension adds context.l shortcut to every widget
Full RTL layout when Arabic is active — Flutter handles automatically
All date pickers, time pickers, and system widgets switch language

Notification System

Initializes on app start in main()
Sets real device timezone using flutter_timezone
Schedules for tomorrow automatically if reminder time already passed today
Requests exact alarm and notification permissions on Android 13+
Android manifest permissions: POST_NOTIFICATIONS, USE_EXACT_ALARM, VIBRATE, RECEIVE_BOOT_COMPLETED

API Service Pattern

Single api_service.dart file handles all HTTP calls
Token stored and retrieved via SessionService
Authorization: Bearer <token> header added automatically when token exists
10-second timeout on all requests
Error returned as {'error': 'Cannot connect to server'} on exception

8. Challenges and Solutions
   ChallengeSolutionDark mode not applying on all screensReplaced prop-drilling with global ValueNotifier + ThemeX extensioncontext.l used outside build()Moved all translated strings inside build() methodDropdown values breaking on language switchReplaced String values with int index — language-independentflutter_timezone 1.0.8 Kotlin incompatibilityUpgraded to flutter_timezone: ^1.1.0Core library desugaring error on AndroidAdded isCoreLibraryDesugaringEnabled = true and desugar dependency in build.gradle.ktsLogin returning "not found"Backend endpoint was /auth/signin not /auth/loginSignup returning "bad request"Backend has no phone or national_id fields — removed them; role was 'lab' not 'scans'Login success/error checks in wrong orderRewrote \_login() to check access_token first before error branchesNotifications firing at wrong timeFixed by setting tz.local from real device timezone instead of defaulting to UTC

9. Project Structure (Key Files)
   lib/
   ├── main.dart
   ├── core/
   │ ├── theme/app_theme.dart
   │ ├── services/api_service.dart
   │ ├── services/session_service.dart
   │ └── router.dart
   ├── l10n/
   │ ├── app_en.arb
   │ ├── app_ar.arb
   │ └── (de, fr, es, ru, tr)
   ├── models/
   │ └── reminder_model.dart
   ├── services/
   │ └── notification_service.dart
   ├── screens/
   │ ├── auth/
   │ │ ├── login_screen.dart
   │ │ ├── signup_screen.dart
   │ │ ├── forgot_password_screen.dart
   │ │ └── phone_verification_screen.dart
   │ └── home/
   │ ├── home_screen.dart
   │ ├── home_tab.dart
   │ ├── reminder_tab.dart
   │ ├── records_tab.dart
   │ ├── menu_tab.dart
   │ ├── chatbot_screen.dart
   │ ├── add_reminder_sheet.dart
   │ ├── all_reminders_screen.dart
   │ ├── all_doctors_screen.dart
   │ └── category_screen.dart
   └── widgets/
   ├── theme_toggle_button.dart
   └── lang_toggle_button.dart

10. Future Improvements

Connect medical records tab to backend for real document upload and retrieval
Implement real AI chatbot using Anthropic or OpenAI API instead of keyword matching
Add Google Maps integration for the Near By screen using real GPS coordinates
Connect doctor booking system to backend
Add profile screen with edit functionality
Implement phone OTP verification with a real SMS provider (e.g. Twilio)
Add weekly/monthly reminder repeat logic with calendar view
Extend backend with medical records, appointments, and prescriptions tables
Add biometric login (fingerprint / Face ID)
Publish to Google Play Store and Apple App Store

Summary

The user is developing a Flutter-based healthcare mobile app, specifically working on the HomeTab UI screen. The goal was to enhance the UI with smooth animations and better interaction feedback without changing the existing design or structure.

Key Enhancements Implemented
Header Animation
Wrapped the greeting/header section with a custom FadeSlideIn widget.
Adds a subtle fade + slide-in effect on screen load.
Category Buttons (Doctors, Pharmacy, Labs, Scans)
Wrapped each category item with ScaleTap to provide a press animation.
Grouped them using StaggeredList for sequential entrance animations.
Doctor List Animation
Replaced static rendering with StaggeredList.
Each doctor card appears with a delay of 80ms for a smooth staggered effect.
Tap Interaction Feedback
Introduced ScaleTap widget across tappable components.
Adds a slight scale-down effect on press for better UX.
Custom Animation Widgets Added
FadeSlideIn: Handles fade + vertical slide animation with delay.
StaggeredList: Applies staggered animation to a list of widgets.
ScaleTap: Handles tap scaling animation.
Notes & Constraints
The original UI layout and structure were preserved.
Changes were additive (wrappers only), not structural rewrites.
Errors encountered were mainly due to:
Missing custom widgets
Incorrect const usage inside animated lists

🧠 App Overview

You’re building a modern healthcare mobile app for patients using Flutter.
The UI is already strong: clean, minimal, and consistent with a medical design style.

Main sections in your app:

Home dashboard
Medication reminders
Medical records
Emergency card
Nearby doctors
AI chat assistant
✅ Core Improvements to Focus On

1. 🔔 Medication Reminders
   Add mark as taken / skipped
   Add snooze option
   Track adherence (taken vs missed)
2. 📊 Insights & Statistics
   Show:
   Total records
   Stable vs critical cases
   Medication adherence %
   Use simple visualizations (progress bars, stats cards)
3. 📁 Medical Records
   Improve with:
   Attach files (images / PDFs)
   Better filtering & search
   Timeline view (already implemented well)
4. 🚑 Emergency Card
   Add quick actions:
   Call emergency contact
   Share medical info
5. 🗺️ Nearby Doctors
   Add:
   Filters (rating, specialty)
   Quick actions (call / book)
   🎬 Animations (Key Upgrade Area)
6. Navigation
   Smooth fade + slide transitions between screens
   Active tab with scale + color change
7. Cards & Lists
   Staggered animation when loading
   Fade in + slight upward movement
8. Buttons
   Tap feedback:
   Scale down (0.95)
   Ripple effect
9. Reminder Interaction
   When user taps "Take":
   Show checkmark animation
   Change color (e.g., to green)
   Smooth transition
10. Bottom Sheets
    Use draggable bottom sheets with:
    Smooth drag
    Snap positions (collapsed / half / full)
11. Floating Action Button
    Animate expansion into form (Add Record / Add Reminder)
12. Chat UI
    Message bubbles:
    Fade + slide in
    Optional typing indicator
13. Progress & Stats
    Animate progress bars with ease-in-out
    🔴 Important Issue Identified
    You have a layout overflow (BOTTOM OVERFLOWED)
    Fix:
    Use scrollable layout:
    SingleChildScrollView
    or ListView with proper constraints
    wrap with SafeArea
    💡 Key Advice

Your app is already close to production level.

To level it up:

Focus on smooth animations
Ensure no UI bugs (overflow, clipping)
Improve interaction feedback
Keep everything consistent and responsive
🔥 Bottom Line

You don’t need more features right now.

You need:

Better UX polish
Smooth animations
Strong interaction feedback

That’s what will make your app feel premium, not just functional.

Project Summary: MedCare — Healthcare Mobile Application

1. Project Title
   MedCare — A Modern, Patient-Centered Healthcare Mobile Application

2. Project Overview
   MedCare is a comprehensive mobile healthcare application designed for patients to manage their medical life in one place. The app provides a calm, reassuring digital environment where users can track medications, store medical records, locate nearby healthcare services, and consult an AI health assistant — all through a clean, accessible interface optimized for ease of use.

3. Objectives

Build a unified patient-facing mobile app covering daily health management needs
Deliver a calm, trustworthy UX through thoughtful visual design and smooth micro-interactions
Support multilingual and multi-theme accessibility for a broad patient demographic
Integrate an AI-powered chatbot to provide on-demand health guidance
Enable fast, intuitive navigation with minimal learning curve for all age groups

4. Features & Functionality
   🏠 Home Dashboard (home_tab.dart, home_screen.dart)

Personalized greeting with patient name
Quick-access cards: Doctors, Pharmacy, Labs, Scan Centers
Animated health stats with progress bars
Top-rated nearby doctors list with ratings and specialties
Floating AI Chat button (persistent across all tabs)

💊 Medication Reminders (reminder_tab.dart, add_reminder_sheet.dart, all_reminders_screen.dart)

Schedule reminders by medicine name, dosage, form, and time
Medicine forms supported: tablet, capsule, liquid, injection, drops, inhaler, patch, powder, other
Daily progress chip: "X of Y taken today" with animated count-up
"Take → Done ✓" animated state transition per reminder
Persistent storage via SharedPreferences
Bottom sheet for adding new reminders (DraggableScrollableSheet)

📁 Medical Records (records_tab.dart, record_detail_screen.dart, add_record_screen.dart)

Categorized records: Lab Tests, Imaging, Prescriptions, Diagnoses
Animated sliding tab indicator between categories
Add new records with file attachments
Detail view with staggered section reveals

🚨 Emergency Card

Critical patient information: diseases, allergies, active medications
Accessible quickly from home for emergency responders

👨‍⚕️ Nearby Doctors (all_doctors_screen.dart)

List of doctors with name, specialty, rating, review count, and experience
"Book" appointment button per doctor
13 pre-seeded doctors across multiple specialties

🏥 Nearby Services (category_screen.dart)

Categories: Pharmacy, Laboratories, Scan Centers
Each entry shows name, distance, and operating hours
Pre-seeded real-world-style Cairo-based locations

🤖 AI Health Assistant (chatbot_screen.dart)

Chat interface with user and assistant message bubbles
Typing indicator (animated 3-dot wave) while awaiting response
Messages appear with fade + slide animation
Powered by Anthropic Claude API (claude-sonnet-4-20250514)

👤 Profile & Settings (profile_edit_screen.dart, menu_tab.dart)

Editable patient profile (name, email)
Session management via SessionService
Logout with redirect to login screen

🎨 Theme Picker (theme_picker_screen.dart)

Light, Dark, and System Default themes
Live preview cards with mini UI mockup
Persisted via ValueNotifier<ThemeMode> (themeNotifier)

🌐 Language Picker (language_picker_screen.dart)

Supported languages: English, Arabic, French, German, Spanish, Russian, Turkish
RTL support implied for Arabic
Persisted via ValueNotifier<Locale> (langNotifier)
Full localization via AppLocalizations

5. Technologies & Frameworks
   LayerTechnologyFrameworkFlutter (Dart)State ManagementValueNotifier, setStateLocal StorageSharedPreferencesLocalizationAppLocalizations (Flutter l10n)AI BackendAnthropic Claude API (/v1/messages)NavigationFlutter Navigator 2.0 with custom AppPageRouteThemingCustom AppTheme, AppColors, BuildContext extensions

6. System Architecture
   lib/
   ├── core/
   │ ├── theme/ → AppTheme, AppColors, context extensions
   │ ├── services/ → SessionService
   │ └── utils/ → animation_utils.dart ← NEW
   ├── l10n/ → AppLocalizations (7 languages)
   ├── models/ → ReminderModel, UserModel
   └── features/
   ├── auth/ → LoginScreen
   └── home/
   ├── home_screen.dart → Shell + BottomNav + FAB
   ├── home_tab.dart → Dashboard
   ├── reminder_tab.dart → Reminders
   ├── records_tab.dart → Medical records
   ├── menu_tab.dart → Settings & profile
   ├── chatbot_screen.dart → AI assistant
   ├── all_doctors_screen.dart
   ├── all_reminders_screen.dart
   ├── category_screen.dart
   ├── profile_edit_screen.dart
   ├── theme_picker_screen.dart
   └── language_picker_screen.dart

7. Animation System (animation_utils.dart)
   A centralized animation toolkit was designed and implemented as a core utility. It contains 12 reusable animation components:
   Widget / ClassPurposeFadeSlideInFades + slides any widget upward on appearance; supports configurable delay and curveStaggeredListWraps a list of children with staggered FadeSlideIn delays (default 65ms per item)ScaleTapTactile press feedback — scales widget to 0.95 on tap-down, springs back on releaseAnimatedProgressBarFills from 0 → value with easeOutCubic; used for health statsReminderTakeButtonAnimates "Take" → "Done ✓" with color, icon, and text transition (350ms)TypingIndicator3-dot bouncing wave animation for AI chatbot thinking stateChatBubbleMessage bubble with FadeSlideIn; differentiates user vs. assistant visuallyPulsingFABFloating action button with continuous shadow pulse (1800ms cycle)AnimatedCountUpInteger count-up from 0 → target; used for reminder progress chipAppPageRouteApp-wide page transition — soft fade + slight upward slide (300ms)AnimatedTabIndicatorSliding pill tab indicator with animated color and font weight transitionsShimmerLoadingSkeleton shimmer placeholder for loading states
   Animation Design Principles applied:

All durations: 200–400ms (calm, medical-grade UX)
Curves: easeOutCubic for entries, easeInOut for loops
Performance: single AnimationController per widget, properly disposed
No janky rebuilds: AnimatedBuilder used to limit rebuild scope

8. Implementation Plan (Screen-by-Screen)
   Each screen was assigned specific animation upgrades:

home_screen.dart → AnimatedSwitcher for tab switching, AnimatedScale on nav items, PulsingFAB for chat button
home_tab.dart → StaggeredList for cards, AnimatedProgressBar for stats
reminder_tab.dart → ReminderTakeButton for take/done transition, StaggeredList for list
add_reminder_sheet.dart → DraggableScrollableSheet with snap points, staggered form fields
records_tab.dart → AnimatedTabIndicator, AnimatedSwitcher on category switch
chatbot_screen.dart → ChatBubble, TypingIndicator, animated input field
all_doctors_screen.dart → StaggeredList, ScaleTap on cards and Book button
all_reminders_screen.dart → AnimatedCountUp on progress chip
menu_tab.dart → StaggeredList on menu items, ScaleTap on tiles
profile_edit_screen.dart → FadeSlideIn on avatar, staggered form fields
theme_picker_screen.dart → AnimatedContainer selection state
language_picker_screen.dart → AnimatedScale on selection checkmark
category_screen.dart → StaggeredList on location items

9. Design System

Color palette: Soft medical blues (#2196F3 primary), teal accents, white/light-gray backgrounds, success green (#4CAF50)
Typography: Clear hierarchy — bold 24px headers, 15px card titles, 12–13px metadata
Cards: Rounded corners (16px radius), soft shadows in light mode, subtle borders in dark mode
Theming: Full light/dark/system support with isDark context extension throughout
RTL: Supported for Arabic via Flutter's built-in directionality

10. Future Improvements

Real appointment booking integration with doctor availability APIs
Push notifications for medication reminders (via flutter_local_notifications)
Cloud sync for medical records (Firebase / Supabase)MediLink — Project Summary Report

1. Project Overview
   Project Title: MediLink — A Multi-Role Flutter Healthcare Application
   Concept: MediLink is a comprehensive mobile healthcare ecosystem built with Flutter that serves multiple user roles within a single application. The platform connects patients, doctors, pharmacies, and laboratories through a unified, role-aware interface that dynamically adapts its UI, navigation, and permissions based on the authenticated user's role.

2. Problem Statement
   Healthcare services are fragmented across multiple disconnected platforms — patients struggle to coordinate with doctors, pharmacies, and labs separately. There is no unified mobile platform that serves all healthcare stakeholders in one ecosystem with role-based access, AI-assisted diagnosis support, and medical image analysis. MediLink addresses this gap by providing a single app that adapts to each user type dynamically.

3. Objectives

Build a scalable, production-ready Flutter mobile application supporting four distinct user roles
Implement dynamic UI, navigation, and permission control based on the logged-in user's role
Integrate an AI-powered medical chatbot (MediBot) for symptom checking and diagnosis assistance
Integrate a chest X-ray analysis AI model to detect 11 chest diseases from uploaded images
Follow clean architecture principles for maintainability and scalability
Support both Arabic and English languages with theme toggling (dark/light mode)

4. User Roles & Features
   4.1 Patient

Home dashboard with health overview
Medicine and appointment reminder system with local notifications
Medical records management
AI chatbot (MediBot) accessible via floating action button
Chest X-ray upload and AI analysis

4.2 Doctor

Dashboard showing today's patients, pending cases, and urgent cases
Patient list with search functionality
Appointment management (accept / reject / reschedule)
Real-time chat with patients
Profile with logout

4.3 Pharmacy

Dashboard with order statistics and revenue tracking
Order management (pending / delivered / cancelled)
Inventory management
Delivery tracking
Profile with logout

4.4 Labs & Scan Centers

Dashboard with booking statistics and pending results
Booking management
Test management (CBC, Blood Sugar, etc.)
Scan management (X-ray, MRI, etc.)
Result upload (PDF / images)
Profile with logout

5. System Architecture
   5.1 Folder Structure — Clean Architecture
   lib/
   ├── core/
   │ ├── theme/ (app_theme.dart, RoleTheme)
   │ ├── services/ (api_service, notification_service,
   │ │ session_service, api_ai)
   │ ├── widgets/ (theme_toggle, lang_toggle)
   │ └── router.dart (RoleRouter)
   ├── features/
   │ ├── auth/
   │ │ ├── models/ (user_model.dart)
   │ │ └── screens/ (splash, welcome, login, signup, onboarding)
   │ ├── patient/screens/
   │ ├── doctor/screens/
   │ ├── pharmacy/screens/
   │ └── labs/screens/
   └── main.dart
   5.2 Role Detection & Routing Flow
   App Start
   ↓
   SessionService.load()
   ↓
   SplashScreen
   ↓
   isLoggedIn? ──Yes──→ RoleRouter → Doctor / Pharmacy / Labs / Patient
   ↓ No
   OnboardingScreen → WelcomeScreen → Login
   ↓
   Backend returns { id, name, role, access_token }
   ↓
   UserModel.fromJson() → SessionService.save() → RoleRouter
   5.3 Role-Based Theme Colors
   RoleColorPatientBlue (AppColors.primary)DoctorGreen (#2E7D32)PharmacyPurple (#6A1B9A)LabsOrange (#E65100)

6. Technologies & Tools
   CategoryTechnologyMobile FrameworkFlutter (Dart)State/SessionSessionService (SharedPreferences)REST APIhttp package, MultipartRequestLocal Notificationsflutter_local_notificationsImage Handlingimage_pickerBackend (Auth/Data)Custom REST API at configurable base URLAI Chatbot BackendPython server via ngrok (MultipartRequest/POST)X-Ray API BackendDart shelf server (shelf, shelf_router, shelf_multipart)AI ModelEfficientNet-B4 (PyTorch .pth, 203MB)Image PreprocessingDart image package (resize + ImageNet normalization)LocalizationFlutter l10n (Arabic + English)

7. AI & ML Components
   7.1 MediBot — AI Medical Chatbot

Backend: Python-based server exposed via ngrok
Endpoint: POST /chat (MultipartRequest with message + session_id + optional file)
Response model: ChatResponse containing response text, detected intent, language, symptoms list, session ID, and optional diagnosis object
Diagnosis model: Contains diagnosis name, probability, and reasoning
Integration: ChatService in api_ai.dart handles all communication; chatbot screen maintains full conversation history and typing indicator UI

7.2 Chest X-Ray Analysis — EfficientNet-B4 Model

Model: best_bal_efficientnet_b4_model.pth — PyTorch EfficientNet-B4, 203MB, trained on chest X-ray data
Input size: 380×380 pixels, CHW format, ImageNet normalization (mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
Output: Sigmoid probabilities for 11 disease classes
Disease classes detected:

Atelectasis, Cardiomegaly, Consolidation, Effusion, Emphysema, Infiltration, Mass, No Finding, Nodule, Pleural Thickening, Pneumothorax

Default threshold: 0.5 (configurable via query parameter)
API Server: Dart shelf-based HTTP server (x_ray_api.dart) running on port 8000
Endpoints:

GET /health — model status check
POST /predict — full prediction (requires API key)
POST /analyze — alias of /predict, used by the Flutter chatbot

7.3 X-Ray API Security

API key authentication via X-API-Key header
CORS middleware supporting configurable allowed origins
File size limit: 20MB
Supported formats: JPEG, PNG, WebP
Error handling: 400 (bad input), 401 (auth), 413 (too large), 415 (wrong type), 422 (bad threshold), 500 (inference failure), 503 (model not loaded)

8. Key Implementation Details
   8.1 Session Persistence
   SessionService uses SharedPreferences to persist the logged-in user across app restarts. On app launch, main() calls SessionService.load() before runApp(), enabling the splash screen to route directly to the correct role screen without re-login.
   8.2 UserModel & Role Parsing
   dartenum UserRole { patient, doctor, pharmacy, labs }
   // Backend string "doctor" → UserRole.doctor
   // Backend string "pharmacy" → UserRole.pharmacy
   // Backend string "labs" or "scans" → UserRole.labs
   // Anything else → UserRole.patient (safe default)
   8.3 Chatbot X-Ray Integration
   The chatbot screen has two image sending modes:

📎 Attach button → sends image to MediBot AI (ChatService) for general medical discussion
🔬 X-Ray button (orange, Icons.biotech_rounded) → activates \_xrayMode = true → sends image to XRayService.analyze() → displays formatted disease results in the chat bubble

XRayResult.toSummary() formats the API response into a human-readable chat message showing detected diseases with confidence percentages and a disclaimer to consult a doctor.
8.4 Notification System
NotificationService uses flutter_local_notifications with timezone-aware scheduling. Supports medicine reminders and doctor appointment alerts with exact alarm scheduling on Android.

9. Bugs Fixed During Development
   BugLocationFixDuplicate \_error function namex_ray_api.dartRenamed logging version to \_logErrorMalformed 422 response linex_ray_api.dartFixed extra whitespace and argument formattingNo error handling on inferencex_ray_api.dartWrapped runInference() in try/catch, returns HTTP 500Missing /analyze routex_ray_api.dartAdded as alias of /predict for chatbot useBroken import paths after restructureAll screensUpdated to package:medilink/... absolute importsLogin not saving role to sessionlogin_screen.dartReplaced saveToken() with SessionService.save(UserModel)

10. Configuration Reference
    SettingLocationValue to UpdateMain backend URLapi_service.darthttp://YOUR_PC_IP:3000X-Ray server URLapi_ai.dart → XRayServicehttp://YOUR_PC_IP:8000Chatbot server URLapi_ai.dart → ChatServicengrok URLX-Ray API keyapi_ai.dart → XRayServiceMust match kApiKeys in x_ray_api.dart

11. Future Improvements

Replace X-ray model stub inference with real PyTorch/ONNX/TFLite runtime
Add real-time chat using WebSockets for doctor-patient messaging
Implement medicine alternative suggestion feature
Add role switching (users with multiple roles)
Add Labs results analytics dashboard with charts
Implement patient permission system (controlling who sees their data)
Deploy X-ray API server with GPU support for faster inference
Add PDF report generation for X-ray analysis results
Biometric authentication (fingerprint/Face ID) for record access
Emergency card QR code generation for first responders
Wearable device integration (heart rate, steps) on the home dashboard
Actual geolocation for nearby pharmacies, labs, and scan centers (Google Maps API)
Expanded AI chatbot with medical knowledge base and symptom checker
MediLink — Project Summary Report

1. Project Overview
   Project Title: MediLink — A Multi-Role Flutter Healthcare Application
   Concept: MediLink is a comprehensive mobile healthcare ecosystem built with Flutter that serves multiple user roles within a single application. The platform connects patients, doctors, pharmacies, and laboratories through a unified, role-aware interface that dynamically adapts its UI, navigation, and permissions based on the authenticated user's role.

2. Problem Statement
   Healthcare services are fragmented across multiple disconnected platforms — patients struggle to coordinate with doctors, pharmacies, and labs separately. There is no unified mobile platform that serves all healthcare stakeholders in one ecosystem with role-based access, AI-assisted diagnosis support, and medical image analysis. MediLink addresses this gap by providing a single app that adapts to each user type dynamically.

3. Objectives

Build a scalable, production-ready Flutter mobile application supporting four distinct user roles
Implement dynamic UI, navigation, and permission control based on the logged-in user's role
Integrate an AI-powered medical chatbot (MediBot) for symptom checking and diagnosis assistance
Integrate a chest X-ray analysis AI model to detect 11 chest diseases from uploaded images
Follow clean architecture principles for maintainability and scalability
Support both Arabic and English languages with theme toggling (dark/light mode)

4. User Roles & Features
   4.1 Patient

Home dashboard with health overview
Medicine and appointment reminder system with local notifications
Medical records management
AI chatbot (MediBot) accessible via floating action button
Chest X-ray upload and AI analysis

4.2 Doctor

Dashboard showing today's patients, pending cases, and urgent cases
Patient list with search functionality
Appointment management (accept / reject / reschedule)
Real-time chat with patients
Profile with logout

4.3 Pharmacy

Dashboard with order statistics and revenue tracking
Order management (pending / delivered / cancelled)
Inventory management
Delivery tracking
Profile with logout

4.4 Labs & Scan Centers

Dashboard with booking statistics and pending results
Booking management
Test management (CBC, Blood Sugar, etc.)
Scan management (X-ray, MRI, etc.)
Result upload (PDF / images)
Profile with logout

5. System Architecture
   5.1 Folder Structure — Clean Architecture
   lib/
   ├── core/
   │ ├── theme/ (app_theme.dart, RoleTheme)
   │ ├── services/ (api_service, notification_service,
   │ │ session_service, api_ai)
   │ ├── widgets/ (theme_toggle, lang_toggle)
   │ └── router.dart (RoleRouter)
   ├── features/
   │ ├── auth/
   │ │ ├── models/ (user_model.dart)
   │ │ └── screens/ (splash, welcome, login, signup, onboarding)
   │ ├── patient/screens/
   │ ├── doctor/screens/
   │ ├── pharmacy/screens/
   │ └── labs/screens/
   └── main.dart
   5.2 Role Detection & Routing Flow
   App Start
   ↓
   SessionService.load()
   ↓
   SplashScreen
   ↓
   isLoggedIn? ──Yes──→ RoleRouter → Doctor / Pharmacy / Labs / Patient
   ↓ No
   OnboardingScreen → WelcomeScreen → Login
   ↓
   Backend returns { id, name, role, access_token }
   ↓
   UserModel.fromJson() → SessionService.save() → RoleRouter
   5.3 Role-Based Theme Colors
   RoleColorPatientBlue (AppColors.primary)DoctorGreen (#2E7D32)PharmacyPurple (#6A1B9A)LabsOrange (#E65100)

6. Technologies & Tools
   CategoryTechnologyMobile FrameworkFlutter (Dart)State/SessionSessionService (SharedPreferences)REST APIhttp package, MultipartRequestLocal Notificationsflutter_local_notificationsImage Handlingimage_pickerBackend (Auth/Data)Custom REST API at configurable base URLAI Chatbot BackendPython server via ngrok (MultipartRequest/POST)X-Ray API BackendDart shelf server (shelf, shelf_router, shelf_multipart)AI ModelEfficientNet-B4 (PyTorch .pth, 203MB)Image PreprocessingDart image package (resize + ImageNet normalization)LocalizationFlutter l10n (Arabic + English)

7. AI & ML Components
   7.1 MediBot — AI Medical Chatbot

Backend: Python-based server exposed via ngrok
Endpoint: POST /chat (MultipartRequest with message + session_id + optional file)
Response model: ChatResponse containing response text, detected intent, language, symptoms list, session ID, and optional diagnosis object
Diagnosis model: Contains diagnosis name, probability, and reasoning
Integration: ChatService in api_ai.dart handles all communication; chatbot screen maintains full conversation history and typing indicator UI

7.2 Chest X-Ray Analysis — EfficientNet-B4 Model

Model: best_bal_efficientnet_b4_model.pth — PyTorch EfficientNet-B4, 203MB, trained on chest X-ray data
Input size: 380×380 pixels, CHW format, ImageNet normalization (mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
Output: Sigmoid probabilities for 11 disease classes
Disease classes detected:

Atelectasis, Cardiomegaly, Consolidation, Effusion, Emphysema, Infiltration, Mass, No Finding, Nodule, Pleural Thickening, Pneumothorax

Default threshold: 0.5 (configurable via query parameter)
API Server: Dart shelf-based HTTP server (x_ray_api.dart) running on port 8000
Endpoints:

GET /health — model status check
POST /predict — full prediction (requires API key)
POST /analyze — alias of /predict, used by the Flutter chatbot

7.3 X-Ray API Security

API key authentication via X-API-Key header
CORS middleware supporting configurable allowed origins
File size limit: 20MB
Supported formats: JPEG, PNG, WebP
Error handling: 400 (bad input), 401 (auth), 413 (too large), 415 (wrong type), 422 (bad threshold), 500 (inference failure), 503 (model not loaded)

8. Key Implementation Details
   8.1 Session Persistence
   SessionService uses SharedPreferences to persist the logged-in user across app restarts. On app launch, main() calls SessionService.load() before runApp(), enabling the splash screen to route directly to the correct role screen without re-login.
   8.2 UserModel & Role Parsing
   dartenum UserRole { patient, doctor, pharmacy, labs }
   // Backend string "doctor" → UserRole.doctor
   // Backend string "pharmacy" → UserRole.pharmacy
   // Backend string "labs" or "scans" → UserRole.labs
   // Anything else → UserRole.patient (safe default)
   8.3 Chatbot X-Ray Integration
   The chatbot screen has two image sending modes:

📎 Attach button → sends image to MediBot AI (ChatService) for general medical discussion
🔬 X-Ray button (orange, Icons.biotech_rounded) → activates \_xrayMode = true → sends image to XRayService.analyze() → displays formatted disease results in the chat bubble

XRayResult.toSummary() formats the API response into a human-readable chat message showing detected diseases with confidence percentages and a disclaimer to consult a doctor.
8.4 Notification System
NotificationService uses flutter_local_notifications with timezone-aware scheduling. Supports medicine reminders and doctor appointment alerts with exact alarm scheduling on Android.

9. Bugs Fixed During Development
   BugLocationFixDuplicate \_error function namex_ray_api.dartRenamed logging version to \_logErrorMalformed 422 response linex_ray_api.dartFixed extra whitespace and argument formattingNo error handling on inferencex_ray_api.dartWrapped runInference() in try/catch, returns HTTP 500Missing /analyze routex_ray_api.dartAdded as alias of /predict for chatbot useBroken import paths after restructureAll screensUpdated to package:medilink/... absolute importsLogin not saving role to sessionlogin_screen.dartReplaced saveToken() with SessionService.save(UserModel)

10. Configuration Reference
    SettingLocationValue to UpdateMain backend URLapi_service.darthttp://YOUR_PC_IP:3000X-Ray server URLapi_ai.dart → XRayServicehttp://YOUR_PC_IP:8000Chatbot server URLapi_ai.dart → ChatServicengrok URLX-Ray API keyapi_ai.dart → XRayServiceMust match kApiKeys in x_ray_api.dart

11. Future Improvements

Replace X-ray model stub inference with real PyTorch/ONNX/TFLite runtime
Add real-time chat using WebSockets for doctor-patient messaging
Implement medicine alternative suggestion feature
Add role switching (users with multiple roles)
Add Labs results analytics dashboard with charts
Implement patient permission system (controlling who sees their data)
Deploy X-ray API server with GPU support for faster inference
Add PDF report generation for X-ray analysis results

Looking at the conversation, there is only one exchange in this entire chat — you uploaded a Flutter signup screen file and asked to remove the phone number page, which I did.
There is no broader project discussion to summarize. Here's what can be extracted from this single interaction:

Project Summary
Project Title
Mobile Application with User Authentication (Flutter)
Technology & Framework

Flutter (Dart) — cross-platform mobile development
Material Design components

Feature Discussed: User Registration (Signup Screen)
The project includes a multi-role signup flow with the following fields:

Full name, Gender (dropdown), Role/Job type (dropdown)
National ID (14-digit, numeric only)
Email, Password (with strength validation), Confirm password

User Roles Supported
patient, doctor, pharmacy, scans
Validation Logic

Name: required
National ID: required, exactly 14 digits
Email: must contain @ and .
Password: must start with uppercase, contain a number and a special character
Confirm password: must match password

API Integration

Calls ApiService.signUp() with name, email, password, and role
Handles success (redirects to login), connection errors, and server-side errors (e.g. duplicate email)

Change Made in This Session

Removed the second step (phone number entry page)
Converted from a 2-step flow to a single-page signup form
Sign Up button now validates and submits directly from the profile form
