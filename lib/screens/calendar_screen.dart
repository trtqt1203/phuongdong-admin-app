import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/screens/booking_detail_screen.dart';
import 'package:phuong_dong_admin/services/booking_service.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:phuong_dong_admin/widgets/booking_tile.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

enum _CalendarMode { month, week, day }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focused = DateTime.now();
  DateTime selected = DateTime.now();
  _CalendarMode mode = _CalendarMode.month;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch làm việc')),
    body: StreamBuilder<List<Booking>>(
      stream: context.read<BookingService>().watchBookings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookings = snapshot.data!;
        final selectedItems =
            bookings
                .where(
                  (item) =>
                      item.date == DateFormat('yyyy-MM-dd').format(selected),
                )
                .toList()
              ..sort((a, b) => a.time.compareTo(b.time));
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<_CalendarMode>(
                segments: const [
                  ButtonSegment(
                    value: _CalendarMode.month,
                    label: Text('Tháng'),
                  ),
                  ButtonSegment(value: _CalendarMode.week, label: Text('Tuần')),
                  ButtonSegment(value: _CalendarMode.day, label: Text('Ngày')),
                ],
                selected: {mode},
                onSelectionChanged: (value) =>
                    setState(() => mode = value.first),
              ),
            ),
            if (mode != _CalendarMode.day)
              TableCalendar<Booking>(
                locale: 'vi_VN',
                firstDay: DateTime.now().subtract(const Duration(days: 730)),
                lastDay: DateTime.now().add(const Duration(days: 1095)),
                focusedDay: focused,
                selectedDayPredicate: (day) => isSameDay(day, selected),
                calendarFormat: mode == _CalendarMode.week
                    ? CalendarFormat.week
                    : CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Tháng',
                  CalendarFormat.week: 'Tuần',
                },
                eventLoader: (day) => bookings
                    .where(
                      (item) =>
                          item.date == DateFormat('yyyy-MM-dd').format(day),
                    )
                    .toList(),
                onDaySelected: (day, focus) => setState(() {
                  selected = day;
                  focused = focus;
                }),
                onPageChanged: (day) => focused = day,
                calendarBuilders: CalendarBuilders<Booking>(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return const SizedBox.shrink();
                    final statuses = events.map((item) => item.status).toSet();
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: statuses.take(3).map((status) {
                          final color = switch (status) {
                            BookingStatus.pending => AppColors.gold,
                            BookingStatus.confirmed => AppColors.green,
                            BookingStatus.cancelled => AppColors.rust,
                            BookingStatus.completed => AppColors.dim,
                          };
                          return Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(
                        () => selected = selected.subtract(
                          const Duration(days: 1),
                        ),
                      ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      DateFormat("EEEE, dd/MM/yyyy", 'vi').format(selected),
                      style: AppTheme.serif.copyWith(fontSize: 20),
                    ),
                    IconButton(
                      onPressed: () => setState(
                        () => selected = selected.add(const Duration(days: 1)),
                      ),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lịch ngày ${DateFormat('dd/MM').format(selected)}',
                    style: AppTheme.serif.copyWith(fontSize: 22),
                  ),
                  Text(
                    '${selectedItems.length} lịch',
                    style: AppTheme.mono.copyWith(
                      color: AppColors.gold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: selectedItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Ngày này chưa có lịch hẹn.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: selectedItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => BookingTile(
                        booking: selectedItems[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailScreen(
                              bookingId: selectedItems[index].id,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}
