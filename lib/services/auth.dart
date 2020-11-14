import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errandsguy_app/Models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  AuthService({this.auth, this.firestore});
Stream<User> get user => auth.authStateChanges();
  UserModel _userFromFirebaseUser(User user) {
    return user != null ? UserModel(uid: user.uid) : null;
  }
  Future signInWithCredentail(AuthCredential credential) =>
      auth.signInWithCredential(credential);
  Future<void> logout() => auth.signOut();

  Future signIn(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
  Future signOut() async {
    try {
      return await auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
   getUserInfo(String email) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("userEmail", isEqualTo: email)
        .get()
        .catchError((e) {
      print(e.toString());
    });
  }
}
