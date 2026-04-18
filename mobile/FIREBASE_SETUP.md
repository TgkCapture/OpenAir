# Firebase Setup (Required before running the app)

## Steps

1. Go to https://console.firebase.google.com
2. Create a new project called "openair-dev"
3. Add an Android app:
   - Package name: `com.tgkcapture.openair`
   - Download `google-services.json`
   - Place it at: `mobile/android/app/google-services.json`
4. Add an iOS app:
   - Bundle ID: `com.tgkcapture.openair`
   - Download `GoogleService-Info.plist`
   - Place it at: `mobile/ios/Runner/GoogleService-Info.plist`
5. Enable Cloud Messaging in Firebase Console

## After placing the files

```bash
cd mobile
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Note
These files are in `.gitignore` — every developer must set up their own Firebase project for development. Production Firebase credentials are managed by the project maintainer.