import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated configuration template allowing cross-platform Firebase initialization.
class DefaultFirebaseOptions {
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
        return ios;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForDevEnvironment00',
    appId: '1:100000000000:web:abcdef0123456789abcdef',
    messagingSenderId: '100000000000',
    projectId: 'job-platform-mobile-fcm',
    authDomain: 'job-platform-mobile-fcm.firebaseapp.com',
    storageBucket: 'job-platform-mobile-fcm.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForDevEnvironment00',
    appId: '1:100000000000:android:abcdef0123456789abcdef',
    messagingSenderId: '100000000000',
    projectId: 'job-platform-mobile-fcm',
    storageBucket: 'job-platform-mobile-fcm.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForDevEnvironment00',
    appId: '1:100000000000:ios:abcdef0123456789abcdef',
    messagingSenderId: '100000000000',
    projectId: 'job-platform-mobile-fcm',
    storageBucket: 'job-platform-mobile-fcm.appspot.com',
    iosBundleId: 'com.dutpbl6.jobPlatformMobile',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForDevEnvironment00',
    appId: '1:100000000000:web:abcdef0123456789abcdef',
    messagingSenderId: '100000000000',
    projectId: 'job-platform-mobile-fcm',
    storageBucket: 'job-platform-mobile-fcm.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForDevEnvironment00',
    appId: '1:100000000000:web:abcdef0123456789abcdef',
    messagingSenderId: '100000000000',
    projectId: 'job-platform-mobile-fcm',
    storageBucket: 'job-platform-mobile-fcm.appspot.com',
  );
}
