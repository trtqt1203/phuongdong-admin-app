import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/services/booking_service.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:phuong_dong_admin/widgets/status_badge.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) => StreamBuilder<Booking?>(
    stream: context.read<BookingService>().watchBooking(bookingId),
    builder: (context, snapshot) {
      final booking = snapshot.data;
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (booking == null) {
        return const Scaffold(
          body: Center(child: Text('Lịch hẹn không còn tồn tại.')),
        );
      }
      return _BookingDetail(booking: booking);
    },
  );
}

class _BookingDetail extends StatefulWidget {
  const _BookingDetail({required this.booking});
  final Booking booking;
  @override
  State<_BookingDetail> createState() => _BookingDetailState();
}

class _BookingDetailState extends State<_BookingDetail> {
  late final TextEditingController note;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    note = TextEditingController(text: widget.booking.adminNote);
  }

  @override
  void didUpdateWidget(covariant _BookingDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!note.selection.isValid &&
        oldWidget.booking.adminNote != widget.booking.adminNote) {
      note.text = widget.booking.adminNote;
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> changeStatus(BookingStatus status) async {
    if (status == BookingStatus.cancelled) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hủy lịch hẹn?'),
          content: const Text('Thao tác này sẽ được ghi vào lịch sử.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận hủy'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    if (!mounted) return;
    await context.read<BookingService>().updateStatus(
      widget.booking.id,
      status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final canComplete =
        booking.status == BookingStatus.confirmed &&
        !booking.appointmentAt.isAfter(DateTime.now());
    final timeline =
        booking.statusHistory.any(
          (event) => event.status == BookingStatus.pending,
        )
        ? booking.statusHistory
        : [
            StatusEvent(status: BookingStatus.pending, at: booking.createdAt),
            ...booking.statusHistory,
          ];
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          Text(
            booking.id,
            style: AppTheme.mono.copyWith(
              color: AppColors.gold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  booking.name,
                  style: AppTheme.serif.copyWith(fontSize: 34),
                ),
              ),
              StatusBadge(status: booking.status, large: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:${booking.phone}')),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('GỌI'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('sms:${booking.phone}')),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('SMS'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://zalo.me/${booking.phone}'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('ZALO'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoCard(
            children: [
              _Info(label: 'Dịch vụ', value: booking.typeLabel),
              _Info(
                label: 'Sản phẩm',
                value: booking.product.isEmpty ? 'Chưa chọn' : booking.product,
              ),
              _Info(
                label: 'Ngày giờ',
                value: '${booking.date} · ${booking.time}',
              ),
              _Info(label: 'Số điện thoại', value: booking.phone),
              _Info(
                label: 'Email',
                value: booking.email.isEmpty ? 'Không có' : booking.email,
              ),
              _Info(
                label: 'Ngân sách',
                value: booking.budget.isEmpty
                    ? 'Chưa cung cấp'
                    : booking.budget,
              ),
              _Info(
                label: 'Thanh toán',
                value: booking.payMethod.isEmpty
                    ? 'Chưa chọn'
                    : booking.payMethod,
              ),
              _Info(
                label: 'Ghi chú khách',
                value: booking.note.isEmpty ? 'Không có' : booking.note,
                full: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BÁO GIÁ',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _editQuote(context, booking),
                        child: Text(
                          booking.quote == null ? 'Tạo báo giá' : 'Chỉnh sửa',
                        ),
                      ),
                    ],
                  ),
                  if (booking.quote == null)
                    const Text(
                      'Chưa có báo giá.',
                      style: TextStyle(color: AppColors.muted),
                    )
                  else ...[
                    _PriceRow('Loại', booking.quote!.type),
                    _PriceRow('Vải', booking.quote!.fabric),
                    _PriceRow('Số lượng', '${booking.quote!.qty}'),
                    _PriceRow(
                      'Đơn giá',
                      money.format(booking.quote!.unitPrice),
                    ),
                    const Divider(),
                    _PriceRow(
                      'Tổng',
                      money.format(booking.quote!.total),
                      strong: true,
                    ),
                    _PriceRow(
                      'Tiền cọc',
                      money.format(booking.quote!.deposit),
                      strong: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GHI CHÚ NỘI BỘ',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      hintText: 'Thông tin chỉ nhân viên nhìn thấy…',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: saving
                          ? null
                          : () async {
                              final service = context.read<BookingService>();
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => saving = true);
                              await service.updateAdminNote(
                                booking.id,
                                note.text,
                              );
                              if (mounted) {
                                setState(() => saving = false);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã lưu ghi chú.'),
                                  ),
                                );
                              }
                            },
                      child: Text(saving ? 'ĐANG LƯU…' : 'LƯU GHI CHÚ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LỊCH SỬ TRẠNG THÁI',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...timeline.map(
                    (event) =>
                        _TimelineItem(status: event.status, at: event.at),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
          ),
          child: Row(
            children: [
              if (booking.status == BookingStatus.pending)
                Expanded(
                  child: FilledButton(
                    onPressed: () => changeStatus(BookingStatus.confirmed),
                    child: const Text('XÁC NHẬN LỊCH'),
                  ),
                ),
              if (canComplete)
                Expanded(
                  child: FilledButton(
                    onPressed: () => changeStatus(BookingStatus.completed),
                    child: const Text('ĐÁNH DẤU HOÀN THÀNH'),
                  ),
                ),
              if (booking.status != BookingStatus.cancelled &&
                  booking.status != BookingStatus.completed) ...[
                if (booking.status == BookingStatus.pending || canComplete)
                  const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => changeStatus(BookingStatus.cancelled),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rust,
                  ),
                  child: const Text('HỦY LỊCH'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editQuote(BuildContext context, Booking booking) async {
    final type = TextEditingController(
      text: booking.quote?.type ?? booking.product,
    );
    final fabric = TextEditingController(text: booking.quote?.fabric ?? '');
    final qty = TextEditingController(text: '${booking.quote?.qty ?? 1}');
    final unit = TextEditingController(
      text: '${booking.quote?.unitPrice ?? 0}',
    );
    final deposit = TextEditingController(
      text: '${booking.quote?.deposit ?? 0}',
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Báo giá ${booking.id}',
                style: AppTheme.serif.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: type,
                decoration: const InputDecoration(labelText: 'Loại sản phẩm'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fabric,
                decoration: const InputDecoration(labelText: 'Loại vải'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qty,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số lượng'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unit,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Đơn giá'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deposit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tiền cọc'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('LƯU BÁO GIÁ'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      final count = int.tryParse(qty.text) ?? 1;
      final price = int.tryParse(unit.text) ?? 0;
      await context.read<BookingService>().updateQuote(
        booking.id,
        BookingQuote(
          type: type.text.trim(),
          fabric: fabric.text.trim(),
          qty: count,
          unitPrice: price,
          total: count * price,
          deposit: int.tryParse(deposit.text) ?? 0,
        ),
      );
    }
    type.dispose();
    fabric.dispose();
    qty.dispose();
    unit.dispose();
    deposit.dispose();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(runSpacing: 14, children: children),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value, this.full = false});
  final String label;
  final String value;
  final bool full;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: full ? double.infinity : (MediaQuery.sizeOf(context).width - 68) / 2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 3),
        Text(value),
      ],
    ),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: strong
                ? AppTheme.mono.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  )
                : null,
          ),
        ),
      ],
    ),
  );
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.status, required this.at});
  final BookingStatus status;
  final DateTime at;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(width: 1, color: const Color(0x33FFFFFF)),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('HH:mm · dd/MM/yyyy').format(at),
                  style: AppTheme.mono.copyWith(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
