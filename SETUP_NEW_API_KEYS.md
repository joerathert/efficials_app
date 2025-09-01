# Firebase API Key Setup Instructions

## Step 1: Create New API Keys

1. Go to [Google Cloud Console - API Credentials](https://console.cloud.google.com/apis/credentials?project=efficials-app)

2. Click "Create Credentials" → "API Key" and create **4 separate keys**:
   - Web API Key
   - Android API Key  
   - iOS API Key
   - Windows API Key

## Step 2: Restrict API Keys (IMPORTANT FOR SECURITY)

For each key, click the edit icon (pencil) and set restrictions:

### Web API Key:
- Application restrictions: HTTP referrers (web sites)
- Add your web domains (e.g., `*.firebaseapp.com/*`, `localhost:*`)

### Android API Key:
- Application restrictions: Android apps
- Add package name: `com.example.efficials_app`

### iOS API Key:
- Application restrictions: iOS apps  
- Add bundle identifier: `com.example.efficialsApp`

### Windows API Key:
- Application restrictions: None (or HTTP referrers if hosting)

## Step 3: Configure Your App

### For Dart/Flutter:
1. Copy `lib/config/firebase_config_template.dart` to `lib/config/firebase_config.dart`
2. Replace the placeholders with your new API keys:
   ```dart
   apiKey: 'YOUR_ACTUAL_API_KEY_HERE'
   ```

### For Android:
1. Copy `android/app/google-services-template.json` to `android/app/google-services.json`  
2. Replace `YOUR_NEW_ANDROID_API_KEY_HERE` with your Android API key

### Update Your Main App:
Replace the import in `lib/main.dart`:
```dart
// Change from:
import 'firebase_options.dart';

// To:
import 'config/firebase_config.dart';

// And change:
options: DefaultFirebaseOptions.currentPlatform,

// To:
options: FirebaseConfig.currentPlatform,
```

## Step 4: Test Your Setup

Run your app and verify Firebase connection works:
```bash
flutter run
```

## Security Notes

- ✅ Template files are safe to commit (contain no real keys)
- ❌ Never commit the actual config files with real API keys
- ✅ The .gitignore is configured to prevent accidental commits
- ✅ API keys are restricted to specific platforms/domains

## If You Make a Mistake

If you accidentally commit API keys again:
1. Immediately revoke the exposed keys in Google Cloud Console
2. Generate new keys
3. Follow these setup instructions again