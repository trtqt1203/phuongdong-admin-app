import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, cancelled, completed }

extension BookingStatusX on BookingStatus {
  String get value => name;
  String get label => switch (this) {
    BookingStatus.pending => 'Chờ xác nhận',
    BookingStatus.confirmed => 'Đã xác nhận',
    BookingStatus.cancelled => 'Đã hủy',
    BookingStatus.completed => 'Hoàn thành',
  };

  static BookingStatus parse(Object? value) => BookingStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => BookingStatus.pending,
  );
}

class BookingQuote {
  const BookingQuote({
    required this.type,
    required this.fabric,
    required this.qty,
    required this.unitPrice,
    required this.total,
    required this.deposit,
  });

  final String type;
  final String fabric;
  final int qty;
  final int unitPrice;
  final int total;
  final int deposit;

  factory BookingQuote.fromMap(Map<String, dynamic> map) => BookingQuote(
    type: map['type'] as String? ?? '',
    fabric: map['fabric'] as String? ?? '',
    qty: (map['qty'] as num?)?.toInt() ?? 1,
    unitPrice: (map['unitPrice'] as num?)?.toInt() ?? 0,
    total: (map['total'] as num?)?.toInt() ?? 0,
    deposit: (map['deposit'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'type': type,
    'fabric': fabric,
    'qty': qty,
    'unitPrice': unitPrice,
    'total': total,
    'deposit': deposit,
  };
}

class StatusEvent {
  const StatusEvent({required this.status, required this.at, this.by = ''});
  final BookingStatus status;
  final DateTime at;
  final String by;

  factory StatusEvent.fromMap(Map<String, dynamic> map) => StatusEvent(
    status: BookingStatusX.parse(map['status']),
    at: (map['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    by: map['by'] as String? ?? '',
  );
}

class Booking {
  const Booking({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.email,
    required this.product,
    required this.budget,
    required this.note,
    required this.date,
    required this.time,
    required this.status,
    required this.payMethod,
    required this.adminNote,
    required this.createdAt,
    required this.updatedAt,
    this.quote,
    this.statusHistory = const [],
  });

  final String id;
  final String type;
  final String name;
  final String phone;
  final String email;
  final String product;
  final String budget;
  final String note;
  final String date;
  final String time;
  final BookingStatus status;
  final String payMethod;
  final BookingQuote? quote;
  final String adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusEvent> statusHistory;

  bool get isToday {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return date == today;
  }

  DateTime get appointmentAt =>
      DateTime.tryParse('${date}T$time:00') ?? createdAt;
  String get typeLabel => type == 'domay' ? 'Đo may' : 'Tư vấn';

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    final quoteMap = map['quote'];
    return Booking(
      id: map['id'] as String? ?? doc.id,
      type: map['type'] as String? ?? 'tuvan',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      product: map['product'] as String? ?? '',
      budget: map['budget'] as String? ?? '',
      note: map['note'] as String? ?? '',
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      status: BookingStatusX.parse(map['status']),
      payMethod: map['payMethod'] as String? ?? '',
      quote: quoteMap is Map<String, dynamic>
          ? BookingQuote.fromMap(quoteMap)
          : null,
      adminNote: map['adminNote'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statusHistory: (map['statusHistory'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StatusEvent.fromMap)
          .toList(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'id': id,
    'type': type,
    'name': name,
    'phone': phone,
    'email': email,
    'product': product,
    'budget': budget,
    'note': note,
    'date': date,
    'time': time,
    'status': status.value,
    'payMethod': payMethod,
    'quote': quote?.toMap(),
    'adminNote': adminNote,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'statusHistory': [
      {
        'status': status.value,
        'at': FieldValue.serverTimestamp(),
        'by': 'manual',
      },
    ],
  };
}
