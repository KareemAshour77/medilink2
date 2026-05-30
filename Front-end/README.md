# MediLink Flutter App
**Your Link to Doctors** — Optimized for iPhone 14 Pro + VS Code

---

## ⚡ Quick Start (VS Code)

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Open iOS Simulator — iPhone 14 Pro
```bash
open -a Simulator
```
Then in Simulator: **File → Open Simulator → iOS 17 → iPhone 14 Pro**

### 3. Run from VS Code
- Press **F5** → Select **"MediLink – iPhone 14 Pro"**
- Or use the Terminal:
```bash
flutter run -d 'iPhone 14 Pro'
```

### Hot Reload / Restart
| Action | Shortcut |
|---|---|
| Hot Reload | `r` in terminal |
| Hot Restart | `R` in terminal |
| Stop | `q` in terminal |

---

## 📱 iPhone 14 Pro Specifics

| Property | Value |
|---|---|
| Logical resolution | 393 × 852 pt |
| Physical resolution | 1179 × 2556 px |
| Scale factor | @3x |
| Top safe area | ~59pt (Dynamic Island) |
| Bottom safe area | ~34pt (Home Indicator) |

The app handles all of the above automatically:
- `SystemUiMode.edgeToEdge` renders behind Dynamic Island
- `SafeArea` widgets on every screen keep content clear of notch and home bar
- `TextScaler.noScaling` keeps layout pixel-perfect regardless of accessibility settings

---

## 📁 Project Structure

```
medilink/
├── .vscode/
│   ├── launch.json       ← F5 run config for iPhone 14 Pro
│   ├── settings.json     ← Dart/Flutter editor settings
│   ├── tasks.json        ← Build tasks (Cmd+Shift+B)
│   └── extensions.json   ← Recommended extensions
├── lib/
│   ├── main.dart
│   ├── theme/
│   │   └── app_theme.dart     ← Colors, fonts, sizing constants
│   └── screens/
│       ├── splash_screen.dart
│       ├── onboarding/
│       │   └── onboarding_screen.dart
│       ├── auth/
│       │   ├── welcome_screen.dart
│       │   ├── signup_screen.dart
│       │   ├── login_screen.dart
│       │   ├── phone_verification_screen.dart
│       │   └── forgot_password_screen.dart
│       └── home/
│           ├── home_screen.dart      ← Bottom nav shell
│           ├── home_tab.dart
│           ├── reminder_tab.dart
│           ├── records_tab.dart
│           └── menu_tab.dart
└── pubspec.yaml
```

---

## 🎨 Design System

**Primary:** `#2BB5E0` | **Font:** Poppins | **H-Padding:** 24pt | **Card radius:** 16pt | **Button height:** 56pt

Supports **Light ☀️** and **Dark 🌙** mode — toggle on every screen.

---

## 🛠 Troubleshooting

**Simulator not showing iPhone 14 Pro?**
```bash
xcrun simctl list devices | grep "iPhone 14 Pro"
```
If missing: Xcode → Settings → Platforms → iOS 17 → install

**flutter command not found?** Add to `~/.zshrc`:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

**Dependency errors?**
```bash
flutter clean && flutter pub get
```
