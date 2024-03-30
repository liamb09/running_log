// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
/// 
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
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXGUt5diT_3jYyHq4xuDq1o5xHBQp2ayI',
    appId: '1:178903937427:web:2da98466b1f41014b53866',
    messagingSenderId: '178903937427',
    projectId: 'running-log-af92b',
    authDomain: 'running-log-af92b.firebaseapp.com',
    storageBucket: 'running-log-af92b.appspot.com',
    measurementId: 'G-PB6XH0EXKV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAlEdAp5kQ2W9aMtzRSNZDpSbkxCmLfJm4',
    appId: '1:178903937427:android:db3c5433a4896d85b53866',
    messagingSenderId: '178903937427',
    projectId: 'running-log-af92b',
    storageBucket: 'running-log-af92b.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAoK6pSKGN0eLJkeUQkhyhuuWmjebhXn9c',
    appId: '1:178903937427:ios:a8b2803628a0f3feb53866',
    messagingSenderId: '178903937427',
    projectId: 'running-log-af92b',
    storageBucket: 'running-log-af92b.appspot.com',
    iosBundleId: 'com.example.runningLog',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAoK6pSKGN0eLJkeUQkhyhuuWmjebhXn9c',
    appId: '1:178903937427:ios:4d7025dca169b72fb53866',
    messagingSenderId: '178903937427',
    projectId: 'running-log-af92b',
    storageBucket: 'running-log-af92b.appspot.com',
    iosBundleId: 'com.example.runningLog.RunnerTests',
  );
}
