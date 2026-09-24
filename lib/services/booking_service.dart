import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phuong_dong_admin/models/booking.dart';

class BookingService {
  BookingService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');

  Stream<List<Booking>> watchBookings() => _bookings
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Booking.fromDoc).toList());

  Future<void> refreshBookings() async {
    await _bookings
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.server));
  }

  Stream<Booking?> watchBooking(String id) => _bookings
      .doc(id)
      .snapshots()
      .map((snapshot) => snapshot.exists ? Booking.fromDoc(snapshot) : null);

  Stream<Map<String, dynamic>> watchPublicSettings() => _firestore
      .collection('settings')
      .doc('public')
      .snapshots()
      .map((snapshot) => snapshot.data() ?? const <String, dynamic>{});

  Stream<List<Map<String, dynamic>>> watchAdmins() => _firestore
      .collection('admins')
      .orderBy('email')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList(),
      );

  String nextCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return 'PD-${List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)]).join()}';
  }

  Future<String> createManual({
    required String type,
    required String name,
    required String phone,
    required String email,
    required String product,
    required String budget,
    required String note,
    required String date,
    required String time,
  }) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final id = nextCode();
      final ref = _bookings.doc(id);
      if ((await ref.get()).exists) continue;
      await ref.set({
        'id': id,
        'type': type,
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim().toLowerCase(),
        'product': product.trim(),
        'budget': budget.trim(),
        'note': note.trim(),
        'date': date,
        'time': time,
        'status': BookingStatus.pending.value,
        'payMethod': '',
        'quote': null,
        'adminNote': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': [
          {
            'status': 'pending',
            'at': Timestamp.now(),
            'by': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
          },
        ],
      });
      return id;
    }
    throw StateError('Không tạo được mã lịch hẹn duy nhất.');
  }

  Future<void> updateStatus(String id, BookingStatus status) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    await _bookings.doc(id).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {'status': status.value, 'at': Timestamp.now(), 'by': uid},
      ]),
    });
  }

  Future<void> updateAdminNote(String id, String note) =>
      _bookings.doc(id).update({
        'adminNote': note.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateQuote(String id, BookingQuote? quote) =>
      _bookings.doc(id).update({
        'quote': quote?.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updatePublicSettings(Map<String, dynamic> settings) =>
      _firestore.collection('settings').doc('public').set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> createStaff({
    required String email,
    required String password,
    String role = 'staff',
  }) async {
    await _functions.httpsCallable('createAdminUser').call({
      'email': email.trim(),
      'password': password,
      'role': role,
    });
  }

  Future<void> disableStaff(String uid) async {
    await _functions.httpsCallable('disableAdminUser').call({'uid': uid});
  }
}
