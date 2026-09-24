import 'package:flutter_test/flutter_test.dart';
import 'package:phuong_dong_admin/models/booking.dart';

void main() {
  test('booking status and quote preserve business values', () {
    expect(BookingStatusX.parse('confirmed'), BookingStatus.confirmed);
    expect(BookingStatus.completed.label, 'Hoàn thành');
    const quote = BookingQuote(
      type: 'Vest',
      fabric: 'Wool 150s',
      qty: 2,
      unitPrice: 5000000,
      total: 10000000,
      deposit: 3000000,
    );
    expect(BookingQuote.fromMap(quote.toMap()).total, 10000000);
    expect(quote.deposit, lessThan(quote.total));
  });
}
