import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:costing_master/constant/firebase_constants.dart';
import 'package:costing_master/model/user_model.dart';
import 'package:costing_master/provider/firebase_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
    firestore: ref.read(firestoreProvider),
    auth: ref.read(firebaseAuthProvider),
    googleSignIn: ref.read(googleSignInProvider)));

class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository(
      {required FirebaseFirestore firestore,
      required FirebaseAuth auth,
      required GoogleSignIn googleSignIn})
      : _firestore = firestore,
        _auth = auth,
        _googleSignIn = googleSignIn;

  User? get currentUser => _auth.currentUser;
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  Stream<User?> get authStateChange => _auth.authStateChanges();

  /// Returns the signed-in user's profile, or null when signed out.
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _users.doc(user.uid).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return UserModel(name: user.displayName ?? '', uid: user.uid);
    }
    return UserModel.fromMap(data);
  }

  /// Returns null if the user closed the Google account picker.
  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      final userModel = UserModel(name: user.displayName ?? '', uid: user.uid);
      await _users
          .doc(user.uid)
          .set(userModel.toMap(), SetOptions(merge: true));
      return userModel;
    }
    return getCurrentUserModel();
  }

  Future<void> logOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
