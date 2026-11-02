# Calley – Flutter Machine Test

Flutter app for the C S Tech Infosolutions machine test, built from the Get Calley Figma design and integrated with the Calley mock REST API.

## Screens
1. **Choose Your Language** – 9 languages, saved locally
2. **Register** – name, email, password, +91 mobile, T&C → `POST /api/auth/register`, then `POST /api/auth/send-otp`
3. **Email OTP Verification** – 6 auto-advancing boxes, 30s resend timer → `POST /api/auth/verify-otp`
4. **Login** – `POST /api/auth/login`, session persisted
5. **Getting Started** – video banner, WhatsApp support, Start Calling Now
6. **Dashboard** – list selector, animated donut (Pending / Done / Schedule), stat cards → `GET /api/list?userId=` and `GET /api/list/{listId}`
7. **Side drawer** – profile, app language, help, app info, logout with confirm
8. **Calling list** – All / Pending / Done / Scheduled tabs, tap to dial, call feedback sheet

## Tech
- Flutter 3.47 / Dart 3.13
- `http`, `shared_preferences`, `url_launcher`
- Donut chart drawn with `CustomPainter` (no chart package)

```
lib/
  core/      api.dart, session.dart, theme.dart
  screens/   language, register, otp, login, dashboard, app_drawer, calls
  widgets/   common.dart
```

## Run
```bash
flutter pub get
flutter run
flutter build apk --debug   # build/app/outputs/flutter-apk/app-debug.apk
```

Base URL: `https://mock-api.calleyacd.com` (change in `lib/core/api.dart`).
"# Calley_App" 
