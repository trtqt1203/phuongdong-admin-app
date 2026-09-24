import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService extends ChangeNotifier {
  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const _channel = AndroidNotificationChannel(
    'new_bookings',
    'Lịch hẹn mới',
    description: 'Thông báo khi website có lịch hẹn mới',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<String?> openedBookingId = ValueNotifier(null);
  bool enabled = true;
  bool _initialized = false;
  User? _currentUser;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  Future<void> initialize(User user) async {
    _currentUser = user;
    if (_initialized) {
      await _saveToken(user);
      return;
    }
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool('push_enabled') ?? true;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (response) =>
          openedBookingId.value = response.payload,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    if (enabled) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    }
    await _saveToken(user);
    _tokenSubscription = _messaging.onTokenRefresh.listen((_) {
      final currentUser = _currentUser;
      if (currentUser != null) _saveToken(currentUser);
    });
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      if (!enabled || FirebaseAuth.instance.currentUser == null) return;
      await _local.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Lịch hẹn mới',
        body: message.notification?.body ?? 'Mở ứng dụng để xem chi tiết.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'new_bookings',
            'Lịch hẹn mới',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['bookingId'] as String?,
      );
    });
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openMessage,
    );
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _openMessage(initial);
    notifyListeners();
  }

  void _openMessage(RemoteMessage message) {
    final id = message.data['bookingId'] as String?;
    if (id != null && id.isNotEmpty) openedBookingId.value = id;
  }

  Future<void> _saveToken(User user) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.collection('admin_tokens').doc(token).set({
      'uid': user.uid,
      'token': token,
      'enabled': enabled,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setEnabled(bool value, User user) async {
    enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_enabled', value);
    if (value) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    }
    await _saveToken(user);
    notifyListeners();
  }

  Future<void> deactivate() async {
    _currentUser = null;
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    openedBookingId.dispose();
    super.dispose();
  }
}
