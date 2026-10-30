# Night Match redesign progress

Checklist of every Dart file currently under `Frontend/lib/Views`. Check an item only after reviewing and completing its UI pass.

## A. Splash, onboarding, and authentication
- [x] `lib/Views/SplashOnboarding/splash.dart`
- [x] `lib/Views/SplashOnboarding/onboarding.dart`
- [x] `lib/Views/Auth/login_page.dart`
- [x] `lib/Views/Auth/sign_up_page.dart`
- [x] `lib/Views/Auth/forgot_password_page.dart` (reset flow is handled here, if present)
- [x] `lib/Views/Admin/admin_login.dart`

## B. Player discovery and booking
- [x] `lib/Views/Player/home.dart`
- [x] `lib/Views/Player/explore.dart`
- [x] `lib/Views/Player/court_detail.dart`
- [x] `lib/Views/Player/court_booking_page.dart`

## C. Player social and account
- [ ] `lib/Views/Player/matches_page.dart`
- [ ] `lib/Views/Player/chat.dart`
- [ ] `lib/Views/Player/ai_assistant.dart`
- [ ] `lib/Views/Player/HomeSettings.dart`
- [ ] `lib/Views/Player/navigation.dart`

## D. Manager
- [ ] `lib/Views/Manager/dashboard.dart`
- [ ] `lib/Views/Manager/venue_page.dart`
- [ ] `lib/Views/Manager/bookings.dart`
- [ ] `lib/Views/Manager/messages.dart`
- [ ] `lib/Views/Manager/manager_profile_page.dart`
- [ ] `lib/Views/Manager/manager_navigation.dart`
- [ ] `lib/Views/Manager/tournaments.dart`

## E. Worker
- [ ] `lib/Views/Worker/worker_home_page.dart`
- [ ] `lib/Views/Worker/worker_courts_page.dart`
- [ ] `lib/Views/Worker/worker_court_detail_page.dart`
- [ ] `lib/Views/Worker/worker_reservations_page.dart`
- [ ] `lib/Views/Worker/worker_upcoming_page.dart`
- [ ] `lib/Views/Worker/worker_chat_page.dart`
- [ ] `lib/Views/Worker/worker_profile_page.dart`
- [ ] `lib/Views/Worker/worker_navigation.dart`

## F. Admin
- [ ] `lib/Views/Admin/admindashboard.dart`

## G. Final sweep
- [ ] `lib/Views/Dialogs, sheets, feedback, and pickers` (shared UI used by the views above)
- [ ] Debug/design preview updated

## Follow-up surfaces not currently represented by a dedicated Views file
- [ ] Notifications sheet (embedded as `_NotificationSheet` in `lib/Views/Player/matches_page.dart`; include in Group C)
- [ ] Booking hold countdown is not supported by the current reservation service; TODO is recorded beside the booking bar.
