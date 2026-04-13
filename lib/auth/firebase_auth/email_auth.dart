import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Register a new user with email + password + display name.
/// Creates the Firestore user document on success.
Future<UserCredential?> registerWithEmail({
  required String name,
  required String email,
  required String password,
}) async {
  final credential = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(email: email, password: password);
  final user = credential.user;
  if (user != null) {
    await user.updateDisplayName(name);
    // Create Firestore user document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'email': email,
      'display_name': name,
      'player_name': name,
      'created_time': FieldValue.serverTimestamp(),
      'is_guest': false,
    }, SetOptions(merge: true));
  }
  return credential;
}

/// Sign in an existing user with email + password.
Future<UserCredential?> signInWithEmail({
  required String email,
  required String password,
}) async {
  return await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: email, password: password);
}

/// Send a password reset email.
Future<void> sendPasswordReset({required String email}) async {
  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
}

/// Sign in anonymously as a guest.
Future<UserCredential?> signInAsGuest() async {
  return await FirebaseAuth.instance.signInAnonymously();
}

/// Sign out current user.
Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
}

/// Legacy function expected by FirebaseAuthManager
Future<UserCredential?> emailSignInFunc(String email, String password) async {
  return await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: email, password: password);
}

/// Legacy function expected by FirebaseAuthManager
Future<UserCredential?> emailCreateAccountFunc(String email, String password) async {
  return await FirebaseAuth.instance
      .createUserWithEmailAndPassword(email: email, password: password);
}
