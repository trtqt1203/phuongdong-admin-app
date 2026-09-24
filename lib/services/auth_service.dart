import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance {
    _subscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  late final StreamSubscription<User?> _subscription;
  bool _initialAuthEvent = true;
  User? user;
  String role = '';
  bool ready = false;

  bool get isOwner => role == 'owner';
  bool get isAuthenticated => user != null && role.isNotEmpty;

  Future<void> _onAuthChanged(User? next) async {
    final isInitialEvent = _initialAuthEvent;
    _initialAuthEvent = false;
    user = next;
    role = '';
    if (next != null) {
      final prefs = await SharedPreferences.getInstance();
      if (isInitialEvent && !(prefs.getBool('remember_login') ?? true)) {
        await _removeDeviceToken();
        await _auth.signOut();
        user = null;
      } else {
        final profile = await _firestore
            .collection('admins')
            .doc(next.uid)
            .get();
        final data = profile.data();
        final nextRole = data?['role'] as String? ?? '';
        final disabled = data?['disabled'] == true;
        if (!{'owner', 'admin', 'staff'}.contains(nextRole) || disabled) {
          await _auth.signOut();
          user = null;
        } else {
          role = nextRole;
        }
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final profile = await _firestore
        .collection('admins')
        .doc(credential.user!.uid)
        .get();
    final data = profile.data();
    final nextRole = data?['role'] as String? ?? '';
    final disabled = data?['disabled'] == true;
    if (!{'owner', 'admin', 'staff'}.contains(nextRole) || disabled) {
      await _removeDeviceToken();
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'not-authorized',
        message: 'Tài khoản chưa được cấp quyền nhân viên.',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_login', remember);
    user = credential.user;
    role = nextRole;
    ready = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _removeDeviceToken();
    await _auth.signOut();
  }

  Future<void> _removeDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('admin_tokens').doc(token).delete();
      }
    } catch (_) {
      // Signing out must still succeed if FCM is unavailable.
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
