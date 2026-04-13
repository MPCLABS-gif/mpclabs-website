import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyDG-EPVoIGLOwlS6Wu0TYuCWtf5oKFpCfM",
            authDomain: "match-point-coach-hd5pd8.firebaseapp.com",
            projectId: "match-point-coach-hd5pd8",
            storageBucket: "match-point-coach-hd5pd8.firebasestorage.app",
            messagingSenderId: "860266899184",
            appId: "1:860266899184:web:71ec23881b236b142b0435",
            measurementId: "G-XX9WK6GP3S"));
  } else {
    await Firebase.initializeApp();
  }
}
