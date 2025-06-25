import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyDTw6ib0nKMghlpvVH2m3tbw3lahIrVXgQ",
      appId: "1:73516037879:android:a3c5169e938321877cc5f2",
      messagingSenderId: "73516037879",
      projectId: "momwherego",
      storageBucket: "momwherego.firebasestorage.app",
      databaseURL: "https://momwherego.firebaseio.com",
      androidClientId: "106415738282775289622.apps.googleusercontent.com",
      iosClientId: "your-ios-client-id",
    );
  }
}
