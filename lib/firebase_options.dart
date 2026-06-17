 
 
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

 
 
 
 
 
 
 
 
 
 
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyD74SHybDzVtCxvpzXUn5OWbnpNmZ0BlGI',
    appId: '1:258263681738:android:b97363391b576682134233',
    messagingSenderId: '258263681738',
    projectId: 'klassinfo-app',
    storageBucket: 'klassinfo-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCFQ0IqVNLzGGNNiJ0jLrx2jg9GWhUYUXs',
    appId: '1:258263681738:ios:71a4d1070481c78f134233',
    messagingSenderId: '258263681738',
    projectId: 'klassinfo-app',
    storageBucket: 'klassinfo-app.firebasestorage.app',
    iosBundleId: 'com.example.klassinfoApp',
  );
}
