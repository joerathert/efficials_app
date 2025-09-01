// Template file - Copy to firebase_config.dart and fill in your actual API keys
// This file shows the structure but contains no real keys

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError('Linux platform not configured');
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_NEW_WEB_API_KEY_HERE',
    appId: '1:907190154709:web:a18d04881c49063ff7f95c',
    messagingSenderId: '907190154709',
    projectId: 'efficials-app',
    authDomain: 'efficials-app.firebaseapp.com',
    storageBucket: 'efficials-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_NEW_ANDROID_API_KEY_HERE',
    appId: '1:907190154709:android:d06353dd57ea575ff7f95c',
    messagingSenderId: '907190154709',
    projectId: 'efficials-app',
    storageBucket: 'efficials-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_NEW_IOS_API_KEY_HERE',
    appId: '1:907190154709:ios:22d9971cdef82981f7f95c',
    messagingSenderId: '907190154709',
    projectId: 'efficials-app',
    storageBucket: 'efficials-app.firebasestorage.app',
    iosBundleId: 'com.example.efficialsApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_NEW_MACOS_API_KEY_HERE',
    appId: '1:123456789:macos:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'efficials-app',
    storageBucket: 'efficials-app.firebasestorage.app',
    iosBundleId: 'com.example.efficialsApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_NEW_WINDOWS_API_KEY_HERE',
    appId: '1:907190154709:web:d5bf1769d81eb731f7f95c',
    messagingSenderId: '907190154709',
    projectId: 'efficials-app',
    authDomain: 'efficials-app.firebaseapp.com',
    storageBucket: 'efficials-app.firebasestorage.app',
  );
}