import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:phuong_dong_admin/widgets/booking_tile.dart';
import 'package:phuong_dong_admin/widgets/chart_widgets.dart';
import 'package:phuong_dong_admin/widgets/stat_card.dart';
import 'package:phuong_dong_admin/widgets/status_badge.dart';
import 'package:table_calendar/table_calendar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Phương Đông Admin · Demo',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const DemoShell(),
  );
}

class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  int index = 0;

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      label: 'Tổng quan',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      label: 'Lịch hẹn',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      label: 'Lịch',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      label: 'Cài đặt',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const pages = [
      _DemoDashboard(),
      _DemoBookings(),
      _DemoCalendar(),
      _DemoSettings(),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final content = Column(
          children: [
            const _DemoBanner(),
            Expanded(
              child: IndexedStack(index: index, children: pages),
            ),
          ],
        );
        if (!desktop) {
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: destinations,
            ),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: (value) => setState(() => index = value),
                extended: constraints.maxWidth >= 1180,
                minExtendedWidth: 220,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 22, 12, 30),
                  child: Text(
                    constraints.maxWidth >= 1180 ? 'PHƯƠNG ĐÔNG' : 'PĐ',
                    style: AppTheme.serif.copyWith(
                      color: AppColors.gold,
                      fontSize: 22,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Tổng quan'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.event_note_outlined),
                    selectedIcon: Icon(Icons.event_note),
                    label: Text('Lịch hẹn'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: Text('Lịch'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Cài đặt'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: AppColors.gold.withValues(alpha: .12),
    child: const Text(
      'DỮ LIỆU DEMO  ·  KHÔNG KẾT NỐI FIREBASE',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.gold,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _DemoDashboard extends StatelessWidget {
  const _DemoDashboard();

  @override
  Widget build(BuildContext context) {
    final bookings = demoBookings;
    final today = bookings.where((item) => item.isToday).toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          sliver: SliverList.list(
            children: [
              Text(
                DateFormat(
                  "EEEE, d 'tháng' M",
                  'vi',
                ).format(DateTime.now()).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Tổng quan xưởng',
                style: AppTheme.serif.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: columns == 4 ? 1.65 : 1.48,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      StatCard(
                        label: 'Tổng lịch hẹn',
                        value: '${bookings.length}',
                        icon: Icons.event_note,
                      ),
                      StatCard(
                        label: 'Hôm nay',
                        value: '${today.length}',
                        icon: Icons.today,
                      ),
                      StatCard(
                        label: 'Chờ xác nhận',
                        value:
                            '${bookings.where((item) => item.status == BookingStatus.pending).length}',
                        icon: Icons.hourglass_top,
                      ),
                      StatCard(
                        label: 'Đã xác nhận',
                        value:
                            '${bookings.where((item) => item.status == BookingStatus.confirmed).length}',
                        icon: Icons.verified_outlined,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final charts = [
                    _Panel(
                      title: '7 ngày gần nhất',
                      child: WeeklyBookingsChart(bookings: bookings),
                    ),
                    _Panel(
                      title: 'Phân loại dịch vụ',
                      child: BookingTypeChart(bookings: bookings),
                    ),
                  ];
                  if (constraints.maxWidth < 760) {
                    return Column(
                      children: [
                        charts[0],
                        const SizedBox(height: 12),
                        charts[1],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: charts[0]),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: charts[1]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lịch hẹn hôm nay',
                    style: AppTheme.serif.copyWith(fontSize: 25),
                  ),
                  Text(
                    '${today.length} LỊCH',
                    style: AppTheme.mono.copyWith(
                      color: AppColors.gold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...today.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BookingTile(
                    booking: booking,
                    onTap: () => _openBooking(context, booking),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DemoBookings extends StatefulWidget {
  const _DemoBookings();

  @override
  State<_DemoBookings> createState() => _DemoBookingsState();
}

class _DemoBookingsState extends State<_DemoBookings> {
  BookingStatus? filter;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final items = demoBookings.where((item) {
      final term = query.trim().toLowerCase();
      return (filter == null || item.status == filter) &&
          (term.isEmpty ||
              '${item.id} ${item.name} ${item.phone}'.toLowerCase().contains(
                term,
              ));
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lịch hẹn', style: AppTheme.serif.copyWith(fontSize: 34)),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tên, SĐT hoặc mã lịch hẹn',
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _DemoFilter(
                      label: 'Tất cả',
                      selected: filter == null,
                      onTap: () => setState(() => filter = null),
                    ),
                    ...BookingStatus.values.map(
                      (status) => _DemoFilter(
                        label: status.label,
                        selected: filter == status,
                        onTap: () => setState(() => filter = status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Không có lịch hẹn phù hợp.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => BookingTile(
                    booking: items[index],
                    onTap: () => _openBooking(context, items[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _DemoCalendar extends StatefulWidget {
  const _DemoCalendar();

  @override
  State<_DemoCalendar> createState() => _DemoCalendarState();
}

class _DemoCalendarState extends State<_DemoCalendar> {
  DateTime selected = DateTime.now();
  DateTime focused = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedItems = demoBookings
        .where((item) => item.date == DateFormat('yyyy-MM-dd').format(selected))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
      children: [
        Text('Lịch làm việc', style: AppTheme.serif.copyWith(fontSize: 34)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TableCalendar<Booking>(
              locale: 'vi_VN',
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 730)),
              focusedDay: focused,
              selectedDayPredicate: (day) => isSameDay(day, selected),
              eventLoader: (day) => demoBookings
                  .where(
                    (item) => item.date == DateFormat('yyyy-MM-dd').format(day),
                  )
                  .toList(),
              onDaySelected: (day, focus) => setState(() {
                selected = day;
                focused = focus;
              }),
              onPageChanged: (day) => focused = day,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Lịch ngày ${DateFormat('dd/MM/yyyy').format(selected)}',
          style: AppTheme.serif.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 10),
        if (selectedItems.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Ngày này chưa có lịch hẹn.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
          )
        else
          ...selectedItems.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BookingTile(
                booking: booking,
                onTap: () => _openBooking(context, booking),
              ),
            ),
          ),
      ],
    );
  }
}

class _DemoSettings extends StatefulWidget {
  const _DemoSettings();

  @override
  State<_DemoSettings> createState() => _DemoSettingsState();
}

class _DemoSettingsState extends State<_DemoSettings> {
  bool notifications = true;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
    children: [
      Text('Cài đặt', style: AppTheme.serif.copyWith(fontSize: 34)),
      const SizedBox(height: 14),
      const Card(
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.background,
            child: Icon(Icons.person_outline),
          ),
          title: Text('owner@phuongdong.vn'),
          subtitle: Text(
            'Vai trò: Chủ cửa hàng',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              value: notifications,
              onChanged: (value) => setState(() => notifications = value),
              title: const Text('Thông báo lịch hẹn mới'),
              subtitle: const Text(
                'Dữ liệu mô phỏng',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.people_outline),
              title: Text('Nhân viên'),
              subtitle: Text(
                '3 tài khoản đang hoạt động',
                style: TextStyle(color: AppColors.muted),
              ),
              trailing: Icon(Icons.chevron_right),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.schedule_outlined),
              title: Text('Giờ làm việc'),
              subtitle: Text(
                '09:00 – 18:00 · Thứ 2 đến Thứ 7',
                style: TextStyle(color: AppColors.muted),
              ),
              trailing: Icon(Icons.chevron_right),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Xuất lịch hẹn ra Excel'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bản demo không tạo file thật.')),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DemoDetail extends StatelessWidget {
  const _DemoDetail({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
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
            children: [
              Expanded(
                child: Text(
                  booking.name,
                  style: AppTheme.serif.copyWith(fontSize: 36),
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
                  onPressed: () => _demoAction(context),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('GỌI'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _demoAction(context),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('SMS'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _demoAction(context),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('ZALO'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Panel(
            title: 'Thông tin khách hàng',
            child: Column(
              children: [
                _DetailRow('Dịch vụ', booking.typeLabel),
                _DetailRow('Ngày giờ', '${booking.date} · ${booking.time}'),
                _DetailRow('Số điện thoại', booking.phone),
                _DetailRow('Sản phẩm', booking.product),
                _DetailRow('Ngân sách', booking.budget),
                _DetailRow('Ghi chú', booking.note),
              ],
            ),
          ),
          if (booking.quote != null) ...[
            const SizedBox(height: 12),
            _Panel(
              title: 'Báo giá',
              child: Column(
                children: [
                  _DetailRow('Loại vải', booking.quote!.fabric),
                  _DetailRow(
                    'Tổng',
                    money.format(booking.quote!.total),
                    strong: true,
                  ),
                  _DetailRow(
                    'Tiền cọc',
                    money.format(booking.quote!.deposit),
                    strong: true,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const TextField(
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Ghi chú nội bộ',
              hintText: 'Thông tin chỉ nhân viên nhìn thấy…',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () => _demoAction(context),
            child: Text(
              booking.status == BookingStatus.pending
                  ? 'XÁC NHẬN LỊCH HẸN'
                  : 'CẬP NHẬT TRẠNG THÁI',
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: strong
                ? AppTheme.mono.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  )
                : null,
          ),
        ),
      ],
    ),
  );
}

class _DemoFilter extends StatelessWidget {
  const _DemoFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

void _openBooking(BuildContext context, Booking booking) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _DemoDetail(booking: booking)),
  );
}

void _demoAction(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đây là thao tác minh họa trong bản demo.')),
  );
}

String _date(int offset) =>
    DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: offset)));

final demoBookings = <Booking>[
  Booking(
    id: 'PD-A8K2Q7',
    type: 'domay',
    name: 'Nguyễn Minh Khang',
    phone: '090 321 8899',
    email: 'khang.nguyen@example.com',
    product: 'Vest cưới hai hàng khuy',
    budget: '18–25 triệu',
    note: 'Ưu tiên phom Ý, cần hoàn thiện trước lễ cưới.',
    date: _date(0),
    time: '09:30',
    status: BookingStatus.pending,
    payMethod: 'Chuyển khoản',
    adminNote: '',
    quote: const BookingQuote(
      type: 'Vest may đo',
      fabric: 'Vitale Barberis Canonico',
      qty: 1,
      unitPrice: 22500000,
      total: 22500000,
      deposit: 7000000,
    ),
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now(),
  ),
  Booking(
    id: 'PD-M4R9T2',
    type: 'tuvan',
    name: 'Trần Hoàng Nam',
    phone: '098 765 4321',
    email: 'nam.tran@example.com',
    product: 'Business suit',
    budget: '12–18 triệu',
    note: 'Tư vấn trang phục cho chuyến công tác Singapore.',
    date: _date(0),
    time: '14:00',
    status: BookingStatus.confirmed,
    payMethod: '',
    adminNote: 'Khách quen, chuẩn bị trước vải navy.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now(),
  ),
  Booking(
    id: 'PD-X7C3L5',
    type: 'domay',
    name: 'Lê Anh Tuấn',
    phone: '091 246 8024',
    email: 'tuan.le@example.com',
    product: 'Tuxedo đen cổ sam',
    budget: '25–35 triệu',
    note: '',
    date: _date(1),
    time: '10:15',
    status: BookingStatus.pending,
    payMethod: 'Thẻ',
    adminNote: '',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now(),
  ),
  Booking(
    id: 'PD-H5N8P3',
    type: 'domay',
    name: 'Phạm Quốc Bảo',
    phone: '093 556 7788',
    email: '',
    product: 'Blazer linen mùa hè',
    budget: '10–15 triệu',
    note: 'Phom thoải mái, dùng đi nghỉ dưỡng.',
    date: _date(-1),
    time: '16:30',
    status: BookingStatus.completed,
    payMethod: 'Tiền mặt',
    adminNote: '',
    quote: const BookingQuote(
      type: 'Blazer may đo',
      fabric: 'Linen Loro Piana',
      qty: 1,
      unitPrice: 14500000,
      total: 14500000,
      deposit: 5000000,
    ),
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now(),
  ),
  Booking(
    id: 'PD-Q2V6D9',
    type: 'tuvan',
    name: 'Đỗ Đức Long',
    phone: '097 111 2200',
    email: 'long.do@example.com',
    product: 'Tủ đồ doanh nhân',
    budget: 'Trên 40 triệu',
    note: 'Cần ba bộ dùng luân phiên trong tuần.',
    date: _date(3),
    time: '11:00',
    status: BookingStatus.cancelled,
    payMethod: '',
    adminNote: 'Khách đổi lịch công tác.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now(),
  ),
];
