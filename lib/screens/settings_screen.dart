import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/screens/customers_screen.dart';
import 'package:phuong_dong_admin/services/auth_service.dart';
import 'package:phuong_dong_admin/services/booking_service.dart';
import 'package:phuong_dong_admin/services/notification_service.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final notifications = context.watch<NotificationService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
                child: Icon(Icons.person_outline),
              ),
              title: Text(auth.user?.email ?? ''),
              subtitle: Text(
                'Vai trò: ${auth.role}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: notifications.enabled,
                  onChanged: auth.user == null
                      ? null
                      : (value) => notifications.setEnabled(value, auth.user!),
                  title: const Text('Thông báo push'),
                  subtitle: const Text(
                    'Nhận thông báo khi có lịch hẹn mới',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Khách hàng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomersScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Xuất lịch hẹn ra Excel'),
                  subtitle: const Text(
                    'Chọn khoảng ngày và chia sẻ file .xlsx',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  onTap: () => _exportExcel(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _WorkingHoursCard(),
          if (auth.isOwner) ...[const SizedBox(height: 12), const _StaffCard()],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await notifications.deactivate();
              await auth.signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('ĐĂNG XUẤT'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Phương Đông Admin · Dữ liệu đồng bộ Firebase theo thời gian thực',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.dim, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
    );
    if (range == null || !context.mounted) return;
    final bookings = await context.read<BookingService>().watchBookings().first;
    final selected = bookings.where((item) {
      final date = DateTime.tryParse(item.date);
      return date != null &&
          !date.isBefore(range.start) &&
          !date.isAfter(range.end.add(const Duration(days: 1)));
    }).toList();
    final workbook = Excel.createExcel();
    final sheet = workbook['Lịch hẹn'];
    sheet.appendRow(
      [
        'Mã',
        'Loại',
        'Khách hàng',
        'SĐT',
        'Email',
        'Sản phẩm',
        'Ngân sách',
        'Ngày',
        'Giờ',
        'Trạng thái',
        'Tổng tiền',
        'Tiền cọc',
        'Ghi chú',
      ].map(TextCellValue.new).toList(),
    );
    for (final item in selected) {
      sheet.appendRow(
        [
          item.id,
          item.typeLabel,
          item.name,
          item.phone,
          item.email,
          item.product,
          item.budget,
          item.date,
          item.time,
          item.status.label,
          '${item.quote?.total ?? 0}',
          '${item.quote?.deposit ?? 0}',
          item.note,
        ].map(TextCellValue.new).toList(),
      );
    }
    workbook.delete('Sheet1');
    final bytes = workbook.save();
    if (bytes == null) return;
    final directory = await getTemporaryDirectory();
    final name =
        'lich-hen-${DateFormat('yyyyMMdd').format(range.start)}-${DateFormat('yyyyMMdd').format(range.end)}.xlsx';
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: [name],
        title: 'Lịch hẹn Phương Đông',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

class _WorkingHoursCard extends StatefulWidget {
  const _WorkingHoursCard();
  @override
  State<_WorkingHoursCard> createState() => _WorkingHoursCardState();
}

class _WorkingHoursCardState extends State<_WorkingHoursCard> {
  final open = TextEditingController();
  final close = TextEditingController();
  final holidays = TextEditingController();
  bool loaded = false;
  bool saving = false;
  @override
  void dispose() {
    open.dispose();
    close.dispose();
    holidays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
    stream: context.read<BookingService>().watchPublicSettings(),
    builder: (context, snapshot) {
      if (!loaded && snapshot.hasData) {
        loaded = true;
        open.text = snapshot.data!['openTime'] as String? ?? '09:00';
        close.text = snapshot.data!['closeTime'] as String? ?? '18:00';
        holidays.text =
            (snapshot.data!['holidays'] as List<dynamic>? ?? const []).join(
              ', ',
            );
      }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'GIỜ LÀM VIỆC',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: open,
                      decoration: const InputDecoration(labelText: 'Mở cửa'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: close,
                      decoration: const InputDecoration(labelText: 'Đóng cửa'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: holidays,
                decoration: const InputDecoration(
                  labelText: 'Ngày nghỉ (YYYY-MM-DD, cách nhau dấu phẩy)',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() => saving = true);
                        await context
                            .read<BookingService>()
                            .updatePublicSettings({
                              'openTime': open.text.trim(),
                              'closeTime': close.text.trim(),
                              'holidays': holidays.text
                                  .split(',')
                                  .map((value) => value.trim())
                                  .where((value) => value.isNotEmpty)
                                  .toList(),
                              'workDays': [1, 2, 3, 4, 5, 6],
                            });
                        if (mounted) setState(() => saving = false);
                      },
                child: Text(saving ? 'ĐANG LƯU…' : 'LƯU LỊCH LÀM VIỆC'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _StaffCard extends StatelessWidget {
  const _StaffCard();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NHÂN VIÊN',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addStaff(context),
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
            ],
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: context.read<BookingService>().watchAdmins(),
            builder: (context, snapshot) {
              final admins = snapshot.data ?? const [];
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return Column(
                children: admins
                    .map(
                      (admin) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(admin['email'] as String? ?? ''),
                        subtitle: Text(
                          admin['role'] as String? ?? 'staff',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        trailing: admin['role'] == 'owner'
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.person_off_outlined,
                                  color: AppColors.rust,
                                ),
                                onPressed: () => _disableStaff(
                                  context,
                                  admin['uid'] as String,
                                  admin['email'] as String? ?? '',
                                ),
                              ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    ),
  );

  Future<void> _addStaff(BuildContext context) async {
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'staff';
    String error = '';
    bool busy = false;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Thêm nhân viên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu tạm'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                initialValue: role,
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('Nhân viên')),
                  DropdownMenuItem(value: 'admin', child: Text('Quản trị')),
                ],
                onChanged: (value) => role = value ?? 'staff',
                decoration: const InputDecoration(labelText: 'Vai trò'),
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
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setLocal(() {
                        busy = true;
                        error = '';
                      });
                      try {
                        await context.read<BookingService>().createStaff(
                          email: email.text,
                          password: password.text,
                          role: role,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (_) {
                        setLocal(() {
                          busy = false;
                          error = 'Không tạo được tài khoản. Kiểm tra email, mật khẩu và quyền owner.';
                        });
                      }
                    },
              child: Text(busy ? 'ĐANG TẠO…' : 'TẠO TÀI KHOẢN'),
            ),
          ],
        ),
      ),
    );
    email.dispose();
    password.dispose();
  }

  Future<void> _disableStaff(
    BuildContext context,
    String uid,
    String email,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vô hiệu hóa nhân viên?'),
        content: Text(email),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );
    if (accepted == true && context.mounted) {
      await context.read<BookingService>().disableStaff(uid);
    }
  }
}
