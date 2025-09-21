# Firebase setup for VIKASA (mobile first)

1) Create a Firebase project and apps
- Android appId (applicationId): com.vikasa.app
- iOS bundle id: com.vikasa.app
- (Optional) Web app if you want web push later

2) Download config files
- Android: google-services.json → place at vikasa_app/android/app/google-services.json
- iOS: GoogleService-Info.plist → place at vikasa_app/ios/Runner/GoogleService-Info.plist

3) Generate firebase_options.dart (recommended)
- Install FlutterFire CLI:
  npm i -g firebase-tools
  dart pub global activate flutterfire_cli
- Login and configure:
  firebase login
  flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID> --platforms=android,ios,web --out=lib/firebase/firebase_options.dart --yes

4) Notifications permissions
- Android 13+: POST_NOTIFICATIONS permission added in AndroidManifest.xml
- iOS: enable Push capability and APNs key/cert in Apple Developer portal, then link to Firebase project

5) Web push (later)
- Add proper firebase-messaging-sw.js with initialized Firebase app and messaging (current file is a placeholder)
- Set DefaultFirebaseOptions.webConfigured = true in lib/firebase/firebase_options.dart (auto-generated usually)

6) Testing
- Run app and approve notification permission prompt
- In logs, you should see an FCM token printed. Use it to send a test message from Firebase console.

Notes
- Never commit real secrets; config files contain identifiers, not secrets, but treat them cautiously.
- Push tokens should be stored server-side (Supabase push_tokens table) — to be implemented.
