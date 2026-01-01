import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDFfD8_YIkUlIhngPCXpXSOQVM6Gpxjq14',
    appId: '1:549075737620:web:718b9699814999f9ed9b01',
    messagingSenderId: '549075737620',
    projectId: 'itiraf-f9cc6',
    authDomain: 'itiraf-f9cc6.firebaseapp.com',
    storageBucket: 'itiraf-f9cc6.firebasestorage.app',
    measurementId: 'G-V1VBX9KM3V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFfD8_YIkUlIhngPCXpXSOQVM6Gpxjq14',
    appId: '1:549075737620:android:c402bee00da9dddbed9b01',
    messagingSenderId: '549075737620',
    projectId: 'itiraf-f9cc6',
    storageBucket: 'itiraf-f9cc6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDFfD8_YIkUlIhngPCXpXSOQVM6Gpxjq14',
    appId: '1:549075737620:android:c402bee00da9dddbed9b01',
    messagingSenderId: '549075737620',
    projectId: 'itiraf-f9cc6',
    storageBucket: 'itiraf-f9cc6.firebasestorage.app',
    iosBundleId: 'com.dgn.konubu',
  );

  // VAPID key for FCM web push notifications
  static const String vapidKey =
      'BK5pd3kFllWmG1226LF8cks86HWD_Vu-4CbTd19p2Ino1h8VUo0jUSQr1yCBGlrbzcUX0ps7CjDUm0XOSM7Aqbs';
}
