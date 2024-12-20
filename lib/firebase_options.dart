// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBUley_uNXoSqyMgUrB8BGoYDTDiSEar2U',
    appId: '1:134955657768:android:ec45045b7d62fabfd5231d',
    messagingSenderId: '134955657768',
    projectId: 'snaply-ef62f',
    storageBucket: 'snaply-ef62f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCjEw-jn3bcgQIx8rKFlZ7QGpzymOyvUoA',
    appId: '1:134955657768:ios:3c81867875401d24d5231d',
    messagingSenderId: '134955657768',
    projectId: 'snaply-ef62f',
    storageBucket: 'snaply-ef62f.firebasestorage.app',
    iosBundleId: 'com.example.learning',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCjEw-jn3bcgQIx8rKFlZ7QGpzymOyvUoA',
    appId: '1:134955657768:ios:0ca277d504d9d2b1d5231d',
    messagingSenderId: '134955657768',
    projectId: 'snaply-ef62f',
    storageBucket: 'snaply-ef62f.firebasestorage.app',
    iosBundleId: 'com.example.snaply',
  );
}
