# VIKASA Network – Monorepo

Structure
- vikasa_app/         # Flutter app (Android/iOS/Web)
- infra/
  - migrations/       # Supabase SQL migrations
  - edge_functions/   # Supabase Edge Functions (to be added)
- appsmith/           # Admin app exports/config
- .env.example        # Environment variables template (do not commit real keys)

Quick start
1) Flutter app
- Install Flutter and run:
  - flutter pub get (inside vikasa_app)
  - flutter run

2) Supabase (manual project setup)
- Create Supabase project and configure Auth (email/password)
- Apply SQL: infra/migrations/0001_create_schema.sql
- Set SMTP for password reset emails

3) Firebase / FCM
- Create Firebase project and enable Cloud Messaging
- Add google-services.json (Android) and GoogleService-Info.plist (iOS)
- Web config to be added later

4) Ads (mobile only)
- Create AdMob app and rewarded ad units
- Wire into vikasa_app (mobile). Web claims disabled initially.

5) Admin (Appsmith)
- Deploy Appsmith (cloud or Docker)
- Connect to Supabase as datasource
- Build pages: Dashboard, Users, Claims, Withdrawals, Config, Announcements, Burns, Audit Logs

Rules
- Show all currency values with >= 8 decimals (no rounding). Use Decimal/fixed-point.
- DB numeric(38,18) or higher; never float.
- Server authoritative on timing/locks/withdrawals.
- No Color.withOpacity; use Color.withValues() for alpha in Flutter.
