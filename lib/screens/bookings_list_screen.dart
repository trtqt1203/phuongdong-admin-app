import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/screens/booking_detail_screen.dart';
import 'package:phuong_dong_admin/services/booking_service.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:phuong_dong_admin/widgets/booking_tile.dart';
import 'package:provider/provider.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});
  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  BookingStatus? filter;
  String query = '';
  bool appointmentSort = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Lịch hẹn'),
      actions: [
        PopupMenuButton<bool>(
          initialValue: appointmentSort,
          onSelected: (value) => setState(() => appointmentSort = value),
          itemBuilder: (_) => const [
            PopupMenuItem(value: false, child: Text('Mới nhất trước')),
            PopupMenuItem(value: true, child: Text('Ngày hẹn gần nhất')),
          ],
          icon: const Icon(Icons.sort),
        ),
      ],
    ),
    body: StreamBuilder<List<Booking>>(
      stream: context.read<BookingService>().watchBookings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var bookings = snapshot.data!.where((item) {
          final term = query.trim().toLowerCase();
          final matchesStatus = filter == null || item.status == filter;
          final matchesQuery =
              term.isEmpty ||
              '${item.id} ${item.name} ${item.phone}'.toLowerCase().contains(
                term,
              );
          return matchesStatus && matchesQuery;
        }).toList();
        if (appointmentSort) {
          bookings.sort((a, b) => a.appointmentAt.compareTo(b.appointmentAt));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tên, SĐT hoặc mã PD-XXXXXX',
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _Filter(
                    label: 'Tất cả',
                    selected: filter == null,
                    onTap: () => setState(() => filter = null),
                  ),
                  ...BookingStatus.values.map(
                    (status) => _Filter(
                      label: status.label,
                      selected: filter == status,
                      onTap: () => setState(() => filter = status),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: bookings.isEmpty
                  ? const Center(
                      child: Text(
                        'Không có lịch hẹn phù hợp.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey(
                              '${booking.id}-${booking.status.name}',
                            ),
                            direction:
                                booking.status == BookingStatus.cancelled ||
                                    booking.status == BookingStatus.completed
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: AppColors.rust,
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (_) =>
                                _quickAction(context, booking),
                            child: BookingTile(
                              booking: booking,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingDetailScreen(
                                    bookingId: booking.id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _createManual(context),
      icon: const Icon(Icons.add),
      label: const Text('TẠO LỊCH'),
    ),
  );

  Future<bool> _quickAction(BuildContext context, Booking booking) async {
    final action = await showModalBottomSheet<BookingStatus>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(booking.name, style: AppTheme.serif.copyWith(fontSize: 25)),
              const SizedBox(height: 12),
              if (booking.status == BookingStatus.pending)
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, BookingStatus.confirmed),
                  icon: const Icon(Icons.check),
                  label: const Text('XÁC NHẬN LỊCH'),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, BookingStatus.cancelled),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rust,
                ),
                icon: const Icon(Icons.close),
                label: const Text('HỦY LỊCH'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action != null && context.mounted) {
      await context.read<BookingService>().updateStatus(booking.id, action);
    }
    return false;
  }

  Future<void> _createManual(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final product = TextEditingController();
    final budget = TextEditingController();
    final note = TextEditingController();
    var type = 'tuvan';
    var date = DateTime.now().add(const Duration(days: 1));
    var time = const TimeOfDay(hour: 14, minute: 0);
    var busy = false;
    var error = '';
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Tạo lịch thủ công'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'tuvan', label: Text('Tư vấn')),
                      ButtonSegment(value: 'domay', label: Text('Đo may')),
                    ],
                    selected: {type},
                    onSelectionChanged: (value) =>
                        setLocal(() => type = value.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Tên khách *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: product,
                    decoration: const InputDecoration(labelText: 'Sản phẩm'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: budget,
                    decoration: const InputDecoration(labelText: 'Ngân sách'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 730),
                              ),
                              initialDate: date,
                            );
                            if (picked != null) setLocal(() => date = picked);
                          },
                          child: Text(DateFormat('dd/MM/yyyy').format(date)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: time,
                            );
                            if (picked != null) setLocal(() => time = picked);
                          },
                          child: Text(time.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Ghi chú'),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        error,
                        style: const TextStyle(color: AppColors.rust),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (name.text.trim().length < 2 ||
                          phone.text.trim().length < 9) {
                        setLocal(
                          () => error = 'Tên và số điện thoại chưa hợp lệ.',
                        );
                        return;
                      }
                      setLocal(() {
                        busy = true;
                        error = '';
                      });
                      try {
                        await context.read<BookingService>().createManual(
                          type: type,
                          name: name.text,
                          phone: phone.text,
                          email: email.text,
                          product: product.text,
                          budget: budget.text,
                          note: note.text,
                          date: DateFormat('yyyy-MM-dd').format(date),
                          time:
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (_) {
                        setLocal(() {
                          busy = false;
                          error = 'Không tạo được lịch hẹn.';
                        });
                      }
                    },
              child: Text(busy ? 'ĐANG LƯU…' : 'TẠO LỊCH'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    email.dispose();
    product.dispose();
    budget.dispose();
    note.dispose();
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}
