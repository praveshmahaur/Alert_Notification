import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Signup Function (Default role = "user")
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore default role "user" set 
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': "user",
      });
      

      return userCredential.user;
    } catch (e) {
      print("Signup Error: $e");
      return null;
    }
  }

  // Login Function (Fetch user role from Firestore)
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch Data From Firebase
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (userDoc.exists) {
        return userDoc['role']; // "user" or "admin"
      } else {
        return null; // User document not receive
      }
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // 🔹 Logout Function
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

