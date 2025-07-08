import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data() as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  String _mapFirebaseAuthError(String error) {
    if (error.contains('invalid-email')) {
      return 'Format email tidak valid.';
    } else if (error.contains('user-not-found')) {
      return 'Email tidak terdaftar.';
    } else if (error.contains('wrong-password')) {
      return 'Password salah.';
    } else if (error.contains('email-already-in-use')) {
      return 'Email sudah digunakan.';
    } else if (error.contains('weak-password')) {
      return 'Password terlalu lemah (minimal 6 karakter).';
    } else if (error.contains('network-request-failed')) {
      return 'Tidak dapat terhubung ke server. Cek koneksi internet.';
    } else {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserData(result.user!.uid);
      return true;
    } catch (e) {
      _error = _mapFirebaseAuthError(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> register(String email, String password, String name, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        id: result.user!.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(result.user!.uid).set(newUser.toJson());
      _currentUser = newUser;
      return true;
    } catch (e) {
      _error = _mapFirebaseAuthError(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password) async {
    return await register(email, password, 'User', 'user');
  }

  Future<void> updateRole(String role) async {
    if (_currentUser == null) return;
    try {
      await _firestore.collection('users').doc(_currentUser!.id).update({'role': role});
      _currentUser = UserModel(
        id: _currentUser!.id,
        email: _currentUser!.email,
        name: _currentUser!.name,
        role: role,
        createdAt: _currentUser!.createdAt,
        photoUrl: _currentUser!.photoUrl,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
