# Nurse Companion (Flutter)

A mobile app for Sri Lankan nurses that covers:

- the shift check-in → check-out → OT workflow
- roster import, by photo (OCR) or manual entry
- leave and OT tracking
- salary forecasts
- workload and burnout insights

It talks to the `sl-nurse-api` backend.

## Run it

```bash
flutter pub get

# Against a local sl-nurse-api (default http://localhost:4000; Android emulator uses 10.0.2.2)
flutter run

# Against another server
flutter run --dart-define=API_BASE_URL=https://api.example.lk

# Demo mode: no backend, sample data, any login works
flutter run --dart-define=DEMO_MODE=true
```

For Flutter web against a local API, add the web origin to the API's `CORS_ORIGINS`.

On web, `?tab=0..3` opens a tab directly.

## Tests

```bash
flutter test                                              # API client, models, view models, every screen at 320/390/820 px, main flows
API_BASE_URL=http://localhost:4000 flutter test test_live/  # contract test against a running sl-nurse-api
```

## Structure

```
lib/
├── main.dart                  # wiring: API vs demo backend, AuthGate (welcome ⇄ app)
├── core/
│   ├── config.dart            # API_BASE_URL / DEMO_MODE dart-defines
│   ├── app_scope.dart         # AppScope (DI), AuthController, DataSync (reload after writes)
│   ├── network/               # ApiClient (envelope, errors, token refresh), secure token store
│   ├── theme/                 # pastel palette, theme, spacing
│   ├── charts/                # SmoothLineChart, ProgressRing, StackedCapsuleBars (CustomPainter)
│   └── widgets/               # PastelCard, MetricPill, FloatingNavBar, AsyncView, TextPromptDialog …
├── data/
│   ├── models.dart            # models mirroring the API JSON
│   ├── repository.dart        # NurseRepository + AuthService interfaces
│   ├── api_repository.dart    # sl-nurse-api implementation
│   └── mock_repository.dart   # in-memory demo backend (supports writes)
└── features/
    ├── auth/                  # Welcome, Login, Register
    ├── shell/                 # tabs, floating dock, side menu
    ├── dashboard/             # salary hero, today's shift workflow, quick actions (+ dashboard_vm)
    ├── duty/                  # date carousel, completion, weekly hours, leave (+ duty_vm)
    ├── shifts/                # shift actions / add-shift bottom sheets
    ├── roster/                # OCR scan → review → save; manual month editor
    ├── analytics/             # forecast, OT outlook, payslip preview, workload & burnout
    └── profile/               # personal + pay settings, allowances/deductions, sign out
```

## API endpoints used

| Feature | Endpoint |
|---|---|
| Sign in / up / out, session refresh | `POST /auth/login`, `/auth/register`, `/auth/logout`, `/auth/refresh` |
| Profile and pay settings | `GET` / `PATCH /auth/me`, `GET` / `PUT /salary/config` |
| Shifts and workflow | `GET /shifts`, `POST /shifts`, `POST /shifts/bulk`, `PUT /shifts/:id` (`CHECK_IN`, `CHECK_OUT`, `SWITCH_TO_OT`, `END_OT`), `DELETE /shifts/:id` |
| Roster OCR | `POST /roster/scan`: a photo, or `rawText` from on-device OCR / paste |
| Analytics | `GET /analytics/predict-salary`, `GET /analytics/work-trends` |

## Notes

- **Session:** tokens are stored securely (Keychain / Keystore / WebCrypto). An expired access token is refreshed automatically once. If the refresh fails, the app returns to the welcome screen and explains why.
- **Keeping screens in sync:** after any change (check-in, leave toggle, roster import, settings), every open screen reloads, so the dashboard, duty, analytics and profile screens stay consistent.
- **Leave entitlements:** the Casual (14 days) and Sick (21 days) totals live in `LeavePolicy` (`features/duty/duty_vm.dart`). Adjust them for your institution.
- **Platform setup:**
  - Android declares `INTERNET` and allows plain HTTP only to local development hosts (`res/xml/network_security_config.xml`).
  - iOS has camera and photo-library usage descriptions, and `NSAllowsLocalNetworking` for local development.
  - Production should use HTTPS.
- **Font:** Plus Jakarta Sans is bundled under the SIL OFL (`assets/fonts/OFL.txt`).
